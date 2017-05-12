package Kolab::Mailer;

##
##  Copyright (c) 2003  Code Fusion cc
##
##    Writen by Stuart Bingë  <s.binge@codefusion.co.za>
##
##  This  program is free  software; you can redistribute  it and/or
##  modify it  under the terms of the GNU  General Public License as
##  published by the  Free Software Foundation; either version 2, or
##  (at your option) any later version.
##
##  This program is  distributed in the hope that it will be useful,
##  but WITHOUT  ANY WARRANTY; without even the  implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
##  General Public License for more details.
##
##  You can view the  GNU General Public License, online, at the GNU
##  Project's homepage; see <http://www.gnu.org/licenses/gpl.html>.
##

use 5.008;
use strict;
use warnings;
use Kolab;
use MIME::Entity;
use MIME::Body;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'all' => [ qw(
        &sendMultipart
        &sendText
    )
] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = sprintf('%d.%02d', q$Revision: 1.1.1.1 $ =~ /(\d+)\.(\d+)/);

sub sendMultipart
{
    my $from = shift || '';
    my $to = shift || '';
    my $subj = shift || '';

    my $mesg = MIME::Entity->build(
        From    => $from,
        To      => $to,
        Subject => $subj,
        Type    => "multipart/mixed"
    );

    my (@stats, $data);
    while (my $file = shift) {
        @stats = stat($file);
        seek($file, 0, 0);
        read($file, $data, $stats[7]);
        Kolab::log('M', 'Read ' . $stats[7] . ' bytes, data = ' . $data, KOLAB_DEBUG);
        $mesg->attach(Data => $data);
    }

    open(SENDMAIL, '|' . $Kolab::config{'prefix'} . '/sbin/sendmail -oi -t -odq');
    $mesg->print(\*SENDMAIL);
    close(SENDMAIL);
}

sub sendText
{
    my $from = shift || '';
    my $to = shift || '';
    my $subj = shift || '';
    my $text = shift || '';

    my $mesg = MIME::Entity->build(
        From    => $from,
        To      => $to,
        Subject => $subj,
        Data    => $text,
    );

    open(SENDMAIL, '|' . $Kolab::config{'prefix'} . '/sbin/sendmail -oi -t -odq');
    $mesg->print(\*SENDMAIL);
    close(SENDMAIL);
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Kolab::Mailer - Perl extension for sending out email

=head1 ABSTRACT

  Kolab::Mailer allows callers to send out various types of
  email, namely plain, multipart & binary through sendmail.

=head1 AUTHOR

Stuart Bingë, E<lt>s.binge@codefusion.co.zaE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003  Code Fusion cc

This  program is free  software; you can redistribute  it and/or
modify it  under the terms of the GNU  General Public License as
published by the  Free Software Foundation; either version 2, or
(at your option) any later version.

This program is  distributed in the hope that it will be useful,
but WITHOUT  ANY WARRANTY; without even the  implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You can view the  GNU General Public License, online, at the GNU
Project's homepage; see <http://www.gnu.org/licenses/gpl.html>.

=cut
