package HTML::KhatGallery::Plugin::SortNaturally;
use strict;
use warnings;

=head1 NAME

HTML::KhatGallery::Plugin::SortNaturally - Plugin for khatgallery to use Natural sort for index lists.

=head1 VERSION

This describes version B<0.01> of HTML::KhatGallery::Plugin::SortNaturally.

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    # use the khatgallery script
    khatgallery --plugins HTML::KhatGallery::Plugin::SortNaturally I<directory>
    
    # from within a script
    require HTML::KhatGallery;

    my @plugins = qw(HTML::KhatGallery:;Core HTML::KhatGallery::Plugin::SortNaturally);
    HTML::KhatGallery->import(@plugins);
    HTML::KhatGallery->run(%args);

=head1 DESCRIPTION

This is a plugin for khatgallery to use Natural sort for index lists.

=cut

use Sort::Naturally;

=head1 OBJECT METHODS

Documentation for developers and those wishing to write plugins.

=head1 Dir Action Methods

Methods implementing directory-related actions.  All such actions
expect a reference to a state hash, and generally will update either
that hash or the object itself, or both, in the course of their
running.

=head2 sort_images

Sorts the $dir_state->{files} array.

=cut
sub sort_images {
    my $self = shift;
    my $dir_state = shift;

    if (@{$dir_state->{files}})
    {
	my @images = nsort(@{$dir_state->{files}});
	$dir_state->{files} = \@images;
    }
} # sort_images

=head2 sort_dirs

Sorts the $dir_state->{subdirs} array.

=cut
sub sort_dirs {
    my $self = shift;
    my $dir_state = shift;

    if (@{$dir_state->{subdirs}})
    {
	my @dirs = nsort(@{$dir_state->{subdirs}});
	$dir_state->{subdirs} = \@dirs;
    }
} # sort_dirs


=head1 REQUIRES

    Test::More
    HTML::KhatGallery
    Sort::Naturally

=head1 INSTALLATION

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Or, if you're on a platform (like DOS or Windows) that doesn't like the
"./" notation, you can do this:

   perl Build.PL
   perl Build
   perl Build test
   perl Build install

In order to install somewhere other than the default, such as
in a directory under your home directory, like "/home/fred/perl"
go

   perl Build.PL --install_base /home/fred/perl

as the first step instead.

This will install the files underneath /home/fred/perl.

You will then need to make sure that you alter the PERL5LIB variable to
find the modules.

Therefore you will need to change the PERL5LIB variable to add
/home/fred/perl/lib

	PERL5LIB=/home/fred/perl/lib:${PERL5LIB}

=head1 SEE ALSO

perl(1).

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 AUTHOR

    Kathryn Andersen (RUBYKAT)
    perlkat AT katspace dot com
    http://www.katspace.org/tools

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2006 by Kathryn Andersen

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of HTML::KhatGallery::Plugin::SortNaturally
__END__
