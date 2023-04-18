
use strict;
use warnings;

package Zest::Author::TABULO::Util::List;
our $VERSION = '1.000012';

use List::Util qw(uniq);
use Exporter::Shiny qw(
    flat
    sort_flat
    uniq_flat
    uniq_sort_flat
);


#region: #== UTILITY FUNCTIONS (EXPORT_OK) ==

sub uniq_sort_flat { uniq(sort (flat(@_)))  }
sub sort_flat { sort (flat(@_))  }
sub uniq_flat { uniq(flat(@_)) }
sub flat { # flatten our arguments (shallowly; 1-level deep)
    map {
        ref $_ eq 'ARRAY' ? (@$_) : $_
    } (@_);
}

#endregion (UTILITY FUNCTIONS)

1;

=pod

=encoding UTF-8

=for :stopwords Tabulo[n]

=head1 NAME

Zest::Author::TABULO::Util::List - Utility functions used by TABULO's authoring dist

=head1 VERSION

version 1.000012

=for Pod::Coverage flat sort_flat  uniq_flat  uniq_sort_flat

=head1 AUTHORS

Tabulo[n] <dev@tabulo.net>

=head1 LEGAL

This software is copyright (c) 2023 by Tabulo[n].

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

#ABSTRACT: Utility functions used by TABULO's authoring dist

## TODO: Actually document some of the below
