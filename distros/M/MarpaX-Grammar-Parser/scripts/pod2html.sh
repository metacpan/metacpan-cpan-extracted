#!/bin/bash

NAME=MarpaX/Grammar/Parser
export NAME

pod2html.pl -i lib/$NAME.pm -o /dev/shm/html/Perl-modules/html/$NAME.html

NAME=Data/TreeDumper/Renderer/Marpa

pod2html.pl -i lib/$NAME.pm -o /dev/shm/html/Perl-modules/html/$NAME.html
