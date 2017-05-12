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
(name => 'coderef (anon)',
 code => '$a02 = sub { shift}; 
          GraphViz::Data::Structure->new($a02,graph=>{label=>"coderef (anon)"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="coderef (anon)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_sub0 [label="&main::__ANON__", rank=0, shape=plaintext];
	}
}

)
)
%%
(name => 'coderef (named)',
 code => '$a02 = \\&get_current; 
          GraphViz::Data::Structure->new($a02,graph=>{label=>"coderef (named)"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="coderef (named)"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_sub0 [label="&main::get_current", rank=0, shape=plaintext];
	}
}

)
)
%%
(name => 'undef',
 code => 'GraphViz::Data::Structure->new(undef,graph=>{label=>"undef"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label=undef];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_atom0 [label=undef, rank=0, shape=plaintext];
	}
}

)
)
%%
(name => 'atom',
 code => 'GraphViz::Data::Structure->new(1,graph=>{label=>"atom"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label=atom];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_atom0 [label=1, rank=0, shape=plaintext];
	}
}

)
)
%%
(name => 'scalar',
 code => '$a02 = 1; 
          GraphViz::Data::Structure->new($a02,graph=>{label=>"scalar"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label=scalar];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_atom0 [label=1, rank=0, shape=plaintext];
	}
}

)
)
%%
(name => 'undef ref',
 code => '$a02 = undef; 
          GraphViz::Data::Structure->new(\\$a02,graph=>{label=>"undef ref"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="undef ref"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_atom0 [label=undef, rank=1, shape=plaintext];
	}
	gvds_scalar0 -> gvds_atom0;
}

)
)
%%
(name => 'glob',
 code => '$a02 = *Foo; 
          GraphViz::Data::Structure->new(\\$a02,graph=>{label=>"glob"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label=glob];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_glob0 [label="{<port0>*main::Foo|{(empty)}}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
}

)
)
%%
(name => 'regexp-textual',
 code => '$a02 = qr/foo/; 
          GraphViz::Data::Structure->new($a02,graph=>{label=>"regexp-textual"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="regexp-textual"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_atom0 [label="qr/foo/", rank=0, shape=plaintext];
	}
}

)
)
%%
(name => 'regexp-flagged',
 code => '$a02 = qr/foo/mixs; 
          GraphViz::Data::Structure->new($a02,graph=>{label=>"regexp-flagged"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="regexp-flagged"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_atom0 [label="qr/foo/msix", rank=0, shape=plaintext];
	}
}

)
)
%%
(name => 'empty array',
 code => 'GraphViz::Data::Structure->new([],graph=>{label=>"empty array"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="empty array"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="\\[\\]", rank=0, shape=plaintext];
	}
}

)
)
%%
(name => 'empty hash',
 code => 'GraphViz::Data::Structure->new({},graph=>{label=>"empty hash"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="empty hash"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_hash0 [label="\\{\\}", rank=0, shape=plaintext];
	}
}

)
)
%%
(name => 'one-element array',
 code => 'GraphViz::Data::Structure->new([1],graph=>{label=>"one-element array"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="one-element array"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="<port1>1", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
}

)
)
%%
(name => 'three-element array, horizontal',
 code => 'GraphViz::Data::Structure->new(["sample","something longer",1],graph=>{label=>"three-element array, horizontal"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="three-element array, horizontal"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="{<port1>sample}|{<port2>something longer}|{<port3>1}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
}

)
)
%%
(name => 'three-element array, vertical',
 code => 'GraphViz::Data::Structure->new(["sample","something longer",1],Orientation=>"vertical",graph=>{label=>"three-element array, vertical"})->graph->as_canon',
 out  => qq(digraph test {
	graph [rankdir=LR, ratio=fill, label="three-element array, vertical"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="{<port1>sample}|{<port2>something longer}|{<port3>1}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
}

)
)
%%
(name => 'one-element hash, horizontal',
 code => 'GraphViz::Data::Structure->new({"first"=>"one"},graph=>{label=>"one-element hash, horizontal"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="one-element hash, horizontal"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_hash0 [label="{<port1>first|<port2>one}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
}

)
)
%%
(name => 'one-element hash, vertical',
 code => 'GraphViz::Data::Structure->new({"first"=>"one"},Orientation=>"vertical",graph=>{label=>"one-element hash, vertical"})->graph->as_canon',
 out  => qq(digraph test {
	graph [rankdir=LR, ratio=fill, label="one-element hash, vertical"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_hash0 [label="{<port1>first|<port2>one}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
}

)
)
%%
(name => 'three-element hash, horizontal',
 code => 'GraphViz::Data::Structure->new({Alpha=>"sample",Beta=>"a longer string",Gamma=>1},graph=>{label=>"three-element hash, horizontal"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="three-element hash, horizontal"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_hash0 [label="{<port1>Alpha|<port2>sample}|{<port3>Beta|<port4>a longer string}|{<port5>Gamma|<port6>1}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
}

)
)
%%
(name => 'three-element hash, vertical',
 code => 'GraphViz::Data::Structure->new({Alpha=>"sample",Beta=>"a longer string",Gamma=>1},Orientation=>"vertical",graph=>{label=>"three-element hash, vertical"})->graph->as_canon',
 out  => qq(digraph test {
	graph [rankdir=LR, ratio=fill, label="three-element hash, vertical"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_hash0 [label="{{<port1>Alpha|<port3>Beta|<port5>Gamma}|{<port2>sample|<port4>a longer string|<port6>1}}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
}

)
)
