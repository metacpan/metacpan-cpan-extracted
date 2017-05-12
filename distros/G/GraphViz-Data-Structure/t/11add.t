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
(name => 'add subbing for new',
 code => 'my ($a); 
          $a=[1,2,4,8]; 
          my $z = GraphViz::Data::Structure->new(\\$a,graph=>{label=>"ad subbing for new"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="ad subbing for new"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array0 [label="{<port1>1}|{<port2>2}|{<port3>4}|{<port4>8}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_scalar0 -> gvds_array0;
}

)
)
%%
(name => 'add actually adding',
 code => 'my ($a); 
          $a=[1,2,4,8]; 
          my $z = GraphViz::Data::Structure->new(\\$a,graph=>{label=>"add actually adding"}); 
          my $b=[10,20,30]; 
          my $w = $z->add($b)->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="add actually adding"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="", color=white, fontcolor=black, rank=0, shape=record, style=filled];
		gvds_array1 [label="{<port1>10}|{<port2>20}|{<port3>30}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_array0 [label="{<port1>1}|{<port2>2}|{<port3>4}|{<port4>8}", color=white, fontcolor=black, rank=1, shape=record, style=filled];
	}
	gvds_scalar0 -> gvds_array0;
}

)
)
%%
(name => 'tie it together',
 code => 'my ($a); 
          $a=[1,2,4,8]; 
         my $z = GraphViz::Data::Structure->new($a,graph=>{label=>"tie it together"}); 
         my $b=[10,20,30]; 
         $z->add($b); 
         my $c=[$a,$b]; 
         $z->add($c)->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="tie it together"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_array0 [label="{<port1>1}|{<port2>2}|{<port3>4}|{<port4>8}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
		gvds_array1 [label="{<port1>10}|{<port2>20}|{<port3>30}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
		gvds_array2 [label="{<port1>.}|{<port2>.}", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	gvds_array2:port1 -> gvds_array0;
	gvds_array2:port2 -> gvds_array1;
}

)
)
