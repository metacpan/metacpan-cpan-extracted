package Dist::Zilla::Plugin::Author::Plicease 2.70 {

  use strict;
  use warnings;
  use 5.020;
  use Path::Tiny ();
  use File::ShareDir::Dist ();
  use File::Which ();

  # ABSTRACT: Dist::Zilla plugins used by Plicease


  sub dist_dir
  {
    my $file = Path::Tiny->new(__FILE__);
    if($file->is_absolute)
    {
      return Path::Tiny->new(
        File::ShareDir::Dist::dist_share('Dist-Zilla-PluginBundle-Author-Plicease')
      );
    }
    else
    {
      my $share = $file
        ->absolute
        ->parent
        ->parent
        ->parent
        ->parent
        ->parent
        ->parent
        ->child('share');
      die "no share $share" unless -d $share;
      return $share;
    }
  }


  sub git
  {
    File::Which::which('git') && eval { require Dist::Zilla::Plugin::Git; 1 } ? 1 : 0
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Author::Plicease - Dist::Zilla plugins used by Plicease

=head1 VERSION

version 2.70

=head1 DESCRIPTION

The modules in this namespace contain some miscellaneous L<Dist::Zilla>
plugins that I use to customize my personal L<Dist::Zilla> experience.
Most likely you don't want or need to use them.  If you do run into
one of my distributions my L<Dist::Zilla> bundle includes documentation
that may be able to help:

L<Dist::Zilla::PluginBundle::Author::Plicease>

=head1 METHODS

=head2 dist_dir

 my $dir = Dist::Zilla::Plugin::Author::Plicease->dist_dir;

Returns this distributions share directory.

=head2 git

 my $bool = Dist::Zilla::Plugin::Author::Plicease->git;

Returns true if C<git> and the Git plugins are installed.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2021 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
