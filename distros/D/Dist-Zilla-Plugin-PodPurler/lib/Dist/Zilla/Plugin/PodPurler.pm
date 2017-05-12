package Dist::Zilla::Plugin::PodPurler;
{
  $Dist::Zilla::Plugin::PodPurler::VERSION = '0.093401';
}
# ABSTRACT: like PodWeaver, but more erratic and amateurish
use Moose;
use Moose::Autobox 0.08;
use List::MoreUtils qw(any);
with 'Dist::Zilla::Role::FileMunger';

use namespace::autoclean;

use Pod::Elemental 0.092930;
use Pod::Elemental::Selectors -all;
use Pod::Elemental::Transformer::Pod5;
use Pod::Elemental::Transformer::Nester;
use Pod::Elemental::Transformer::Gatherer;


sub munge_file {
  my ($self, $file) = @_;

  return $self->munge_pod($file)
    if $file->name =~ /\.(?:pm|pod)$/i
    and ($file->name !~ m{/} or $file->name =~ m{^lib/});

  return;
}

sub munge_perl_string {
  my ($self, $doc, $arg) = @_;

  my $document = $doc->{pod};
  Pod::Elemental::Transformer::Pod5->new->transform_node($document);

  my $nester = Pod::Elemental::Transformer::Nester->new({
    top_selector => s_command([ qw(head1 method attr) ]),
    content_selectors => [
      s_flat,
      s_command( [ qw(head2 head3 head4 over item back) ]),
    ],
  });

  $nester->transform_node($document);

  for my $pair (
    [ method => 'METHODS'    ],
    [ attr   => 'ATTRIBUTES' ],
  ) {
    my $sel = s_command($pair->[0]);
    if ($document->children->grep($sel)->length) {
      my $gatherer = Pod::Elemental::Transformer::Gatherer->new({
        gather_selector => $sel,
        container       => Pod::Elemental::Element::Nested->new({
          command => 'head1',
          content => "$pair->[1]\n",
        }),
      });

      $gatherer->transform_node($document);

      $gatherer->container->children->grep($sel)->each_value(sub {
        $_->command('head2');
      });
    }
  }

  unless (
    $document->children->grep(sub {
      s_command('head1', $_) and $_->content eq "VERSION\n"
    })->length
  ) {
    my $version_section = Pod::Elemental::Element::Nested->new({
      command  => 'head1',
      content  => "VERSION\n",
      children => [
        Pod::Elemental::Element::Pod5::Ordinary->new({
          content => sprintf "version %s\n", $self->zilla->version,
        }),
      ],
    });

    $document->children->unshift($version_section);
  }

  unless (
    $document->children->grep(sub {
      s_command('head1', $_) and $_->content eq "NAME\n"
    })->length
  ) {
    Carp::croak "couldn't find package declaration in " . $arg->{filename}
      unless my $pkg_node = $doc->{ppi}->find_first('PPI::Statement::Package');

    my $package = $pkg_node->namespace;

    $self->log("couldn't find abstract in " . $arg->{filename})
      unless my ($abstract) = $doc->{ppi} =~ /^\s*#+\s*ABSTRACT:\s*(.+)$/m;

    my $name = $package;
    $name .= " - $abstract" if $abstract;

    my $name_section = Pod::Elemental::Element::Nested->new({
      command  => 'head1',
      content  => "NAME\n",
      children => [
        Pod::Elemental::Element::Pod5::Ordinary->new({
          content => "$name\n",
        }),
      ],
    });

    $document->children->unshift($name_section);
  }

  unless (
    $document->children->grep(sub {
      s_command('head1', $_) and $_->content =~ /\AAUTHORS?\n\z/
    })->length
  ) {
    my @authors = $self->zilla->authors->flatten;
    my $name = @authors > 1 ? 'AUTHORS' : 'AUTHOR';

    my $author_section = Pod::Elemental::Element::Nested->new({
      command  => 'head1',
      content  => "$name\n",
      children => [
        Pod::Elemental::Element::Pod5::Ordinary->new({
          content => join("\n", @authors) . "\n"
        }),
      ],
    });

    $document->children->push($author_section);
  }

  unless (
    $document->children->grep(sub {
      s_command('head1', $_) and $_->content =~ /\A(?:COPYRIGHT|LICENSE)\n\z/
    })->length
  ) {
    my $legal_section = Pod::Elemental::Element::Nested->new({
      command  => 'head1',
      content  => "COPYRIGHT AND LICENSE\n",
      children => [
        Pod::Elemental::Element::Pod5::Ordinary->new({
          content => $self->zilla->license->notice
        }),
      ],
    });

    $document->children->push($legal_section);
  }

  return {
    pod => $document,
    ppi => $doc->{ppi},
  };
}

sub munge_pod {
  my ($self, $file) = @_;

  my $content     = $file->content;
  my $new_content = $self->munge_perl_string(
    $content,
    {
      filename => $file->name,
    },
  );

  $file->content($new_content);
}

with 'Pod::Elemental::PerlMunger';

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Dist::Zilla::Plugin::PodPurler - like PodWeaver, but more erratic and amateurish

=head1 VERSION

version 0.093401

=head1 DESCRIPTION

PodPurler ress, which rips apart your kinda-POD and reconstructs it as boring
old real POD.

=head1 WARNING

This library has been superceded by L<Pod::Weaver> and
L<Dist::Zilla::Plugin::PodWeaver>.  It is unlikely to be updated again unless
there are serious security problems (!?) or someone gives me some money.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
