package Graph::Bipartite;
# $Id: Bipartite.pm,v 1.1 2003/05/25 15:03:20 detzold Exp $

require 5.005_62;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Graph::Bipartite ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.01';


# Preloaded methods go here.
my $n1;
my $n2;
my $n;
my @neighbours;

sub new {
	$n1 = $_[ 1 ];
	$n2 = $_[ 2 ];
	$n = $n1 + $n2;
	for( my $i = 0; $i < $n; $i++ ) {
		$neighbours[ $i ] = [];
	}
	my $class = shift;
	my $self = { };
	bless( $self, $class );
	return $self;
}

sub insert_edge {
	push( @{ $neighbours[ $_[ 1 ] ] }, $_[ 2 ] );
	push( @{ $neighbours[ $_[ 2 ] ] }, $_[ 1 ] );
}

sub neighbours {
	if( scalar( @{ $neighbours[ $_[ 1 ] ] } ) > 0 ) {
		return scalar( @{ $neighbours[ $_[ 1 ] ] } );
	}
	0;
}

my @matching;

sub maximum_matching {
	for( my $i = 0; $i < $n; ++$i ) {
		$matching[ $i ] = -1;
	}
	while( _sbfs() > 0 ) {
		_sdfs();
	}
	my %h;
	for( my $i = 0; $i < $n1; ++$i ) {
		if( $matching[ $i ] != -1 ) {
			$h{ $i } = $matching[ $i ];
		}
	}
	%h;
}

my @level;

sub _sbfs {
	my @queue1;
	my @queue2;
	for( my $i = 0; $i < $n1; ++$i ) {
		if( $matching[ $i ] == -1 ) {
			$level[ $i ] = 0;
			push( @queue1, $i );
		} else {
			$level[ $i ] = -1;
		}
	}
	for( my $i = $n1; $i < $n; ++$i ) {
		$level[ $i ] = -1;
	}
	while( scalar( @queue1 ) > 0 ) {
		$#queue2 = -1;
		my $free = 0;
		while( scalar( @queue1 ) > 0 ) {
			my $v = pop( @queue1 );
			for my $w ( @{ $neighbours[ $v ] } ) {
				if( $matching[ $v ] != $w && $level[ $w ] == -1 ) {
					$level[ $w ] = $level[ $v ] + 1;
					push( @queue2, $w );
					if( $matching[ $w ] == -1 ) {
						$free = $w;
					}
				}
			}
		}
		if( $free > 0 ) {
			return 1;
		}
		$#queue1 = -1;
		while( scalar( @queue2 ) > 0 ) {
			my $v = pop( @queue2 );
			for my $w ( @{ $neighbours[ $v ] } ) {
				if( $matching[ $v ] == $w && $level[ $w ] == -1 ) {
					$level[ $w ] = $level[ $v ] + 1;
					push( @queue1, $w );
				}
			}
		}
	}
	0;
}

sub _sdfs {
	for( my $i = 0; $i < $n1; ++$i ) {
		if( $matching[ $i ] == -1 ) {
			_rec_sdfs( $i );
		}
	}
}

sub _rec_sdfs {
	my $u = $_[ 0 ];
	if( $u < $n1 ) {
		for my $w ( @{ $neighbours[ $u ] } ) {
			if( $matching[ $u ] != $w && $level[ $w ] == $level[ $u ] + 1 ) {
				if( _rec_sdfs( $w ) == 1 ) {
					$matching[ $u ] = $w;
					$matching[ $w ] = $u;
					$level[ $u ] = -1;
					return 1;
				}
			}
		}
	} else {
		if( $matching[ $u ] == -1 ) {
			$level[ $u ] = -1;
			return 1;
		} else {
			for my $w ( @{ $neighbours[ $u ] } ) {
				if( $matching[ $u ] == $w && $level[ $w ] == $level[ $u ] + 1 ) {
					if( _rec_sdfs( $w ) == 1 ) {
						$level[ $u ] = -1;
						return 1;
					}
				}
			}
		}
	}
	$level[ $u ] = -1;
	0;
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Graph::Bipartite - Graph algorithms on bipartite graphs.

=head1 SYNOPSIS

  use Graph::Bipartite;
  $g = Graph::Bipartite->new( 5, 4 ); 
  $g->insert_edge( 3, 5 );
  $g->insert_edge( 2, 7 );
  %h = $g->maximum_matching();

=head1 DESCRIPTION

This algorithm computes the maximum matching of a bipartite unweighted  
and undirected graph in worst case running time O( sqrt(|V|) * |E| ).

The constructor takes as first argument the number of vertices  of the 
first partition V1, as second argument  the number of  vertices of the
second  partition V2. For nodes of the first partition the valid range 
is [0..|V1|-1], for nodes of the  second partition  it is [|V1|..|V1|+|V2|-1].

The function  maximum_matching()  returns a maximum matching as a hash 
where the keys  represents  the  vertices of  V1 and the value of each
key an edge to a vertex in V2 being in the matching.

=head1 AUTHOR

Daniel Etzold, detzold@gmx.de

=head1 SEE ALSO

perl(1).

=cut
