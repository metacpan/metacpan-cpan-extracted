package Mail::Decency::Core::Excludes;

use Moose::Role;

use version 0.74; our $VERSION = qv( "v0.1.4" );

use feature qw/ switch /;

=head1 NAME

Mail::Decency::Core::Meta::Excludes

=head1 DESCRIPTION

Excludes module handling per recipient/sender domain/address.

Those exlusions can be either defined in the configuration and/or a plain text file and/or the a database.

=head1 CONFIG

    ---
    
    exclusions:
        
        modules:
            
            DNSBL:
                sender_domain:
                    - sender.tld
                    - somedomain.tld
                recipient_domain:
                    - recipient.tld
                    - anotherdomain.tld
                sender_address:
                    - some@sender.tld
                recipient_address:
                    - bla@recipient.tld
        
        file: /etc/decency/exclusions.txt
        
        database: 1
    

=head2 EXCLUSION PLAIN TEXT FILE

like this:

    sender_domain:DNSBL:sender.tld
    sender_domain:DNSBL:somedomain.tld
    recipient_domain:GeoWeight:recipient.tld
    recipient_domain:GeoWeight:anotherdomain.tld
    sender_address:SPF:some@sender.tld
    recipient_address:SPF:bla@recipient.tld

=head2 DATABASE

=head1 CLASS ATTRIBUTES

=head2 exclude_sender_domain : HashRef[Bool]

=cut

has exclusions => ( is => 'rw', isa => 'HashRef[Bool]', predicate => 'enable_exclusions' );

=head2 enable_file : Str

=cut

has exclusion_file => ( is => 'rw', isa => 'Str', predicate => 'enable_exclusion_file' );

=head2 enable_database : Bool

=cut

has enable_database => ( is => 'rw', isa => 'Bool', default => 0 );

=head2 exclusion_methods : ArrayRef[Str]

=cut

has exclusion_methods => ( is => 'rw', isa => 'ArrayRef[Str]', predicate => 'has_exclusions' );

=head1 METHODS

=head2 after init

=cut

after init => sub {
    my ( $self ) = @_;
    
    return unless defined $self->config->{ exclusions };
    my @exclusion_methods = ();
    
    # having exclusions in configuration
    if ( defined( my $m_ref = $self->config->{ exclusions }->{ modules } ) ) {
        $self->exclusions( {} );
        while ( my ( $module, $t_ref ) = each %$m_ref ) {
            while ( my ( $type, $values_ref ) = each %$t_ref ) {
                $self->exclusions->{ "$type:$module:$_" } = 1 for @$values_ref;
            }
        }
        push @exclusion_methods, '_get_exclude_from_config';
    }
    
    # enable database ..
    if ( $self->config->{ exclusions }->{ database } ) {
        $self->{ schema_definition } ||= {};
        $self->{ schema_definition }->{ exclusions } = {
            $self->name => {
                module  => [ varchar => 32 ],
                type    => [ varchar => 20 ],
                value   => [ varchar => 255 ],
                -unique => [ qw/ module type value / ]
            },
        };
        $self->enable_database( 1 );
        push @exclusion_methods, '_get_exclude_from_database';
    }
    
    # having a plaintext file ..
    if ( defined( my $file = $self->config->{ exclusions }->{ file } ) ) {
        $file = $self->config_dir. "/$file"
            if ! -f $file && $file !~ /^\//;
        die "Exclusion file '$file' does not exist or not accessable\n"
            unless -f $file;
        die "Exclusion file '$file' not readable\n"
            unless -r $file;
        open my $fh, '<', $file
            or die "Error opening exclusion file '$file': $@";
        close $fh;
        $self->exclusion_file( $file );
        push @exclusion_methods, '_get_exclude_from_file';
    }
    
    $self->exclusion_methods( \@exclusion_methods );
    
};

=head2 do_exclude

Returns bool wheter the current mail (session) shall overstep the current module

=cut

sub do_exclude {
    my ( $self, $module ) = @_;
    
    return unless $self->has_exclusions;
    
    my $session = $self->session_data;
    
    my @check = (
        [
            "recipient_address:$module:". lc( $session->to ),
            [ "recipient_address", "$module", lc( $session->to ) ]
        ],
        [
            "recipient_domain:$module:". lc( $session->to_domain ),
            [ "recipient_domain", "$module", lc( $session->to_domain ) ]
        ],
        [
            "sender_address:$module:". lc( $session->from ),
            [ "sender_address", "$module", lc( $session->from ) ]
        ],
        [
            "sender_domain:$module:". lc( $session->from_domain ),
            [ "sender_domain", "$module", lc( $session->from_domain ) ]
        ],
    );
    
    foreach my $check( @check ) {
        return 1 if $self->cache->get( $check );
    }
    
    foreach my $check( @{ $self->exclusion_methods } ) {
        my ( $ok, $cache ) = $self->$check( \@check );
        if ( $ok ) {
            $self->cache->set( $cache => 1 );
            return 1;
        }
    }
}

=head2 _get_exclude_from_config

=cut

sub _get_exclude_from_config {
    my ( $self, $check_ref ) = @_;
    
    foreach my $check( @$check_ref ) {
        if ( defined $self->exclusions->{ $check->[0] } ) {
            return ( 1, $check->[0] );
        }
    }
    
    return;
}

=head2 _get_exclude_from_file

=cut

sub _get_exclude_from_file {
    my ( $self, $check_ref ) = @_;
    
    my ( $ok, $cache_name );
    eval {
        open my $fh, '<', $self->exclusion_file or die $!;
        
        CHECK_LINE:
        while ( my $l = <$fh> ) {
            chomp $l;
            foreach my $check( @$check_ref ) {
                if ( $check->[0] eq $l ) {
                    $ok++;
                    $cache_name = $check->[0];
                    last CHECK_LINE;
                }
            }
        }
        
        close $fh;
    };
    $self->logger->error( "Error reading from exclusion file: $@" ) if $@;
    
    return ( $ok, $cache_name );
}

=head2 _get_exclude_from_database

=cut

sub _get_exclude_from_database {
    my ( $self, $check_ref ) = @_;
    
    foreach my $check( @$check_ref ) {
        my $db_ref = $self->database->get( exclusions => $self->name => {
            type   => $check->[1]->[0],
            module => $check->[1]->[1],
            value  => $check->[1]->[2],
        } );
        return ( 1, $check->[0] ) if $db_ref && $db_ref->{ value } eq $check->[1]->[2];
    }
    
    return;
}

=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut


1;
