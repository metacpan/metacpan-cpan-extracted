package LaTeX::TikZ::Scope;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Scope - An object modeling a TikZ scope or layer.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

use Sub::Name ();

use LaTeX::TikZ::Tools;

use Mouse;

=head1 ATTRIBUTES

=head2 C<mods>

=cut

has '_mods' => (
 is       => 'rw',
 isa      => 'Maybe[ArrayRef[LaTeX::TikZ::Mod::Formatted]]',
 init_arg => 'mods',
 default  => sub { [ ] },
);

sub mods { @{$_[0]->_mods} }

has '_mods_cache' => (
 is       => 'ro',
 isa      => 'Maybe[HashRef[LaTeX::TikZ::Mod::Formatted]]',
 init_arg => undef,
 default  => sub { +{ } },
);

=head2 C<body>

=cut

has 'body' => (
 is       => 'ro',
 isa      => 'ArrayRef[Str]',
 required => 1,
 init_arg => 'body',
);

my $my_tc   = LaTeX::TikZ::Tools::type_constraint(__PACKAGE__);
my $ltmf_tc = LaTeX::TikZ::Tools::type_constraint('LaTeX::TikZ::Mod::Formatted');
my $body_tc = __PACKAGE__->meta->find_attribute_by_name('body')
                               ->type_constraint;

around 'BUILDARGS' => sub {
 my ($orig, $class, %args) = @_;

 my $mods = $args{mods};
 if (defined $mods and ref $mods eq 'ARRAY') {
  for my $mod (@$mods) {
   $mod = $ltmf_tc->coerce($mod);
  }
 }

 my $body = $args{body};
 if ($my_tc->check($body)) {
  push @$mods, $body->mods;
  $args{body} = $body->body;
 }

 $args{mods} = $mods;

 $class->$orig(%args);
};

sub BUILD {
 my $scope = shift;

 my $cache = $scope->_mods_cache;

 my @unique_mods;
 for my $mod ($scope->mods) {
  my $tag = $mod->tag;
  next if exists $cache->{$tag};
  $cache->{$tag} = $mod;
  push @unique_mods, $mod;
 }
 $scope->_mods(\@unique_mods);
}

=head1 METHODS

=cut

my $inter = Sub::Name::subname('inter' => sub {
 my ($lh, $rh) = @_;

 my (@left, @common, @right);
 my %where;

 --$where{$_} for keys %$lh;
 ++$where{$_} for keys %$rh;

 while (my ($key, $where) = each %where) {
  if ($where < 0) {
   push @left,   $lh->{$key};
  } elsif ($where > 0) {
   push @right,  $rh->{$key};
  } else {
   push @common, $rh->{$key};
  }
 }

 return \@left, \@common, \@right;
});

=head2 C<instantiate>

=cut

sub instantiate {
 my ($scope) = @_;

 my ($layer, @clips, @raw_mods);
 for ($scope->mods) {
  my $type = $_->type;
  if ($type eq 'clip') {
   unshift @clips, $_->content;
  } elsif ($type eq 'layer') {
   confess("Can't apply two layers in a row") if defined $layer;
   $layer = $_->content;
  } else { # raw
   push @raw_mods, $_->content;
  }
 }

 my @body = @{$scope->body};

 my $mods_string = @raw_mods ? ' [' . join(',', @raw_mods) . ']' : undef;

 if (@raw_mods and @body == 1 and $body[0] =~ /^\s*\\draw\b\s*([^\[].*)\s*$/) {
  $body[0]     = "\\draw$mods_string $1"; # Has trailing semicolon
  $mods_string = undef;                   # Done with mods
 }

 for (0 .. $#clips) {
  my $clip        = $clips[$_];
  my $clip_string = "\\clip $clip ;";
  my $mods_string = ($_ == $#clips and defined $mods_string)
                     ? $mods_string : '';
  unshift @body, "\\begin{scope}$mods_string",
                 $clip_string;
  push    @body, "\\end{scope}",
 }

 if (not @clips and defined $mods_string) {
  unshift @body, "\\begin{scope}$mods_string";
  push    @body, "\\end{scope}";
 }

 if (defined $layer) {
  unshift @body, "\\begin{pgfonlayer}{$layer}";
  push    @body, "\\end{pgfonlayer}";
 }

 return @body;
}

=head2 C<fold>

=cut

sub fold {
 my ($left, $right, $rev) = @_;

 my (@left, @right);

 if ($my_tc->check($left)) {

  if ($my_tc->check($right)) {

   my ($only_left, $common, $only_right) = $inter->(
    $left->_mods_cache,
    $right->_mods_cache,
   );

   my $has_different_layers;
   for (@$only_left, @$only_right) {
    if ($_->type eq 'layer') {
     $has_different_layers = 1;
     last;
    }
   }

   if (!$has_different_layers and @$common) {
    my $x = $left->new(
     mods => $only_left,
     body => $left->body,
    );
    my $y = $left->new(
     mods => $only_right,
     body => $right->body,
    );
    return $left->new(
     mods => $common,
     body => fold($x, $y, $rev),
    );
   } else {
    @right = $right->instantiate;
   }
  } else {
   $body_tc->assert_valid($right);
   @right = @$right;
  }

  @left = $left->instantiate;
 } else {
  if ($my_tc->check($right)) {
   return fold($right, $left, 1);
  } else {
   $body_tc->assert_valid($_) for $left, $right;
   @left  = @$left;
   @right = @$right;
  }
 }

 $rev ? [ @right, @left ] : [ @left, @right ];
}

use overload (
 '@{}' => sub { [ $_[0]->instantiate ] },
);

__PACKAGE__->meta->make_immutable;

=head1 SEE ALSO

L<LaTeX::TikZ>.

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

1; # End of LaTeX::TikZ::Scope
