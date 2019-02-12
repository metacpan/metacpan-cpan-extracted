#!/usr/bin/awk -f

BEGIN	{
    if (ARGC < 2) {
	print "Usage: tt-2xt.awk NIL_TEXT_STRING TT_FILE(s)..." > "/dev/stderr"
	exit 1;
    }
    niltxt=ARGV[1];
    delete ARGV[1];

    FS="\t";
    OFS="\t";
}
/^$/    { print $0; next }
/^%%/   { print $0; next }
{ print niltxt,$0 }
