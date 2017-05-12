package Games::Lacuna::Task::Report::Inbox;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose::Role;

has 'archive' => (
    is              => 'rw',
    isa             => 'RegexpRef',
    documentation   => 'Message subjects matching this pattern will be archived',
    default         => sub { 
        qr/^ ( 
            Trade \s Accepted |
            Mission \s completed
        ) $/x;
    },
);

has 'delete' => (
    is              => 'rw',
    isa             => 'RegexpRef',
    documentation   => 'Message subjects matching this pattern will be deleted',
    default         => sub { 
        qr/^ ( 
            Target \s Neutralized | 
            Glyph \s Discovered! | 
            Control \s Changed \s Hands | 
            Mining \s Platform \s Deployed | 
            Probe \s Detected! |
            Trade \s Withdrawn |
            Excavator \s Results |
            Excavator \s Deployed |
            Excavator \s Uncovered \s Plan
        ) $/x;
    },
);

sub report_inbox {
    my ($self) = @_;
    
    my $inbox_object = $self->build_object('Inbox');
    my $has_new_messages = $self->get_stash('has_new_messages');
    
    my $page = int($has_new_messages / 25 ) + ( $has_new_messages % 25 ? 1:0);
    $page //= 1;
    
    my (@archive,@delete,%counter,%action);
    
    PAGES:
    while ($page > 0) {
        # Get inbox for attacks
        my $inbox_data = $self->request(
            object  => $inbox_object,
            method  => 'view_inbox',
            params  => [ { page_number => $page } ],
        );
        
        
        MESSAGES:
        foreach my $message (@{$inbox_data->{messages}}) {
            next MESSAGES
                unless $message->{from_id} == $message->{to_id};
            my $subject = $message->{subject};
            
            if ($subject =~ $self->delete) {
                push(@delete,$message->{id});
                $action{$subject} = 'delete';
            } elsif ($subject =~ $self->archive) {
                push(@archive,$message->{id});
                $action{$subject} = 'archive';
            } else {
                next MESSAGES
                    if $message->{has_read};
                $action{$subject} = 'keep';
            }
            
            $counter{$subject} ||= 0;
            $counter{$subject} ++;
        }
        
        $page --;
    }
    
    my $empire_name = $self->empire_name;
    
    my $table = Games::Lacuna::Task::Table->new(
        headline=> 'Inbox Digest',
        columns => ['Subject','Count','Action'],
    );
    while (my ($subject,$count) = each %counter) {
        $table->add_row({
            subject => $subject,
            count   => $count,
            action  => $action{$subject},
        });
    }
    
    if (scalar @archive) {
        $self->log('debug','Archiveing %i messages',(scalar @archive));
        
        $self->request(
            object  => $inbox_object,
            method  => 'archive_messages',
            params  => [\@archive],
        );
    }
    
    if (scalar @delete) {
        $self->log('debug','Deleting %i messages',(scalar @delete));
        
        $self->request(
            object  => $inbox_object,
            method  => 'trash_messages',
            params  => [\@delete],
        );
    }
    
    return $table;
}

no Moose::Role;
1;