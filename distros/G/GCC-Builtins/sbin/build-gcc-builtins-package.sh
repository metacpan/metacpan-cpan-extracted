#!/bin/bash

WHEREAMI="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

rm -f whitelist.txt; touch whitelist.txt
rm -f blacklist.txt; touch blacklist.txt

# there may be undefined functions,
# so run it once to get all the function names
# then whitelist it and try compiling
CMD="${WHEREAMI}/build-gcc-builtins-package.pl"; echo "$0 : executing command: ${CMD} ..."; eval $CMD; if [ $? -ne 0 ]; then echo "$0 : command has failed : ${CMD}"; exit 1; fi
declare -a ALLFUNCS=(
	'__builtin_clz'
	$(grep -B1 'CODE:' lib/GCC/Builtins.xs | grep -v 'CODE:' | grep -v '\--' | sed -e 's/[(].*$//' | awk '{print "__builtin_"$0}')
)

for afunc in "${ALLFUNCS[@]}"; do
	cp whitelist.txt whitelist.ori
	echo $afunc >> whitelist.txt
	CMD="${WHEREAMI}/build-gcc-builtins-package.pl"; echo "$0 : executing command: ${CMD} ..."; eval $CMD; if [ $? -ne 0 ]; then echo "$0 : command has failed : ${CMD}"; exit 1; fi
	CMD="make clean"; echo "$0 : executing command: ${CMD} ..."; eval $CMD
	CMD="perl Makefile.PL"; echo "$0 : executing command: ${CMD} ..."; eval $CMD; if [ $? -ne 0 ]; then echo "$0 : command has failed : ${CMD}"; exit 1; fi
	CMD="make all && perl -Iblib/lib -Iblib/arch t/000-load.t && perl -Iblib/lib -Iblib/arch t/010-clz.t"; echo "$0 : executing command: ${CMD} ...";
	eval $CMD
	if [ $? -ne 0 ]; then
		# failed
		mv whitelist.ori whitelist.txt
		echo $afunc >> blacklist.txt
	else
		cp whitelist.txt whitelist.ori
	fi
done

mv whitelist.txt whitelist.txt.final
mv blacklist.txt blacklist.txt.final

echo "$0 : done, set the contents of whitelist.txt.final and blacklist.txt.final into '${WHEREAMI}/build-gcc-builtins-package.pl'"
echo "then run '${WHEREAMI}/build-gcc-builtins-package.pl' and then perl Makefile.PL && make all && make test"
echo "If any of the test files above t/666-\*.t fails, copy the expected value into '${WHEREAMI}/build-gcc-builtins-package.pl' and retry."
