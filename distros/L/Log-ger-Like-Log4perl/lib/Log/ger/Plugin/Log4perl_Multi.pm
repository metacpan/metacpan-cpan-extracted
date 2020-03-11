package Log::ger::Plugin::Log4perl_Multi;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-11'; # DATE
our $DIST = 'Log-ger-Like-Log4perl'; # DIST
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;

use Log::ger ();

sub meta { +{
    v => 2,
} }

sub get_hooks {
    my %plugin_conf = @_;

    return {
        create_filter => [
            __PACKAGE__, 50,
            sub {
                my $filter = sub {
                    {level => shift};
                };
                return [$filter, 0, 'log4perl_multi'];
            },
        ],

        create_formatter => [
            __PACKAGE__, 50,
            sub {
                my $formatter = sub {
                    shift; # level
                    return
                        join("", map { ref $_ eq 'CODE' ? ($_->()) : ($_) } @_);
                };
                return [$formatter, 0, 'log4perl_multi'];
            },
        ],

        create_routine_names => [
            __PACKAGE__, 50,
            sub {
                my %hook_args = @_;

                return [{
                    logger_methods => [
                        ["log", undef, "log4perl_multi", undef, "log4perl_multi"],
                    ],
                }, 0];
            }],
    };
}

1;
# ABSTRACT: Plugin to mimic Log::Log4perl (log())

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Plugin::Log4perl_Multi - Plugin to mimic Log::Log4perl (log())

=head1 VERSION

version 0.003

=head1 SYNOPSIS

Use from L<Log::ger::Like::Log4perl>.

=head1 DESCRIPTION

=for Pod::Coverage ^(.+)$

=head1 SEE ALSO

L<Log::ger::Plugin::Log4perl>

L<Log::ger::Like::Log4perl>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
