#!perl 
use warnings;
use strict;

use Data::Dumper;
use Test::More;
use Test::Trap;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $des = Devel::Examine::Subs->new(
                            file => 't/sample.data',
                            extensions => [qw(pl pm)],
                            copy => 'this.test',
                            no_indent => 0,
                            regex => 1,
                            diff => 1,
                            cache => 0,
                            include => [],
                            exclude => [],
                            hello => 'world',
                            goodbye => 'world',
                            search => 'this',
                          );

is (keys %{$des->{params}}, 11, "config retains only valid params on init");

$des->has(); # use above params
$des->has(); # at start of this run, params are cleaned out

is (keys %{$des->{params}}, 8, "config dumps non-persistent params on " .
                               "subsequent runs");

is (keys %{$des->{params}}, 8, "config retains all specified persistent " .
                               "params");

my @persistent = qw(file extensions cache copy no_indent regex diff backup);

### NOTE: if the following test fails for a new transient param,
### be sure to check if you need to put it in _clean_core_config()
### as these vars won't be cleaned if set after _config()

for my $p (keys %{$des->{params}}){
    ok ((grep {$p eq $_} @persistent), "$p is a valid persistent param");
}

done_testing();
