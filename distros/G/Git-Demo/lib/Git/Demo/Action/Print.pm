package Git::Demo::Action::Print;
use strict;
use warnings;

sub new{
    my $class = shift;
    my $args = shift;

    my $self = {};
    my $logger = Log::Log4perl->get_logger( __PACKAGE__ );
    $self->{logger} = $logger;

    bless $self, $class;
    return $self;
}

sub run{
    my( $self, $character, $event ) = @_;
    my @args = @{ $event->args() };
    foreach( @args ){
        printf( ">> %-12s : %s\n", $character->name() . ' says', $_ );
    }
}


1;
