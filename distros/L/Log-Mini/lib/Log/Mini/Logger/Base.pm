package Log::Mini::Logger::Base;

use strict;
use warnings;

use Carp qw(croak);
use Time::HiRes;


my $LEVELS = {
    error => 1,
    warn  => 2,
    info  => 3,
    debug => 4,
    trace => 5,
};

sub new
{
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{'level'} = $params{'level'} || 'error';

    return $self;
}

sub set_level
{
    my $self = shift;
    my ($new_level) = @_;

    croak('Unknown log level')
      unless $LEVELS->{$new_level};

    $self->{'level'} = $new_level;

    return 1;
}

sub level
{
    my $self = shift;

    return $self->{level} || 'error';
}

sub log   { return shift->_log(@_) }
sub info  { return shift->_log('info',  @_) }
sub error { return shift->_log('error', @_) }
sub warn  { return shift->_log('warn',  @_) }
sub debug { return shift->_log('debug', @_) }
sub trace { return shift->_log('trace', @_) }

sub _log
{
    my $self    = shift;
    my $level   = shift;
    my $message = shift;

    return if $LEVELS->{$level} > $LEVELS->{$self->{'level'}};
    
    my $text = sprintf("%s [%s] %s\n", $self->_getCurrentTime(), $level, $message);
    $text = sprintf($text, @_) if (@_);

    $self->_print($text);

    return 1;
}

sub _print { croak 'Not implemented!' }

sub _getCurrentTime
{
    my ($seconds, $miliseconds) = Time::HiRes::gettimeofday();

    my ($sec,$min,$hour,$mday,$mon,$year) = localtime($seconds);

    return sprintf('%i-%02i-%02i %02i:%02i:%02i.%03i', 1900+$year, $mon, $mday, $hour, $min, $sec, substr($miliseconds, 0, 3));
}

1;
