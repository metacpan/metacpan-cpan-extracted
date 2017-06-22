[![Linux Build Status](https://travis-ci.org/nigelhorne/File-pfopen.svg?branch=master)](https://travis-ci.org/nigelhorne/File-pfopen)
[![Windows Build status](https://ci.appveyor.com/api/projects/status/1t1yhvagx00c2qi8?svg=true)](https://ci.appveyor.com/project/nigelhorne/cgi-info)
[![Dependency Status](https://dependencyci.com/github/nigelhorne/File-pfopen/badge)](https://dependencyci.com/github/nigelhorne/File-pfopen)
[![Coverage Status](https://coveralls.io/repos/github/nigelhorne/File-pfopen/badge.svg?branch=master)](https://coveralls.io/github/nigelhorne/File-pfopen?branch=master)

# File::pfopen

Try hard to find a file

# VERSION

Version 0.02

# SYNOPSIS

## pfopen

    use File::pfopen 'pfopen';
    ($fh, $filename) = pfopen('/tmp:/var/tmp:/home/njh/tmp', 'foo', 'txt:bin'));
    $fh = pfopen('/tmp:/var/tmp:/home/njh/tmp', 'foo'));

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

Please report any bugs or feature requests to `bug-file-pfopen at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-pfopen](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-pfopen).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SEE ALSO

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::pfopen

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-pfopen](http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-pfopen)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/File-pfopen](http://annocpan.org/dist/File-pfopen)

- CPAN Ratings

    [http://cpanratings.perl.org/d/File-pfopen](http://cpanratings.perl.org/d/File-pfopen)

- Search CPAN

    [http://search.cpan.org/dist/File-pfopen/](http://search.cpan.org/dist/File-pfopen/)

# LICENSE AND COPYRIGHT

Copyright 2017 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

\* Personal single user, single computer use: GPL2
\* All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.
