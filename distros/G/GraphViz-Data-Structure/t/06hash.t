#!/usr/bin/perl -w

BEGIN {
  unshift @INC,'../lib';
}

use Test::More tests=>17;
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
(name => 'ref to zero-element hash',
 code => 'GraphViz::Data::Structure->new(\\{},graph=>{label=>"ref to zero-element hash"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="ref to zero-element hash"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_hash0 [label="\\{\\}", rank=1, shape=plaintext];
	}
	gvds_scalar0 -> gvds_hash0;
}

)
)
%%
(name => 'ref to one-element hash',
 code => 'GraphViz::Data::Structure->new(\\{"test"=>"me"},graph=>{label=>"ref to one-element hash"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="ref to one-element hash"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_hash0 [label="{<port1>test|<port2>me}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_scalar0 -> gvds_hash0;
}

)
)
%%
(name => 'ref to three-element hash',
 code => 'GraphViz::Data::Structure->new(\\{"larry"=>"fuzz","moe"=>"mop","curly"=>"none"},
        graph=>{label=>"ref to three-element hash"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="ref to three-element hash"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_hash0 [label="{<port1>curly|<port2>none}|{<port3>larry|<port4>fuzz}|{<port5>moe|<port6>mop}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_scalar0 -> gvds_hash0;
}

)
)
%%
(name => 'ref to vertical three-element hash',
 code => 'GraphViz::Data::Structure->new(\\{"larry"=>"fuzz","moe"=>"mop","curly"=>"none"},
        Orientation=>"vertical",graph=>{label=>"ref to vertical three-element hash"})->graph->as_canon',
 out  => qq(digraph test {
	graph [rankdir=LR, ratio=fill, label="ref to vertical three-element hash"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_hash0 [label="{{<port1>curly|<port3>larry|<port5>moe}|{<port2>none|<port4>fuzz|<port6>mop}}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_scalar0 -> gvds_hash0;
}

)
)
%%
(name => 'single-element hash ref to empty arrays',
 code => 'my %a=(Empty=>[]); 
        GraphViz::Data::Structure->new(\\%a,graph=>{label=>"single-element hash ref to empty arrays"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="single-element hash ref to empty arrays"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_hash0 [label="{<port1>Empty|<port2>.}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array0 [label="\\[\\]", rank=1, shape=plaintext];
	}
	gvds_hash0:port2 -> gvds_array0;
}

)
)
%%
(name => 'three-element hash ref to empty arrays',
 code => 'my %a=(Nil=>[],Nada=>[],Zip=>[]); 
        GraphViz::Data::Structure->new(\\%a,graph=>{label=>"three-element hash ref to empty arrays"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="three-element hash ref to empty arrays"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_hash0 [label="{<port1>Nada|<port2>.}|{<port3>Nil|<port4>.}|{<port5>Zip|<port6>.}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array0 [label="\\[\\]", rank=1, shape=plaintext];
		gvds_array1 [label="\\[\\]", rank=1, shape=plaintext];
		gvds_array2 [label="\\[\\]", rank=1, shape=plaintext];
	}
	gvds_hash0:port2 -> gvds_array0;
	gvds_hash0:port4 -> gvds_array1;
	gvds_hash0:port6 -> gvds_array2;
}

)
)
%%
(name => 'single-element hash ref to one-element arrays',
 code => 'my %a=(Pointer=>["test"]); 
        GraphViz::Data::Structure->new(\\%a,graph=>{label=>"single-element hash ref to one-element arrays"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="single-element hash ref to one-element arrays"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_hash0 [label="{<port1>Pointer|<port2>.}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array0 [label="<port1>test", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_hash0:port2 -> gvds_array0;
}

)
)
%%
(name => 'three-element hash ref to one-element arrays',
 code => 'my %a=(Fuzz=>["larry"],Mop=>["moe"],Bald=>["curly"]); 
        GraphViz::Data::Structure->new(\\%a,graph=>{label=>"three-element hash ref to one-element arrays"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="three-element hash ref to one-element arrays"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_hash0 [label="{<port1>Bald|<port2>.}|{<port3>Fuzz|<port4>.}|{<port5>Mop|<port6>.}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array0 [label="<port1>curly", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_array1 [label="<port1>larry", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_array2 [label="<port1>moe", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_hash0:port2 -> gvds_array0;
	gvds_hash0:port4 -> gvds_array1;
	gvds_hash0:port6 -> gvds_array2;
}

)
)
%%
(name => 'single-element hash ref to three-element arrays',
 code => 'my %a=(Stooges=>["larry","moe","curly"]); 
        GraphViz::Data::Structure->new(\\%a,graph=>{label=>"single-element hash ref to three-element arrays"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="single-element hash ref to three-element arrays"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_hash0 [label="{<port1>Stooges|<port2>.}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array0 [label="{<port1>larry}|{<port2>moe}|{<port3>curly}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_hash0:port2 -> gvds_array0;
}

)
)
%%
(name => 'three-element hash ref to three-element arrays',
 code => 'my %a=(Stooges=>["larry","moe","curly"],
               MarxBros=>["groucho","harpo","chico"],
               Goons=>["seagoon","bloodnok","eccles"]); 
        GraphViz::Data::Structure->new(\\%a,graph=>{label=>"three-element hash ref to three-element arrays"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="three-element hash ref to three-element arrays"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_hash0 [label="{<port1>Goons|<port2>.}|{<port3>MarxBros|<port4>.}|{<port5>Stooges|<port6>.}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array0 [label="{<port1>seagoon}|{<port2>bloodnok}|{<port3>eccles}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_array1 [label="{<port1>groucho}|{<port2>harpo}|{<port3>chico}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_array2 [label="{<port1>larry}|{<port2>moe}|{<port3>curly}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_hash0:port2 -> gvds_array0;
	gvds_hash0:port4 -> gvds_array1;
	gvds_hash0:port6 -> gvds_array2;
}

)
)
%%
(name => 'single-element hash ref to empty hashes',
 code => 'my %a=(Nil=>{}); 
        GraphViz::Data::Structure->new(\\%a,graph=>{label=>"single-element hash ref to empty hashes"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="single-element hash ref to empty hashes"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_hash0 [label="{<port1>Nil|<port2>.}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_hash1 [label="\\{\\}", rank=1, shape=plaintext];
	}
	gvds_hash0:port2 -> gvds_hash1;
}

)
)
%%
(name => 'three-element hash ref to empty hashes',
 code => 'my %a=(Nada=>{},Zilch=>{},Zip=>{}); 
        GraphViz::Data::Structure->new(\\%a,graph=>{label=>"three-element hash ref to empty hashes"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="three-element hash ref to empty hashes"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_hash0 [label="{<port1>Nada|<port2>.}|{<port3>Zilch|<port4>.}|{<port5>Zip|<port6>.}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_hash1 [label="\\{\\}", rank=1, shape=plaintext];
		gvds_hash2 [label="\\{\\}", rank=1, shape=plaintext];
		gvds_hash3 [label="\\{\\}", rank=1, shape=plaintext];
	}
	gvds_hash0:port2 -> gvds_hash1;
	gvds_hash0:port4 -> gvds_hash2;
	gvds_hash0:port6 -> gvds_hash3;
}

)
)
%%
(name => 'single-element hash ref to one-element hashes',
 code => 'my %a=(One=>{"test"=>"2"}); 
        GraphViz::Data::Structure->new(\\%a,graph=>{label=>"single-element hash ref to one-element hashes"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="single-element hash ref to one-element hashes"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_hash0 [label="{<port1>One|<port2>.}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_hash1 [label="{<port1>test|<port2>2}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_hash0:port2 -> gvds_hash1;
}

)
)
%%
(name => 'three-element hash ref to one-element hashes',
 code => 'my %a=(One=>{"larry"=>"fuzz"},
               Two=>{"moe"=>"mop"},
               Three=>{"curly"=>"none"}); 
        GraphViz::Data::Structure->new(\\%a,graph=>{label=>"three-element hash ref to one-element hashes"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="three-element hash ref to one-element hashes"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_hash0 [label="{<port1>One|<port2>.}|{<port3>Three|<port4>.}|{<port5>Two|<port6>.}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_hash1 [label="{<port1>larry|<port2>fuzz}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_hash2 [label="{<port1>curly|<port2>none}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_hash3 [label="{<port1>moe|<port2>mop}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_hash0:port2 -> gvds_hash1;
	gvds_hash0:port4 -> gvds_hash2;
	gvds_hash0:port6 -> gvds_hash3;
}

)
)
%%
(name => 'single-element hash ref to three-element hashes',
 code => 'my %a=(Stooges=>{"larry"=>"fuzz","moe"=>"mop","curly"=>"none"}); 
        GraphViz::Data::Structure->new(\\%a,graph=>{label=>"single-element hash ref to three-element hashes"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="single-element hash ref to three-element hashes"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_hash0 [label="{<port1>Stooges|<port2>.}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_hash1 [label="{<port1>curly|<port2>none}|{<port3>larry|<port4>fuzz}|{<port5>moe|<port6>mop}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_hash0:port2 -> gvds_hash1;
}

)
)
%%
(name => 'three-element hash ref to three-element hashes',
 code => 'my %a=(Stooges=>{"larry"=>1,"moe"=>2,"curly"=>3},
               MarxBros=>{"groucho"=>1,"harpo"=>2,"chico"=>3},
               Goons=>{"seagoon"=>1,"bloodnok"=>2,"eccles"=>3}); 
        GraphViz::Data::Structure->new(\\%a,graph=>{label=>"three-element hash ref to three-element hashes"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="three-element hash ref to three-element hashes"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_hash0 [label="{<port1>Goons|<port2>.}|{<port3>MarxBros|<port4>.}|{<port5>Stooges|<port6>.}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_hash1 [label="{<port1>bloodnok|<port2>2}|{<port3>eccles|<port4>3}|{<port5>seagoon|<port6>1}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_hash2 [label="{<port1>chico|<port2>3}|{<port3>groucho|<port4>1}|{<port5>harpo|<port6>2}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_hash3 [label="{<port1>curly|<port2>3}|{<port3>larry|<port4>1}|{<port5>moe|<port6>2}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_hash0:port2 -> gvds_hash1;
	gvds_hash0:port4 -> gvds_hash2;
	gvds_hash0:port6 -> gvds_hash3;
}

)
)
%%
(name => 'odd characters in parent',
 code => 'my %a=("<html>"=>{"larry"=>1,"moe"=>2,"curly"=>3},
               "<script>"=>{"groucho"=>1,"harpo"=>2,"chico"=>3},
               "<body>"=>{"seagoon"=>1,"bloodnok"=>2,"eccles"=>3}); 
        GraphViz::Data::Structure->new(\\%a,graph=>{label=>"odd characters in parent"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="odd characters in parent"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_hash0 [label="{<port1>\\<body\\>|<port2>.}|{<port3>\\<html\\>|<port4>.}|{<port5>\\<script\\>|<port6>.}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_hash1 [label="{<port1>bloodnok|<port2>2}|{<port3>eccles|<port4>3}|{<port5>seagoon|<port6>1}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_hash2 [label="{<port1>curly|<port2>3}|{<port3>larry|<port4>1}|{<port5>moe|<port6>2}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
		gvds_hash3 [label="{<port1>chico|<port2>3}|{<port3>groucho|<port4>1}|{<port5>harpo|<port6>2}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_hash0:port2 -> gvds_hash1;
	gvds_hash0:port4 -> gvds_hash2;
	gvds_hash0:port6 -> gvds_hash3;
}

)
)
