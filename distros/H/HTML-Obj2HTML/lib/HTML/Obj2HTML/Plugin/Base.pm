use strict;
use warnings;

HTML::Obj2HTML::register_extension("repeat", {
  tag => "",
  before => sub {
    my $o = shift;
    my $ret = [];
    if (ref $o ne "HASH") {
      return $o;
    } else {
      if (!defined $o->{num}) { $o->{num} = 1; }
      for (my $i=0; $i<$o->{num}; $i++) {
        push(@{$ret}, @{$o->{_}});
      }
    }
    return $ret;
  }
});
HTML::Obj2HTML::register_extension("editable", {
  tag => "",
  before => sub {
    my $o = shift;
    my $prevro = HTML::Obj2HTML::get_opt("readonly");
    HTML::Obj2HTML::set_opt("readonly", 0);
    my $ret = HTML::Obj2HTML::gen($o);
    HTML::Obj2HTML::set_opt("readonly", $prevro);
    return $ret;
  }
});
HTML::Obj2HTML::register_extension("readonly", {
  tag => "",
  before => sub {
    my $o = shift;
    my $prevro = HTML::Obj2HTML::get_opt("readonly");
    HTML::Obj2HTML::set_opt("readonly", 1);
    my $ret = HTML::Obj2HTML::gen($o);
    HTML::Obj2HTML::set_opt("readonly", $prevro);
    return $ret;
  }
});

HTML::Obj2HTML::register_extension("ifReadOnly", {
  tag => "if",
  before => sub {
    my $o = shift;
    if (ref $o eq "HASH") {
      $o->{cond} = HTML::Obj2HTML::get_opt('readonly');
    }
    return "";
  }
});
HTML::Obj2HTML::register_extension("ifEditable", {
  tag => "if",
  before => sub {
    my $o = shift;
    if (ref $o eq "HASH") {
      $o->{cond} = !Obj2HTML::get_opt("readonly");
    }
    return "";
  }
});

1;
