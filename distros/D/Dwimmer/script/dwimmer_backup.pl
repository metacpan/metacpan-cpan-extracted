#!/usr/bin/perl
use strict;
use warnings;
use autodie;

use File::Temp   qw(tempdir);
use Getopt::Long qw(GetOptions);
use Pod::Usage   qw(pod2usage);
use POSIX;

# TODO: On Linux this is sqlite3 and should be located at /usr/bin/sqlite3
# Windows?
my $SQLITE = 'sqlite3';

my %opt;
GetOptions(\%opt,
    'root=s',
);
pod2usage() if not $opt{root};


my $db_dir = File::Spec->catdir($opt{root}, 'db');
my $dbfile = File::Spec->catfile( $db_dir, 'dwimmer.db' );
die "Database file '$dbfile' does not exist\n" if not -e $dbfile;

my $backup_dir = File::Spec->catdir($opt{root}, 'backup');
if (not -e $backup_dir) {
    mkdir $backup_dir;
}
my $backup_file = File::Spec->catfile( $backup_dir, POSIX::strftime("%Y%m%d-%H%M%S.dump", gmtime) );

system qq($SQLITE $dbfile ".dump" > $backup_file);

=head1 SYNOPSIS

REQUIRED PARAMETERS:

   --root ROOT          path to the root of the installation

=cut

