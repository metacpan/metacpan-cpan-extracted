package Mail::Decency::LogParser;

use Moose;
extends 'Mail::Decency::Core::Server';

with qw/
    Mail::Decency::Core::Stats
/;

use version 0.74; our $VERSION = qv( "v0.1.4" );

use POE qw/
    Wheel::FollowTail
/;

use Data::Dumper;
use Scalar::Util qw/ weaken blessed /;

use Mail::Decency::Helper::Cache;
use Mail::Decency::Helper::Database;
use Mail::Decency::Helper::Logger;

=head1 NAME

Mail::Decency::LogParser

=head1 SYNOPSIS

    use Mail::Decency::LogParser;
    
    my $syslog_parser = Mail::Decency::LogParser->new( {
        config => '/etc/decency/log-parser.yml'
    } );
    
    $syslog_parser->run;

=head1 DESCRIPTION

The LogParser server provides tools to tail and parse mail server log files. It can implement different log parser styles. For now it supports only postfix log files via L<Mail::Decency::LogParser::Core::PostfixParser>.

=head1 CONFIG

Provide either a hashref or a YAML file. 

Example:

    ---
    
    include:
        - logging.yml
        - database.yml
        - cache.yml
    
    syslog:
        style: Postfix
        file: /var/log/mail.log
    
    parser:
        -
            Stats:
                disable: 0
                use_date_interval: 1
                intervals:
                    - 10
                    - 600
                    - 86400
                
                csv_log:
                    file: /var/spool/decency/logs/csv
                    classes:
                        - total_reject
                        - connections
                        - sent
                        - deferred
        -
            Aggregator:
                disable: 0
                interval_formats:
                    - 'year-%Y'
                    - 'week-%Y-%U'
                    - 'month-%Y-%m'
        -
            GeoSource:
                disable: 0
                interval_formats:
                    - 'year-%Y'
                    - 'week-%Y-%U'
                    - 'month-%Y-%m'
                enable_per_recipient: 1
    


=cut


=head1 CLASS ATTRIBUTES

See L<Mail::Decency::Policy::Core>

=head2 syslog_file : Str

Path to the syslog file

=cut

has syslog_file   => ( is => 'ro', isa => 'Str' );

=head2 syslog_socket : Str

Path to socket for syslog

=cut

has syslog_socket => ( is => 'ro', isa => 'Str' );



=head2 syslog_file : Str

Path to the syslog file

=cut

has parser        => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
has handle_parse  => ( is => 'rw', isa => 'CodeRef' );

=head1 METHODS


=head2 init

Loads LogParser modules, inits config, cache and databases

=cut

sub init {
    my ( $self ) = @_;
    
    # mark es inited
    $self->{ inited } ++;
    
    # enable style
    die "Require 'syslog.style: Postfix|QSMTPd|...'\n"
        unless $self->config->{ syslog } && $self->config->{ syslog }->{ style };
    my $role = $self->config->{ syslog }->{ style } =~ /::/
        ? $self->config->{ syslog }->{ style }
        : "Mail::Decency::LogParser::Core::". $self->config->{ syslog }->{ style }. "Parser"
    ;
    with $role;
    
    # init logger, cache, database
    $self->init_logger();
    $self->init_cache();
    $self->init_database();
    $self->init_syslog_parser();
    
    if ( defined( my $file = $self->config->{ syslog }->{ file } ) ) {
        die "Syslog file '$file' does not exist or not readable\n"
            unless -f $file;
        die "Have no read access to '$file'\n"
            unless -r $file;
        $self->{ syslog_file } = $file;
        $self->logger->info( "Start parsing '$file'" );
    }
    elsif ( defined( my $socket = $self->config->{ syslog }->{ socket } ) ) {
        $self->{ syslog_socket } = $socket;
    }
    else {
        die "Require either 'socket' or 'file' in section 'syslog'\n"
    }
    
    
    return;
}




=head2 init_syslog_parser

=cut

sub init_syslog_parser {
    my ( $self ) = @_;
    
    my $parsers_ref = $self->config->{ parser } or die "Missing 'parser' in config\n";
    die "'parser' supposed to be an arrayref, got ". ref( $parsers_ref ). "\n"
        unless ref( $parsers_ref ) eq 'ARRAY';
    
    foreach my $parser_ref( @{ $parsers_ref } ) {
        
        # get name anf config
        my ( $name, $config_ref ) = %$parser_ref;
        
        # setup enw filter
        
        my $parser = $self->gen_child(
            "Mail::Decency::LogParser" => $name => $parser_ref );
        $parser_ref->{ $name } = $parser->config if $parser;
    }
}




=head2 start

Starts all POE servers without calling the POE::Kernel->run

=cut

sub start {
    my ( $self ) = @_;
    
    weaken( my $self_weak = $self );
    POE::Session->create(
        inline_states => {
            _start => sub {
                $_[HEAP]->{ tailor } = POE::Wheel::FollowTail->new(
                    Filename     => $self_weak->syslog_file,
                    InputEvent   => "read_line",
                    ResetEvent   => "rotate_log",
                    PollInterval => 1,
                );
            },
            
            read_line => sub {
                my $parsed_ref = $self_weak->parse_line( $_[ ARG0 ] );
                $self->handle( $parsed_ref )
                    if $parsed_ref && $parsed_ref->{ final };
            },
            
            rotate_log => sub {
                # for now: not required
            },
            
            _default => sub {
                my ( $heap, $event, $args ) = @_[ HEAP, ARG0, ARG1 ];
                $self_weak->logger->error( "** UNKNOWN EVENT $event, $args" );
            }
        },
    );
}


=head2 run 

Start and run the server via POE::Kernel->run

=cut

sub run {
    my ( $self ) = @_;
    $self->start;
    
    POE::Kernel->run;
}


=head2 handle

Handle method, called by the L<POE::Wheel::FollowTail> instance on each tailed line.

=cut

sub handle {
    my ( $self, $parsed_ref ) = @_;
    
    foreach my $parser( @{ $self->childs } ) {
        eval {
            $parser->handle( $parsed_ref );
        };
        $self->logger->error( "Error in parser '$parser': $@" ) if $@;
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
