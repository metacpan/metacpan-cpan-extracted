# -*- perl -*-

# t/02_derived.t - Wildcards with captures

use strict;
use Test::More tests => 6;

my $debug = $ENV{FILE_WILDCARD_DEBUG} || 0;

#01
BEGIN { use_ok('File::Wildcard'); }

my $mods = File::Wildcard->new(
    path   => './//*.pm',
    derive => ['$1/$2.tmp'],
    debug  => $debug,
    sort   => 1
);

#02
isa_ok( $mods, 'File::Wildcard', "return from new" );

my @found = map {
    [ map { lc $_ } @$_ ]
} $mods->all;

#03
is_deeply(
    \@found,
    [   [qw( blib/lib/file/wildcard.pm blib/lib/file/wildcard.tmp )],
        [qw( blib/lib/file/wildcard/find.pm blib/lib/file/wildcard/find.tmp)],
        [qw( lib/file/wildcard.pm lib/file/wildcard.tmp)],
        [qw( lib/file/wildcard/find.pm lib/file/wildcard/find.tmp)],
    ],
    'Returned expected derived list'
);

$mods = File::Wildcard->new(
    path   => [ split m'/', 'lib/File/Wild????.*' ],
    derive => ['Playing$1.$2'],
    debug  => $debug
);

#04
isa_ok( $mods, 'File::Wildcard', "return from new" );

@found = map { lc $_ } @{ $mods->next };

#05
is_deeply(
    \@found,
    [qw( lib/file/wildcard.pm playingcard.pm )],
    'Multiple patterns in the same component'
);

#06
ok( !$mods->next, 'Only one match' );
