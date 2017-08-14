#!/bin/bash

NAME=MarpaX/Languages/SVG/Parser
export NAME

mkdir -p /dev/shm/html/Perl-modules/html/$NAME

# My web server's doc root is /dev/shm/html/.
# For non-Debian user's, /dev/shm/ is the built-in RAM disk.

pod2html.pl -i lib/$NAME.pm            -o /dev/shm/html/Perl-modules/html/$NAME.html
pod2html.pl -i lib/$NAME/Actions.pm    -o /dev/shm/html/Perl-modules/html/$NAME/Actions.html
pod2html.pl -i lib/$NAME/Config.pm     -o /dev/shm/html/Perl-modules/html/$NAME/Config.html
pod2html.pl -i lib/$NAME/XMLHandler.pm -o /dev/shm/html/Perl-modules/html/$NAME/XMLHandler.html
pod2html.pl -i lib/$NAME/Utils.pm      -o /dev/shm/html/Perl-modules/html/$NAME/Utils.html
