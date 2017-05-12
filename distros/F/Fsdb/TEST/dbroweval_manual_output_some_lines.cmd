prog='dbroweval'
# 1. this command is embedded in dbmapreduce_multiple_aware_sub.cmd
# 2. next line quoting is odd because of t/test_command.t
#   the inner ' all pass through without being quoted
args='-m -n -b 'my $count = 0; my $current_key = ""; @out_args = (-cols =>[qw(experiment n)]);' -e '$ofref = [ $current_key, $count ];'  ' if ($current_key ne _experiment) { if ($current_key ne "") { $ofref = [ $current_key, $count ] }; $count = 1; $current_key = _experiment; } else { $count++; }; ''
in='TEST/dbmapreduce_ex.in'
cmp='diff -c -b '
