package Log::Any::Adapter::Syslog;
use strict;
use warnings;

# ABSTRACT: Send Log::Any logs to syslog
our $VERSION = '1.6'; # VERSION

use Log::Any::Adapter::Util qw{make_method};
use base qw{Log::Any::Adapter::Base};

use Unix::Syslog qw{:macros :subs};
use File::Basename ();

my $log_params;


# Build log level priorities
my @logging_methods = Log::Any->logging_methods;
our %logging_levels;
for my $i (0..@logging_methods-1) {
    $logging_levels{$logging_methods[$i]} = $i;
}
# some common typos
$logging_levels{warn} = $logging_levels{warning};
$logging_levels{inform} = $logging_levels{info};
$logging_levels{err} = $logging_levels{error};

sub _min_level {
    my $self = shift;

    return $ENV{LOG_LEVEL}
        if $ENV{LOG_LEVEL} && defined $logging_levels{$ENV{LOG_LEVEL}};
    return 'trace' if $ENV{TRACE};
    return 'debug' if $ENV{DEBUG};
    return 'info'  if $ENV{VERBOSE};
    return 'error' if $ENV{QUIET};
    return 'trace';
}

# When initialized we connect to syslog.
sub init {
    my ($self) = @_;

    $self->{name}     ||= File::Basename::basename($0) || 'perl';
    $self->{options}  ||= LOG_PID;
    $self->{facility} ||= LOG_LOCAL7;
    $self->{min_level}||= $self->_min_level;

    # We want to avoid re-opening the syslog unnecessarily, so only do it if
    # the parameters have changed.
    my $new_params = $self->_log_params;
    if ((not defined $log_params) or ($log_params ne $new_params)) {

        $log_params = $new_params;
        openlog($self->{name}, $self->{options}, $self->{facility});
    }

    return $self;
}

sub _log_params {
    my ($self) = @_;
    return sprintf('%d,%d,%s',
        $self->{options}, $self->{facility}, $self->{name});
}

# Create logging methods: debug, info, etc.
foreach my $method (Log::Any->logging_methods()) {
    my $priority = {
        trace     => LOG_DEBUG,
        debug     => LOG_DEBUG,
        info      => LOG_INFO,
        inform    => LOG_INFO,
        notice    => LOG_NOTICE,
        warning   => LOG_WARNING,
        warn      => LOG_WARNING,
        error     => LOG_ERR,
        err       => LOG_ERR,
        critical  => LOG_CRIT,
        crit      => LOG_CRIT,
        fatal     => LOG_CRIT,
        alert     => LOG_ALERT,
        emergency => LOG_EMERG,
    }->{$method};
    defined($priority) or $priority = LOG_ERR; # unknown, take a guess.

    make_method($method, sub {
        my $self = shift;
        return if $logging_levels{$method} <
                $logging_levels{$self->{min_level}};

        syslog($priority, '%s', join('', @_))
    });
}

# Create detection methods: is_debug, is_info, etc.
foreach my $method (Log::Any->detection_methods()) {
    my $level = $method; $level =~ s/^is_//;
    make_method($method, sub {
        my $self = shift;
        return $logging_levels{$level} >= $logging_levels{$self->{min_level}};
    });

}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Adapter::Syslog - Send Log::Any logs to syslog

=head1 VERSION

version 1.6

=head1 SYNOPSIS

    use Log::Any::Adapter;
    Log::Any::Adapter->set('Syslog');

    # You can override defaults:
    use Unix::Syslog qw{:macros};
    Log::Any::Adapter->set(
        'Syslog',
        # name defaults to basename($0)
        name     => 'my-name',
        # options default to LOG_PID
        options  => LOG_PID|LOG_PERROR,
        # facility defaults to LOG_LOCAL7
        facility => LOG_LOCAL7
    );

=head1 DESCRIPTION

L<Log::Any> is a generic adapter for writing logging into Perl modules; this
adapter use the L<Unix::Syslog> module to direct that output into the standard
Unix syslog system.

=head1 CONFIGURATION

C<Log::Any::Adapter::Syslog> is designed to work out of the box with no
configuration required; the defaults should be reasonably sensible.

You can override the default configuration by passing extra arguments to the
C<Log::Any::Adapter> method:

=over

=item name

The I<name> argument defaults to the basename of C<$0> if not supplied, and is
inserted into each line sent to syslog to identify the source.

=item options

The I<options> configure the behaviour of syslog; see L<Unix::Syslog> for
details.

The default is C<LOG_PID>, which includes the PID of the current process after
the process name:

    example-process[2345]: something amazing!

The most likely addition to that is C<LOG_PERROR> which causes syslog to also
send a copy of all log messages to the controlling terminal of the process.

B<WARNING:> If you pass a defined value you are setting, not augmenting, the
options.  So, if you want C<LOG_PID> as well as other flags, pass them all.

=item facility

The I<facility> determines where syslog sends your messages.  The default is
C<LOCAL7>, which is not the most useful value ever, but is less bad than
assuming the fixed facilities.

See L<Unix::Syslog> and L<syslog(3)> for details on the available facilities.

=item min_level

Minimum syslog level. All messages below the selected level will be silently
discarded. Default is debug.

If LOG_LEVEL environment variable is set, it will be used instead. If TRACE
environment variable is set to true, level will be set to 'trace'. If DEBUG
environment variable is set to true, level will be set to 'debug'. If VERBOSE
environment variable is set to true, level will be set to 'info'.If QUIET
environment variable is set to true, level will be set to 'error'.

=back

=head1 AUTHORS

=over 4

=item *

Daniel Pittman <daniel@rimspace.net>

=item *

Stephen Thirlwall <sdt@cpan.org>

=back

=head1 CONTRIBUTOR

=for stopwords Maros Kollar

Maros Kollar <maros.kollar@geizhals.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Stephen Thirlwall.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
