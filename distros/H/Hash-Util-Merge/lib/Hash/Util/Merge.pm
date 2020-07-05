package Hash::Util::Merge;

use v5.10.1;

use strict;
use warnings;

use Exporter ();
use Sub::Util 1.40 qw( set_prototype );

our $VERSION = 'v0.1.2';

# ABSTRACT: utility functions for merging hashes


our @EXPORT_OK = qw/ mergemap /;

sub import {

    # This borrows a technique from List::Util that exports symbols $a
    # and $b to the callers namespace, so that function arguments can
    # simply use $a and $b, akin to how function arguments for sort
    # works.

    my $pkg = caller;
    no strict 'refs'; ## no critic (ProhibitNoStrict)
    ${"${pkg}::a"} = ${"${pkg}::a"};
    ${"${pkg}::b"} = ${"${pkg}::b"};
    goto &Exporter::import;
}


sub mergemap {

    my $pkg = caller;
    no strict 'refs'; ## no critic (ProhibitNoStrict)
    my $glob_a = \ *{"${pkg}::a"};
    my $glob_b = \ *{"${pkg}::b"};

    my ($f, $x, $y) = @_;

    my %r;

    for my $k (keys %$x, keys %$y) {
        next if exists $r{$k};
        local *$glob_a = \ $x->{$k};
        local *$glob_b = \ $y->{$k};
        $r{$k} = $f->();
    }

    return \%r;
}

BEGIN {
    set_prototype '&$$' => \&mergemap;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Hash::Util::Merge - utility functions for merging hashes

=head1 VERSION

version v0.1.2

=head1 SYNOPSIS

  use Hash::Util::Merge qw/ mergemap /;

  my %a = ( x => 1, y => 2 );
  my %b = ( x => 3, y => 7 );

  my $c = mergemap { $a + $b } \%a, \%b;

  # %c = ( x => 4, y => 9 );

=head1 DESCRIPTION

This module provides some syntactic sugar for merging simple
hashes with a function.

=head1 EXPORTS

None by default.

=head2 mergemap

  $hashref = mergemap { fn($a,$b) } \%a, \%b;

For each key in the hashes C<%a> and C<%b>, this function applies the
user-supplied function C<fn> to the corresponding values of that key,
in the resulting hash reference.

If a key does not exist in either of the hashes, then it will return
C<undef>.

=head1 KNOWN ISSUES

L<Readonly> hashes, or those with locked keys, may return an error
when merged with a hash that has other keys.

=head1 SEE ALSO

L<Hash::Merge>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Hash-Util-Merge>
and may be cloned from L<git://github.com/robrwo/Hash-Util-Merge.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Hash-Util-Merge/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

This module uses code from L<List::Util::PP>.

This module was developed from work for Science Photo Library
L<https://www.sciencephoto.com>.

=head1 CONTRIBUTOR

=for stopwords Mohammad S Anwar

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
