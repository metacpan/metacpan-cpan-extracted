use strict;
use warnings;

package Zest::Author::TABULO::Util::ShareDir;
our $VERSION = '1.000012';

use Path::Tiny;
use File::ShareDir ();

use Exporter::Shiny qw( dist_file dist_dir);

#region: #== UTILITY FUNCTIONS (EXPORT_OK) ==

sub dist_file {
    my $pkg = shift;
    eval { path( dist_dir($pkg)->child(@_) ) };
}

sub dist_dir {

    # Code adopted from L<File::Share>, which unfortunately does not work when we are in BUILD dir (blib/lib).
    my ($dist) = (@_);
    $dist =~ s![.]pm$!!;   # strip trailing .pm (if any)
    $dist =~ s!(::|/)!-!g; # e.g. ==> Pod-Wordlist-Author-TABULO

    ( my $inc = $dist ) =~ s!(-|::)!/!g; # e.g.        Pod/Wordlist/Author/TABULO
    $inc .= '.pm';                       # e.g.:                    Pod/Wordlist/Author/TABULO.pm'
    my $pth = $INC{$inc} || '';          # e.g.: $BUILD(/blib)?/lib/Pod/Wordlist/Author/TABULO.pm'
    $pth =~ s/$inc$//;                   # e.g.: $BUILD(/blib)?/lib'

    # Handle the case where t looks like we are in a build directory or a in a development repo
    for ( $pth || () ) {

        my $path = path($pth);                               # convert to Path::Tiny object
        $path = $path->parent->realpath;                     # strip trailing /lib
        $path = $path->parent if $path->basename eq "blib";  # In case the module might have been loaded from blib/lib.
         # $path should now refer to $BUILD (or $REPO), hopefully.
        next unless $path;

        # Does it look like we are in a development repo (rather than in an installed location) ?
        my $in_repo;
        foreach (qw/.gitignore Changes META.json Meta.yml README README.md dist.ini/) {
            $path->child($_)->exists and do { $in_repo=1; last };
        }
        next unless $in_repo // 0;

        next unless ($path = $path->child("share"))->is_dir;
        return $path;
    }
    require File::ShareDir;
    return eval { path( File::ShareDir::dist_dir($dist) ) };
}



#endregion (UTILITY FUNCTIONS)

1;

=pod

=encoding UTF-8

=for :stopwords Tabulo[n]

=head1 NAME

Zest::Author::TABULO::Util::ShareDir - DZIL-related utility functions used by TABULO's authoring dist

=head1 VERSION

version 1.000012

=for Pod::Coverage dist_file dist_dir

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
