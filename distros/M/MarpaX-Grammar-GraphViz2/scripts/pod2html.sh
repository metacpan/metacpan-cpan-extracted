#!/bin/bash

NAME=MarpaX/Grammar/GraphViz2

# My web server's doc root is /dev/shm/html/.
# For non-Debian user's, /dev/shm/ is the built-in RAM disk.

pod2html.pl -i lib/$NAME.pm        -o /dev/shm/html/Perl-modules/html/$NAME.html
pod2html.pl -i lib/$NAME/Config.pm -o /dev/shm/html/Perl-modules/html/$NAME/Config.html
pod2html.pl -i lib/$NAME/Filer.pm  -o /dev/shm/html/Perl-modules/html/$NAME/Filer.html
pod2html.pl -i lib/$NAME/Utils.pm  -o /dev/shm/html/Perl-modules/html/$NAME/Utils.html
