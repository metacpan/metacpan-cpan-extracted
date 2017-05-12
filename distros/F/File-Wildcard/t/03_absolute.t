# -*- perl -*-

# t/03_absolute.t - Absolute file spec test

use strict;
use Test::More;

BEGIN {
    if ( $^O =~ /vms/i ) {
        plan skip_all => "Cannot test absolute POSIX files on this platform";
    }
    else {
        plan tests => 19;
    }

    #01
    use_ok('File::Wildcard');
}

use File::Spec;

my $debug = $ENV{FILE_WILDCARD_DEBUG} || 0;

my $temp = File::Spec->tmpdir . '/File-Wildcard-test';
$temp =~ s!\\!/!g;    # for Windows silly slash direction

# Just in case the temp directory is lying around...

if ( -e $temp ) {
    my $wcrm = File::Wildcard->new(
        path           => "$temp///",
        ellipsis_order => "inside-out"
    );
    for ( $wcrm->all ) {
        if ( -d $_ ) {
            rmdir $_;
        }
        else {
            1 while unlink $_;
        }
    }
}

mkdir $temp;
mkdir "$temp/abs";
mkdir "$temp/abs/foo";
mkdir "$temp/abs/bar";

open FOO, ">$temp/abs/foo/lish.tmp";
close FOO;
open FOO, ">$temp/abs/bar/drink.tmp";
close FOO;

# Force the case sensitivity for absolute files
# as it says in the docs

my $sens = Filesys::Type::case($temp) ne 'sensitive';

my $mods = File::Wildcard->new(
    path             => "$temp/abs/foo/lish.tmp",
    case_insensitive => $sens,
    debug            => $debug
);

#02
isa_ok( $mods, 'File::Wildcard', "return from new" );

#03
like( $mods->next, qr"$temp/abs/foo/lish.tmp"i, 'Simple case, no wildcard' );

#04
ok( !$mods->next, 'Only found one file' );

my ( $junk, @chunks ) = split m'/', "$temp/abs/*/*.tmp";

$mods = File::Wildcard->new(
    path             => \@chunks,
    case_insensitive => $sens,
    debug            => $debug,
    absolute         => 1,
    sort             => 1
);

#05
isa_ok( $mods, 'File::Wildcard', "return from new" );

my @found = $mods->all;

SKIP:
{
    skip 'This test unreliable on Windows', 1 if $^O =~ /win/i;

    #06
    is_deeply(
        \@found,
        [ "$temp/abs/bar/drink.tmp", "$temp/abs/foo/lish.tmp" ],
        'Wildcard in filename'
    );
}

$mods = File::Wildcard->new(
    path             => "$temp///*.tmp",
    case_insensitive => $sens,
    debug            => $debug,
    sort             => 1
);

#07
isa_ok( $mods, 'File::Wildcard', "(ellipsis) return from new" );

@found = $mods->all;

#08
is_deeply(
    \@found,
    [ "$temp/abs/bar/drink.tmp", "$temp/abs/foo/lish.tmp" ],
    'Ellipsis found tmp files'
);

$mods = File::Wildcard->new(
    path             => "$temp///",
    case_insensitive => $sens,
    debug            => $debug,
    sort             => 1
);

#09
isa_ok( $mods, 'File::Wildcard', "(ellipsis) return from new" );

@found = $mods->all;

#10
is_deeply(
    \@found,
    [   "$temp/",         "$temp/abs/",
        "$temp/abs/bar/", "$temp/abs/bar/drink.tmp",
        "$temp/abs/foo/", "$temp/abs/foo/lish.tmp",
    ],
    'Recursive directory search (normal)'
);

$mods = File::Wildcard->new(
    path             => "$temp///",
    case_insensitive => $sens,
    debug            => $debug,
    sort             => sub { $_[1] cmp $_[0] }
);

#11
isa_ok( $mods, 'File::Wildcard', "(ellipsis) return from new" );

@found = $mods->all;

#12
is_deeply(
    \@found,
    [   "$temp/",         "$temp/abs/",
        "$temp/abs/foo/", "$temp/abs/foo/lish.tmp",
        "$temp/abs/bar/", "$temp/abs/bar/drink.tmp",
    ],
    'Recursive directory search (custom sort)'
);

$mods = File::Wildcard->new(
    path             => "$temp///",
    case_insensitive => $sens,
    debug            => $debug,
    sort             => 1,
    ellipsis_order   => 'breadth-first'
);

#13
isa_ok( $mods, 'File::Wildcard', "(ellipsis) return from new" );

@found = $mods->all;

# Note that breadth-first skips the topmost level
# I have not found an easy way round this.

#14
is_deeply(
    \@found,
    [   "$temp/abs/",     "$temp/abs/bar/",
        "$temp/abs/foo/", "$temp/abs/bar/drink.tmp",
        "$temp/abs/foo/lish.tmp",
    ],
    'Recursive directory search (breadth-first)'
);

# Append absolute bug

$mods = File::Wildcard->new(
    debug => $debug,
    sort  => 1
);

$mods->append( path => "$temp///*.tmp" );

@found = $mods->all;

#15
is_deeply(
    \@found,
    [ "$temp/abs/bar/drink.tmp", "$temp/abs/foo/lish.tmp" ],
    "Appended absolute"
);

$mods = File::Wildcard->new(
    path             => "$temp///",
    case_insensitive => $sens,
    debug            => $debug,
    sort             => 1,
    ellipsis_order   => 'inside-out'
);

#16
isa_ok( $mods, 'File::Wildcard', "(ellipsis) return from new" );

@found = $mods->all;

#17
is_deeply(
    \@found,
    [   "$temp/abs/bar/drink.tmp", "$temp/abs/bar/",
        "$temp/abs/foo/lish.tmp",  "$temp/abs/foo/",
        "$temp/abs/",              "$temp/",
    ],
    'Recursive directory search (inside-out)'
);

$mods->append( path => "$temp///" );
@found = $mods->all;

#18
is_deeply(
    \@found,
    [   "$temp/abs/bar/drink.tmp", "$temp/abs/bar/",
        "$temp/abs/foo/lish.tmp",  "$temp/abs/foo/",
        "$temp/abs/",              "$temp/",
    ],
    'Append to absolute'
);

# Tidy up after tests

for (@found) {
    if ( -d $_ ) {
        rmdir $_;
    }
    else {
        1 while unlink $_;
    }
}

rmdir $temp;

#19
ok( !-e $temp, "Test has tidied up after itself" );
