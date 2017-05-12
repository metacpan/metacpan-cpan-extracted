### 02-fancy_args.t ###########################################################
# This file tests the hash methods for setting arguments.

### Includes ##################################################################

# Safe Perl
use warnings;
use strict;
use Carp;

use Test::More tests => 4;
use Test::Exception;

use HPCI;

my $cluster = $ENV{HPCI_CLUSTER} || 'uni';

{
	my $group = HPCI->group( cluster => $cluster, base_dir => 'scratch', name => 'T_Fancy_args' );
	my $stage = $group->stage(
		name => 'TestStage',
		resources_required => {
			h_vmem => '2G'
			},
		command => 'nothing',
		extra_sge_args_string => ''
		);

	print STDERR "\n";

	is($stage->command, "nothing", "Existing argument test.");

	$stage->set_python_cmd('foo.py', baz => 1, bar => [1, 2, 3], quux => '/tmp', a => undef);
	is($stage->command, "python foo.py -a --bar 1 2 3 --baz 1 --quux /tmp", "Python argument test.");

	$stage->set_r_cmd('foo.R', baz => 1, bar => [1, 2, 3], quux => '/tmp', a => undef);
	is($stage->command, "Rscript foo.R -a --bar 1 2 3 --baz 1 --quux /tmp", "R argument test.");

	$stage->set_perl_cmd('foo.pl', baz => 1, bar => [1, 2, 3], quux => '/tmp', a => undef);
	is($stage->command, "perl foo.pl -a --bar 1 --bar 2 --bar 3 --baz 1 --quux /tmp", "Perl argument test.");
}

sleep(5); # leave time for cleanup of group and stages...

done_testing();

1;
