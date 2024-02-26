package Log::ger::Plugin::MultilevelLog;

use strict;
use warnings;

use Log::ger::Util;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-29'; # DATE
our $DIST = 'Log-ger'; # DIST
our $VERSION = '0.042'; # VERSION

sub meta { +{
    v => 2,
} }

sub get_hooks {
    my %conf = @_;

    my $sub_name    = $conf{sub_name}    || 'log';
    my $method_name = $conf{method_name} || 'log';

    return {
        create_filter => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                my %hook_args = @_; # see Log::ger::Manual::Internals/"Arguments passed to hook"

                my $filter = sub {
                    my $level = Log::ger::Util::numeric_level(shift);
                    return 0 unless $level <= $Log::ger::Current_Level;
                    {level=>$level};
                };

                [$filter, 0, 'ml'];
            },
        ],

        create_formatter => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                my %hook_args = @_; # see Log::ger::Manual::Internals/"Arguments passed to hook"

                my $formatter =

                 # just like the default formatter, except it accepts first
                 # argument (level)
                    sub {
                        shift; # level
                        return $_[0] if @_ < 2;
                        my $fmt = shift;
                        my @args;
                        for (@_) {
                            if (!defined($_)) {
                                push @args, '<undef>';
                            } elsif (ref $_) {
                                push @args, Log::ger::Util::_dump($_);
                            } else {
                                push @args, $_;
                            }
                        }
                        # redefine is just a dummy category for perls < 5.22
                        # which don't have 'redundant' yet
                        no warnings ($warnings::Bits{'redundant'} ? 'redundant' : 'redefine');
                        sprintf $fmt, @args;
                    };

                [$formatter, 0, 'ml'];
            },
        ],

        create_routine_names => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                my %hook_args = @_; # see Log::ger::Manual::Internals/"Arguments passed to hook"
                return [{
                    logger_subs    => [[$sub_name   , undef, 'ml', undef, 'ml']],
                    logger_methods => [[$method_name, undef, 'ml', undef, 'ml']],
                }, $conf{exclusive}];
            },
        ],
    };
}

1;
# ABSTRACT: (DEPRECATED) Old name for Log::ger::Format::MultilevelLog

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Plugin::MultilevelLog - (DEPRECATED) Old name for Log::ger::Format::MultilevelLog

=head1 VERSION

version 0.042

=head1 DESCRIPTION

This plugin has been renamed to L<Log::ger::Format::MultilevelLog> in 0.038. The
old name is provided for backward compatibility for now, but is deprecated and
will be removed in the future. Please switch to the new name and be aware that
format plugins only affect the current package.

=for Pod::Coverage ^(.+)$

=head1 SEE ALSO

L<Log::ger::Format::MultilevelLog>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2022, 2020, 2019, 2018, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
