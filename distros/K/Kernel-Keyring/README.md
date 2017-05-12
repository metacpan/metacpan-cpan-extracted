<div>
    <p>
        <img src="https://travis-ci.org/lixmal/Kernel-Keyring.png?branch=master" alt="Travis CI build status">
    </p>
</div>

# NAME

Kernel::Keyring - Wrapper for kernel keyring syscalls

# SYNOPSIS

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

# DESCRIPTION

[Kernel::Keyring](https://metacpan.org/pod/Kernel::Keyring) is a rudimentary wrapper for libkeyutils based syscalls.
Provided functions should suffice for the typical use case: storing passwords/keys in a secure location, the kernel.
Data stored in the kernel keyring doesn't get swapped to disk (unless big\_key type is used) and it can automatically time out.

A general overview of the keyring facility is given here: [http://man7.org/linux/man-pages/man7/keyrings.7.html](http://man7.org/linux/man-pages/man7/keyrings.7.html)

More documentation is available on the man page of keyctl [http://man7.org/linux/man-pages/man1/keyctl.1.html](http://man7.org/linux/man-pages/man1/keyctl.1.html)

Module exports all functions by default.

All functions "die" with a proper message on errors.

# PREREQUISITES

The module requires kernel support and the `keyutils` library to be installed.

- Package names for Ubuntu/Debian: `libkeyutils-dev` `libkeyutils1`
- Package names for RedHat: `keyutils-devel` `keyutils-libs`
- Source as tar: [http://people.redhat.com/~dhowells/keyutils/](http://people.redhat.com/~dhowells/keyutils/)

# FUNCTIONS

### key\_add

    key_add($type, $name, $data, $keyring)

Adds key with given type, name and data to the keyring.

`$type` is usually the string `user`, more info on the man page of `keyctl`.

`$name` is the name of the key, can be used for searching (not implemented yet).

`$data` is an arbitrary string of data. Strings with wide characters should be encoded to ensure proper string length.
Else data might appear truncated on key retrieval.

`$keyring` can be be any of the following:

- Thread keyring: `@t`
- Process keyring: `@p`
- Session keyring: `@s`
- User specific keyring: `@u`
- User default session keyring: `@us`
- Group specific keyring: `@g`

The function returns the assigned key id on success, dies on error.

Corresponds to `keyctl add <type> <desc> <data> <keyring>` shell command from keyutils package

### key\_get\_by\_id

    key_add($id)

Retrieves key string with given id.

Corresponds to `keyctl read <key>` shell command from keyutils package

### key\_timeout

    key_timeout($id, $seconds)

Sets timeout on given id in seconds. Kernel automatically unlinks timed out keys.

Corresponds to `keyctl timeout <key> <timeout>` shell command from keyutils package

### key\_unlink

    key_unlink($id, $keyring)

Deletes key with given id from given keyring (e.g. `@s`). Supports only the two argument version for fast lookups.

Corresponds to `keyctl unlink <key> <keyring>` shell command from keyutils package

### key\_session

    key_session($name)

Creates a new keyring and attaches it to the current session. Doesn't place the program in a new shell, unlike the `keyctl` command.
This function might be necessary for unattended applications, like server software.
Without calling key\_session first the session keyring is destroyed on user logout (after starting the app), resulting in "Key has been revoked" error messages.
Omitting `$name` will result in the keyring name defaulting to a random 32bit number appended to "K::KR::" (seen in file /proc/keys).

Corresponds to `keyctl session <name>` shell command from keyutils package

### key\_perm

    key_perm($id, $mask)

Sets permission on given key id.

Mask should be given in hex format
as a combination of (following paragraph taken from man page of `keyctl`:

    Possessor UID       GID       Other     Permission Granted
    ========  ========  ========  ========  ==================
    01000000  00010000  00000100  00000001  View
    02000000  00020000  00000200  00000002  Read
    04000000  00040000  00000400  00000004  Write
    08000000  00080000  00000800  00000008  Search
    10000000  00100000  00001000  00000010  Link
    20000000  00200000  00002000  00000020  Set Attribute
    3f000000  003f0000  00003f00  0000003f  All

`View` permits the type, description and other parameters of a key to be viewed.

`Read` permits the payload (or keyring list) to be read if supported by the type.

`Write` permits the payload (or keyring list) to be modified or updated.

`Search` on a key permits it to be found when a keyring to which it is linked is searched.

`Link` permits a key to be linked to a keyring.

`Set Attribute` permits a key to have its owner, group membership, permissions mask and timeout changed.

Corresponds to `keyctl setperm <key> <mask>` shell command from keyutils package

### key\_revoke

    key_revoke($id)

Revokes access to the key with given id. No operations other than `unlink` are possible on revoked keys.

Corresponds to `keyctl revoke <key>` shell command from keyutils package

# REPOSITORY

[http://github.com/lixmal/Kernel-Keyring](http://github.com/lixmal/Kernel-Keyring)

# AUTHOR

Viktor Liu <lixmal@cpan.org>

# COPYRIGHT AND LICENSING

Copyright (C) 2016-2017 Viktor Liu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Details can be found in the file LICENSE.
