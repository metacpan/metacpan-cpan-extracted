=head1 NAME

DynGig::Automata::MapReduce - Sequential map/reduce automation framework.
Extends DynGig::Automata::Serial.

=cut
package DynGig::Automata::MapReduce;

use base DynGig::Automata::Serial;

use warnings;
use strict;
use Carp;

use File::Spec;

use DynGig::Automata::EZDB::Exclude;

sub new
{
    my ( $class, $name ) = @_;

    croak 'undefined/invalid name' if ! defined $name || ref $name;

    bless DynGig::Automata::Serial->new
    (
        name => $name,
        queue => _MapReduce->queue( File::Spec->join( 'conf', $name ) ),
    );
}

sub setup
{
    my $this = DynGig::Automata::Serial::setup( @_ );

    $this->{_run}{exclude} ||= DynGig::Automata::EZDB::Exclude->new
    (
        $this->file( 'exclude' ),
        table => [ DynGig::Automata::Serial::GLOBAL, $this->job() ],
    );

    return $this;
}

sub run
{
    my ( $this, %param ) = @_;
    my $error = 'invalid context';
##  context
    croak "$error: not defined" unless my $context = $param{context};
    croak "$error: not HASH" if ref $context ne 'HASH';

    for my $key ( 'global', map { $_->{name} } @{ $this->{queue} } )
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
##  prepare
    $this->setup();

    my $run = $this->{_run};

    $run->{logger} ||= DynGig::Util::Logger->new();
    $run->{context} = $context;

    my $exclude = $run->{exclude};
    my $logger = sub { $run->{logger}->write( @_ ) };
    my %context = map { $_ => $context->{$_} } qw( transient global );
##  sequence
    for my $job ( @{ $this->{queue} } )
    {
        my $name = $job->{name};
        my %param = 
        (
            job => $name,
            exclude => $exclude,
            name => $this->{name},
        );

        map { $exclude->expire( $_ ) } DynGig::Automata::Serial::GLOBAL, $name;

        my ( $status, $result ) = $this->_eval
        (
            $job,
            param => \%param,
            logger => $logger,
            context => +{ %context, glocal => $context->{ $name } },
        );

        croak $result if $status != DynGig::Automata::Serial::OK;
    }

    delete $context->{transient};
}

package _MapReduce;

use warnings;
use strict;
use Carp;

use YAML::XS;

use DynGig::Util::Time;
use DynGig::Util::MapReduce;

use constant { PRECISION => 30 };

sub queue
{
    my ( $class, $conf ) = @_;
    my ( @queue, %job );
    my $error = 'invalid queue config';

    for my $param ( YAML::XS::LoadFile $conf )
    {
        croak $error unless $param && ref $param eq 'HASH';

        my $name = $param->{name};

        croak "$error: invalid/undefined name" if ! defined $name || ref $name;
        croak "$error: name collision '$name'" if $job{$name};

        $param->{name} = $job{$name} = "job.$name";

        my %param =
        (
            interval => DynGig::Util::Time->rel2sec( $param->{interval} ),
            job => DynGig::Util::MapReduce->new( _param( %$param ) ),
        );

        push @queue, { param => \%param, name => $job{$name}, code => \&_code };
    }

    return \@queue;
}

sub _param
{
    my %param = @_;
    my $error = "invalid job config $param{name}";

    for my $key ( qw( batch map reduce ) )
    {
        my $plugin = $param{$key};

        unless ( defined $plugin )
        {
            next if $key eq 'reduce';
            croak "$error: undefined $key";
        }

        croak "$error: invalid $key " . ( $@ || '' ) if ref $plugin ne 'HASH'
            || ref ( $plugin->{code} = do $plugin->{code} ) ne 'CODE'
            || ref ( $plugin->{param} ||= {} ) ne 'HASH';

        $plugin->{timeout} = DynGig::Util::Time->rel2sec( $plugin->{timeout} );
    }

    return %param;
}

sub _code
{
    my %param = @_;
    my $job = $param{job};
    my $logger = $param{logger};
    my $context = $param{context};
    my $glocal = $context->{glocal};
    my $global = $context->{global};
    my $name = $job->name();
    my $time = time;
    my $delta = 0;

    if ( my $interval = $param{interval} )
    {
        unless ( my $last = $glocal->{timestamp} )
        {
            $delta = $interval;
        }
        elsif ( ( $delta = $last + $interval - $time ) > PRECISION )
        {
            goto DONE;
        }
        elsif ( $delta < 0 )
        {
            &$logger( 'OVERDUE: %s for %d seconds', $name, -$delta )
                if -$delta > PRECISION;

            $delta = 0;
        }
    }

    my %context = ( $name => $glocal, global => $global->{$name} ||= {} );

    &$logger( 'START: %s', $name );

    $job->run
    (
        context => \%context,
        map { $_ => $param{param} } qw( batch reduce ),
    );

    &$logger( 'DONE: %s', $name );

    $glocal->{timestamp} = $time;
    DONE: $glocal->{due} = $delta;
}

=head1 NOTE

See DynGig::Automata

=cut

1;

__END__
