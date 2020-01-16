# FTN::Crypt - Encryption of the FTN messages
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

package FTN::Crypt;

use strict;
use warnings;
use v5.10.1;

use base qw/FTN::Crypt::Error/;

#----------------------------------------------------------------------#

=head1 NAME

FTN::Crypt - Encryption of the FTN messages.

=head2 VERSION

0.5.1

=cut

our $VERSION = '0.5.1';

#----------------------------------------------------------------------#

=head1 SYNOPSIS

    use FTN::Crypt;

    my $obj = FTN::Crypt->new(
        Nodelist => 'NODELIST.*',
        Pointlist => [
            'pointlist_1.*',
            'pointlist_2',
        ],
    ) or die FTN::Crypt->error;

    $obj->encrypt_message(
        Address => $ftn_address,
        Message => $msg,
    ) or die $obj->error;

=head1 DESCRIPTION

The possibility of FTN netmail encryption may be sometimes a useful option.
Corresponding nodelist flag was proposed in FSC-0073.

Although current FidoNet Policy (version 4.07 dated June 9, 1989) clearly
forbids routing of encrypted traffic without the express permission of
all the links in the delivery system, it's still possible to deliver such
messages directly. And, obviously, such routing may be allowed in FTN
networks other than FidoNet.

The proposed nodelist userflag is ENCRYPT:[TYPE], where [TYPE] is one of
'PGP2', 'PGP5', 'GnuPG'. So encryption-capable node should have something
like U,ENCRYPT:PGP5 in his nodelist record.

=cut

#----------------------------------------------------------------------#

use FTN::Crypt::Constants;
use FTN::Crypt::Msg;
use FTN::Crypt::Nodelist;

use GnuPG::Interface;

use IO::Handle;

use PGP::Finger;

use Try::Tiny;

#----------------------------------------------------------------------#

my $DEFAULT_KEYSERVER_URL = 'https://zimmermann.mayfirst.org/pks/lookup';

my $GPG2_BVER = '2.1.0';

#----------------------------------------------------------------------#

=head1 METHODS

=cut

#----------------------------------------------------------------------#

=head2 new()

Constructor.

=head3 Parameters:

=over 4

=item * C<Nodelist>: Path to nodelist file(s), either scalar or arrayref. If contains wildcard, file with maximum number in digital extension will be selected.

=item * B<Optional> C<Pointlist>: Path to pointlist file(s), either scalar or arrayref. If contains wildcard, file with maximum number in digital extension will be selected.

=item * B<Optional> C<Keyserver> Keyserver (defaults to 'https://zimmermann.mayfirst.org/pks/lookup').

=item * B<Optional> C<Pubring> Public keyring file.

=item * B<Optional> C<Secring> Secret keyring file.

=back

=head3 Returns:

Created object or error in C<FTN::Crypt-E<gt>error>.

Sample:

    my $obj = FTN::Crypt->new(
        Nodelist => 'NODELIST.*',
        Pointlist => [
            'pointlist_1.*',
            'pointlist_2',
        ],
    ) or die FTN::Crypt->error;

=cut

sub new {
    my $class = shift;
    my (%opts) = @_;

    unless (%opts) {
        $class->set_error('No options specified');
        return;
    }

    my $self = {
        keyserver_url => $opts{Keyserver} ? $opts{Keyserver} : $DEFAULT_KEYSERVER_URL,
        gnupg         => GnuPG::Interface->new(),
    };

    $self->{nodelist} = FTN::Crypt::Nodelist->new(
        Nodelist => $opts{Nodelist},
        Pointlist => $opts{Pointlist},
    );
    unless ($self->{nodelist}) {
        $class->set_error(FTN::Crypt::Nodelist->error);
        return;
    }

    $self->{gnupg}->options->hash_init(
        armor            => 1,
        meta_interactive => 0,
    );

    $self->{gnupg}->options->push_extra_args('--keyring', $opts{Pubring}) if $opts{Pubring};
    $self->{gnupg}->options->push_extra_args('--secret-keyring', $opts{Secring}) if $opts{Secring};
    $self->{gnupg}->options->push_extra_args('--always-trust');

    $self = bless $self, $class;
    return $self;
}

#----------------------------------------------------------------------#

=head2 encrypt_message()

Message encryption.

=head3 Parameters:

=over 4

=item * C<Address>: Recipient's FTN address.

=item * C<Message>: FTN message text with kludges.

=back

=head3 Returns:

Encrypted message or error in C<$obj-E<gt>error>.

Sample:

    my $res = $obj->encrypt_message(
        Address => $ftn_address,
        Message => $msg,
    ) or die $obj->error;

=cut

sub encrypt_message {
    my $self = shift;
    my (%opts) = @_;

    my $msg = FTN::Crypt::Msg->new(
        Address => $opts{Address},
        Message => $opts{Message},
    );
    unless ($msg) {
        $self->set_error(FTN::Crypt::Msg->error);
        return;
    }

    my $res;

    my ($addr, $method) = $self->{nodelist}->get_email_addr($msg->get_address);
    unless ($addr) {
        $self->set_error('Encryption-capable address not found', $self->{nodelist}->error);
        return;
    }

    my $gnupg_ver = $self->{gnupg}->version;
    if ($method eq 'PGP2') {
        if (version->parse($gnupg_ver) < version->parse($GPG2_BVER)) {
            $self->{gnupg}->options->meta_pgp_2_compatible(1);
        } else {
            $self->set_error("GnuPG is too new (ver. $gnupg_ver), can't ensure required encryption method ($method)");
            return;
        }
    } elsif ($method eq 'PGP5') {
        $self->{gnupg}->options->meta_pgp_5_compatible(1);
    }

    unless ($self->_lookup_key($addr) || $self->_import_key($addr)) {
        $self->set_error("PGP key for $addr not found");
        return;
    }

    my $key_id = $self->_select_key($addr);
    $self->{gnupg}->options->push_recipients($key_id);

    my ($in_fh, $out_fh, $err_fh) = (IO::Handle->new(), IO::Handle->new(),
        IO::Handle->new());

    my $handles = GnuPG::Handles->new(
        stdin  => $in_fh,
        stdout => $out_fh,
        stderr => $err_fh,
    );

    my $pid = $self->{gnupg}->encrypt(handles => $handles);

    print $in_fh $msg->get_text;
    close $in_fh;

    my $msg_enc = join '', <$out_fh>;
    close $out_fh;

    close $err_fh;

    waitpid $pid, 0;

    if ($msg_enc) {
        unless ($msg->set_text($msg_enc)) {
            $self->set_error("Can't write message text", $msg->error);
            return;
        }
        unless ($msg->add_kludge("$FTN::Crypt::Constants::ENC_MESSAGE_KLUDGE: $method")) {
            $self->set_error("Can't modify message kludges", $msg->error);
            return;
        }

        $res = $msg->get_message;
        unless ($res) {
            $self->set_error("Can't get message", $msg->error);
            return;
        }
    } else {
        $self->set_error('Message enccryption failed');
        return;
    }

    return $res;
}

#----------------------------------------------------------------------#

=head2 decrypt_message()

Message decryption.

=head3 Parameters:

=over 4

=item * C<Address>: Recipient's FTN address.

=item * C<Message>: FTN message text with kludges.

=item * C<Passphrase>: Key passphrase.

=back

=head3 Returns:

Decrypted message or error in C<$obj-E<gt>error>.

Sample:

    my $res = $obj->decrypt_message(
        Address => $ftn_address,
        Message => $msg,
        Passphrase => $pass,
    ) or die $obj->error;

=cut

sub decrypt_message {
    my $self = shift;
    my (%opts) = @_;

    unless (%opts) {
        $self->set_error('No options specified');
        return;
    }
    unless (defined $opts{Passphrase}) {
        $self->set_error('No passphrase specified');
        return;
    }

    my $msg = FTN::Crypt::Msg->new(
        Address => $opts{Address},
        Message => $opts{Message},
    );
    unless ($msg) {
        $self->set_error(FTN::Crypt::Msg->error);
        return;
    }

    my $res;

    my $method_used;
    foreach my $c (@{$msg->get_kludges}) {
        foreach my $k (@{$c}) {
            $method_used = $1 if $k =~ /^$FTN::Crypt::Constants::ENC_MESSAGE_KLUDGE:\s+(\w+)$/;
        }
    }
    unless ($method_used) {
        $self->set_error('Message seems not to be encrypted');
        return;
    }

    my ($addr, $method) = $self->{nodelist}->get_email_addr($msg->get_address);
    unless ($addr) {
        $self->set_error('Encryption-capable address not found', $self->{nodelist}->error);
        return;
    }
    unless ($method) {
        $self->set_error('Encryption method not found', $self->{nodelist}->error);
        return;
    }

    if ($method ne $method_used) {
        $self->set_error("Message is encrypted with $method_used while node uses $method");
        return;
    }

    my ($in_fh, $out_fh, $err_fh, $pass_fh) = (IO::Handle->new(),
        IO::Handle->new(), IO::Handle->new(), IO::Handle->new());

    my $handles = GnuPG::Handles->new(
        stdin      => $in_fh,
        stdout     => $out_fh,
        stderr     => $err_fh,
        passphrase => $pass_fh,
    );

    my $pid = $self->{gnupg}->decrypt(handles => $handles);

    print $pass_fh $opts{Passphrase};
    close $pass_fh;

    print $in_fh $msg->get_text;
    close $in_fh;

    my $msg_dec = join '', <$out_fh>;
    close $out_fh;

    close $err_fh;

    waitpid $pid, 0;

    if ($msg_dec) {
        unless ($msg->set_text($msg_dec)) {
            $self->set_error("Can't write message text", $msg->error);
            return;
        }
        unless ($msg->remove_kludge($FTN::Crypt::Constants::ENC_MESSAGE_KLUDGE)) {
            $self->set_error("Can't modify message kludges", $msg->error);
            return;
        }

        $res = $msg->get_message;
        unless ($res) {
            $self->set_error("Can't get message", $msg->error);
            return;
        }
    } else {
        $self->set_error('Message decryption failed');
        return;
    }

    return $res;
}

#----------------------------------------------------------------------#

sub _lookup_key {
    my $self = shift;
    my ($uid) = @_;

    my ($out_fh, $err_fh) = (IO::Handle->new(), IO::Handle->new());

    my $handles = GnuPG::Handles->new(
        stdout => $out_fh,
        stderr => $err_fh,
    );

    my $pid = $self->{gnupg}->list_public_keys(
        handles      => $handles,
        command_args => [$uid],
    );

    my $out = join '', <$out_fh>;

    close $out_fh;
    close $err_fh;

    waitpid $pid, 0;

    return $out ? 1 : 0;
}

#----------------------------------------------------------------------#

sub _import_key {
    my ($self, $uid) = @_;

    return if $self->_lookup_key($uid);

    my $res;

    try {
        my $finger = PGP::Finger->new(
            sources => [
                PGP::Finger::Keyserver->new(
                    url => $self->{keyserver_url},
                ),
                # Now there are no PGP-related DNS records in fidonet.net zone
                #~ PGP::Finger::DNS->new(
                    #~ dnssec => 1,
                    #~ rr_types => ['OPENPGPKEY', 'TYPE61'],
                #~ ),
            ],
        );
        $res = $finger->fetch($uid);
    } catch {
        return;
    };

    if ($res) {
        my ($in_fh, $out_fh, $err_fh) = (IO::Handle->new(),
             IO::Handle->new(), IO::Handle->new());

        my $handles = GnuPG::Handles->new(
            stdin  => $in_fh,
            stdout => $out_fh,
            stderr => $err_fh,
        );

        my $pid = $self->{gnupg}->import_keys(handles => $handles);

        print $in_fh $res->as_string('armored');
        close $in_fh;

        close $out_fh;
        close $err_fh;

        waitpid $pid, 0;

        return 1;
    }

    return;
}

#----------------------------------------------------------------------#

sub _select_key {
    my ($self, $uid) = @_;

    return unless $self->_lookup_key($uid);

    my @keys;
    foreach my $key ($self->{gnupg}->get_public_keys($uid)) {
        push @keys, [$key->creation_date, $key->hex_id]
            if !$self->_key_is_disabled($key) && $self->_key_can_encrypt($key);
        foreach my $subkey (@{$key->subkeys_ref}) {
            push @keys, [$subkey->creation_date, $subkey->hex_id]
                if !$self->_key_is_disabled($subkey) && $self->_key_can_encrypt($subkey);
        }
    }

    @keys = map { '0x' . substr $_->[1], -8 }
            sort { $b->[0] <=> $a->[0] }
            @keys;

    return $keys[0];
}

#----------------------------------------------------------------------#

sub _key_is_disabled {
    my ($self, $key) = @_;

    return index($key->usage_flags, 'D') != -1;
}

#----------------------------------------------------------------------#

sub _key_can_encrypt {
    my ($self, $key) = @_;

    return index($key->usage_flags, 'E') != -1;
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

=head1 INSTALLATION

Using C<cpan>:

    $ cpan FTN::Crypt

Manual install:

    $ perl Makefile.PL
    $ make
    $ make test
    $ make install

=head1 REFERENCES

=over 4

=item 1 L<FidoNet Policy Document Version 4.07|https://www.fidonet.org/policy4.txt>

=item 2 L<FTS-5001 - Nodelist flags and userflags|http://ftsc.org/docs/fts-5001.006>

=item 3 L<FSC-0073 - Encrypted message identification for FidoNet *Draft I*|http://ftsc.org/docs/fsc-0073.001>

=back

=cut
