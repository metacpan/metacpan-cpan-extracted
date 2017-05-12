#!/usr/bin/perl

######################
# Build Docs From GoogleCode wiki
######################

use strict;
use warnings;
use Pod::From::GoogleWiki;
use FindBin qw/$Bin/;
use Cwd qw/abs_path/;
use File::Copy;
use File::Spec;

my $trunk_dir = abs_path( File::Spec->catdir( $Bin,       '..', '..' ) );
my $wiki_dir  = abs_path( File::Spec->catdir( $trunk_dir, '..', 'wiki' ) );
my $project_url = 'http://code.google.com/p/foorum';

my @filenames = (
    'README',          'INSTALL',    'Configure', 'I18N',
    'TroubleShooting', 'AUTHORS',    'RULES',     'HowRSS',
    'Tutorial1',       'Tutorial2',  'Tutorial3', 'Tutorial4',
    'Tutorial5',       'PreRelease', 'Upgrade'
);

my $pfg = Pod::From::GoogleWiki->new();

# build tp trunk/lib/Foorum/Manual/ dir
foreach my $filename (@filenames) {
    {
        local $/;
        open( my $fh, '<',
            File::Spec->catfile( $wiki_dir, "$filename\.wiki" ) )
            or do {
            print "Skip $filename\n";
            next;
            };
        flock( $fh, 1 );
        my $string = <$fh>;
        close($fh);

        # change build-in links
        foreach my $f (@filenames) {
            $string =~ s/\[$f\]/\[Foorum\:\:Manual\:\:$f\]/isg;
        }

        my $pod = $pfg->wiki2pod($string);

        open(
            my $fh2,
            '>',
            File::Spec->catfile(
                $trunk_dir, 'lib', 'Foorum', 'Manual', "$filename\.pod"
            )
        );
        print $fh2 "\n=pod\n$pod\n\n=cut\n";
        close($fh2);

        print "$filename OK\n";
    }
}

1;
