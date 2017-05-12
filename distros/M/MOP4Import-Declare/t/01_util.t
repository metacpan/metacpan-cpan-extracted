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

use MOP4Import::Util
  qw/fields_hash fields_array fields_symbol
     lexpand
     globref
     isa_array
     extract_fields_as
    /;

describe "MOP4Import::Util", sub {
  describe "fields", sub {

    my @space_missions = qw{
                             Salyut
                             Antares
                             ISS
                             Ilan_Ramon
                             Semyorka
                             Michael_P_Anderson
                             Friendship7
                             Challenger
                         };
    my %space_missions = map {(lc($_) => $_)} @space_missions;
    {
      package SpaceMissions;
      our %FIELDS = map {(lc($_) => $_)} @space_missions;
      our @FIELDS = @space_missions;
    }

    describe "fields_hash, fields_array, fields_symbol", sub {
      expect(fields_hash('SpaceMissions'))->to_be(\%space_missions);
      expect(fields_array('SpaceMissions'))->to_be(\@space_missions);
      expect(*{fields_symbol('SpaceMissions')}{HASH})->to_be(\%space_missions);
      ok {fields_symbol('SpaceMissions') == globref('SpaceMissions', 'FIELDS')};
    };

    my @more_space_missions = (@space_missions
                               , qw{
                                     Vladislav_Volkov
                                     Start
                                     Diamant
                                     Sigma7
                                     Agena
                                 });
    {
      package MoreSpaceMissions;
      our @ISA = 'SpaceMissions';
      our %FIELDS = map {(lc($_) => $_)} @more_space_missions;
    }

    describe "extract_fields_as(BASE_CLASS, \$obj)", sub {
      it "should only extract common fields found in base class", sub {
	my $rec = +{map {lc($_) => $_} @more_space_missions};
	expect(+{extract_fields_as 'SpaceMissions', $rec})->to_be(\%space_missions);
      };
    };

    describe "isa_array", sub {
      it "should extract \@ISA", sub {
	expect(isa_array('MoreSpaceMissions'))->to_be(['SpaceMissions']);
      };
    };
  };

  describe "lexpand", sub {
    it "should return empty list for undef", sub {
      expect([lexpand(undef)])->to_be([]);
    };

    it "should return single item for other types", sub {
      expect([lexpand('')])->to_be(['']);
      expect([lexpand('foo')])->to_be(['foo']);
      expect([lexpand(+{bar => 'baz'})])->to_be([+{bar => 'baz'}]);
    };
  };

  describe "parse_opts", sub {
    my $CLS = 'MOP4Import::Util';

    describe "in simple case", sub {
      it "should accept empty list", sub {
	expect([$CLS->parse_opts([])])->to_be([]);
      };

      it "should return safely when undef found", sub {
	my @list = (qw!--foo=bar!, undef, '--baz');
	expect([$CLS->parse_opts(\@list)])->to_be([foo => 'bar']);
	expect(\@list)->to_be([undef, '--baz']);
      };

      my @list = qw(--debug --verbose=3 -- --other);
      it "should parse posix style options", sub {
	expect([$CLS->parse_opts(\@list)])->to_be([qw/debug 1 verbose 3/]);
      };
      it "should reserve elements after --", sub {
	expect(\@list)->to_be([qw/--other/]);
      };
    };

    describe "HASH result", sub {
      it "should return hash when called from scalar context", sub {
	expect(scalar $CLS->parse_opts([qw/--foo --bar=3/]))->to_be(+{foo => 1, bar => 3});
      };

    };

    describe "given result", sub {

      it "should return given ARRAY when it is given", sub {
	my $obj = [];
	ok {$CLS->parse_opts([qw/--foo --bar=3/], $obj) == $obj};
	expect($obj)->to_be([foo => 1, bar => 3]);
      };

      it "should return given HASH when it is given", sub {
	my $obj = +{};
	ok {$CLS->parse_opts([qw/--foo --bar=3/], $obj) == $obj};
	expect($obj)->to_be(+{foo => 1, bar => 3});
      };

      it "should return given hash even when called from list context", sub {
	expect($CLS->parse_opts([qw/--foo --bar=3/], +{}))->to_be(+{foo => 1, bar => 3});
      };

      it "should return given array without expanding even when called from list context", sub {
	expect($CLS->parse_opts([qw/--foo --bar=3/], +{}))->to_be(+{foo => 1, bar => 3});
      };
    };

    describe "allowed chars for option name", sub {

      # Note: - is allowed for parse_opts, but not allowed
      #  in MOP4Import::Declare->declare_fields.
      it "should accept -", sub {
	expect([$CLS->parse_opts([qw!--git-dir=/var/lib/git/foo.git
				     --no-pager
				     --info-path=/usr/share/info
				    !])])->to_be([qw!git-dir /var/lib/git/foo.git
						     no-pager 1
						     info-path /usr/share/info
						    !]);
      };

      it "should accept .", sub {
	expect([$CLS->parse_opts([qw!--user.name=foobar
				     --user.email=baz@example.com
				    !])])->to_be([qw!user.name foobar
						     user.email baz@example.com
						    !]);
      };
    };

    describe "option alias", sub {
      my %alias = qw!v verbose d debug!;
      it "should accept -v, -d when alias spec is given", sub {
	expect([$CLS->parse_opts([qw!-v -d!], undef, \%alias)])->to_be([qw/verbose 1 debug 1/]);
      };
    };
  };

  describe "take_hash_opts_maybe", sub {
    my $CLS = 'MOP4Import::Util';

    describe "when first argument is a HASH", sub {
      it "should take first hash from given list", sub {
	my @list = (my $h = +{foo => 'bar'}, '--baz=qux');
	ok {$CLS->take_hash_opts_maybe(\@list) == $h};
	expect(\@list)->to_be(['--baz=qux']);
      };
    };

    describe "otherwise", sub {
      it "should behave exactly same as normal parse_opts", sub {
	expect([$CLS->take_hash_opts_maybe([])])->to_be([]);

	it "should return safely when undef found", sub {
	  my @list = (qw!--foo=bar!, undef, '--baz');
	  expect([$CLS->take_hash_opts_maybe(\@list)])->to_be([foo => 'bar']);
	  expect(\@list)->to_be([undef, '--baz']);
	};

	my @list = qw(--debug --verbose=3 -- --other);
	it "should parse posix style options", sub {
	  expect([$CLS->take_hash_opts_maybe(\@list)])->to_be([qw/debug 1 verbose 3/]);
	};
	it "should reserve elements after --", sub {
	  expect(\@list)->to_be([qw/--other/]);
	};
      };
    };
  };

  describe "parse_pairlist", sub {
    my $CLS = 'MOP4Import::Util';

    describe "in simple case", sub {
      it "should accept empty list", sub {
	expect([$CLS->parse_pairlist([])])->to_be([]);
      };

      it "should return safely when undef found", sub {
	my @list = (qw!foo=bar!, undef, 'baz=qux');
	expect([$CLS->parse_pairlist(\@list)])->to_be([foo => 'bar']);
	expect(\@list)->to_be([undef, 'baz=qux']);
      };

      my @list = qw(debug= verbose=3 other elements);
      it "should parse posix style options", sub {
	expect([$CLS->parse_pairlist(\@list)])->to_be([debug => '', verbose => 3]);
      };
      it "should reserve unknown elements", sub {
	expect(\@list)->to_be([qw/other elements/]);
      };
    };

    describe "boxing option", sub {
      it "should accept empty list", sub {
	expect([$CLS->parse_pairlist([], 1)])->to_be([]);
      };

      it "should return safely when undef found", sub {
	my @list = (qw!foo=bar!, undef, 'baz=qux');
	expect([$CLS->parse_pairlist(\@list, 1)])->to_be([[foo => 'bar']]);
	expect(\@list)->to_be([undef, 'baz=qux']);
      };

      my @list = qw(debug= verbose=3 other elements);
      it "should parse posix style options", sub {
	expect([$CLS->parse_pairlist(\@list, 1)])->to_be([[debug => ''], [verbose => 3]]);
      };
      it "should reserve unknown elements", sub {
	expect(\@list)->to_be([qw/other elements/]);
      };
    };
  };
};

done_testing();
