####################################################################
#
#    This file was generated using Parse::Yapp version 1.02.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package Graph::Reader::Dot;
$Graph::Reader::Dot::VERSION = '2.09';
use strict;
use warnings;

use parent 'Parse::Yapp::Driver';



sub new {
        my($class)=shift;
        ref($class)
    and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '1.02',
                                  yystates =>
[
	{#State 0
		ACTIONS => {
			'STRICT' => 1,
			'GRAPH' => 2,
			'DIGRAPH' => 5
		},
		GOTOS => {
			'Graph' => 3,
			'GraphType' => 4
		}
	},
	{#State 1
		ACTIONS => {
			'STRICT' => 1,
			'GRAPH' => 2,
			'DIGRAPH' => 5
		},
		GOTOS => {
			'GraphType' => 6
		}
	},
	{#State 2
		DEFAULT => -6
	},
	{#State 3
		ACTIONS => {
			'' => 7
		}
	},
	{#State 4
		ACTIONS => {
			'QUOT' => 9,
			'NUMBER' => 8,
			'ID' => 10
		},
		GOTOS => {
			'IdNumQuot' => 11
		}
	},
	{#State 5
		DEFAULT => -5
	},
	{#State 6
		DEFAULT => -4
	},
	{#State 7
		DEFAULT => -0
	},
	{#State 8
		DEFAULT => -31
	},
	{#State 9
		DEFAULT => -30
	},
	{#State 10
		DEFAULT => -32
	},
	{#State 11
		ACTIONS => {
			"{" => 12
		}
	},
	{#State 12
		ACTIONS => {
			'GRAPH' => 13,
			'EDGE' => 17,
			'NODE' => 19,
			'NUMBER' => 8,
			'QUOT' => 9,
			"{" => 22,
			'SUBGRAPH' => 24,
			'ID' => 10
		},
		DEFAULT => -2,
		GOTOS => {
			'AttrStmt' => 15,
			'NodeId' => 14,
			'StmtList' => 16,
			'IdNumQuot' => 18,
			'OptStmtList' => 20,
			'Stmt' => 21,
			'Attr' => 23,
			'Subgraph' => 25,
			'EdgeStmt' => 26,
			'NodeStmt' => 27,
			'NodeIdSubgraph' => 28
		}
	},
	{#State 13
		ACTIONS => {
			"[" => 29
		},
		DEFAULT => -33,
		GOTOS => {
			'OptAttrList' => 30
		}
	},
	{#State 14
		ACTIONS => {
			"[" => 29
		},
		DEFAULT => -26,
		GOTOS => {
			'OptAttrList' => 31
		}
	},
	{#State 15
		ACTIONS => {
			";" => 32
		},
		DEFAULT => -39,
		GOTOS => {
			'OptSemicolon' => 33
		}
	},
	{#State 16
		ACTIONS => {
			'GRAPH' => 13,
			'EDGE' => 17,
			'NODE' => 19,
			'NUMBER' => 8,
			'QUOT' => 9,
			"{" => 22,
			'SUBGRAPH' => 24,
			'ID' => 10
		},
		DEFAULT => -3,
		GOTOS => {
			'AttrStmt' => 15,
			'NodeId' => 14,
			'IdNumQuot' => 18,
			'Stmt' => 34,
			'Attr' => 23,
			'Subgraph' => 25,
			'EdgeStmt' => 26,
			'NodeStmt' => 27,
			'NodeIdSubgraph' => 28
		}
	},
	{#State 17
		ACTIONS => {
			"[" => 29
		},
		DEFAULT => -33,
		GOTOS => {
			'OptAttrList' => 35
		}
	},
	{#State 18
		ACTIONS => {
			":" => 36,
			"=" => 37
		},
		DEFAULT => -21
	},
	{#State 19
		ACTIONS => {
			"[" => 29
		},
		DEFAULT => -33,
		GOTOS => {
			'OptAttrList' => 38
		}
	},
	{#State 20
		ACTIONS => {
			"}" => 39
		}
	},
	{#State 21
		DEFAULT => -10
	},
	{#State 22
		DEFAULT => -7,
		GOTOS => {
			'BeginScope' => 41,
			'WrappedStmtList' => 40
		}
	},
	{#State 23
		ACTIONS => {
			";" => 32
		},
		DEFAULT => -39,
		GOTOS => {
			'OptSemicolon' => 42
		}
	},
	{#State 24
		ACTIONS => {
			'QUOT' => 9,
			'NUMBER' => 8,
			'ID' => 10
		},
		GOTOS => {
			'IdNumQuot' => 43
		}
	},
	{#State 25
		ACTIONS => {
			";" => 32
		},
		DEFAULT => -25,
		GOTOS => {
			'OptSemicolon' => 44
		}
	},
	{#State 26
		ACTIONS => {
			";" => 32
		},
		DEFAULT => -39,
		GOTOS => {
			'OptSemicolon' => 45
		}
	},
	{#State 27
		ACTIONS => {
			";" => 32
		},
		DEFAULT => -39,
		GOTOS => {
			'OptSemicolon' => 46
		}
	},
	{#State 28
		ACTIONS => {
			'EDGEOP' => 47,
			"[" => 29
		},
		DEFAULT => -33,
		GOTOS => {
			'OptAttrList' => 48
		}
	},
	{#State 29
		ACTIONS => {
			'QUOT' => 9,
			'NUMBER' => 8,
			"]" => 52,
			'ID' => 10
		},
		GOTOS => {
			'Attr' => 51,
			'IdNumQuot' => 49,
			'AttrList' => 50
		}
	},
	{#State 30
		DEFAULT => -17
	},
	{#State 31
		DEFAULT => -20
	},
	{#State 32
		DEFAULT => -40
	},
	{#State 33
		DEFAULT => -12
	},
	{#State 34
		DEFAULT => -11
	},
	{#State 35
		DEFAULT => -19
	},
	{#State 36
		ACTIONS => {
			'QUOT' => 9,
			'NUMBER' => 8,
			'ID' => 10
		},
		GOTOS => {
			'IdNumQuot' => 53
		}
	},
	{#State 37
		ACTIONS => {
			'QUOT' => 9,
			'NUMBER' => 8,
			'ID' => 10
		},
		GOTOS => {
			'IdNumQuot' => 54
		}
	},
	{#State 38
		DEFAULT => -18
	},
	{#State 39
		ACTIONS => {
			";" => 32
		},
		DEFAULT => -39,
		GOTOS => {
			'OptSemicolon' => 55
		}
	},
	{#State 40
		ACTIONS => {
			"}" => 56
		}
	},
	{#State 41
		ACTIONS => {
			"{" => 22,
			'QUOT' => 9,
			'NUMBER' => 8,
			'GRAPH' => 13,
			'SUBGRAPH' => 24,
			'ID' => 10,
			'EDGE' => 17,
			'NODE' => 19
		},
		GOTOS => {
			'AttrStmt' => 15,
			'NodeId' => 14,
			'StmtList' => 57,
			'IdNumQuot' => 18,
			'Stmt' => 21,
			'Attr' => 23,
			'Subgraph' => 25,
			'EdgeStmt' => 26,
			'NodeStmt' => 27,
			'NodeIdSubgraph' => 28
		}
	},
	{#State 42
		DEFAULT => -16
	},
	{#State 43
		ACTIONS => {
			"{" => 58
		},
		DEFAULT => -29
	},
	{#State 44
		DEFAULT => -15
	},
	{#State 45
		DEFAULT => -14
	},
	{#State 46
		DEFAULT => -13
	},
	{#State 47
		ACTIONS => {
			"{" => 22,
			'QUOT' => 9,
			'NUMBER' => 8,
			'SUBGRAPH' => 24,
			'ID' => 10
		},
		GOTOS => {
			'NodeId' => 59,
			'Subgraph' => 61,
			'EdgeStmt' => 62,
			'IdNumQuot' => 60,
			'NodeIdSubgraph' => 28
		}
	},
	{#State 48
		DEFAULT => -24
	},
	{#State 49
		ACTIONS => {
			"=" => 37
		}
	},
	{#State 50
		ACTIONS => {
			"," => 64,
			"]" => 65
		},
		DEFAULT => -41,
		GOTOS => {
			'OptComma' => 63
		}
	},
	{#State 51
		DEFAULT => -37
	},
	{#State 52
		DEFAULT => -34
	},
	{#State 53
		DEFAULT => -22
	},
	{#State 54
		DEFAULT => -38
	},
	{#State 55
		DEFAULT => -1
	},
	{#State 56
		DEFAULT => -27
	},
	{#State 57
		ACTIONS => {
			'GRAPH' => 13,
			'EDGE' => 17,
			'NODE' => 19,
			'NUMBER' => 8,
			'QUOT' => 9,
			"{" => 22,
			'SUBGRAPH' => 24,
			'ID' => 10
		},
		DEFAULT => -8,
		GOTOS => {
			'EndScope' => 66,
			'AttrStmt' => 15,
			'NodeId' => 14,
			'IdNumQuot' => 18,
			'Stmt' => 34,
			'Attr' => 23,
			'Subgraph' => 25,
			'EdgeStmt' => 26,
			'NodeStmt' => 27,
			'NodeIdSubgraph' => 28
		}
	},
	{#State 58
		DEFAULT => -7,
		GOTOS => {
			'BeginScope' => 41,
			'WrappedStmtList' => 67
		}
	},
	{#State 59
		DEFAULT => -26
	},
	{#State 60
		ACTIONS => {
			":" => 36
		},
		DEFAULT => -21
	},
	{#State 61
		DEFAULT => -25
	},
	{#State 62
		DEFAULT => -23
	},
	{#State 63
		ACTIONS => {
			'QUOT' => 9,
			'NUMBER' => 8,
			'ID' => 10
		},
		GOTOS => {
			'Attr' => 68,
			'IdNumQuot' => 49
		}
	},
	{#State 64
		DEFAULT => -42
	},
	{#State 65
		DEFAULT => -35
	},
	{#State 66
		DEFAULT => -9
	},
	{#State 67
		ACTIONS => {
			"}" => 69
		}
	},
	{#State 68
		DEFAULT => -36
	},
	{#State 69
		DEFAULT => -28
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'Graph', 6,
sub
#line 16 "Graph_Reader_Dot.yp"
{
		# add the graph attributes...
		my $r = $_[0]->YYData->{DefAttr}->[-1]->{Graph};
		my $g = $_[0]->{GRAPH};
		for my $attr (keys %{$r}) {
			my $value = $r->{$attr};
			$g->set_graph_attribute($attr,$value);
		}
		$g->set_graph_attribute('name', $_[2] ); 	# set name, will be reused by Graph::Writer::Dot
	}
	],
	[#Rule 2
		 'OptStmtList', 0,
sub
#line 28 "Graph_Reader_Dot.yp"
{ #empty
		return undef;
	}
	],
	[#Rule 3
		 'OptStmtList', 1, undef
	],
	[#Rule 4
		 'GraphType', 2,
sub
#line 35 "Graph_Reader_Dot.yp"
{
		return $_[2];	# dunno what to do with the strict anyway...
	}
	],
	[#Rule 5
		 'GraphType', 1, undef
	],
	[#Rule 6
		 'GraphType', 1,
sub
#line 41 "Graph_Reader_Dot.yp"
{
		&{$_[0]->YYData->{Options}->{Carp}}( "!graph will be treated as digraph" );	# see below for expl.
		return $_[1];
	}
	],
	[#Rule 7
		 'BeginScope', 0,
sub
#line 48 "Graph_Reader_Dot.yp"
{	# empty
		# mah: use some clone() function?
		# mah: for optimization should do lazy copying... (i.e. COW, copy-on-write)
		my $n = {};
		$n->{Graph} = { %{$_[0]->YYData->{DefAttr}->[-1]->{Graph}} };
		$n->{Node} = { %{$_[0]->YYData->{DefAttr}->[-1]->{Node}} };
		$n->{Edge} = { %{$_[0]->YYData->{DefAttr}->[-1]->{Edge}} };
		push @{$_[0]->YYData->{DefAttr}}, $n;
	}
	],
	[#Rule 8
		 'EndScope', 0,
sub
#line 59 "Graph_Reader_Dot.yp"
{	# empty
		pop @{$_[0]->YYData->{DefAttr}};
	}
	],
	[#Rule 9
		 'WrappedStmtList', 3,
sub
#line 64 "Graph_Reader_Dot.yp"
{
		return $_[2];
	}
	],
	[#Rule 10
		 'StmtList', 1,
sub
#line 69 "Graph_Reader_Dot.yp"
{
		return $_[1];
	}
	],
	[#Rule 11
		 'StmtList', 2,
sub
#line 73 "Graph_Reader_Dot.yp"
{
		for my $k ( keys %{$_[2]} ) {	# merge the hashes
			$_[1]->{$k}++;
		}
		return $_[1];
	}
	],
	[#Rule 12
		 'Stmt', 2,
sub
#line 81 "Graph_Reader_Dot.yp"
{
		return {};
	}
	],
	[#Rule 13
		 'Stmt', 2, undef
	],
	[#Rule 14
		 'Stmt', 2,
sub
#line 87 "Graph_Reader_Dot.yp"
{
		return $_[1]->[2];	# only pass on the cumulative node set
	}
	],
	[#Rule 15
		 'Stmt', 2, undef
	],
	[#Rule 16
		 'Stmt', 2,
sub
#line 93 "Graph_Reader_Dot.yp"
{	# graph / subgraph attribute (i.e. same as graph [bla=3];)
		my $r = $_[0]->YYData->{DefAttr}->[-1]->{Graph};
		$r->{$_[1]->[0]} = $_[1]->[1];

		return {};	# no node returned...
	}
	],
	[#Rule 17
		 'AttrStmt', 2,
sub
#line 101 "Graph_Reader_Dot.yp"
{
		_merge_hash( $_[0]->YYData->{DefAttr}->[-1]->{Graph}, $_[2] );
	}
	],
	[#Rule 18
		 'AttrStmt', 2,
sub
#line 105 "Graph_Reader_Dot.yp"
{	# note: those will only apply to newly created nodes...
		_merge_hash( $_[0]->YYData->{DefAttr}->[-1]->{Node}, $_[2] );
	}
	],
	[#Rule 19
		 'AttrStmt', 2,
sub
#line 109 "Graph_Reader_Dot.yp"
{	# note: those will only apply to newly created edges...
		_merge_hash( $_[0]->YYData->{DefAttr}->[-1]->{Edge}, $_[2] );
	}
	],
	[#Rule 20
		 'NodeStmt', 2,
sub
#line 114 "Graph_Reader_Dot.yp"
{
		my $g = $_[0]->{GRAPH};
		unless( $g->has_vertex($_[1]) ) {
			$g->add_vertex($_[1]);
			# default node attribute only apply to *new* nodes (as in dot)
			# btw, that implies also, that the order is important in dot files for the attribute values...
			if( $_[0]->YYData->{Options}->{UseNodeAttr} ) {
				_set_attribute_hash( $g, $_[0]->YYData->{DefAttr}->[-1]->{Node}, $_[1] );
			}
		};
		_set_attribute_hash( $g, $_[2], $_[1] );
		return { $_[1] => 1 };
	}
	],
	[#Rule 21
		 'NodeId', 1, undef
	],
	[#Rule 22
		 'NodeId', 3,
sub
#line 131 "Graph_Reader_Dot.yp"
{
		&{$_[0]->YYData->{Options}->{Carp}}( "!cannot correctly process subnodes" );
		return $_[1];
	}
	],
	[#Rule 23
		 'EdgeStmt', 3,
sub
#line 142 "Graph_Reader_Dot.yp"
{
		my $g = $_[0]->{GRAPH};
		for my $u (keys %{$_[1]}) {
			for my $v (keys %{ @{$_[3]}[0] } ) {
				# add non-existent nodes...	(should make a separate loop for efficiency)
				if( $_[0]->YYData->{Options}->{UseNodeAttr} ) {
					unless ( $g->has_vertex($u) ) {
						$g->add_vertex($u); # important
						_set_attribute_hash( $g, $_[0]->YYData->{DefAttr}->[-1]->{Node}, $u );
					}
					unless(  $g->has_vertex($v) ) {
						$g->add_vertex($v);	# important
						_set_attribute_hash( $g, $_[0]->YYData->{DefAttr}->[-1]->{Node}, $v );
					}
				}
				$g->add_edge($u,$v);
				_set_attribute_hash($g, $_[3]->[1], $u, $v );
				if( $_[0]->YYData->{Options}->{UseEdgeAttr} ) {
					_set_attribute_hash($g, $_[0]->YYData->{DefAttr}->[-1]->{Edge}, $u, $v );
				}
			}
		}
		for my $u (keys %{$_[1]}) {	# update cumulative node hash
			$_[3]->[2]->{$u}++;
		}
		return [$_[1],$_[3]->[1], $_[3]->[2]];
	}
	],
	[#Rule 24
		 'EdgeStmt', 2,
sub
#line 170 "Graph_Reader_Dot.yp"
{
		return [$_[1],$_[2],$_[1]];	# mah: not copying $_[1] is dangerous but works at the moment
			# (it requires the other routines to keep the order of (a) make edges and (b) update cumulative nodes)
	}
	],
	[#Rule 25
		 'NodeIdSubgraph', 1, undef
	],
	[#Rule 26
		 'NodeIdSubgraph', 1,
sub
#line 178 "Graph_Reader_Dot.yp"
{
		return { $_[1] => 1 }
	}
	],
	[#Rule 27
		 'Subgraph', 3,
sub
#line 185 "Graph_Reader_Dot.yp"
{	# anonymous subgraph
		return $_[2];
	}
	],
	[#Rule 28
		 'Subgraph', 5,
sub
#line 189 "Graph_Reader_Dot.yp"
{	# named subgraph
		# have to store the nodeset somewhere...
		if( defined $_[0]->YYData->{Subgraphs}->{$_[2]} ) {
			# check for name clash for subgraph
			die "?subgraph '$_[2]' has been doubly defined\n";
		} else {
			# *copy* the subgraphs nodes for later use
			# mah: note: assumptions is, that the outside may (and in fact will) modify hash contents
			$_[0]->YYData->{Subgraphs}->{$_[2]} = { %{$_[4]} };
		}
		return $_[4];
	}
	],
	[#Rule 29
		 'Subgraph', 2,
sub
#line 202 "Graph_Reader_Dot.yp"
{	# subgraph reference (mah: what does it do?)
		if( !defined $_[0]->YYData->{Subgraphs}->{$_[2]} ) {
			# check for missing name
			die "?subgraph '$_[2]' has not been defined\n";
		} else {
			# hand out copy...
			return +{ %{$_[0]->YYData->{Subgraphs}->{$_[2]}} };
		}
	}
	],
	[#Rule 30
		 'IdNumQuot', 1,
sub
#line 213 "Graph_Reader_Dot.yp"
{
		return substr $_[1],1,-1;
	}
	],
	[#Rule 31
		 'IdNumQuot', 1, undef
	],
	[#Rule 32
		 'IdNumQuot', 1, undef
	],
	[#Rule 33
		 'OptAttrList', 0,
sub
#line 223 "Graph_Reader_Dot.yp"
{ # may be empty
		return {};
	}
	],
	[#Rule 34
		 'OptAttrList', 2,
sub
#line 227 "Graph_Reader_Dot.yp"
{
		return {};
	}
	],
	[#Rule 35
		 'OptAttrList', 3,
sub
#line 231 "Graph_Reader_Dot.yp"
{
		return $_[2];
	}
	],
	[#Rule 36
		 'AttrList', 3,
sub
#line 236 "Graph_Reader_Dot.yp"
{
		my ($k,$v) = @{$_[3]};
		$_[1]->{$k} = $v;
		return $_[1];
	}
	],
	[#Rule 37
		 'AttrList', 1,
sub
#line 242 "Graph_Reader_Dot.yp"
{
		return { @{$_[1]} };	# pull it into a hash reference
	}
	],
	[#Rule 38
		 'Attr', 3,
sub
#line 247 "Graph_Reader_Dot.yp"
{
		return [$_[1],$_[3]];
	}
	],
	[#Rule 39
		 'OptSemicolon', 0,
sub
#line 252 "Graph_Reader_Dot.yp"
{ #empty
		return ';' # just for the sake of completeness...
	}
	],
	[#Rule 40
		 'OptSemicolon', 1,
sub
#line 256 "Graph_Reader_Dot.yp"
{
	}
	],
	[#Rule 41
		 'OptComma', 0,
sub
#line 260 "Graph_Reader_Dot.yp"
{ # empty
		return ',';	# for the sake of completeness...
	}
	],
	[#Rule 42
		 'OptComma', 1,
sub
#line 264 "Graph_Reader_Dot.yp"
{
	}
	]
],
                                  @_);
    bless($self,$class);
}

#line 267 "Graph_Reader_Dot.yp"


sub _merge_hash {
	my ($dst,$src) = @_;
	# merge keys and values of %{$src} in %{$dst}
	for ( keys %$src ) {
		$dst->{$_} = $src->{$_};
	}
}

sub _set_attribute_hash {
	my $g = shift;
	my $h = shift;
	local $_;

	# @_ contains the destination... (graph, node, edge)
	for (keys %$h ) {
		if (@_ == 0) {
			$g->set_graph_attribute(@_,$_,$h->{$_});
		} elsif (@_ == 1) {
			$g->set_vertex_attribute(@_,$_,$h->{$_});
		} else {
			$g->set_edge_attribute(@_,$_,$h->{$_});
		}
	}
}

# lexer starts here:

# build regexp for reserved words:
my @reserved = qw(
	strict digraph graph edge node subgraph
);
my $reserved_re = qr{\b(@{[join '|', @reserved]})\b}oi;

sub _Error {
    exists $_[0]->YYData->{ERRMSG} and do {
        print $_[0]->YYData->{ERRMSG};
        delete $_[0]->YYData->{ERRMSG};
        return;
    };
	print "\$_[0]->YYCurtok " . $_[0]->YYCurtok."\n";
	print "\$_[0]->YYCurval " . $_[0]->YYCurval."\n";
	print "\@\$_[0]->YYExpect " . (join " ", $_[0]->YYExpect )."\n";
	print "\$_[0]->YYLexer " . $_[0]->YYLexer."\n";
	print "substr(\$_[0]->YYData->{INPUT},0,21) " .  substr($_[0]->YYData->{INPUT},0,21) . "...\n";
    print "Syntax error.\n";
}

sub _Lexer {
    my($parser)=shift;
	my $fh = $parser->{FILE};

	$parser->YYData->{INPUT} =~ s:^//.*::;	# must be at beginning of string, this ensures it is unquoted (string are only single line)
	if( $parser->YYData->{INPUT} eq '' ) {
		do {
			return ('',undef) if( $fh->eof );
			$_ = <$fh>;
			chomp;
			s/^\s*//;
			if( m:/\*: ) {	# kill c-style comments
			# TODO scan for eof...
				while( ! s:/\*.*\*/::s ) {
					$_ .= <$fh>;
				}
				chomp;
			}
		} while( m:^//:  || $_ eq '' );	# skip comment & empty lines
		$parser->YYData->{INPUT} = $_;
	}

	$parser->YYData->{INPUT} =~ s/^($reserved_re)\s*// and return uc $1;	# reserved word
	$parser->YYData->{INPUT} =~ s/^(-[->])\s*// and return( 'EDGEOP', $1 );	# edge operator (directed or undirected)
	$parser->YYData->{INPUT} =~ s/^([_a-zA-Z][._a-zA-Z0-9]*)\s*// and return( 'ID',$1 );	# identifier
	$parser->YYData->{INPUT} =~ s/^(-?[0-9]*\.[0-9]*|-?[0-9]+)\s*// and return( 'NUMBER',$1 );	# number
	$parser->YYData->{INPUT} =~ s/^(\"(?:\\\"|[^\"])*\")\s*// and return( 'QUOT', $1 );	# quoted string
	$parser->YYData->{INPUT} =~ s/^(.)\s*//s and return($1,$1);	# any char
}

use Graph::Reader;
use vars qw(@ISA $UseNodeAttr $UseEdgeAttr);

@ISA = qw(Parse::Yapp::Driver Graph::Reader);	# this will override setting from yapp

sub _init {
    my $self = shift;
    $self->SUPER::_init();
}

sub _read_graph {
    my $self  = shift;
    my $graph = shift;
    my $FILE  = shift;

    $self->{CONTEXT} = [];
    $self->{GRAPH}   = $graph;
	$self->{FILE} = $FILE;
	# initialize parse data structures...
	undef $self->YYData->{Subgraphs};	# will contain node sets for every name subgraph
	# clear default attribs for current scope:
	$self->YYData->{DefAttr} = [{Graph=>{}, Node=>{}, Edge=>{}}];
	$self->YYData->{Options}->{UseNodeAttr} = $UseNodeAttr;
	$self->YYData->{Options}->{UseEdgeAttr} = $UseEdgeAttr;
	$self->YYData->{Options}->{Carp} = \&Carp::carp;
	$self->YYData->{Options}->{Croak} = \&Carp::croak;
	# ^ now that's a workaround for not being able to declare Carp early enough, coz of Yapp restrictions...

	# the following kills a warning from the test regression suite:
	$self->YYData->{INPUT} = '' unless defined $self->YYData->{INPUT};

	$self->YYParse( yylex => \&_Lexer, yyerror => \&_Error );

    return 1;
}

1;

=head1 NAME

Graph::Reader::Dot - class for reading a Graph instance from Dot format

=head1 SYNOPSIS

    use Graph::Reader::Dot;
    use Graph;

    $reader = Graph::Reader::Dot->new();
    $graph = $reader->read_graph('mygraph.dot');

=head1 DESCRIPTION

B<Graph::Reader::Dot> is a class for reading in a directed graph
in the file format used by the I<dot> tool (part of the AT+T graphviz
package).

B<Graph::Reader::Dot> is a subclass of B<Graph::Reader>,
which defines the generic interface for Graph reader classes.

=head1 METHODS AND CONFIGURATION

=head2 C<new()>

Constructor - generate a new reader instance.

    $reader = Graph::Reader::Dot->new();

This doesn't take any arguments.

=head2 C<read_graph()>

Read a graph from a file:

    $graph = $reader->read_graph( $file );

The C<$file> argument can be either a filename
or a filehandle of a previously opened file.

=head2 C<$Graph::Reader::Dot::UseNodeAttr>

Controls, if implicit node attributes given by the dot directive C<node[]> will be merged into (new) nodes.
Setting it to C<0> or C<undef> (default) will not disable this feature.
Setting it to any other value will enable this feature.

=head2 C<$Graph::Reader::Dot::UseEdgeAttr>

Controls, if implicit edge attributes given by the dot directive C<edge[]> will be merged into edges.
Setting it to C<0> or C<undef> (default) will not disable this feature.
Setting it to any other value will enable this feature.

=head1 RESTRICTIONS

=over 4

=item *

Default (graph) attributes in subgraphs (i.e. inside C<{}>) are not processed.

=item *

Sub nodes as used by dot's C<record> node shape are supported.

=item *

Undirected graphs will be treated as directed graphs.
This means that the C<--> edge operator works as the C<-E<gt>> edge operator.

=item *

Be aware that you are loosing scope information on writing back the graph.

=item *

Multiple C<node[]> or C<edge[]> statements in the same scope are not correctly supported.

=back

=head1 SEE ALSO

=over 4

=item http://www.graphviz.org/

The home page for the AT+T graphviz toolkit that
includes the dot tool.

=item Graph::Reader

The base class for B<Graph::Reader::Dot>.

=item Graph::Writer::Dot

Used to serialise a Graph instance in Dot format.

=item Graph

Jarkko Hietaniemi's classes for representing directed graphs.

=item Parse::Yapp

Another base class for B<Graph::Reader::Dot>.
The B<Parse::Yapp> module comes with the following copyright notice:

The Parse::Yapp module and its related modules and shell
scripts are copyright (c) 1998-1999 Francois Desarmenien,
France. All rights reserved.

You may use and distribute them under the terms of either
the GNU General Public License or the Artistic License, as
specified in the Perl README file.

If you use the "standalone parser" option so people don't
need to install Parse::Yapp on their systems in order to
run you software, this copyright noticed should be
included in your software copyright too, and the copyright
notice in the embedded driver should be left untouched.

=back

=head1 AUTHOR

Mark A. Hillebrand E<lt>mah@wjpserver.cs.uni-sb.deE<gt>

=head1 COPYRIGHT

Copyright (c) 2001 by Mark A. Hillebrand.  All rights reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


1;
