package LaTeX::TikZ::Mod::Layer;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Mod::Layer - A modifier that specifies a drawing layer.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

use Scalar::Util ();
use List::Util   ();

use LaTeX::TikZ::Mod::Formatted;

use LaTeX::TikZ::Interface;

use Mouse;
use Mouse::Util::TypeConstraints;

=head1 RELATIONSHIPS

This class consumes the L<LaTeX::TikZ::Mod> role, and as such implements the L</tag>, L</covers>, L</declare> and L</apply> methods.

=cut

with 'LaTeX::TikZ::Mod';

=head1 ATTRIBUTES

=head2 C<name>

=cut

has 'name' => (
 is       => 'ro',
 isa      => 'Str',
 required => 1,
);

=head2 C<above>

=cut

subtype 'LaTeX::TikZ::Mod::LevelList'
     => as 'ArrayRef[LaTeX::TikZ::Mod::Layer]';

coerce 'LaTeX::TikZ::Mod::LevelList'
    => from 'Str'
    => via { [ __PACKAGE__->new(name => $_) ] };

coerce 'LaTeX::TikZ::Mod::LevelList'
    => from 'ArrayRef[Str]'
    => via { [ map __PACKAGE__->new(name => $_), @$_ ] };

has '_above' => (
 is       => 'ro',
 isa      => 'LaTeX::TikZ::Mod::LevelList',
 init_arg => 'above',
 default  => sub { [ ] },
 coerce   => 1,
);

sub above { @{$_[0]->_above} }

=head2 C<below>

=cut

has '_below' => (
 is       => 'ro',
 isa      => 'LaTeX::TikZ::Mod::LevelList',
 init_arg => 'below',
 default  => sub { [ ] },
 coerce   => 1,
);

sub below { @{$_[0]->_below} }

has '_score' => (
 is       => 'ro',
 isa      => 'Int',
 init_arg => undef,
 lazy     => 1,
 builder  => '_build_score',
);

=head1 METHODS

=cut

my %layers;

around 'new' => sub {
 my ($orig, $self, %args) = @_;

 my $name = $args{name};
 if (defined $name) {
  $self->meta->find_attribute_by_name('name')
             ->type_constraint->assert_valid($name);
  my $layer = $layers{$name};
  if (defined $layer) {
   confess("Can't redefine layer '$name'") if keys(%args) > 1;
   return $layer;
  }
 }

 return $self->$orig(%args);
};

sub BUILD {
 my ($self) = @_;

 my $name = $self->name;
 $layers{$name} = $self;
 Scalar::Util::weaken($layers{$name});
}

sub DEMOLISH {
 my ($self) = @_;

 delete $layers{$self->name};
}

=head2 C<tag>

=cut

sub tag {
 my ($self) = @_;

 ref($self) . '/' . $self->name;
}

=head2 C<covers>

=cut

sub covers { $_[0]->name eq $_[1]->name }

=head2 C<score>

=cut

{
 our %score;

 sub score {
  my $layer = $_[0];

  my $name = $layer->name;

  return $score{$name} if exists $score{$name};

  my (@lower, $min);
  for ($layer->above) {
   my $cur = $_->score;
   if (defined $cur) {
    $min = $cur if not defined $min or $min < $cur;
   } else {
    push @lower, $_;
   }
  }

  my (@higher, $max);
  for ($layer->below) {
   my $cur = $_->score;
   if (defined $cur) {
    $max = $cur if not defined $max or $max < $cur;
   } else {
    push @higher, $_;
   }
  }

  if (defined $min) {
   if (defined $max) {
    confess("Order mismatch for $name") unless $min < $max;
    $score{$name} = ($min + $max) / 2;
   } else {
    my $i = List::Util::max(values %score);
    $score{$_} = ++$i for $name, @higher;
   }
  } elsif (defined $max) {
   my $i = List::Util::min(values %score);
   $score{$_} = --$i for @lower, $name;
  } else {
   my $i = 0;
   $score{$_} = ++$i for @lower, $name, @higher;
  }

  $score{$name}
 }

=head2 C<declare>

=cut

 sub declare {
  shift;

  return unless @_;

  local %score = (main => 0);

  $_->score for @_;

  my @layers = sort { $score{$a} <=> $score{$b} }
                map { ref() ? $_->name : $_ }
                 keys %score;

  my @intro = map "\\pgfdeclarelayer{$_}",
               grep $_ ne 'main',
                @layers;

  return (
   @intro,
   "\\pgfsetlayers{" . join(',', @layers) . "}",
  );
 }
}

=head2 C<apply>

=cut

sub apply {
 my ($self) = @_;

 LaTeX::TikZ::Mod::Formatted->new(
  type    => 'layer',
  content => $self->name,
 )
}

LaTeX::TikZ::Interface->register(
 layer => sub {
  shift;

  my $name = shift;
  __PACKAGE__->new(name => $name, @_);
 },
);

__PACKAGE__->meta->make_immutable(
 inline_constructor => 0,
);

=head1 SEE ALSO

L<LaTeX::TikZ>, L<LaTeX::TikZ::Mod>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-latex-tikz at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LaTeX-TikZ>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LaTeX::TikZ

=head1 COPYRIGHT & LICENSE

Copyright 2010,2011,2012,2013,2014,2015 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of LaTeX::TikZ::Mod::Layer
