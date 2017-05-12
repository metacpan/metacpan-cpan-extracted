#pragma D option quiet

perlxs$target:::sub-entry, perlxs$target:::sub-return {
	printf("%s %s (%s:%d)\n", probename == "sub-entry" ? "->" : "<-",
            copyinstr(arg0), copyinstr(arg1), arg2);
}
