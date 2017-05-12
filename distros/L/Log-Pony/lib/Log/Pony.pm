package Log::Pony;
use strict;
use warnings;
use utf8;
use 5.008005;
our $VERSION = '1.0.1';
use Carp ();
use Term::ANSIColor ();
use Class::Accessor::Lite (
    ro => [qw/color log_level/],
);

our $TRACE_LEVEL = 0;

__PACKAGE__->set_levels(qw( debug           info     warn               critical        error));
__PACKAGE__->set_colors(   'red on_white', 'green', 'black on_yellow', 'black on_red', 'red on_black');

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    my $log_level = delete $args{log_level}
            or Carp::croak("Missing mandatory parameter: log_level");
       $log_level = uc($log_level);
    my $color     = delete $args{color} || 0;
    my $self = bless {
        log_level   => $log_level,
        log_level_n => $class->level_to_number($log_level),
        color       => $color,
    }, $class;
    $self->init(%args);
    return $self;
}

sub init { }

sub set_colors {
    my ($class, @colors) = @_;
    no strict 'refs';
    *{"${class}::colors"} = sub { @colors };
}

sub colorize {
    my ($self, $level, $message) = @_;
    my $n = $self->level_to_number($level);
    my @colors = $self->colors();
    my $color = $colors[$n] || $colors[-1];
    return Term::ANSIColor::colored([$color], $message);
}

sub log {
    my ($self, $level, $format, @args) = @_;
    return if $self->level_to_number($level) < $self->{log_level_n};
    local $TRACE_LEVEL = $TRACE_LEVEL + 1;
    $self->process($level, $self->sanitize(sprintf($format, @args)));
}

sub trace_info {
    my $self = shift;
    my @caller  = caller($TRACE_LEVEL+1);
    return "at $caller[1] line $caller[2]";
}

sub sanitize {
    my ($self, $message) = @_;
    $message =~ s/\x0a\z//g;
    $message =~ s/\x0d/\\r/g;
    $message =~ s/\x0a/\\n/g;
    $message =~ s/\x09/\\t/g;
    return $message;
}

sub time {
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime(time);
    return sprintf( "%04d-%02d-%02dT%02d:%02d:%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec );
}

sub process {
    my ($self, $level, $message) = @_;
    my $time = $self->time();
    my $trace = $self->trace_info();
    if ($self->color) {
        $message = $self->colorize($level, $message);
    }
    print STDERR "$time [$level] $message $trace\n";
}

sub info {
    my $self = shift;
    local $TRACE_LEVEL = $TRACE_LEVEL + 1;
    $self->log(INFO => @_);
}

sub warn {
    my $self = shift;
    local $TRACE_LEVEL = $TRACE_LEVEL + 1;
    $self->log(WARN => @_);
}

sub critical {
    my $self = shift;
    local $TRACE_LEVEL = $TRACE_LEVEL + 1;
    $self->log(CRITICAL => @_);
}

sub debug {
    my $self = shift;
    local $TRACE_LEVEL = $TRACE_LEVEL + 1;
    $self->log(DEBUG => @_);
}

sub set_levels {
    my ($class, @levels) = @_;
    my $i = 1;
    my %levels = map { uc($_) => $i++ } @levels;
    for my $level (@levels) {
        unless ($class->can($level)) {
            $class->mk_level_accessor($level);
        }
    }
    no strict 'refs';
    *{"${class}::level_to_number"} = sub {
        my ($class, $level) = @_;
        my $number = $levels{uc $level}
            or Carp::croak("Unknown logging level: $level");
        return $number;
    };
}

sub mk_level_accessor {
    my ($class, $level) = @_;
    my $LEVEL = uc($level);
       $level = lc($level);
    no strict 'refs';
    *{"${class}::${level}"} = sub {
        my $self = shift;
        local $TRACE_LEVEL = $TRACE_LEVEL + 1;
        $self->log($LEVEL => @_);
    };
}

1;
__END__

=encoding utf8

=head1 NAME

Log::Pony - Yet another simple logger class

=head1 SYNOPSIS

    my $logger = Log::Pony->new(
        log_level => $ENV{MYAPP_LOG_LEVEL} || 'info',
    );
    $logger->info("Payed by her");
    $logger->warn("A unexpected things happend!");
    $logger->critical("Ouch! Disk full!");
    $logger->debug("Through here...");

=head1 DESCRIPTION

Log::Pony is simple logger class.

B<THIS IS A DEVELOPMENT RELEASE. API MAY CHANGE WITHOUT NOTICE>.

Log::Pony provides

=over 4

=item Flexible logging level

=item Flexible output

=back

=head1 MOTIVATION

I need a simple, flexible, OO-ish, customizable, and thin logger class, but I can't find any module on CPAN.

=head1 METHODS

=over 4

=item my $logger = Log::Pony->new(%args)

Create new Log::Pony instance.

Mandatory parameter for this method is B<log_level>.
You can on specify the log level by constructor.

Optionaly, you can pass B<color> parameter.
It enables colorize for default C<< $logger->process >> method.
You can access this parameters value by C<< $logger->color() >>.

And other parameters passed to C<< $logger->init(%args) >> method.

=item my $level = $logger->log_level() : Str

Get a current log level in string.

=item $logger->color() : Bool

Returns color parameter passed at constructor.

=item $logger->log($level, $format, @args);

This method format log message by sprintf by $format and @args.

And output log by C<< $logger->process($level, $message) >>.

=item $logger->debug(@msg)

Shorthand for C<< $logger->log('DEBUG', @msg) >>.

=item $logger->info(@msg)

Shorthand for C<< $logger->log('INFO', @msg) >>.

=item $logger->warn(@msg)

Shorthand for C<< $logger->log('WARN', @msg) >>.

=item $logger->critical(@msg)

Shorthand for C<< $logger->log('CRITICAL', @msg) >>.

=back

=head1 EXTEND THIS CLASS

You can extend this class by inheritance.

=over 4

=item Hook C<< $logger->init(%args) >>

You can hook C<< $logger->init(%args) >>.

This method is a hook point to extend your logger class.
Default implementation of this method does no operation.

Here is an example code:

    pckage My::Logger;
    use parent qw/Log::Pony/;

    sub init {
        my ($self, %args) = @_;
        my $rotate_logs = File::RotateLogs->new(
            %args
        );
        $self->{rotate_logs} = $rotate_logs;
    }

    sub process {
        my ($self, $level, $message) = @_;
        $self->{rotate_logs}->print($message);
    }

Log::Pony pass arguments without 'log_level' to C<< $logger->init >>.
You can setup your logger class at this hook point.

=item C<< $logger->process($level, $message) >>

The method to output log message to any device.
You can output, e-mailing, send to syslog, or string to DB at this point.

Default implementation is here:

    sub process {
        my ($self, $level, $message) = @_;
        my $time = $self->time();
        my $trace = $self->trace_info();
        print STDERR "$time [$level] $message $trace\n";
    }

You can call following methods to get information:

=over 4

=item $self->time()

Get a current time in localtime in following format;

    2004-04-01T12:00:00

=item $self->trace_info()

Get a trace information in following format:

    at my/script.pl line 15

You can add this trace information folloing log message, then
you can debug more easily.

=item $self->colorize($level: Str, $message: Str) : Str

Colorize your message for readability.

C<< $level >> is string indicates level name.
C<< $message >> is string to colorize.

I<Return value>: Colorized $message.

=back

=back

=head1 CUSTOMIZING LOGGING LEVELS

You can customize logging level by following methods.

You need to inherit from Log::Pony to customize logging level.

=over 4

=item MyLogger->set_levels(@levels);

    MyLogger->set_levels(qw/debug info warn crit emergency/);

You can set levels by this method.

You need pass the levels as first is whatever thing, last is important.

This methods non existent method automatically.
In this case, you can call C<< $logger->emergency($msg) >> method after this definition.

=item MyLogger->set_colors(@colors);

    __PACKAGE__->set_colors(   'red on_white', 'green', 'black on_yellow', 'black on_red', 'red on_black');

Set colors for each levels. You should put order of colors are same as levels.

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

L<Log::Dispatch>, L<Log::Minimal>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
