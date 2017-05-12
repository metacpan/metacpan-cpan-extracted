package Finnigan::OLE2DirectoryEntry;

use strict;
use warnings FATAL => qw( all );
our $VERSION = 0.0206;

use Finnigan;
use base 'Finnigan::Decoder';

my $UNUSED       = 0xFFFFFFFF;   # -1
my $END_OF_CHAIN = 0xFFFFFFFE;   # -2
my $FAT_SECTOR  = 0xFFFFFFFD;   # -3
my $DIF_SECTOR = 0xFFFFFFFC;   # -4
my $STORAGE = 1;
my $ROOT = 5;

my $DEPTH = -1; # for recursive directory listing

my %SPECIAL = ($END_OF_CHAIN => 1, $UNUSED => 1, $FAT_SECTOR => 1, $DIF_SECTOR => 1);

sub new {
  my ($class, $file, $index) = @_;
  my $self = {file => $file, index => $index};
  bless $self, $class;

  # The directory entries are organized in a red-black tree (for
  # efficiency of access). The following piece of code does an ordered
  # traversal of such a tree and creates a new tree of
  # OLE2DirectoryEntry objects whose child lists are properly ordered,
  # to simplify the code

  my $p = $file->{properties}->[$index];
  
  # copy the property's data
  $self->{name} = $p->name;
  $self->{type} = $p->type;
  $self->{start} = $p->start;
  $self->{size} = $p->data_size;
  
  # process child nodes, if any
  my @stack = ($index);
  my ($left, $right, $child);
  $index = $p->child;
  unless ( $index == $UNUSED ) {
    # start at the leftmost position
    $left = $file->{properties}->[$index]->left;
    $right = $file->{properties}->[$index]->right;
    $child = $file->{properties}->[$index]->child;

    while ( $left != $UNUSED ) {
      push @stack, $index;
      $index = $left;
      $left = $file->{properties}->[$index]->left;
      $right = $file->{properties}->[$index]->right;
      $child = $file->{properties}->[$index]->child;
    }

    while ( $index != $self->{index} ) { # while sid != self.sid:
      push @{$self->{children}}, new Finnigan::OLE2DirectoryEntry($file, $index);

      # try to move right
      $left = $file->{properties}->[$index]->left;
      $right = $file->{properties}->[$index]->right;
      $child = $file->{properties}->[$index]->child;
      if ( $right != $UNUSED ) {
        # and then back to the left
        $index = $right;
        while ( 1 ) {
          $left = $file->{properties}->[$index]->left;
          $right = $file->{properties}->[$index]->right;
          $child = $file->{properties}->[$index]->child;
          last if $left == $UNUSED;
          push @stack, $index;
          $index = $left;
        }
      }
      else {
        # couldn't move right; move up instead
        my $ptr;
        while ( 1 ) {
          $ptr = $stack[-1];
          pop @stack;
          $left = $file->{properties}->[$ptr]->left;
          $right = $file->{properties}->[$ptr]->right;
          $child = $file->{properties}->[$ptr]->child;
          last if $right != $index;
          $index = $right;
        }
        $left = $file->{properties}->[$index]->left;
        $right = $file->{properties}->[$index]->right;
        $child = $file->{properties}->[$index]->child;
        $index = $ptr if $right != $ptr;
      }
      # in the OLE file, entries are sorted on (length, name).
      # for convenience, we sort them on name instead.
      
      #self.kids.sort()
    }
  }

  return $self;
}

sub list {
  my ( $self, $style ) = @_;
  $self->render_list_item($style, $DEPTH) unless $self->type == $ROOT;
  if ( $self->{children} ) {
    $DEPTH++;
    $_->list($style) for @{$self->{children}};
    $DEPTH--;
  }
}

sub find {
  my ( $self, $query) = @_;

  die "find() must be called on the root entry" unless $self->type == $ROOT;

  return $self if $query eq "/";

  $query =~ s%^/+%%;
  $query =~ s%/+$%%;

  my @name = split "\/", $query;

  my $node = $self;
  foreach my $i ( 0 .. $#name ) {
    if ( $node->{children} ) {
      my $match = 0;
      foreach my $child ( @{$node->{children}} ) {
        if ( $child->name eq $name[$i]) {
          $node = $child;
          $match = 1;
          last;
        }
      }
      return undef unless $match;
    }
    else {
      return undef;
    }
  }
  return $node unless $node->name eq $self->name;
  return undef; # not found
}

sub render_list_item {
  my ($self, $style) = @_;
  my $size = $self->size;
  my $size_text = $self->type == $STORAGE ? "" :  "($size bytes)";
  print "  " x $DEPTH, $self->name, " $size_text\n";
}

sub data {
  my $self = shift;
  my $data;

  # get the data
  my $stream_size;
  if ( $self->size ) {
    if ( $self->size > $self->file->header->ministream_max
         or
         $self->type == $ROOT ) {  # the data in the root entry is always in big blocks
      $stream_size = 'big';
    }
    else {
      $stream_size = 'mini';
    }

    my $first = undef;
    my $previous = undef;
    my $size = 0;
    my $fragment_group = undef;
    my @chain = $self->file->get_chain($self->start, $stream_size);

    # assemble contiguous fragments
    my $contiguous;
    while ( 1 ) {
      my $block = shift @chain;
      if ( defined $block ) {
        $contiguous = 0;
        if ( not defined $first ) {
          $first = $block;
          $contiguous = 1;
        }
        if ( defined $previous and $block == $previous + 1 ) {
          $contiguous = 1;
        }
        if ( $contiguous ) {
          $previous = $block;
          $size += $self->file->sector_size($stream_size);
          next;
        }
      }
      last unless defined $first;

      $data .= $self->file->read(
                                 $stream_size, # which depot
                                 $first,       # where
                                 $previous - $first + 1 # how many sectors
                                );

      # my $desc = sprintf "$stream_size blocks %s..%s (%s)", $first, $previous, $previous-$first+1;
      # $desc .= sprintf " of %s bytes", $self->file->sector_size($stream_size);
      # print "$desc\n";

      last unless $block;

      $first = $block;
      $previous = $block;
      $size = $self->file->sector_size;
    }
    return substr($data, 0, $self->size);
  }
  return undef;
}

sub file {
  shift->{file};
}

sub name {
  shift->{name};
}

sub type {
  shift->{type};
}

sub size {
  shift->{size};
}

sub start {
  shift->{start};
}

1;
__END__

=head1 NAME

Finnigan::OLE2DirectoryEntry -- a decoder for the Microsoft OLE2 directory entry

=head1 SYNOPSIS

  use Finnigan;
  my $dir = new Finnigan::OLE2DirectoryEntry($ole2file, 0);
  $dir->list();

=head1 DESCRIPTION

The OLE2 directory entries are organized in a red-black tree (for
efficiency of access). The directory entry's constructor method
B<new()> is called recursively starting from the root directory
contained in the file's 0-th property.

=head2 METHODS

=over 4

=item new($file, $propertyIndex)

The constructor method. Its first argument is a reference to Finnigan::OLE2File, and the second argument is the index of the file's property (Finnigan::OLE2Property) to be decoded as a directory entry. The root directory is always found in property number 0.

=item list($style)

Lists the directory's contents to STDOUT. The style argument can have
three values: wiki, html, and plain (or undefined). The wiki and html
styles have not been implemented yet.

This method is not useful as part of the API (directory listings are
better understood by humans). But once the path to a node is known, it
can be retrieved with the find method.

=item find($path)

Get the directory entry (Finnigan::OLE2DirectoryEntry) matching the
path supplied in the only argument. The directory entry's data method
needs to be called in order to extract the node data.=back

=back

=head2 PRIVATE METHODS

=over 4

=item data

=item file

=item name

=item render_list_item

=item size

=item start

=item type

=back

=head1 SEE ALSO

Finnigan::OLE2File

Finnigan::OLE2Property

L<Windows Compound Binary File Format Specification|http://download.microsoft.com/download/0/B/E/0BE8BDD7-E5E8-422A-ABFD-4342ED7AD886/WindowsCompoundBinaryFileFormatSpecification.pdf>

=head1 AUTHOR

Gene Selkov, E<lt>selkovjr@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Gene Selkov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
