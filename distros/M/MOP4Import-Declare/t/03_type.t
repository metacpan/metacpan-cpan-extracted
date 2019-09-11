#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }

use Test::Kantan;

use rlib qw!../..!;

use MOP4Import::t::t_lib qw/no_error expect_script_error catch/;

describe "MOP4Import::Declare::Type", sub {
  describe "use ... -as_base", sub {

    it "should have no error", no_error <<'END';
package Base1;
use MOP4Import::Declare::Type -as_base, -inc
   , [fields => qw/x y/]
   , [type => Foo => [fields => qw/a b/]
                     , [subtypes =>
                         ,  Bar => [[fields => qw/c d/]]
                         ,  Baz => [[fields => qw/e f/]]
                       ]]
   ;
1;
END

    it "should make Base1 as a subclass of MOP4Import::Declare", sub {
      ok {Base1->isa('MOP4Import::Declare::Type')};
    };

    it "should define MY as constant sub", no_error <<'END';
package Base1;
sub test {
  (my MY $self, my Foo $foo, my Bar $bar, my Baz $baz) = @_;
}
END

    it "should define field Base1->{x,y}", no_error <<'END';
package Base1;
sub test2 {
  (my MY $self, my Foo $foo, my Bar $bar, my Baz $baz) = @_;
  $self->{x} + $self->{y} + $foo->{a} + $foo->{b}
  + $bar->{a} + $bar->{b} + $bar->{c} + $bar->{d}
  + $baz->{a} + $baz->{b} + $baz->{e} + $baz->{f}
}
END

   foreach my $spec ([MY => 'Base1'], [Foo => 'Base1::Foo']
, [Bar => 'Base1::Bar'], [Baz => 'Base1::Baz']) {

    my ($alias, $real) = @$spec;
    it "should detect spell miss for ${real}->{unk}"
      , expect_script_error sprintf(<<'END', $alias)
package Base1; sub test3_%1$s {
  (my %1$s $foo) = @_;
  $foo->{unk}
}
END
	, to_match =>
	  qr/^No such class field "unk" in variable \$foo of type $real/;
  }
  };

  describe "use YOUR_CLASS -as_base, [extend => Baz]", sub {
    it "should be used without error", no_error <<'END';
package User; use Base1 -as_base, [extend => Baz => [fields => qw/aaa bbb/]];
1;
END

    it "should define field User::Baz->{aaa,bbb}", no_error <<'END';
package User;
sub test {
  (my Baz $baz) = @_;
  $baz->{a} + $baz->{b} + $baz->{e} + $baz->{f}
 + $baz->{aaa} + $baz->{bbb}
}
END

  };

};

done_testing();
