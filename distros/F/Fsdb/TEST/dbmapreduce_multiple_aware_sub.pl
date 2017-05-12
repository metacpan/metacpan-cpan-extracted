#!/usr/bin/perl

use Fsdb::Filter::dbpipeline qw(dbroweval);

sub simple_reducer {
    dbroweval('-m', 
	'-n',
	'-b' => 'my $count = 0; my $current_key = ""; @out_args = (-cols =>[qw(experiment n)]);',
	'-e' => '$ofref = [ $current_key, $count ];',
	' if ($current_key ne _experiment) { if ($current_key ne "") { $ofref = [ $current_key, $count ] }; $count = 1; $current_key = _experiment; } else { $count++; $ofref = undef; }; ');
}

#sub test {
#    my $it = simple_reducer();
#    $it->setup_run_finish();
#};
#
#&test;
