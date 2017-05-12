# @(#)JESFTP.pm	1.1	03/07/09

package MVS::JESFTP;

=pod

=head1 NAME

MVS::JESFTP - Perl extension for submitting JCL to MVS systems through
FTP.

=head1 SYNOPSIS

use MVS::JESFTP;

$jes = MVS::JESFTP->open($host, $logonid, $password) or die;

$jes->submit($job);

$aref = $jes->wait_for_results($jobname, $timeout);

$jes->get_results($aref);

$jes->delete_results($aref);

$jes->quit;

=head1 DESCRIPTION

IBM mainframe MVS systems accept job input through the Job Entry
Subsystem (JES). This input is in the form of 80-byte I<card images>
that correspond to the punch cards of ancient times. The new releases of
MVS can accept this input via FTP to the MVS I<internal reader>
(equivalent to the physical card readers of older systems).

This module uses the Net::FTP module under the hood to handle the FTP
chores.

=cut

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
use Net::FTP;

@ISA = qw(Exporter Net::FTP);
@EXPORT = qw();
$VERSION = '1.1';

=pod

=head1 METHODS

=head2 $jes = MVS::JESFTP->open($host, $logonid, $password);

This method creates a connection to the MVS system JES. If the
connection is made, C<open> returns a reference C<$jes> to the JES
connection; otherwise C<open> returns C<undefined>.

C<open> takes three arguments:

=over 4

=item C<$host>

The IP address or DNS name of the MVS system.

=item C<$logonid>

A valid FTP logon ID for the host.

=item C<$password>

A valid FTP password for the host.

=back

=cut

sub open { #------------------------------------------------------------
	my($pkg, $host, $logonid, $password) = @_;

	my $self = Net::FTP->new($host) or return undef;

	$self->login($logonid, $password) or return undef;

	bless $self, $pkg;

	return $self;
} #---------------------------------------------------------------------

=pod

=head2 $jes->submit($job);

This method submits the jobstream contained in the file C<$job>. If the
submission is successful, C<submit> returns true; otherwise C<submit>
returns C<undefined>.

=cut

sub submit { #----------------------------------------------------------
	my($self, $job) = @_;

	$self->quot('SITE', 'FILETYPE=JES JESLRECL=80') or return undef;

	return $self->put($job);
} #---------------------------------------------------------------------

=pod

=head2 $aref = $jes->wait_for_results($jobname, $timeout);

This method waits for the output of the submitted job to arrive in the
JES I<hold queue>. C<wait_for_results> returns an array reference
C<$aref> to the a list of output files for the job suitable for input to
C<get_results>, or C<undefined> if NO results could be obtained. (1)

C<wait_for_results> takes two arguments:

=over 4

=item C<$jobname>

The name of the job you presumedly submitted with the C<submit> method.

=item C<$timeout>

How many seconds to wait for the job output to arrive; defaults to 60.

=back

=cut

sub wait_for_results { #------------------------------------------------
	my($self, $JOB, $TIMEOUT) = @_;

	$JOB =~ s/\..+$//;
	$TIMEOUT ||= 60;

	my @results = ();
	my $i = 0;
	while (++$i <= $TIMEOUT) {
		# print "$i: waiting for $JOB...\n";
		last if (@results = grep /^$JOB\s+JOB\d+\s+OUTPUT/, $self->dir);
		sleep(1);
	}
	return (@results) ? \@results : undef;
} #---------------------------------------------------------------------

=pod

=head2 $result = $jes->get_results($aref);

This method retrieves the output of the submitted job from the JES
I<hold queue>. C<get_results> returns C<undefined> if successful;
otherwise it returns a reference to an array of names of the files
it could NOT retrieve. (1)

C<get_results> takes one argument:

=over 4

=item C<$aref>

An array reference to the a list of output files from the job, such as
C<wait_for_results> generates. C<get_results> will retreive (via FTP)
each output file in turn and store them in the current subdirectory;
file names will be preserved.

=back

=cut

sub get_results { #-----------------------------------------------------
	my ($self, $ref) = @_;

	my @fails = ();
	foreach my $line (@$ref) {
		my $JOB = (split(/\s+/, $line))[1] . '.x';
		$self->get($JOB) or push @fails, $JOB;
	}

	return (@fails) ? \@fails : undef;
} #---------------------------------------------------------------------

=pod

=head2 $result = $jes->delete_results($aref);

This method deletes the output of the submitted job from the JES
I<hold queue>. C<delete_results> returns C<true> if successful;
otherwise it returns a reference to an array of names of the jobs
it could not delete.

C<delete_results> takes one argument:

=over 4

=item C<$aref>

An array reference to the a list of output files from the job, such as
C<wait_for_results> generates. C<delete_results> will delete each job
in turn.

=back

=cut

sub delete_results { #-----------------------------------------------------
	my ($self, $ref) = @_;

	my @fails = ();
	foreach my $line (@$ref) {
		my $JOB = (split(/\s+/, $line))[1];
		$self->delete($JOB) or push @fails, $JOB;
	}

	return (@fails) ? \@fails : undef;
} #---------------------------------------------------------------------

=pod

=head2 $jes->quit;

This method closes the connection to JES. It is just the Net::FTP
C<quit> method.

=cut

=pod

(1) To use this method, your JCL I<JOB> card must specify a I<MSGCLASS>
that directs its output to the JES I<hold queue>. If you don't
understand what this means, B<don't use this method>, or you will hang
your calling program.

=head1 PREREQUISITES

You have to have Net::FTP installed.

=head1 INSTALLATION

 tar xzf MVS-JESFTP-1.00.tar.gz
 perl Makefile.PL
 make
 #
 # Edit TEST.SEQ to contain your site-specific logonid,
 # password, account, & node in the appropriate places.
 #
 make test
 make install

For Win32 systems, after unarchiving the the package, copy JESFTP.pm to
C:\Perl\site\lib\MVS (modifying this path for your installation of
Perl).

=head1 AUTHOR

Mike Owens

mike.owens@state.nm.us

Copyright (c) 2000 Mike Owens. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See either the GNU
General Public License or the Artistic License for more details.

=head1 SEE ALSO

C<perl(1)>

C<Net::FTP>

=cut

1;
