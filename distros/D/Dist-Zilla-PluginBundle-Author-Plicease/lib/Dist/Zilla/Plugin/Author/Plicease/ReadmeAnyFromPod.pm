package Dist::Zilla::Plugin::Author::Plicease::ReadmeAnyFromPod 2.71 {

  use 5.020;
  use Moose;
  use URI::Escape ();
  use File::Which ();
  use Ref::Util qw( is_plain_hashref );
  use experimental qw( postderef );

# ABSTRACT: Personal subclass of Dist::Zilla::Plugin::ReadmeAnyFromPod


  extends 'Dist::Zilla::Plugin::ReadmeAnyFromPod';

  around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    my %args = @_ == 1 && is_plain_hashref($_[0]) ? $_[0]->%* : @_;
    foreach my $key (keys %args)
    {
      die "removed key: $key"
        if $key =~ /^(travis_.*|appveyor_user|appveyor)$/;
    }

    return $class->$orig(@_);
  };

  has cirrus_user => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
      my($self) = @_;
      $self->github_user;
    },
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

      foreach my $workflow ($self->workflow->@*)
      {
        $status .= " ![$workflow](https://github.com/@{[ $self->github_user ]}/$name/workflows/$workflow/badge.svg)";
      }
      $status;
    };

    $content =~ s{# NAME\s+(.*?) - (.*?#)}{# $1$status\n\n$2}s;
    $content =~ s{# VERSION\s+version (\d+\.|)\d+\.\d+(\\_\d+|)\s+#}{#}a;
    return $content;
  };

  __PACKAGE__->meta->make_immutable;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Author::Plicease::ReadmeAnyFromPod - Personal subclass of Dist::Zilla::Plugin::ReadmeAnyFromPod

=head1 VERSION

version 2.71

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

This software is copyright (c) 2012-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
