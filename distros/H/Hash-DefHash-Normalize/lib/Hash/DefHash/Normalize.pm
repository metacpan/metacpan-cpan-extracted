package Hash::DefHash::Normalize;

our $DATE = '2018-09-10'; # DATE
our $VERSION = '0.040'; # VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       normalize_defhash
               );

sub normalize_defhash($;$) {
    my ($dh, $opts) = @_;

    $opts //= {};
    $opts->{remove_internal_properties}  //= 0;

    my $opt_rip = $opts->{remove_internal_properties};

    my $ndh = {};

  KEY:
    for my $k (keys %$dh) {
        die "Invalid prop/attr syntax '$k', must be word/dotted-word only"
            unless $k =~ /\A(\w+)(?:\.(\w+(?:\.\w+)*))?(?:\((\w+)\))?\z/;

        my ($prop, $attr);
        if (defined $3) {
            $prop = $1;
            $attr = defined($2) ? "$2.alt.lang.$3" : "alt.lang.$3";
        } else {
            $prop = $1;
            $attr = $2;
        }

        my $nk = "$prop" . (defined($attr) ? ".$attr" : "");

        # strip property/attr started with _
        if ($prop =~ /\A_/ || defined($attr) && $attr =~ /\A_|\._/) {
            unless ($opt_rip) {
                $ndh->{$nk} = $dh->{$k};
            }
            next KEY;
        }

        $ndh->{$nk} = $dh->{$k};
    }

    $ndh;
}

1;
# ABSTRACT: Normalize DefHash

__END__

=pod

=encoding UTF-8

=head1 NAME

Hash::DefHash::Normalize - Normalize DefHash

=head1 VERSION

This document describes version 0.040 of Hash::DefHash::Normalize (from Perl distribution Hash-DefHash-Normalize), released on 2018-09-10.

=head1 SYNOPSIS

 use Hash::DefHash::Normalize qw(normalize_defhash);

 my $ndh = normalize_defhash($dh);

=head1 FUNCTIONS

=head2 normalize_defhash($dh[, \%opts ]) => HASH

Normalize and check L<DefHash> C<$dh> (a hashref). Return normalized hash, which
is a shallow copy of C<$dh>. Die on error.

Available options:

=over

=item * remove_internal_properties => BOOL (default: 0)

If set to 1, all properties and attributes starting with underscore (C<_>) with
will be stripped. According to L<DefHash> specification, they are ignored and
usually contain notes/comments/extra information.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Hash-DefHash-Normalize>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Hash-DefHash-Normalize>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Hash-DefHash-Normalize>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<DefHash>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
