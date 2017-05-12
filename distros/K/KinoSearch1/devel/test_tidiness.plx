#!/usr/bin/perl
use strict;
use warnings;

=for comment

test_tidiness.plx => check all Perl modules and test files to see if their tidiness
is up to date.  Since this has no effect on users, it's not part of the
standard test suite.

=cut

use File::Find qw( find );
use File::Spec::Functions qw( catfile );
use Text::Diff;
use Perl::Tidy;
use Test::More 'no_plan';

# grab all .pm filepaths 
my @paths;
find(
    {   wanted => sub {
            push @paths, $File::Find::name
                if $File::Find::name =~ /\.pm$/;
        },      
        no_chdir => 1,
    },
    'lib',  
);

# grab all .t files
find(
    {   wanted => sub {
            push @paths, $File::Find::name
                if $File::Find::name =~ /\.t$/;
        },      
        no_chdir => 1,
    },
    't',  
);

my $rc_filepath = catfile('devel', 'kinotidyrc');
ok(-f $rc_filepath, "found $rc_filepath");

for my $path (@paths) {
    # grab orig text
    open( my $module_fh, '<', $path )
        or die "couldn't open file '$path' for reading: $!";
    my $orig_text = do { local $/; <$module_fh> };
    close $module_fh;

    my $tidied = '';
    Perl::Tidy::perltidy(
        source => \$orig_text,
        destination => \$tidied,
        perltidyrc => $rc_filepath,
    );
    is( index($orig_text, $tidied), 0, "$path" );
    if (index($orig_text, $tidied) != 0) {
        warn diff(\$orig_text, \$tidied);
        <STDIN>;
    }
}

