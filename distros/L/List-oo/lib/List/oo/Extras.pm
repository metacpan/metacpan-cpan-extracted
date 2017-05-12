package List::oo;
# auto-generated, do not edit

=head1 NAME

List::oo::Extras - auto-generated bits

See L<List::oo>.

=cut

use warnings;
use strict;
use List::Util ();
use List::MoreUtils 0.21 ();

# aliases
sub each_arrayref {CORE::shift->meach_array(@_);}
sub first_index {CORE::shift->firstidx(@_);}
sub first_value {CORE::shift->firstval(@_);}
sub last_index {CORE::shift->lastidx(@_);}
sub last_value {CORE::shift->lastval(@_);}
sub zip {CORE::shift->mesh(@_);}

# methods
sub after {
  my ($self, $block) = @_;
  return($self->new(&List::MoreUtils::after($block, @$self)));
}
sub after_incl {
  my ($self, $block) = @_;
  return($self->new(&List::MoreUtils::after_incl($block, @$self)));
}
sub all {
  my ($self, $block) = @_;
  return(&List::MoreUtils::all($block, @$self));
}
sub any {
  my ($self, $block) = @_;
  return(&List::MoreUtils::any($block, @$self));
}
sub apply {
  my ($self, $block) = @_;
  return($self->new(&List::MoreUtils::apply($block, @$self)));
}
sub before {
  my ($self, $block) = @_;
  return($self->new(&List::MoreUtils::before($block, @$self)));
}
sub before_incl {
  my ($self, $block) = @_;
  return($self->new(&List::MoreUtils::before_incl($block, @$self)));
}
sub each_array {
  my ($self, @list) = @_;
  return(&List::MoreUtils::each_array($self, \@list));
}
sub false {
  my ($self, $block) = @_;
  return(&List::MoreUtils::false($block, @$self));
}
sub first {
  my ($self, $block) = @_;
  return(&List::Util::first($block, @$self));
}
sub firstidx {
  my ($self, $block) = @_;
  return(&List::MoreUtils::firstidx($block, @$self));
}
sub firstval {
  my ($self, $block) = @_;
  return(&List::MoreUtils::firstval($block, @$self));
}
sub indexes {
  my ($self, $block) = @_;
  return($self->new(&List::MoreUtils::indexes($block, @$self)));
}
sub insert_after {
  my ($self, $block, $var1) = @_;
  return($self->new(&List::MoreUtils::insert_after($block, $var1, $self)));
}
sub insert_after_string {
  my ($self, $var1, $var2) = @_;
  return($self->new(&List::MoreUtils::insert_after_string($var1, $var2, $self)));
}
sub lastidx {
  my ($self, $block) = @_;
  return(&List::MoreUtils::lastidx($block, @$self));
}
sub lastval {
  my ($self, $block) = @_;
  return(&List::MoreUtils::lastval($block, @$self));
}
sub max {
  my ($self) = @_;
  return(&List::Util::max(@$self));
}
sub maxstr {
  my ($self) = @_;
  return(&List::Util::maxstr(@$self));
}
sub mesh {
  my ($self, @list) = @_;
  return($self->new(&List::MoreUtils::mesh($self, \@list)));
}
sub min {
  my ($self) = @_;
  return(&List::Util::min(@$self));
}
sub minmax {
  my ($self) = @_;
  return(&List::MoreUtils::minmax(@$self));
}
sub minstr {
  my ($self) = @_;
  return(&List::Util::minstr(@$self));
}
sub natatime {
  my ($self, $var1) = @_;
  return(&List::MoreUtils::natatime($var1, @$self));
}
sub none {
  my ($self, $block) = @_;
  return(&List::MoreUtils::none($block, @$self));
}
sub notall {
  my ($self, $block) = @_;
  return(&List::MoreUtils::notall($block, @$self));
}
sub pairwise {
  my ($self, $block, @list) = @_;
  return($self->new(&List::MoreUtils::pairwise($block, $self, \@list)));
}
sub part {
  my ($self, $block) = @_;
  return(map({$self->new(@$_)} &List::MoreUtils::part($block, @$self)));
}
sub reduce {
  my ($self, $block) = @_;
  return(&List::Util::reduce($block, @$self));
}
sub shuffle {
  my ($self) = @_;
  return($self->new(&List::Util::shuffle(@$self)));
}
sub sum {
  my ($self) = @_;
  return(&List::Util::sum(@$self));
}
sub true {
  my ($self, $block) = @_;
  return(&List::MoreUtils::true($block, @$self));
}
sub uniq {
  my ($self) = @_;
  return($self->new(&List::MoreUtils::uniq(@$self)));
}

1;
