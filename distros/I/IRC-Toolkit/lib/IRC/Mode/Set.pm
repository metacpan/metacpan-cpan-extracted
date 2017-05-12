package IRC::Mode::Set;
$IRC::Mode::Set::VERSION = '0.092002';
use strictures 2;
use Carp;

use IRC::Mode::Single;
use IRC::Toolkit::Modes;

use Scalar::Util 'blessed';
use Storable 'dclone';

use Moo;

my $str_to_arr = sub {
  ref $_[0] eq 'ARRAY' ? $_[0] : [ split //, $_[0] ]
};

has param_always => (
  lazy    => 1,
  is      => 'ro',
  coerce  => $str_to_arr,
  builder => sub { [ qw/ b k o h v / ] },
);

has param_on_set => (
  lazy    => 1,
  is      => 'ro',
  coerce  => $str_to_arr,
  builder => sub { [ 'l' ] },
);

has mode_array => (
  lazy      => 1,
  is        => 'ro',
  predicate => 'has_mode_array',
  builder   => sub {
    my ($self) = @_;
    mode_to_array( $self->mode_string,
      param_always => $self->param_always,
      param_set    => $self->param_on_set,
      (
        $self->has_params ? (params => $self->params)
         : ()
      ),
    );
  },
);

has params => (
  lazy      => 1,
  is        => 'ro',
  predicate => 'has_params',
  coerce    => sub {
    ref $_[0] eq 'ARRAY' ? $_[0] : [ split ' ', $_[0] ]
  },
  builder => sub {
    [ map {; defined $_->[2] ? $_->[2] : () } @{ $_[0]->mode_array } ]
  },
);


sub as_string { $_[0]->mode_string }

has mode_string => (
  lazy      => 1,
  is        => 'ro',
  predicate => 'has_mode_string',
  builder   => sub { array_to_mode $_[0]->mode_array },
);


sub split_mode_set {
  my ($self, $max) = @_;
  $max ||= 4;

  my @new;
  my @queue = @{ $self->mode_array };
  while (@queue) {
    my @spl = splice @queue, 0, $max;
    push @new, blessed($self)->new(
      mode_array => [ @spl ],
    )
  }

  @new
}


sub clone {
  my ($self) = @_;
  (blessed $self)->new(mode_array => dclone($self->mode_array))
}

sub clone_from_mode {
  my ($self, $mode) = @_;
  my @match = grep {; $_->[1] eq $mode } @{ $self->mode_array };
  return unless @match;
  blessed($self)->new(
    mode_array => dclone(\@match),
  )
}

sub clone_from_params {
  my ($self, $regex) = @_;
  my @match = grep {;
    defined($_->[2]) and $_->[2] =~ m/$regex/
  } @{ $self->mode_array };
  return unless @match;
  blessed($self)->new(
    mode_array => dclone(\@match),
  )
}


sub modes_as_objects {
  map {; IRC::Mode::Single->new(@$_) } @{ $_[0]->mode_array };
}


has _iter => (
  lazy    => 1,
  is      => 'rw',
  builder => sub { 0 },
);

sub next {
  my ($self, %param) = @_;
  my $cur = $self->_iter;
  $self->_iter($cur+1);
  my $item = $self->mode_array->[$cur] || return;
  $param{as_object} ?
    IRC::Mode::Single->new(@$item)
    : $item
}

sub reset {
  my ($self) = @_;
  $self->_iter(0);
  $self
}

=pod

=for Pod::Coverage BUILD has_\w+

=cut

sub BUILD {
  my ($self) = @_;
  confess
    "Expected to be constructed with either a mode_string or mode_array"
    unless $self->has_mode_array or $self->has_mode_string;
}
  

1;

=pod

=head1 NAME

IRC::Mode::Set - A set of parsed IRC mode changes

=head1 SYNOPSIS

  ## Construct a new set of changes from a mode string:
  my $from_string = IRC::Mode::Set->new(
    mode_string => '+o-o+v avenj Joah Gilded',

    ## Optionally specify modes that take parameters (always or when set)
    ## Defaults:
    param_always => 'bkohv',
    param_on_set => 'l',
  );

  my $mode_array = $from_string->mode_array;
  ## $mode_array looks like:
  ## [
  ##   [ '+', 'o', 'avenj' ],
  ##   [ '-', 'o', 'Joah'  ],
  ##   [ '+', 'v', 'Gilded' ],
  ## ]

  ## Iterate over each mode change:
  while (my $change = $from_string->next) {
    ## $change is set to each individual array as seen above, in turn
  }

  ## Reset ->next() iterator to top:
  $from_string->reset;

  ## Like above loop, but get IRC::Mode::Single objects:
  while (my $this_mode = $from_string->next(as_object => 1) ) {
    ## $this_mode is an IRC::Mode::Single
  }

  ## Construct a new set of changes from an ARRAY
  ## (such as produced by IRC::Toolkit::Modes):
  my $from_array = IRC::Mode::Set->new(
    mode_array => $mode_array,
  );

  ## Get an IRC-appropriate string back out:
  my $str_from_array = $from_array->mode_string;

  ## Split a Set into multiple Sets with a max of $count items each
  ## (defaults to 4 changes per set if none specified)
  my @sets = $from_array->split_mode_set( 3 );
  
  ## Create a new Set containing matching items from this Set:
  my $modes_match = $from_array->clone_from_mode('v');
  my $args_match  = $from_array->clone_from_params('Joah');

=head1 DESCRIPTION

These objects provide a simple parser interface to IRC mode changes.

An understanding of the C<CHANMODES=> directive in C<ISUPPORT> will help
immensely -- see L<http://www.irc.org/tech_docs/005.html>

=head2 new

  my $set = IRC::Mode::Set->new(
    mode_string => '+o-o avenj Joah',
  );

  ## Or with IRC::Toolkit::Modes ->
  my $mode_array = mode_to_array($string);
  my $set = IRC::Mode::Set->new(
    mode_array  => $mode_array,
  );

Create a new IRC::Mode::Set from either a string or an ARRAY produced by
L<IRC::Toolkit::Modes>.

B<param_always> can be specified (as a string or an ARRAY of modes) to
indicate modes that are expected to always take a parameter. Defaults to
'bkohv'

B<param_on_set> can be specified (as a string or an ARRAY of modes) to
indicate modes that are expected to take a parameter only when set. Defaults
to 'l'

See L<IRC::Toolkit::ISupport> for an easy way to retrieve these values from a
parsed ISUPPORT (005) numeric.

=head2 clone

Clone the instanced Mode::Set.

=head2 clone_from_mode

Takes a single mode character.

Returns a new Mode::Set composed of only modes in the existing set containing 
the specified mode character.

=head2 clone_from_params

Takes a pattern or regexp object.

Returns a new Mode::Set composed of only modes in the existing set with
parameters matching the pattern.

=head2 mode_array

Returns the array-of-arrays containing each change in the Set.

This is a data structure in the form of:

  [
    [ $mode_flag, $mode_char, $param ],
    ...
  ]

Also see L<IRC::Toolkit::Modes/mode_to_array>

Predicate: B<has_mode_array>

=head2 modes_as_objects

Returns a list of L<IRC::Mode::Single> objects constructed from our current
L</mode_array>.

=head2 mode_string

Returns the string representing the mode change.

Predicate: B<has_mode_string>

=head2 as_string

B<as_string> is an alias for B<mode_string> to retain compatibility with
L<IRC::Mode::Single>.

=head2 params

Retrieve only the parameters to the mode change (as an ARRAY)

Predicate: B<has_params>

=head2 next

Iterates the array-of-arrays composing the Set.

Returns the next ARRAY in the set (or empty list if none left).

If C<< as_object => 1 >> is specified, an L<IRC::Mode::Single> object is
returned.

Reset to top by calling L</reset>.

=head2 reset

Resets the L</next> iterator.

=head2 split_mode_set

Given an integer parameter C<$x>, splits a Set into smaller Sets containing at
most C<$x> single mode changes.

Defaults to 4, which is a common C<ISUPPORT MODES=> setting.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
