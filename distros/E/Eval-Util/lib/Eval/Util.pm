package Eval::Util;

our $DATE = '2018-03-05'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(inside_eval);

sub inside_eval {
    my $i = 0;
    while (1) {
        my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext) = #, $is_require, $hints, $bitmask, $hinthash
            caller($i);
        last unless defined $package;
        $i++;
        if ($subroutine eq "(eval)" || $evaltext) {
            return 1;
        }
    };
    0;
}

1;
# ABSTRACT: Utilities related to eval()

__END__

=pod

=encoding UTF-8

=head1 NAME

Eval::Util - Utilities related to eval()

=head1 VERSION

This document describes version 0.001 of Eval::Util (from Perl distribution Eval-Util), released on 2018-03-05.

=head1 SYNOPSIS

 use Eval::Util qw(inside_eval);

 eval { say "foo" if inside_eval() };
 say "bar" if inside_eval();
 # will print C<foo> but not C<bar>.

=head1 DESCRIPTION

=head1 FUNCTIONS

None exported by default, but they are exportable.

=head2 inside_eval

Usage: inside_eval() => bool

Will check if running code is inside eval() (either string eval or block eval).
This is done via examining the stack trace and checking for frame with
subroutine named C<(eval)>.

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

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
