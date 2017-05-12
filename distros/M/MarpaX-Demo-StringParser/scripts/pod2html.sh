#!/bin/bash

NAME=MarpaX/Demo/StringParser
export NAME

pod2html.pl -i lib/$NAME.pm          -o /dev/shm/html/Perl-modules/html/$NAME.html
pod2html.pl -i lib/$NAME/Config.pm   -o /dev/shm/html/Perl-modules/html/$NAME/Config.html
pod2html.pl -i lib/$NAME/Filer.pm    -o /dev/shm/html/Perl-modules/html/$NAME/Filer.html
pod2html.pl -i lib/$NAME/Renderer.pm -o /dev/shm/html/Perl-modules/html/$NAME/Renderer.html
pod2html.pl -i lib/$NAME/Utils.pm    -o /dev/shm/html/Perl-modules/html/$NAME/Utils.html
