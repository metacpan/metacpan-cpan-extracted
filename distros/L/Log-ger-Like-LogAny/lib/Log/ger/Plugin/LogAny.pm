package Log::ger::Plugin::LogAny;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-11'; # DATE
our $DIST = 'Log-ger-Like-LogAny'; # DIST
our $VERSION = '0.006'; # VERSION

use strict;
use warnings;

use Log::ger ();

sub meta { +{
    v => 2,
} }

sub get_hooks {
    my %plugin_conf = @_;

    return {
        create_formatter => [
            __PACKAGE__, 50,
            sub {
                my $formatter = sub {
                    return join " ", @_;
                };
                return [$formatter, 0, 'join'];
            },
        ],
        create_routine_names => [
            __PACKAGE__, # key
            50,          # priority
            sub {
                my %hook_args = @_;

                my $levels = [keys %Log::ger::Levels];

                return [{
                    logger_subs            => [map { (["log_$_", $_, "join"], ["log_${_}f", $_, "default"]) }
                                                   @$levels],
                    level_checker_subs     => [map { ["log_is_$_", $_] } @$levels],
                    logger_methods         => [map { (["$_", $_, "join"], ["${_}f", $_, "default"]) }
                                                   @$levels],
                    level_checker_methods => [map { ["is_$_", $_] } @$levels],
                }, 1];
            }],
    };
}

1;
# ABSTRACT: Plugin to mimic Log::Any

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Plugin::LogAny - Plugin to mimic Log::Any

=head1 VERSION

version 0.006

=head1 SYNOPSIS

Use from L<Log::ger::Like::LogAny>.

=head1 DESCRIPTION

=for Pod::Coverage ^(.+)$

=head1 SEE ALSO

L<Log::ger::Like::LogAny>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
