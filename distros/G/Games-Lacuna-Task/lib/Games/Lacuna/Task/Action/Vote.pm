package Games::Lacuna::Task::Action::Vote;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose;
extends qw(Games::Lacuna::Task::Action);

our $BUILDING_COORDINATES_RE = qr/\(-?\d+,-?\d+\)/;
our $NAME_RE = qr/[[:space:][:alnum:]]+/;

has 'accept_proposition' => (
    isa             => 'RegexpRef',
    is              => 'rw',
    required        => 1,
    documentation   => 'Propositions matching this regexp should accepted',
    default         => sub { qr/^( 
        (Upgrade|Install) \s $NAME_RE
        |
        Demolish \s (Dent|Bleeder)
        |
        Rename \s $NAME_RE
        |
        Repair \s $NAME_RE
        |
        Seize \s $NAME_RE
        |
        Transfer \s Station
    )/xi },
);

has 'reject_proposition' => (
    isa             => 'RegexpRef',
    is              => 'rw',
    required        => 1,
    documentation   => 'Propositions matching this regexp should be rejected',
    default         => sub { qr//xi },
);

sub description {
    return q[Parliament voting based on rules];
}

sub run {
    my ($self) = @_;
    
    PLANETS:
    foreach my $body_stats ($self->my_stations) {
        $self->log('info',"Processing space station %s",$body_stats->{name});
        $self->process_space_station($body_stats);
    }
    
    my $inbox_object = $self->build_object('Inbox');
    
    my @trash_messages;
    my $page_number = 1;
    while (1) {
        # Get inbox for parliament
        my $inbox_data = $self->request(
            object  => $inbox_object,
            method  => 'view_inbox',
            params  => [{ tags => ['Parliament'],page_number => $page_number }],
        );
        
        MESSAGES:
        foreach my $message (@{$inbox_data->{messages}}) {
            if ($message->{subject} =~ m/^(Pass|Reject):\s+/
                || $message->{subject} =~ $self->accept_proposition
                || $message->{subject} =~ $self->reject_proposition) {
                push(@trash_messages,$message->{id});
            }
        }
        
        last
            if scalar(@{$inbox_data->{messages}}) < 25;
        
        $page_number++;
    }
    
    # Archive
    if (scalar @trash_messages) {
        $self->log('notice',"Trashing %i messages",scalar @trash_messages);
        
        $self->request(
            object  => $inbox_object,
            method  => 'trash_messages',
            params  => [\@trash_messages],
        );
    }
}

sub process_space_station {
    my ($self,$station_stats) = @_;
    
    # Get parliament ministry
    my ($parliament) = $self->find_building($station_stats->{id},'Parliament');
    return
        unless $parliament;
    my $parliament_object = $self->build_object($parliament);
    
    my $proposition_data = $self->request(
        object  => $parliament_object,
        method  => 'view_propositions',
    );
    
    PROPOSITION:
    foreach my $proposition (@{$proposition_data->{propositions}}) {
        next PROPOSITION
            if defined $proposition->{my_vote};
        
        my $vote;
        
        if ($proposition->{name} =~ $self->accept_proposition) {
            $vote = 1;
        } elsif ($proposition->{name} =~ $self->reject_proposition) {
            $vote = 0;
        } else {
            next PROPOSITION;
        }
        
        $self->log('notice','Voting %s on proposition %s',($vote ? 'Yes':'No'),$proposition->{name});
        
        $self->request(
            object  => $parliament_object,
            method  => 'cast_vote',
            params  => [$proposition->{id},$vote],
        );
    
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
