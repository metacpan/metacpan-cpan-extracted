package MColPro::TimeList;

use strict;
use warnings;

use Carp qw/carp/;
use Scalar::Util 'weaken';
use namespace::clean 0.20;

sub new
{
	my $class = shift;
	my $self = bless {
		head => undef,
		tail => undef,
		size => 0,
	}, $class;

    $self->{head} = 
    {
        item => [ 0, '' ],
        next => undef,
        prev => undef
    };
    $self->{tail} =
    {
        item => [ time + 31536000*100, '' ],
        next => undef,
        prev => undef
    };

    $self->{head}{next} = $self->{tail};
    $self->{tail}{prev} = $self->{head};

	return $self;
}

sub get {
    my $self = shift;

    my @result;
    my $now = time;

    
    for( my $current = $self->{head}{next}; defined $current; )
    {
        my $next = $current->{next};

        if( $current->{item}[0] <= $now )
        {
            push @result, $current->{item};

            $self->{size}--;

            $current->{prev}{next} = $current->{next};
            $current->{next}{prev} = $current->{prev};

            $current->{prev} = undef;
            $current->{next} = undef;
        }
        else
        {
            last;
        }

        $current = $next;
    }

    return \@result;
}

sub put {
	my ( $self, $item ) = @_;

    my $current = $self->{tail}{prev};
    for ( ; defined $current && $current != $self->{head};
        $current = $current->{prev} )
    {
        last if $item->[0] > $current->{item}[0];
    }

	my $new_node =
    {
        item => $item,
	    prev => $current,
	    next => $current->{next},
	};
	$current->{next}{prev} = $new_node;
	$current->{next} = $new_node;
	$self->{size}++;

	return;
}

sub flatten
{
    my $self = shift;
    my @ret;

    my $current = $self->{head};
    for ( ; defined $current; $current = $current->{next} )
    {
        my %tmp = %{ $current->{item} };
        push @ret, \%tmp;
    }

    return \@ret;
}

sub size {
	my $self = shift;
	return $self->{size};
}

1;
