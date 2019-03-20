package Log::Mini::LoggerBase;

use strict;
use warnings;

use Carp qw(croak);
use List::Util qw(first);
use Time::Moment;

use Data::Dumper;
use feature qw/say/;

my $LEVELS = {
    error => 1,
    warn  => 2,
    info  => 3,
    debug => 4,
    trace => 5
};

sub new {

    # say STDERR Dumper(\@_);
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{'level'} = $params{'level'} || 'error';

    return $self;
}

sub set_level {
    my $self = shift;
    my ($new_level) = @_;

    croak('Unknown log level')
      unless first { $new_level eq $_ } keys %$LEVELS;

    $self->{'level'} = $new_level;

    return;
}

sub level {
    my $self = shift;

    return $self->{level} || 'error';
}

sub log   { return shift->_log( shift, @_) }
sub info  { return shift->_log( 'info',  @_ ) }
sub error { return shift->_log( 'error', @_ ) }
sub warn  { return shift->_log( 'warn',  @_ ) }
sub debug { return shift->_log( 'debug', @_ ) }
sub trace { return shift->_log( 'trace', @_ ) }

sub _log {
    my $self = shift;
    my $level = shift;
    my $message = shift;

    return if $LEVELS->{$level} > $LEVELS->{ $self->{'level'} };

    my $time = Time::Moment->now->strftime('%Y-%m-%d %T%3f');

    my $text = sprintf("%s [%s] %s\n", $time, $level, $message);
    $text = sprintf($text, @_) if (@_);

    $self->_print($text);

    return;
}

sub _print { croak 'Not implemented!' }

1;
