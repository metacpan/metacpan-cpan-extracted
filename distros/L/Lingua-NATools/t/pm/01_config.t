# -*- cperl -*-

use Test::More tests => 12;

use_ok "Lingua::NATools::Config";

unlink "zbr" if -f "zbr"; # just in case some old test is around

my $config = Lingua::NATools::Config->new();
isa_ok $config, "Lingua::NATools::Config";

is $config->param("foo"), undef;

$config->param("bar", "foo");

is($config->param("foo"), undef);
is($config->param("bar"), "foo");

$config->param("long-key", "big entry with spaces");

is($config->param("long-key"), "big entry with spaces");

$config->write("zbr");

ok(-f "zbr");

my $other = Lingua::NATools::Config->new("zbr");
isa_ok $other, "Lingua::NATools::Config";

is($other->param("foo"), undef);
is($other->param("bar"), "foo");
is($other->param("long-key"), "big entry with spaces");

$other->param("zbr", 0);
is($other->param("zbr"),0);

unlink "zbr";
