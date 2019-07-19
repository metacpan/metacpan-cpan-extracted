package Dist::Zilla::Plugin::Author::Plicease 2.37 {

  use strict;
  use warnings;
  use Path::Tiny ();
  use File::ShareDir::Dist ();

  # ABSTRACT: Dist::Zilla plugins used by Plicease


  sub dist_dir
  {
    Path::Tiny->new(
      File::ShareDir::Dist::dist_share('Dist-Zilla-Plugin-Author-Plicease')
    );
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Author::Plicease - Dist::Zilla plugins used by Plicease

=head1 VERSION

version 2.37

=head1 DESCRIPTION

This distribution contains some miscellaneous plugins that I use
that should probably not be of any use to anyone else.  Historically
they were used and included by my bundle C<[@Author::Plicease]>, but
I've separated them into their own distribution so they can be
installed without the the full set of prereqs required by the bundle.

=head1 METHODS

=head2 dist_dir

 my $dir = Dist::Zilla::Plugin::Author::Plicease->dist_dir;

Returns this distributions share directory.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
