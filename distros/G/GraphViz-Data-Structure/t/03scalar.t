#!/usr/bin/perl -w

BEGIN {
  unshift @INC,'../lib';
}

use Test::More tests=>8;
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
(name => 'ref to atom',
 code => 'GraphViz::Data::Structure->new(\\1,graph=>{label=>"ref to atom"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="ref to atom"];
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
(name => 'ref to scalar',
 code => '$a03 = 1; 
        GraphViz::Data::Structure->new(\\$a03,graph=>{label=>"ref to scalar"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="ref to scalar"];
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
(name => 'ref to ref to scalar',
 code => '$a03 = 1; 
        $b03 = \\$a03; 
        GraphViz::Data::Structure->new(\\$b03,graph=>{label=>"ref to ref to scalar"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="ref to ref to scalar"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_scalar1 [label="", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_atom0 [label=1, rank=2, shape=plaintext];
	}
	gvds_scalar0 -> gvds_scalar1;
	gvds_scalar1 -> gvds_atom0;
}

)
)
%%
(name => 'ref to self',
 code => '$a03 = \\$a03; 
        GraphViz::Data::Structure->new($a03,graph=>{label=>"ref to self"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="ref to self"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	gvds_scalar0 -> gvds_scalar0;
}

)
)
%%
(name => 'ref to ref to self',
 code => '$a03 = \\$a03; 
        $b03 = \\$a03; 
        GraphViz::Data::Structure->new(\\$b03,graph=>{label=>"ref to ref to self"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="ref to ref to self"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_scalar1 [label="", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_scalar0 -> gvds_scalar1;
	gvds_scalar1 -> gvds_scalar1;
}

)
)
%%
(name => 'twin circular ref',
 code => '$a03 = \\$b03; 
        $b03 = \\$a03; 
        GraphViz::Data::Structure->new(\\$a03,graph=>{label=>"twin circular ref"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="twin circular ref"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_scalar1 [label="", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_scalar0 -> gvds_scalar1;
	gvds_scalar1 -> gvds_scalar0;
}

)
)
%%
(name => 'triple circular ref',
 code => '$a03 = \\$b03; 
        $b03 = \\$c03; 
        $c03 = \\$a03; 
        GraphViz::Data::Structure->new(\\$a03,graph=>{label=>"triple circular ref"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="triple circular ref"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_scalar1 [label="", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_scalar2 [label="", color=white, fontcolor=black, rank=2, shape=record, style=filled];
	}
	gvds_scalar0 -> gvds_scalar1;
	gvds_scalar1 -> gvds_scalar2;
	gvds_scalar2 -> gvds_scalar0;
}

)
)
%%
(name => 'odd characters',
 code => '$z="<html><head> ...";
        GraphViz::Data::Structure->new(\\$z,graph=>{label=>"odd characters"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="odd characters"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_atom0 [label="\\\\<html\\\\>\\\\<head\\\\> ...", rank=1, shape=plaintext];
	}
	gvds_scalar0 -> gvds_atom0;
}

)
)
