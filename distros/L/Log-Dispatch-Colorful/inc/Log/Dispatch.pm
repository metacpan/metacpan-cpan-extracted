#line 1
package Log::Dispatch;

use 5.006;

use strict;
use warnings;

use base qw( Log::Dispatch::Base );

use Carp ();

our $VERSION = '2.22';
our %LEVELS;


BEGIN
{
    foreach my $l ( qw( debug info notice warning err error crit critical alert emerg emergency ) )
    {
        my $sub = sub { my $self = shift;
                        $self->log( level => $l, message => "@_" ); };

        $LEVELS{$l} = 1;

        no strict 'refs';
        *{$l} = $sub
    }
}

sub new
{
    my $proto = shift;
    my $class = ref $proto || $proto;
    my %p = @_;

    my $self = bless {}, $class;

    my @cb = $self->_get_callbacks(%p);
    $self->{callbacks} = \@cb if @cb;

    return $self;
}

sub add
{
    my $self = shift;
    my $object = shift;

    # Once 5.6 is more established start using the warnings module.
    if (exists $self->{outputs}{$object->name} && $^W)
    {
        Carp::carp("Log::Dispatch::* object ", $object->name, " already exists.");
    }

    $self->{outputs}{$object->name} = $object;
}

sub remove
{
    my $self = shift;
    my $name = shift;

    return delete $self->{outputs}{$name};
}

sub log
{
    my $self = shift;
    my %p = @_;

    return unless $self->would_log( $p{level} );

    $self->_log_to_outputs( $self->_prepare_message(%p) );
}

sub _prepare_message
{
    my $self = shift;
    my %p = @_;

    $p{message} = $p{message}->()
        if ref $p{message} eq 'CODE';

    $p{message} = $self->_apply_callbacks(%p)
        if $self->{callbacks};

    return %p;
}

sub _log_to_outputs
{
    my $self = shift;
    my %p = @_;

    foreach (keys %{ $self->{outputs} })
    {
        $p{name} = $_;
        $self->_log_to(%p);
    }
}

sub log_and_die
{
    my $self = shift;

    my %p = $self->_prepare_message(@_);

    $self->_log_to_outputs(%p) if $self->would_log($p{level});

    $self->_die_with_message(%p);
}

sub log_and_croak
{
    my $self = shift;

    $self->log_and_die( @_, carp_level => 3 );
}

sub _die_with_message
{
    my $self = shift;
    my %p = @_;

    my $msg = $p{message};

    local $Carp::CarpLevel = ($Carp::CarpLevel || 0) + $p{carp_level}
	if exists $p{carp_level};

    Carp::croak($msg);
}

sub log_to
{
    my $self = shift;
    my %p = @_;

    $p{message} = $self->_apply_callbacks(%p)
        if $self->{callbacks};

    $self->_log_to(%p);
}

sub _log_to
{
    my $self = shift;
    my %p = @_;
    my $name = $p{name};

    if (exists $self->{outputs}{$name})
    {
        $self->{outputs}{$name}->log(@_);
    }
    elsif ($^W)
    {
        Carp::carp("Log::Dispatch::* object named '$name' not in dispatcher\n");
    }
}

sub output
{
    my $self = shift;
    my $name = shift;

    return unless exists $self->{outputs}{$name};

    return $self->{outputs}{$name};
}

sub level_is_valid
{
    shift;
    return $LEVELS{ shift() };
}

sub would_log
{
    my $self = shift;
    my $level = shift;

    return 0 unless $self->level_is_valid($level);

    foreach ( values %{ $self->{outputs} } )
    {
        return 1 if $_->_should_log($level);
    }

    return 0;
}


1;

__END__

#line 523
