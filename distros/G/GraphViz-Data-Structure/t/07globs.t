#!/usr/bin/perl -w

BEGIN {
  unshift @INC,'../lib';
}

use Test::More tests=>4;
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
(name => 'file glob',
 code => 'my $a = *STDOUT; 
          GraphViz::Data::Structure->new($a,graph=>{label=>"file glob"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="file glob"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_atom0 [label="*main::STDOUT", rank=0, shape=plaintext];
	}
}

)
)
%%
(name => 'empty glob ref',
 code => 'my $a = \\*FOO; 
          GraphViz::Data::Structure->new($a,graph=>{label=>"empty glob ref"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="empty glob ref"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_glob0 [label="{<port0>*main::FOO|{(empty)}}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
}

)
)
%%
(name => 'file glob ref',
 code => 'my $a = \\*STDOUT; 
          GraphViz::Data::Structure->new($a,graph=>{label=>"file glob ref"})->graph->as_canon',
 out  => qq((fileno(1))", rank=1, shape=plaintext];
	}
	gvds_glob0:port2 -> gvds_atom0;
}

digraph test {
	graph [ratio=fill, label="file glob ref"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_glob0 [label="{<port0>*main::STDOUT|{{<port1>Filehandle|<port2>.}}}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_atom0 [label="FileHandle *main::STDOUT\
)
)
%%
(name => 'multi glob ref',
 code => 'my ($a,$b,@c,%d); 
          $a=\\*Foo::Bar; 
          *Foo::Bar=\\&normalize; 
          *Foo::Bar=\\$b; 
          $b="test string"; 
          *Foo::Bar = \\@c; 
          @c=qw(foo bar baz); 
          *Foo::Bar = \\%d; 
          %d = (This=>That,The=>Other);  
          GraphViz::Data::Structure->new(\\$a,graph=>{label=>"multi glob ref"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="multi glob ref"];
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
