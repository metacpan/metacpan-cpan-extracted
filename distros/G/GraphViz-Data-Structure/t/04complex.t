#!/usr/bin/perl -w

BEGIN {
  unshift @INC,'../lib';
}

use Test::More tests=>1;
use GraphViz::Data::Structure;

while (my $current = get_current()) {
  %hash = eval $current;
  my $result = eval $hash{'code'};
  die $@ if $@;
  is (normalize($result), normalize($hash{'out'}), $hash{'name'});
}

sub get_current {
   my $code = "";
   while (<DATA>) {
   last if /%%/;
   $code .= $_;
   }
   $code;
}

sub normalize {  }

__DATA__
(name => 'verify circular links (dot cannot render)',
 code => 'my @a; 
        @a=(\\@a,\\@a,\\\\@a); 
        GraphViz::Data::Structure->new(\\@a,graph=>{label=>"verify circular links (dot cannot render)"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="verify circular links (dot cannot render)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="{<port1>.}|{<port2>.}|{<port3>.}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	gvds_array0:port1 -> gvds_array0;
	gvds_array0:port2 -> gvds_array0;
	gvds_array0:port3 -> gvds_array0;
}

)
)
