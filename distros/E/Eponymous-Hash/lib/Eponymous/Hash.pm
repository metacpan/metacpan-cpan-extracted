package Eponymous::Hash;
use PadWalker 'var_name';
use Scalar::Util 'blessed';

our $VERSION = '0.02';

sub import {
  shift;
  my $name = pop || 'eponymous_hash';
  my $calling_class = caller;

  *{"${calling_class}::$name"} = \&eponymous_hash;
}

sub eponymous_hash {
  if (ref $_[0] eq 'HASH') {
    return map {$_ => $_[0]->{$_}} @_[1..$#_];
  }
  elsif (blessed $_[0]) {
    return map {$_ => $_[0]->$_} @_[1..$#_];
  }
  else {
    return map { substr(var_name(1, \$_), 1) => $_ } @_;
  }
}

1;

=head1 NAME

Eponymous::Hash - Translates named variables to a hash list with corresponding keys

=head1 DESCRIPTION

Translates named variables to a hash list with corresponding keys

=head1 USAGE

  use Eponymous::Hash 'epy';

The name 'epy' is arbitrary. You may define any name in the use statement.

B<With scalars>

  my $mammal = 'ponycorn';
  my $diet   = 'sprinkles';

  my %hash = epy($mammal, $diet)
  # (mammal => 'ponycorn', diet => 'sprinkles')


B<With hash reference>

  my $thing = {
    mammal => 'ponycorns',
    diet => 'sprinkls'
  };

  my %hash = epy($thing, 'mammal', 'diet');
  # (mammal => 'ponycorn', diet => 'sprinkles')


B<With blessed object>

  my $thing = Thing->new;
  $thing->mammal; # ponycorns
  $thing->diet;   # sprinkles

  my %hash = epy($thing, 'mammal', 'diet');
  # (mammal => 'ponycorn', diet => 'sprinkles')

=head1 METHODS

=head2 eponymous_hash

Default method name.  If parameter is passed to use statement, parameter will be used instead.

=head1 VERSION

0.02

=head1 AUTHOR

Glen Hinkle C<tempire@cpan.org>
