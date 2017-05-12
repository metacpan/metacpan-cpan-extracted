# -*- perl -*-

# t/04_append.t - Tests for multiwildcard append and prepend

use strict;
use Test::More tests => 6;

my $debug = $ENV{FILE_WILDCARD_DEBUG} || 0;

#01
BEGIN { use_ok('File::Wildcard'); }

my $mods = File::Wildcard->new( debug => $debug );

#02
isa_ok( $mods, 'File::Wildcard', "return from new" );

#03
ok( !$mods->next, 'Empty object gives no files' );

$mods->append( path => 'lib///Wildcard.pm' );
$mods->append( path => './//04*.t' );

my @found = map { lc $_ } $mods->all;

#04
is_deeply(
    \@found,
    [   qw( lib/file/wildcard.pm
            t/04_append.t )
    ],
    'Appended wildcards'
);

$mods->prepend( path => './//04*.t' );
$mods->prepend( path => 'lib///Wildcard.pm' );

@found = map { lc $_ } $mods->all;

#05
is_deeply(
    \@found,
    [   qw( lib/file/wildcard.pm
            t/04_append.t )
    ],
    'Prepended wildcards'
);

$mods->append( path => 'lib/File///' );
$mods->match(qr{ \Alib/File/(.*rd)\.pm\z }xms);
@found = map { lc $_ } $mods->all;

#06
is_deeply( \@found, [qw( lib/file/wildcard.pm)], 'Append with match' );
