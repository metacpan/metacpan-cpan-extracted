package Mail::Decency::Helper::Logger;

use Moose;

use version 0.74; our $VERSION = qv( "v0.1.4" );

use Sys::Syslog qw/ :standard :macros /;
use Scalar::Util qw/ weaken /;
use File::Path qw/ make_path /;
use Carp qw/ carp /;

=head1 NAME

Mail::Decency::Helper::Logger

=head1 DESCRIPTION

Helper modules for Decency policies or content filters

=cut

has prefix     => ( is => 'rw', isa => 'Str', default => '' ); 
has syslog     => ( is => 'rw', isa => 'Bool' );
has console    => ( is => 'rw', isa => 'Bool' );
has directory  => ( is => 'rw', isa => 'Str' );
has log_level  => ( is => 'rw', default => 0 );
has disabled   => ( is => 'rw', isa => 'Bool', default => 0 );
has _log_level => ( is => 'ro', isa => 'HashRef', default => sub { {
    error   => 0,
    info    => 1,
    verbose => 2,
    debug0  => 3,
    debug1  => 4,
    debug2  => 5,
    debug3  => 6,
} } );
has _log_file_handles => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
has _log_file_inodes => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
has _log_method => ( is => 'rw', isa => 'CodeRef' );



sub BUILD {
    my ( $self, $args_ref ) = @_;
    
    my @print = ();
    
    # determine log level
    my $log_level = defined $args_ref->{ log_level }
        ? $args_ref->{ log_level }
        : "info"
    ;
    $log_level = $log_level !~ /^\d+$/
        ? ( defined $self->_log_level->{ $log_level }
            ? $self->_log_level->{ $log_level }
            : 1
        )
        : $log_level
    ;
    $self->log_level( $log_level );
    push @print, "LogLevel: $log_level";
    
    # determine output
    foreach my $output( qw/ syslog console directory / ) {
        $self->$output( $args_ref->{ $output } )
            if $args_ref->{ $output };
    }
    
    
    my @methods = ();
    
    # enable syslog
    if ( $self->syslog ) {
        openlog( "decency", "ndelay,pid", "local0" );
        push @methods, sub {
            my ( $self, $int_log_level, $str_log_level, $msg ) = @_;
            my $level = $int_log_level == 0
                ? LOG_ERR
                : ( $int_log_level == 1
                    ? LOG_INFO
                    : LOG_DEBUG
                )
            ;
            my $suffix = $level == LOG_DEBUG
                ? "/$str_log_level"
                : ""
            ;
            Sys::Syslog::syslog( $level => "[". $self->prefix. $suffix. "]: $msg" );
        };
        push @print, "Enable Syslog";
    }
    
    # enable console
    if ( $self->console ) {
        push @methods, sub {
            my ( $self, $int_log_level, $str_log_level, $msg ) = @_;
            warn "[$$/". localtime(). "/". $self->prefix. "/$str_log_level]: $msg\n";
        };
        push @print, "Enable Console";
    }
    
    # enable directory
    if ( $self->directory ) {
        make_path( $self->directory, { mode => 0700 } )
            unless -d $self->directory;
        die "Could not create log directory '". $self->directory. "'\n"
            unless -d $self->directory;
        
        my $log_sub = sub {
            my ( $file, $self, $int_log_level, $str_log_level, $msg ) = @_;
            my ( undef, $inode ) = stat( $file );
            
            my $fh = $self->_log_file_handles->{ $file };
            if ( ! $fh || ! -f $file || ! defined $self->_log_file_inodes->{ $file } || $inode != $self->_log_file_inodes->{ $file } ) {
                eval { close $fh if $fh; };
                my $mode = -f $file ? ">>" : ">";
                open $fh, $mode, $file
                    or carp "Cannot open '$file' for write/append: $!";
                $self->_log_file_handles->{ $file } = $fh;
                $self->_log_file_inodes->{ $file } = $inode;
            }
            print $fh "[$$/". localtime(). "/". $self->prefix. "/$str_log_level]: $msg\n"
                or carp "Failed print to '$file': $!";
        };
        
        my $dir = $self->directory;
        my $log_sub_ref = {
            error => sub {
                $log_sub->( "$dir/error.log", @_ ); 
            },
            info => sub {
                $log_sub->( "$dir/info.log", @_ ); 
            },
            debug => sub {
                $log_sub->( "$dir/debug.log", @_ ); 
            }
        };
        my $log_sub_map_ref = {
            0 => "error",
            1 => "info",
        };
        
        push @methods, sub {
            my ( $self, $int_log_level, $str_log_level, $msg ) = @_;
            my $name = $log_sub_map_ref->{ $int_log_level } || "debug";
            $log_sub_ref->{ $name }->( $self, $int_log_level, $str_log_level, $msg );
        };
        push @print, "Enable Directory";
    }
    
    # build the logger method
    $self->_log_method( sub {
        my ( $self, $log_level, $msg ) = @_;
        my $int_log_level = $self->_log_level->{ $log_level } || 0;
        return
            if $int_log_level > $self->log_level;
        $_->( $self, $int_log_level, $log_level, $msg ) for @methods;
    } );
    
    $self->log( info => "Inited Logger: ". join( ", ", @print ) );
    
    return $self;
}

=head2 log

=cut

sub log {
    my ( $self, $log_level, $msg ) = @_;
    return if $self->disabled;
    $self->_log_method->( $self, $log_level, $msg );
}

=head2 error

Log error level

=cut

sub error {
    my ( $self, $msg ) = @_;
    $self->log( error => $msg );
}

=head2 info

Log info level

=cut

sub info {
    my ( $self, $msg ) = @_;
    $self->log( info => $msg );
}

=head2 debug0

Log debug0 level

=cut

sub debug0 {
    my ( $self, $msg ) = @_;
    $self->log( debug0 => $msg );
}

=head2 debug1

Log debug1 level

=cut

sub debug1 {
    my ( $self, $msg ) = @_;
    $self->log( debug1 => $msg );
}

=head2 debug2

Log debug2 level

=cut

sub debug2 {
    my ( $self, $msg ) = @_;
    $self->log( debug2 => $msg );
}

=head2 debug3

Log debug3 level

=cut

sub debug3 {
    my ( $self, $msg ) = @_;
    $self->log( debug3 => $msg );
}



=head2 clone

Returns new instance of self

=cut

sub clone {
    my ( $self, $prefix ) = @_;
    my $clone = bless { %$self }, ref( $self );
    $clone->prefix( $prefix ) if $prefix;
    return $clone;
}





=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut

1;

