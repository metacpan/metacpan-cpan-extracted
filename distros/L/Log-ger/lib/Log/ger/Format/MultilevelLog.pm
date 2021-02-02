package Log::ger::Format::MultilevelLog;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-01-31'; # DATE
our $DIST = 'Log-ger'; # DIST
our $VERSION = '0.038'; # VERSION

use strict;
use warnings;

use Log::ger::Util;

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
# ABSTRACT: Create a log($LEVEL, ...) subroutine/method

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Format::MultilevelLog - Create a log($LEVEL, ...) subroutine/method

=head1 VERSION

version 0.038

=head1 SYNOPSIS

To use for the current package:

 use Log::ger::Format MultilevelLog => (
     # sub_name => 'log_it',    # optional, defaults to 'log'
     # method_name => 'log_it', # optional, defaults to 'log'
     # exclusive => 1,          # optional, defaults to 0
 );
 use Log::ger;

 log('warn', 'This is a warning');
 log('debug', 'This is a debug, data is %s', $data);

 log_warn "This is also a warning"; # still available, unless you set exclusive to 1

=head1 DESCRIPTION

The Log::ger default is to create separate C<log_LEVEL> subroutine (or C<LEVEL>
methods) for each level, e.g. C<log_trace> subroutine (or C<trace> method),
C<log_warn> (or C<warn>), and so on. But sometimes you might want a log routine
that takes $level as the first argument. That is, instead of:

 log_warn('blah ...');

or:

 $log->debug('Blah: %s', $data);

you prefer:

 log('warn', 'blah ...');

or:

 $log->log('debug', 'Blah: %s', $data);

This format plugin can create such log routine for you.

Note: the multilevel log is slightly slower because of the extra argument and
additional string level -> numeric level conversion. See benchmarks in
L<Bencher::Scenarios::LogGer>.

Note: the individual separate C<log_LEVEL> subroutines (or C<LEVEL> methods) are
still installed, unless you specify configuration L</exclusive> to true.

=for Pod::Coverage ^(.+)$

=head1 CONFIGURATION

=head2 sub_name

String. Defaults to C<log>.

=head2 method_name

String. Defaults to C<log>.

=head2 exclusive

Boolean. If set to true, will block the generation of the default C<log_LEVEL>
subroutines or C<LEVEL> methods (e.g. C<log_warn>, C<trace>, ...).

=head1 SEE ALSO

L<Log::ger::Format::HashArgs>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
