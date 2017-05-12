package HON::EC2::Snapshots::Monitoring;

use 5.006;
use strict;
use warnings;

=head1 NAME

HON::EC2::Snapshots::Monitoring - Log file monitoring

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.04';

use base 'Exporter';
our @EXPORT_OK = qw/findLogsOfTheDay isLogOk/;

=head1 SYNOPSIS

  use HON::EC2::Snapshots::Monitoring;

  my @logs = findLogsOfTheDay(\@lines, '12-18-2015');
  isLogOk(@logs);

=head1 DESCRIPTION

Several utilities functions

=head1 SUBROUTINES/METHODS

=head2 findLogsOfTheDay

Find logs of the day

=cut

sub findLogsOfTheDay {
  my ( $refLines, $date ) = @_;
  my @logsOfTheDay = ();
  my $keepLogs     = 0;

  foreach my $line ( @{$refLines} ) {
    if ( $line =~ m/Starting\s\w+\sBackup\s--\s(\d{1,2}-\d{2}-\d{4})/xmsgi ) {
      if ( $1 eq $date ) {
        $keepLogs = 1;
      }
    }

    if ( $keepLogs == 1 ) {
      push @logsOfTheDay, $line;
    }

    if ( $line =~ m/Backup\sdone/xmsgi ) {
      $keepLogs = 0;
    }
  }
  return @logsOfTheDay;
}

=head2 isLogOk

Verify specific part of the log

=cut

sub isLogOk {
  my @lines        = @_;
  my $isSnapshot   = 0;
  my $isTagging    = 0;
  my $isPurging    = 0;

  foreach my $line (@lines) {
    if (
      $line =~ m/^Snapshots\staken\sby\sec2-automate-backup-awscli[.]sh/xmsgi )
    {
      $isSnapshot = 1;
    }
    if ( $line =~ m/Tagging\sSnapshot\ssnap-/xmsgi ) {
      $isTagging = 1;
    }
    if ( $line =~ m/Snapshot\sPurging\sis/xmsgi ) {
      $isPurging = 1;
    }
  }

  return ( $isSnapshot and $isTagging and $isPurging );
}

=head1 AUTHOR

William Belle, C<< <william.belle at gmail.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-hon-ec2-snapshots-monitoring at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HON-EC2-Snapshots-Monitoring>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HON::EC2::Snapshots::Monitoring


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HON-EC2-Snapshots-Monitoring>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HON-EC2-Snapshots-Monitoring>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HON-EC2-Snapshots-Monitoring>

=item * Search CPAN

L<http://search.cpan.org/dist/HON-EC2-Snapshots-Monitoring/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 William Belle.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 dated June, 1991 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA


=cut

1;    # End of HON::EC2::Snapshots::Monitoring
