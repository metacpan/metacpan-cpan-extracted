[![Linux Build Status](https://travis-ci.org/nigelhorne/File-pfopen.svg?branch=master)](https://travis-ci.org/nigelhorne/File-pfopen)
[![Windows Build status](https://ci.appveyor.com/api/projects/status/1t1yhvagx00c2qi8?svg=true)](https://ci.appveyor.com/project/nigelhorne/cgi-info)
[![Dependency Status](https://dependencyci.com/github/nigelhorne/File-pfopen/badge)](https://dependencyci.com/github/nigelhorne/File-pfopen)
[![Coverage Status](https://coveralls.io/repos/github/nigelhorne/File-pfopen/badge.svg?branch=master)](https://coveralls.io/github/nigelhorne/File-pfopen?branch=master)
[![Kritika Analysis Status](https://kritika.io/users/nigelhorne/repos/7983554719636717/heads/master/status.svg)](https://kritika.io/users/nigelhorne/repos/7983554719636717/heads/master/)

# NAME

File::pfopen - Try hard to find a file

# VERSION

Version 0.03

# SUBROUTINES/METHODS

## pfopen

Look in a list of directories for a file with an optional list of suffixes.

    use File::pfopen 'pfopen';
    ($fh, $filename) = pfopen('/tmp:/var/tmp:/home/njh/tmp', 'foo', 'txt:bin');
    $fh = pfopen('/tmp:/var/tmp:/home/njh/tmp', 'foo', '<');

If mode (argument 4) isn't given, the file is open read/write ('+<')

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

Doesn't play well in taint mode.

Using the colon separator can cause confusion on Windows.

Would be better if the mode and suffixes options were the other way around, but it's too late to change that now.

Please report any bugs or feature requests to `bug-file-pfopen at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-pfopen](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-pfopen).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::pfopen

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/release/File-pfopen](https://metacpan.org/release/File-pfopen)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=File-pfopen](https://rt.cpan.org/NoAuth/Bugs.html?Dist=File-pfopen)

- CPANTS

    [http://cpants.cpanauthors.org/dist/File-pfopen](http://cpants.cpanauthors.org/dist/File-pfopen)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=File-pfopen](http://matrix.cpantesters.org/?dist=File-pfopen)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=File::pfopen](http://deps.cpantesters.org/?module=File::pfopen)

# LICENSE AND COPYRIGHT

Copyright 2017-2024 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

\* Personal single user, single computer use: GPL2
\* All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.
