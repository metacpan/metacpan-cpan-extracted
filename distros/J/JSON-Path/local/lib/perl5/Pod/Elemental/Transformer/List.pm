package Pod::Elemental::Transformer::List;
{
  $Pod::Elemental::Transformer::List::VERSION = '0.102000';
}
use Moose;
use Pod::Elemental::Transformer 0.101620;
with 'Pod::Elemental::Transformer';
# ABSTRACT: transform :list regions into =over/=back to save typing


use Pod::Elemental::Element::Pod5::Command;
use Pod::Elemental::Types qw(FormatName);

use namespace::autoclean;


has format_name => (
  is  => 'ro',
  isa => FormatName,
  default => 'list',
);

sub transform_node {
  my ($self, $node) = @_;

  for my $i (reverse(0 .. $#{ $node->children })) {
    my $para = $node->children->[ $i ];
    next unless $self->__is_xformable($para);
    my @replacements = $self->_expand_list_paras( $para );
    splice @{ $node->children }, $i, 1, @replacements;
  }
}

sub __is_xformable {
  my ($self, $para) = @_;

  return unless $para->isa('Pod::Elemental::Element::Pod5::Region')
         and $para->format_name eq $self->format_name;

  confess("list regions must be pod (=begin :" . $self->format_name . ")")
    unless $para->is_pod;

  return 1;
}

my %_TYPE = (
  '=' => 'def',
  '*' => 'bul',
  '0' => 'num',
);

sub _expand_list_paras {
  my ($self, $parent) = @_;

  my @replacements;

  my $type;
  my $i = 1;

  PARA: for my $para (@{ $parent->children }) {
    unless ($para->isa('Pod::Elemental::Element::Pod5::Ordinary')) {
      push @replacements, $self->__is_xformable($para)
         ? $self->_expand_list_paras($para)
         : $para;

      next PARA;
    }

    my $pip = q{}; # paragraph in progress
    my @lines = split /\n/, $para->content;

    LINE: while (@lines) {
      my $line = shift @lines;
      if (my ($prefix, $rest) = $line =~ m{^(=|\*|(?:[0-9]+\.))\s+(.+)$}) {
        if (length $pip) {
          push @replacements, Pod::Elemental::Element::Pod5::Ordinary->new({
            content => $pip,
          });
        }

        $prefix = '0' if $prefix =~ /^[0-9]/;
        my $line_type = $_TYPE{ $prefix };
        $type ||= $line_type;

        confess("mismatched list types; saw $line_type marker after $type")
          if $line_type ne $type;

        my $method = "__paras_for_$type\_marker";
        my ($marker, $leftover) = $self->$method($rest, $i++);
        push @replacements, $marker;
        if (defined $leftover and length $leftover) {
          while (@lines && $lines[0] =~ /^\s+/) {
            my $cont = shift @lines;
            $cont =~ s/^\s+//;
            $leftover .= " $cont";
          }
          push @replacements, Pod::Elemental::Element::Pod5::Ordinary->new({
            content => $leftover,
          });
        }
        $pip = q{};
      } else {
        $pip .= "$line\n";
      }
    }

    if (length $pip) {
      push @replacements, Pod::Elemental::Element::Pod5::Ordinary->new({
        content => $pip,
      });
    }
  }

  my $indentlevel = 4;
  $indentlevel = $1 if $parent->content =~ /:over<(\d+)>/;
  unshift @replacements, Pod::Elemental::Element::Pod5::Command->new({
    command => 'over',
    content => $indentlevel,
  });

  push @replacements, Pod::Elemental::Element::Pod5::Command->new({
    command => 'back',
    content => '',
  });

  return @replacements;
}

sub __paras_for_num_marker {
  my ($self, $rest, $i) = @_;

  return (
    Pod::Elemental::Element::Pod5::Command->new({
      command => 'item',
      content => $i,
    }),
    $rest,
  );
}

sub __paras_for_def_marker {
  my ($self, $rest) = @_;

  return (
    Pod::Elemental::Element::Pod5::Command->new({
      command => 'item',
      content => $rest,
    }),
    '',
  );
}

sub __paras_for_bul_marker {
  my ($self, $rest) = @_;

  return (
    Pod::Elemental::Element::Pod5::Command->new({
      command => 'item',
      content => '*',
    }),
    $rest,
  );
}

1;

__END__

=pod

=head1 NAME

Pod::Elemental::Transformer::List - transform :list regions into =over/=back to save typing

=head1 VERSION

version 0.102000

=head1 SYNOPSIS

By transforming your L<Pod::Elemental::Document> like this:

  my $xform = Pod::Elemental::Transfomer::List->new;
  $xform->transform_node($pod_document);

You can then produce traditional Pod5 lists by using C<:list> regions like
this:

  =for :list
  * Doe
  a (female) deer
  * Ray
  a drop of golden sun

The behavior of list regions is slighly complex, and described L<below|/LIST
REGION PARSING>.

=head1 ATTRIBUTES

=head2 format_name

This attribute, which defaults to "list" is the region format that will be
processed by this transformer.

=head1 LIST REGION PARSING

There are three kinds of lists: numbered, bulleted, and definition.  Every list
must be only one kind of list.  Trying to mix list styles will result in an
exception during transformation.

Lists can be written as a single paragraph beginning C<< =for :list >> or a
region marked off with C<< =begin :list >> and C<< =end :list >>.  The content
allowed in each of those two types is defined by the L<Pod
specification|perlpodspec> but boils down to this: "for" regions will only be
able to contain list markers and paragraphs of text, while "begin and end"
regions can contain arbitrary Pod paragraphs and nested list regions.

All lists have a default C<indentlevel> value of 4.  Adding
C<< :over<n> >> to a C<=begin :list> definition will result in that list
having an C<indentlevel> of C<n> instead.  (This functionality is not
available for lists defined with C<=for :list>.)

Ordinary paragraphs in list regions are scanned for lines beginning with list
item markers (see below).  If they're found, the list is broken into paragraphs
and markers.  Here's a demonstrative example:

  =for :list
  * Doe
  a deer,
  a female deer
  * Ray
  a drop of golden sun
  or maybe it's a golden
  drop of sun

The above is equivalent to

  =begin :list

  * Doe
  a deer,
  a female deer
  * Ray
  a drop of golden sun
  or maybe it's a golden
  drop of sun

  =end :list

It will be transformed into:

  =over 4

  =item *

  Doe

  a deer,
  a female deer

  =item *

  Ray

  a drop of golden sun
  or maybe it's a golden
  drop of sun

Which renders as:

=over 4

=item *

Doe

a deer,
a female deer

=item *

Ray

a drop of golden sun
or maybe it's a golden
drop of sun

=back

I<rendering ends here>

In other words: the B<C<*>> indicates a new bullet.  The rest of the line is
made into one paragraph, which will become the text of the bullet point when
rendered.  (Yeah, Pod is weird.) To continue the text of the bullet point
on more than one line, start subsequent lines with white space.

  =for :list
  * this bullet line
    continues on a second line

Will be transformed into:

  =over 4

  =item *

  this bullet line continues on a second line

  =back

Which renders as:

=over 4

=item *

this bullet line continues on a second line

=back

I<rendering ends here>

All subsequent lines without markers or leading white space will be kept
together as one paragraph.

Asterisks mark off bullet list items.  Numbered lists are marked off with
"C<1.>" (or any number followed by a dot).  Equals signs mark off definition
lists.  The markers must be followed by a space.

Here's a numbered list:

  =for :list
  1. bell
  2. book
  3. candle

The choice of number doesn't matter.  The generated Pod C<=item> commands will
start with 1 and increase by 1 each time.

This is rendered as:

=over 4

=item 1.

bell

=item 2.

book

=item 3.

candle

=back

I<rendering ends here>

Definition lists are unusual in that the text on the line after a item marker
will be used as the bullet, rather than the next paragraph.  So this input:

  =begin :list

  = benefits

  There are more benefits than can be listed here.

  =end :list

Or this input:

  =for :list
  = benefits
  There are more benefits than can be listed here.

Will become the following output Pod:

  =over 4

  =item benefits

  There are more benefits than can be listed here

  =back

Which is rendered as:

=over 4

=item benefits

There are more benefits than can be listed here

=back

I<rendering ends here>

If you want to nest lists, you have to make the outer list a begin/end region,
like this:

  =begin :list

  * first outer item

  * second outer item

  =begin :list

  1. first inner item

  2. second inner item

  =end :list

  * third outer item

  =end :list

The inner list, above, could have been written as a compact "for" region.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
