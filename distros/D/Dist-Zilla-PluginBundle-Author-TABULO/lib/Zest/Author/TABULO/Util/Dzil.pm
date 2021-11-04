
use strict;
use warnings;

package Zest::Author::TABULO::Util::Dzil;
our $VERSION = '1.000006';

use Data::OptList;
use Text::Trim;

use Exporter::Shiny qw( grok_plugin grok_plugins);

#region: #== UTILITY FUNCTIONS (EXPORT_OK) ==

## no critic: Prototypes
sub grok_plugin($) { # single plugin ()
    local $_;
    my (@plugin) = @{$_[0]};  # MUST be an ARRAY ref.
    my $v = ref $plugin[$#plugin] ? pop @plugin : {};  # options
    my $k = join '/', grep {; defined && $_ ne '' }  map {; $_= trim($_ // '') }  (@plugin);

    my ( $moniker, $label ) = split( qr{\s*/\s*}, $k, 2 );
        ( $moniker, $label ) = (trim($moniker //= ''),  trim($label //= ''));
    $label =~ s!\A$moniker\Z!!; # in case it starts with that
    my $name = join('/', $moniker || (), $label || ());

    my $p = [ $moniker || (), $name || (), $v // () ];
    @$p ? $p : ()
}

sub grok_plugins { # One or more plugins. Lax style (can be a mix of ARRAY-refs and (k => v) pairs )
    local $_;
    my (@args) = @_;
    my ( @res, @input );

    for my $arg (@args) {
        if ( ref($arg) =~ m/ARRAY/ ) {
            push @res, grok_plugins(@input) if @input; # recurse!
            push @res, grok_plugin($arg);
            @input = ();
        } else {
            push @input, $arg;
        }
    }
    if (@input) {

        my %prefs = (
            moniker        => 'plugins',
            require_unique => 1,
            must_be        => [qw(HASH)],
            );
        my @optlist = @{ Data::OptList::mkopt( \@input, \%prefs ) };

        push @res, map {
            grok_plugin($_);
        } @optlist;
    }

    # say STDERR "Grokked plugins: "; p @res;
    @res;
}




#endregion (UTILITY FUNCTIONS)

1;

=pod

=encoding UTF-8

=for :stopwords Tabulo[n]

=head1 NAME

Zest::Author::TABULO::Util::Dzil - DZIL-related utility functions used by TABULO's authoring dist

=head1 VERSION

version 1.000006

=for Pod::Coverage grok_plugin grok_plugins

=head1 AUTHORS

Tabulo[n] <dev@tabulo.net>

=head1 LEGAL

This software is copyright (c) 2021 by Tabulo[n].

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

#ABSTRACT: DZIL-related utility functions used by TABULO's authoring dist

## TODO: Actually document some of the below
