package Log::ger::UseDataDumper;

our $DATE = '2018-06-10'; # DATE
our $VERSION = '0.001'; # VERSION

use Data::Dumper ();
use Log::ger ();
use strict 'subs', 'vars';
use warnings;

my @known_configs = qw(
                          Indent Trailingcomma Purity Pad Varname Useqq Terse
                          Freezer Toaster Deepcopy Bless Pair Maxdepth
                          Maxrecurse Useperl Sortkeys Deparse parseseen);

my %default_configs = (
    Indent => 1,
    Purity => 1,
    Terse  => 1,
);

sub import {
    my ($pkg, %args) = @_;
    my %configs = %default_configs;
    for my $k (sort keys %args) {
        die unless grep { $k eq $_ } @known_configs;
        $configs{$k} = $args{$k};
    }

    $Log::ger::_dumper = sub {
        my %orig_configs;
        for (keys %configs) {
            $orig_configs{$_} = ${"Data::Dumper::$_"};
            ${"Data::Dumper::$_"} = $configs{$_};
        }
        my $res = Data::Dumper::Dumper(@_);
        for (keys %configs) {
            ${"Data::Dumper::$_"} = $orig_configs{$_};
        }
        $res;
    };
}

1;
# ABSTRACT: Use Data::Dumper (with nicer defaults) to dump data structures

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::UseDataDumper - Use Data::Dumper (with nicer defaults) to dump data structures

=head1 VERSION

This document describes version 0.001 of Log::ger::UseDataDumper (from Perl distribution Log-ger-UseDataDumper), released on 2018-06-10.

=head1 SYNOPSIS

 use Log::ger::UseDataDumper;

To configure Data::Dumper:

 use Log::ger::UseDataDumper (Indent => 0, Purity => 0);

=head1 DESCRIPTION

This module sets the L<Log::ger> dumper to L<Data::Dumper>, which by default is
already the case but in this edition the default configuration is somewhat
closer to that of L<Data::Dump>:

 Indent => 1,
 Purity => 1,
 Terse  => 1,

This module also lets you configure Data::Dumper during import (see example in
Synopsis).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Log-ger-UseDataDumper>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Log-ger-UseDataDumper>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log-ger-UseDataDumper>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Log::ger>

L<Data::Dumper>

L<Log::ger::UseDataDump>, L<Log::ger::UseDataDumpColor>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
