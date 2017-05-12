package Git::Demo::Story::Event;
use strict;
use warnings;

sub new{
    my $class = shift;
    my $args = shift;

    if( ! $args ){
        die( "No args passed" );
    }

    if( ! ref( $args ) eq 'HASH' ){
        die( "args passed weren't a HASHREF" );
    }

    my $self = {};
    my $logger = Log::Log4perl->get_logger( "Git::Demo::Story::Event" );
    $self->{logger} = $logger;

    # Required attributes
    foreach( qw/characters action type/ ){
        if( ! $args->{$_} ){
            die( "Required argument $_ not passed" );
        }
        $self->{$_} = $args->{$_};
    }
    if( $args->{args} ){
        if( ref( $args->{args} ) eq 'ARRAY' ){
            $self->{args} = $args->{args};
        }else{
            die( "args is not an arrayref" );
        }
    }
    $self->{args} ||= [];

    bless $self, $class;
    return $self;
}

sub characters{
    my $self = shift;
    return $self->{characters};
}

sub action{
    my $self = shift;
    return $self->{action};
}

sub type{
    my $self = shift;
    return $self->{type};
}

sub args{
    my $self = shift;
    return $self->{args};
}

sub to_hash{
    my $self = shift;
    my $hash = { characters => $self->{characters},
                 action     => $self->{action},
                 type       => $self->{type},
                 args       => $self->{args} };
    return $hash;
}

sub stringify{
    my $self = shift;
    return sprintf( "%-12s %s %s\n", $self->{characters}, $self->{action}, join( ' ', @{ $self->{args} } ) );
}

1;
