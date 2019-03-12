package Log::AutoDump;

use 5.006;

use strict;
use warnings;

use Data::Dumper;
use IO::File;

use constant FATAL => 0;
use constant ERROR => 1;
use constant WARN  => 2;
use constant INFO  => 3;
use constant DEBUG => 4;
use constant TRACE => 5;

my %LEVELS = ( 0 => 'FATAL', 1 => 'ERROR', 2 => 'WARN', 3 => 'INFO', 4 => 'DEBUG', 5 => 'TRACE' );

use constant DEFAULT_LEVEL => 5;
use constant DEFAULT_SORT_KEYS => 1;
use constant DEFAULT_QUOTE_KEYS => 0;

use constant DEFAULT_BASE_DIR => '/tmp';
use constant MAX_FRAME => 10;

=head1 NAME

Log::AutoDump - Log with automatic dumping of references and objects.

=head1 VERSION

Version 0.15

=cut

our $VERSION = '0.15';

$VERSION = eval $VERSION;

=head1 SYNOPSIS

Logging as usual, but with automatic dumping of references and objects.

 use Log::AutoDump;

 my $log = Log::AutoDump->new;
    
 $log->msg( 4, "Logging at level 4 (debug)", $ref, $hashref );

 $log->warn( "Logging at warn level (2)", \@somelist, "Did you see that list?!" )
 
=cut

=head1 DESCRIPTION

When logging in development, it is common to dump a reference or object.

When working with logging systems that employ the idea of "log-levels", you can quickly end up with expensive code.

For example...

 $log->warn( "Some object:", Dumper( $obj ), "Did you like that?" );

If the B<level> for the C<$log> object is set lower than B<warn>, the above log statement will never make it to any log file, or database.

Unfortunately, you have still C<Dumped> an entire data-structure, just in case.

We take the dumping process out of your hands.

The above statement becomes...

 $log->warn( "Some object:", $obj, "Did you like that?" );

Which is easier to read/write for a start, but will also B<dump> the C<obj> by default.

Using L<Data::Dumper> unless specified.

You can control the C<$Data::Dumper::Maxdepth> by setting the C<dump_depth> attribute at construction time, and/or change it later.

 my $log = Log::AutoDump->new( dump_depth => 3 );
 
 $log->dump_depth( 1 );

This is useful when dealing with some references or objects that may contain things like L<DateTime> objects, which are themselves huge.  

=cut


=head1 METHODS

=head2 Class Methods

=head3 new

Creates a new logger object.

 my $log = Log::AutoDump->new(
     level              => 3,
     dumps              => 1,
     dump_depth         => 2,
     sort_keys          => 1,
     quote_keys         => 0,
     filename_datestamp => 1,
 );

=cut

sub new
{
    my ( $class, %args ) = @_;

    if ( 1 )   # possibly use db backend later
    {
        my $path = $ENV{LOG_AUTODUMP_BASE_DIR} || $args{ base_dir } || DEFAULT_BASE_DIR;

        $path .= '/' unless $path =~ m!/$!;

        my $filename = delete $args{filename} || $0;
    
        $filename =~ s/^\.//;
    
        $filename =~ s/[\s\/]/-/g;

        $filename =~ s/^-//;

        if ( $args{ filename_datestamp } || $args{ datestamp_filename } )  # datestamp_filename can be removed after May 2012
        {
            my ( undef, undef, undef, $day, $mon, $year, undef, undef, undef ) = localtime( time );

            $mon++;
            $mon =~ s/^(\d)$/0$1/;
            $day =~ s/^(\d)$/0$1/;
        
            my $datestamp = ( $year + 1900 ) . $mon . $day;
            
            $filename = $datestamp . '-' . $filename;
        }
        
        $args{ filename } = $path . $filename;
    }
        
    my $self = {
         level      => exists $args{ level } ? $args{ level } : DEFAULT_LEVEL,
         dumps      => exists $args{ dumps } ? $args{ dumps } : 1,
         dump_depth => $args{ dump_depth } || 0,
         sort_keys  => exists $args{ sort_keys }  ? $args{ sort_keys }  : DEFAULT_SORT_KEYS,
         quote_keys => exists $args{ quote_keys } ? $args{ quote_keys } : DEFAULT_QUOTE_KEYS,
         filename   => $args{ filename },
         autoflush  => exists $args{ autoflush } ? $args{ autoflush } : 1,
        _fh         => undef,
    };

    my $fh = IO::File->new( ">> " . $self->{filename} );

    $fh->binmode( ":utf8" );

    $fh->autoflush( 1 );

    $self->{ _fh } = $fh;

    bless( $self, $class );
    
    return $self;
}

=head2 Instance Methods

=head3 level

Changes the log level for the current instance.

 $log->level( 3 );

=cut

sub level
{
    my ( $self, $arg ) = @_;
    $self->{ level } = $arg if defined $arg;
    return $self->{ level };
}

=head3 dumps

Controls whether references and objects are dumped or not.

 $log->dumps( 1 );

=cut

sub dumps
{
    my ( $self, $arg ) = @_;
    $self->{ dumps } = $arg if defined $arg;
    return $self->{ dumps };
}

=head3 dump_depth

Sets C<$Data::Dumper::Maxdepth>.

 $log->dump_depth( 3 );

=cut

sub dump_depth
{
    my ( $self, $arg ) = @_;
    $self->{ dump_depth } = $arg if defined $arg;
    return $self->{ dump_depth };
}

=head3 sort_keys

Sets C<$Data::Dumper::Sortkeys>.

 $log->sort_keys( 0 );

=cut

sub sort_keys
{
    my ( $self, $arg ) = @_;
    $self->{ sort_keys } = $arg if defined $arg;
    return $self->{ sort_keys };
}

=head3 quote_keys

Sets C<$Data::Dumper::Quotekeys>.

 $log->quote_keys( 0 );

=cut

sub quote_keys
{
    my ( $self, $arg ) = @_;
    $self->{ quote_keys } = $arg if defined $arg;
    return $self->{ quote_keys };
}


=head3 filename

Set the filename.

 $log->filename( 'foo.log' );

=cut

sub filename
{
    my ( $self, $arg ) = @_;
    $self->{ filename } = $arg if defined $arg;
    return $self->{ filename };
}

sub _fh
{
    my ( $self, $arg ) = @_;
    $self->{ _fh } = $arg if defined $arg;
    return $self->{ _fh };
}

=head3 autoflush

Set the autoflush on the filehandle.

 $log->autoflush( 1 );

=cut

sub autoflush
{
    my ( $self, $autoflush ) = @_;

    if ( defined $autoflush )
    {
        $self->{ autoflush } = $autoflush;

        $self->{ _fh }->autoflush( $self->{ autoflush } );
    }

    return $self->{ autoflush };
}

=head3 msg

 $log->msg(2, "Hello");

This method expects a log level as the first argument, followed by a list of log messages/references/objects.

This is the core method called by the following (preferred) methods, using the below mapping...

 TRACE => 5
 DEBUG => 4
 INFO  => 3
 WARN  => 2
 ERROR => 1
 FATAL => 0

=cut

sub msg
{
    my ( $self, $level, @things ) = @_;

    local $Data::Dumper::Maxdepth = $self->dump_depth;
    
    local $Data::Dumper::Sortkeys = $self->sort_keys;

    local $Data::Dumper::Quotekeys = $self->quote_keys;
    
    if ( $level !~ /^\d+$/ )
    {
        # bad log level, so push the 'level' to the 'things'
        $self->msg( FATAL, "LOG LEVEL MISSING (on the next line)" );
        unshift( @things, $level );
        $level = FATAL;
    }

    return $self if $level > $self->level;

    my $package = '-';
    my $sub = '-';
    my $line = 0;

    ( $package, undef, $line ) = caller( 1 );

    if ( caller( 2 ) )
    {
        ( undef, undef, undef, $sub ) = caller( 2 );
    }

    $sub =~ s/^.*::(.*?)$/$1/;
        
    ###################
    # prefix the line #
    ###################
    
    my ( $sec, $min, $hour, $day, $mon, $year, undef, undef, undef ) = localtime( time );

    $mon++;
    $mon =~ s/^(\d)$/0$1/;
    $day =~ s/^(\d)$/0$1/;
    $hour =~ s/^(\d)$/0$1/;
    $min =~ s/^(\d)$/0$1/;
    $sec =~ s/^(\d)$/0$1/;
    
    my $datetime = ( $year + 1900 ) . '/' . $mon . '/' . $day . ' ' . $hour . ':' . $min . ':' . $sec;
                                                
    my $prefix = join( ' ', $datetime, $$, $LEVELS{ $level }, $package, $sub, '(' . $line . ')' ) . ' - ';

    my $msg = '';

    foreach my $thing ( @things )
    {
        if ( my $label = ref $thing )
        {
#
# THIS WILL COME BACK INTO PLAY SOON
#
#           if ( $label eq 'CGI' )   # don't dump the whole CGI object
#           {
#               $msg .= "CGI Params...\n";
#               
#               my $max_param_length = 0;
#                               
#               foreach my $param ( $thing->param )
#               {
#                   $max_param_length = length($param) if length($param) > $max_param_length;
#               }
#                               
#               foreach my $param ( sort { $a cmp $b } grep { $_ !~ /\n/ } $thing->param )
#               {
#                   $msg .= "\t" . sprintf("%-*s", $max_param_length, $param) . " = " . $thing->param($param) . "\n";
#               } 
#
#               $msg .= "CGI URL Params...\n";
#               
#               $max_param_length = 0;
#                               
#               foreach my $param ( $thing->url_param )
#               {
#                   $max_param_length = length($param) if length($param) > $max_param_length;
#               }
#                               
#               foreach my $param ( sort { $a cmp $b } grep { $_ !~ /\n/ } $thing->url_param )
#               {
#                   $msg .= "\t" . sprintf("%-*s", $max_param_length, $param) . " = " . ( $thing->url_param($param) || '' ) . "\n";
#               } 
#
#               $msg .= "CGI Cookies...\n";
#               
#               my $max_cookie_length = 0;
#                               
#               foreach my $cookie ( $thing->cookie )
#               {
#                   $max_cookie_length = length($cookie) if length($cookie) > $max_cookie_length;
#               }
#
#               foreach my $cookie ( sort { $a cmp $b } $thing->cookie )
#               {
#                   $msg .= "\t" . sprintf("%-*s", $max_cookie_length, $cookie ) . " = " . ( $thing->cookie($cookie) || '' ) . "\n";
#               } 
#           }   
#           else
#           {
                if ( $self->dumps || $level == 0 )
                {
                    $Data::Dumper::Maxdepth = 9 if $level == 0;

                    $msg .= Dumper $thing;

                    $Data::Dumper::Maxdepth = $self->dump_depth;
                }
                else
                {
                    $msg .= $prefix . "NOT DUMPING [ " . $label . " ]";
                }
#           }
        }
        else
        {
            if ( defined $thing ) 
            {
                $msg .= $prefix . $thing;
            }
            else
            {
                $msg .= $prefix . '<< UNDEFINED LOG STATEMENT >>';
            }
        }
        
        $msg .= "\n" if $msg !~ /\n$/;
    }

    # we have to make a local copy of the fh for some reason  :-/

    my $fh = $self->_fh;

    print $fh $msg;

    return $self;
}

sub _flush
{
    my $self = shift;

    my $fh = $self->_fh;

    $fh->flush;

    return $self;
}

=head4 trace

 $log->trace( "Trace some info" );

A C<trace> statement is generally used for extremely low level logging, calling methods, getting into methods, etc.

=cut

sub trace
{
    my $self = shift;
    $self->msg( TRACE, @_ ) if $self->is_trace;
    return $self;
}

sub is_trace
{
    my $self = shift;
    return 1 if $self->level >= TRACE;
    return 0;
}

=head4 debug

 $log->debug( "Debug some info" );

=cut

sub debug
{
    my $self = shift;

    if ( scalar( @_ ) == 1 && $_[ 0 ] =~ /^#/ && $_[ 0 ] =~ /#$/ )
    {
        $self->msg( DEBUG, '#' x length( $_[ 0 ] ) ) if $self->is_debug;
        $self->msg( DEBUG, @_ ) if $self->is_debug;
        $self->msg( DEBUG, '#' x length( $_[ 0 ] ) ) if $self->is_debug;
    }
    else
    {
        $self->msg( DEBUG, @_ ) if $self->is_debug;
    }
    return $self;
}

sub is_debug
{
    my $self = shift;
    return 1 if $self->level >= DEBUG;
    return 0;
}


=head4 info

 $log->info( "Info about something" );

=cut

sub info
{
    my $self = shift;
    $self->msg( INFO, @_ ) if $self->is_info;
    return $self;
}

sub is_info
{
    my $self = shift;
    return 1 if $self->level >= INFO;
    return 0;
}

=head4 warn

 $log->warn( "Something not quite right here" );

=cut

sub warn
{
    my $self = shift;
    $self->msg( WARN, @_ ) if $self->is_warn;
    return $self;
}

sub is_warn
{
    my $self = shift;
    return 1 if $self->level >= WARN;
    return 0;
}

=head4 error

 $log->error( "Something went wrong" );

=cut

sub error
{
    my $self = shift;
    $self->msg( ERROR, @_ ) if $self->is_error;
    return $self;
}

sub is_error
{
    my $self = shift;
    return 1 if $self->level >= ERROR;
    return 0;
}

=head4 fatal

 $log->fatal( "Looks like we died" );

=cut

sub fatal
{
    my $self = shift;
    $self->msg( FATAL, @_ ) if $self->is_fatal;
    return $self;
}

sub is_fatal
{
    my $self = shift;
    return 1 if $self->level >= FATAL;
    return 0;
}


=head1 TODO

simple scripts (the caller stack)

extend to use variations of Data::Dumper




=head1 AUTHOR

Rob Brown, C<< <rob at intelcompute.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-log-autodump at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-AutoDump>.  I will be notified, and then you will
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log::AutoDump


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-AutoDump>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Log-AutoDump>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Log-AutoDump>

=item * Search CPAN

L<http://search.cpan.org/dist/Log-AutoDump/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Rob Brown.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Log::AutoDump
