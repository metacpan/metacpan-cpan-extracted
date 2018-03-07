package List::Util::Uniq;

our $DATE = '2018-03-06'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       uniq_adj uniq_adj_ci uniq_ci
               );

sub uniq_adj {
    my @res;

    return () unless @_;
    my $last = shift;
    push @res, $last;
    for (@_) {
        next if !defined($_) && !defined($last);
        # XXX $_ becomes stringified
        next if defined($_) && defined($last) && $_ eq $last;
        push @res, $_;
        $last = $_;
    }
    @res;
}

sub uniq_adj_ci {
    my @res;

    return () unless @_;
    my $last = shift;
    push @res, $last;
    for (@_) {
        next if !defined($_) && !defined($last);
        # XXX $_ becomes stringified
        next if defined($_) && defined($last) && lc($_) eq lc($last);
        push @res, $_;
        $last = $_;
    }
    @res;
}

sub uniq_ci {
    my @res;

    my %mem;
    my $undef_added;
    for (@_) {
        if (defined) {
            push @res, $_ unless $mem{lc $_}++;
        } else {
            push @res, $_ unless $undef_added++;
        }
    }
    @res;
}

1;
# ABSTRACT: List utilities related to finding unique items

__END__

=pod

=encoding UTF-8

=head1 NAME

List::Util::Uniq - List utilities related to finding unique items

=head1 VERSION

This document describes version 0.002 of List::Util::Uniq (from Perl distribution List-Util-Uniq), released on 2018-03-06.

=head1 SYNOPSIS

 use List::Util::Uniq qw(uniq_adj uniq_adj_ci uniq_ci);

 @res = uniq_adj(1, 4, 4, 3, 1, 1, 2); # 1, 4, 3, 1, 2
 @res = uniq_adj_ci("a", "b", "B", "c", "a"); # "a", "b", "c", "a"
 @res = uniq_ci("a", "b", "B", "c", "a"); # "a", "b", "c"

=head1 FUNCTIONS

Not exported by default but exportable.

=head2 uniq_adj(@list) => LIST

Remove I<adjacent> duplicates from list, i.e. behave more like Unix utility's
B<uniq> instead of L<List::MoreUtils>'s C<uniq> function. Uses string equality
test.

=head2 uniq_adj_ci(@list) => LIST

Like C<uniq_adj> except case-insensitive.

=head2 uniq_ci(@list) => LIST

Like C<List::MoreUtils>' C<uniq> except case-insensitive.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/List-Util-Uniq>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-List-Util-Uniq>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=List-Util-Uniq>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<List::Util>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
