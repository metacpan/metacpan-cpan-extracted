package Devel::Probe;
use strict;
use warnings;

use Storable qw(dclone);
use XSLoader;
use Carp qw(croak);

our $VERSION = '0.000006';
XSLoader::load( 'Devel::Probe', $VERSION );

sub import {
    my ($class) = @_;
    Devel::Probe::install();
}

use constant {
    NONE => 0,
    ONCE => 1,
    PERMANENT => 2,
};

sub config {
    my ($config) = @_;

    Devel::Probe::disable();
    return unless $config;

    foreach my $action (@{ $config->{actions} }) {
        if ($action->{action} eq 'enable') {
            Devel::Probe::enable();
            next;
        }
        if ($action->{action} eq 'disable') {
            Devel::Probe::disable();
            next;
        }
        if ($action->{action} eq 'clear') {
            Devel::Probe::clear();
            next;
        }
        if ($action->{action} eq 'define') {
            my $file = $action->{file};
            next unless $file;

            my $type = $action->{type} // ONCE;
            my $argument = $action->{argument};
            foreach my $line (@{ $action->{lines} // [] }) {
                add_probe($file, $line, $type, $argument);
            }
            next;
        }
    }
}

sub add_probe {
    my ($file, $line, $type, $argument) = @_;
    if ($type ne ONCE && $type ne PERMANENT) {
        croak sprintf("'%s' is not a valid probe type: try Devel::Probe::ONCE|PERMANENT", $type);
    }

    my $probes = Devel::Probe::_internal_probe_state();
    $probes->{$file}->{$line} = [$type, defined $argument ? $argument : ()];
}

sub dump {
    return dclone(Devel::Probe::_internal_probe_state());
}

1;
__END__

=pod

=encoding utf8

=head1 NAME

Devel::Probe - Quick & dirty code probes for Perl

=head1 VERSION

Version 0.000006

=head1 SYNOPSIS

    use Devel::Probe;
    ...
    Devel::Probe::trigger(sub {
        my ($file, $line, $argument) = @_;
        # probe logic
    });
    Devel::Probe::config(\%config);
    ...
    Devel::Probe::enable();
    ...
    Devel::Probe::disable();

=head1 DESCRIPTION

Use this module to allow the possibility of creating probes for some lines in
your code.  These probes can be used to build things like debuggers, fault
injection tests, or production observability tooling.

The probing code is installed when you import the module, but it is disabled.
In these conditions, the probe code is light enough that it should cause no
impact at all in your CPU usage; an impact might be noticed when you enable the
module and configure some probes, particularly depending on the frequency with
which those probes will be triggered, and how heavy the trigger callback turns
out to be.

=head1 FUNCTIONS

=over 4

=item * C<trigger(\&coderef)>

Specify a piece of Perl code that will be called for every probe that triggers.

=item * C<config(\%config)>

Specify a configuration for the module, including what lines in your code will
cause probes to be triggered.  This call will always disable the module as a
first action, so you always need to explicitly enable it again, either from the
configuration itself or in a further call to C<enable()>.

=item * C<add_probe($file, $line, $type, $callback_argument)>

Manually add a probe.  This is what gets called from C<config()> when adding
probes; please see the CONFIGURATION example for more information.

=item * C<enable()> / C<disable()>  / C<is_enabled()>

Dynamically activate and deactivate probing, and check this status.  When
disabled, C<Devel::Probe> will have minimal overhead, and probes will fire
again as soon as C<enable()> is called.

=item * C<install()> / C<remove()> / C<is_installed()>

Install or remove the probe handling code, and check this status.  When you
import the module, C<install()> is called automatically for you.

When uninstalled, C<Devel::Probe> will have zero overhead, and all probe state
is cleared.  Probes will not fire again until C<install()> is called and both
trigger and probes are redefined.

=item * C<clear()>

Remove all probes.

=item * C<dump()>

Return all probes as a hash.

=back

=head1 CONFIGURATION

An example configuration hash looks like this:

    my %config = (
        actions => [
            { action => 'disable' },
            { action => 'clear' },
            { action => 'define' ... },
            { action => 'enable' },
        ],
    );

Possible actions are:

=over 4

=item * C<disable>: disable probing.

=item * C<clear>: clear current list of probes.

=item * C<enable>: enable probing.

=item * C<define>: define a new probe.  A full define action looks like:

    my %define = (
        action => 'define',
        type => PROBE_TYPE,
        file => 'file_name',
        lines => [ 10, 245, 333 ],
        argument => $my_callback_argument,
    );

The type field is optional and its default value is C<Devel::Probe::ONCE>.  Possible values
are:

=over 4

=item * C<Devel::Probe::ONCE>: the probe will trigger once and then will be destroyed right
after that.  This default makes it more difficult to overwhelm your system with
too much probing, unless you explicitly request a different type of probe.

=item * C<Devel::Probe::PERMANENT>: the probe will trigger every time that line of code is
executed.

=back

The C<argument> field is optional and its default value is undefined. Possible
values are any Perl scalar.  If present, it will be passed to the C<trigger>
callback as the third argument.

=back

=head1 EXAMPLE

This will invoke the callback defined with the call to C<trigger()>, the first
time line 21 executes, taking advantage of C<PadWalker> to dump the local
variables.  After that first execution, that particular probe will not be
triggered anymore.  For line 22, every time that line is executed the probe
will be triggered.

    # line 1
    use 5.18.0;
    use Data::Dumper qw(Dumper);
    use PadWalker qw(peek_my);
    use Devel::Probe;

    Devel::Probe::trigger(sub {
        my ($file, $line) = @_;
        say Dumper(peek_my(1)); # 1 to jump up one level in the stack;
    });

    my %config = (
        actions => [
            { action => 'define', file => __FILE__, lines => [ 22 ] },
            { action => 'define', file => __FILE__, type => Devel::Probe::PERMANENT, lines => [ 23 ] },
        ],
    );
    Devel::Probe::config(\%config);
    Devel::Probe::enable();
    my $count;
    while (1) {
        $count++;                                   # line 22
        my $something_inside_the_loop = $count * 2; # line 23
        sleep 5;
    }
    Devel::Probe::disable();

As another example, you can pass a custom argument to the trigger callback:

    # line 1
    use 5.18.0;
    use PadWalker qw(peek_my);
    use Devel::Probe;

    Devel::Probe::trigger(sub {
        my ($file, $line, $interesting_var_name) = @_;
        say "$interesting_var_name: " . ${ peek_my(1)->{$interesting_var_name} };
    });

    my %config = (
        actions => [
            { action => 'enable' },
            { action => 'define',
              file => __FILE__,
              type => Devel::Probe::PERMANENT,
              lines => [ 26 ],
              argument => '$squared'
            },
        ],
    );
    Devel::Probe::config(\%config);
    my $count = 0;
    my $squared = 0;
    while (1) {
        $count++;
        $squared = $count * $count; # line 26
        sleep 5;
    }

=head1 SUGGESTIONS

For files found directly by the Perl interpreter, the file name in the probe
definition will usually be a relative path name; for files that are found
through the PERL5LIB environment variable, the file name in the probe
definition will usually be a full path name.

One typical use case would be to have a signal handler associated with a
specific signal, which when triggered would disable the module, read the
configuration from a given place, reconfigure the module accordingly and then
enable it.  Similarly, this kind of control can be implemented using remote
endpoints to deal with reconfiguring, disabling and enabling the module.

=head1 TODO

=over 4

=item

Probes are stored in a hash of file names; per file name, there is a hash
of line numbers (with the probe type as a value).  It is likely this can be
made more performant with a better data structure, but that needs profiling.

=back

=head1 AUTHORS

=over 4

=item * Gonzalo Diethelm C<< gonzus AT cpan DOT org >>

=item * Ben Tyler C<< btyler AT cpan DOT org >>

=back
