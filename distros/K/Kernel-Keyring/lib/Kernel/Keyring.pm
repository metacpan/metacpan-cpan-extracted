package Kernel::Keyring;
use strict;
use warnings;

our $VERSION = '0.07';

use Carp 'croak';
use Exporter 'import';
use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

use constant PREFIX => 'K::KR::';

our @EXPORT = qw/
    key_add
    key_get_by_id
    key_timeout
    key_unlink
    key_session
    key_perm
    key_revoke
/;

my %keyrings = (
    '@t'  => -1,  # KEY_SPEC_THREAD__key
    '@p'  => -2,  # KEY_SPEC_PROCESS__key
    '@s'  => -3,  # KEY_SPEC_SESSION__key
    '@u'  => -4,  # KEY_SPEC_USER__key
    '@us' => -5,  # KEY_SPEC_USER_SESSION__key
    '@g'  => -6,  # KEY_SPEC_GROUP__key
    '@a'  => -7,  # KEY_SPEC_REQKEY_AUTH_KEY
);


sub key_add {
    if (@_ != 4) {
        croak 'Wrong number of parameters';
    }
    my $keyring = $keyrings{$_[3]} or croak "Unknown keyring: $_[3]";
    my $id = _key_add($_[0], $_[1], $_[2], length $_[2], $keyring);
    if ($id < 0) {
        die "Error adding key: $!\n"
    }
    return $id;
}

sub key_get_by_id {
    if (!$_[0]) {
        croak 'No key id given';
    }
    my ($ret, $key) = _key_read($_[0]);
    if ($ret < 0) {
        die "Error retrieving key: $!\n"
    }
    return $key;
}

sub key_timeout {
    if (@_ != 2) {
        croak 'Wrong number of parameters';
    }
    my $ret = _key_timeout(@_);
    if ($ret < 0) {
        die "Error setting timeout: $!\n"
    }
    return $ret;
}

sub key_unlink {
    if (@_ != 2) {
        croak 'Wrong number of parameters';
    }
    my $keyring = $keyrings{$_[1]} or croak "Unknown keyring: $_[1]";
    my $ret = _key_unlink($_[0], $keyring);
    if ($ret < 0) {
        die "Error unlinking key: $!\n"
    }
    return $ret;
}

sub key_session {
    my $id = _key_session($_[0] || PREFIX . int rand 2**32);
    if ($id < 0) {
        die "Error joining session: $!\n"
    }
    return $id;
}

sub key_perm {
    if (@_ != 2) {
        croak 'Wrong number of parameters';
    }
    my $ret = _key_perm(@_);
    if ($ret < 0) {
        die "Error setting permissions: $!\n"
    }
    return $ret;
}

sub key_revoke {
    if (@_ != 1) {
        croak 'Wrong number of parameters';
    }
    my $ret = _key_revoke(@_);
    if ($ret < 0) {
        die "Error revoking key: $!\n"
    }
    return $ret;
}

1;


__END__

=pod

=encoding UTF-8

=begin html

<p>
    <img src="https://travis-ci.org/lixmal/Kernel-Keyring.png?branch=master" alt="Travis CI build status">
</p>

=end html

=head1 NAME

Kernel::Keyring - Wrapper for kernel keyring syscalls

=head1 SYNOPSIS

    use Kernel::Keyring;
    use utf8;
    use Encode;

    # create keyring for current session with name 'Test'
    key_session 'Test';

    # add new user type key named 'password' with data 'secretPW' in session keyring (@s)
    my $id = key_add 'user', 'password', 'secretPW', '@s';

    # same with wide characters
    my $id2 = key_add 'user', 'secret_name', Encode::encode('UTF-8', '刘维克多'), '@s';

    # retrieve data for given id
    my $data = key_get_by_id $id;

    # set timeout on key to 60 seconds
    key_timeout $id, 60;

    # clear timeout
    key_timeout $id, 0;

    # set key permissions to all for possessor, none for anyone else
    key_perm $id, 0x3f000000;

    # revoke access to key
    key_revoke $id;

    # delete key for given keyring
    key_unlink $id, '@s';

=head1 DESCRIPTION

L<Kernel::Keyring> is a rudimentary wrapper for libkeyutils based syscalls.
Provided functions should suffice for the typical use case: storing passwords/keys in a secure location, the kernel.
Data stored in the kernel keyring doesn't get swapped to disk (unless big_key type is used) and it can automatically time out.

A general overview of the keyring facility is given here: L<http://man7.org/linux/man-pages/man7/keyrings.7.html>

More documentation is available on the man page of keyctl L<http://man7.org/linux/man-pages/man1/keyctl.1.html>


Module exports all functions by default.

All functions "die" with a proper message on errors.

=head1 PREREQUISITES

The module requires kernel support and the C<keyutils> library to be installed.

=over 1

=item Package names for Ubuntu/Debian: C<libkeyutils-dev> C<libkeyutils1>

=item Package names for RedHat: C<keyutils-devel> C<keyutils-libs>

=item Source as tar: L<http://people.redhat.com/~dhowells/keyutils/>

=back


=head1 FUNCTIONS

=head3 key_add

    key_add($type, $name, $data, $keyring)

Adds key with given type, name and data to the keyring.

C<$type> is usually the string C<user>, more info on the man page of C<keyctl>.

C<$name> is the name of the key, can be used for searching (not implemented yet).

C<$data> is an arbitrary string of data. Strings with wide characters should be encoded to ensure proper string length.
Else data might appear truncated on key retrieval.

C<$keyring> can be be any of the following:

=over 1

=item Thread keyring: C<@t>

=item Process keyring: C<@p>

=item Session keyring: C<@s>

=item User specific keyring: C<@u>

=item User default session keyring: C<@us>

=item Group specific keyring: C<@g>

=back

The function returns the assigned key id on success, dies on error.


Corresponds to C<keyctl add E<lt>typeE<gt> E<lt>descE<gt> E<lt>dataE<gt> E<lt>keyringE<gt>> shell command from keyutils package

=head3 key_get_by_id

    key_add($id)

Retrieves key string with given id.


Corresponds to C<keyctl read E<lt>keyE<gt>> shell command from keyutils package

=head3 key_timeout

    key_timeout($id, $seconds)

Sets timeout on given id in seconds. Kernel automatically unlinks timed out keys.


Corresponds to C<keyctl timeout E<lt>keyE<gt> E<lt>timeoutE<gt>> shell command from keyutils package

=head3 key_unlink

    key_unlink($id, $keyring)

Deletes key with given id from given keyring (e.g. C<@s>). Supports only the two argument version for fast lookups.


Corresponds to C<keyctl unlink E<lt>keyE<gt> E<lt>keyringE<gt>> shell command from keyutils package

=head3 key_session

    key_session($name)

Creates a new keyring and attaches it to the current session. Doesn't place the program in a new shell, unlike the C<keyctl> command.
This function might be necessary for unattended applications, like server software.
Without calling key_session first the session keyring is destroyed on user logout (after starting the app), resulting in "Key has been revoked" error messages.
Omitting C<$name> will result in the keyring name defaulting to a random 32bit number appended to "K::KR::" (seen in file /proc/keys).


Corresponds to C<keyctl session E<lt>nameE<gt>> shell command from keyutils package

=head3 key_perm

    key_perm($id, $mask)

Sets permission on given key id.

Mask should be given in hex format
as a combination of (following paragraph taken from man page of C<keyctl>:

    Possessor UID       GID       Other     Permission Granted
    ========  ========  ========  ========  ==================
    01000000  00010000  00000100  00000001  View
    02000000  00020000  00000200  00000002  Read
    04000000  00040000  00000400  00000004  Write
    08000000  00080000  00000800  00000008  Search
    10000000  00100000  00001000  00000010  Link
    20000000  00200000  00002000  00000020  Set Attribute
    3f000000  003f0000  00003f00  0000003f  All

C<View> permits the type, description and other parameters of a key to be viewed.

C<Read> permits the payload (or keyring list) to be read if supported by the type.

C<Write> permits the payload (or keyring list) to be modified or updated.

C<Search> on a key permits it to be found when a keyring to which it is linked is searched.

C<Link> permits a key to be linked to a keyring.

C<Set Attribute> permits a key to have its owner, group membership, permissions mask and timeout changed.


Corresponds to C<keyctl setperm E<lt>keyE<gt> E<lt>maskE<gt>> shell command from keyutils package

=head3 key_revoke

    key_revoke($id)

Revokes access to the key with given id. No operations other than C<unlink> are possible on revoked keys.


Corresponds to C<keyctl revoke E<lt>keyE<gt>> shell command from keyutils package

=head1 REPOSITORY

L<http://github.com/lixmal/Kernel-Keyring>

=head1 AUTHOR

Viktor Liu E<lt>lixmal@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSING

Copyright (C) 2016-2017 Viktor Liu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Details can be found in the file LICENSE.

=cut

