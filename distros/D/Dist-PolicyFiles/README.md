# NAME

Dist::PolicyFiles - Generate CONTRIBUTING.md and SECURITY.md

# VERSION

Version 0.03

# SYNOPSIS

    use Dist::PolicyFiles;

    my $obj = Dist::PolicyFiles->new(login => $login_name, module => $module);
    $obj->create_contrib_md();
    $obj->create_security_md();

# DESCRIPTION

This module is used to generate the policy files `CONTRIBUTING.md` and
`SECURITY.md`. It comes with the [dist-policyfiles](https://metacpan.org/pod/dist-policyfiles) command line tool.

## METHODS

### Constructor

The constructor `new()` accepts the following named arguments, where `login`
and `module` are mandatory:

- `dir`

    Optional. Directory where the policy files should be written. By default, this
    is the current working directory. See also accessor of the same name.

- `email`

    Optional. User's email address. If not specified, `new()` tries to read it
    from comments in `HOME/.ssh/config` (see [GitHub::Config::SSH::UserData](https://metacpan.org/pod/GitHub%3A%3AConfig%3A%3ASSH%3A%3AUserData)).

    See also the accessor method of the same name.

- `full_name`

    Optional. User's full name. If not specified, `new()` tries to read it from
    comments in `HOME/.ssh/config` (see [GitHub::Config::SSH::UserData](https://metacpan.org/pod/GitHub%3A%3AConfig%3A%3ASSH%3A%3AUserData)).

    See also the accessor method of the same name.

- `login`

    Mandatory. User's github login name.

    See also the accessor method of the same name.

- `module`

    Mandatory. Module name.

    See also the accessor method of the same name.

- `prefix`

    Optional. Prefix for repo name, see method `create_security_md()`. Default is
    an empty string.

    See also the accessor method of the same name.

- `uncapitalize`

    Optional. Set this to _`true`_ if your repo name is lower case, see method
    `create_security_md()`. Default is _`false`_.

    See also the accessor method of the same name.

### Generation of policy files

- `create_contrib_md(_CONTRIB_MD_TMPL_)`
- `create_contrib_md()`

    Creates `CONTRIBUTING.md` in directory `dir` (see corresponding constructor
    argument). Optional argument _`CONTRIB_MD_TMPL`_ is the name of a template
    file (see [Text::Template](https://metacpan.org/pod/Text%3A%3ATemplate)) for this policy. If this argument is not
    specified, then the internal default template is used (see constant
    _`INTERNAL_CONTRIB_MD`_).

    The template can use the following variables:

    - `$cpan_rt`

        CPAN's request tracker, e.g.:

            https://rt.cpan.org/NoAuth/ReportBug.html?Queue=My-Great-Module

    - `$email`

        User's email address.

    - `$full_name`

        User's full name.

    - `$github_i`

        Github issue, e.g.:

            https://github.com/jd/My-Great-Module/issues

        See method `create_security_md()` for information on how the repo name is generated.

    - `$module`

- `create_security_md(_NAMED_ARGUMENTS_)`

    Creates `SECURITY.md` in directory `dir` (see corresponding constructor
    argument). The arguments accepted by this method are exactly the same as those accepted by the `new()` method of [Software::Security::Policy::Individual](https://metacpan.org/pod/Software%3A%3ASecurity%3A%3APolicy%3A%3AIndividual).

    However, there are the following defaults:

    - `maintainer:`

        User's full name and email address, e.g.:

            'John Doe <jd@cpan.org>'

    - `program`

        Module name, see constructor argument `module`.

    - `url`

            'https://github.com/LOGIN/REPO/blob/main/SECURITY.md'

        where:

        - _`LOGIN`_

            User's login name, see constructor argument `login`.

        - _`REPO`_

            The repo name is structured as follows:

            - The repo name begins with the contents of &lt;prefix()>.
            - The rest of the repo name is the module name where the double colons are replaced with hyphens.
            - If the constructor argument `uncapitalise` was _`true`_, the latter part of
            the repo name is changed to lower case.

    To completely disable one of these arguments, set it to `undef` or an empty string.

### Accessors

- `dir()`

    Returns the value passed via the constructor argument `dir` or the default
    value `'.'`.

- `email()`

    Returns the user's email address.

- `full_name()`

    Returns the user's full name.

- `login()`

    Returns the value passed via the constructor argument `login`.

- `module()`

    Returns the value passed via the constructor argument `module`.

- `prefix()`

    Returns the value passed via the constructor argument `prefix` or the default
    value (empty string).

- `uncapitalize()`

    Returns the value passed via the constructor argument `uncapitalize` or the default
    value (_`false`_).

## CONSTANTS

Constant _`INTERNAL_CONTRIB_MD`_ containes the internal template used to
create `CONTRIBUTING.md`. The constant is not exported. If necessary, access
it as follows: `Dist::PolicyFiles::INTERNAL_CONTRIB_MD`.

# AUTHOR

Klaus Rindfrey, `<klausrin at cpan.org.eu>`

# BUGS

Please report any bugs or feature requests to `bug-dist-policyfiles at rt.cpan.org`, or through
the web interface at [https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dist-PolicyFiles](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dist-PolicyFiles).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SEE ALSO

[dist-policyfiles](https://metacpan.org/pod/dist-policyfiles),
[GitHub::Config::SSH::UserData](https://metacpan.org/pod/GitHub%3A%3AConfig%3A%3ASSH%3A%3AUserData),
[Software::Security::Policy::Individual](https://metacpan.org/pod/Software%3A%3ASecurity%3A%3APolicy%3A%3AIndividual),
[Text::Template](https://metacpan.org/pod/Text%3A%3ATemplate)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dist::PolicyFiles

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-PolicyFiles](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-PolicyFiles)

- Search CPAN

    [https://metacpan.org/release/Dist-PolicyFiles](https://metacpan.org/release/Dist-PolicyFiles)

- GitHub Repository

    [https://github.com/klaus-rindfrey/perl-dist-policyfiles](https://github.com/klaus-rindfrey/perl-dist-policyfiles)

# LICENSE AND COPYRIGHT

This software is copyright (c) 2025 by Klaus Rindfrey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
