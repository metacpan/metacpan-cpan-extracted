# -*- perl -*-

# t/05_symlink.t - Symbolic link processing

use strict;
use Test::More;
use Cwd;

BEGIN {
    eval "symlink cwd, 't/sym_up'";

    if ($@) {
        plan skip_all => "Symbolic links not available: $@";
    }
    else {
        plan tests => 8;
    }

    #01:
    use_ok('File::Wildcard');
}

my $debug = $ENV{FILE_WILDCARD_DEBUG} || 0;

my $mods = File::Wildcard->new(
    path    => './//*sym*',
    sort    => 1,
    exclude => qr{/\.},
    debug   => $debug
);

$mods->match(qr/sym/);

#02
isa_ok( $mods, 'File::Wildcard', "return from new" );

#03
like( $mods->next, qr't/05_symlink.t'i, 'Found the test itself' );

#04
like( $mods->next, qr't/sym_up'i, 'Sym link' );

#05
ok( !$mods->next, 'And no more' );

$mods = File::Wildcard->new(
    path  => 't///Changes',
    sort  => 1,
    debug => $debug
);

#06
ok( !$mods->next, 'Nothing found' );

$mods = File::Wildcard->new(
    path   => 't///Changes',
    sort   => 1,
    follow => 1,
    debug  => $debug
);

#07
like( $mods->next, qr't/sym_up/Changes'i, 'Followed sym link' );

#08
ok( !$mods->next, 'Nothing more' );

END {
    unlink 't/sym_up';
}
