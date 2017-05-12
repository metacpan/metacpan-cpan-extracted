package Git::Demo::Story;
use strict;
use warnings;
use Git::Demo::Story::Event;
use Git::Demo::Story::Character;
use Git::Demo::Story::EventHandler;
use YAML::Any qw/LoadFile DumpFile/;

=head1 NAME

Git::Demo::Story - The story with which to run a demo

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

##FIXME

=head1 SUBROUTINES/METHODS

=head2 new

=cut


sub new{
    my $class = shift;
    my $args = shift;

    my $self = {};

    foreach( qw/dir/ ){
        if( ! $args->{$_} ){
            die( __PACKAGE__ . " requires argument $_" );
        }
        $self->{$_} = $args->{$_};
    }

    foreach( qw/verbose/ ){
        $self->{$_} = $args->{$_};
    }

    my $logger = Log::Log4perl->get_logger( __PACKAGE__ );
    $self->{logger} = $logger;

    bless $self, $class;

    if( $args->{story_file} ){
        $self->load_story( $args->{story_file} );
    }

    $self->{event_handler} = Git::Demo::Story::EventHandler->new( { story   => $self,
                                                                    verbose => $self->{verbose},
                                                                  } );

    $self->{characters}   ||= [];
    $self->{events}       ||= [];
    $self->{event_cursor}   = 0;

    return $self;
}


sub load_story{
    my $self       = shift;
    my $story_file = shift;
    my $logger     = $self->{logger};

    if( ! $story_file ){
        die( "No story file passed to load_story\n" );
    }
    if( ! -f $story_file ){
        die( "Story file ($story_file) does not exist\n" );
    }

    my $details = LoadFile( $story_file );
    if( ! $details ){
        die( "Could not load story from $story_file\n" );
    }

    $self->{characters} = {};
    if( $details->{characters} and ref( $details->{characters} ) eq 'ARRAY' ){
        foreach my $character_hash( @{ $details->{characters} } ){
            my $character = Git::Demo::Story::Character->new( { story    => $self,
                                                                name     => $character_hash->{name},
                                                                git_args => $character_hash->{git_args},
                                                            } );
            $self->{characters}->{$character_hash->{name}} = $character;
        }
    }

    $self->{events} = [];
    if( $details->{events} and ref( $details->{events} ) eq 'ARRAY' ){
        foreach( @{ $details->{events} } ){
            my $event = Git::Demo::Story::Event->new( $_ );
            $logger->debug( "Adding event: " . $event->stringify() );
            push( @{ $self->{events} }, $event );
        }
    }
    $self->{event_cursor} = 0;

    $self->{story_file} = $story_file;
}


sub save_story{
    my $self = shift;
    my $story_file = shift;

    $story_file ||= $self->{story_file};
    if( ! $story_file ){
        die( "No story_file defined to write to" );
    }

    my $details = { characters => $self->{characters} };
    my @events;
    foreach( @{ $self->{events} } ){
        push( @events, $_->to_hash() );
    }
    $details->{events} = \@events;

    DumpFile( $story_file, $details );
}

# Returns the number of events played
sub play{
    my $self = shift;
    my $count = 0;
    while( my $event = $self->next_event() ){
        $count++;
        $self->{event_handler}->exec( $event );
    }
    return $count;
}

# Plays the next event, and returns this event
sub play_next{
    my $self = shift;
    if( my $event = $self->next_event() ){
        $self->{event_handler}->exec( $event );
        return $event;
    }
    return undef;
}

# Returns the next event and increments the event cursor
sub next_event{
    my $self = shift;
    if( defined( $self->{events}->[ $self->{event_cursor} ] ) ){
        return $self->{events}->[ $self->{event_cursor}++ ];
    }
    return undef;
}

# Return all characters
sub characters{
    my $self = shift;
    return $self->{characters};
}

# Return a character by name
sub get_character{
    my $self = shift;
    my $name = shift;
    if( defined( $self->{characters}->{$name} ) ){
        return $self->{characters}->{$name};
    }
    return undef;
}

sub dir{
    my $self = shift;
    return $self->{dir};
}

sub pause{
    my $self = shift;
    if( $self->{no_pause} ){
        return;
    }
    print "Continue?";
    my $in = <STDIN>
}
=head1 AUTHOR

Robin Clarke, C<< <rcl at cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Robin Clarke.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
