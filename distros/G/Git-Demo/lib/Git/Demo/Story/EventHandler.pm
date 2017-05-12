package Git::Demo::Story::EventHandler;
use strict;
use warnings;
use Git::Demo::Action::Git;
use Git::Demo::Action::Print;
use Git::Demo::Action::File;

sub new{
    my $class = shift;
    my $args = shift;

    my $self = {};
    foreach( qw/story/ ){
        if( ! $args->{$_} ){
            die( __PACKAGE__ . " requires $_" );
        }
        $self->{$_} = $args->{$_};
    }

    # And the optionals
    foreach( qw/verbose/ ){
        $self->{$_} = $args->{$_};
    }

    my %action_handlers = ( 'git'   => Git::Demo::Action::Git->new(),
                            'print' => Git::Demo::Action::Print->new(),
                            'file'  => Git::Demo::Action::File->new(),
                           );
    $self->{action_handlers} = \%action_handlers;

    my $logger = Log::Log4perl->get_logger( __PACKAGE__ );
    $self->{logger} = $logger;

    bless $self, $class;
    return $self;
}

sub characters{
    my $self  = shift;
    my $event = shift;

    my @characters = ();
    my @names = split( / /, $event->characters() );

    if( scalar( @names ) == 0 ){
        return @characters;
    }

    # If the magic word ALL is used, get all characters
    if( $names[0] =~ m/^ALL/ ){
        my $magic = shift( @names );
        if( $magic eq 'ALL' ){
            @characters = values( %{ $self->{story}->characters() } );
        }else{
            # But if the magic word ALL_NOT, then use all as a basis, but remove those which come
            # after ALL_NOT
            my @temp_characters = values( %{ $self->{story}->characters() } );
          CHARACTER:
            foreach my $character( @temp_characters ){
                foreach( @names ){
                    if( $_ eq $character->name() ){
                        next CHARACTER;
                    }
                }
                push( @characters, $character );
            }
        }
    }else{
        # We just have a list of names - see if we know the characters
        foreach( @names ){
            my $character = $self->{story}->get_character( $_ );
            if( ! $character ){
                die( "Unknown character (" . $event->character() . ")" );
            }
            push( @characters, $character );
        }
    }
    return @characters;
}

sub exec{
    my $self  = shift;
    my $event = shift;
    my $logger = $self->{logger};

    my $action_handler = undef;
    if( ! defined( $self->{action_handlers}->{ $event->type() } ) ){
        die( "Unknown event type: " . $event->type() );
    }

    my @characters = $self->characters( $event );
    foreach my $character( @characters ){
        $logger->debug( sprintf( "running a %s action for %s", $event->type(), $character->name() ) );
        my( $rtn, $warnings ) = $self->{action_handlers}->{ $event->type() }->run( $character, $event );
        if( $self->{verbose} && $rtn ){
            print $rtn;
        }
        if( $warnings ){
            print "Git warnings:\n$warnings";
        }
    }
}
1;
