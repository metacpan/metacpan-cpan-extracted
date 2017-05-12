use 5.008;
use strict;
use warnings;

package GraphViz::ISA;
our $VERSION = '1.100860';
# ABSTRACT: Graphing class hierarchies at run-time
use Carp;
use GraphViz;
our $AUTOLOAD;

sub new {
    my $this  = shift;
    my $class = ref($this) || $this;
    my $self  = {};
    bless $self, $class;
    $self->_init(@_);
    return $self;
}

sub _init {
    my ($self, $that) = @_;
    my $pkg = ref($that) || $that;
    $self->{g} = GraphViz->new();
    my $tree = { $pkg => $self->isatree($pkg) };
    $self->graph($tree);
}

sub isatree {
    my ($self, $pkg) = @_;
    no strict 'refs';
    my $isa = *{"$pkg\::ISA"}{ARRAY};
    return {} unless @$isa;
    my %out;
    for my $base (@$isa) {
        $out{$base} = $self->isatree($base);
    }
    return \%out;
}

sub graph {
    my ($self, $tree) = @_;
    return unless keys %$tree;
    for my $pkg (keys %$tree) {
        $self->{g}->add_node($pkg);
        $self->{g}->add_edge($_, $pkg) for keys %{ $tree->{$pkg} };
        $self->graph($tree->{$pkg});
    }
}

sub AUTOLOAD {
    my $self = shift;
    my $type = ref($self) or croak "$self is not an object";
    (my $name = $AUTOLOAD) =~ s/.*:://;
    return if $name =~ /DESTROY/;

    # hm, maybe GraphViz knows what to do with it...
    $self->{g}->$name(@_);
}
1;


__END__
=pod

=for stopwords isatree

=head1 NAME

GraphViz::ISA - Graphing class hierarchies at run-time

=head1 VERSION

version 1.100860

=head1 SYNOPSIS

  use GraphViz::ISA;
  my $p = Some::Class->new;

  my $g1 = GraphViz::ISA->new($p);
  print $g1->as_png;

  my $g2 = GraphViz::ISA->new('Some::Other::Module');
  print $g2->as_png;

=head1 DESCRIPTION

This class constructs a graph showing the C<@ISA> hierarchy (note:
not object hierarchies) from a package name or a blessed scalar.

The methods described here are defined by this class; all other method calls
are passed to the underlying GraphViz object:

=head1 METHODS

=head2 new

This constructs the object itself and takes a parameter. The parameter
can be either a package name or a scalar blessed into a package. It then
calls C<isatree()> and hands the result to C<graph()>. Then it returns
the newly constructed object.

=head2 isatree

Takes a package name as a parameter and traverses the indicated package's
C<@ISA> recursively, constructing a hash of hashes. If a package's C<@ISA>
is empty, it has an empty hashref as the value in the tree.

=head2 graph

Takes a tree previously constructed by C<isatree()> and traverses it,
creating nodes and edges as it goes along.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=GraphViz-ISA>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/GraphViz-ISA/>.

The development version lives at
L<http://github.com/hanekomu/GraphViz-ISA/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2001 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

