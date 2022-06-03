package HTML::Obj2HTML::Plugin::SemanticUI;

use strict;
use warnings;

my @tabs = ();
my @content = ();
HTML::Obj2HTML::register_extension("tabsection", {
  tag => "",
  before => sub {
    my $obj = shift;
    @tabs = ();
    @content = ();
    return HTML::Obj2HTML::gen($obj);
  },
  after => sub {
    my $obj = shift;
    my $divinner = {
      class => "ui tabular menu",
      _ => \@tabs
    };
    if (ref $obj eq "HASH") {
      foreach my $k (%{$obj}) {
        if (defined $divinner->{$k}) { $divinner->{$k} .= " ".$obj->{$k}; } else { $divinner->{$k} = $obj->{$k}; }
      }
      return HTML::Obj2HTML::gen([ div => $divinner, \@content ]);
    } else {
      return HTML::Obj2HTML::gen([ div => { class => "ui top attached tabular menu", _ => \@tabs }, \@content ]);
    }
  }
});
HTML::Obj2HTML::register_extension("tab", {
  tag => "",
  before => sub {
    my $obj = shift;
    if ($obj->{class}) { $obj->{class} .= " "; }
    if ($obj->{active}) { $obj->{class} .= "active "; }
    push(@tabs, div => { class => $obj->{class}."item", "data-tab" => $obj->{tab}, _ => $obj->{label} });
    push(@content, div => { class => $obj->{class}."ui bottom attached tab segment", "data-tab" => $obj->{tab}, _ => $obj->{content} });
    return "";
  }
});

my $stepcontent = {};
my $steplabels = {};
my $curstepid;
HTML::Obj2HTML::register_extension("steps", {
  tag => "",
  before => sub {
    my $o = shift;
    my $content = $o->{_};
    $stepcontent->{$o->{id}} = [];
    $steplabels->{$o->{id}} = [];
    $curstepid = $o->{id};
    HTML::Obj2HTML::gen($content); # This processes it, but it doesn't actually generate anything, that's handled by the after()
  },
  after => sub {
    my $o = shift;
    my $id = "";
    if (ref $o eq "HASH") { $id = $o->{id}; }
    my $cls = HTML::Obj2HTML::combineClasses("ui steps", $o->{class});
    my $ccls = HTML::Obj2HTML::combineClasses("stepcontent", $o->{contentclass});
    return [
      div => { "data-stepid" => $id, class => $cls, _ => \@{$steplabels->{$o->{id}}} },
      div => { "data-stepid" => $id, class => $ccls, _ => \@{$stepcontent->{$o->{id}}} }
    ];
  }
});
HTML::Obj2HTML::register_extension("step", {
  tag => "",
  before => sub {
    my $o = shift;
    my @steplabels = @{$steplabels->{$curstepid}};
    my $cnt = (($#steplabels+1)/2)+1; # -1 = no steps, start count from 1, therefore +2.
    if (!@steplabels) {
      push(@{$steplabels->{$curstepid}}, div => { "data-stepid" => $curstepid, class => 'active step', "data-stepnum" => $cnt, _ => $o->{label} });
      push(@{$stepcontent->{$curstepid}}, div => { "data-stepid" => $curstepid, "data-stepnum" => $cnt, _ => $o->{_} });
    } else {
      push(@{$steplabels->{$curstepid}}, div => { "data-stepid" => $curstepid, class => 'step', "data-stepnum" => $cnt, _ => $o->{label} });
      push(@{$stepcontent->{$curstepid}}, div => { "data-stepid" => $curstepid, "data-stepnum" => $cnt, style => 'display: none;', _ => $o->{_} });
    }
    return;
  }
});
1;
