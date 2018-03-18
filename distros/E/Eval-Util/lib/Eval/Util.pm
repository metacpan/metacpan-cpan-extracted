package Eval::Util;

our $DATE = '2018-03-12'; # DATE
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(
                       inside_eval
                       inside_block_eval
                       inside_string_eval
                       eval_level
               );
# XXX block_eval_level
# XXX string_eval_level

sub inside_eval {
    my $i = 0;
    while (1) {
        my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext) = #, $is_require, $hints, $bitmask, $hinthash
            caller($i);
        last unless defined $package;
        $i++;
        if ($subroutine eq "(eval)" || defined $evaltext) {
            return 1;
        }
    };
    0;
}

sub inside_block_eval {
    my $i = 0;
    while (1) {
        my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext) = #, $is_require, $hints, $bitmask, $hinthash
            caller($i);
        last unless defined $package;
        $i++;
        if ($subroutine eq "(eval)" && !defined($evaltext)) {
            return 1;
        }
    };
    0;
}

sub inside_string_eval {
    my $i = 0;
    while (1) {
        my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext) = #, $is_require, $hints, $bitmask, $hinthash
            caller($i);
        last unless defined $package;
        $i++;
        if ($subroutine eq "(eval)" && defined($evaltext)) {
            return 1;
        }
    };
    0;
}

sub eval_level {
    my $i = 0;
    my $level = 0;
    while (1) {
        my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext) = #, $is_require, $hints, $bitmask, $hinthash
            caller($i);
        last unless defined $package;
        $i++;
        if ($subroutine eq "(eval)" || defined $evaltext) {
            $level++;
        }
    };
    $level;
}

1;
# ABSTRACT: Utilities related to eval()

__END__

=pod

=encoding UTF-8

=head1 NAME

Eval::Util - Utilities related to eval()

=head1 VERSION

This document describes version 0.002 of Eval::Util (from Perl distribution Eval-Util), released on 2018-03-12.

=head1 SYNOPSIS

 use Eval::Util qw(
    inside_eval
    inside_block_eval
    inside_string_eval
    eval_level
 );

 # will not print 'foo', but print 'bar' and 'baz'
 say "foo" if inside_eval();
 eval { say "bar" if inside_eval() };
 eval q(say "baz" if inside_eval());

 # will not print 'foo' or 'baz' but print 'bar'
 say "foo" if inside_block_eval();
 eval { say "bar" if inside_block_eval() };
 eval q(say "baz" if inside_block_eval());

 # will not print 'foo' or 'bar' but print 'baz'
 say "foo" if inside_string_eval();
 eval { say "bar" if inside_string_eval() };
 eval q(say "baz" if inside_string_eval());

 say eval_level(); # 0
 eval { say eval_level() }; # 1
 eval { eval { say eval_level() } }; # 2

=head1 DESCRIPTION

=head1 FUNCTIONS

None exported by default, but they are exportable.

=head2 inside_eval

Usage: inside_eval() => bool

Will check if running code is inside eval() (either string eval or block eval).
This is done via examining the stack trace and checking for frame with
subroutine named C<(eval)>.

A faster and simpler alternative is to check if the Perl special variable C<$^S>
is true. Consult L<perlvar> for more details about this variable.

=head2 inside_block_eval

Usage: inside_block_eval() => bool

Will check if running code is inside block eval() (C<eval { ... }>). Will return
false if code is only inside string eval. This is done via examining the stack
trace and checking for frame with subroutine named C<(eval)> that has undefined
eval text.

=head2 inside_string_eval

Usage: inside_string_eval() => bool

Will check if running code is inside string eval() (C<eval " ... ">). Will
return false if code is only inside block eval. This is done via examining the
stack trace and checking for frame with subroutine named C<(eval)> that has
defined eval text.

=head2 eval_level

Usage: eval_level() => int

Return 0 if running code is not inside any eval, 1 if inside one eval, 2 if
inside two evals, and so on.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Eval-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Eval-Util>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Eval-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

C<caller> in L<perlfunc>

C<$^S> in L<perlvar>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
