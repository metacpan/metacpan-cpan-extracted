package Devel::Deprecations::Environmental;

use strict;
use warnings;

use DateTime::Format::ISO8601;
use Module::Load ();
use Scalar::Util qw(blessed);

our $VERSION = '1.000';

=head1 NAME

Devel::Deprecations::Environmental - deprecations for your code's surroundings

=head1 DESCRIPTION

A framework for managing deprecations of the environment in which your code runs

=head1 SYNOPSIS

This will load the Devel::Deprecations::Environmental::Plugin::Int32 plugin and emit a
warning if running on a 32 bit system:

    use Devel::Deprecations::Environmental qw(Int32);

This will start warning about an impending deprecation on the 1st of February
2023, upgrade that to a warning about being unsupported on the 1st of February
2024, and upgrade that to a fatal error on the 1st of February 2025:

    use Devel::Deprecations::Environmental
        Int32 => {
            warn_from        => '2023-02-01',
            unsupported_from => '2024-02-01',
            fatal_from       => '2025-02-01',
        };

This will always warn about 32 bit perl or a really old perl:

    use Devel::Deprecations::Environmental
        OldPerl => { older_than => '5.14.0', },
        'Int32';

=head1 DEPRECATION ARGUMENTS

Each deprecation has a name, which can be optionally followed by a hash-ref of
arguments. All deprecations automatically support:

=over

=item warn_from

The time at which to start emitting warnings about an impending deprecation.
Defaults to the moment of creation, C<'1970-01-01'> (any ISO 8601 format is
accepted). You can also provide this as a L<DateTime> object.

This must be before any of C<unsupported_from> or C<fatal_from> which are
specified.

=item unsupported_from

The time at which to start warning harder, when something is no longer
supported. Defaults to C<undef>, meaning "don't do this".

This must be before C<fatal_from> if that is specified.

=item fatal_from

The time after which the code should just C<die>. Defaults to C<undef>,
meaning "don't do this".

=back

Of those three only the most severe will be emitted.

Arguments with names beginning with an underscore are reserved for internal
use. Plugins can support any other arguments they wish.

=head1 CONTENT OF WARNINGS / FATAL ERRORS

The pseudo-variables C<$date>, C<$filename>, C<$line>, and C<$reason> will be
interpolated.

C<$date> will be C<From $unsupported_from: > or C<From $fatal_from: > (using
whichever is earlier) if one of those is configured.

C<$filename> and C<$line> will tell you the file and line on which
C<Devel::Deprecations::Environmental> is loaded.

C<$reason> is defined in the plugin's C<reason()> method.

=head2 Initial warning

C<Deprecation warning! ${date}In $filename on line $line: $reason\n>

=head2 "Unsupported" warning

C<Unsupported! In $filename on line $line: $reason\n>

=head2 Fatal error

C<Unsupported! In $filename on line $line: $reason\n>

=cut

sub import {
    my $class = shift;
    my @args = @_;
    if($class eq __PACKAGE__) {
        # when loading Devel::Deprecations::Environmental itself ...
        while(@args) {
            my $plugin = 'Devel::Deprecations::Environmental::Plugin::'.shift(@args);
            my $plugin_args = ref($args[0]) ? shift(@args) : {};
            $plugin_args->{_source} = {
                filename => (caller(0))[1],
                line     => (caller(0))[2]
            };

            Module::Load::load($plugin);
            my @errors = ();
            push @errors, "doesn't inherit from ".__PACKAGE__
                unless($plugin->isa(__PACKAGE__));
            push @errors, "doesn't implement 'reason()'"
                unless($plugin->can('reason'));
            push @errors, "doesn't implement 'is_deprecated()'"
                unless($plugin->can('is_deprecated'));
            die(join("\n",
                __PACKAGE__.": plugin $plugin doesn't implement all it needs to",
                map { "  $_" } @errors
            )."\n")
                if(@errors);
            $plugin->import($plugin_args);
        }
    } else {
        # when called on a subclass ...
        my $args = $args[0];
        $args->{warn_from} ||= '1970-01-01';
        my %_froms = (
            map {
                $_ => blessed($args->{$_}) ? $args->{$_} : DateTime::Format::ISO8601->parse_datetime($args->{$_})
            } grep {
                exists($args->{$_})
            } qw(warn_from unsupported_from fatal_from)
        );
        delete($args->{$_}) foreach(qw(warn_from unsupported_from fatal_from));

        # check that warn/unsupported/fatal are ordered correctly in time
        foreach my $pair (
            [qw(warn_from        unsupported_from)],
            [qw(warn_from        fatal_from)],
            [qw(unsupported_from fatal_from)],
        ) {
            if(
                exists($_froms{$pair->[0]}) && exists($_froms{$pair->[1]}) &&
                !($_froms{$pair->[0]} < $_froms{$pair->[1]})
            ) {
                die(sprintf("%s: %s must be before %s\n", __PACKAGE__, @{$pair}));
            }
        }

        if($class->is_deprecated($args)) {
            my $reason = $class->reason($args);
            my $now = DateTime->now();
            if($_froms{fatal_from} && $_froms{fatal_from} < $now) {
                die(_fatal_msg(
                    %{$args->{_source}},
                    reason => $reason
                ));
            } elsif($_froms{unsupported_from} && $_froms{unsupported_from} < $now) {
                warn(_unsupported_msg(
                    %{$args->{_source}},
                    reason => $reason
                ));
            } elsif($_froms{warn_from} < $now) { # warn_from always exists!
                warn(_warn_msg(
                    %{$args->{_source}},
                    reason => $reason,
                    date   => (
                        sort { $a <=> $b }
                        map  { $_froms{$_} }
                        grep { $_froms{$_} }
                        qw(unsupported_from fatal_from)
                    )[0] || undef
                ));
            }
        }
    }
}

sub _fatal_msg {
    my %args = @_;
    return "Unsupported! In $args{filename} on line $args{line}: $args{reason}\n";
}

sub _unsupported_msg { return _fatal_msg(@_); }

sub _warn_msg {
    my %args = @_;
    return "Deprecation warning! ".
           ($args{date} ? 'From '.$args{date}->iso8601().': ' : '').
           "In $args{filename} on line $args{line}: $args{reason}\n";
}

=head1 FUNCTIONS

There are no public functions or methods, everything is done when the
module is loaded (specifically, when its C<import()> method is called)
with all specific deprecations handled by plugins.

=head1 WRITING YOUR OWN PLUGINS

The C<Devel::Deprecations::Environmental::Plugin::*> namespace is yours to play in, except
for the C<Devel::Deprecations::Environmental::Plugin::Internal::*> namespace.

A plugin should inherit from C<Devel::Deprecation>, and implement the following
methods, which will be called as class methods. Failure to define either of
them will result in fatal errors. They will be passed the arguments hash-ref
(with C<warn_from>, C<unsupported_from>, and C<fatal_from> removed):

=over

=item reason

Returns a brief string explaining the deprecation. For example "32 bit
integers" or "Perl too old".

=item is_deprecated

This should return true or false for whether the environment matches the
deprecation or not.

=back

=head1 FEEDBACK

I welcome feedback about my code, including constructive criticism, bug
reports, documentation improvements, and feature requests. The best bug reports
include files that I can add to the test suite, which fail with the current
code in my git repo and will pass once I've fixed the bug

Feature requests are far more likely to get implemented if you submit a patch
yourself, preferably with tests.

=head1 SOURCE CODE REPOSITORY

L<git://github.com/DrHyde/perl-modules-Devel-Deprecations.git>

=head1 SEE ALSO

L<Devel::Deprecate> - for deprecating parts of your own code as opposed
to parts of the environment your code is running in;

=head1 AUTHOR, LICENCE and COPYRIGHT

Copyright 2022 David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

This software is free-as-in-speech software, and may be used, distributed, and
modified under the terms of either the GNU General Public Licence version 2 or
the Artistic Licence. It's up to you which one you use. The full text of the
licences can be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

1;
