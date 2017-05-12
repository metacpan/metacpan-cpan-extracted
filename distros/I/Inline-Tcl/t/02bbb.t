use Inline Config => DIRECTORY => './blib_test';

BEGIN {
    print "1..1\n";
}

use Inline Tcl => <<END;
	set asdf2 2
	proc ASDF { valval } {
		set val 1
		puts "ASDF: Hello world! \$valval \$val \$::asdf2"
		return [expr \$::asdf2 + \$val]
	}
END

$thisresult = ASDF(2);
print "SCRIPT: $thisresult\n";
print "not " unless ( ASDF(2) == 3 );
print "ok 1\n";
