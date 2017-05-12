package Mail::Decency::Core::Stats;

use Moose::Role;

use version 0.74; our $VERSION = qv( "v0.1.5" );

use Data::Dumper;
use DateTime;

=head1 NAME

Mail::Decency::Core::Stats

=head1 DESCRIPTION

Statistic database for policy server and content filter

=cut

=head2 enable_stats

Wheter enable stats or not

=cut

has enable_stats => ( is => 'rw', isa => 'Bool', default => 0 );

has stats_intervals => ( is => 'rw', isa => 'ArrayRef[Str]', default => sub {
    [
        'hour',
        'day',
        'week',
        'month',
        'year',
    ]
} );
has stats_time_zone => ( is => 'ro', isa => 'DateTime::TimeZone', default => sub {
    DateTime::TimeZone::Local->TimeZone();
} );
has schema_definition => ( is => 'ro', isa => 'HashRef[HashRef]' );


=head1 MODIFIER

=head2 init

Update schema definition of this module

=cut

after 'init' => sub {
    my ( $self ) = @_;
    
    my $prefix = $self->name;
    
    $self->{ schema_definition } ||= {};
    $self->{ schema_definition }->{ stats } = {
        $self->name. "_response" => {
            module  => [ varchar => 32 ],
            period  => [ varchar => 10 ],
            start   => 'integer',
            type    => [ varchar => 32 ],
            -unique => [ qw/ module period start type / ]
        },
        $self->name. "_performance" => {
            module  => [ varchar => 32 ],
            type    => [ varchar => 32 ],
            period  => [ varchar => 10 ],
            calls   => [ varchar => 10 ],
            runtime => [ 'real' ],
            start   => 'integer',
            -unique => [ qw/ module period start type / ]
        }
    };
    
    $self->enable_stats( 1 )
        if $self->config->{ enable_stats };
};

=head2 maintenance

Clears all entries which are older then the current interval. For hour, that would mean any hourly stats before the current hour, for year that would mean any stat from the last year and so on..

=cut

before 'maintenance' => sub {
    my ( $self ) = @_;
    my $table = lc( $self->name );
    
    my $now = DateTime->now( time_zone => $self->stats_time_zone );
    my @intervals = map {
        my $iv = $now->clone->truncate( to => $_ );
        [ $_, $iv->epoch ];
    } grep {
        /^(hour|day|week|month|year)$/
    } @{ $self->stats_intervals };
    
    my @module_names = map { "$_" } @{ $self->childs };
    ( my $server_name = ref( $self ) ) =~ s/^.*:://;
    push @module_names, "${server_name}Core";
    
    foreach my $interval_ref( @intervals ) {
        $self->database->remove( stats => "${table}_performance" => {
            module => \@module_names,
            period => $interval_ref->[0],
            start  => { 
                '<' => $interval_ref->[1],
            }
        } );
        $self->database->remove( stats => "${table}_response" => {
            module => \@module_names,
            period => $interval_ref->[0],
            start  => { 
                '<' => $interval_ref->[1],
            }
        } );
    }
};


=head1 METHODS

=head2 update_stats

=cut

sub update_stats {
    my ( $self, $module, $type, $weight_diff, $runtime ) = @_;
    
    print Dumper [ $type => $weight_diff, $runtime ];
    
    my $now = DateTime->now( time_zone => $self->stats_time_zone );
    my @intervals = map {
        my $iv = $now->clone->truncate( to => $_ );
        [ $_, $iv->epoch ];
    } grep {
        /^(hour|day|week|month|year)$/
    } @{ $self->stats_intervals };
    
    eval {
        
        my $table = lc( $self->name );
        foreach my $interval_ref( @intervals ) {
            my %search = (
                module => "$module",
                period => $interval_ref->[0],
                start  => $interval_ref->[1],
            );
            
            # increment weighting
            if ( defined $weight_diff ) {
                $self->database->usr_lock;
                my $db_ref = $self->database->get( stats => "${table}_performance" => \%search );
                $db_ref ||= { weight => 0, runtime => 0, calls => 0 };
                $self->database->set( stats => "${table}_performance" => \%search, {
                    weight  => ( $db_ref->{ weight } || 0 ) + $weight_diff,
                    calls   => $db_ref->{ calls } + 1,
                    runtime => $db_ref->{ runtime } + $runtime
                } );
                $self->database->usr_unlock;
            }
            
            # increment response counter
            $self->database->increment( stats => "${table}_response" => {
                %search,
                type => $type,
            } );
        }
    };
    $self->logger->error( "Error updating stats for $module / $type: $@" ) if $@;
    
    return;
}


=head2 print_stats

Print out stats

=cut

sub print_stats {
    my ( $self, $return ) = @_;
    
    my $table = lc( $self->name );
    
    my $now = DateTime->now( time_zone => $self->stats_time_zone );
    my @intervals = map {
        my $iv = $now->clone->truncate( to => $_ );
        [ $_, $iv->epoch ];
    } grep {
        /^(hour|day|week|month|year)$/
    } @{ $self->stats_intervals };
    
    my @module_names = map { "$_" } @{ $self->childs };
    ( my $server_name = ref( $self ) ) =~ s/^.*:://;
    push @module_names, "${server_name}Core";
    
    my ( %stats_weight, %stats_response ) = ();
    
    foreach my $interval_ref( @intervals ) {
        my ( $period, $start ) = @$interval_ref;
        
        foreach my $module( @module_names ) {
            my $weight_ref = $self->database->get( stats => "${table}_performance" => {
                module => $module,
                period => $period,
                start  => { 
                    '>=' => $start,
                }
            } );
            if ( $weight_ref ) {
                $stats_weight{ $module } ||= {};
                $stats_weight{ $module }->{ $period } = $weight_ref->{ weight };
                
                if ( $period eq 'year' ) {
                    $stats_weight{ $module }->{ $_ } = $weight_ref->{ $_ }
                        for qw/ calls runtime /;
                }
            }
            
            my @response = $self->database->search( stats => "${table}_response" => {
                module => $module,
                period => $period,
                start  => {
                    '>=' => $start,
                }
            } );
            
            foreach my $response_ref( @response ) {
                next unless $response_ref->{ type };
                $stats_response{ $response_ref->{ type } } ||= {};
                $stats_response{ $response_ref->{ type } }->{ $module } ||= {};
                $stats_response{ $response_ref->{ type } }->{ $module }->{ $period }
                    = $response_ref->{ data };
            }
        }
    }
    
    my $format = '%-20s'. ( ' | %-10s' x 5 );
    
    
    #
    # PRINT RESPONSE
    #
    
    if ( scalar keys %stats_response ) {
        
        print "# **************************************\n# RESPONSE STATS\n# **************************************\n";
        foreach my $response( sort keys %stats_response ) {
            my @out = ( sprintf( $format, 'Module', map { ucfirst( $_ ). " ". $now->$_ } qw/ hour day week month year / ) );
            
            print "\n# ****** $response ******\n";
            
            my $response_ref = $stats_response{ $response };
            foreach my $module( sort { $b =~ /Core$/ ? -1 : $a cmp $b } keys %$response_ref ) {
                push @out, sprintf( $format, $module,
                    $response_ref->{ $module }->{ hour }
                        ? sprintf( '%.1f', $response_ref->{ $module }->{ hour } )
                        : "-"
                    ,
                    $response_ref->{ $module }->{ day }
                        ? sprintf( '%.1f', $response_ref->{ $module }->{ day } )
                        : "-"
                    ,
                    $response_ref->{ $module }->{ week }
                        ? sprintf( '%.1f', $response_ref->{ $module }->{ week } )
                        : "-"
                    ,
                    $response_ref->{ $module }->{ month }
                        ? sprintf( '%.1f', $response_ref->{ $module }->{ month } )
                        : "-"
                    ,
                    $response_ref->{ $module }->{ year }
                        ? sprintf( '%.1f', $response_ref->{ $module }->{ year } )
                        : "-"
                    ,
                );
            }
            
            print join( "\n", @out ). "\n";
        }
        print "\n\n";
    }
    
    #
    # PRINT WEIGHT
    #
    if ( scalar keys %stats_weight ) {
        
        print "# **************************************\n# WEIGHT STATS\n# **************************************\n";
        my @out = ( sprintf( $format, 'Module', map { ucfirst( $_ ). " ". $now->$_ } qw/ hour day week month year / ) );
        
        foreach my $module( sort { $b =~ /Core$/ ? -1 : $a cmp $b } keys %stats_weight ) {
            push @out, sprintf( $format, $module,
                $stats_weight{ $module }->{ hour }
                    ? sprintf( '%.1f', $stats_weight{ $module }->{ hour } )
                    : "-"
                ,
                $stats_weight{ $module }->{ day }
                    ? sprintf( '%.1f', $stats_weight{ $module }->{ day } )
                    : "-"
                ,
                $stats_weight{ $module }->{ week }
                    ? sprintf( '%.1f', $stats_weight{ $module }->{ week } )
                    : "-"
                ,
                $stats_weight{ $module }->{ month }
                    ? sprintf( '%.1f', $stats_weight{ $module }->{ month } )
                    : "-"
                ,
                $stats_weight{ $module }->{ year }
                    ? sprintf( '%.1f', $stats_weight{ $module }->{ year } )
                    : "-"
                ,
                
            );
        }
        print join( "\n", @out ). "\n\n\n";
    }
    
    #
    # PRINT RUNTIME
    #
    if ( scalar keys %stats_weight ) {
        
        print "# **************************************\n# RUNTIME STATS\n# **************************************\n";
        my @out = ( sprintf( $format, 'Module', map { ucfirst( $_ ) } qw/ total calls average - - / ) );
        
        foreach my $module( sort { $b =~ /Core$/ ? -1 : $a cmp $b } keys %stats_weight ) {
            my $average = $stats_weight{ $module }->{ calls } > 0
                ? $stats_weight{ $module }->{ runtime } / $stats_weight{ $module }->{ calls }
                : 0
            ;
            push @out, sprintf( $format, $module,
                sprintf( '%.2f', $stats_weight{ $module }->{ runtime } || 0 ),
                $stats_weight{ $module }->{ calls } || "-",
                sprintf( '%.4f', $average ),
                "-",
                "-",
            );
        }
        print join( "\n", @out ). "\n\n\n";
    }
    
    #
    # MODULE STATS
    #
    
    foreach my $module( @{ $self->childs } ) {
        next unless $module->can( 'print_stats' );
        print "# *************************************\n# Module: $module STATS\n# *************************************\n";
        $module->print_stats;
        print "\n\n\n";
    }
    
    #print Dumper( { weight => \%stats_weight, response => \%stats_response, out => \@out } );
    
}



=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut




1;
