package Mason::Plugin::QuoteFilters;
# ABSTRACT: Filters for making quoted strings

use Moose;
with 'Mason::Plugin';

our $VERSION = 0.002;# VERSION

__PACKAGE__->meta->make_immutable;

1;


__END__
=pod

=head1 NAME

Mason::Plugin::QuoteFilters - Filters for making quoted strings

=head1 VERSION

version 0.002

=head1 DESCRIPTION

This plugin provides some filter sugar for quoting strings in Mason template
output.

Say you have a Perl variable, $bar, that you need to inject into some
JavaScript.  Currently you would write:

    var foo = '<% $bar %>';

which this author thinks is ugly because the quotes get lost in the syntax.  It
also has a tendency to throw off syntax highlighters.

Instead, using this filter you could write:

    var foo = <% $bar |Q %>;

and get the same end result.

=head1 FILTERS

=over

=item Q

Single quote a string.  Any embedded single quotes are escaped with backslashes.

=item QQ

Double quote a string.  Any embedded double quotes are escaped with backslashes.

=back

=head1 SEE ALSO

L<Mason|Mason>

=head1 AUTHOR

Stephen Clouse <stephenclouse@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Stephen Clouse.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

