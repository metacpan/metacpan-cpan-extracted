package Dist::Zilla::Plugin::Author::Plicease::ReadmeAnyFromPod 2.62 {

  use 5.014;
  use Moose;
  use URI::Escape ();
  use File::Which ();


  extends 'Dist::Zilla::Plugin::ReadmeAnyFromPod';

  has travis_status => (
    is => 'ro',
  );

  has travis_user => (
    is      => 'ro',
    default => 'plicease',
  );

  has travis_com => (
    is      => 'ro',
    default => 0,
  );

  has travis_base => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
      my($self) = @_;
      $self->travis_com
        ? 'https://travis-ci.com/github'
        : 'https://travis-ci.org',
    },
  );

  has travis_image_base => (
    is => 'ro',
    lazy => 1,
    default => sub {
      my($self) = @_;
      $self->travis_com
        ? 'https://api.travis-ci.com'
        : 'https://travis-ci.org',
    },
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

  has default_branch => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
      my($self) = @_;
      if(File::Which::which('git'))
      {
        my %b = map { $_ => 1 }
                map { s/\s$//r }
                map { s/^\*?\s*//r }
                `git branch`;
        if($b{main} && $b{master})
        {
          $self->log("!! You have both a main and master branch, please switch to just a main branch (or explicitly set default_branch) !!");
          return 'main';
        }
        elsif($b{main})
        {
          $self->log("deteching main as default branch");
          return 'main';
        }
        elsif($b{master})
        {
          $self->log("!! Please switch to using main as the main branch (or explicitly set default_branch) !!");
          return 'master';
        }
        else
        {
          $self->log("!! cannot find either a main or master branch please create one or explicitly set default_branch !!");
          return 'main';
        }
      }
      $self->log("unable to detect default branch assuming main");
      return 'main';  # may need to update the repo
    },
  );

  sub mvp_multivalue_args { qw( workflow ) }

  around get_readme_content => sub {
    my $orig = shift;
    my $self = shift;

    my $content = do {
      no warnings 'redefine';
      local *URI::Escape::uri_escape = sub {
        my($uri) = @_;
        $uri;
      };

      $self->$orig(@_);
    };

    return $content unless $self->type eq 'gfm';

    my $status = do {
      my $name = $self->zilla->name;

      my $cirrus_status = -f $self->zilla->root->child('.cirrus.yml');

      my $status = '';
      $status .= " [![Build Status](https://api.cirrus-ci.com/github/@{[ $self->cirrus_user ]}/$name.svg)](https://cirrus-ci.com/github/@{[ $self->cirrus_user ]}/$name)" if $cirrus_status;
      $status .= " [![Build Status](@{[ $self->travis_image_base ]}/@{[ $self->travis_user ]}/$name.svg?branch=@{[ $self->default_branch ]})](@{[ $self->travis_base ]}/@{[ $self->travis_user ]}/$name)" if $self->travis_status;
      $status .= " [![Build status](https://ci.appveyor.com/api/projects/status/@{[ $self->appveyor ]}/branch/@{[ $self->default_branch ]}?svg=true)](https://ci.appveyor.com/project/@{[ $self->appveyor_user ]}/$name/branch/@{[ $self->default_branch ]})" if $self->appveyor;

      foreach my $workflow (@{ $self->workflow })
      {
        $status .= " ![$workflow](https://github.com/@{[ $self->github_user ]}/$name/workflows/$workflow/badge.svg)";
      }
      $status;
    };

    $content =~ s{# NAME\s+(.*?) - (.*?#)}{# $1$status\n\n$2}s;
    $content =~ s{# VERSION\s+version (\d+\.|)\d+\.\d+(\\_\d+|)\s+#}{#};
    return $content;
  };

  __PACKAGE__->meta->make_immutable;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Author::Plicease::ReadmeAnyFromPod

=head1 VERSION

version 2.62

=head1 SYNOPSIS

 [Author::Plicease::ReadmeAnyFromPod]

=head1 SEE ALSO

=over 4

=item L<Dist::Zilla>

=item L<Dist::Zilla::PluginBundle::Author::Plicease>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012,2013,2014,2015,2016,2017,2018,2019,2020,2021 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
