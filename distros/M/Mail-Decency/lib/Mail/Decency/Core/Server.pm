package Mail::Decency::Core::Server;


use Moose;
extends 'Mail::Decency::Core::Meta';

use version 0.74; our $VERSION = qv( "v0.1.4" );

use Data::Dumper;
use Scalar::Util qw/ weaken blessed /;

use Mail::Decency::Helper::Cache;
use Mail::Decency::Helper::Database;
use Mail::Decency::Helper::Logger;
#use POE::Component::Server::Postfix;

use YAML;


=head1 NAME

Mail::Decency::Core::Server

=head1 DESCRIPTION

Base module for all decency servers (policy, content filter, syslog parser).


=head1 CLASS ATTRIBUTES

=head2 inited Bool

Wheter the server is inited or not

=cut

has inited => ( is => 'ro', isa => 'Bool' );


=head2 inited ArrayRef[Mail::Decency::Core::Child]

List of all (enabled) modules for this server.. Will be required when called handle

=cut

has childs => (
    is      => 'rw',
    isa     => 'ArrayRef[Mail::Decency::Core::Child]',
    default => sub { [] }
 );


=head1 METHODS


=head2 init

Init class for the server

=cut

sub init {
    die "Init method has to be overwritten by server methosd\n";
}


=head2 init_postfix_server

Setup POE::Component::Server::Postfix

=cut

sub init_postfix_server {
    my ( $self ) = @_;
    
    # check server config
    die "server config missing!\n"
        unless defined $self->config->{ server } && ref( $self->config->{ server } ) eq 'HASH';
    die "set either host and port OR socket for server\n"
        if (
            ! defined $self->config->{ server }->{ host }
            && ! defined $self->config->{ server }->{ port }
            && ! defined $self->config->{ server }->{ socket }
        ) || (
            defined $self->config->{ server }->{ host }
            && defined $self->config->{ server }->{ socket }
        );
    
    return 1;
}


=head2 init_logger

Setup logger facility

=cut

sub init_logger {
    my ( $self ) = @_;
    
    # setup logger
    ( my $prefix = ref( $self ) ) =~ s/^.*:://; 
    my $logger = Mail::Decency::Helper::Logger->new(
        %{ $self->config->{ logging } },
        prefix => $prefix
    );
    $self->{ logger } = $logger;
    # $self->{ logger } = sub {
    #     $logger->log( @_ );
    # };
    
    return 1;
}


=head2 init_cache

Setup cache facility ( $self->cache )

=cut

sub init_cache {
    my ( $self ) = @_;
    
    # setup cache
    die "cache config missing!\n"
        unless defined $self->config->{ cache };
    $self->{ cache } = blessed( $self->config->{ cache } )
        ? $self->config->{ cache }
        : Mail::Decency::Helper::Cache->new( %{ $self->config->{ cache } } )
    ;
    
    return 1;
}


=head2 init_database

Initi's database

=cut

sub init_database {
    my ( $self ) = @_;
    
    # setup cache
    die "database config missing!\n"
        unless defined $self->config->{ database };
    
    if ( blessed( $self->config->{ database } ) ) {
        $self->{ database } =  $self->config->{ database };
    }
    else {
        my $type = $self->config->{ database }->{ type }
            or die "Missing type for database (main)!\n";
        
        eval {
            $self->{ database } = Mail::Decency::Helper::Database
                ->create( $type => $self->config->{ database } );
        };
        die "Cannot create main database: $@\n" if $@;
        
    }
    
    weaken( my $self_weak = $self );
    $self->database->logger( $self->logger->clone( "$self/db" ) );
}



=head2 run 

Run the server

=cut

sub run {
    die "Run method has to be overwritten my server\n";
}


=head2 gen_child

=cut

sub gen_child {
    my ( $self, $base, $name, $config_ref, $init_args_ref ) = @_;
    
    # if not hashref as config .. check wheter file
    if ( ! ref( $config_ref ) ) {
        
        # having config dir ?
        if ( ! $self->has_config_dir && defined $self->config->{ config_dir } ) {
            if ( -d $self->config->{ config_dir } ) {
                $self->config_dir( $self->config->{ config_dir } );
            }
            else {
                die "Provided config_dir '". $self->config->{ config_dir }. "' is not a directory or not readable\n";
            }
        }
        
        # having dir-name ?
        if ( ! -f $config_ref && $self->has_config_dir && -f $self->config_dir . "/$config_ref" ) {
            $config_ref = $self->config_dir . "/$config_ref";
        }
        
        # having file ..
        if ( -f $config_ref ) {
            eval {
                $config_ref = YAML::LoadFile( $config_ref );
            };
            if ( $@ ) {
                die "Error loading config file '$config_ref' for $name: $@\n";
            }
        }
        else {
            die "Sorry, cannot find config file '$config_ref' for $name. (config_dir: ". ( $self->has_config_dir ? $self->config_dir : "not set" ). ")\n"; 
        }
    }
    
    # being disabled ?
    return if $config_ref->{ disable };
    
    # weak reference to self
    weaken( my $self_weak = $self );
    
    # havin extra databas for this fellow ?
    my $database;
    if ( defined $config_ref->{ database } ) {
        my $type = $config_ref->{ database }->{ type }
            or die "Missing required 'type' for database ($name)!\n";
        eval {
            $database = Mail::Decency::Helper::Database
                ->create( $type => $config_ref->{ database } );
        };
        die "Cannot create database for $name: $@\n" if $@;
    }
    else {
        weaken( $database = $self->database );
    }
    
    # determine module base
    my $module = "$base\::$name";
    eval "use $module";
    die "Missing policy module '$name' ($module)\n" if $@;
    
    # create instance of sub module
    my $obj;
    eval {
        my $logger = $self->logger->clone( lc( $self->logger->prefix. "/$name" ) );
        
        # delegate logger if new database
        $database->logger( $logger->clone->prefix. "/db" )
            if ( defined $config_ref->{ database } );
        
        # create the object itself
        $obj = $module->new(
            name     => $name,
            config   => $config_ref,
            cache    => $self->cache,
            database => $database,
            server   => $self,
            logger   => $logger,
            %$init_args_ref
        );
        
        # check database, if can .. don't start with corrupted !
        if ( $obj->can( 'check_database' ) && ! $ENV{ NO_CHECK_DATABASE } ) {
            ( my $db_class = ref( $self->database ) ) =~ s/^.+:://;
            $obj->check_database( $obj->schema_definition )
                or die "Please create the database yourself (class: $db_class)\n";
        }
        
    };
    
    die "Error creating $name: $@\n" if $@;
    
    # add to meta list of childs
    push @{ $self->childs }, $obj;
    
    return $obj;
}


=head2 maintenance 

Call maintenance, cleanup databases.

=cut

sub maintenance {
    my ( $self ) = @_;
    
    $self->logger->info( "Running in maintenance mode" );
    
    foreach my $policy( @{ $self->childs } ) {
        $policy->maintenance() if $policy->can( 'maintenance' );
    }
    
    $self->logger->info( "Maintenance performed" );
    
    exit 0;
}


=head2 disable_logging

Disables all loggers in all modules

=cut

sub disable_logging {
    my ( $self ) = @_;
    $self->logger->disabled( 1 );
    $self->database->logger->disabled( 1 );
    foreach my $child( @{ $self->childs } ) {
        $child->logger->disabled( 1 );
        $child->database->logger->disabled( 1 );
    }
}


=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut



1;
