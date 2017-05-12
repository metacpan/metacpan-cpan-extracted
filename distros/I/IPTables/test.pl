####################################################################
## The little hampster grew humps, and wrote this....             ##
## Copyright (c) 2001 Theo Zourzouvillys <theo@crazygreek.co.uk>  ##
## Includes code from netfilter (netfilter.samba.org)             ##
####################################################################
#       .Copyright (C)  2000-2001 Theo Zourzouvillys
#       .Created:       26/09/2001
#       .Contactid:     <theo@crazygreek.co.uk>
#       .Url:           http://theo.me.uk
#       .Authors:       Theo Zourzouvillys
#       .ID:            $Id: test.pl,v 1.13 2002/04/05 19:57:40 theo Exp $

## Warning, if this blows up your computer, don't blame me ;)

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use IPTables qw(:constants); 
# qw(IPT_INV_DSTIP IPT_INV_SRCIP IFNAMSIZ IPT_INV_VIA_IN IPT_INV_VIA_OUT IPT_INV_FRAG IPT_F_FRAG);
$loaded = 1;
######################### End of black magic.


for $bit (qw(filter nat mangle))
{
	my $table = new IPTables($bit) or die "Can't connect!\n";

	print "Handle: $table\n";
	my $l = undef;
	for ( $chain = $table->first_chain ; $chain ; $chain = $table->next_chain )
	{
		print "Chain is: $chain, ";
		($table->builtin($chain))?print 'builtin': print 'user';
		print "\n";
		printf("Chain %s (policy %s %d packets, %d bytes)\n", $chain, $table->get_policy($chain)) if ( $table->builtin($chain) );
		print " pkts bytes target     prot opt in     out     source               destination\n";
		$e = $table->first_rule($chain);
		while($e)
		{
			$this{$chain}++;

			printf(" %-4d %-4d   %-9s %-4s -- %-7s %-7s %s%s  %s%s\n",
				$e->bytes, 
				$e->packets, 
				$e->get_target,
				($e->proto == 0)?'all':$e->proto,
				$e->iniface,
				$e->outiface,
				$e->src,
				$e->src_mask,
				$e->dst,
				$e->dst_mask
			);

			if (my $target = $e->find_target)
			{
				print $target->print_match;
				print q| - |;
				print $target->print_target;
			}

			$l = $e;
			$e = $e->iptc_next_rule;

		}

		print "\n";
	}

	# = # = # = # = # = # = # = # = # = # = # = # = # = # = # = # = # = # = # = #
}

print "OK - Passed all tests\n";

exit 0; ### WARNING! Don't uncomment, or it may fuck up your current rules!

## These are just examples of what you can do...

my $table = new IPTables('filter') or die "Can't connect!\n";

## Chain, src, dst, proto, jumpto. match

$table->add_entry("INPUT", "213.206.4.55", "123.4.5.6", "tcp", "REJECT", "tcp", ['dport', "22"]);

my $table = new IPTables('filter') or die "Can't connect!\n";
$table->add_entry("INPUT", "213.206.4.55", "123.4.5.6", "tcp", "REJECT", 'unclean', []);

my $table = new IPTables('filter') or die "Can't connect!\n";
$table->delete_entry("INPUT", $this{INPUT}+1);

# my $table = new IPTables('filter') or die "Can't connect!\n";
# print "Setting policy\n";
# $table->set_policy("FORWARD", "DROP");
# print "Done.\n";

my $table = new IPTables('filter') or die "Can't connect!\n";
print "Resetting Counters on filter INPUT\n";
$table->reset_counter("INPUT");
print "Done.\n";

my @match = list_matches();
foreach my $match (@match)
{
	my ($name, @opts) = @{$match};
	print "$name: ";
	print join(" - ", @opts);
	print "\n";
	match_help($name);
}


my @match = list_targets();
foreach my $match (@match)
{
	my ($name, @opts) = @{$match};
	print "$name: ";
	print join(" - ", @opts);
	print "\n";
	target_help($name);
}

