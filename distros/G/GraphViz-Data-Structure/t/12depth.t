#!/usr/bin/perl -w

BEGIN {
  unshift @INC,'../lib';
}

use Test::More tests=>3;
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
(name => 'depth off',
 code => 'my ($a); $a=[1,[2,[4,[8]]]]; 
          my $z = GraphViz::Data::Structure->new(\\$a,graph=>{label=>"depth off"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="depth off"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array0 [label="{<port1>1}|{<port2>.}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array1 [label="{<port1>2}|{<port2>.}", color=white, fontcolor=black, rank=2, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array2 [label="{<port1>4}|{<port2>.}", color=white, fontcolor=black, rank=3, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array3 [label="<port1>8", color=white, fontcolor=black, rank=4, shape=record, style=filled];
	}
	gvds_array0:port2 -> gvds_array1;
	gvds_array1:port2 -> gvds_array2;
	gvds_array2:port2 -> gvds_array3;
	gvds_scalar0 -> gvds_array0;
}

)
)
%%
(name => 'depth at 2',
 code => 'my ($a); 
          $a=[1,[2,[4,[8]]]]; 
          my $z = GraphViz::Data::Structure->new(\\$a,Depth=>2,graph=>{label=>"depth at 2"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="depth at 2"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array0 [label="{<port1>1}|{<port2>.}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array1 [label="{<port1>2}|{<port2>.}", color=white, fontcolor=black, rank=2, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_dummy1 [label="...", rank=3, shape=plaintext];
	}
	gvds_array0:port2 -> gvds_array1;
	gvds_array1:port2 -> gvds_dummy1;
	gvds_scalar0 -> gvds_array0;
}

)
)
%%
(name => 'depth at 1',
 code => 'my ($a); 
          $a=[1,[2,[4,[8]]]]; 
          my $z = GraphViz::Data::Structure->new(\\$a,Depth=>1,graph=>{label=>"depth at 1"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="depth at 1"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array0 [label="{<port1>1}|{<port2>.}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_dummy1 [label="...", rank=2, shape=plaintext];
	}
	gvds_array0:port2 -> gvds_dummy1;
	gvds_scalar0 -> gvds_array0;
}

)
)
