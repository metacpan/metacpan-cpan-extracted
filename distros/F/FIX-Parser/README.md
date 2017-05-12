# perl-FIX-Parser
A module to parse FIX market data. Currently supports FIX 4.4.

Installation
============

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

Example
=======

```
use FIX::Parser::FIX44;

my $parser = FIX::Parser::FIX44->new;

my @msgs = $parser->add($fix_msg);

for(@msgs) {
	print "Symbol: ".$_->{symbol}."\n";
        
	print "Bid: ".$_->{bid}."\n";
	print "Ask: ".$_->{ask}."\n";
	print "Datetime: ".$_->{datetime}."\n";
}

```

