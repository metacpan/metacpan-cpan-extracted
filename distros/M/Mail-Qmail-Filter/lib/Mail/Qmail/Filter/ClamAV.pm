use 5.014;
use warnings;

package Mail::Qmail::Filter::ClamAV;

our $VERSION = '1.0';

use Mo qw(coerce default);
extends 'Mail::Qmail::Filter';

has 'clamav_options' => sub { [] };
has 'dump_malware_to';
has 'error_text'  => 'An error occured when scanning the message for viruses.';
has 'reject_text' => sub {
    sub { "Virus found: $_[0]" }
};

sub filter {
    my $self     = shift;
    my $message  = $self->message;
    my $body_ref = $message->body_ref;

    require File::Scan::ClamAV;    # lazy load because filter might be skipped
    my $av = File::Scan::ClamAV->new( @{ $self->clamav_options } );
    my ( $response, $virus ) = $av->streamscan($$body_ref);
    if ( my $errstr = $av->errstr ) {
        $self->defer( $self->error_text, $errstr );
    }
    else {
        $self->debug( result => $response );
        if ($virus) {
            $self->debug( virus => $virus );
            if ( defined( my $dir = $self->dump_malware_to ) ) {
                require Path::Tiny and Path::Tiny->import('path')
                  unless defined &path;
                path( $dir, my $file = join '_', $^T, $$, $virus =~ y!/\n!_!r )
                  ->spew($$body_ref);
                $self->debug( 'dumped message to' => $file );
            }
            $self->reject( $self->reject_text, $virus );
        }
    }
}

1;

__END__

=head1 NAME

Mail::Qmail::Filter::ClamAV -
check if message contains mailware

=head1 SYNOPSIS

    use Mail::Qmail::Filter;
    
    Mail::Qmail::Filter->new->add_filter(
        '::ClamAV' => {
            clamav_options  => [ port => '/run/clamav/clamd-socket' ],
            skip_for_rcpt   => [ 'postmaster', 'postmaster@' . $mydomain ],
            dump_malware_to => '/var/tmp/malware',
        },
        '::Queue',
    )->run;

=head1 DESCRIPTION

This L<Mail::Qmail::Filter> plugin checks if the incoming e-mail message
contains a virus.

=head1 OPTIONAL PARAMETERS

=head2 clamav_options

Options which are passed to C<L<File::Scan::ClamAV>-E<gt>new()>.

=head2 dump_malware_to

If a virus is found in the message, copy it into a file in the given directory.
The file will be named 
C<E<lt>epoch_time_when_script_startedE<gt>_E<lt>pidE<gt>_E<lt>virus_nameE<gt>>

=head2 error_text

Reply text in case an error occurs during the scan.

Default: C<An error occured when scanning the message for viruses.>

An error message is passed to this method, so you may include it via C<$_[0]>
if you want.

=head2 reject_text

Reply text to send to the client when the message is rejected.

Default:

    sub { "Virus found: $_[0]" }

=head1 SEE ALSO

L<Mail::Qmail::Filter/COMMON OPTIONS FOR ALL FILTERS>, L<File::Scan::ClamAV>

=head1 LICENSE AND COPYRIGHT

Copyright 2022 Martin Sluka.

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
