#!/usr/bin/perl -w

BEGIN {
  unshift @INC,'../lib';
}

use Test::More tests=>5;
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
(name => 'array ref to self',
 code => '@a= (1,\\@a,3);
          GraphViz::Data::Structure->new(\\@a,graph=>{label=>"array ref to self"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="array ref to self"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="{<port1>1}|{<port2>.}|{<port3>3}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	gvds_array0:port2 -> gvds_array0;
}

)
)
%%
(name => 'scalar ref to array element',
 code => '@a=(1,2,3); 
          $a=\\$a[2];
          GraphViz::Data::Structure->new($a,graph=>{label=>"scalar ref to array element"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="scalar ref to array element"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_atom0 [label=3, rank=1, shape=plaintext];
	}
	gvds_scalar0 -> gvds_atom0;
}

)
)
%%
(name => 'hash ref to self',
 code => '%refhash=(Self=>\\%refhash);
          GraphViz::Data::Structure->new(\\%refhash,graph=>{label=>"hash ref to self"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="hash ref to self"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_hash0 [label="{<port1>Self|<port2>.}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	gvds_hash0:port2 -> gvds_hash0;
}

)
)
%%
(name => 'scalar ref to hash element',
 code => '%refhash=(One=>1,Two=>2);
          $a=\\$refhash{One};
          GraphViz::Data::Structure->new($a,graph=>{label=>"scalar ref to hash element"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="scalar ref to hash element"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_atom0 [label=1, rank=1, shape=plaintext];
	}
	gvds_scalar0 -> gvds_atom0;
}

)
)
%%
(name => 'complex case',
 code => '@a=(1,2); 
          $a[0]=\\@a; 
          $a[1]=\\$a[0]; 
          GraphViz::Data::Structure->new(\\@a,graph=>{label=>"complex case"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="complex case"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="{<port1>.}|{<port2>.}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	gvds_array0:port1 -> gvds_array0;
	gvds_array0:port2 -> gvds_array0:port1;
}

)
)
