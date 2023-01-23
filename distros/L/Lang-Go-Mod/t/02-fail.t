package main;
use File::Spec;
use Test2::V0;
use Lang::Go::Mod qw(parse_go_mod);

my $go_version = 'go 1.16';
my $module     = 'module github.com/user/example';

my $missing_module = <<"MISSING_MODULE";
$go_version
MISSING_MODULE
ok(
    dies {
        parse_go_mod($missing_module);
    }
  ) or note($@);

my $missing_go = <<"MISSING_GO";
$module
MISSING_GO
ok(
    dies {
        parse_go_mod($missing_go);
    }
  ) or note($@);

# this doesn't fail but demonstrates the "minimum viable go.mod"
my $minimal = <<"MINIMAL";
$module
$go_version
MINIMAL
ok(
    lives {
        parse_go_mod($minimal);
    }
  ) or note($@);

my $typo_exclude = <<"TYPO_EXCLUDE";
$minimal
excude example.com/thismodule v1.3.0
TYPO_EXCLUDE
ok(
    dies {
        parse_go_mod($typo_exclude);
    }
  ) or note($@);

my $typo_replace = <<"TYPO_REPLACE";
$minimal
repace github.com/example/my-project/pkg/old => ./pkg/new
TYPO_REPLACE
ok(
    dies {
        parse_go_mod($typo_replace);
    }
  ) or note($@);

my $typo_require = <<"TYPO_REQUIRE";
$minimal
requir github.com/example/greatmodule v1.1.1
TYPO_REQUIRE
ok(
    dies {
        parse_go_mod($typo_require);
    }
  ) or note($@);

my $malformed_exclude = <<"MALFORMED_EXCLUDE";
$minimal
exclude example.com/thismodule 
MALFORMED_EXCLUDE
ok(
    dies {
        parse_go_mod($malformed_exclude);
    }
  ) or note($@);

my $malformed_replace = <<"MALFORMED_REPLACE";
$minimal
replace github.com/example/my-project/pkg/old
MALFORMED_REPLACE
ok(
    dies {
        parse_go_mod($malformed_replace);
    }
  ) or note($@);

my $malformed_require = <<"MALFORMED_REQUIRE";
$minimal
require github.com/example/greatmodule
MALFORMED_REQUIRE
ok(
    dies {
        parse_go_mod($malformed_require);
    }
  ) or note($@);

my $malformed_multi_exclude = <<"MALFORMED_MULTI_EXCLUDE";
$minimal
exclude (
  example.com/thismodule 

MALFORMED_MULTI_EXCLUDE
ok(
    dies {
        parse_go_mod($malformed_multi_exclude);
    }
  ) or note($@);

my $malformed_multi_replace = <<"MALFORMED_MULTI_REPLACE";
$minimal
replace (
  github.com/example/my-project/pkg/old

MALFORMED_MULTI_REPLACE
ok(
    dies {
        parse_go_mod($malformed_multi_replace);
    }
  ) or note($@);

my $malformed_multi_require = <<"MALFORMED_MULTI_REQUIRE";
$minimal
require (
  github.com/example/greatmodule

MALFORMED_MULTI_REQUIRE
ok(
    dies {
        parse_go_mod($malformed_multi_require);
    }
  ) or note($@);

done_testing;

1;
