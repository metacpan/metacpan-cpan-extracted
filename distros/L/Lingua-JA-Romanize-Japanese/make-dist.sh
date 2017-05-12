#!/bin/sh

die () {
    echo "$*" >&2
    exit 1
}
doit () {
    echo "\$ $*" >&2
    $* || die "[ERROR:$?]"
}

dic=skk/SKK-JISYO.S
doit wget -O $dic~ http://openlab.jp/skk/skk/dic/SKK-JISYO.S
diff $dic $dic~ > /dev/null || doit /bin/mv -f $dic~ $dic
/bin/rm -f $dic~

egrep -v '^t/.*\.t$' MANIFEST > MANIFEST~
ls t/*.t >> MANIFEST~
diff MANIFEST MANIFEST~ > /dev/null || doit /bin/mv -f MANIFEST~ MANIFEST
/bin/rm -f MANIFEST~

[ -f Makefile ] && doit make clean
[ -f META.yml ] || touch META.yml
doit perl Makefile.PL
doit make
doit make disttest

main=`grep 'lib/.*pm$' < MANIFEST | head -1`
[ "$main" == "" ] && die "main module is not found in MANIFEST"
doit pod2text $main > README~
diff README README~ > /dev/null || doit /bin/mv -f README~ README
/bin/rm -f README~

doit make dist
[ -d blib ] && doit /bin/rm -fr blib
[ -f pm_to_blib ] && doit /bin/rm -f pm_to_blib
[ -f Makefile ] && doit /bin/rm -f Makefile
[ -f Makefile.old ] && doit /bin/rm -f Makefile.old

ls -lt *.tar.gz | head -1
