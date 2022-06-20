package HTML::Obj2HTML::Plugin::SemanticUI;

use strict;
use warnings;

my @semanticnumbers = qw(zero one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen);
HTML::Obj2HTML::register_extension("form", {
  attr => { class => "ui form" }
});HTML::Obj2HTML::register_extension("select", {
  attr => { class => "ui dropdown" }
});
HTML::Obj2HTML::register_extension("checkbox", {
  tag => "",
  before => sub {
    my $obj = shift;
    if (ref $obj ne "HASH") { return ""; }
    my $readonly = HTML::Obj2HTML::get_opt("readonly") || $obj->{readonly};
    delete($obj->{readonly});
    if ($readonly) {
      return HTML::Obj2HTML::gen([ div => [
        if => { cond => $obj->{checked}, true => [ icon => 'green check' ], false => [ icon => 'red close' ]},
        _ => " ".$obj->{label}
      ]]);
    } else {
      my $label = $obj->{label}; delete($obj->{label});
      if (!$label && $obj->{checkboxlabel}) { $label = $obj->{checkboxlabel}; delete($obj->{checkboxlabel}); }
      if (!$obj->{value}) { $obj->{value} = 1; }
      $obj->{if} = { cond => $obj->{checked}, true => { checked => 1 } }; delete($obj->{checked});
      $obj->{type} = "checkbox";
      return HTML::Obj2HTML::gen([
        div => { class => 'ui checkbox', _ => [
          input => $obj, label => $label
        ] }
      ]);
    }
  }
});
HTML::Obj2HTML::register_extension("radio", {
  tag => "",
  before => sub {
    my $obj = shift;
    if (ref $obj ne "HASH") { return ""; }
    my $readonly = HTML::Obj2HTML::get_opt("readonly") || $obj->{readonly};
    delete($obj->{readonly});
    if ($readonly) {
      return HTML::Obj2HTML::gen([ div => [
        if => { cond => $obj->{checked}, true => [ icon => 'check' ] },
        _ => " ".$obj->{label}
      ]]);
    } else {
      my $label = $obj->{label}; delete($obj->{label});
      if (!$label && $obj->{radiolabel}) { $label = $obj->{radiolabel}; delete($obj->{radiolabel}); }
      if (!$obj->{value}) { $obj->{value} = 1; }
      $obj->{if} = { cond => $obj->{checked}, true => { checked => 1 } }; delete($obj->{checked});
      $obj->{type} = "radio";
      return HTML::Obj2HTML::gen([
        div => { class => 'ui radio checkbox', _ => [
          input => $obj, label => $label
        ] }
      ]);
    }
  }
});
HTML::Obj2HTML::register_extension("labeledinput", {
  tag => "",
  before => sub {
    my $obj = shift;
    if (ref $obj ne "HASH") { return ""; }
    my $readonly = HTML::Obj2HTML::get_opt("readonly") || $obj->{readonly};
    delete($obj->{readonly});
    if ($readonly) {
      return [ div => $obj->{value}." ".$obj->{label} ];
    } else {
      my $label = $obj->{label}; delete($obj->{label});

      # The has we were passed actually belongs to a child element, we need to copy and clear.
      my $inputobj = {};
      for (keys %$obj) { $inputobj->{$_} = $obj->{$_}; delete $obj->{$_}; }

      return [ div => { class => "ui right labeled input", _ => [
        input => $inputobj,
        div => { class => "ui basic label", _ => $label }
      ]}];
    }
  }
});
HTML::Obj2HTML::register_extension("field", {
  tag => 'div',
  before => sub {
    my $obj = shift;
    if (ref $obj eq "HASH") {
      if (!defined $obj->{_}) { $obj->{_} = []; }
      my $label = genhelplabel($obj);
      if ($label) {
        unshift(@{$obj->{"_"}}, "label", $obj->{label});
      }
    }
    return undef;
  },
  attr => { class => 'field' }
});

HTML::Obj2HTML::register_extension("fields", {
  tag => "div",
  before => sub {
    my $o = shift;
    if (ref $o ne "HASH") { return ""; }
    $o->{class} = "ui ".$semanticnumbers[$o->{num}]." fields";
    delete($o->{num});
    return "";
  }
});
HTML::Obj2HTML::register_extension("checkboxfield", {
  tag => "",
  before => sub {
    my $obj = shift;
    if (ref $obj ne "HASH") { return ""; }
    return HTML::Obj2HTML::gen(commonfield($obj, [ checkbox => $obj ]));
  }
});
HTML::Obj2HTML::register_extension("radiofield", {
  tag => "",
  before => sub {
    my $obj = shift;
    if (ref $obj ne "HASH") { return ""; }
    return HTML::Obj2HTML::gen(commonfield($obj, [ radio => $obj ]));
  }
});

HTML::Obj2HTML::register_extension("inputfield", {
  tag => "",
  before => sub {
    my $obj = shift;
    if (ref $obj ne "HASH") { return ""; }
    my $readonly = HTML::Obj2HTML::get_opt("readonly") || $obj->{readonly};
    delete($obj->{readonly});
    if ($readonly) {
      return HTML::Obj2HTML::gen(commonfield($obj, [ span => $obj->{value} ]));
    } else {
      return HTML::Obj2HTML::gen(commonfield($obj, [ input => $obj ]));
    }
  }
});

HTML::Obj2HTML::register_extension("textareafield", {
  tag => "",
  before => sub {
    my $obj = shift;
    if (ref $obj ne "HASH") { return ""; }
    if (defined $obj->{value}) {
      my $val = $obj->{value};
      delete($obj->{value});
      $val =~ s/^\s+//g;
      $val =~ s/\s+$//g;
      $obj->{_} = "$val";
    } else {
      $obj->{_} = "";
    }

    my $readonly = HTML::Obj2HTML::get_opt("readonly") || $obj->{readonly};
    delete($obj->{readonly});
    if ($readonly) {
      if ($obj->{class} =~ /editor/) {
        return HTML::Obj2HTML::gen(commonfield($obj, [ div => [ raw => $obj->{_} ] ]));
      } else {
        return HTML::Obj2HTML::gen(commonfield($obj, [ div => [ md => $obj->{_} ] ]));
      }
    } else {
      return HTML::Obj2HTML::gen(commonfield($obj, [ textarea => $obj ]));
    }

  }
});
HTML::Obj2HTML::register_extension("htmlfield", {
  tag => "",
  before => sub {
    my $obj = shift;
    if (ref $obj ne "HASH") { return ""; }
    if ($obj->{class} !~ /editor/) {
      if ($obj->{class}) { $obj->{class} .= " "; }
      $obj->{class} .= "editor";
    }
    return [ textareafield => $obj ];
  }
});

HTML::Obj2HTML::register_extension("selectfield", {
  tag => "",
  before => sub {
    my $obj = shift;
    if (ref $obj ne "HASH") { return ""; }

    my $readonly = HTML::Obj2HTML::get_opt("readonly") || $obj->{readonly};
    delete($obj->{readonly});

    if ($obj->{class}) { $obj->{class}.=" "; }
    $obj->{class}.= "ui dropdown";
#    if ($obj->{multiple}) { $obj->{class}.= " fluid"; }

    my $db = $obj->{db} || $HTML::Obj2HTML::db;
    delete($obj->{db});

    if ($obj->{options} && ref $obj->{options} eq "ARRAY") {
      my @contents = ();
      if ($obj->{inclblank}) { push(@contents, option => { value => "", _ => "" }); }
      for (my $i = 0; $i <= $#{$obj->{hiddenoptions}}; $i+=2) {
        my $v = $obj->{hiddenoptions}->[$i];
        my $t = $obj->{hiddenoptions}->[$i+1];
        if ((!$obj->{multiple} && defined $obj->{value} && "$obj->{value}" eq "$v") ||
            ($obj->{multiple} && defined $obj->{value} && ($obj->{value} & $v))) {
          if ($readonly) {
            push(@contents, div => $t);
          } else {
            push(@contents, option => { value => $v, _ => $t, selected => 1 });
          }
        }
      }
      for (my $i = 0; $i <= $#{$obj->{options}}; $i+=2) {
        my $v = $obj->{options}->[$i];
        my $t = $obj->{options}->[$i+1];
        my $opt = { value => $v, _ => $t };
        if (!$obj->{multiple}) {
          if (defined $obj->{value} && "$obj->{value}" eq "$v") { $opt->{selected} = 1; }
        } else {
          if (defined $obj->{value} && ($obj->{value} & $v)) { $opt->{selected} = 1; }
          if (defined $obj->{values}) {
            if (grep {"$_" eq "$v"} @{$obj->{values}}) { $opt->{selected} = 1; }
          }
        }

        if ($readonly) {
          if ($opt->{selected}) {
            push(@contents, div => $opt->{_});
          }
        } else {
          push(@contents, option => $opt);
        }
      }
      $obj->{_} = \@contents;
      delete($obj->{values});
      delete($obj->{options});
      delete($obj->{hiddenoptions});
    }
    if ($obj->{optionsql} && ref $obj->{optionsql} eq "ARRAY") {
      my @contents = ();
      if ($obj->{inclblank}) { push(@contents, option => { value => "", _ => "" }); }
      if (!$obj->{valuefield}) { $obj->{valuefield} = "id"; }
      if (!$obj->{textfield}) { $obj->{textfield} = "name"; }
      for (my $r = $db->for(@{$obj->{optionsql}}); $r->more; $r->next) {
        my $opt = { value => $r->{$obj->{valuefield}}, _ => $r->{$obj->{textfield}} };
        if (!$obj->{multiple}) {
          if (defined $obj->{value} && "$obj->{value}" eq "$r->{$obj->{valuefield}}") { $opt->{selected} = 1; }
        } else {
          if (defined $obj->{selectedfield} && $r->{$obj->{selectedfield}}) {
            $opt->{selected} = 1;
          } elsif (defined $obj->{value} && ($obj->{value} & $r->{$obj->{valuefield}})) {
            $opt->{selected} = 1;
          }
          if (defined $obj->{values}) {
            if (grep({$_ eq $r->{$obj->{valuefield}}} @{$obj->{values}})) { $opt->{selected} = 1; }
          }
        }
        if ($readonly) {
          if ($opt->{selected}) {
            push(@contents, div => $opt->{_});
          }
        } else {
          push(@contents, option => $opt);
        }
      }
      $obj->{_} = \@contents;
      delete($obj->{values});
      delete($obj->{optionsql});
      delete($obj->{valuefield});
      delete($obj->{textfield});
    }
    if (!$obj->{_}) { $obj->{_} = []; }
    delete($obj->{value});
    delete($obj->{inclblank});

    if ($readonly) {
      return HTML::Obj2HTML::gen(commonfield($obj, $obj->{_}));
    } else {
      return HTML::Obj2HTML::gen(commonfield($obj, [ select => $obj ]));
    }

  }
});
HTML::Obj2HTML::register_extension("dateinput", {
  tag => "",
  before => sub {
    my $o = shift;
    return HTML::Obj2HTML::gen([
      div => { class => "ui calendar dateonly", _ => [
        div => { class => "ui input left icon", _ => [
          i => { class => "calendar icon", _ => [] },
          input => $o
        ]}
      ]}
    ]);
  }
});
HTML::Obj2HTML::register_extension("datefield", {
  tag => "",
  before => sub {
    my $obj = shift;
    if (ref $obj ne "HASH") { return ""; }

    my $readonly = HTML::Obj2HTML::get_opt("readonly") || $obj->{readonly};
    delete($obj->{readonly});
    if ($readonly) {
      return HTML::Obj2HTML::gen(commonfield($obj, [ span => $obj->{value} ] ));
    } else {
      return HTML::Obj2HTML::gen(commonfield($obj, [
          div => { class => "ui calendar ".$obj->{class}, _ => [
            div => { class => "ui input left icon", _ => [
              i => { class => "calendar icon", _ => [] },
              input => { type => "text", name => $obj->{name}, placeholder => $obj->{placeholder}, value => $obj->{value} }
            ]}
          ]}
      ]));
    }
  }
});
HTML::Obj2HTML::register_extension("hiddeninput", {
  tag => "input",
  attr => { type => "hidden" }
});
HTML::Obj2HTML::register_extension("submit", {
  tag => "",
  before => sub {
    my $obj = shift;
    if (ref $obj ne "HASH") { $obj = { _ => $obj }; }
    my $readonly = HTML::Obj2HTML::get_opt("readonly") || $obj->{readonly};
    delete($obj->{readonly});
    if ($readonly) {
      return [];
    }
    if (!ref $obj) { $obj = { value => $obj }; } else { $obj->{value} = $obj->{label}; delete($obj->{label}); }
    if (defined $obj->{class}) { $obj->{class} .= " ui button"; } else { $obj->{class}.="ui positive button"; }
    $obj->{type} = "submit";
    return [ input => $obj ];
  },
});

HTML::Obj2HTML::register_extension("cancel", {
  tag => "",
  before => sub {
    my $obj = shift;
    if (ref $obj ne "HASH") { $obj = { _ => $obj }; }
    my $readonly = HTML::Obj2HTML::get_opt("readonly") || $obj->{readonly};
    delete($obj->{readonly});
    if ($readonly) {
      return [];
    }
    if (!ref $obj) { $obj = { value => $obj }; } else { $obj->{value} = $obj->{label}; delete($obj->{label}); }
    if ($obj->{class}) { $obj->{class} .= " "; }
    $obj->{class}.="ui negative button";
    return [ a => $obj ];
  },
});

HTML::Obj2HTML::register_extension("helplabel", {
  tag => "label",
  before => sub {
    my $o = shift;
    if (ref $o ne "HASH") { $o = { helptext => $o }; }
    $o->{_} = [ _ => $o->{label} ];
    if ($o->{helptext}) {
      push(@{$o->{_}}, help => { text => $o->{helptext} });
    }
    if ($o->{helphtml}) {
      push(@{$o->{_}}, help => { html => $o->{helphtml} });
    }
    delete($o->{label});
    delete($o->{helptext});
    delete($o->{helphtml});
    return "";
  }
});

sub genhelplabel {
  my $obj = shift;
  if (ref $obj ne "HASH") { $obj = { _ => $obj }; }
  if ($obj->{label}) {
    my $label = $obj->{label};
    if ($obj->{helptext}) {
      $label = [ _ => $label, i => { style => 'margin-left: 5px;', class => 'blue circular icon help', 'data-content' => $obj->{helptext}, _ => [] } ];
      delete($obj->{helptext});
    }
    if ($obj->{helphtml}) {
      $label = [ _ => $label, i => { style => 'margin-left: 5px;', class => 'blue circular icon help', 'data-html' => $obj->{helphtml}, _ => [] } ];
      delete($obj->{helphtml});
    }
    delete($obj->{label});
    return $label;
  }
  return;
}
sub commonfield {
  my $obj = shift;
  my $field = shift;

  if (ref $obj ne "HASH") { return ""; }
  my $class = "field";
  if ($obj->{required}) {
    $class .= " required";
    delete($obj->{required});
  }

  my $label = genhelplabel($obj);
  if ($label) {
    unshift(@{$field}, "label", $label);
  };
  if ($obj->{uiwidth}) {
    $class .= " $semanticnumbers[$obj->{uiwidth}] wide";
    delete($obj->{uiwidth});
  }
  return [ div => { class => $class, _ => $field }];
}
1;
