#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

echo " [XT::RELEASE::BEFORE] DIR=$DIR"
cd "$DIR/../../"
rm -rfv FASTX-*
if [[ -e "META.yml" ]]; then
 mv META.yml META.old
fi
if [[ -e "experimental" ]];
then
	mv experimental ../_build_fastx_reader_exp
fi

if [[ $(grep VERSION lib/FASTX/Reader.pm | grep -o "'.*'" ) != $(grep -o "^\d\+\.\d\+"  Changes | head -n1) ]]; then
	echo "Changes and VERSION mismatch"
	exit;
fi
cd -
