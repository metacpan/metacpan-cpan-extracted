#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;

use IO::All -utf8;
use Time::Piece;

use HON::EC2::Snapshots::Monitoring qw/findLogsOfTheDay isLogOk/;

=head1 NAME

hon-ec2-snapshots-monitoring.pl - Monitor EC2 snapshots log

=head1 VERSION

Version 0.03

=head1 USAGE

  hon-ec2-snapshots-monitoring.pl --help

  hon-ec2-snapshots-monitoring.pl --log=/path/to/file.log

=head1 REQUIRED ARGUMENTS

=over 2

=item --log=/path/to/file.log

path to the log file

=back

=head1 DESCRIPTION

Monitor EC2 snapshots log

=cut

our $VERSION = '0.03';

my ( $log, $help );
GetOptions(
  'log=s' => \$log,
  'help'  => \$help,
) || pod2usage(2);

if ( $help || !$log ) {
  pod2usage(1);
  exit 0;
}

my $time      = Time::Piece->new;
my @lines     = io($log)->slurp;
my @todayLogs = findLogsOfTheDay( \@lines, $time->mdy );
if ( isLogOk(@todayLogs) ) {
  print 'exit 0', "\n";
  exit 0;
}
else {
  print 'exit 1', "\n";
  exit 1;
}

=head1 AUTHOR

William Belle, C<< <william.belle at gmail.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-hon-ec2-snapshots-monitoring at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HON-EC2-Snapshots-Monitoring>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

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
