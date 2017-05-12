#!perl

# COPYRIGHT AND LICENCE
#
# Copyright (C) 2009 WhitePages.com, Inc. with primary
# development by Joshua ben Jore.
#
# This program is distributed WITHOUT ANY WARRANTY, including but not
# limited to the implied warranties of merchantability or fitness for
# a particular purpose.
#
# The program is free software.  You may distribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation (either version 2 or any later version)
# and the Perl Artistic License as published by O’Reilly Media, Inc.
# Please open the files named gpl-2.0.txt and Artistic for a copy of
# these licenses.

use strict;
use warnings;
use Test::More;

=head1 DESCRIPTION

This is a basic test of ordinary NYTProf

=cut

use Config qw( %Config );
use File::Basename qw( fileparse );
use File::Spec::Functions qw( catfile catdir );
use File::Path qw( rmtree );

# Check for the existence of Devel::NYTProf before continuing
#
system $^X, '-e', 'exit ! eval { require Devel::NYTProf }';
if ($?) {
    plan( skip_all => "Skipped because Devel::NYTProf isn't installed" );
    exit;
}
else {
    plan( tests => 14 );
}


# Locate my test script.
#
my ( $nm, $dir, $suffix ) = fileparse( $0, '.t' );
my $script = catfile( $dir, "$nm.pl" );

# Coordinate the report file
#
my $report_file = catfile( $dir, "$nm.out" );
my $report_dir  = catdir( $dir, $nm );
if ( $report_file =~ /:/ ) {
    # For Windows or whatever, if the report file has a : in it,
    # just go with a relative path to the report file which I
    # *hope* has no colon in it.
    $report_file = "$nm.out";
    $report_dir  = $nm;
}
diag( "report_file: $report_file" );
diag( "report_dir: $report_dir" );

# Coordinate the 

# Locate nytprofcsv. TODO: stop relying on $PATH
#
my $nytprofcsv;
my @candidate_paths = (
    catfile( $Config{installscript}, 'nytprofcsv' ),
    'nytprofcsv',
);
for my $candidate ( @candidate_paths ) {
    system $candidate, '--help';

    # nytprof{csv,html} --help just exits with 1. I'm only checking for the -1 response 
    # documented by system() for things that can't be found at all.
    next if -1 == $?;

    $nytprofcsv = $candidate;
    last;
}
diag( "nytprofcsv: $nytprofcsv" );

# Run the test script to generate $report_file.
#
{
    1 while unlink $report_file;
    local $ENV{NYTPROF} = "file=$report_file";
    system $^X, '-Mblib', $script;
    is( $?, 0, "Run $script ok" );
    ok( -e $report_file, "Report file $report_file exists" );
    ok( -f $report_file, "Report file $report_file is a file" );
    ok( -r $report_file, "Report file $report_file is readable" );
}

# Get the output.
#
rmtree( $report_dir );
my @cmd = (
    $nytprofcsv,
        '--file' => $report_file,
        '--out'  => $report_dir,
);
system @cmd;
is( $?, 0, "Ran @cmd ok" );
ok( -e $report_dir, "Report dir $report_dir exists" );
ok( -d $report_dir, "Report dir $report_dir is a directory" );


# Run the test script with use_db_sub=1 to generate $report_file.
#
{
    1 while unlink $report_file;
    local $ENV{NYTPROF} = "use_db_sub=1:file=$report_file";
    system $^X, '-Mblib', $script;
    is( $?, 0, "Run $script ok" );
    ok( -e $report_file, "Report file $report_file exists" );
    ok( -f $report_file, "Report file $report_file is a file" );
    ok( -r $report_file, "Report file $report_file is readable" );
}

# Get the output.
#
rmtree( $report_dir );
@cmd = (
    $nytprofcsv,
        '--file' => $report_file,
        '--out'  => $report_dir,
);
system @cmd;
is( $?, 0, "Ran @cmd ok" );
ok( -e $report_dir, "Report dir $report_dir exists" );
ok( -d $report_dir, "Report dir $report_dir is a directory" );

=begin emacs

## Local Variables:
## mode: cperl
## mode: auto-fill
## cperl-indent-level: 4
## End:

=end emacs
