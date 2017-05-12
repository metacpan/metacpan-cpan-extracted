#!/usr/bin/perl

# Basic test for JSAN::Index

use strict;
BEGIN {
    $|  = 1;
    $^W = 1;
}

use Test::More;
use Params::Util qw{ _HASH _HASHLIKE };
use File::Remove 'remove';
use LWP::Online  'online';

BEGIN { remove( \1, 'temp' ) if -e 'temp'; }
END   { remove( \1, 'temp' ) if -e 'temp'; }

use JSAN::Index;

JSAN::Index->init({
    mirror_local => 'temp',
    prune => 1
});


if ( online() ) {
    plan( tests => 52 );
} else {
    plan( skip_all => "Skipping online tests" );
    exit(0);
}





#####################################################################
# Testing ::Author

# Test a known-good author
SCOPE: {
    my $adamk = JSAN::Index::Author->retrieve( login => 'adamk' );
    isa_ok( $adamk,        'JSAN::Index::Author' );
    is(     $adamk->login, 'adamk',                            'Author->login returns as expected'        );
    is(     $adamk->name,  'Adam Kennedy',                     'Author->name returns as expected'         );
    like(   $adamk->doc,   qr{^/},                             'Author->doc returns a root-relative path' );
    like(   $adamk->email, qr{^[\w.-]+\@[\w-]+(?:\.[\w-]+)*$}, 'Author->email returns an email address'   );
    like(   $adamk->url,   qr{^http://},                        'Author->url returns a URI'                );
    my @releases = @{$adamk->releases};
    ok( scalar(@releases), '->releases works' );
    isa_ok( $releases[0], 'JSAN::Index::Release');
}





#####################################################################
# Testing ::Distribution

# Test a known-good distribution
SCOPE: {
    my $swapdist = JSAN::Index::Distribution->retrieve( name => 'Display.Swap' );
    isa_ok( $swapdist, 'JSAN::Index::Distribution' );
    is(   $swapdist->name,    'Display.Swap', 'Distribution->name matches expected' );
    like( $swapdist->doc,     qr{^/},         'Distribution->doc returns a root-relative path' );
    my @releases = @{$swapdist->releases};
    ok( scalar(@releases), '->releases works' );
    isa_ok( $releases[0], 'JSAN::Index::Release');
    isa_ok( $swapdist->latest_release, 'JSAN::Index::Release'      );
    # Is extractable
    can_ok( $swapdist, 'extract_libs', 'extract_tests', 'extract_resource' );
}





#####################################################################
# Testing ::Release

#####################################################################
# Find a known release
my $swaprel = JSAN::Index::Release->retrieve(
    source => '/dist/a/ad/adamk/Display.Swap-0.01.tar.gz',
);
isa_ok( $swaprel,               'JSAN::Index::Release'      );
isa_ok( $swaprel->distribution, 'JSAN::Index::Distribution' );
isa_ok( $swaprel->author,       'JSAN::Index::Author'       );
ok(     $swaprel->source,       '::Release has a ->source'  );


#####################################################################
# Clear out any existing file
my $swaprel_file = $swaprel->file_path;
ok( $swaprel_file, '::Release->file_path returns a value' );

SKIP: {
    skip( "Don't need to predelete file", 2 ) unless -f $swaprel_file;
    ok(
        scalar(remove( \1, $swaprel_file )),
        "Removing existing release file $swaprel_file",
    );
    ok( ! -f $swaprel_file, 'File was removed' );
}
is( $swaprel->file_mirrored, '', '::Release->file_mirrored returns false when no file' );


#####################################################################
# Attempt to mirror the file twice. This should exercise both the normal
# and shortcut logic.
is( $swaprel->mirror, $swaprel_file, '->mirror returns the file path' );
ok( -f $swaprel_file, "->mirror actually fetched file" );
ok( $swaprel->file_mirrored, '::Release->file_mirrored returns true when file exists' );
is( $swaprel->mirror, $swaprel_file, '->mirror return the file path on the second (shortcut) call' );


#####################################################################
# Get the archive object directly
isa_ok( $swaprel->archive, 'Archive::Tar' );


#####################################################################
# Load the META.yaml data for the release
my $meta = $swaprel->meta_data;
ok( _HASHLIKE($meta), '::Release->meta_data returns a HASH' );


#####################################################################
# Is it extractable
can_ok( $swaprel, 'extract_libs', 'extract_tests', 'extract_resource' );


#####################################################################
# Can we find its dependencies
is_deeply( scalar($swaprel->requires), {}, '::Release->requires returns an empty hash for known-null deps' );
is_deeply(
    [ $swaprel->requires_libraries ], [ ],
    '::Release->requires_libraries for known no-deps returns null list',
);
is_deeply(
    [ $swaprel->requires_releases  ], [ ],
    '::Release->requires_releases  for known no-deps returns null list',
);


#####################################################################
# Repeat for something we know has deps
my $hasdeps = JSAN::Index::Release->retrieve( source => '/dist/a/ad/adamk/Display.Swap-0.09.tar.gz' );
my $display = JSAN::Index::Library->retrieve( name => 'Display' );
my $jsan    = JSAN::Index::Library->retrieve( name => 'JSAN'    );

isa_ok( $hasdeps, 'JSAN::Index::Release' );
isa_ok( $display, 'JSAN::Index::Library' );
isa_ok( $jsan,    'JSAN::Index::Library' );

my $deps = $hasdeps->requires;

is( ref($deps), 'HASH', '::Release returns a HASH for known deps release'    );

ok( defined($deps->{Display}), 'Display.Swap depends on Display as expected' );
ok( defined($deps->{JSAN}),    'Display.Swap depends on JSAN as expected'    );
is_deeply(
    [ $hasdeps->requires_libraries ], [ $display, $jsan ],
    '::Release->requires_libraries returns as expected for known-deps release',
);

my @hasdeps_releases = $hasdeps->requires_releases;
is(
    scalar(@hasdeps_releases), 2,
    '::Release->requires_releases returns 2 items for known-deps release',
);
isa_ok( $hasdeps_releases[0], 'JSAN::Index::Release' );
isa_ok( $hasdeps_releases[1], 'JSAN::Index::Release' );





#####################################################################
# Testing ::Library

# Find a known library
my $swaplib = JSAN::Index::Library->retrieve( name => 'Display.Swap' );

isa_ok( $swaplib, 'JSAN::Index::Library' );
isa_ok( $swaplib->distribution, 'JSAN::Index::Distribution' );
isa_ok( $swaplib->release, 'JSAN::Index::Release' );

ok( $swaplib->version, 'Library->version returns true' );
like( $swaplib->doc, qr{^/},  'Library->doc returns a root-relative path' );

is_deeply(
    $swaplib->distribution, $swaplib->release->distribution,
    '->release->distribution matches ->distribution',
);

# Is extractable
can_ok( $swaplib, 'extract_libs', 'extract_tests', 'extract_resource' );





#####################################################################
# More Interesting Tests

my $file = $swaplib->release->mirror;
ok( $file,    'Library->release->mirror returns true' );
ok( -f $file, 'Library->release->mirror exists'       );
