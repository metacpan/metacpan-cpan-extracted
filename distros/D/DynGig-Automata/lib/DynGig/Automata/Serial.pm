=head1 NAME

DynGig::Automata::Serial - Process targets in serial batches.
Each batch of targets is processed in sequential steps specified by the user.

=cut
package DynGig::Automata::Serial;

use warnings;
use strict;
use Carp;

use YAML::XS;
use File::Spec;

use DynGig::Util::Logger;
use DynGig::Util::LockFile::Time;
use DynGig::Automata::EZDB::Alert;

use constant { OK => 0, ERROR => 1, GLOBAL => 'global', KILL => 3600 * 240 };

sub new
{
    my ( $class, %this ) = @_;
    my ( %dir, %file );
    my $name = $this{name};
    my $queue = $this{queue};
    my $error = 'invalid config';

    croak "$error: undefined/invalid name" if ! defined $name || ref $name;

    croak "$error: undefined/invalid queue" if ! defined $queue
        || ref $queue ne 'ARRAY' || grep { ! defined $_ } @$queue;

    for my $job ( @$queue, @this{ qw( target begin end ) } )
    {
        next unless $job;

        croak $error if ref $job ne 'HASH';

        croak "$error: undefined/invalid name"
            if ! defined $job->{name} || ref $job->{name};

        croak "$error: undefined/invalid code"
            if ! defined $job->{code} || ref $job->{code} ne 'CODE';

        $job->{param} ||= {};
        map { $job->{$_} ||= 0 } qw( redo retry timeout );
    }
##  create directories
    map { croak "invalid directory $_ " unless $dir{$_} = Cwd::abs_path( $_ ) }
        qw( run param );

    map { $file{$_} = File::Spec->join( $dir{run}, "$name.$_" ) }
        qw( log alert pause );

    bless +{ %this, _dir => \%dir, _file => \%file }, ref $class || $class;
}

sub run
{
    my ( $this, %param ) = @_;
    my $error = 'invalid context';
##  context
    croak "$error: not defined" unless my $context = $param{context};
    croak "$error: not HASH" if ref $context ne 'HASH';

    my @key = ( 'global', map { $_->{name} } @{ $this->{queue} } );

    map { push @key, $_ if defined $this->{$_} } qw( target begin end );

    for my $key ( @key )
    {
        unless ( defined $context->{$key} )
        {
            $context->{$key} = {};
        }
        elsif ( ref $context->{$key} ne 'HASH' )
        {
            croak "$error: $key not HASH";
        }
    }

    $context->{transient} = {};
    my $run = $this->{_run} = { context => $context };
##  prepare
    $this->_prepare( %param );
##  alert db
    $run->{alert} ||= DynGig::Automata::EZDB::Alert->new
    (
        $this->{_file}{alert}, table => [ GLOBAL ],
    );

    my $name = $this->{name};
    my $logger = $run->{logger};
##  begin
    $logger->write( 'START: sequence %s', $name );
    $this->_job( $this->{begin} );
##  sequence
    while ( my @target = $this->_job( $this->{target} ) )
    {
        $logger->write( 'TARGET: %s', YAML::XS::Dump \@target );

        for my $job ( @{ $this->{queue} } )
        {
            $logger->write( 'START: %s', $job->{name} );
            $this->_job( $job, target => \@target );
            $logger->write( 'DONE: %s', $job->{name} );
        }
    }
##  end
    $this->_job( $this->{end} );
    $logger->write( 'DONE: sequence %s', $name );

    delete $context->{transient};
}

sub file
{
    my ( $this, $ext ) = @_;
    return File::Spec->join( $this->{_dir}{run}, $this->{name} . '.' . $ext );
}

sub job
{
    my $this = shift @_;
    my @job = map { $_->{name} } @{ $this->{queue} };

    return wantarray ? @job : \@job;
}

sub setup
{
    my $this = shift @_;
    my $run = $this->{_dir}{run};

    croak "mkdir $run: $!" unless -d $run || mkdir $run, 0755;
    return $this;
}

sub AUTOLOAD
{
    my $this = shift @_;
    my $run = $this->{_run};

    return our $AUTOLOAD =~ /::(\w+)$/ && $run ? $run->{$1} : undef;
}

sub _prepare
{
    my ( $this, %param ) = @_;

    $this->setup();

    my $log = $param{log};
    my $file = $this->{_file};
    my $run = $this->{_run};

    map { unlink $_ if -e $_ } values %$file;

    $run->{param} = {};
    $run->{logger} = DynGig::Util::Logger->new( %param );

    symlink $log, $file->{log} if defined $log && -e $log;
}

sub _eval  ##  run plugin code
{
    my ( $this, $job, %param ) = @_;
    my ( $status, @result ) = OK;

    eval
    {
        my $timeout = $job->{timeout};
        local $SIG{ALRM} = sub { die "timeout after $timeout seconds\n" };

        alarm $timeout;
        @result = &{ $job->{code} }( %{ $job->{param} }, %param );
        alarm 0;
    };

    if ( $@ )
    {
        $status = ERROR;
        @result = $@;
    }

    return $status, @result;
}

sub _job
{
    my ( $this, $job, %param ) = @_;

    return unless $job;

    my ( $retry, @result );
    my $name = $job->{name};
    my $run = $this->{_run};
    my $alert = $run->{alert};
    my $logger = $run->{logger};
    my $context = $run->{context};
    my %logger = ( logger => sub { $logger->write( @_ ) } );
    my %context = map { $_ => $context->{$_} } qw( transient global );
    
    $context{glocal} = $context->{ $name };

    while ( 1 )
    {
        my $stuck;

        while ( 1 )  ##  stuck on alert or pause
        {
            my $pause =
                DynGig::Util::LockFile::Time->check( $this->{_file}{pause} );

            unless ( $pause )
            {
                last unless my %alert = $alert->dump( GLOBAL );
                $stuck = -1;
            }
            elsif ( $pause >= KILL )
            {
                $logger->write( 'KILL: %s', $name );
                $alert->truncate( GLOBAL );

                return;
            }
            elsif ( $stuck <= 0 )
            {
                $logger->write( 'PAUSE: %s', $name );
                $stuck = $pause;
            }

            sleep 10;
        }

        if ( $stuck )
        {
            $logger->write( 'RESUME: %s', $name );

            if ( $stuck < 0 )
            {
                last unless $job->{redo};
                $retry = 0;  ##  redo & reset counter
            } 
        }

        @result = $this->_eval
        (
            $job, %{ $this->_param( $name ) }, %param, %logger,
            context => \%context,
        );

        last if OK == shift @result;

        if ( $retry ++ < $job->{retry} )
        {
            $logger->write( 'RETRY %d: %s << %s', $retry, $name, $result[0] );
        }
        else
        {
            $alert->set( GLOBAL, $name, $result[0] );
            $logger->write( 'ALERT: %s << %s', $name, $result[0] );
        }
    }

    return @result;
}

sub _param  ##  load param from file
{
    my ( $this, $name ) = @_;
    my $file = File::Spec->join( $this->{_dir}{param}, $name );

    return {} unless open my $handle, '<', $file;

    my $time = ( stat $handle )[9];
    my $param = $this->{_run}{param}{$name} ||= {};

    unless ( $param->{$time} )
    {
        my $override = eval { YAML::XS::LoadFile $handle };

        map { delete $param->{$_} } keys %$param;
        $param->{$time} = $@ && ref $override ne 'HASH' ? {} : $override;
    }

    close $handle;
    return $param->{$time};
}

=head1 NOTE

See DynGig::Automata

=cut

1;

__END__
