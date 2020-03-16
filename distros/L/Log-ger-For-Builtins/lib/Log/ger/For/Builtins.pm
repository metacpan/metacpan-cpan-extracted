package Log::ger::For::Builtins;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-14'; # DATE
our $DIST = 'Log-ger-For-Builtins'; # DIST
our $VERSION = '0.001'; # VERSION

use strict 'subs', 'vars';
use warnings;
use Log::ger;

use Data::Dmp ();

our %SUPPORTED = (
    # func => [code or target sub, bool log_result]

    readpipe    => ["CORE::readpipe", 1],
    rename      => ["CORE::rename", 1],
    system      => [sub { system(@_) }, 1],
);

sub import {
    my $package = shift;

    my $caller = caller(0);
    for my $func (@_) {
        die "Exporting '$func' is not supported"
            unless grep { $func eq $_ } keys %SUPPORTED;
        *{"$caller\::$func"} = sub {
            my ($code_or_subname, $log_result) = @{ $SUPPORTED{$func} };
            my $wantarray = wantarray();

            log_trace "-> %s(%s)", $func, join(", ", map {Data::Dmp::dmp($_)} @_);

            my $res;
            if (ref $code_or_subname eq 'CODE') {
                if ($wantarray) { $res = [$code_or_subname->(@_)]  } else { $res = $code_or_subname->(@_) }
            } else {
                if ($wantarray) { $res = [&{$code_or_subname}(@_)] } else { $res = &{$code_or_subname}(@_) }
            }

            log_trace "<- %s%s", $func, $log_result ? " = ".($wantarray ? "(".join(", ", map {Data::Dmp::dmp($_)} @$res).")" : Data::Dmp::dmp($res)) : " (result not logged)";
            $wantarray ? @$res : $res;
        };
    }
}

1;
# ABSTRACT: Add logging to Perl builtins

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::For::Builtins - Add logging to Perl builtins

=head1 VERSION

This document describes version 0.001 of Log::ger::For::Builtins (from Perl distribution Log-ger-For-Builtins), released on 2020-03-14.

=head1 SYNOPSIS

 use Log::ger::For::Builtins qw(
     readpipe
     rename
     system
 );

=head1 DESCRIPTION

This module exports wrappers for Perl builtins with added logging. Logging is
produced using L<Log::ger> at the trace level and can be seen by using one of
output plugins e.g. L<Log::ger::Output::Screen>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Log-ger-For-Builtins>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Log-ger-For-Builtins>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log-ger-For-Builtins>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Log::ger>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
