#!/bin/sh

class_name=Geo::OLC::XS

dir_name=$(echo $class_name | sed -e 's/::/-/g')
errors="/tmp/release_$$_errors"
rm -f $errors

echo
echo "== Preparing Makefile =="
make distclean > /dev/null 2>&1
perl Makefile.PL > /dev/null 2>&1
rm -f /tmp/release_$$_make
make distclean 2>&1 | tee -a /tmp/release_$$_make
perl Makefile.PL 2>&1 | tee -a /tmp/release_$$_make

echo "== Checking missing files in MANIFEST ==" >>$errors
cat /tmp/release_$$_make | egrep '^Not in MANIFEST:' | awk -F: '{print $2}' | sed 's/^ *//g' >>$errors

echo
echo "== Building distribution =="
rm -f /tmp/release_$$_make
rm -f ${dir_name}-*.tar
rm -f ${dir_name}-*.tar.gz
make dist 2>&1 | tee -a /tmp/release_$$_make
name=$(cat /tmp/release_$$_make | egrep "^Created ${dir_name}.*.gz" | awk '{print $2}' | sed 's/\.tar\.gz$//g')

echo
echo "== Extracting distribution $name =="
rm -f /tmp/release_$$_make
rm -fr "./$name"
tar zxvf "$name.tar.gz"

echo
echo "== Compiling & testing distribution $name =="
pushd "./$name"
perl Makefile.PL
make test 2>&1 | tee -a /tmp/release_$$_make
popd
rm -fr "./$name"

echo "== Checking test results ==" >>$errors
cat /tmp/release_$$_make | egrep '^Result:' >>$errors
rm -f /tmp/release_$$_make

echo "== Checking git status ==" >>$errors
git status >>$errors

echo "== Checking current version ==" >>$errors
git grep -E '(Version|VERSION).*[0-9]' | egrep -v '^(duktape.[hc]|duk_.*.[hc]|ppport.h|Makefile.PL|bin/release.sh)' | egrep -v 'XSLoader|head' >>$errors

echo "== Checking last documented version ==" >>$errors
cat Changes | head -n 1 | awk '{print $1}' >>$errors

echo "== Checking missing modules required by library ==" >>$errors
mkfifo /tmp/release_$$_a
git grep -E '^[ \t]*use' | egrep '\.(pm|pl):' | egrep -v '^(bin)/' | sed 's/::/@@/g' | awk -F: '{print $2}' | sed 's/qw.*//g' | sed 's/#.*//g' | tr -d ';' | sed 's/ *$//g' | sed 's/@@/::/g' | egrep -v "use (strict|warnings|utf8|parent|$class_name)" | sed 's/^use //g' | sort -u >/tmp/release_$$_a &
mkfifo /tmp/release_$$_b
cat Makefile.PL | awk '{if ($0 ~ /},/) {p=0; next;} if (p) { print; } if ($0 ~ /PREREQ_PM/) {p=1; next;}}' | awk -F\' '{print $2}' | egrep -v 'ExtUtils::XSpp' | sort -u >/tmp/release_$$_b &
diff /tmp/release_$$_a /tmp/release_$$_b >>$errors
rm -f /tmp/release_$$_a /tmp/release_$$_b

echo "== Checking missing modules required by tests ==" >>$errors
mkfifo /tmp/release_$$_a
git grep use t | sed 's/::/@@/g' | awk -F: '{print $2}' | sed 's/qw.*//g' | sed 's/#.*//g' | tr -d ';' | sed 's/ *$//g' | sed 's/@@/::/g' | egrep -v "use (strict|warnings|utf8|parent|$class_name)|^[ \t]*use_ok" | sed 's/^use //g' | sort -u >/tmp/release_$$_a &
mkfifo /tmp/release_$$_b
cat Makefile.PL | awk '{if ($0 ~ /},/) {p=0; next;} if (p) { print; } if ($0 ~ /TEST_REQUIRES/) {p=1; next;}}' | awk -F\' '{print $2}' | sort -u >/tmp/release_$$_b &
diff /tmp/release_$$_a /tmp/release_$$_b >>$errors
rm -f /tmp/release_$$_a /tmp/release_$$_b

echo "== Checking suspicious declarations ==" >>$errors
git grep -E '(for|while|if|do)[ \t]*\((int|char|long|unsigned|float|double|size_t) ' | egrep -v '\.(cc):' >>$errors

echo
echo "== Ready to upload $name.tar.gz to CPAN =="

if [ -s $errors ]
then
    echo
    echo
    echo
    echo "================================="
    echo "== CHECK THESE POSSIBLE ERRORS =="
    echo "================================="
    echo
    cat $errors
    echo
    echo "================================="
    rm -f $errors
fi
