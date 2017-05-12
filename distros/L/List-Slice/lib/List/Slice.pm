package List::Slice;
# ABSTRACT: Slice-like operations on lists
$List::Slice::VERSION = '0.003';
use strict;
require Exporter;

our @ISA        = qw(Exporter);
our @EXPORT_OK  = qw( head tail );

require XSLoader;
XSLoader::load('List::Slice', $List::Slice::VERSION);

1;

__END__

=pod

=head1 NAME

List::Slice - Slice-like operations on lists

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use List::Slice qw( head tail );

=head1 DESCRIPTION

This module provides functions for slicing lists. This is helpful when you
want to do a chain of manipulations on a list (map, grep, sort) and then
slice, without the cumbersome C<(...)[x]> syntax.

=head1 FUNCTIONS

=head2 head

    my @values = head $size, @list;

Returns the first C<$size> elements from C<@list>. If C<$size> is negative, returns
all but the last C<$size> elements from C<@list>.

    @result = head 2, qw( foo bar baz );
    # foo, bar

    @result = head -2, qw( foo bar baz );
    # foo

=head2 tail

    my @values = tail $size, @list;

Returns the last C<$size> elements from C<@list>. If C<$size> is negative, returns
all but the first C<$size> elements from C<@list>.

    @result = tail 2, qw( foo bar baz );
    # bar, baz

    @result = tail -2, qw( foo bar baz );
    # baz

=head1 SEE ALSO

L<List::Util>, L<List::MoreUtils>, L<List::UtilsBy>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
