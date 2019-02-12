#!/usr/bin/awk -f

BEGIN	{
    if (ARGC < 1) {
	print "Usage: tt-123-eos-expand.awk TT_FILE(s)..." > "/dev/stderr"
	print " + adds '__$' bigrams to mootrain verbose .123 files" > "/dev/stderr"
	exit 1;
    }
    eos="__$"
    FS="\t";
    OFS="\t";
}
/^$/    { print $0; next }
/^%%/   { print $0; next }
{
    if (NF==2 && $1==eos) {
	##-- unigram: __$
	print eos,1;
	next;
    }
    print $0;
    if (NF==3) {
	##-- bigrams
	if ($1==eos && $2==eos) {
	    ##-- bigram: (EOS EOS): ignore (moot doesn't produce this)
	    next;
	}
	else if ($1==eos) {
	    ##-- bigram: (EOS a2) --> (EOS), (EOS EOS)
	    print eos,$3;
	    print eos,eos,$3;
	}
	else if ($2==eos) {
	    ##-- bigram: (a1 EOS) --> (EOS) #, (EOS EOS)
	    print eos,$3;
	    #print eos,eos,$3;
	}
    }
    else if (NF==4) {
	##-- trigrams
	if ($2==eos && ($1==eos || $3==eos)) {
	    ##-- trigram: (EOS EOS a3) or (a1 EOS EOS): ignore (moot doesn't produce these)
	    next;
	}
	else if ($1==eos) {
	    ##-- trigram: (EOS a2 a3) --> (EOS EOS a2)
	    print eos,eos,$2,$4;
	}
	else if ($3==eos) {
	    ##-- trigram: (a1 a2 EOS) --> (a2 EOS EOS)
	    print $2,eos,eos,$4;
	}
    }
    else if (NF>4) {
	##-- (k>4)-gram: unhandled
	print ARGV[0] ": " ARGV[ARGIND] ":" FNR ": can't expand k>4 gram with k=" NF ": " $0 > "/dev/stderr"
    }
}
