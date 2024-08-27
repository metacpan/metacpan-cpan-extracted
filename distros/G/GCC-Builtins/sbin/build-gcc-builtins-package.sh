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
		echo "Function '$afunc' goes to the blacklist ..."
	else
		cp whitelist.txt whitelist.ori
		echo "Function '$afunc' goes to the whitelist ..."
	fi
done

mv whitelist.txt whitelist.txt.final
mv blacklist.txt blacklist.txt.final

echo "$0 : done."
echo "If you want to add whitelisted/blacklisted functions then edit '${WHEREAMI}/build-gcc-builtins-package.pl'."
echo
echo "Normally, you do not need to edit anything. The whitelisted functions will be read from file automatically and the blacklisted functions are already set in that file and should not be needing changes unless GCC adds other builtins."
echo
echo "Then run '${WHEREAMI}/build-gcc-builtins-package.pl' and then perl Makefile.PL && make all && make test"
echo
echo "If any of the test files above t/666-\*.t fails, copy the expected value into '${WHEREAMI}/build-gcc-builtins-package.pl' (into '%T_EXPECTED_RESULTS') and retry."
echo
echo
echo "$0 : so, all done, it seems all was successful. Now run what is mentioned above."
echo
