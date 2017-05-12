#!/usr/bin/perl
#
# genprepundo.pl
#
# Initialize undo file for Clustered Genezzo
#
#
use strict;
use warnings;
use Getopt::Long;
use Carp;
use Genezzo::Contrib::Clustered::PrepUndo;
use Pod::Usage;

=head1 NAME

genprepundo.pl - Prepare undo file for Clustered Genezzo

=head1 SYNOPSIS

B<genprepundo.pl> [options]

Options:

    -help                      brief help message
    -man                       full documentation
    -gnz_home                  supply a directory for the gnz_home
    -undo_filename             name of the undo file
    -number_of_processes
    -undo_blocks_per_process

=head1 OPTIONS

=over 8

=item B<-help>

    Print a brief help message and exits.

=item B<-man>
 
    Prints the manual page and exits.

=item B<-gnz_home>
 
    Supply the location for the gnz_home installation.  If 
    specified, it overrides the GNZ_HOME environment variable.

=item B<-undo_filename>

    Supply the name of the undo file.  If not specified, it
    defaults to undo.und for file system devices.  It must
    be specified for raw devices.

=item B<-number_of_processes>

    Specify the maximum number of processes supported by undo.
    If not specified defaults to 256.

=item B<-undo_blocks_per_process>

    Specify the number of blocks (which list fileno-blockno pairs)
    for a process.  If not specified defaults to 220.

=back

=head1 DESCRIPTION

  Creates or re-initializes undo file under GNZ_HOME.  By default
  file is named undo.und.  File header contains basic information about
  all other files in Genezzo installation.  genprepundo.pl must
  be run whenever a new file is added to the Genezzo installation.

  Undo file format is documented in Clustered.pm.

=head1 AUTHOR

  Eric Rollins, rollins@acm.org

=head1 COPYRIGHT AND LICENSE

  Copyright (c) 2005 Eric Rollins.  All rights reserved.

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  any later version.


  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

  Address bug reports and comments to rollins@acm.org

=cut

BEGIN {
    my $man  = 0;
    my $help = 0;
    my $init = 0;
    my $shutdown = 0;
    my $gnz_home = '';
    my $undo_filename = '';
    my $number_of_processes = 256;
    my $undo_blocks_per_process = 220;

    GetOptions(
               'help|?' => \$help, man => \$man, 
               'gnz_home=s' => \$gnz_home,
	       'undo_filename=s' => \$undo_filename,
	       'number_of_processes=i' => \$number_of_processes,
	       'undo_blocks_per_process=i' => \$undo_blocks_per_process)
        or pod2usage(2);

    my $glob_id = "Genezzo Version $Genezzo::GenDBI::VERSION - $Genezzo::GenDBI::RELSTATUS $Genezzo::GenDBI::RELDATE\n\n";

    pod2usage(-msg => $glob_id, -exitstatus => 1) if $help;
    pod2usage(-msg => $glob_id, -exitstatus => 0, -verbose => 2) if $man;

    print "beginning initialization...\n";
    Genezzo::Contrib::Clustered::PrepUndo::prepareUndo(
    	gnz_home => $gnz_home,
	undo_filename => $undo_filename,
	number_of_processes => $number_of_processes,
	undo_blocks_per_process => $undo_blocks_per_process);
}

