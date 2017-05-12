package Devel::Caller::Util;

our $DATE = '2015-07-26'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use warnings;
use strict;

use Exporter qw(import);
our @EXPORT_OK = qw(callers);

sub callers {
    my $start = $_[0] // 0;
    my $with_args = $_[1];

    my @res;
    my $i = $start+1;

    while (1) {
        my @caller;
        if ($with_args) {
            {
                package DB;
                @caller = caller($i);
                $caller[11] = [@DB::args] if @caller;
            }
        } else {
            @caller = caller($i);
        }
        last unless @caller;

        push @res, \@caller;
        $i++;
    }

    @res;
}

1;
# ABSTRACT: caller()-related utility routines

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::Caller::Util - caller()-related utility routines

=head1 VERSION

This document describes version 0.03 of Devel::Caller::Util (from Perl distribution Devel-Caller-Util), released on 2015-07-26.

=head1 SYNOPSIS

 use Devel::Util::Caller qw(callers);

 my @callers = callers();

=head1 FUNCTIONS

=head2 callers([ $start=0 [, $with_args] ]) => LIST

A convenience function to return the whole callers stack, produced by calling
C<caller()> repeatedly from frame C<$start+1> until C<caller()> returns empty.
Result will be like:

 (
     #  0          1           2       3             4          5            6           7             8        9          10
     [$package1, $filename1, $line1, $subroutine1, $hasargs1, $wantarray1, $evaltext1, $is_require1, $hints1, $bitmask1, $hinthash1],
     [$package2, $filename2, $line2, ...],
     ...
 )

If C<$with_args> is true, will also return subroutine arguments in the 11th
element of each frame, produced by retrieving C<@DB::args>.

=head1 SEE ALSO

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Devel-Caller-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Devel-Caller-Util>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-Caller-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
