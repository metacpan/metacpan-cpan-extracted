#!/usr/bin/perl -w

BEGIN {
  unshift @INC,'../lib';
}

use Test::More tests=>6;
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
(name => 'multi glob ref, default colors',
 code => 'my ($a,$b,@c,%d); 
          $a=\\*Foo::Bar; 
          *Foo::Bar=\\&normalize; 
          *Foo::Bar=\\$b; $b="test string"; 
          *Foo::Bar = \\@c; @c=qw(foo bar baz); 
          *Foo::Bar = \\%d; %d = (This=>That,The=>Other);  
          my $z = GraphViz::Data::Structure->new(\\$a,graph=>{label=>"multi glob ref, default colors"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="multi glob ref, default colors"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_glob0 [label="{<port0>*Foo::Bar|{{<port1>Array|<port2>.}|{<port3>Hash|<port4>.}|{<port5>Scalar|<port6>.}|{<port7>Sub|<port8>.}}}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array0 [label="{<port1>foo}|{<port2>bar}|{<port3>baz}", color=white, fontcolor=black, rank=2, shape=record, style=filled];
		gvds_hash0 [label="{<port1>The|<port2>Other}|{<port3>This|<port4>That}", color=white, fontcolor=black, rank=2, shape=record, style=filled];
		gvds_atom0 [label="test string", rank=2, shape=plaintext];
		gvds_sub0 [label="&main::normalize", rank=2, shape=plaintext];
	}
	gvds_glob0:port2 -> gvds_array0;
	gvds_glob0:port6 -> gvds_atom0;
	gvds_glob0:port4 -> gvds_hash0;
	gvds_glob0:port8 -> gvds_sub0;
	gvds_scalar0 -> gvds_glob0:port0;
}

)
)
%%
(name => 'multi glob ref, pastel colors',
 code => 'my ($a,$b,@c,%d); 
          $a=\\*Foo::Bar; 
          *Foo::Bar=\\&normalize; 
          *Foo::Bar=\\$b; 
          $b="test string"; 
          *Foo::Bar = \\@c; 
          @c=qw(foo bar baz); 
          *Foo::Bar = \\%d; 
          %d = (This=>That,The=>Other);  
          my $z = GraphViz::Data::Structure->new(\\$a,graph=>{label=>"multi glob ref, pastel colors"},Colors=>Pastel)->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="multi glob ref, pastel colors"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="", color=lightyellow, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_glob0 [label="{<port0>*Foo::Bar|{{<port1>Array|<port2>.}|{<port3>Hash|<port4>.}|{<port5>Scalar|<port6>.}|{<port7>Sub|<port8>.}}}", color=lavender, fontcolor=black, rank=1, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array0 [label="{<port1>foo}|{<port2>bar}|{<port3>baz}", color=palevioletred, fontcolor=black, rank=2, shape=record, style=filled];
		gvds_hash0 [label="{<port1>The|<port2>Other}|{<port3>This|<port4>That}", color=paleturquoise, fontcolor=black, rank=2, shape=record, style=filled];
		gvds_atom0 [label="test string", rank=2, shape=plaintext];
		gvds_sub0 [label="&main::normalize", rank=2, shape=plaintext];
	}
	gvds_glob0:port2 -> gvds_array0;
	gvds_glob0:port6 -> gvds_atom0;
	gvds_glob0:port4 -> gvds_hash0;
	gvds_glob0:port8 -> gvds_sub0;
	gvds_scalar0 -> gvds_glob0:port0;
}

)
)
%%
(name => 'multi glob ref, bright colors',
 code => 'my ($a,$b,@c,%d); 
          $a=\\*Foo::Bar; 
          *Foo::Bar=\\&normalize; 
          *Foo::Bar=\\$b; $b="test string"; 
          *Foo::Bar = \\@c; 
          @c=qw(foo bar baz); 
          *Foo::Bar = \\%d; 
          %d = (This=>That,The=>Other);  
          my $z = GraphViz::Data::Structure->new(\\$a,graph=>{label=>"multi glob ref, bright colors"},Colors=>Bright,"fontcolor"=>"white","fontname"=>"Helvetica")->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="multi glob ref, bright colors"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="", color=yellow, fontcolor=white, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_glob0 [label="{<port0>*Foo::Bar|{{<port1>Array|<port2>.}|{<port3>Hash|<port4>.}|{<port5>Scalar|<port6>.}|{<port7>Sub|<port8>.}}}", color=purple, fontcolor=white, rank=1, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array0 [label="{<port1>foo}|{<port2>bar}|{<port3>baz}", color=tomato, fontcolor=white, rank=2, shape=record, style=filled];
		gvds_hash0 [label="{<port1>The|<port2>Other}|{<port3>This|<port4>That}", color=cyan, fontcolor=white, rank=2, shape=record, style=filled];
		gvds_atom0 [label="test string", rank=2, shape=plaintext];
		gvds_sub0 [label="&main::normalize", rank=2, shape=plaintext];
	}
	gvds_glob0:port2 -> gvds_array0;
	gvds_glob0:port6 -> gvds_atom0;
	gvds_glob0:port4 -> gvds_hash0;
	gvds_glob0:port8 -> gvds_sub0;
	gvds_scalar0 -> gvds_glob0:port0;
}

)
)
%%
(name => 'multi glob ref, custom colors',
 code => 'my ($a,$b,@c,%d); 
          $a=\\*Foo::Bar; 
          *Foo::Bar=\\&normalize; 
          *Foo::Bar=\\$b; 
          $b="test string"; 
          *Foo::Bar = \\@c; 
          @c=qw(foo bar baz); 
          *Foo::Bar = \\%d; 
          %d = (This=>That,The=>Other);  
          my $z = GraphViz::Data::Structure->new(\\$a,Colors=>{Scalar=>"indianred1", Array=>"burlywood2", Hash=>"seagreen1", Glob=>"moccasin"},graph=>{label=>"multi glob ref, custom colors"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="multi glob ref, custom colors"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="", color=indianred1, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_glob0 [label="{<port0>*Foo::Bar|{{<port1>Array|<port2>.}|{<port3>Hash|<port4>.}|{<port5>Scalar|<port6>.}|{<port7>Sub|<port8>.}}}", color=moccasin, fontcolor=black, rank=1, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array0 [label="{<port1>foo}|{<port2>bar}|{<port3>baz}", color=burlywood2, fontcolor=black, rank=2, shape=record, style=filled];
		gvds_hash0 [label="{<port1>The|<port2>Other}|{<port3>This|<port4>That}", color=seagreen1, fontcolor=black, rank=2, shape=record, style=filled];
		gvds_atom0 [label="test string", rank=2, shape=plaintext];
		gvds_sub0 [label="&main::normalize", rank=2, shape=plaintext];
	}
	gvds_glob0:port2 -> gvds_array0;
	gvds_glob0:port6 -> gvds_atom0;
	gvds_glob0:port4 -> gvds_hash0;
	gvds_glob0:port8 -> gvds_sub0;
	gvds_scalar0 -> gvds_glob0:port0;
}

)
)
%%
(name => 'multi glob ref, default colors with overrides',
 code => 'my ($a,$b,@c,%d); 
          $a=\\*Foo::Bar; 
          *Foo::Bar=\\&normalize; 
          *Foo::Bar=\\$b; 
          $b="test string"; 
          *Foo::Bar = \\@c; 
          @c=qw(foo bar baz); 
          *Foo::Bar = \\%d; 
          %d = (This=>That,The=>Other);  
          my $z = GraphViz::Data::Structure->new(\\$a,Colors=>{Hash=>"red"},graph=>{label=>"multi glob ref, default colors with overrides"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="multi glob ref, default colors with overrides"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="", color=indianred1, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_glob0 [label="{<port0>*Foo::Bar|{{<port1>Array|<port2>.}|{<port3>Hash|<port4>.}|{<port5>Scalar|<port6>.}|{<port7>Sub|<port8>.}}}", color=moccasin, fontcolor=black, rank=1, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array0 [label="{<port1>foo}|{<port2>bar}|{<port3>baz}", color=burlywood2, fontcolor=black, rank=2, shape=record, style=filled];
		gvds_hash0 [label="{<port1>The|<port2>Other}|{<port3>This|<port4>That}", color=red, fontcolor=black, rank=2, shape=record, style=filled];
		gvds_atom0 [label="test string", rank=2, shape=plaintext];
		gvds_sub0 [label="&main::normalize", rank=2, shape=plaintext];
	}
	gvds_glob0:port2 -> gvds_array0;
	gvds_glob0:port6 -> gvds_atom0;
	gvds_glob0:port4 -> gvds_hash0;
	gvds_glob0:port8 -> gvds_sub0;
	gvds_scalar0 -> gvds_glob0:port0;
}

)
)
%%
(name => 'multi glob ref, create a palette',
 code => 'my ($a,$b,@c,%d); 
          $a=\\*Foo::Bar; 
          *Foo::Bar=\\&normalize; 
          *Foo::Bar=\\$b; 
          $b="test string"; 
          *Foo::Bar = \\@c; 
          @c=qw(foo bar baz); 
          *Foo::Bar = \\%d; 
          %d = (This=>That,The=>Other); 
          my $z = GraphViz::Data::Structure->new(\\$a,Colors=>"pink",graph=>{label=>"multi glob ref, create a palette"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="multi glob ref, create a palette"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="", color=pink, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_glob0 [label="{<port0>*Foo::Bar|{{<port1>Array|<port2>.}|{<port3>Hash|<port4>.}|{<port5>Scalar|<port6>.}|{<port7>Sub|<port8>.}}}", color=pink, fontcolor=black, rank=1, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array0 [label="{<port1>foo}|{<port2>bar}|{<port3>baz}", color=pink, fontcolor=black, rank=2, shape=record, style=filled];
		gvds_hash0 [label="{<port1>The|<port2>Other}|{<port3>This|<port4>That}", color=pink, fontcolor=black, rank=2, shape=record, style=filled];
		gvds_atom0 [label="test string", rank=2, shape=plaintext];
		gvds_sub0 [label="&main::normalize", rank=2, shape=plaintext];
	}
	gvds_glob0:port2 -> gvds_array0;
	gvds_glob0:port6 -> gvds_atom0;
	gvds_glob0:port4 -> gvds_hash0;
	gvds_glob0:port8 -> gvds_sub0;
	gvds_scalar0 -> gvds_glob0:port0;
}

)
)
