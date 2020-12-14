package Log::Any::Adapter::Journal;

# ABSTRACT: Adapter for Log::Any that outputs with a priority prefix that systemd's journal can parse

use 5.010;
use strict;
use warnings;

use Log::Any::Adapter::Util qw(logging_methods numeric_level);
use parent 'Log::Any::Adapter::Screen';
use Class::Method::Modifiers;

our $VERSION = '1.0';

# sub init {
#     my ($self) = @_;
# }

# For each of the logging methods exposed by Log::Any, add the level
# prefix in angled brackets.
for my $method ( logging_methods ) {
    my $level = numeric_level( $method );

    # Journal doesn't recognize trace (8), print as debug instead
    $level = 7 if $level > 7;

    before $method => sub {
        $_[1] = "<$level>$_[1]" unless $_[0]->{use_color};
    };
}

# Log::Any levels       Journal levels
# 0 emergency           0 emerg
# 1 alert               1 alert
# 2 critical            2 crit
# 3 error               3 err
# 4 warning             4 warning
# 5 notice              5 notice
# 6 info                6 info
# 7 debug               7 debug
# 8 trace

1;

__END__

=pod

=head1 NAME

Log::Any::Adapter::Journal - Adapter for Log::Any that outputs with a priority prefix that systemd's journal can parse

=head1 VERSION

version 1.0

=head1 STATUS

=for html <a href="https://travis-ci.org/mvgrimes/Log-Any-Adapter-Journal"><img src="https://travis-ci.org/mvgrimes/Log-Any-Adapter-Journal.svg?branch=master" alt="Build Status"></a>
<a href="https://metacpan.org/pod/Log::Any::Adapter::Journal"><img alt="CPAN version" src="https://badge.fury.io/pl/Log-Any-Adapter-Journal.svg" /></a>

=head1 SYNOPSIS

    use Log::Any::Adapter;
    Log::Any::Adapter->set( 'Journal', 
        # min_level => 'debug', # default is 'warning'
        # colors    => { }, # customize colors
        # use_color => 1, # force color even when not interactive
        # stderr    => 0, # print to STDOUT instead of the default STDERR
        # formatter => sub { "LOG: $_[1]" }, # default none
    );

=head1 DESCRIPTION

When sending log messages to systemd's journal, the priority can be set by
prefixing the message with the priority (as a number) in angled brackets.
This adapter will format L<Log::Any> messages to accomodate the systemd's log
parser.

By default, systemd will parse the output from commands run as systemd
services/units for the priority prefix (both STDOUT and STDERR). Users can
also pipe output through the C<systemd-cat> command to enable parsing of
priority for scripts.

Journald doesn't support the trace (8) log level. If the min_level is set to
'trace', then logs will be sent to journald with the debug (7) log level.
This behavior changed in version 1.0 of L<Log::Any::Adapter::Journal>.
Prior to version 1.0, trace logs were treated as if they were debug logs,
so they were sent to with debug (7) log level even if min_level was 'debug'.

This adapter is based on the L<Log::Any::Adapter::Screen>, and accepts the same
optional settings. We assume you want color output when running interactively
and the priority prefix otherwise.  More precisely, the priority prefix will be
added when C<! -t STDIN> or C<!!use_color>.  See L<Log::Any::Adapter::Screen>
for more information on the various options.

=head1 SEE ALSO

L<Log::Any>, L<Log::Any::Adapter::Screen>, C<systemd-cat>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<http://github.com/mvgrimes/Log-Any-Adapter-Journal/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Mark Grimes E<lt>mgrimes@cpan.orgE<gt>

=head1 SOURCE

Source repository is at L<https://github.com/mvgrimes/Log-Any-Adapter-Journal>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Mark Grimes E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
