package Log::ger::Plugin::Perl;

our $DATE = '2020-03-11'; # DATE
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;
use Log::ger::Util ();

sub meta { +{
    v => 2,
} }

sub get_hooks {
    my %conf = @_;

    my $action = delete($conf{action}) || {
        warn  => 'warn',
        error => 'warn',
        fatal => 'die',
    };
    keys %conf and die "Unknown configuration: ".join(", ", sort keys %conf);

    return {
        after_install_routines => [
            __PACKAGE__, # key
            99,          # priority
            sub {        # hook
                require B::CallChecker;
                require B::Generate;

                my %hook_args = @_;

                # we are only relevant when targetting package
                return [undef] unless ($hook_args{target}||'') eq 'package';

                for my $r (@{ $hook_args{routines} }) {
                    my ($code, $name, $lnum, $type) = @$r;
                    next unless $type =~ /\Alog_/;

                    my $act = $action->{ Log::ger::Util::string_level($lnum) };

                    my $logger;
                    if (!$act) {
                        $logger = sub { B::SVOP->new("const",0,!1) };
                    } elsif ($act eq 'warn') {
                        #$logger = sub { warn @_ > 1 ? sprintf(shift, @_) : @_ };
                        $logger = sub { sub { warn @_ > 1 ? sprintf(shift, @_) : @_ } };
                        $logger = sub { sub { warn @_ > 1 ? sprintf(shift, @_) : @_ } };
                    } elsif ($act eq 'carp') {
                        require Carp;
                        $logger = sub { Carp::carp(@_ > 1 ? sprintf(shift, @_) : @_) };
                    } elsif ($act eq 'cluck') {
                        require Carp;
                        $logger = sub { Carp::cluck(@_ > 1 ? sprintf(shift, @_) : @_) };
                    } elsif ($act eq 'croak') {
                        require Carp;
                        $logger = sub { Carp::croak(@_ > 1 ? sprintf(shift, @_) : @_) };
                    } elsif ($act eq 'confess') {
                        require Carp;
                        $logger = sub { Carp::confess(@_ > 1 ? sprintf(shift, @_) : @_) };
                    } else { # die is the default
                        $logger = sub { die @_ > 1 ? sprintf(shift, @_) : @_ };
                    }

                    my $fullname = "$hook_args{target_arg}\::$name";
                    B::CallChecker::cv_set_call_checker(
                        \&{$fullname},
                        sub { B::SVOP->new("anoncode", $logger, $logger) },
                        #sub { B::SVOP->new("const", 0, !1) },
                        \!1,
                    );
                }
                [1];
            }],
    };
}

1;
# ABSTRACT: Replace log statements with Perl's standard facility (warn, die, etc)

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Plugin::Perl - Replace log statements with Perl's standard facility (warn, die, etc)

=head1 VERSION

This document describes version 0.002 of Log::ger::Plugin::Perl (from Perl distribution Log-ger-Plugin-Perl), released on 2020-03-11.

=head1 SYNOPSIS

 use Log::ger::Plugin Perl => (
     action => { # optional
         trace => '',
         debug => '',
         info  => '',
         warn  => 'warn',
         error => 'warn',
         fatal => 'die',
     },
 );

=head1 DESCRIPTION

This plugin uses L<B::CallChecker> to replace logging statements with C<warn()>,
C<die()>, etc.

Caveats:

=over

=item * must be done at compile-time

=item * only works when you are using procedural style

=item * logging statements at level with action='' or unmentioned, will become no-op

The effect is similar to what is achieved by

=item * once replaced/optimized away, subsequent logger reinitialization at run-time won't take effect

=item * currently formats message with sprintf(), no layouter support

=back

=for Pod::Coverage ^(.+)$

=head1 CONFIGURATION

=head2 action => hash

A mapping of Log::ger error level name and action. Unmentioned levels mean to
ignore log for that level. Action can be one of:

=over

=item * '' (empty string)

Ignore the log message.

=item * warn

Pass message to Perl's C<warn()>.

=item * die

Pass message to Perl's C<die()>.

=item * carp

Pass message to L<Carp>'s C<carp()>.

=item * cluck

Pass message to L<Carp>'s C<cluck()>.

=item * croak

Pass message to L<Carp>'s C<croak()>.

=item * confess

Pass message to L<Carp>'s C<confess()>.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Log-ger-Plugin-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Log-ger-Plugin-Perl>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log-ger-Plugin-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Log::ger::Output::Perl>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
