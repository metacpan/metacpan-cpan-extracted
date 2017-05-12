use strict;
use warnings;

use Test::More;

plan skip_all => "Not a Linux machine" if $^O ne 'linux';

use POSIX qw/ ceil /;

use_ok 'Linux::Statm::Tiny';

my %stats = (
    size     => 0,
    resident => 1,
    share    => 2,
    text     => 3,
    data     => 5,
    vsz      => 0,
    rss      => 1,
    );

my $psz = `getconf PAGE_SIZE`;
chomp($psz);

my %mults = (
    pages    => 1,
    bytes    => $psz,
    kb       => $psz / 1024,
    mb       => $psz / (1024 * 1024),
    );


ok my $stat = Linux::Statm::Tiny->new(), 'new';

test_stats($stat);

$stat->refresh;

test_stats($stat);

sub test_stats {
    my ($stat) = @_;

    is $stat->page_size, $psz, 'page_size';

    note( explain $stat->statm );

    foreach my $key (keys %stats) {
        can_ok $stat, $key;
        note "${key} = " . $stat->$key;
        is $stat->$key, $stat->statm->[$stats{$key}], $key;

        my $alt = "${key}_pages";
        is $stat->$alt, $stat->$key, $alt;

        foreach my $type (keys %mults) {
            my $name = "${key}_${type}";
            ok my $method = $stat->can($name), "can ${name}";
            is $stat->$method, ceil($stat->$key * $mults{$type}), $name;
            }

        }

    is $stat->vsz, $stat->size, 'vsz';
    is $stat->rss, $stat->resident, 'rss';
    }

done_testing;
