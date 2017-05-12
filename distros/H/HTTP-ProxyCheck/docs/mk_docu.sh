#!/bin/sh
#===============================================================================
# mk_docu.sh Version 1.0, Thu May 29 14:50:22 CEST 2003
#===============================================================================
# Copyright (c) 2003 Thomas Weibel. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#===============================================================================

lib_path="../lib/HTTP"

docu_path="."

echo "Creating documentation"

cat > style.css <<STYLE
BODY {
    background: white;
    color: black;
    font-family: arial,sans-serif;
    font-size: medium;
    margin: 0;
    padding: 1ex;
}

CODE {
    font-size: large;
}

A {
    text-decoration: none;
}

A:link {
    background: transparent;
    color: #336699;
}

A:visited {
    background: transparent;
    color: #336699;
}

DT {
    margin-top: 1em;
}

PRE {
    background: #eeeeee;
    border: 1px solid #888888;
    color: black;
    padding-top: 1em;
    padding-bottom: 1em;
    white-space: pre;
}

H1 {
    background: transparent;
    color: #336699;
    font-size: large;
}

H2      {
    background: transparent;
    color: #336699;
    font-size: large;
}

H3     {
    background: transparent;
    color: #336699;
    font-size: medium;
}

LI {
    line-height: 1.2em;
}
STYLE

pod2html --css style.css --backlink "[ back to top ]" --infile $lib_path/ProxyCheck.pm --outfile $docu_path/HTTP_ProxyCheck.html

pod2text $lib_path/ProxyCheck.pm > $docu_path/HTTP_ProxyCheck.txt

rm -f pod2htmd.* pod2htmi.*

echo "Documentation created"
