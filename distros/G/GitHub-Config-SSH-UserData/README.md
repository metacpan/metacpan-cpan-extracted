# NAME

GitHub::Config::SSH::UserData - Read user data from comments in ssh config file

# VERSION

Version 0.06

# SYNOPSIS

    use GitHub::Config::SSH::UserData qw(get_user_data_from_ssh_cfg);

    my $udata = get_user_data_from_ssh_cfg("johndoe");

or

    my $udata = get_user_data_from_ssh_cfg("johndoe", $my_ssh_config_file);

# DESCRIPTION

This module exports a single function (`get_user_data_from_ssh_cfg()`) that
is useful when using multiple GitHub accounts with SSH keys.  First, you
should read this gist [https://gist.github.com/oanhnn/80a89405ab9023894df7](https://gist.github.com/oanhnn/80a89405ab9023894df7)
and follow the instructions.

To use `get_user_data_from_ssh_cfg()`, you must add information to your ssh config file (default
`~/.ssh/config`) by adding comments like this:

    Host github-ALL-ITEMS
    #  User: John Doe <main@addr.xy> <foo@bar> additional data
       HostName github.com
       IdentityFile ~/.ssh/abc
       IdentitiesOnly yes

    Host github-minimal
    #  User: <main@addr.xy>
       HostName github.com
       IdentityFile ~/.ssh/mini
       IdentitiesOnly yes

    Host github-std
    #  User: Jonny Controlletti <main-jc@addr.xy>
       HostName github.com
       IdentityFile ~/.ssh/std
       IdentitiesOnly yes

    Host github-std-data
    #  User: Alexander Platz <AlexPl@addr.xy> more data
       HostName github.com
       IdentityFile ~/.ssh/aaaaa
       IdentitiesOnly yes

The function looks for `Host` names beginning with `github-`. It assumes that
the part after the hyphen is your username on github. E.g., in the example
above the github usernames are `ALL-ITEMS`, `minimal`, `std` and `std-data`.

The next line must be a comment line beginning with `User:` followed by an
optional name (full name, may contain spaces) followed by one or two email addresses in angle
brackets, optionally followed by another string. See the examples above.

The following function can be exported on demand:

- `get_user_data_from_ssh_cfg(_USER_NAME_, _SSH_CFG_FILE_)`
- `get_user_data_from_ssh_cfg(_USER_NAME_)`

    The function scans file _`SSH_CFG_FILE`_ (default is
    `$ENV{HOME}/.ssh/config` and looks for `Host github-_USER_NAME_`. Then is
    scans the `User:` comment in the next line (see description above). It
    returns a reference to a hash containing:

    - `full_name`

        The full name before the first email address. If no full name is specified,
        then the value is set to _`USER_NAME`_.

        This key always exists.

    - `email`

        The first email address. This key always exists.

    - `email2`

        The second email address. This key only exists if a second email address is specified.

    - `other_data`

        Trailing string. This key only exists if a second email address if there is
        such a trailing string.

    If `Host github-_USER_NAME_` is not found, or if there is no corresponding `User:` comment, or if this comment is not formatted correctly, a fatal error occurs.

# AUTHOR

Klaus Rindfrey, `<klausrin at cpan.org.eu>`

# BUGS

Please report any bugs or feature requests to `bug-github-config-ssh-userdata
at rt.cpan.org`, or through the web interface at
[https://rt.cpan.org/NoAuth/ReportBug.html?Queue=GitHub-Config-SSH-UserData](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=GitHub-Config-SSH-UserData).
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

# SEE ALSO

[https://gist.github.com/oanhnn/80a89405ab9023894df7](https://gist.github.com/oanhnn/80a89405ab9023894df7)

[App::ghmulti](https://metacpan.org/pod/App%3A%3Aghmulti), [Dist::PolicyFiles](https://metacpan.org/pod/Dist%3A%3APolicyFiles), [Git::RemoteURL::Parse](https://metacpan.org/pod/Git%3A%3ARemoteURL%3A%3AParse)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc GitHub::Config::SSH::UserData

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=GitHub-Config-SSH-UserData](https://rt.cpan.org/NoAuth/Bugs.html?Dist=GitHub-Config-SSH-UserData)

- Search CPAN

    [https://metacpan.org/release/GitHub-Config-SSH-UserData](https://metacpan.org/release/GitHub-Config-SSH-UserData)

- GitHub Repository

    [https://github.com/klaus-rindfrey/perl-github-config-ssh-userdata](https://github.com/klaus-rindfrey/perl-github-config-ssh-userdata)

# LICENSE AND COPYRIGHT

This software is copyright (c) 2025 by Klaus Rindfrey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
