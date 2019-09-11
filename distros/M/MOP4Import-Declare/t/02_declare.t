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

describe "MOP4Import::Declare", sub {
  describe "use ... -as_base", sub {

    it "should have no error", no_error <<'END';
package Tarot1;
use MOP4Import::Declare -as_base, -inc
   , [fields => qw/pentacle chariot tower _hermit/];
1;
END

    it "should make Tarot1 as a subclass of MOP4Import::Declare", sub {
      ok {Tarot1->isa('MOP4Import::Declare')};
    };

    it "should make define MY alias in Tarot1", sub {
      ok {Tarot1->MY eq 'Tarot1'};
    };

    it "should define MY as constant sub", no_error <<'END';
package Tarot1; sub test { (my MY $foo) = @_; }
END

    it "should define field Tarot1->{pentacle,chariot,tower}", no_error <<'END';
package Tarot1; sub test2 {
  (my MY $foo) = @_;
  $foo->{pentacle} + $foo->{chariot} + $foo->{tower} + $foo->{_hermit};
}
END

    it "should detect spell miss for Tarot1->{towerrr}"
      , expect_script_error <<'END'
package Tarot1; sub test3 {
  (my MY $foo) = @_;
  $foo->{towerrr}
}
END
	, to_match =>
	  qr/^No such class field "towerrr" in variable \$foo of type Tarot1/;

    it "should create getters automatically", sub {
      my $obj = bless {pentacle => "coin", chariot => "VII", tower => "XVI"}
	, 'Tarot1';
      ok {$obj->pentacle eq "coin"};
      ok {$obj->chariot eq "VII"};
      ok {$obj->tower eq "XVI"};
    };

    it "should not create getters for _private fields", sub {
      my $obj = bless {}, 'Tarot1';
      expect(catch {$obj->_hermit})->to_match(qr/^Can't locate object method "_hermit" via package "Tarot1"/);
    };
  };

  describe "use YOUR_CLASS", sub {
    it "should be used without error", no_error <<'END';
package TarotUser; use Tarot1;
END

    it "should *not* inherit YOUR_CLASS by default", sub {
      ok {@TarotUser::ISA == 0};
    };
  };

  describe "Error checking for pragmas (specs)", sub {
    it "should detect undef", expect_script_error
      q{package SpecError1; use MOP4Import::Declare undef;}
      , to_match => qr/^Undefined pragma!/;

    it "should detect unknown type", expect_script_error
      q{package SpecError2; use MOP4Import::Declare +{'foo' => 'bar'};}
      , to_match => qr/^Invalid pragma: \{'foo' => 'bar'\}/;

    it "should detect invalid import spec", expect_script_error
      q{package SpecError3; use MOP4Import::Declare '_foo';}
      , to_match => qr/^Invalid import spec: _foo/;

    it "should detect unknown pragma", expect_script_error
      q{package SpecError4; use MOP4Import::Declare '-foo';}
      , to_match => qr/^No such pragma: \`use MOP4Import::Declare \['foo'\]\`/;

    it "should detect duplicate fields", expect_script_error
      q{package SpecError5; use MOP4Import::Declare [fields => qw/foo foo/];}
      , to_match => qr/^Duplicate field decl! foo/;

    it "should detect accessor redefinition", expect_script_error
      q{package SpecError6; sub foo {'FOO'}; use MOP4Import::Declare [fields => qw/foo/];}
      , to_match => qr/^Accessor SpecError6::foo is redefined!/;
  };

  my @cards = qw(Ace Chariot Cup Death Devil Emperor Empress Fool Hanged_Man
 Hermit Hierophant High_Priestess Judgement Justice King Knight Lovers
 Magician Moon Page Pentacle Queen Star Strength Sun Sword Temperance
 Tower Wand Wheel_of_Fortune World);

  my $subst = sub {
    (my $str = $_[0])
      =~ s{\@\*SUBST\*\@}{@cards}g;
    $str;
  };

  describe "use YOUR_CLASS -as_base", sub {
    it "should have no error", no_error $subst->(q{
package Tarot2; use Tarot1 -as_base, -inc, [naming => 'Base'];

our @CARDS = qw(@*SUBST*@);

our %CARDS = map {$_ => $_} @CARDS;

our $CARDS = join(" ", @CARDS);

sub CARDS { [reverse @CARDS] }
});

    it "should make Tarot2 as a subclass of Tarot1", sub {
      ok {Tarot2->isa('Tarot1')};
    };

    it "should make Tarot2 as a subclass of MOP4Import::Declare", sub {
      ok {Tarot2->isa('MOP4Import::Declare')};
    };

    it "should define MY alias in Tarot2", sub {
      ok {Tarot2->MY eq 'Tarot2'};
    };

    it "should name Tarot1 Base in Tarot2", sub {
      ok {Tarot2->Base eq 'Tarot1'};
    };

    it "should inherit fields from Tarot1", no_error <<'END';
package Tarot2; sub test2 {
  (my MY $foo) = @_;
  $foo->{pentacle} + $foo->{chariot} + $foo->{tower} + $foo->{_hermit};
}
END

    it "should detect spell miss for Tarot2->{towerrr}"
      , expect_script_error <<'END'
package Tarot2; sub test3 {
  (my MY $foo) = @_;
  $foo->{towerrr}
}
END
	, to_match =>
	  qr/^No such class field "towerrr" in variable \$foo of type Tarot2/;

    it "should keep fields declaration order", sub {
      expect(MOP4Import::Util::fields_array('Tarot2'))->to_be([qw/pentacle chariot tower _hermit/]);
    };

  };

  describe "use YOUR_CLASS [as => 'MyAlias']", sub {
    it "should anve no error", no_error q{
package TarotImport2;
use Tarot1 [as => 'MyTarot'];
};

    it "should create alias for YOUR_CLASS", sub {
      expect(TarotImport2->MyTarot)->to_be('Tarot1');
    };
  };

  describe "Exporter like sigil based import for \$, \@, \% and &", sub {
    it "should have no error", no_error q{
package TarotImport1;
use Tarot2 qw/$CARDS @CARDS %CARDS &CARDS/;
};
    it 'should import @CARDS', sub {
      expect(eval q{package TarotImport1; \@CARDS})->to_be(\@cards);
    };
    it 'should import $CARDS', sub {
      expect(eval q{package TarotImport1; $CARDS})->to_be(join(" ", @cards));
    };
    it 'should import %CARDS', sub {
      expect(eval q{package TarotImport1; \%CARDS})->to_be(+{map {$_ => $_} @cards});
    };
    it 'should import &CARDS', sub {
      expect(eval q{package TarotImport1; CARDS()})->to_be([reverse @cards]);
    };

    it "should raise error for typos", sub {
      expect(do {eval q{package Ng1; use Tarot2 qw/$CAR/;}; $@})->to_match(qr/No such symbol 'CAR' in package Tarot2/);
      expect(do {eval q{package Ng1; use Tarot2 qw/@CAR/;}; $@})->to_match(qr/No such symbol 'CAR' in package Tarot2/);
      expect(do {eval q{package Ng1; use Tarot2 qw/%CAR/;}; $@})->to_match(qr/No such symbol 'CAR' in package Tarot2/);
      expect(do {eval q{package Ng1; use Tarot2 qw/&CAR/;}; $@})->to_match(qr/No such symbol 'CAR' in package Tarot2/);
    };

  };

  describe "Exporter like sigil based import for *", sub {
    it "should have no error", no_error q{
package TarotImportGLOB;
use Tarot2 qw/*CARDS/;
};
    it 'should import @CARDS', sub {
      expect(eval q{package TarotImportGLOB; \@CARDS})->to_be(\@cards);
    };
    it 'should import $CARDS', sub {
      expect(eval q{package TarotImportGLOB; $CARDS})->to_be(join(" ", @cards));
    };
    it 'should import %CARDS', sub {
      expect(eval q{package TarotImportGLOB; \%CARDS})->to_be(+{map {$_ => $_} @cards});
    };
    it 'should import &CARDS', sub {
      expect(eval q{package TarotImportGLOB; CARDS()})->to_be([reverse @cards]);
    };

    it "should raise error for typos", sub {
      expect(do {eval q{package Ng1; use Tarot2 qw/*CAR/;}; $@})->to_match(qr/No such symbol 'CAR' in package Tarot2/);
    };
  };

  describe "Exporter like word import for *", sub {
    it "should have no error", no_error q{
package TarotImportWORD;
use Tarot2 qw/CARDS/;
};
    it 'should import @CARDS', sub {
      expect(eval q{package TarotImportWORD; \@CARDS})->to_be(\@cards);
    };
    it 'should import $CARDS', sub {
      expect(eval q{package TarotImportWORD; $CARDS})->to_be(join(" ", @cards));
    };
    it 'should import %CARDS', sub {
      expect(eval q{package TarotImportWORD; \%CARDS})->to_be(+{map {$_ => $_} @cards});
    };
    it 'should import &CARDS', sub {
      expect(eval q{package TarotImportWORD; CARDS()})->to_be([reverse @cards]);
    };

    it "should raise error for typos", sub {
      expect(do {eval q{package Ng1; use Tarot2 qw/CAR/;}; $@})->to_match(qr/No such symbol 'CAR' in package Tarot2/);
    };
  };

  describe "[import => IMPORT_SPECS...]", sub {
    it "should have no error", no_error q{
package TarotImportViaPragma;
use Tarot2 [import => qw/CARDS/];
};

    it 'should import @CARDS', sub {
      expect(eval q{package TarotImportViaPragma; \@CARDS})->to_be(\@cards);
    };
  };

  describe "[parent => CLASS] pragma", sub {
    it "should raise error for unknown class"
      , expect_script_error q{package Error10; use MOP4Import::Declare [parent => 'UnknownMissingModuleZZZZZ'];}
      , to_match => qr/Can't locate UnknownMissingModuleZZZZZ\.pm/;

    it "should work for valid (loadable) class", sub {
      expect(eval q{package OK4parent; use MOP4Import::Declare [parent => 'Data::Dumper']; our @ISA; \@ISA})->to_be(['Data::Dumper']);
    };
  };

  describe "Safe multiple inheritance with c3 mro", sub {
    describe "use Generic -as_base; use Specific -as_base;", sub {
      it "should have no error", no_error <<'END';
package TarotUserC3;
use Tarot1 -as_base;
use Tarot2 -as_base;
END

      it "should have c3 mro", sub {
	expect(mro::get_mro('TarotUserC3'))->to_be('c3');
      };
    };

    describe "use Specific -as_base; use Generic -as_base;", sub {
      it "should raise (better) error", sub {
	local $@;
	if ($] >= 5.014) {
	  expect(do {eval q{package Ng2;use Tarot2 -as_base;use Tarot1 -as_base;}; $@}
	       )->to_match(qr/^Can't add base 'Tarot1' to 'Ng2'/);
	} else {
	  # skip...
	}
      };
    };
  };

  describe "use .. [fields [f => \@spec],...]", sub {
    describe "YourClass->FieldSpec typename", sub {
      it "should be accesible as a typename method", sub {
	ok {Tarot2->FieldSpec eq MOP4Import::Declare->FieldSpec};
      };
    };

    describe "FieldSpec->name", sub {
      it "should be defined", sub {
	expect(eval q{$Tarot2::FIELDS{tower}{name}})->to_be('tower');
      };
    };

    describe "spec: doc => 'help mesage'", sub {
      it "should be accepted"
	, no_error q{package F_doc; use Tarot2 [fields => [f => doc => 'help mesage']]};

      it "should be set correctly", sub {
	expect(eval q{$F_doc::FIELDS{f}{doc}})->to_be('help mesage');
      };
    };

    describe "spec: default => 'value'", sub {
      it "should be accepted"
	, no_error q{package F_def; use Tarot2 [fields => [f => default => 'defval']]};

      describe "YourClass->default_FNAME", sub {
	it "should return default value", sub {
	  ok {F_def->default_f eq 'defval'};
	};
      };
    };

    describe "spec: no_getter => 1", sub {
      it "should be accepted"
	, no_error q{package F_nog; use Tarot2 [fields => [f => no_getter => 1]]};

      it "should define field F_nog->{f}", no_error <<'END';
sub test {(my F_nog $obj) = @_; $obj->{f}}
END

      it "should not have a getter", sub {
	expect(F_nog->can("f"))->to_be(undef);
      };
    };

    describe "unknown spec name", sub {
      it "should raise error", expect_script_error
	q{package F_unk; use Tarot2 [fields => [f => unknown => 1]]}
	, to_match => qr/^Unknown option for F_unk.f in F_unk/;
    };
  };
};

done_testing();
