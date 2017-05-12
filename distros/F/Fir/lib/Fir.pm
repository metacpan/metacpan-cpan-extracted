package Fir;
use Moose;
use Fir::Major;
use Fir::Minor;
use Tree::DAG_Node;
our $VERSION = '0.33';

has 'root' => (
    is      => 'ro',
    isa     => 'Tree::DAG_Node',
    default => sub {
        my $root = Tree::DAG_Node->new();
        $root->name('root');
        return $root;
    }
);

sub add_major {
    my ( $self, $major, @minors ) = @_;
    my $root = $self->root;
    $root->add_daughter($major);
    foreach my $minor (@minors) {
        $major->add_daughter($minor);
    }
}

sub path {
    my ( $self, $path ) = @_;
    my $root = $self->root;
    foreach my $node ( $root->descendants ) {
        $node->is_selected(0);
    }
    foreach my $node ( $root->daughters ) {
        $node->is_open(0);
    }
    foreach my $node ( sort { length( $b->path ) <=> length( $a->path ) }
        $root->descendants )
    {
        my $node_path = $node->path;
        next unless $path =~ /^$node_path/;
        $node->is_selected(1);
        $node->is_open(1) if $node->isa('Fir::Major');
        $node->mother->is_open(1) unless $node->mother == $root;
        last;
    }
}

sub as_string {
    my $self   = shift;
    my $root   = $self->root;
    my $string = '';
    foreach my $major ( $root->daughters ) {
        if ( $major->is_selected ) {
            $string .= '*' . $major->name . '* ' . $major->path . "\n";
        } else {
            $string .= $major->name . ' ' . $major->path . "\n";
        }
        if ( $major->is_open ) {
            foreach my $minor ( $major->daughters ) {
                if ( $minor->is_selected ) {
                    $string
                        .= '  *' . $minor->name . '* ' . $minor->path . "\n";
                } else {
                    $string
                        .= '  ' . $minor->name . ' ' . $minor->path . "\n";
                }
            }
        }
    }
    return $string;
}

1;

__END__

=head1 NAME

Fir - a Tree::DAG_Node subclass for menu nagivation

=head1 SYNOPSIS

  # set up the following navigation structure:
  # Home (/)
  # \-- About (/about/)
  #   \-- Leon (/about/leon/)
  #   \-- Jake (/about/jake/)
  my $fir  = Fir->new;
  my $home = Fir::Major->new();
  $home->name('Home');
  $home->path('/');
  my $about = Fir::Major->new();
  $about->name('About');
  $about->path('/about/');
  my $leon = Fir::Minor->new();
  $leon->name('Leon');
  $leon->path('/about/leon/');
  my $jake = Fir::Minor->new();
  $jake->name('Jake');
  $jake->path('/about/jake/');
  $fir->add_major($home);
  $fir->add_major( $about, $leon, $jake );

  # and select a path
  $fir->path('/about/');

  # now traverse the tree
  my $root = $fir->root;
  foreach my $major ( $root->daughters ) {
      if ( $major->is_selected ) {
          print '*' . $major->name . '* ' . $major->path . "\n";
      } else {
          print $major->name . ' ' . $major->path . "\n";
      }
      if ( $major->is_open ) {
          foreach my $minor ( $major->daughters ) {
              if ( $minor->is_selected ) {
                  print $minor->name . '* ' . $minor->path . "\n";
              } else {
                  print $minor->name . ' ' . $minor->path . "\n";
              }
          }
      }
  }
  # that prints:
  # Home /
  # *About* /about/
  # Leon /about/leon/
  # Jake /about/jake/
 

=head1 DESCRIPTION

Fir is a Tree::DAG_Node subclass for menu nagivation. Menu navigation
on a web application is fiddly code and this module hides that away 
from you. Note that this module only handles the logic, not the 
display of the navigation.

There are two kinds of nodes L<Fir::Major> nodes are allowed to have
subnodes, while L<Fir::Minor> nodes are not.

=head1 METHODS

=head2 new

The constructor:

  my $fir  = Fir->new;

=head2 add_major

Adds a major navigation node, and possibly some minor navigation
nodes below it:

  my $about = Fir::Major->new();
  $about->name('About');
  $about->path('/about/');
  my $leon = Fir::Minor->new();
  $leon->name('Leon');
  $leon->path('/about/leon/');
  my $jake = Fir::Minor->new();
  $jake->name('Jake');
  $jake->path('/about/jake/');
  $fir->add_major($home);
  $fir->add_major( $about, $leon, $jake );

=head2 path

Given a path, opens and selects nodes for the naviation::

  $fir->path('/about/');

=head2 as_string

A debugging method to help you visualise your tree:

  die $fir->as_string;

=head1 SEE ALSO

L<Fir::Major>, L<Fir::Minor>

=head1 AUTHOR

Leon Brocard E<lt>F<acme@astray.com>E<gt>

=head1 COPYRIGHT

=head1 LICENSE

Copyright (C) 2008, Leon Brocard

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
