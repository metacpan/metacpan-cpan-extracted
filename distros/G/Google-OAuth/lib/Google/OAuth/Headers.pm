package Google::OAuth::Headers ;
@Google::OAuth::Headers::ISA = qw( Google::OAuth::Request ) ;

## use this package for custom header fields:
## Google::OAuth::Headers->new( $token )->add(
##	foo => 'bar'
##	)->request( GET => $url, ... ) ;

sub new {
	my $package = shift ;
	return bless { headers => [], token => shift @_ }, $package ;
	}

sub add {
	my $self = shift ;
	push @{ $self->{headers} }, @_ ;
	return $self ;
	}

sub headers {
	my $self = shift ;
	my $method = shift ;

	return $self->{token}->headers( $method ), @{ $self->{headers} } ;
	}

1
