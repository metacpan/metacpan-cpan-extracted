#!/usr/bin/perl

######################
# Release Foorum
######################

use strict;
use warnings;
use FindBin qw/$Bin/;
use Cwd qw/abs_path/;
use File::Spec;
use lib File::Spec->catdir( $FindBin::Bin, '..', '..', 'lib' );
use File::Next;
use File::Slurp ();
use Foorum::Release qw/get_version bump_up_version/;

my $trunk_dir = abs_path( File::Spec->catdir( $Bin, '..', '..' ) );

# 1, bump up the version
print "bump up the version:\n";
my $version_now = get_version();
my $version_up  = bump_up_version($version_now);

my $files = File::Next::files($trunk_dir);

while ( defined( my $file = $files->() ) ) {
    next if ( $file !~ /\.pm$/ );    # only .pm

    print "working on $file\n";

    my $content = eval { File::Slurp::read_file( $file, binmode => ':raw' ) };
    if ($@) {
        warn $@;
        next;
    }

    $content =~ s/our \$VERSION = \'[\d\.]+\'\;/our \$VERSION = \'$version_up\'\;/i;

    eval {
        File::Slurp::write_file( $file, { binmode => ':raw' }, $content );
    };
    if ($@) {
        warn $@;
    }
}

1;
