# Git-Glog

[Git::Glog](https://metacpan.org/module/Git::Glog) is a perl module
which provides the script git-glog.

git-glog is a perl wrapper around git-log that displays gravatars in your
256 color terminal.


## INSTALLATION

To install this module from cpan:

    cpan -i Git::Glog

or

    cpanm Git::Glog

To install this module from source, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install


## USAGE

    git glog [options] [-- git-log options]

     Options:
       --help|-h            brief help message
       --width|-w           set the width of the output ascii
       --dir|-d             directory to fetch/store ascii gravatars

Please see: `man git-glog`


## SETTINGS

git-glog will attempt to read your git settings for the following:

*   `glog.dir`
    
    The directory to store and read ascii gravatars from.
    Default is `$HOME/.git-glog/`
    
        git config --global --add glog.dir $HOME/.git-glog
    
    To take a peek at the stored ascii gravatars, try:
    
        cat $(git config --get glog.dir)/* | gunzip | less -R
    
    or
    
        cat ~/.git-glog/* | gunzip | less -R


## EXAMPLES

A fancy git log:

    git glog -- --stat --summary --pretty=fuller


## CAVEATS

git may complain of a non-zero exit code if git-glog does not complete.
This will probably occur if the log is generated from a large repository or
is left completely open ended ( no from... to ).

Right now the output is piped to `less -R` ( when STDOUT is a tty ). FYI.


## WHY ON EARTH WOULD YOU MAKE THIS?

Because I thought it would be fun.  It was.


## SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc commands.

    perldoc Git::Glog
    perldoc git-glog

You can also look for information at:

*   GitHub in moshen/Git-Glog (report bugs here)
    https://github.com/moshen/Git-Glog

*   RT, CPAN's request tracker
    http://rt.cpan.org/NoAuth/Bugs.html?Dist=Git-Glog

*   AnnoCPAN, Annotated CPAN documentation
    http://annocpan.org/dist/Git-Glog

*   CPAN Ratings
    http://cpanratings.perl.org/d/Git-Glog

*   Search CPAN
    http://search.cpan.org/dist/Git-Glog/


## LICENSE AND COPYRIGHT

Copyright (C) 2011 Colin Kennedy

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

