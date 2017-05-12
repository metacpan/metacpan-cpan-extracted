package DayDayUp::Notes; # make CPAN happy

use MooseX::Declare;

class DayDayUp::Notes extends DayDayUp::Controller is mutable {
    
    our $VERSION = '0.95';
    
    use DayDayUpX::Note;
    use Search::GIN::Query::Class;

    method index {
        
        my $notes;
        
        my $kioku = $self->app->kioku;
        my $scope = $kioku->new_scope;
        my $all = $kioku->backend->all_entries;
        while( my $chunk = $all->next ){
            entry: for my $id (@$chunk) {
                my $entry = $kioku->lookup($id->id);
                next entry unless blessed $entry && $entry->isa('DayDayUpX::Note');
                $entry->{id} = $id->id; # hack
                push @{ $notes->{ $entry->status} }, $entry;
            }
        }

        # sort by time DESC
        foreach my $key ( keys %$notes ) {
            $notes->{$key}
                = [ sort { $b->time <=> $a->time } @{ $notes->{$key} } ];
        }
        $self->stash->{notes} = $notes;
        $self->render_tt( 'notes/index.html' );
    };
    
    method add {

        unless ( $self->req->method eq 'POST' ) {
            return $self->render_tt( 'notes/add.html' );
        }
        
        my $config = $self->app->config;
        my $params = $self->req->params->to_hash;

        my $note = DayDayUpX::Note->new(
            text   => $params->{text},
            status => 'open',
            time   => time(),
        );
        foreach my $tag ( split(/\s+/, $params->{tags}) ) {
            $note->add_tag( $tag );
        }

        my $kioku = $self->app->kioku;
        my $scope = $kioku->new_scope;
        $kioku->txn_do(sub {
            $kioku->insert($note);
        });

        $self->redirect_tt( '/notes' );
    };
    
    method edit {

        my $captures = $self->match->captures;
        my $id = $captures->{id};
        
        my $kioku = $self->app->kioku;
        my $scope = $kioku->new_scope;
        my $note  = $kioku->lookup($id);

        unless ( $self->req->method eq 'POST' ) {
        	# pre-fulfill
        	$self->stash->{fif} = {
        		text => $note->text,
        	};
            return $self->render_tt( 'notes/add.html' );
        }
        
        my $params = $self->req->params->to_hash;
        
        $note->text( $params->{text} );
        $note->clear_tags;
        foreach my $tag ( split(/\s+/, $params->{tags}) ) {
            $note->add_tag( $tag );
        }
        
        {
            my $scope = $kioku->new_scope;
            $kioku->txn_do(sub {
                $kioku->update($note);
            });
        }

        $self->redirect_tt( '/notes' );
    };
    
    method delete {

        my $captures = $self->match->captures;
        my $id = $captures->{id};
        
        my $kioku = $self->app->kioku;
        my $scope = $kioku->new_scope;
        $kioku->delete($id);

        $self->redirect_tt( '/notes' );
    };
    
    method update {
    	
    	my $captures = $self->match->captures;
        my $id = $captures->{id};
        
        my $params = $self->req->params->to_hash;
        
        my $kioku = $self->app->kioku;
        my $scope = $kioku->new_scope;
        my $note  = $kioku->lookup($id);
        
        my $status = $params->{status};
        if ( $status eq 'closed' or $status eq 'rejected' ) {
            $note->status( $status );
            $note->closed_time( time() );
        } else {
            $note->status( $status );
        }
        
        {
            my $scope = $kioku->new_scope;
            $kioku->txn_do(sub {
                $kioku->update($note);
            });
        }
        
        $self->redirect_tt( '/notes' );
    };
    
    method view_all {

    	my $params = $self->req->params->to_hash;
    	my $status = $params->{status};
        
        my $notes;
        my $kioku = $self->app->kioku;
        my $scope = $kioku->new_scope;
        my $all = $kioku->backend->all_entries;
        while( my $chunk = $all->next ){
            entry: for my $id (@$chunk) {
                my $entry = $kioku->lookup($id->id);
                next entry unless blessed $entry && $entry->isa('DayDayUpX::Note');
                $entry->{id} = $id->id; # hack
                push @{ $notes }, $entry if $entry->status eq $status;
            }
        }

        $self->stash( {
    		notes => { $status => $notes },
    		is_in_view_all_page => 1,
    		status => $status,
    	} );
    	$self->render_tt( 'notes/index.html' );
    }
};

1;
