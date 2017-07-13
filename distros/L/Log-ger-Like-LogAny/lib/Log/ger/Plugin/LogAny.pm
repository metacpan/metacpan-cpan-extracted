package Log::ger::Plugin::LogAny;

our $DATE = '2017-07-12'; # DATE
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;

use Log::ger ();

sub get_hooks {
    my %conf = @_;

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
            __PACKAGE__, 50,
            sub {
                my %args = @_;

                my $levels = [keys %Log::ger::Levels];

                return [{
                    log_subs    => [map { ["log_$_", $_, "join"], ["log_${_}f", $_, "default"] }
                                        @$levels],
                    is_subs     => [map { ["log_is_$_", $_] } @$levels],
                    log_methods => [map { ["$_", $_, "join"], ["${_}f", $_, "default"] }
                                        @$levels],
                    is_methods  => [map { ["is_$_", $_] } @$levels],
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

version 0.003

=head1 SYNOPSIS

Use from L<Log::ger::Like::LogAny>.

=head1 DESCRIPTION

=for Pod::Coverage ^(.+)$

=head1 SEE ALSO

L<Log::ger::Like::LogAny>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
