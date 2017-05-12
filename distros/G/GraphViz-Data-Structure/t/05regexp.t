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
(name => 'regexp-textual',
 code => 'my $a = qr/foo/; 
          GraphViz::Data::Structure->new($a,graph=>{label=>"regexp-textual"})->graph->as_canon',
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
(name => 'regexp-ref',
 code => 'my $a = qr/.*?foo[^2]\\d\\w/; 
          GraphViz::Data::Structure->new(\\$a,graph=>{label=>"regexp-ref"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="regexp-ref"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_scalar0 [label="", color=white, fontcolor=black, rank=0, shape=record, style=filled];
	}
	{
		graph [rank=same];
		gvds_atom0 [label="qr/.*?foo\\\\[\\^2\\\\]\\\\d\\\\w/", rank=1, shape=plaintext];
	}
	gvds_scalar0 -> gvds_atom0;
}

)
)
%%
(name => 'regexp-flagged',
 code => 'my $a = qr/foo/ix; 
          GraphViz::Data::Structure->new($a,graph=>{label=>"regexp-flagged"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="regexp-flagged"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_atom0 [label="qr/foo/ix", rank=0, shape=plaintext];
	}
}

)
)
%%
(name => 'regexp-interpolated',
 code => 'my $b="bar";my $a = qr/foo$b/; 
          GraphViz::Data::Structure->new($a,graph=>{label=>"regexp-interpolated"})->graph->as_canon',
 out  => qq(digraph test {
	graph [ratio=fill, label="regexp-interpolated"];
	node [label="\\N"];
	{
		graph [rank=same];
		gvds_atom0 [label="qr/foobar/", rank=0, shape=plaintext];
	}
}

)
)
