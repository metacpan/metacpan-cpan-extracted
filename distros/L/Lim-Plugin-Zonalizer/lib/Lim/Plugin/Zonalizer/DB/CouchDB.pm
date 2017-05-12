package Lim::Plugin::Zonalizer::DB::CouchDB;

use utf8;
use common::sense;

use Carp;
use Scalar::Util qw(weaken blessed);

use Lim               ();
use AnyEvent::CouchDB ();
use Lim::Plugin::Zonalizer qw(:err);
use URI::Escape::XS qw(uri_escape);
use JSON ();
use Clone qw(clone);

use base qw(Lim::Plugin::Zonalizer::DB);

our %VALID_ORDER_FIELD = ( analysis => { fqdn => 0, map { $_ => 1 } ( qw(created updated) ) } );
our $ID_DELIMITER = ':';

=encoding utf8

=head1 NAME

Lim::Plugin::Zonalizer::DB::CouchDB - The CouchDB database for Zonalizer

=head1 METHODS

=over 4

=item Init

=cut

sub Init {
    my ( $self, %args ) = @_;

    $self->{delete_batch} = 100;

    foreach ( qw(uri) ) {
        unless ( defined $args{$_} ) {
            confess 'configuration: ' . $_ . ' is not defined';
        }
    }

    foreach ( qw(delete_batch) ) {
        if ( defined $args{$_} ) {
            $self->{$_} = $args{$_};
        }
    }

    $self->{db} = AnyEvent::CouchDB::couchdb( $args{uri} );
    return;
}

=item Destroy

=cut

sub Destroy {
}

=item Name

=cut

sub Name {
    return 'CouchDB';
}

=item $db->ReadAnalysis

=cut

sub ReadAnalysis {
    my ( $self, %args ) = @_;
    my $real_self = $self;
    weaken( $self );

    unless ( ref( $args{cb} ) eq 'CODE' ) {
        confess 'cb is not CODE';
    }
    undef $@;

    my $limit = defined $args{limit} ? $args{limit} : 0;
    if ( $limit == 0 ) {
        $args{cb}->();
        return;
    }
    unless ( $limit > 0 ) {
        $@ = ERR_INVALID_LIMIT;
        $args{cb}->();
        return;
    }

    my $search_fqdn;
    my $search_fqdn2;
    if ( defined $args{search} ) {
        if ( $args{search} =~ /^\../o ) {
            $search_fqdn2 = $args{search};
            $search_fqdn2 =~ s/^\.//o;
            $search_fqdn2 =~ s/\.$//o;
            $search_fqdn2 = join( '.', reverse( split( /\./o, $search_fqdn2 ) ) );
        }
        else {
            $search_fqdn = $args{search};
            unless ( $search_fqdn =~ /\.$/o ) {
                $search_fqdn .= '.';
            }
        }
    }

    my $view   = '';
    my %option = (
        include_docs => 1,
        limit        => $limit
    );
    my $ignore_paging = 0;
    my $reverse       = 0;

    if ( defined $args{sort} ) {
        if ( $args{direction} eq 'descending' ) {
            $option{descending} = 1;
        }
    }

    if ( defined $search_fqdn or defined $search_fqdn2 ) {
        if ( defined $args{after} ) {
            $option{startkey} = [ $args{space} ? $args{space} : '', [ defined $search_fqdn ? $search_fqdn : $search_fqdn2, undef ] ];
            $option{endkey} = [ $args{space} ? $args{space} : '', [ defined $search_fqdn ? $search_fqdn : $search_fqdn2, $option{descending} ? () : ( {} ) ] ];
        }
        elsif ( defined $args{before} ) {
            $reverse = 1;
            $option{startkey} = [ $args{space} ? $args{space} : '', [ defined $search_fqdn ? $search_fqdn : $search_fqdn2, undef ] ];
            $option{endkey} = [ $args{space} ? $args{space} : '', [ defined $search_fqdn ? $search_fqdn : $search_fqdn2, $option{descending} ? ( {} ) : () ] ];
        }
        else {
            $option{startkey} = [ $args{space} ? $args{space} : '', [ defined $search_fqdn ? $search_fqdn : $search_fqdn2, $option{descending} ? ( {} ) : () ] ];
            $option{endkey} = [ $args{space} ? $args{space} : '', [ defined $search_fqdn ? $search_fqdn : $search_fqdn2, $option{descending} ? () : ( {} ) ] ];
        }
    }

    if ( defined $search_fqdn ) {
        $view = 'fqdn';
    }
    elsif ( defined $search_fqdn2 ) {
        $view = 'rfqdn';
    }

    if ( defined $args{sort} ) {
        unless ( exists $VALID_ORDER_FIELD{analysis}->{ $args{sort} } ) {
            $@ = ERR_INVALID_SORT_FIELD;
            $args{cb}->();
            return;
        }

        my $startkey;

        if ( defined $args{after} ) {
            $startkey = [ split( /$ID_DELIMITER/o, $args{after} ), !$option{descending} ? ( {} ) : () ];
            unless ( scalar @{$startkey} == 2 + ( !$option{descending} ? 1 : 0 ) ) {
                $@ = ERR_INVALID_AFTER;
                $args{cb}->();
                return;
            }

            # uncoverable branch false
            if ( $VALID_ORDER_FIELD{analysis}->{ $args{sort} } == 1 ) {
                $startkey->[0] = $startkey->[0] + 0;
            }
        }
        elsif ( defined $args{before} ) {
            $reverse = 1;
            $startkey = [ split( /$ID_DELIMITER/o, $args{before} ), $option{descending} ? ( {} ) : () ];
            unless ( scalar @{$startkey} == 2 + ( $option{descending} ? 1 : 0 ) ) {
                $@ = ERR_INVALID_BEFORE;
                $args{cb}->();
                return;
            }

            # uncoverable branch false
            if ( $VALID_ORDER_FIELD{analysis}->{ $args{sort} } == 1 ) {
                $startkey->[0] = $startkey->[0] + 0;
            }
        }

        if ( $startkey ) {
            unless ( $option{startkey} ) {
                $option{startkey} = [ $args{space} ? $args{space} : '' ];
            }
            push( @{ $option{startkey} }, @$startkey );
        }

        $view = ( $view ? $view . '_' : '' ) . 'by_' . $args{sort};
    }
    else {
        my $startkey;

        if ( defined $args{after} ) {
            $startkey = [ $args{space} ? $args{space} : '', $args{after}, {} ];
        }
        elsif ( defined $args{before} ) {
            $reverse = 1;
            $startkey = [ $args{space} ? $args{space} : '', $args{before} ];
        }

        if ( $startkey ) {
            push( @{ $option{startkey} }, @$startkey );
        }

        unless ( $view ) {
            $view = 'all';
        }
    }

    if ( $reverse ) {
        if ( $option{descending} ) {
            delete $option{descending};
        }
        else {
            $option{descending} = 1;
        }
    }

    unless ( $option{startkey} ) {
        $option{startkey} = [ $args{space} ? $args{space} : '', $option{descending} ? ( {} ) : () ];
    }
    unless ( $option{endkey} ) {
        $option{endkey} = [ $args{space} ? $args{space} : '', $option{descending} ? () : ( {} ) ];
    }

    # uncoverable branch false
    Lim::DEBUG and $self->{logger}->debug( 'couchdb analysis/', $view, $args{space} ? ' ' . $args{space} : '' );
    $self->{db}->view( 'analysis/' . $view, \%option )->cb(
        sub {
            # uncoverable branch true
            unless ( defined $self ) {

                # uncoverable statement
                return;
            }

            my ( $before, $after, $previous, $next, $rows, $total_rows, $offset );
            eval { ( $before, $after, $previous, $next, $rows, $total_rows, $offset ) = $self->HandleResponse( $_[0], $reverse, 1 ); };
            if ( $@ ) {

                # uncoverable branch false
                Lim::ERR and $self->{logger}->error( 'CouchDB error: ', $@ );
                $@ = ERR_INTERNAL_DATABASE;
                $args{cb}->();
                return;
            }

            unless ( $offset ) {
                $previous = 0;
            }

            my $extra = '';
            if ( defined $search_fqdn ) {
                $extra .= ( $extra ? '&' : '' ) . 'search=' . uri_escape( $search_fqdn );
            }
            if ( defined $search_fqdn2 ) {
                $extra .= ( $extra ? '&' : '' ) . 'search=' . uri_escape( '.' . $search_fqdn2 );
            }
            if ( $args{space} ) {
                $extra .= ( $extra ? '&' : '' ) . 'space=' . uri_escape( $args{space} );
            }

            my $code = sub {
                $args{cb}->(
                    ( $previous || $next ) && !$ignore_paging
                    ? {
                        before   => $before,
                        after    => $after,
                        previous => $previous,
                        next     => $next,
                        $extra ? ( extra => $extra ) : ()
                      }
                    : undef,
                    @$rows
                );
            };

            unless ( scalar @$rows ) {
                $ignore_paging = 1;
                $code->();
                return;
            }

            #
            # We need to swap after/before since we are using a descending
            # view to do reverse lookup
            #
            if ( $reverse ) {
                my $a = $after;
                my $b = $before;
                $before = $a;
                $after  = $b;
            }

            # TODO: Can this be solved in a better way then fetching previous/next with skip?

            $option{limit} = 1;
            delete $option{startkey};
            delete $option{endkey};
            delete $option{include_docs};

            my $code_next = sub {
                unless ( $next ) {
                    $code->();
                    return;
                }

                if ( $reverse ) {

                    # uncoverable branch false
                    Lim::DEBUG and $self->{logger}->debug( 'couchdb analysis/', $view, ' next check (reverse), skip ', $offset - 1 );
                    $option{skip} = $offset - 1;
                }
                else {
                    # uncoverable branch false
                    Lim::DEBUG and $self->{logger}->debug( 'couchdb analysis/', $view, ' next check, skip ', $offset + scalar @$rows );
                    $option{skip} = $offset + scalar @$rows;
                }
                $self->{db}->view( 'analysis/' . $view, \%option )->cb(
                    sub {
                        # uncoverable branch true
                        unless ( defined $self ) {

                            # uncoverable statement
                            return;
                        }

                        my ( $keys );
                        eval {
                            $keys = $self->HandleResponseKey( $_[0] );

                            unless ( ref( $keys->[0] ) eq 'ARRAY' ) {
                                die 'invalid schema';
                            }
                            if ( defined $search_fqdn or defined $search_fqdn2 ) {
                                unless ( ref( $keys->[0]->[1] ) eq 'ARRAY' ) {
                                    die 'invalid schema';
                                }
                            }
                        };
                        if ( $@ ) {

                            # uncoverable branch false
                            Lim::ERR and $self->{logger}->error( 'CouchDB error: ', $@ );
                            $@ = ERR_INTERNAL_DATABASE;
                            $args{cb}->();
                            return;
                        }

                        if ( defined $search_fqdn and $keys->[0]->[1]->[0] ne $search_fqdn ) {
                            $next = 0;
                        }
                        elsif ( defined $search_fqdn2 and $keys->[0]->[1]->[0] ne $search_fqdn2 ) {
                            $next = 0;
                        }

                        if ( $args{space} ) {
                            unless ( $keys->[0]->[0] eq $args{space} ) {
                                $next = 0;
                            }
                        }
                        elsif ( $keys->[0]->[0] ne '' ) {
                            $next = 0;
                        }

                        $code->();
                    }
                );
            };

            unless ( $previous ) {
                $code_next->();
                return;
            }

            if ( $reverse ) {

                # uncoverable branch false
                Lim::DEBUG and $self->{logger}->debug( 'couchdb analysis/', $view, ' previous check (reverse), skip ', $offset + scalar @$rows );
                $option{skip} = $offset + scalar @$rows;
            }
            else {
                # uncoverable branch false
                Lim::DEBUG and $self->{logger}->debug( 'couchdb analysis/', $view, ' previous check, skip ', $offset - 1 );
                $option{skip} = $offset - 1;
            }
            $self->{db}->view( 'analysis/' . $view, \%option )->cb(
                sub {
                    # uncoverable branch true
                    unless ( defined $self ) {

                        # uncoverable statement
                        return;
                    }

                    my ( $keys );
                    eval {
                        $keys = $self->HandleResponseKey( $_[0] );

                        unless ( ref( $keys->[0] ) eq 'ARRAY' ) {
                            die 'invalid schema';
                        }
                        if ( defined $search_fqdn or defined $search_fqdn2 ) {
                            unless ( ref( $keys->[0]->[1] ) eq 'ARRAY' ) {
                                die 'invalid schema';
                            }
                        }
                    };
                    if ( $@ ) {

                        # uncoverable branch false
                        Lim::ERR and $self->{logger}->error( 'CouchDB error: ', $@ );
                        $@ = ERR_INTERNAL_DATABASE;
                        $args{cb}->();
                        return;
                    }

                    if ( defined $search_fqdn and $keys->[0]->[1]->[0] ne $search_fqdn ) {
                        $previous = 0;
                    }
                    elsif ( defined $search_fqdn2 and $keys->[0]->[1]->[0] ne $search_fqdn2 ) {
                        $previous = 0;
                    }

                    if ( $args{space} ) {
                        unless ( $keys->[0]->[0] eq $args{space} ) {
                            $previous = 0;
                        }
                    }
                    elsif ( $keys->[0]->[0] ne '' ) {
                        $previous = 0;
                    }

                    $code_next->();
                }
            );
        }
    );
    return;
}

=item DeleteAnalysis

=over 4

=item cb => sub { my ($deleted_analysis) = @_; ... }

$@ on error

=back

=cut

sub DeleteAnalysis {
    my ( $self, %args ) = @_;
    my $real_self = $self;
    weaken( $self );

    unless ( ref( $args{cb} ) eq 'CODE' ) {
        confess 'cb is not CODE';
    }
    undef $@;

    my ( $deleted_analysis ) = ( 0 );
    my $analysis;
    $analysis = sub {

        # uncoverable branch false
        Lim::DEBUG and $self->{logger}->debug( 'couchdb analysis/all', $args{space} ? ' ' . $args{space} : '' );
        $self->{db}->view(
            'analysis/all',
            {
                $args{space}
                ? (
                    startkey => [ $args{space}, undef ],
                    endkey => [ $args{space}, {} ]
                  )
                : (),
                limit        => $self->{delete_batch},
                include_docs => 1
            }
          )->cb(
            sub {
                # uncoverable branch true
                unless ( defined $self ) {

                    # uncoverable statement
                    return;
                }

                my $rows;
                eval { $rows = $self->HandleResponseIdRev( $_[0] ); };
                if ( $@ ) {

                    # uncoverable branch false
                    Lim::ERR and $self->{logger}->error( 'CouchDB error: ', $@ );
                    $@ = ERR_INTERNAL_DATABASE;
                    $args{cb}->( $deleted_analysis );
                    return;
                }

                unless ( scalar @$rows ) {
                    $args{cb}->( $deleted_analysis );
                    return;
                }

                foreach ( @$rows ) {
                    $_->{_deleted} = JSON::true;
                }

                # uncoverable branch false
                Lim::DEBUG and $self->{logger}->debug( 'couchdb bulk_docs analysis' );
                $self->{db}->bulk_docs( $rows )->cb(
                    sub {
                        my ( $cv ) = @_;

                        # uncoverable branch true
                        unless ( defined $self ) {

                            # uncoverable statement
                            return;
                        }

                        eval { $cv->recv; };
                        if ( $@ ) {

                            # uncoverable branch false
                            Lim::ERR and $self->{logger}->error( 'CouchDB error: ', $@ );
                            $@ = ERR_INTERNAL_DATABASE;
                            $args{cb}->( $deleted_analysis );
                            return;
                        }

                        $deleted_analysis += scalar @$rows;
                        $analysis->();
                    }
                );
            }
          );
    };
    $analysis->();
    return;
}

=item CreateAnalyze

=cut

sub CreateAnalyze {
    my ( $self, %args ) = @_;
    my $real_self = $self;
    weaken( $self );

    unless ( ref( $args{cb} ) eq 'CODE' ) {
        confess 'cb is not CODE';
    }
    $self->ValidateAnalyze( $args{analyze} );
    undef $@;

    if ( exists $args{analyze}->{_id} or exists $args{analyze}->{_rev} ) {

        # uncoverable branch false
        Lim::ERR and $self->{logger}->error( 'CouchDB specific fields _id/_rev existed during create' );
        $@ = ERR_INTERNAL_DATABASE;
        $args{cb}->();
        return;
    }

    my %analyze = (
        %{ clone $args{analyze} },
        type => 'new_analyze',
        space => $args{space} ? $args{space} : ''
    );

    # uncoverable branch false
    Lim::DEBUG and $self->{logger}->debug( 'couchdb save_doc new_analyze' );
    $self->{db}->save_doc( \%analyze )->cb(
        sub {
            my ( $cv ) = @_;

            # uncoverable branch true
            unless ( defined $self ) {

                # uncoverable statement
                return;
            }

            eval { $cv->recv; };
            if ( $@ ) {

                # uncoverable branch false
                Lim::ERR and $self->{logger}->error( 'CouchDB error: ', $@ );
                $@ = ERR_INTERNAL_DATABASE;
                $args{cb}->();
                return;
            }

            # uncoverable branch false
            Lim::DEBUG and $self->{logger}->debug( 'couchdb new_analysis/all ', $analyze{id}, $args{space} ? ' ' . $args{space} : '' );
            $self->{db}->view(
                'new_analysis/all',
                {
                    key => [
                        $args{space} ? $args{space} : '',
                        $analyze{id}
                    ]
                }
              )->cb(
                sub {
                    # uncoverable branch true
                    unless ( defined $self ) {

                        # uncoverable statement
                        return;
                    }

                    my $rows;
                    eval { $rows = $self->HandleResponseId( $_[0] ); };
                    if ( $@ ) {

                        # uncoverable branch false
                        Lim::ERR and $self->{logger}->error( 'CouchDB error: ', $@ );
                        $@ = ERR_INTERNAL_DATABASE;
                        $args{cb}->();
                        return;
                    }
                    unless ( scalar @$rows ) {
                        $self->{db}->remove_doc( \%analyze )->cb(
                            sub {
                                eval { $_[0]->recv; };

                                # uncoverable branch true
                                unless ( defined $self ) {

                                    # uncoverable statement
                                    return;
                                }

                                # uncoverable branch false
                                Lim::ERR and $self->{logger}->error( 'CouchDB error: ', $@ );
                            }
                        );

                        # uncoverable branch false
                        Lim::ERR and $self->{logger}->error( 'CouchDB error: created analyze but was not returned' );
                        $@ = ERR_INTERNAL_DATABASE;
                        $args{cb}->();
                        return;
                    }
                    unless ( scalar @$rows == 1 ) {
                        $self->{db}->remove_doc( \%analyze )->cb(
                            sub {
                                eval { $_[0]->recv; };

                                # uncoverable branch true
                                unless ( defined $self ) {

                                    # uncoverable statement
                                    return;
                                }

                                # uncoverable branch false
                                Lim::ERR and $self->{logger}->error( 'CouchDB error: ', $@ );
                            }
                        );
                        $@ = ERR_DUPLICATE_ID;
                        $args{cb}->();
                        return;
                    }

                    $analyze{type} = 'analyze';

                    # uncoverable branch false
                    Lim::DEBUG and $self->{logger}->debug( 'couchdb save_doc analyze' );
                    $self->{db}->save_doc( \%analyze )->cb(
                        sub {
                            my ( $cv ) = @_;

                            # uncoverable branch true
                            unless ( defined $self ) {

                                # uncoverable statement
                                return;
                            }

                            eval { $cv->recv; };
                            if ( $@ ) {
                                $self->{db}->remove_doc( \%analyze )->cb(
                                    sub {
                                        eval { $_[0]->recv; };

                                        # uncoverable branch true
                                        unless ( defined $self ) {

                                            # uncoverable statement
                                            return;
                                        }

                                        # uncoverable branch false
                                        Lim::ERR and $self->{logger}->error( 'CouchDB error: ', $@ );
                                    }
                                );

                                # uncoverable branch false
                                Lim::ERR and $self->{logger}->error( 'CouchDB error: ', $@ );
                                $@ = ERR_INTERNAL_DATABASE;
                                $args{cb}->();
                                return;
                            }

                            $args{cb}->( \%analyze );
                        }
                    );
                }
              );
        }
    );
    return;
}

=item ReadAnalyze

=cut

sub ReadAnalyze {
    my ( $self, %args ) = @_;
    my $real_self = $self;
    weaken( $self );

    unless ( ref( $args{cb} ) eq 'CODE' ) {
        confess 'cb is not CODE';
    }
    unless ( defined $args{id} ) {
        confess 'id is not defined';
    }
    undef $@;

    # uncoverable branch false
    Lim::DEBUG and $self->{logger}->debug( 'couchdb analysis/all ', $args{id}, $args{space} ? ' ' . $args{space} : '' );
    $self->{db}->view(
        'analysis/all',
        {
            key => [
                $args{space} ? $args{space} : '',
                $args{id},
                undef
            ],
            include_docs => 1
        }
      )->cb(
        sub {
            # uncoverable branch true
            unless ( defined $self ) {

                # uncoverable statement
                return;
            }

            my $rows;
            eval { $rows = $self->HandleResponse( $_[0], 0, 1 ); };
            if ( $@ ) {

                # uncoverable branch false
                Lim::ERR and $self->{logger}->error( 'CouchDB error: ', $@ );
                $@ = ERR_INTERNAL_DATABASE;
                $args{cb}->();
                return;
            }
            unless ( scalar @$rows ) {
                $@ = ERR_ID_NOT_FOUND;
                $args{cb}->();
                return;
            }
            if ( scalar @$rows > 1 ) {

                # uncoverable branch false
                Lim::ERR and $self->{logger}->error( 'CouchDB error: too many rows returned' );
                $@ = ERR_INTERNAL_DATABASE;
                $args{cb}->();
                return;
            }

            $args{cb}->( $rows->[0] );
        }
      );
    return;
}

=item UpdateAnalyze

=cut

sub UpdateAnalyze {
    my ( $self, %args ) = @_;
    my $real_self = $self;
    weaken( $self );

    unless ( ref( $args{cb} ) eq 'CODE' ) {
        confess 'cb is not CODE';
    }
    $self->ValidateAnalyze( $args{analyze} );
    undef $@;

    unless ( defined $args{analyze}->{_id} ) {

        # uncoverable branch false
        Lim::ERR and $self->{logger}->error( 'CouchDB specific _id is missing' );
        $@ = ERR_ID_NOT_FOUND;
        $args{cb}->();
        return;
    }
    unless ( defined $args{analyze}->{_rev} ) {

        # uncoverable branch false
        Lim::ERR and $self->{logger}->error( 'CouchDB specific _rev is missing' );
        $@ = ERR_REVISION_MISSMATCH;
        $args{cb}->();
        return;
    }
    unless ( defined $args{analyze}->{space} ) {

        # uncoverable branch false
        Lim::ERR and $self->{logger}->error( 'CouchDB specific space is missing' );
        $@ = ERR_SPACE_MISSMATCH;
        $args{cb}->();
        return;
    }
    if ( defined $args{space} and $args{space} ne $args{analyze}->{space} ) {
        $@ = ERR_SPACE_MISSMATCH;
        $args{cb}->();
        return;
    }
    if ( !defined $args{space} and $args{analyze}->{space} ne '' ) {
        $@ = ERR_SPACE_MISSMATCH;
        $args{cb}->();
        return;
    }

    # uncoverable branch false
    Lim::DEBUG and $self->{logger}->debug( 'couchdb save_doc analyze' );
    my $analyze = clone $args{analyze};
    $self->{db}->save_doc( $analyze )->cb(
        sub {
            my ( $cv ) = @_;

            # uncoverable branch true
            unless ( defined $self ) {

                # uncoverable statement
                return;
            }

            eval { $cv->recv; };
            if ( $@ ) {

                # uncoverable branch false
                Lim::ERR and $self->{logger}->error( 'CouchDB error: ', $@ );
                $@ = ERR_INTERNAL_DATABASE;
                $args{cb}->();
                return;
            }

            $args{cb}->( $analyze );
        }
    );
    return;
}

=item DeleteAnalyze

=cut

sub DeleteAnalyze {
    my ( $self, %args ) = @_;
    my $real_self = $self;
    weaken( $self );

    unless ( ref( $args{cb} ) eq 'CODE' ) {
        confess 'cb is not CODE';
    }
    unless ( defined $args{id} ) {
        confess 'id is not defined';
    }
    undef $@;

    # uncoverable branch false
    Lim::DEBUG and $self->{logger}->debug( 'couchdb analysis/all ', $args{id}, $args{space} ? ' ' . $args{space} : '' );
    $self->{db}->view(
        'analysis/all',
        {
            key => [
                $args{space} ? $args{space} : '',
                $args{id},
                undef
            ],
            include_docs => 1
        }
      )->cb(
        sub {
            # uncoverable branch true
            unless ( defined $self ) {

                # uncoverable statement
                return;
            }

            my $rows;
            eval { $rows = $self->HandleResponse( $_[0] ); };
            if ( $@ ) {

                # uncoverable branch false
                Lim::ERR and $self->{logger}->error( 'CouchDB error: ', $@ );
                $@ = ERR_INTERNAL_DATABASE;
                $args{cb}->();
                return;
            }
            unless ( scalar @$rows ) {
                $@ = ERR_ID_NOT_FOUND;
                $args{cb}->();
                return;
            }
            if ( scalar @$rows > 1 ) {

                # uncoverable branch false
                Lim::ERR and $self->{logger}->error( 'CouchDB error: too many rows returned' );
                $@ = ERR_INTERNAL_DATABASE;
                $args{cb}->();
                return;
            }

            $rows->[0]->{_deleted} = JSON::true;

            # uncoverable branch false
            Lim::DEBUG and $self->{logger}->debug( 'couchdb save_doc ', $args{id} );
            $self->{db}->save_doc( $rows->[0] )->cb(
                sub {
                    my ( $cv ) = @_;

                    # uncoverable branch true
                    unless ( defined $self ) {

                        # uncoverable statement
                        return;
                    }

                    eval { $cv->recv; };
                    if ( blessed $@ and $@->can( 'headers' ) and ref( $@->headers ) eq 'HASH' and $@->headers->{Status} == 200 and $@->headers->{Reason} eq 'OK' ) {
                        undef $@;
                    }
                    if ( $@ ) {

                        # uncoverable branch false
                        Lim::ERR and $self->{logger}->error( 'CouchDB error: ', $@ );
                        $@ = ERR_INTERNAL_DATABASE;
                    }

                    $args{cb}->();
                }
            );
        }
      );
    return;
}

=back

=head1 PRIVATE METHODS

=over 4

=item HandleResponse

=cut

sub HandleResponse {
    my ( $self, $cv, $reverse, $keyskip ) = @_;

    unless ( blessed $cv and $cv->can( 'recv' ) ) {
        die 'cv is not object';
    }

    my $data = $cv->recv;

    unless ( ref( $data ) eq 'HASH' ) {
        die 'data is not HASH';
    }
    foreach ( qw(offset total_rows rows) ) {
        unless ( defined $data->{$_} ) {
            die 'data->' . $_ . ' is not defined';
        }
    }
    unless ( ref( $data->{rows} ) eq 'ARRAY' ) {
        die 'data->rows is not ARRAY';
    }

    my ( $before, $after, $previous, $next, @rows ) = ( undef, undef, 0, 0 );

    foreach ( @{ $data->{rows} } ) {
        unless ( ref( $_ ) eq 'HASH' ) {
            die 'data->rows[] entry is not HASH';
        }
        unless ( ref( $_->{key} ) eq 'ARRAY' ) {
            die 'data->rows[]->key is not ARRAY';
        }
        unless ( ref( $_->{doc} ) eq 'HASH' ) {
            die 'data->rows[]->doc is not HASH';
        }
        push( @rows, $_->{doc} );
    }

    unless ( wantarray ) {
        return \@rows;
    }

    if ( $reverse ) {
        @rows = reverse @rows;

        if ( $data->{offset} > 0 ) {
            $next = 1;
        }
        if ( ( $data->{total_rows} - $data->{offset} - scalar @rows ) > 0 ) {
            $previous = 1;
        }
    }
    else {
        if ( $data->{offset} > 0 ) {
            $previous = 1;
        }
        if ( ( $data->{total_rows} - $data->{offset} - scalar @rows ) > 0 ) {
            $next = 1;
        }
    }

    if ( $keyskip ) {
        my ( $skip, @key );

        @key = grep { defined $_ && !ref( $_ ) } @{ $data->{rows}->[0]->{key} };
        $skip = $keyskip;
        while ( $skip-- ) {
            shift( @key );
        }
        $before = join( $ID_DELIMITER, @key );

        @key = grep { defined $_ && !ref( $_ ) } @{ $data->{rows}->[-1]->{key} };
        $skip = $keyskip;
        while ( $skip-- ) {
            shift( @key );
        }
        $after = join( $ID_DELIMITER, @key );
    }
    else {
        $before = join( $ID_DELIMITER, grep { defined $_ && !ref( $_ ) } @{ $data->{rows}->[0]->{key} } );
        $after  = join( $ID_DELIMITER, grep { defined $_ && !ref( $_ ) } @{ $data->{rows}->[-1]->{key} } );
    }

    return ( $before, $after, $previous, $next, \@rows, $data->{total_rows}, $data->{offset} );
}

=item HandleResponseKey

=cut

sub HandleResponseKey {
    my ( $self, $cv ) = @_;

    unless ( blessed $cv and $cv->can( 'recv' ) ) {
        die 'cv is not object';
    }

    my $data = $cv->recv;

    unless ( ref( $data ) eq 'HASH' ) {
        die 'data is not HASH';
    }
    foreach ( qw(rows) ) {
        unless ( defined $data->{$_} ) {
            die 'data->' . $_ . ' is not defined';
        }
    }
    unless ( ref( $data->{rows} ) eq 'ARRAY' ) {
        die 'data->rows is not ARRAY';
    }

    my @rows;

    foreach ( @{ $data->{rows} } ) {
        unless ( ref( $_ ) eq 'HASH' ) {
            die 'data->rows[] entry is not HASH';
        }
        if ( exists $_->{doc} ) {
            unless ( ref( $_->{doc} ) eq 'HASH' ) {
                die 'data->rows[]->doc is not HASH';
            }
            push( @rows, $_->{doc} );
        }
        elsif ( ref( $_->{key} ) eq 'ARRAY' ) {
            push( @rows, [ grep { defined $_ } @{ $_->{key} } ] );
        }
        else {
            push( @rows, $_->{key} );
        }
    }

    return \@rows;
}

=item HandleResponseId

=cut

sub HandleResponseId {
    my ( $self, $cv ) = @_;

    unless ( blessed $cv and $cv->can( 'recv' ) ) {
        die 'cv is not object';
    }

    my $data = $cv->recv;

    unless ( ref( $data ) eq 'HASH' ) {
        die 'data is not HASH';
    }
    foreach ( qw(rows) ) {
        unless ( defined $data->{$_} ) {
            die 'data->' . $_ . ' is not defined';
        }
    }
    unless ( ref( $data->{rows} ) eq 'ARRAY' ) {
        die 'data->rows is not ARRAY';
    }

    my @rows;

    foreach ( @{ $data->{rows} } ) {
        unless ( ref( $_ ) eq 'HASH' ) {
            die 'data->rows[] entry is not HASH';
        }
        unless ( defined $_->{id} ) {
            die 'data->rows[]->id is not defined';
        }
        push( @rows, $_->{id} );
    }

    return \@rows;
}

=item HandleResponseIdRev

=cut

sub HandleResponseIdRev {
    my ( $self, $cv ) = @_;

    unless ( blessed $cv and $cv->can( 'recv' ) ) {
        die 'cv is not object';
    }

    my $data = $cv->recv;

    unless ( ref( $data ) eq 'HASH' ) {
        die 'data is not HASH';
    }
    foreach ( qw(rows) ) {
        unless ( defined $data->{$_} ) {
            die 'data->' . $_ . ' is not defined';
        }
    }
    unless ( ref( $data->{rows} ) eq 'ARRAY' ) {
        die 'data->rows is not ARRAY';
    }

    my @rows;

    foreach ( @{ $data->{rows} } ) {
        unless ( ref( $_ ) eq 'HASH' ) {
            die 'data->rows[] entry is not HASH';
        }
        unless ( ref( $_->{doc} ) eq 'HASH' ) {
            die 'data->rows[]->doc is not HASH';
        }
        unless ( defined $_->{doc}->{_id} ) {
            die 'data->rows[]->doc->_id is not defined';
        }
        unless ( defined $_->{doc}->{_rev} ) {
            die 'data->rows[]->doc->_rev is not defined';
        }
        push( @rows, { _id => $_->{doc}->{_id}, _rev => $_->{doc}->{_rev} } );
    }

    return \@rows;
}

=item HandleResponseBulk

=cut

sub HandleResponseBulk {
    my ( $self, $cv ) = @_;

    unless ( blessed $cv and $cv->can( 'recv' ) ) {
        die 'cv is not object';
    }

    my $data = $cv->recv;

    unless ( ref( $data ) eq 'ARRAY' ) {
        die 'data is not ARRAY';
    }

    foreach ( @$data ) {
        unless ( ref( $_ ) eq 'HASH' ) {
            die 'data[] is not HASH';
        }
        unless ( defined $_->{id} ) {
            die 'data[]->id is not defined';
        }
        if ( exists $_->{rev} and exists $_->{ok} ) {
            unless ( defined $_->{rev} ) {
                die 'data[]->rev is not defined';
            }
            unless ( defined $_->{ok} ) {
                die 'data[]->ok is not defined';
            }
        }
        elsif ( exists $_->{error} and exists $_->{reason} ) {
            unless ( defined $_->{error} ) {
                die 'data[]->error is not defined';
            }
            unless ( defined $_->{reason} ) {
                die 'data[]->reason is not defined';
            }
        }
        else {
            die 'data[] missing rev/id or error/reason';
        }
    }

    return $data;
}

=back

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry@gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim-plugin-zonalizer/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lim::Plugin::Zonalizer::DB::CouchDB

You can also look for information at:

=over 4

=item * Lim issue tracker (report bugs here)

L<https://github.com/jelu/lim-plugin-zonalizer/issues>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2015-2016 Jerry Lundström
Copyright 2015-2016 IIS (The Internet Foundation in Sweden)

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Lim::Plugin::Zonalizer::DB::CouchDB
