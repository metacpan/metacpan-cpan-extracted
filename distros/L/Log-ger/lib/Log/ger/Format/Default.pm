package Log::ger::Format::Default;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-29'; # DATE
our $DIST = 'Log-ger'; # DIST
our $VERSION = '0.042'; # VERSION

sub meta { +{
    v => 2,
} }

sub get_hooks {
    my %conf = @_;

    return {
        create_formatter => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                my %hook_args = @_; # see Log::ger::Manual::Internals/"Arguments passed to hook"


             my $formatter =

                 # the default formatter is sprintf-style that dumps data
                 # structures arguments as well as undef as '<undef>'.
                 sub {
                     return $_[0] if @_ < 2;
                     my $fmt = shift;
                     my @args;
                     for (@_) {
                         if (!defined($_)) {
                             push @args, '<undef>';
                         } elsif (ref $_) {
                             require Log::ger::Util unless $Log::ger::_dumper;
                             push @args, Log::ger::Util::_dump($_);
                         } else {
                             push @args, $_;
                         }
                     }
                     # redefine is just a dummy category for perls < 5.22 which
                     # don't have 'redundant' yet
                     no warnings ($warnings::Bits{'redundant'} ? 'redundant' : 'redefine');
                     sprintf $fmt, @args;
                 };

             [$formatter];


            }],
    };
}

1;
# ABSTRACT: Use default Log::ger formatting style

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Format::Default - Use default Log::ger formatting style

=head1 VERSION

version 0.042

=head1 SYNOPSIS

 use Log::ger::Format 'Default';
 use Log::ger;

 log_debug "Printed as is";
 # will format the log message as: Printed as is

 log_debug "Data for %s is %s", "budi", {foo=>'blah', bar=>undef};
 # will format the log message as: Data for budi is {bar=>undef,foo=>"blah"}

=head1 DESCRIPTION

This is the default Log::ger formatter, which: 1) passes the argument as-is if
there is only a single argument; or, if there are more than one argument, 2)
treats the arguments like sprintf(), where the first argument is the template
and the rest are variables to be substituted to the conversions inside the
template. In the second case, reference arguments will be dumped using
L<Data::Dmp> or L<Data::Dumper> by default (but the dumper is configurable by
setting C<$Log::ger::_dumper>; see for example L<Log::ger::UseDataDump> or
L<Log::ger::UseDataDumpColor>).

The same code is already included in L<Log::ger::Heavy>; this module just
repackages it so it's more reusable.

=for Pod::Coverage ^(.+)$

=head1 SEE ALSO

L<Log::ger::Format::Join>

L<Log::ger>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2022, 2020, 2019, 2018, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
