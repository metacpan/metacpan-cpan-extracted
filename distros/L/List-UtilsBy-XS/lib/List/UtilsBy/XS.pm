package List::UtilsBy::XS;
use 5.008_001;

use strict;
use warnings;

use XSLoader;

use parent qw/Exporter/;

our $VERSION = '0.05';

our @EXPORT_OK = qw(
    sort_by
    rev_sort_by
    nsort_by
    rev_nsort_by

    max_by nmax_by
    min_by nmin_by

    uniq_by

    partition_by
    count_by

    zip_by
    unzip_by

    extract_by

    weighted_shuffle_by

    bundle_by
);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

XSLoader::load __PACKAGE__, $VERSION;

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

List::UtilsBy::XS - XS implementation of List::UtilsBy

=head1 SYNOPSIS

  use List::UtilsBy::XS qw(sort_by);

  sort_by { $_->{foo} } @hash_ref_list

You can use those functions same as List::UtilsBy ones,
but some functions have limitation. See L<LIMITATION> section.

=head1 DESCRIPTION

List::UtilsBy::XS is XS implementation of List::UtilsBy.
Functions are more fast than original ones.

=head1 FUNCTIONS

Same as L<List::UtilsBy>

List::UtilsBy::XS implements following functions.

=over

=item sort_by

=item nsort_by

=item rev_sort_by

=item rev_nsort_by

=item max_by (alias nmax_by)

=item min_by (alias nmin_by)

=item uniq_by

=item partition_by

=item count_by

=item zip_by

=item unzip_by

=item extract_by

=item weighted_shuffle_by

=item bundle_by

=back

=head1 LIMITATIONS

Some functions are implemented by lightweight callback API.
C<sort_by>, C<rev_sort_by>, C<nsort_by>, C<rev_nsort_by>,
C<min_by>, C<max_by>, C<nmin_by>, C<nmax_by>, C<uniq_by>, C<partion_by>,
C<count_by>, C<extract_by>, C<weighted_shuffle_by> are limited some features.

Limitations are:

=head2 Don't change argument C<$_> in code block

L<List::UtilsBy> localizes C<$_> in the code block, but List::UtilsBy::XS
doesn't localize it and it is only alias same as C<map>, C<grep>. So you
should not modify C<$_> in callback subroutine.

=head2 Can't access to arguments as C<@_> in code block

You can access argument as only C<$_> and cannot access as C<@_>,
C<$_[n]>.

=head1 AUTHOR

Syohei YOSHIDA E<lt>syohex@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2013- Syohei YOSHIDA

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<List::UtilsBy>

=cut
