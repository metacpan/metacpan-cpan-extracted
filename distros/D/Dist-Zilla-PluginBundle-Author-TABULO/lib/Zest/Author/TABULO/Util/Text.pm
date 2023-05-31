use strict;
use warnings;

package Zest::Author::TABULO::Util::Text;
our $VERSION = '1.000014';

use Text::Trim qw(trim);
use Exporter::Shiny qw( docstr lines_utf8_from strip_comments trim undent);

#region: #== UTILITY FUNCTIONS (EXPORT_OK) ==

sub lines_utf8_from { # function
    my ( @res, @lines );

    ARG: for my $arg (@_) {
        my $ref = ref $arg // '';
        if ( $ref and my $lines_utf8 = eval { $arg->can('lines_utf8') } ) {
            @lines = $lines_utf8->($arg);
        } elsif ( $ref =~ m/^IO$/ ) {
            @lines = <$arg>;
        } else { # assume simple SCALAR
            @lines = split /\n/, $arg;
        }
        chomp(@lines);
        push @res, @lines;
    }
    @res;
}

sub strip_comments { # function
    my @res;
    ARG: for my $arg (@_) {
        my @lines = split /\n/, $arg;
        LINE: for (@lines) {
            chomp; s!^\s+!!; s!\s+$!!; # chomp & trim white space
            next LINE if m/^\s*[#]/;   # skip line comments
            s!\s+[#].*$!!;             # strip side comments
            next LINE unless "$_";     # skip blank lines.
            push @res, $_;
        }
    }
    @res;
}

# [TAU]: Shamelessly copied from: [Filter::Undent](https://metacpan.org/release/KILNA/Filter-Undent-v1.0.3/view/lib/Filter/Undent.pm)
sub undent ($) { ## no critic
    no warnings 'uninitialized';
    if ( $_[0] =~ m/^(\r?\n)*([ \t]+)/ ) {
        my $i = $2;
        return join '', map { s/^\Q$i\E/$1/g; $_ } grep { $_ ne '' }
            split /(.*?\n)/, $_[0];
    }
    return $_[0];
}

sub docstr {
    trim(undent(join("\n", @_)))
}


#endregion (UTILITY FUNCTIONS)

1;

=pod

=encoding UTF-8

=for :stopwords Tabulo[n]

=head1 NAME

Zest::Author::TABULO::Util::Text - DZIL-related utility functions used by TABULO's authoring dist

=head1 VERSION

version 1.000014

=for Pod::Coverage docstr lines_utf8_from strip_comments trim undent

=head1 AUTHORS

Tabulo[n] <dev@tabulo.net>

=head1 LEGAL

This software is copyright (c) 2023 by Tabulo[n].

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

#ABSTRACT: DZIL-related utility functions used by TABULO's authoring dist

## TODO: Actually document some of the below
