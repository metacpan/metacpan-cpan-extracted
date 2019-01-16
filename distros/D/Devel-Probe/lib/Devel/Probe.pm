package Devel::Probe;
use strict;
use warnings;

use XSLoader;

our $VERSION = '0.000004';
XSLoader::load( 'Devel::Probe', $VERSION );

sub import {
    my ($class) = @_;
    Devel::Probe::install();
}

my @probe_type_names = (
    'none',
    'once',
    'permanent',
);
my %probe_type_name_to_type = map { $probe_type_names[$_] => $_ }
                              (0..scalar(@probe_type_names)-1);

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
        if ($action->{action} eq 'dump') {
            Devel::Probe::dump();
            next;
        }
        if ($action->{action} eq 'clear') {
            Devel::Probe::clear();
            next;
        }
        if ($action->{action} eq 'define') {
            my $file = $action->{file};
            next unless $file;

            my $type_name = $action->{type} // 'once';
            my $type = $probe_type_name_to_type{$type_name} // 1;
            foreach my $line (@{ $action->{lines} // [] }) {
                Devel::Probe::add_probe($file, $line, $type);
            }
            next;
        }
    }
}

1;
__END__

=pod

=encoding utf8

=head1 NAME

Devel::Probe - Quick & dirty code probes for Perl

=head1 VERSION

Version 0.000004

=head1 SYNOPSIS

    use Devel::Probe;
    ...
    Devel::Probe::trigger(sub {
        my ($file, $line) = @_;
        # probe logic
    });
    Devel::Probe::config(%config);
    ...
    Devel::Probe::enable();
    ...
    Devel::Probe::disable();

=head1 DESCRIPTION

Use this module to allow the possibility of creating probes for some lines in
your code.

The probing code is installed when you import the module, and it is disabled.
In these conditions, the probe code is light enough that it should cause no
impact at all in your CPU usage.

You can call C<trigger(\&coderef)> to specify a piece of Perl code that will be
called for every probe that triggers.

You can call C<config(\%config)> to specify a configuration for the module,
including what lines in your code will cause probes to be triggered.  This call
will always disable the module as a first action, so you always need to
explicitly enable it again, either from the configuration itself or in a
further call to C<enable()>.

You can call C<add_probe(file, line, type)> to manually add a probe; this is
what gets called from C<config()>.

You can call C<enable()> / C<disable()> to dynamically activate and deactivate
probing.  You can check this status by calling C<is_enabled()>.

You can call C<install()> / C<remove()> to install or remove the probe handling
code.  You can check this status by calling C<is_installed()>.  When you import
the module, C<install()> is called automatically for you.

You can call C<clear()> to remove all probes.

You can call C<dump()> to print all probes to stderr.

=head1 CONFIGURATION

An example configuration hash looks like this:

    my %config = (
        actions => [
            { action => 'disable' },
            { action => 'clear' },
            { action => 'define' ... },
            { action => 'dump' },
            { action => 'enable' },
        ],
    );

Possible actions are:

=over 4

=item * C<disable>: disable probing.

=item * C<clear>: clear current list of probes.

=item * C<dump>: dump current list of probes to stderr.

=item * C<enable>: enable probing.

=item * C<define>: define a new probe.  A full define action looks like:

    my %define = (
        action => 'define',
        type => PROBE_TYPE,
        file => 'file_name',
        lines => [ 10, 245, 333 ],
    );

The type field is optional and its default value is C<once>.  Possible values
are:

=over 4

=item * C<once>: the probe will trigger once and then will be destroyed right
after that.

=item * C<permanent>: the probe will trigger every time that line of code is
executed.

=back

=back

=head1 EXAMPLE

This will invoke the C<trigger> callback the first time line 21 executes, and
take advantage of C<PadWalker> to dump the local variables.

    use Data::Dumper qw(Dumper);
    use PadWalker qw(peek_my);
    use Devel::Probe;

    Devel::Probe::trigger(sub {
        my ($file, $line) = @_;
        say Dumper(peek_my(1)); # 1 to jump up one level in the stack;
    });

    my %config = (
        actions => [
            { action => 'define', # type is 'once' by default
              file => 'probe my_cool_script.pl', lines => [ 13 ] },
        ],
    );
    Devel::Probe::config(\%config);
    Devel::Probe::enable();
    my $count;
    while (1) {
        $count++;
        my $something_inside_the_loop = $count * 2; # line 21
        sleep 5;
    }
    Devel::Probe::disable();

=head1 SUGGESTIONS

One typical use case would be to have a signal handler associated with a
specific signal, which when triggered would disable the module, read the
configuration from a given place, reconfigure the module accordingly and then
enable it.

Another use case could be a similar kind of control using remote endpoints to
deal with reconfiguring, disabling and enabling the module.

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
