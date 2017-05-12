#!/usr/bin/perl -w

BEGIN {
  unshift @INC,'../lib';
}

use Test::More tests=>18;
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
(name => 'ref to zero-element array',
 code => 'GraphViz::Data::Structure->new(\\[],graph=>{label=>"ref to zero-element array"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="ref to zero-element array"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array0 [label="\\[\\]", rank=1, shape=plaintext];
	}
	gvds_scalar0 -> gvds_array0;
}

)
)
%%
(name => 'ref to one-element array',
 code => 'GraphViz::Data::Structure->new(\\["test"],graph=>{label=>"ref to one-element array"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="ref to one-element array"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array0 [label="<port1>test", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_scalar0 -> gvds_array0;
}

)
)
%%
(name => 'ref to three-element array',
 code => 'GraphViz::Data::Structure->new(\\["larry","moe","curly"],graph=>{label=>"ref to three-element array"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="ref to three-element array"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array0 [label="{<port1>larry}|{<port2>moe}|{<port3>curly}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_scalar0 -> gvds_array0;
}

)
)
%%
(name => 'ref to vertical three-element array',
 code => 'GraphViz::Data::Structure->new(\\["larry","moe","curly"],Orientation=>"vertical",graph=>{label=>"ref to vertical three-element array"})->graph->as_canon',
 out  => qq(digraph test {
	graph [rankdir=LR, ratio=fill, label="ref to vertical three-element array"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array0 [label="{<port1>larry}|{<port2>moe}|{<port3>curly}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_scalar0 -> gvds_array0;
}

)
)
%%
(name => 'single-element array ref to empty arrays',
 code => 'my @a=([]); 
        GraphViz::Data::Structure->new(\\@a,%title)->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="<port1>.", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array1 [label="\\[\\]", rank=1, shape=plaintext];
	}
	gvds_array0:port1 -> gvds_array1;
}

)
)
%%
(name => 'three-element array ref to empty arrays',
 code => 'my @a=([],[],[]); 
        GraphViz::Data::Structure->new(\\@a,graph=>{label=>"three-element array ref to empty arrays"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="three-element array ref to empty arrays"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="{<port1>.}|{<port2>.}|{<port3>.}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array1 [label="\\[\\]", rank=1, shape=plaintext];
		gvds_array2 [label="\\[\\]", rank=1, shape=plaintext];
		gvds_array3 [label="\\[\\]", rank=1, shape=plaintext];
	}
	gvds_array0:port1 -> gvds_array1;
	gvds_array0:port2 -> gvds_array2;
	gvds_array0:port3 -> gvds_array3;
}

)
)
%%
(name => 'single-element array ref to one-element arrays',
 code => 'my @a=(["test"]); 
        GraphViz::Data::Structure->new(\\@a,graph=>{label=>"single-element array ref to one-element arrays"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="single-element array ref to one-element arrays"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="<port1>.", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array1 [label="<port1>test", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_array0:port1 -> gvds_array1;
}

)
)
%%
(name => 'three-element array ref to one-element arrays',
 code => 'my @a=(["larry"],["moe"],["curly"]); 
        GraphViz::Data::Structure->new(\\@a,graph=>{label=>"three-element array ref to one-element arrays"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="three-element array ref to one-element arrays"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="{<port1>.}|{<port2>.}|{<port3>.}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array1 [label="<port1>larry", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_array2 [label="<port1>moe", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_array3 [label="<port1>curly", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_array0:port1 -> gvds_array1;
	gvds_array0:port2 -> gvds_array2;
	gvds_array0:port3 -> gvds_array3;
}

)
)
%%
(name => 'single-element array ref to three-element arrays',
 code => 'my @a=(["larry","moe","curly"]); 
        GraphViz::Data::Structure->new(\\@a,graph=>{label=>"single-element array ref to three-element arrays"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="single-element array ref to three-element arrays"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="<port1>.", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array1 [label="{<port1>larry}|{<port2>moe}|{<port3>curly}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_array0:port1 -> gvds_array1;
}

)
)
%%
(name => 'three-element array ref to three-element arrays',
 code => 'my @a=(["larry","moe","curly"],
               ["groucho","harpo","chico"],
               ["seagoon","bloodnok","eccles"]); 
        GraphViz::Data::Structure->new(\\@a,graph=>{label=>"three-element array ref to three-element arrays"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="three-element array ref to three-element arrays"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="{<port1>.}|{<port2>.}|{<port3>.}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array1 [label="{<port1>larry}|{<port2>moe}|{<port3>curly}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_array2 [label="{<port1>groucho}|{<port2>harpo}|{<port3>chico}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_array3 [label="{<port1>seagoon}|{<port2>bloodnok}|{<port3>eccles}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_array0:port1 -> gvds_array1;
	gvds_array0:port2 -> gvds_array2;
	gvds_array0:port3 -> gvds_array3;
}

)
)
%%
(name => 'single-element array ref to empty hash',
 code => 'my @a=({}); 
        GraphViz::Data::Structure->new(\\@a,graph=>{label=>"single-element array ref to empty hash"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="single-element array ref to empty hash"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="<port1>.", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_hash0 [label="\\{\\}", rank=1, shape=plaintext];
	}
	gvds_array0:port1 -> gvds_hash0;
}

)
)
%%
(name => 'three-element array ref to empty hashes',
 code => 'my @a=({},{},{}); 
        GraphViz::Data::Structure->new(\\@a,graph=>{label=>"three-element array ref to empty hashes"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="three-element array ref to empty hashes"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="{<port1>.}|{<port2>.}|{<port3>.}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_hash0 [label="\\{\\}", rank=1, shape=plaintext];
		gvds_hash1 [label="\\{\\}", rank=1, shape=plaintext];
		gvds_hash2 [label="\\{\\}", rank=1, shape=plaintext];
	}
	gvds_array0:port1 -> gvds_hash0;
	gvds_array0:port2 -> gvds_hash1;
	gvds_array0:port3 -> gvds_hash2;
}

)
)
%%
(name => 'single-element array ref to one-element hashes',
 code => 'my @a=({"test"=>1}); 
        GraphViz::Data::Structure->new(\\@a,graph=>{label=>"single-element array ref to one-element hashes"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="single-element array ref to one-element hashes"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="<port1>.", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_hash0 [label="{<port1>test|<port2>1}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_array0:port1 -> gvds_hash0;
}

)
)
%%
(name => 'three-element array ref to one-element hashes',
 code => 'my @a=({"larry"=>2},{"moe"=>1},{"curly"=>3}); 
        GraphViz::Data::Structure->new(\\@a,graph=>{label=>"three-element array ref to one-element hashes"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="three-element array ref to one-element hashes"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="{<port1>.}|{<port2>.}|{<port3>.}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_hash0 [label="{<port1>larry|<port2>2}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_hash1 [label="{<port1>moe|<port2>1}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_hash2 [label="{<port1>curly|<port2>3}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_array0:port1 -> gvds_hash0;
	gvds_array0:port2 -> gvds_hash1;
	gvds_array0:port3 -> gvds_hash2;
}

)
)
%%
(name => 'single-element array ref to three-element hash',
 code => 'my @a=({"larry"=>2,"moe"=>1,"curly"=>3}); 
        GraphViz::Data::Structure->new(\\@a,graph=>{label=>"single-element array ref to three-element hash"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="single-element array ref to three-element hash"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="<port1>.", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_hash0 [label="{<port1>curly|<port2>3}|{<port3>larry|<port4>2}|{<port5>moe|<port6>1}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_array0:port1 -> gvds_hash0;
}

)
)
%%
(name => 'three-element array ref to three-element hashes',
 code => 'my @a=({"larry"=>2,"moe"=>1,"curly"=>3},
               {"groucho"=>1,"harpo"=>3,"chico"=>2},
               {"seagoon"=>2,"bloodnok"=>1,"eccles"=>3}); 
        GraphViz::Data::Structure->new(\\@a,graph=>{label=>"three-element array ref to three-element hashes"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="three-element array ref to three-element hashes"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="{<port1>.}|{<port2>.}|{<port3>.}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_hash0 [label="{<port1>curly|<port2>3}|{<port3>larry|<port4>2}|{<port5>moe|<port6>1}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_hash1 [label="{<port1>chico|<port2>2}|{<port3>groucho|<port4>1}|{<port5>harpo|<port6>3}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_hash2 [label="{<port1>bloodnok|<port2>1}|{<port3>eccles|<port4>3}|{<port5>seagoon|<port6>2}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_array0:port1 -> gvds_hash0;
	gvds_array0:port2 -> gvds_hash1;
	gvds_array0:port3 -> gvds_hash2;
}

)
)
%%
(name => 'verify port assignments',
 code => 'my @a=(Nil=>[],Nada=>[],Zip=>[]); 
        GraphViz::Data::Structure->new(\\@a,graph=>{label=>"verify port assignments"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="verify port assignments"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="{<port1>Nil}|{<port2>.}|{<port3>Nada}|{<port4>.}|{<port5>Zip}|{<port6>.}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array1 [label="\\[\\]", rank=1, shape=plaintext];
		gvds_array2 [label="\\[\\]", rank=1, shape=plaintext];
		gvds_array3 [label="\\[\\]", rank=1, shape=plaintext];
	}
	gvds_array0:port2 -> gvds_array1;
	gvds_array0:port4 -> gvds_array2;
	gvds_array0:port6 -> gvds_array3;
}

)
)
%%
(name => 'odd characters',
 code => 'my @a=("<html>"=>[],"<script>"=>[],"<body>"=>[]); 
        GraphViz::Data::Structure->new(\\@a,graph=>{label=>"odd characters"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="odd characters"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="{<port1>\\<html\\>}|{<port2>.}|{<port3>\\<script\\>}|{<port4>.}|{<port5>\\<body\\>}|{<port6>.}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array1 [label="\\[\\]", rank=1, shape=plaintext];
		gvds_array2 [label="\\[\\]", rank=1, shape=plaintext];
		gvds_array3 [label="\\[\\]", rank=1, shape=plaintext];
	}
	gvds_array0:port2 -> gvds_array1;
	gvds_array0:port4 -> gvds_array2;
	gvds_array0:port6 -> gvds_array3;
}

)
)
