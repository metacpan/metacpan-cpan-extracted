#!/usr/bin/perl -w

use IPChains;

# Create a new set of attributes
$fw = IPChains->new(Source => "192.168.100.100",
		    SourceMask => "24",	      # can also be "255.255.255.0"
		    Rule => "ACCEPT", 
		    Verbose => 1,
		    Prot => "tcp",
		    DestPort => "0:1024"
		    );

# Append rule with set attributes to the 'input' chain
$fw->append('input');

# Clear attributes (options)
$fw->clopts();

# Set attribute Verbose to 1 (true)
$fw->attribute(Verbose, 1);

# Run the list() method on chain 'input'
$fw->list('input');

# Delete the rule (takes a second arg of rulenum, as does insert()).
$fw->delete('input', 1);

# List active masq rules. Set masq timeouts not yet implemented.
# $fw->clopts();
# $fw->masq();
