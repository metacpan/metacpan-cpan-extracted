package Mail::Decency::LogParser::Core::CacheWrite;

use Moose::Role;

use version 0.74; our $VERSION = qv( "v0.1.4" );

use Data::Dumper;

=head1 NAME

Mail::Decency::LogParser::Core::CacheWrite


=head1 DESCRIPTION

Logs 

=head1 CLASS ATTRIBUTES

=cut

has cache_prefix => ( is => 'rw', isa => 'Str', default => '' );

=head1 METHODS

=head2 handle

=cut

after handle => sub {
    my ( $self ) = @_;
    
    my %data = ();
    $data{ $_ } = $self->_update_data( $self->current_data->{ $_ } )
        for keys %{ $self->current_data };
    
    # write all caches
    while( my ( $type, $data_ref ) = each %data ) {
        foreach my $ref( @$data_ref ) {
            my $cache_name = join( "-", $self->cache_prefix, $type, @$ref );
            #print "WRITE $cache_name\n";
            my $amount = ( $self->cache->get( $cache_name ) || 0 ) + 1;
            $self->cache->set( $cache_name => $amount );
        }
    }
};


=head2 _update_data

=cut

sub _update_data {
    my ( $self, $data_ref ) = @_;
    
    my @time_data = ();
    
    # setup time based caches
    my $now = time();
    
    # setup the time intervals
    if ( $self->use_date_interval ) {
        
        # get now
        my @now = localtime( $now );
        $now[4]++; # increment day
        
        # caches are:
        #   * minute basis MH-<Minute>-<Hour>
        #   * hour basis   HD-<Day>-<Hour>
        #   * day basis    DM-<Month>-<Day>
        my $min_timeout  = 60 - $now[0];
        my $hour_timeout = ( 60 - $now[1] ) * 60 + $min_timeout;
        my $day_timeout  = ( 24 - $now[2] ) * 3600 + $hour_timeout;
        my @times = (
            sprintf( 'mh-%02d-%02d', @now[1,2] ), # minute-hour-day
            sprintf( 'hd-%02d-%02d', @now[2,3] ), # hour-day
            sprintf( 'dm-%02d-%02d', @now[3,4] ), # day-month
        );
        
        push @time_data, map {
            my $c = $_;
            ( map { [ $c, $data_ref->{ $c }, $_ ] } @times );
        } keys %$data_ref;
    }
    
    # setup interval timeouts
    #   * timeouts based on 
    foreach my $type( keys %$data_ref ) {
        push @time_data, map {
            my $start = $now - ( $now % $_ );
            [ $type, $data_ref->{ $type }, $start + $_ ];
        } @{ $self->intervals };
        push @time_data, [ $type, $data_ref->{ $type }, "total" ];
    }
    
    return \@time_data;
}

=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut

1;
