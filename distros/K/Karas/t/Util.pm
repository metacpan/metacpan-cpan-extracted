package t::Util;
use strict;
use warnings;
use utf8;
use parent qw/Exporter/;
use Karas;

our @EXPORT = qw/create_karas/;

sub create_karas {
    require Test::Requires;
    Test::Requires->import('DBD::SQLite');
    my $db = Karas->new(
        connect_info => ['dbi:SQLite::memory:'],
        row_class_map => {},
    );
    return $db;
}

1;

