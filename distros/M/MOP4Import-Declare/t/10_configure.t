#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }

use Test::Kantan;
use Scalar::Util qw/isweak/;

use rlib qw!../..!;

use MOP4Import::t::t_lib qw/no_error expect_script_error/;

describe "MOP4Import::Base::Configure", sub {
  describe "use ... -as_base, [fields => qw/aquarius scorpio gemini/]", sub {

    it "should have no error"
      , no_error q{
package Zodiac1;
use MOP4Import::Base::Configure -as_base, -inc
    , [fields => qw/aquarius scorpio _scorpio_cnt gemini _gemini_cnt/];

sub onconfigure_scorpio {
  (my __PACKAGE__ $self, my $value) = @_;
  $self->{_scorpio_cnt}++;
  $self->{scorpio} = $value;
}

sub onconfigure_twins {
  (my __PACKAGE__ $self, my $value) = @_;
  $self->{_gemini_cnt}++;
  $self->{gemini} = $value;
}

1;
};

    it "should make Zodiac1 as a subclass of ..Configure", sub {
      ok {Zodiac1->isa('MOP4Import::Base::Configure')};
    };

    it "should make define MY alias in Zodiac1", sub {
      ok {Zodiac1->MY eq 'Zodiac1'};
    };

    it "should define MY as constant sub", no_error <<'END';
package Zodiac1; sub test { (my MY $foo) = @_; }
END

    it "should define field Zodiac1->{aquarius,scorpio,gemini}"
      , no_error <<'END';
package Zodiac1; sub test2 {
  (my MY $foo) = @_;
  $foo->{aquarius} + $foo->{scorpio}  + $foo->{gemini};
}
END

    it "should detect spell miss for Zodiac1->{aquariusss}"
      , expect_script_error <<'END'
package Zodiac1; sub test3 {
  (my MY $foo) = @_;
  $foo->{aquariusss}
}
END
	, to_match =>
	  qr/^No such class field "aquariusss" in variable \$foo of type Zodiac1/;

    it "should accept new(key => value...)", sub {
       my $obj = Zodiac1->new
           (aquarius => "foo", scorpio => "bar", gemini => "baz");
       ok {$obj->aquarius eq "foo"};
       ok {$obj->scorpio  eq "bar"};
       ok {$obj->gemini   eq "baz"};
    };

    it "should accept new({key => value...}) too", sub {
       my $obj = Zodiac1->new
           ({aquarius => "bar", scorpio => "baz", gemini => "foo"});
       ok {$obj->aquarius eq "bar"};
       ok {$obj->scorpio  eq "baz"};
       ok {$obj->gemini   eq "foo"};
    };

    it "should accept configure(key => value...)", sub {
       my $obj = Zodiac1->new->configure
           (aquarius => "foo", scorpio => "bar", gemini => "baz");
       ok {$obj->aquarius eq "foo"};
       ok {$obj->scorpio  eq "bar"};
       ok {$obj->gemini   eq "baz"};
    };

    it "should wrong argument for configure", sub {
      expect(do {eval q{Zodiac1->new(undef, 'foo')}; $@})
	->to_match(qr/^Undefined option name for class Zodiac1/);

      expect(do {eval q{Zodiac1->new(foo => 'bar')}; $@})
	->to_match(qr/^Unknown option for class Zodiac1: foo/);
    };

    it "should call onconfigure_zzz hook ", sub {
       my $obj = Zodiac1->new(scorpio => "foo", twins => "bar")->configure
           (scorpio => "baz", twins => "qux");
       ok {$obj->scorpio  eq "baz"};
       ok {$obj->{_scorpio_cnt} == 2};
       ok {$obj->gemini   eq "qux"};
       ok {$obj->{_gemini_cnt} == 2};
     };
  };

  describe "package MyZodiac {use Zodiac1 -as_base}", sub {
    it "should have no error"
      , no_error q{
package MyZodiac; use Zodiac1 -as_base;
};

    it "should inherit Zodiac1", sub {
      ok {MyZodiac->isa('Zodiac1')};
    };
  };

  describe "use .. [fields [f => \@spec],...]", sub {
    describe "spec: default => 'value'", sub {
      it "should be accepted"
	, no_error q{package F_def; use Zodiac1 -as_base, [fields => [f => default => 'defval']]};

      it "should be set as default value", sub {
	ok {F_def->new->f eq 'defval'};
      }
    };

    describe "spec: weakref => 1", sub {
      it "should be accepted"
	, no_error q{package F_weak; use Zodiac1 -as_base, [fields => [f => weakref => 1]]};

      it "should be weakened", sub {
	my $obj = [];
	ok {$obj->[0] = F_weak->new(f => $obj); isweak($obj->[0]->{f})};
      }
    };
    
  };
};

done_testing();
