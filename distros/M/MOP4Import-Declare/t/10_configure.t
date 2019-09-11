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

    it "should raise error for wrong argument", sub {
      expect(do {eval q{Zodiac1->new(undef, 'foo')}; $@})
	->to_match(qr/^Undefined option name for class Zodiac1/);

      expect(do {eval q{Zodiac1->new(foo => 'bar')}; $@})
	->to_match(qr/^Unknown option for class Zodiac1: foo/);

      expect(do {eval q{Zodiac1->new(_gemini_cnt => 100)}; $@})
	->to_match(qr/^Private option is prohibited for class Zodiac1: _gemini_cnt/);
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
        , no_error q{package F_def; use Zodiac1 -as_base, -inc, [fields => [fmt => default => 'tsv']]};

      it "should be set as default value", sub {
	ok {F_def->new->fmt eq 'tsv'};
      };

      it "should be changed in regular manner", sub {
	ok {F_def->new(fmt => 'xlsx')->fmt eq 'xlsx'};
      }
    };

    describe "before/after hook for configure_default", sub {
      it "should be defined", no_error q{
package F_def_with_hooks;
use F_def -as_base
  , [fields =>
       [x => default => 'X'],
       [y => default => 'Y'],
       [z => default => 'Z'],
       'value', 'x_is_explicitly_defined',
    ]
  ;

sub before_configure_default {
  (my MY $self) = @_;
  $self->{x_is_explicitly_defined} = defined $self->{x};
}

sub after_configure_default {
  (my MY $self) = @_;
  $self->{value} //= "$self->{x}$self->{y}$self->{z}";
}

};

      it "should allow defining derived value in after_configure_hook", sub {
        expect(F_def_with_hooks->new->value)->to_be("XYZ");
      };

      it "should allow use of definedness of options in before_configure_hook", sub {
        expect(F_def_with_hooks->new(x => 8)->x_is_explicitly_defined)->to_be(1);
      };

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

  describe 'copy constructor and such', sub {

    describe 'cf_configs()', sub {

      it "should list configured value only", sub {
        my $obj = F_def->new(aquarius => 1, scorpio => 2);

        expect([$obj->cf_configs])->to_be([aquarius => 1, scorpio => 2]);
      };
    };

    describe 'cf_public_fields()', sub {
      my $obj = F_def->new(aquarius => 1, scorpio => 2);

      it "should list all public fields", sub {
        expect([$obj->cf_public_fields])->to_be([qw/aquarius fmt gemini scorpio/]);
      };

      it "should be applicable to class too", sub {
        expect([ref($obj)->cf_public_fields])->to_be([qw/aquarius fmt gemini scorpio/]);
      };
    };

    describe 'my $clone = $original->new($original)', sub {
      my $original = Zodiac1->new
        (aquarius => ["foo"], scorpio => {bar => 1}, gemini => "baz");

      my $clone = $original->new($original);

      describe 'modification to clone', sub {

        push @{$clone->{aquarius}}, 'FOO';

        expect($clone->{aquarius})->to_be(['foo', 'FOO']);

        it "should not affect to original", sub {
          expect($original->{aquarius})->to_be(['foo']);
        };
      };

      describe 'modification to original', sub {
        $original->{scorpio}{BAR} = 2;

        expect($original->{scorpio})->to_be({bar => 1, BAR => 2});

        it "should not affect to clone", sub {
          expect($clone->{scorpio})->to_be({bar => 1});
        };
      }
    };
  };

  describe "fields with dot: [fields => qw/api.token/]", sub {
    it "should have no error", no_error q{
package MyConnector;
use MOP4Import::Base::Configure -as_base, -inc
    , [fields => qw/api.token/];

sub common_header {
  (my MY $self) = @_;
('Content-Type' => 'application/json'
, Authorization => "Bearer $self->{'api.token'}");
}

};

    it "should be configured successfully", sub {

      my $obj = MyConnector->new('api.token' => 'XXXXYYYY');

      expect([$obj->common_header])->to_be([qw(Content-Type application/json Authorization) => "Bearer XXXXYYYY"]);

    };

  };
};

done_testing();
