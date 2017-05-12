#!/usr/bin/perl -w

BEGIN {
  unshift @INC,'../lib';
}

use Test::More tests=>36;
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
(name => 'blessed scalar (empty)',
 code => 'my ($a,$b); 
        $a = \\do{my $scalar}; bless $a, "Foo"; 
        GraphViz::Data::Structure->new($a,graph=>{label=>"blessed scalar (empty)"})->graph->as_canon',
 out  => qq([Scalar object]}|{<port1>.}}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_atom0 [label=undef, rank=1, shape=plaintext];
	}
	gvds_scalar0:port1 -> gvds_atom0;
}

digraph test {
	graph [ratio=fill, label="blessed scalar (empty)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="{{<port0>Foo\
)
)
%%
(name => 'blessed scalar (scalar value)',
 code => 'my ($a,$b); 
        $a = \\$b; 
        bless $a, "Foo";$b="bar"; 
        GraphViz::Data::Structure->new($a,graph=>{label=>"blessed scalar (scalar value)"})->graph->as_canon',
 out  => qq([Scalar object]}|{<port1>.}}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_atom0 [label=bar, rank=1, shape=plaintext];
	}
	gvds_scalar0:port1 -> gvds_atom0;
}

digraph test {
	graph [ratio=fill, label="blessed scalar (scalar value)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="{{<port0>Foo\
)
)
%%
(name => 'blessed scalar (ref value)',
 code => 'my ($a,$b); 
        $a = \\$b; 
        bless $a, "Foo";$b = \\"bar";GraphViz::Data::Structure->new($a,graph=>{label=>"blessed scalar (ref value)"})->graph->as_canon',
 out  => qq([Scalar object]}|{<port1>.}}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_scalar1 [label="", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_atom0 [label=bar, rank=2, shape=plaintext];
	}
	gvds_scalar0:port1 -> gvds_scalar1;
	gvds_scalar1 -> gvds_atom0;
}

digraph test {
	graph [ratio=fill, label="blessed scalar (ref value)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="{{<port0>Foo\
)
)
%%
(name => 'blessed hash (empty)',
 code => 'my $a = {}; 
        bless $a,"Foo"; 
        GraphViz::Data::Structure->new($a,graph=>{label=>"blessed hash (empty)"})->graph->as_canon',
 out  => qq([Hash object]|{(empty)}}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
}

digraph test {
	graph [ratio=fill, label="blessed hash (empty)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_hash0 [label="{<port0>Foo\
)
)
%%
(name => 'blessed array (empty)',
 code => 'my $a = []; 
        bless $a,"Foo"; 
        GraphViz::Data::Structure->new($a,graph=>{label=>"blessed array (empty)"})->graph->as_canon',
 out  => qq([Array object]|{(empty)}}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
}

digraph test {
	graph [ratio=fill, label="blessed array (empty)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="{<port0>Foo\
)
)
%%
(name => 'blessed single-element array (scalar value)',
 code => 'my $a=["filled"]; 
        bless $a,"Foo"; 
        GraphViz::Data::Structure->new($a,graph=>{label=>"blessed single-element array (scalar value)"})->graph->as_canon',
 out  => qq([Array object]|<port1>filled}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
}

digraph test {
	graph [ratio=fill, label="blessed single-element array (scalar value)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="{<port0>Foo\
)
)
%%
(name => 'blessed single-element array (ref to empty array)',
 code => 'my $a=[[]]; 
        bless $a,"Foo"; 
        GraphViz::Data::Structure->new($a,graph=>{label=>"blessed single-element array (ref to empty array)"})->graph->as_canon',
 out  => qq([Array object]|<port1>.}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array1 [label="\\[\\]", rank=1, shape=plaintext];
	}
	gvds_array0:port1 -> gvds_array1;
}

digraph test {
	graph [ratio=fill, label="blessed single-element array (ref to empty array)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="{<port0>Foo\
)
)
%%
(name => 'blessed single-element array (ref to empty hash)',
 code => 'my $a=[{}]; 
        bless $a,"Foo"; 
        GraphViz::Data::Structure->new($a,graph=>{label=>"blessed single-element array (ref to empty hash)"})->graph->as_canon',
 out  => qq([Array object]|<port1>.}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_hash0 [label="\\{\\}", rank=1, shape=plaintext];
	}
	gvds_array0:port1 -> gvds_hash0;
}

digraph test {
	graph [ratio=fill, label="blessed single-element array (ref to empty hash)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="{<port0>Foo\
)
)
%%
(name => 'blessed vertical scalar (empty)',
 code => 'my ($a,$b); 
        $a = \\$b; 
        bless $a, "Foo"; 
        GraphViz::Data::Structure->new($a,Orientation=>"vertical",graph=>{label=>"blessed vertical scalar (empty)"})->graph->as_canon',
 out  => qq([Scalar object]}|{<port1>.}}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_atom0 [label=undef, rank=1, shape=plaintext];
	}
	gvds_scalar0:port1 -> gvds_atom0;
}

digraph test {
	graph [rankdir=LR, ratio=fill, label="blessed vertical scalar (empty)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="{{<port0>Foo\
)
)
%%
(name => 'blessed vertical scalar (scalar value)',
 code => 'my ($a,$b); 
        $a = \\$b; 
        bless $a, "Foo";$b="bar"; 
        GraphViz::Data::Structure->new($a,Orientation=>"vertical",graph=>{label=>"blessed vertical scalar (scalar value)"})->graph->as_canon',
 out  => qq([Scalar object]}|{<port1>.}}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_atom0 [label=bar, rank=1, shape=plaintext];
	}
	gvds_scalar0:port1 -> gvds_atom0;
}

digraph test {
	graph [rankdir=LR, ratio=fill, label="blessed vertical scalar (scalar value)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="{{<port0>Foo\
)
)
%%
(name => 'blessed vertical scalar (ref value)',
 code => 'my ($a,$b); 
        $a = \\$b; 
        bless $a, "Foo";
        $b = \\"bar";
        GraphViz::Data::Structure->new($a,Orientation=>"vertical",graph=>{label=>"blessed vertical scalar (ref value)"})
          ->graph->as_canon',
 out  => qq([Scalar object]}|{<port1>.}}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_scalar1 [label="", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_atom0 [label=bar, rank=2, shape=plaintext];
	}
	gvds_scalar0:port1 -> gvds_scalar1;
	gvds_scalar1 -> gvds_atom0;
}

digraph test {
	graph [rankdir=LR, ratio=fill, label="blessed vertical scalar (ref value)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="{{<port0>Foo\
)
)
%%
(name => 'blessed vertical hash (empty)',
 code => 'my $a = {}; 
        bless $a,"Foo"; 
        GraphViz::Data::Structure->new($a,Orientation=>"vertical",graph=>{label=>"blessed vertical hash (empty)"})->graph->as_canon',
 out  => qq([Hash object]|{(empty)}}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
}

digraph test {
	graph [rankdir=LR, ratio=fill, label="blessed vertical hash (empty)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_hash0 [label="{<port0>Foo\
)
)
%%
(name => 'blessed vertical array (empty)',
 code => 'my $a = []; 
        bless $a,"Foo"; 
        GraphViz::Data::Structure->new($a,Orientation=>"vertical",graph=>{label=>"blessed vertical array (empty)"})->graph->as_canon',
 out  => qq([Array object]|{(empty)}}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
}

digraph test {
	graph [rankdir=LR, ratio=fill, label="blessed vertical array (empty)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="{<port0>Foo\
)
)
%%
(name => 'blessed vertical single-element array (scalar value)',
 code => 'my $a=["filled"]; 
        bless $a,"Foo"; 
        GraphViz::Data::Structure->new($a,Orientation=>"vertical",graph=>{label=>"blessed vertical single-element array (scalar value)"})->graph->as_canon',
 out  => qq([Array object]|<port1>filled}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
}

digraph test {
	graph [rankdir=LR, ratio=fill, label="blessed vertical single-element array (scalar value)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="{<port0>Foo\
)
)
%%
(name => 'blessed vertical single-element array (ref to empty array)',
 code => 'my $a=[[]]; 
        bless $a,"Foo"; 
        GraphViz::Data::Structure->new($a,Orientation=>"vertical",graph=>{label=>"blessed vertical single-element array (ref to empty array)"})->graph->as_canon',
 out  => qq([Array object]|<port1>.}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array1 [label="\\[\\]", rank=1, shape=plaintext];
	}
	gvds_array0:port1 -> gvds_array1;
}

digraph test {
	graph [rankdir=LR, ratio=fill, label="blessed vertical single-element array (ref to empty array)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="{<port0>Foo\
)
)
%%
(name => 'blessed vertical single-element array (ref to empty hash)',
 code => 'my $a=[{}]; 
        bless $a,"Foo"; 
        GraphViz::Data::Structure->new($a,Orientation=>"vertical",graph=>{label=>"blessed vertical single-element array (ref to empty hash)"})->graph->as_canon',
 out  => qq([Array object]|<port1>.}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_hash0 [label="\\{\\}", rank=1, shape=plaintext];
	}
	gvds_array0:port1 -> gvds_hash0;
}

digraph test {
	graph [rankdir=LR, ratio=fill, label="blessed vertical single-element array (ref to empty hash)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="{<port0>Foo\
)
)
%%
(name => 'blessed three-element array (scalars)',
 code => 'my $a=[21,2,3]; 
        bless $a,"Foo"; 
        GraphViz::Data::Structure->new($a,graph=>{label=>"blessed three-element array (scalars)"})->graph->as_canon',
 out  => qq([Array object]|{{<port1>21}|{<port2>2}|{<port3>3}}}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
}

digraph test {
	graph [ratio=fill, label="blessed three-element array (scalars)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="{<port0>Foo\
)
)
%%
(name => 'blessed three-element array (array refs)',
 code => 'my $a=[[1],[2],[3]]; 
        bless $a,"Foo"; 
        GraphViz::Data::Structure->new($a,graph=>{label=>"blessed three-element array (array refs)"})->graph->as_canon',
 out  => qq([Array object]|{{<port1>.}|{<port2>.}|{<port3>.}}}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array1 [label="<port1>1", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_array2 [label="<port1>2", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_array3 [label="<port1>3", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_array0:port1 -> gvds_array1;
	gvds_array0:port2 -> gvds_array2;
	gvds_array0:port3 -> gvds_array3;
}

digraph test {
	graph [ratio=fill, label="blessed three-element array (array refs)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="{<port0>Foo\
)
)
%%
(name => 'blessed three-element array (hash refs)',
 code => 'my $a=[{One=>1},{Two=>2},{Three=>3}]; 
        bless $a,"Foo"; 
        GraphViz::Data::Structure->new($a,graph=>{label=>"blessed three-element array (hash refs)"})->graph->as_canon',
 out  => qq([Array object]|{{<port1>.}|{<port2>.}|{<port3>.}}}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_hash0 [label="{<port1>One|<port2>1}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_hash1 [label="{<port1>Two|<port2>2}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_hash2 [label="{<port1>Three|<port2>3}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_array0:port1 -> gvds_hash0;
	gvds_array0:port2 -> gvds_hash1;
	gvds_array0:port3 -> gvds_hash2;
}

digraph test {
	graph [ratio=fill, label="blessed three-element array (hash refs)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="{<port0>Foo\
)
)
%%
(name => 'blessed vertical three-element array (scalars)',
 code => 'my $a=[21,2,3]; 
        bless $a,"Foo"; 
        GraphViz::Data::Structure->new($a,Orientation=>"vertical",graph=>{label=>"blessed vertical three-element array (scalars)"})->graph->as_canon',
 out  => qq([Array object]|{{<port1>21}|{<port2>2}|{<port3>3}}}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
}

digraph test {
	graph [rankdir=LR, ratio=fill, label="blessed vertical three-element array (scalars)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="{<port0>Foo\
)
)
%%
(name => 'blessed vertical three-element array (array refs)',
 code => 'my $a=[[1],[2],[3]]; 
        bless $a,"Foo"; 
        GraphViz::Data::Structure->new($a,Orientation=>"vertical",graph=>{label=>"blessed vertical three-element array (array refs)"})->graph->as_canon',
 out  => qq([Array object]|{{<port1>.}|{<port2>.}|{<port3>.}}}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array1 [label="<port1>1", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_array2 [label="<port1>2", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_array3 [label="<port1>3", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_array0:port1 -> gvds_array1;
	gvds_array0:port2 -> gvds_array2;
	gvds_array0:port3 -> gvds_array3;
}

digraph test {
	graph [rankdir=LR, ratio=fill, label="blessed vertical three-element array (array refs)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="{<port0>Foo\
)
)
%%
(name => 'blessed vertical three-element array (hash refs)',
 code => 'my $a=[{One=>1},{Two=>2},{Three=>3}]; 
        bless $a,"Foo"; 
        GraphViz::Data::Structure->new($a,Orientation=>"vertical",graph=>{label=>"blessed vertical three-element array (hash refs)"})->graph->as_canon',
 out  => qq([Array object]|{{<port1>.}|{<port2>.}|{<port3>.}}}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_hash0 [label="{<port1>One|<port2>1}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_hash1 [label="{<port1>Two|<port2>2}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_hash2 [label="{<port1>Three|<port2>3}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_array0:port1 -> gvds_hash0;
	gvds_array0:port2 -> gvds_hash1;
	gvds_array0:port3 -> gvds_hash2;
}

digraph test {
	graph [rankdir=LR, ratio=fill, label="blessed vertical three-element array (hash refs)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="{<port0>Foo\
)
)
%%
(name => 'blessed three-element array (mixed empties)',
 code => 'my $a=[{},undef,[]]; 
        bless $a,"Foo"; 
        GraphViz::Data::Structure->new($a,graph=>{label=>"blessed three-element array (mixed empties)"})->graph->as_canon',
 out  => qq([Array object]|{{<port1>.}|{<port2>undef}|{<port3>.}}}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_hash0 [label="\\{\\}", rank=1, shape=plaintext];
		gvds_array1 [label="\\[\\]", rank=1, shape=plaintext];
	}
	gvds_array0:port3 -> gvds_array1;
	gvds_array0:port1 -> gvds_hash0;
}

digraph test {
	graph [ratio=fill, label="blessed three-element array (mixed empties)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="{<port0>Foo\
)
)
%%
(name => 'blessed vertical three-element array (mixed empties)',
 code => 'my $a=[{},undef,[]]; 
        bless $a,"Foo"; 
        GraphViz::Data::Structure->new($a,Orientation=>"vertical",graph=>{label=>"blessed vertical three-element array (mixed empties)"})->graph->as_canon',
 out  => qq([Array object]|{{<port1>.}|{<port2>undef}|{<port3>.}}}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_hash0 [label="\\{\\}", rank=1, shape=plaintext];
		gvds_array1 [label="\\[\\]", rank=1, shape=plaintext];
	}
	gvds_array0:port3 -> gvds_array1;
	gvds_array0:port1 -> gvds_hash0;
}

digraph test {
	graph [rankdir=LR, ratio=fill, label="blessed vertical three-element array (mixed empties)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="{<port0>Foo\
)
)
%%
(name => 'blessed four-element array (mixed refs) with a loop',
 code => 'my $a; 
        my $obj=\\$a; 
        bless $obj,"Bar"; 
        $a=[[1],{Two=>2},\\3,$obj]; 
        bless $a,"Foo"; 
        GraphViz::Data::Structure->new($a,graph=>{label=>"blessed four-element array (mixed refs) with a loop"})->graph->as_canon',
 out  => qq([Array object]|{{<port1>.}|{<port2>.}|{<port3>.}|{<port4>.}}}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array1 [label="<port1>1", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_hash0 [label="{<port1>Two|<port2>2}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_atom0 [label=3, rank=1, shape=plaintext];
	}
	gvds_array0:port4 -> gvds_array0:port0;
	gvds_array0:port1 -> gvds_array1;
	gvds_array0:port3 -> gvds_atom0;
	gvds_array0:port2 -> gvds_hash0;
}

digraph test {
	graph [ratio=fill, label="blessed four-element array (mixed refs) with a loop"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="{<port0>Foo\
)
)
%%
(name => 'blessed vertical four-element array (mixed refs) with a loop',
 code => 'my $a; 
        my $obj=\\$a; 
        bless $obj,"Bar"; 
        $a=[[1],{Two=>2},\\3,$obj]; 
        bless $a,"Foo"; 
        GraphViz::Data::Structure->new($a,Orientation=>"vertical",graph=>{label=>"blessed vertical four-element array (mixed refs) with a loop"})->graph->as_canon',
 out  => qq([Array object]|{{<port1>.}|{<port2>.}|{<port3>.}|{<port4>.}}}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array1 [label="<port1>1", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_hash0 [label="{<port1>Two|<port2>2}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_atom0 [label=3, rank=1, shape=plaintext];
	}
	gvds_array0:port4 -> gvds_array0:port0;
	gvds_array0:port1 -> gvds_array1;
	gvds_array0:port3 -> gvds_atom0;
	gvds_array0:port2 -> gvds_hash0;
}

digraph test {
	graph [rankdir=LR, ratio=fill, label="blessed vertical four-element array (mixed refs) with a loop"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="{<port0>Foo\
)
)
%%
(name => 'blessed three-element hash (scalars)',
 code => 'my $a={Foo=>21,Bar=>2,Baz=>3}; 
        bless $a,"Foo"; 
        GraphViz::Data::Structure->new($a,graph=>{label=>"blessed three-element hash (scalars)"})->graph->as_canon',
 out  => qq([Hash object]|{{<port1>Bar|<port2>2}|{<port3>Baz|<port4>3}|{<port5>Foo|<port6>21}}}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
}

digraph test {
	graph [ratio=fill, label="blessed three-element hash (scalars)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_hash0 [label="{<port0>Foo\
)
)
%%
(name => 'blessed three-element hash (array refs)',
 code => 'my $a={Foo=>[1],Bar=>[2],Baz=>[3]}; 
        bless $a,"Foo"; 
        GraphViz::Data::Structure->new($a,graph=>{label=>"blessed three-element hash (array refs)"})->graph->as_canon',
 out  => qq([Hash object]|{{<port1>Bar|<port2>.}|{<port3>Baz|<port4>.}|{<port5>Foo|<port6>.}}}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array0 [label="<port1>2", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_array1 [label="<port1>3", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_array2 [label="<port1>1", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_hash0:port2 -> gvds_array0;
	gvds_hash0:port4 -> gvds_array1;
	gvds_hash0:port6 -> gvds_array2;
}

digraph test {
	graph [ratio=fill, label="blessed three-element hash (array refs)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_hash0 [label="{<port0>Foo\
)
)
%%
(name => 'blessed three-element hash (hash refs)',
 code => 'my $a={Foo=>{One=>1},Bar=>{Two=>2},Baz=>{Three=>3}}; 
        bless $a,"Foo"; 
        GraphViz::Data::Structure->new($a,graph=>{label=>"blessed three-element hash (hash refs)"})->graph->as_canon',
 out  => qq([Hash object]|{{<port1>Bar|<port2>.}|{<port3>Baz|<port4>.}|{<port5>Foo|<port6>.}}}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_hash1 [label="{<port1>Two|<port2>2}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_hash2 [label="{<port1>Three|<port2>3}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_hash3 [label="{<port1>One|<port2>1}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_hash0:port2 -> gvds_hash1;
	gvds_hash0:port4 -> gvds_hash2;
	gvds_hash0:port6 -> gvds_hash3;
}

digraph test {
	graph [ratio=fill, label="blessed three-element hash (hash refs)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_hash0 [label="{<port0>Foo\
)
)
%%
(name => 'blessed three-element array (mixed empties)',
 code => 'my $a={Foo=>{},Bar=>undef,Baz=>[]}; 
        bless $a,"Foo"; 
        GraphViz::Data::Structure->new($a,graph=>{label=>"blessed three-element array (mixed empties)"})->graph->as_canon',
 out  => qq([Hash object]|{{<port1>Bar|<port2>undef}|{<port3>Baz|<port4>.}|{<port5>Foo|<port6>.}}}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array0 [label="\\[\\]", rank=1, shape=plaintext];
		gvds_hash1 [label="\\{\\}", rank=1, shape=plaintext];
	}
	gvds_hash0:port4 -> gvds_array0;
	gvds_hash0:port6 -> gvds_hash1;
}

digraph test {
	graph [ratio=fill, label="blessed three-element array (mixed empties)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_hash0 [label="{<port0>Foo\
)
)
%%
(name => 'blessed four-element hash (mixed refs)',
 code => 'my $a; 
        $a={Foo=>[1],Bar=>{Two=>2},Baz=>\\3,Bonk=>\\$a}; 
        bless $a,"Foo"; 
        GraphViz::Data::Structure->new($a,graph=>{label=>"blessed four-element hash (mixed refs)"})->graph->as_canon',
 out  => qq([Hash object]|{{<port1>Bar|<port2>.}|{<port3>Baz|<port4>.}|{<port5>Bonk|<port6>.}|{<port7>Foo|<port8>.}}}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_hash1 [label="{<port1>Two|<port2>2}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_atom0 [label=3, rank=1, shape=plaintext];
		gvds_array0 [label="<port1>1", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_hash0:port8 -> gvds_array0;
	gvds_hash0:port4 -> gvds_atom0;
	gvds_hash0:port6 -> gvds_hash0:port0;
	gvds_hash0:port2 -> gvds_hash1;
}

digraph test {
	graph [ratio=fill, label="blessed four-element hash (mixed refs)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_hash0 [label="{<port0>Foo\
)
)
%%
(name => 'blessed vertical three-element hash (scalars)',
 code => 'my $a={Foo=>21,Bar=>2,Baz=>3}; 
        bless $a,"Foo"; 
        GraphViz::Data::Structure->new($a,Orientation=>"vertical",graph=>{label=>"blessed vertical three-element hash (scalars)"})->graph->as_canon',
 out  => qq([Hash object]}|{<port1>Bar|<port3>Baz|<port5>Foo}|{<port2>2|<port4>3|<port6>21}}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
}

digraph test {
	graph [rankdir=LR, ratio=fill, label="blessed vertical three-element hash (scalars)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_hash0 [label="{{<port0>Foo\
)
)
%%
(name => 'blessed vertical three-element hash (array refs)',
 code => 'my $a={Foo=>[1],Bar=>[2],Baz=>[3]}; 
        bless $a,"Foo"; 
        GraphViz::Data::Structure->new($a,Orientation=>"vertical",graph=>{label=>"blessed vertical three-element hash (array refs)"})->graph->as_canon',
 out  => qq([Hash object]}|{<port1>Bar|<port3>Baz|<port5>Foo}|{<port2>.|<port4>.|<port6>.}}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array0 [label="<port1>2", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_array1 [label="<port1>3", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_array2 [label="<port1>1", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_hash0:port2 -> gvds_array0;
	gvds_hash0:port4 -> gvds_array1;
	gvds_hash0:port6 -> gvds_array2;
}

digraph test {
	graph [rankdir=LR, ratio=fill, label="blessed vertical three-element hash (array refs)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_hash0 [label="{{<port0>Foo\
)
)
%%
(name => 'blessed vertical three-element hash (hash refs)',
 code => 'my $a={Foo=>{One=>1},Bar=>{Two=>2},Baz=>{Three=>3}}; 
        bless $a,"Foo"; 
        GraphViz::Data::Structure->new($a,Orientation=>"vertical",graph=>{label=>"blessed vertical three-element hash (hash refs)"})->graph->as_canon',
 out  => qq([Hash object]}|{<port1>Bar|<port3>Baz|<port5>Foo}|{<port2>.|<port4>.|<port6>.}}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_hash1 [label="{<port1>Two|<port2>2}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_hash2 [label="{<port1>Three|<port2>3}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_hash3 [label="{<port1>One|<port2>1}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_hash0:port2 -> gvds_hash1;
	gvds_hash0:port4 -> gvds_hash2;
	gvds_hash0:port6 -> gvds_hash3;
}

digraph test {
	graph [rankdir=LR, ratio=fill, label="blessed vertical three-element hash (hash refs)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_hash0 [label="{{<port0>Foo\
)
)
%%
(name => 'blessed vertical three-element array (mixed empties)',
 code => 'my $a={Foo=>{},Bar=>undef,Baz=>[]}; 
        bless $a,"Foo"; 
        GraphViz::Data::Structure->new($a,Orientation=>"vertical",graph=>{label=>"blessed vertical three-element array (mixed empties)"})->graph->as_canon',
 out  => qq([Hash object]}|{<port1>Bar|<port3>Baz|<port5>Foo}|{<port2>undef|<port4>.|<port6>.}}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array0 [label="\\[\\]", rank=1, shape=plaintext];
		gvds_hash1 [label="\\{\\}", rank=1, shape=plaintext];
	}
	gvds_hash0:port4 -> gvds_array0;
	gvds_hash0:port6 -> gvds_hash1;
}

digraph test {
	graph [rankdir=LR, ratio=fill, label="blessed vertical three-element array (mixed empties)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_hash0 [label="{{<port0>Foo\
)
)
%%
(name => 'blessed vertical four-element hash (mixed refs)',
 code => 'my $a; 
        $a={Foo=>[1],Bar=>{Two=>2},Baz=>\\3,Bonk=>\\$a}; 
        bless $a,"Foo";GraphViz::Data::Structure->new($a,Orientation=>"vertical",graph=>{label=>"blessed vertical four-element hash (mixed refs)"})->graph->as_canon',
 out  => qq([Hash object]}|{<port1>Bar|<port3>Baz|<port5>Bonk|<port7>Foo}|{<port2>.|<port4>.|<port6>.|<port8>.}}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_hash1 [label="{<port1>Two|<port2>2}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_atom0 [label=3, rank=1, shape=plaintext];
		gvds_array0 [label="<port1>1", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_hash0:port8 -> gvds_array0;
	gvds_hash0:port4 -> gvds_atom0;
	gvds_hash0:port6 -> gvds_hash0:port0;
	gvds_hash0:port2 -> gvds_hash1;
}

digraph test {
	graph [rankdir=LR, ratio=fill, label="blessed vertical four-element hash (mixed refs)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_hash0 [label="{{<port0>Foo\
)
)
