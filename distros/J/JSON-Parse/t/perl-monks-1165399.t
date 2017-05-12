# http://perlmonks.org/?node_id=1165399
# https://github.com/benkasminbullock/JSON-Parse/issues/34

use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use Data::Dumper;
use JSON::Parse;

my $j = JSON::Parse->new();
# no complain, no effect:
$j->warn_only(1);

# legal json:
eval {
    my $pl = $j->run('{"k":"v"}');
};
ok (! $@);

# illegal json, the following statement dies:
my $warning;

$SIG{__WARN__} = sub { $warning = "@_" };
eval {
    my $pl = $j->run('illegal json');
};
ok (! $@, "No fatal error");
ok ($warning, "Got warning");

undef $SIG{__WARN__};

done_testing ();
