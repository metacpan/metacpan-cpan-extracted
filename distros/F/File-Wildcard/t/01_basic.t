# -*- perl -*-

# t/01_basic.t - basic tests

use strict;
use Test::More tests => 35;

my $dbf;
my $debug = open $dbf, '>', 'debug.out';

if ( $ENV{FILE_WILDCARD_DEBUG} ) {
    close $dbf;
    $dbf = \*STDERR;
}

BEGIN {
    local $ENV{MODULE_OPTIONAL_SKIP} = 1;

    #01
    use_ok('File::Wildcard');
}

# Run in both case sensitive and insensitive mode
for my $insens ( 0, 1 ) {

    my $mods = File::Wildcard->new(
        path             => 'lib/File/Wildcard.pm',
        case_insensitive => $insens,
        debug_output     => $dbf,
        debug            => $debug
    );

    #02
    isa_ok( $mods, 'File::Wildcard', "return from new" );

    #03
    like( $mods->next, qr'lib/File/Wildcard.pm'i,
        'Simple case, no wildcard' );

    #04
    ok( !$mods->next, 'Only found one file' );

    my @dirs = split m'/', 'lib/File/Wildcard.*';

    $mods = File::Wildcard->new(
        path             => \@dirs,
        absolute         => 0,
        case_insensitive => $insens,
        debug_output     => $dbf,
        debug            => $debug
    );

    #05
    isa_ok( $mods, 'File::Wildcard', "return from new" );

    #06
    like( $mods->next, qr'lib/File/Wildcard\.pm'i, 'Simple asterisk' );

    #07
    ok( !$mods->next, 'Only found one file' );

    $mods = File::Wildcard->new(
        path             => 'lib/File/Wild????.pm',
        case_insensitive => $insens,
        debug_output     => $dbf,
        debug            => $debug
    );

    #08
    isa_ok( $mods, 'File::Wildcard', "return from new" );

    #09
    like( $mods->next, qr'lib/File/Wildcard\.pm'i, 'single char wildcards' );

    #10
    ok( !$mods->next, 'Only found one file' );

    $mods = File::Wildcard->new(
        path             => 'lib/F*/Wildcard.pm',
        case_insensitive => $insens,
        debug_output     => $dbf,
        debug            => $debug
    );

    my $match = $mods->match;
    my @capts = $match =~ /\(.+?\)/;

    #11
    is( scalar(@capts), 1, "Captures from regexp" );

    #12
    isa_ok( $mods, 'File::Wildcard', "return from new" );

    my @found = map { lc $_ } $mods->all;

    #13
    is_deeply(
        \@found,
        [qw( lib/file/wildcard.pm )],
        'Wildcard further back in path'
    );

    $mods = File::Wildcard->new(
        path             => './//Wildcard.pm',
        case_insensitive => $insens,
        debug_output     => $dbf,
        debug            => $debug,
        sort             => 1
    );

    #14
    isa_ok( $mods, 'File::Wildcard', "(ellipsis) return from new" );

    @found = map { lc $_ } $mods->all;

    #15
    is_deeply(
        \@found,
        [qw( blib/lib/file/wildcard.pm lib/file/wildcard.pm )],
        'Ellipsis found blib and lib modules'
    );

    # play it again, Sam

    $mods->reset;
    @found = map { lc $_ } $mods->all;

    #16
    is_deeply(
        \@found,
        [qw( blib/lib/file/wildcard.pm lib/file/wildcard.pm )],
        'Ellipsis found blib and lib modules'
    );

    $mods = File::Wildcard->new(
        path             => './//Wildcard.pm',
        case_insensitive => $insens,
        debug_output     => $dbf,
        debug            => $debug,
        exclude          => qr/^blib/,
        sort             => 1
    );

    #17
    isa_ok( $mods, 'File::Wildcard', "(ellipsis) return from new" );

    @found = map { lc $_ } $mods->all;

    #18
    is_deeply(
        \@found,
        [qw( lib/file/wildcard.pm )],
        'Ellipsis found lib, blib excluded'
    );
}

undef $dbf;
unlink 'debug.out';
