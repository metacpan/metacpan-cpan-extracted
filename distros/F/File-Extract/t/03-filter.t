use strict;
use Test::More (tests => 2);

use File::Extract;
use File::Extract::Filter::Exec;

my $extract = File::Extract->new(
    output_encoding => 'euc-jp',
    filters => {
        'text/plain' => [
            File::Extract::Filter::Exec->new(cmd => "$^X -pe 's/^/\$. /'")
        ]
    },
);
my $r = $extract->extract(__FILE__);

ok($r, "valid result returned");
my @p = grep { !/^\d+ / } split(/\n/, $r->text);
ok(!@p, "text has line numbers");
