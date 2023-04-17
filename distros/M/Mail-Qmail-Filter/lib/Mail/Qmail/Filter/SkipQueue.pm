use 5.014;
use warnings;

package Mail::Qmail::Filter::SkipQueue;

our $VERSION = '1.01';

use Mo qw(coerce);
extends 'Mail::Qmail::Filter';

sub filter {
    my $self    = shift;
    my $message = $self->message;

    require Qmail::Deliverable and Qmail::Deliverable->import('dot_qmail')
      unless defined &dot_qmail;

    my $dot_qmail;
    for ( $message->to ) {
        my $_dot_qmail = dot_qmail($_)
          or return $self->debug( 'No .qmail file found for rcpt' => $_ );
        $self->debug( 'using file' => $_dot_qmail );
        return $self->debug('Delivery to different .qmail files not supported')
          if defined $dot_qmail && $_dot_qmail ne $dot_qmail;
        $dot_qmail = $_dot_qmail;
    }

    open my $fh, '<', $dot_qmail
      or return $self->debug( "Cannot read $dot_qmail", $! );

    my @commands;
    while ( defined( my $line = <$fh> ) ) {
        next if /^#/;
        chomp $line;
        if ( $line !~ /^\|/ ) {
            $self->debug( 'Delivery method not supported', $line );
        }
        else {
            push @commands, $line;
        }
    }

    local $ENV{SENDER} = $message->from;
    for (@commands) {
        require Capture::Tiny and Capture::Tiny->import('capture_merged')
          unless defined &capture_merged;
        my ( $output, $exitcode ) = capture_merged(
            sub {
                open my $fh, $_ or return $self->debug( "Cannot start $_", $! );
                print $fh $message->body;
                close $fh;
                $?;
            }
        );
        $output = join '/', split /\n/, $output;
        $exitcode >>= 8;
        $self->debug( qq("$_" returned with exit code $exitcode) => $output );
        next                   if $exitcode == 0;
        last                   if $exitcode == 99;
        $self->reject($output) if $exitcode == 100;
        return;
    }

    $self->debug( action => 'delivered' );
}

1;

__END__

=head1 NAME

Mail::Qmail::Filter::SkipQueue -
deliver message using external commands

=head1 SYNOPSIS

    use Mail::Qmail::Filter;
    
    Mail::Qmail::Filter->new->add_filter(
        '::SkipQueue',
    )->run;

=head1 DESCRIPTION

This L<Mail::Qmail::Filter> plugin tries to find the appropriate C<.qmail> file
for all recipients and pipes the message to any command lines listed in those
files.
That is, it tries to deliver the message itself, circumventing C<qmail-local>.
The usual rules for exit codes from the programs called apply.
Other delivery methods, namely maildir or mbox lines, are not supported
and will be skipped.

=head1 DISCLAIMER

This plugin is considered experimental.
I implemented it as a proof-of-concept when developing
L<Mail::Qmail::Filter::CheckDeliverability>.
I do not recommend to use it a production environment.

=head1 SEE ALSO

L<Mail::Qmail::Filter/COMMON PARAMETERS FOR ALL FILTERS>,
L<Mail::Qmail::Filter::CheckDeliverability>

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Martin Sluka.

This module is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
