use Inline Config => DIRECTORY => './blib_test';

use Inline Tcl => <<END;
set asdf 2
proc dummy { val } {
  puts "Dummy says \$::asdf + \$val = [expr \$::asdf + \$val]"
  incr val
  return [expr \$::asdf + \$val]
}
END
				 
$result = dummy(1);
print "But returned $result\n";
