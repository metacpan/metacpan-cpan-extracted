package Dist::Zilla::Plugin::PodWeaver;
# ABSTRACT: weave your Pod together from configuration and Dist::Zilla
$Dist::Zilla::Plugin::PodWeaver::VERSION = '4.008';
use Moose;
use Pod::Weaver 3.100710; # logging with proxies
with(
  'Dist::Zilla::Role::FileMunger',
  'Dist::Zilla::Role::FileFinderUser' => {
    default_finders => [ ':InstallModules', ':ExecFiles' ],
  },
);

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod [PodWeaver] is the bridge between L<Dist::Zilla> and L<Pod::Weaver>.  It rips
#pod apart your kinda-Pod and reconstructs it as boring old real Pod.
#pod
#pod =head1 CONFIGURATION
#pod
#pod If the C<config_plugin> attribute is given, it will be treated like a
#pod Pod::Weaver section heading.  For example, C<@Default> could be given.  It may
#pod be given multiple times.
#pod
#pod Otherwise, if a file matching C<./weaver.*> exists, Pod::Weaver will be told to
#pod look for configuration in the current directory.
#pod
#pod Otherwise, it will use the default configuration.
#pod
#pod =attr finder
#pod
#pod [PodWeaver] is a L<Dist::Zilla::Role::FileFinderUser>.  The L<FileFinder> given
#pod for its C<finder> attribute is used to decide which files to munge.  By
#pod default, it will munge:
#pod
#pod =for :list
#pod * C<:InstallModules>
#pod * C<:ExecFiles>
#pod
#pod =method weaver
#pod
#pod This method returns the Pod::Weaver object to be used.  The current
#pod implementation builds a new weaver on each invocation, because one or two core
#pod Pod::Weaver plugins cannot be trusted to handle multiple documents per plugin
#pod instance.  In the future, when that is fixed, this may become an accessor of an
#pod attribute with a builder.  Until this is clearer, use caution when modifying
#pod this method in subclasses.
#pod
#pod =cut

sub weaver {
  my ($self) = @_;

  my $root = $self->zilla->root->stringify;

  my @files = glob("$root/weaver.*");

  my $arg = {
      root        => $root,
      root_config => { logger => $self->logger },
  };

  if ($self->has_config_plugins) {
    my $assembler = Pod::Weaver::Config::Assembler->new;

    my $root = $assembler->section_class->new({ name => '_' });
    $assembler->sequence->add_section($root);

    for my $header ($self->config_plugins) {
      $assembler->change_section($header);
      $assembler->end_section;
    }

    return Pod::Weaver->new_from_config_sequence($assembler->sequence, $arg);
  } elsif (@files) {
    return Pod::Weaver->new_from_config(
      { root   => $root },
      { root_config => { logger => $self->logger } },
    );
  } else {
    return Pod::Weaver->new_with_default_config($arg);
  }
}


sub mvp_aliases { return { config_plugin => 'config_plugins' } }
sub mvp_multivalue_args { qw(config_plugins) }

has config_plugins => (
  isa => 'ArrayRef[Str]',
  traits  => [ 'Array' ],
  default => sub {  []  },
  handles => {
    config_plugins     => 'elements',
    has_config_plugins => 'count',
  },
);

around dump_config => sub
{
  my ($orig, $self) = @_;
  my $config = $self->$orig;

  my $our = {
    $self->has_config_plugins
      ? ( config_plugins => [ $self->config_plugins ] )
      : (),
    finder => $self->finder,
  };

  $our->{plugins} = [];
  for my $plugin (@{ $self->weaver->plugins }) {
    push @{ $our->{plugins} }, {
      class   => $plugin->meta->name,
      name    => $plugin->plugin_name,
      version => $plugin->VERSION,
    };
  }

  $config->{'' . __PACKAGE__} = $our;

  return $config;
};

sub munge_files {
  my ($self) = @_;

  require PPI;
  require Pod::Weaver;
  require Pod::Weaver::Config::Assembler;

  $self->munge_file($_) for @{ $self->found_files };
}

sub munge_file {
  my ($self, $file) = @_;

  $self->log_debug([ 'weaving pod in %s', $file->name ]);

  $self->munge_pod($file);
  return;
}

sub munge_perl_string {
  my ($self, $doc, $arg) = @_;

  my $weaver  = $self->weaver;
  my $new_doc = $weaver->weave_document({
    %$arg,
    pod_document => $doc->{pod},
    ppi_document => $doc->{ppi},
  });

  return {
    pod => $new_doc,
    ppi => $doc->{ppi},
  }
}

sub munge_pod {
  my ($self, $file) = @_;

  my $new_content = $self->munge_perl_string(
    $file->content,
    {
      zilla    => $self->zilla,
      filename => $file->name,
      version  => $self->zilla->version,
      license  => $self->zilla->license,
      authors  => $self->zilla->authors,
      distmeta => $self->zilla->distmeta,
    },
  );

  $file->content($new_content);

  return;
}

with 'Pod::Elemental::PerlMunger' => { -version => 0.100000 };

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::PodWeaver - weave your Pod together from configuration and Dist::Zilla

=head1 VERSION

version 4.008

=head1 DESCRIPTION

[PodWeaver] is the bridge between L<Dist::Zilla> and L<Pod::Weaver>.  It rips
apart your kinda-Pod and reconstructs it as boring old real Pod.

=head1 ATTRIBUTES

=head2 finder

[PodWeaver] is a L<Dist::Zilla::Role::FileFinderUser>.  The L<FileFinder> given
for its C<finder> attribute is used to decide which files to munge.  By
default, it will munge:

=over 4

=item *

C<:InstallModules>

=item *

C<:ExecFiles>

=back

=head1 METHODS

=head2 weaver

This method returns the Pod::Weaver object to be used.  The current
implementation builds a new weaver on each invocation, because one or two core
Pod::Weaver plugins cannot be trusted to handle multiple documents per plugin
instance.  In the future, when that is fixed, this may become an accessor of an
attribute with a builder.  Until this is clearer, use caution when modifying
this method in subclasses.

=head1 CONFIGURATION

If the C<config_plugin> attribute is given, it will be treated like a
Pod::Weaver section heading.  For example, C<@Default> could be given.  It may
be given multiple times.

Otherwise, if a file matching C<./weaver.*> exists, Pod::Weaver will be told to
look for configuration in the current directory.

Otherwise, it will use the default configuration.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 CONTRIBUTORS

=for stopwords David Golden Florian Ragwitz Karen Etheridge Yasutaka ATARASHI Сергей Романов

=over 4

=item *

David Golden <dagolden@cpan.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Yasutaka ATARASHI <yakex@cpan.org>

=item *

Сергей Романов <sromanov-dev@yandex.ru>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
