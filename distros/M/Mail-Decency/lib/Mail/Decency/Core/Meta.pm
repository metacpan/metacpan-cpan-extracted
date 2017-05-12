package Mail::Decency::Core::Meta;

use Moose;

use version 0.74; our $VERSION = qv( "v0.1.4" );

use Data::Dumper;
use Scalar::Util qw/ weaken blessed /;
use YAML qw/ LoadFile /;
use File::Basename qw/ dirname /;

=head1 NAME

Mail::Decency::Core::Meta

=head1 DESCRIPTION

Meta base class for most deceny modules.


=head1 CLASS ATTRIBUTES

See L<Mail::Decency::Policy::Core>

=cut

has config     => ( is => 'rw', trigger => \&_init_config , predicate => 'has_config' );
has config_dir => ( is => 'rw', isa => 'Str', predicate => 'has_config_dir' );
has cache      => ( is => 'ro', isa => 'Mail::Decency::Helper::Cache', weak_ref => 1 );
has database   => ( is => 'ro', isa => 'Mail::Decency::Helper::Database' );
has logger     => ( is => 'ro', isa => 'Mail::Decency::Helper::Logger' );
has name       => ( is => 'rw', isa => 'Str' );

__PACKAGE__->meta->make_immutable;

=head1 METHODS


=head1 BUILD

Constructor chain

=cut

sub BUILD {
    my ( $self ) = @_;
    
    # init policy
    unless ( $self->name ) {
        ( my $class = ref( $self ) ) =~ s/^.*:://;
        $self->name( $class );
    }
    
    # parse config
    $self->parse_config();
    
    # call init ..
    $self->init();
    
    # cleanup, check and such after init
    $self->after_init() if $self->can( 'after_init' );
    
    # Here we are!
    $self->logger->info( "inited" );
    
    
}


=head1 DEMOLISH

Destructor chaing

=cut

sub DEMOLISH {
    my ( $self ) = @_;
    $self->demolish() if $self->can( 'demolish' );
    $self->logger->debug0( "Stopped ". $self->name );
}


=head2 init

Init class for the server

=cut

sub init {
    die "Init method has to be overwritten by module ". ( ref( shift ) ). "\n";
}


=head2 parse_config

Read config file , read includes ..

=cut

sub parse_config {
    my ( $self ) = @_;
    
    # parse config -> find all "includes"
    if ( defined $self->config->{ include } ) {
        my @includes = ref( $self->config->{ include } )
            ? @{ $self->config->{ include } }
            : ( $self->config->{ include } )
        ;
        
        my %add = ();
        foreach my $include( @includes ) {
            my $path = ! -f $include && $self->has_config_dir
                ? $self->config_dir . "/$include"
                : $include
            ;
            die "Cannot include config file '$path': does not exist or not readable (". (
                $self->has_config_dir
                    ? "config_dir: ". $self->config_dir
                    : "no config_dir"
                ). ")\n"
                unless -f $path;
            %add = ( %add, %{ LoadFile( $path ) } );
        }
        
        # merge by replace
        $self->config( { %{ $self->config }, %add } );
    }
}


=head1 PRIVATE METHODS

=head2 _init_config

=cut

sub _init_config {
    my ( $self, $config_ref ) = @_;
    unless ( ref( $self->config ) ) {
        die "Require hashref or path to file for config, got '". $self->config. "'\n"
            unless -f $config_ref;
        
        # extract dir
        unless ( $self->has_config_dir ) {
            my $config_dir = dirname( $config_ref );
            $self->config_dir( $config_dir );
        }
        
        # load file from yaml
        $self->config( LoadFile( $config_ref ) );
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
