package Log::ger::Output::Perl;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-11'; # DATE
our $DIST = 'Log-ger-Output-Perl'; # DIST
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger::Util ();

sub meta { +{
    v => 2,
} }

sub get_hooks {
    my %plugin_conf = @_;

    my $action = delete($plugin_conf{action}) || {
        warn  => 'warn',
        error => 'warn',
        fatal => 'die',
    };
    keys %plugin_conf and die "Unknown configuration: ".
        join(", ", sort keys %plugin_conf);

    return {
        create_outputter => [
            __PACKAGE__, # key
            # we want to handle all levels, thus we need to be higher priority
            # than default Log::ger hooks (10) which will install null loggers
            # for less severe levels.
            9,           # priority
            sub {        # hook
                my %hook_args = @_; # see Log::ger::Manual::Internals/"Arguments passed to hook"

                my $outputter = sub {
                    my ($per_target_conf, $msg, $per_msg_conf) = @_;
                    my $lvl = $per_msg_conf->{level} // $hook_args{level};
                    if (my $act =
                            $action->{Log::ger::Util::string_level($lvl)}) {
                        @_ = ref $msg eq 'ARRAY' ? @$msg : ($msg);
                        if ($act eq 'warn') {
                            warn @_;
                        } elsif ($act eq 'carp') {
                            require Carp;
                            goto &Carp::carp;
                        } elsif ($act eq 'cluck') {
                            require Carp;
                            goto &Carp::cluck;
                        } elsif ($act eq 'croak') {
                            require Carp;
                            goto &Carp::croak;
                        } elsif ($act eq 'confess') {
                            require Carp;
                            goto &Carp::confess;
                        } else {
                            # die is the default action if unknown
                            die @_;
                        }
                    }
                };
                [$outputter];
            }],
    };
}

1;
# ABSTRACT: Log to Perl's standard facility (warn, die, etc)

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Output::Perl - Log to Perl's standard facility (warn, die, etc)

=head1 VERSION

This document describes version 0.004 of Log::ger::Output::Perl (from Perl distribution Log-ger-Output-Perl), released on 2020-03-11.

=head1 SYNOPSIS

 use Log::ger::Output Perl => (
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

This output passes message to Perl's standard facility of reporting error:
C<warn()>, C<die()>, or one of L<Carp>'s C<carp()>, C<cluck()>, C<croak()>, and
C<confess()>.

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

Please visit the project's homepage at L<https://metacpan.org/release/Log-ger-Output-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Log-ger-Output-Perl>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log-ger-Output-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Modelled after L<Log::Dispatch::Perl>.

L<Log::ger::Plugin::Perl> which actually replaces the log statements with
warn(), die(), etc.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
