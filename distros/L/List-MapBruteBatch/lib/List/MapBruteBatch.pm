package List::MapBruteBatch;
BEGIN { $List::MapBruteBatch::VERSION = '0.02'; }
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = 'map_brute_batch';

sub map_brute_batch {
    my ($cb, $items, $cb_success, $cb_failure) = @_;

    if ($cb->($items)) {
        return $cb_success->($items) if $cb_success;
        return;
    } elsif (@$items > 1) {
        my $i = @$items;
        my @a = @$items[0 .. ($i / 2)-1];
        my @b = @$items[$i / 2 .. ($i - 1)];

        return (
            map_brute_batch($cb, \@a, $cb_success, $cb_failure),
            map_brute_batch($cb, \@b, $cb_success, $cb_failure),
        );
    } else {
        return $cb_failure->($items) if $cb_failure;
        return;
    }

}

1;

__END__

=encoding utf8

=head1 NAME

List::MapBruteBatch - Do a brute-force batched C<map()> though a list with a callback

=head1 SYNOPSIS

    map_brute_batch($cb, \@list);
    my @ret = map_brute_batch($cb, \@list, \$cb_success, \$cb_failure);

=head1 DESCRIPTION

Firstly. Why would you use this?

You have some C<N> number of items you want to process. You have some
function that can take those C<N>, and it's much cheaper to do them in
one big batch than one at a time.

However, any one of the C<N> items can fail, causing the entire batch
of C<N> to fail with it. When that happens you either don't know which
one failed the batch, or finding out would be tedious.

This module provides a C<map()>-like function to solve that
problem. It'll attempt to process a C<\@list> you provide with a
C<$cb> function that you provide.

If your C<$cb> doesn't return true we bisect the C<\@list> and call
your C<$cb> on each half of the bisected list, and if those fail we
repeat this process until we're processing one item, which may also
fail.

You can optionally provide C<$cb_success> or C<$cb_failure> callbacks,
those'll be called in C<map()>-like fashion on items that fail or
succeed, respectively. You can use this to make the function return a
list of items showing which items ended up failing or succeeding.

=head1 AUTHOR

Ævar Arnfjörð Bjarmason <avar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013-2016 by Ævar Arnfjörð Bjarmason
<avar@cpan.org>

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
