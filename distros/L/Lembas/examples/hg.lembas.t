#!/bin/bash

# Testing presence of Mercurial
    $ hg --version
re: Mercurial Distributed SCM \(version [\d.]+\)
    (see http://mercurial.selenic.com for more information)
    
re: Copyright \(C\) [\d-]+ Matt Mackall and others
    This is free software; see the source for copying conditions. There is NO
    warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

# Creating a repository
    $ export LEMBASTMPDIR=$(mktemp -d)
    $ cd $LEMBASTMPDIR
    $ mkdir foo
    $ cd foo
    $ pwd
re: ^/tmp/.*/foo$
    $ hg init
    $ echo "this is a file" > content
    $ cat content
    this is a file
    $ hg add content
    $ hg st
    A content
    $ hg commit -m "created repo and added a file"

# Checking that everything looks good
    $ hg log
re: changeset:   0:(??{${LembasWrap::hg_changeset_re}})
    tag:         tip
    user:        Fabrice Gabolde <fabrice.gabolde@gmail.com>
re: date:        .*
    summary:     created repo and added a file
    
# Done, cleanup
    $ cd /
    $ rm -vR $LEMBASTMPDIR
fastforward
re: removed directory: `/tmp/[^'/]*'
