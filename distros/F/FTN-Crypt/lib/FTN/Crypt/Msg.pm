# FTN::Crypt::Msg - Message parsing for the FTN::Crypt module
#
# Copyright (C) 2019 by Petr Antonov
#
# This library is free software; you can redistribute it and/or modify it
# under the same terms as Perl 5.10.0. For more details, see the full text
# of the licenses at https://opensource.org/licenses/Artistic-1.0, and
# http://www.gnu.org/licenses/gpl-2.0.html.
#
# This package is provided "as is" and without any express or implied
# warranties, including, without limitation, the implied warranties of
# merchantability and fitness for a particular purpose.
#
package FTN::Crypt::Msg::MsgChunk;

use strict;
use warnings;
use v5.10.1;

sub new {
    my $class = shift;

    my $self = {
        data => [],
    };
    
    bless $self, $class;
}

sub get {
    my $self = shift;
    
    return $self->{data};
}

sub set {
    my $self = shift;
    my ($line) = @_;
    
    push @{$self->{data}}, $line;
}

#----------------------------------------------------------------------#

package FTN::Crypt::Msg::KludgeChunk;

use strict;
use warnings;
use v5.10.1;

use base qw/FTN::Crypt::Msg::MsgChunk/;

sub remove {
    my $self = shift;
    my ($kludge) = @_;
    
    if (defined $kludge && $kludge ne '') {
        @{$self->{data}} = grep { !/^${kludge}(?::?\s.+)*$/ }
                           @{$self->{data}};
    } else {
        return;
    }

    return 1;
}

#----------------------------------------------------------------------#

package FTN::Crypt::Msg::TextChunk;

use strict;
use warnings;
use v5.10.1;

use base qw/FTN::Crypt::Msg::MsgChunk/;

sub get {
    my $self = shift;
    my ($ftn_ready) = @_;

    my $sep = $ftn_ready ? "\r" : "\n";

    return join $sep, @{$self->{data}};
}

#----------------------------------------------------------------------#

package FTN::Crypt::Msg;

use strict;
use warnings;
use v5.10.1;

use base qw/FTN::Crypt::Error/;

#----------------------------------------------------------------------#

=head1 NAME

FTN::Crypt::Msg - Message parsing for the L<FTN::Crypt> module.

=head1 SYNOPSIS

    use FTN::Crypt::Msg;

    my $obj = FTN::Crypt::Msg->new(
        Address => $ftn_address,
        Message => $msg,
    );
    $obj->add_kludge('ENC: PGP5');
    $obj->remove_kludge('ENC');
    my $text = $obj->get_text;
    my $kludges = $obj->get_kludges;
    my $msg = $obj->get_message;

=cut

#----------------------------------------------------------------------#

use FTN::Address;

#----------------------------------------------------------------------#

my $SOH = chr(1);

my %PREDEFINED_INDEX = (
    'TOP'    => 0,
    'BOTTOM' => -1,
);
my %DEFAULT_INDEX = (
    KLUDGE => 'TOP',
    TEXT   => 'BOTTOM',
);

#----------------------------------------------------------------------#

=head1 METHODS

=cut

#----------------------------------------------------------------------#

=head2 new()

Constructor.

=head3 Parameters:

=over 4

=item * C<Address>: Recipient's FTN address.

=item * C<Message>: FTN message text with kludges.

=back

=head3 Returns:

Created object or error in C<FTN::Crypt::Msg-E<gt>error>.

Sample:

    my $obj = FTN::Crypt::Msg->new(
        Address => $ftn_address,
        Message => $msg,
    ) or die FTN::Crypt::Msg->error;

=cut

sub new {
    my $class = shift;
    my (%opts) = @_;

    unless (%opts) {
        $class->set_error('No options specified');
        return;
    }
    unless ($opts{Address}) {
        $class->set_error('No address specified');
        return;
    }
    unless ($opts{Message}) {
        $class->set_error('No message specified');
        return;
    }

    my $self = {
        msg => [],
        idx => {
            KLUDGE => [],
            TEXT   => [],
        },
    };

    $self = bless $self, $class;

    unless ($self->set_address($opts{Address})) {
        $class->set_error($self->error);
        return;
    }
    unless ($self->set_message($opts{Message})) {
        $class->set_error($self->error);
        return;
    }

    return $self;
}

#----------------------------------------------------------------------#

sub _check_kludge {
    my $self = shift;
    my ($kludge) = @_;

    unless (defined $kludge && $kludge ne '') {
        $self->set_error('Kludge is empty');
        return;
    }

    return $kludge;
}

#----------------------------------------------------------------------#

sub _check_text {
    my $self = shift;
    my ($text) = @_;

    unless (defined $text && $text ne '') {
        $self->set_error('Text is empty');
        return;
    }

    return $text;
}

#----------------------------------------------------------------------#

sub _check_idx {
    my $self = shift;
    my ($type, $idx) = @_;

    unless (grep /^$type$/, keys %{$self->{idx}}) {
        $self->set_error("Invalid message area type (`$type')");
        return;        
    }

    $idx = $DEFAULT_INDEX{$type} unless defined $idx;

    $idx = $PREDEFINED_INDEX{$idx} if defined $PREDEFINED_INDEX{$idx};
    
    unless ($idx =~ /^-?\d+$/) {
        $self->set_error("Invalid chunk index (`$idx')");
        return;
    }

    unless (defined $self->{idx}->{$type}->[$idx]) {
        $self->set_error("Invalid chunk index (`$idx')");
        return;
    }

    return $idx;
}

#----------------------------------------------------------------------#

=head2 add_kludge()

Add kludge to the message.

=head3 Parameters:

=over 4

=item * Kludge string.

=item * B<Optional> C<[TOP|BOTTOM|<index>]> Kludges block, defaults to TOP.

=back

=head3 Returns:

True or error in C<$obj-E<gt>error>.

Sample:

    $obj->add_kludge('ENC: PGP5') or die $obj->error;

=cut

sub add_kludge {
    my $self = shift;
    my ($kludge, $idx) = @_;

    $kludge = $self->_check_kludge($kludge);
    $idx = $self->_check_idx('KLUDGE', $idx);

    if (defined $kludge && defined $idx) {
        $self->{msg}->[$self->{idx}->{KLUDGE}->[$idx]]->set($kludge);
    } else {
        return;
    }

    return 1;
}

#----------------------------------------------------------------------#

=head2 remove_kludge()

Remove kludge from the message.

=head3 Parameters:

=over 4

=item * Kludge string, may be only the first part of the composite kludge.

=item * B<Optional> C<[TOP|BOTTOM|<index>]> Kludges block, defaults to TOP.

=back

=head3 Returns:

True or error in C<$obj-E<gt>error>.

Sample:

    $obj->remove_kludge('ENC') or die $obj->error;

=cut

sub remove_kludge {
    my $self = shift;
    my ($kludge, $idx) = @_;

    $kludge = $self->_check_kludge($kludge);
    $idx = $self->_check_idx('KLUDGE', $idx);

    if (defined $kludge && defined $idx) {
        $self->{msg}->[$self->{idx}->{KLUDGE}->[$idx]]->remove($kludge);
    } else {
        return;
    }

    return 1;
}

#----------------------------------------------------------------------#

=head2 get_kludges()

Get message kludges.

=head3 Parameters:

None.

=head3 Returns:

Arrayref with kludges list or error in C<$obj-E<gt>error>.

Sample:

    $obj->get_kludges() or die $obj->error;

=cut

sub get_kludges {
    my $self = shift;

    my $kludges = [];
    foreach my $c (@{$self->{msg}}) {
        push @{$kludges}, $c->get if $c->isa('FTN::Crypt::Msg::KludgeChunk');
    }

    return $kludges;
}

#----------------------------------------------------------------------#

=head2 get_address()

Get recipient's FTN address.

=head3 Parameters:

None.

=head3 Returns:

Recipient's FTN address or error in C<$obj-E<gt>error>.

Sample:

    my $ftn_address = $obj->get_address() or die $obj->error;

=cut

sub get_address {
    my $self = shift;

    my $addr = $self->{addr}->get;
    unless ($addr) {
        $self->set_error($@);
        return;
    }

    return $addr;
}

#----------------------------------------------------------------------#

=head2 set_address()

Set recipient's FTN address.

=head3 Parameters:

=over 4

=item * Recipient's FTN address.

=back

=head3 Returns:

True or error in C<$obj-E<gt>error>.

Sample:

    $obj->set_address($ftn_address)

=cut

sub set_address {
    my $self = shift;
    my ($addr) = @_;

    $self->{addr} = FTN::Address->new($addr);
    unless ($self->{addr}) {
        $self->set_error($@);
        return;
    }

    return 1;
}

#----------------------------------------------------------------------#

=head2 get_text()

Get text part of the message.

=head3 Parameters:

=over 4

=item * B<Optional> C<[TOP|BOTTOM|<index>]> Text block, defaults to BOTTOM.

=back

=head3 Returns:

Text part of the message or error in C<$obj-E<gt>error>.

Sample:

    my $text = $obj->get_text() or die $obj->error;

=cut

sub get_text {
    my $self = shift;
    my ($idx) = @_;

    $idx = $self->_check_idx('TEXT', $idx);

    my $text = '';
    if (defined $idx) {
        $text = $self->{msg}->[$self->{idx}->{TEXT}->[$idx]]->get;
    } else {
        return;
    }

    return $text;
}

#----------------------------------------------------------------------#

=head2 get_all_text()

Get all text parts of the message.

=head3 Parameters:

None.

=head3 Returns:

Arrayref with text parts of the message or error in C<$obj-E<gt>error>.

Sample:

    my $text = $obj->get_all_text() or die $obj->error;

=cut

sub get_all_text {
    my $self = shift;

    my $text = [];
    foreach my $c (@{$self->{msg}}) {
        push @{$text}, $c->get if $c->isa('FTN::Crypt::Msg::TextChunk');
    }

    return $text;
}

#----------------------------------------------------------------------#

=head2 set_text()

Set text part of the message.

=head3 Parameters:

=over 4

=item * Text part of the message.

=item * B<Optional> C<[TOP|BOTTOM|<index>]> Text block, defaults to BOTTOM.

=back

=head3 Returns:

True or error in C<$obj-E<gt>error>.

Sample:

    $obj->set_text($text) or die $obj->error;

=cut

sub set_text {
    my $self = shift;
    my ($text, $idx) = @_;

    $text = $self->_check_text($text);
    $idx = $self->_check_idx('TEXT', $idx);

    if (defined $text && defined $idx) {
        $self->{msg}->[$self->{idx}->{TEXT}->[$idx]] = FTN::Crypt::Msg::TextChunk->new;
        $text =~ s/\r\n/\r/g;
        $text =~ s/\n/\r/g;
        my @text_lines = split /\r/, $text;
        foreach my $l (@text_lines) {
            $self->{msg}->[$self->{idx}->{TEXT}->[$idx]]->set($l);
        }
    } else {
        return;
    }

    return 1;
}

#----------------------------------------------------------------------#

=head2 get_message()

Get FTN message text with kludges.

=head3 Parameters:

None.

=head3 Returns:

FTN message text with kludges or error in C<$obj-E<gt>error>.

Sample:

    my $msg = $obj->get_message() or die $obj->error;

=cut

sub get_message {
    my $self = shift;

    my @msg;
    foreach my $c (@{$self->{msg}}) {
        if ($c->isa('FTN::Crypt::Msg::KludgeChunk')) {
            push @msg, join "\r", map { "${SOH}$_" } @{$c->get};
        } elsif ($c->isa('FTN::Crypt::Msg::TextChunk')) {
            push @msg, $c->get(1);
        }
    }

    my $msg_out = join "\r", @msg;
    
    return $msg_out;
}

#----------------------------------------------------------------------#

=head2 set_message()

Set FTN message text with kludges.

=head3 Parameters:

=over 4

=item * FTN message text with kludges.

=back

=head3 Returns:

True or error in C<$obj-E<gt>error>.

Sample:

    $obj->set_message($msg) or die $obj->error;

=cut

sub set_message {
    my $self = shift;
    my ($msg) = @_;

    $self->{msg} = [];
    foreach my $a (keys %{$self->{idx}}) {
        $self->{idx}->{$a} = [];
    }

    $msg =~ s/\r\n/\r/g;
    $msg =~ s/\n/\r/g;
    my @msg_lines = split /\r/, $msg;

    my $is_kludge;
    foreach my $l (@msg_lines) {
        if ($l =~ s/^${SOH}//) {
            if (!defined $is_kludge || !$is_kludge) {
                push @{$self->{msg}}, FTN::Crypt::Msg::KludgeChunk->new;
                push @{$self->{idx}->{KLUDGE}}, $#{$self->{msg}};
                $is_kludge = 1;
            }
        } else {
            if (!defined $is_kludge || $is_kludge) {
                push @{$self->{msg}}, FTN::Crypt::Msg::TextChunk->new;
                push @{$self->{idx}->{TEXT}}, $#{$self->{msg}};
                $is_kludge = 0;
            }
        }
        $self->{msg}->[-1]->set($l);
    }

    return 1;
}

1;
__END__

=head1 AUTHOR

Petr Antonov, E<lt>pietro@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Petr Antonov

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses at L<https://opensource.org/licenses/Artistic-1.0>, and
L<http://www.gnu.org/licenses/gpl-2.0.html>.

This package is provided "as is" and without any express or implied
warranties, including, without limitation, the implied warranties of
merchantability and fitness for a particular purpose.

=cut
