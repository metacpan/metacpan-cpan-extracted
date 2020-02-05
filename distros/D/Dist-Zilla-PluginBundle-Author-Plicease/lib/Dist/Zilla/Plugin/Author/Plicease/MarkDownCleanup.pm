package Dist::Zilla::Plugin::Author::Plicease::MarkDownCleanup 2.44 {

  use 5.014;
  use Path::Tiny qw( path );
  use Moose;

  # ABSTRACT: add a travis status button to the README.md file


  with 'Dist::Zilla::Role::AfterBuild';

  has travis_status => (
    is => 'ro',
  );

  has travis_user => (
    is      => 'ro',
    default => 'plicease',
  );

  has cirrus_user => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
      my($self) = @_;
      $self->travis_user;
    },
  );

  has appveyor_user => (
    is      => 'ro',
    default => 'plicease',
  );

  has appveyor => (
    is  => 'ro',
    isa => 'Str',
  );

  has github_user => (
    is      => 'ro',
    default => 'plicease',
  );

  has workflow => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
  );

  sub mvp_multivalue_args { qw( workflow ) }

  sub after_build
  {
    my($self) = @_;
    my $readme = $self->zilla->root->child("README.md");
    if(-r $readme)
    {
      my $name = $self->zilla->name;

      my $cirrus_status = -f $self->zilla->root->child('.cirrus.yml');

      my $status = '';
      $status .= " [![Build Status](https://api.cirrus-ci.com/github/@{[ $self->cirrus_user ]}/$name.svg)](https://cirrus-ci.com/github/@{[ $self->cirrus_user ]}/$name)" if $cirrus_status;
      $status .= " [![Build Status](https://secure.travis-ci.org/@{[ $self->travis_user ]}/$name.png)](http://travis-ci.org/@{[ $self->travis_user ]}/$name)" if $self->travis_status;
      $status .= " [![Build status](https://ci.appveyor.com/api/projects/status/@{[ $self->appveyor ]}/branch/master?svg=true)](https://ci.appveyor.com/project/@{[ $self->appveyor_user ]}/$name/branch/master)" if $self->appveyor;

      foreach my $workflow (@{ $self->workflow })
      {
        $status .= " ![$workflow](https://github.com/@{[ $self->github_user ]}/$name/workflows/$workflow/badge.svg)";
      }

      my $content = $readme->slurp;
      $content =~ s{# NAME\s+(.*?) - (.*?#)}{# $1$status\n\n$2}s;
      $content =~ s{# VERSION\s+version (\d+\.|)\d+\.\d+(\\_\d+|)\s+#}{#};
      $readme->spew_raw($content);
    }
    else
    {
      $self->log("no README.md found");
    }
  }

  __PACKAGE__->meta->make_immutable;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Author::Plicease::MarkDownCleanup - add a travis status button to the README.md file

=head1 VERSION

version 2.44

=head1 SYNOPSIS

 [Author::Plicease::MarkDownCleanup]

=head1 SEE ALSO

=over 4

=item L<Dist::Zilla>

=item L<Dist::Zilla::PluginBundle::Author::Plicease>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012,2013,2014,2015,2016,2017,2018,2019,2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
