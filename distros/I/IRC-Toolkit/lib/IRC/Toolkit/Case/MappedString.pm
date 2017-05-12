package IRC::Toolkit::Case::MappedString;
$IRC::Toolkit::Case::MappedString::VERSION = '0.092002';
use strictures 2;
use IRC::Toolkit::Case;
use Scalar::Util 'blessed';
use overload
  bool     => 'length',
  eq       => '_eq',
  ne       => '_ne',
  gt       => '_gt',
  lt       => '_lt',
  ge       => '_ge',
  le       => '_le',
  cmp      => '_cmp',
  '""'     => 'as_string',
  fallback => 1;

=pod

=for Pod::Coverage STR CMAP

=cut

sub STR  () { 0 }
sub CMAP () { 1 }

sub new {
  my ($class, $cmap, $str) = @_;
  unless (defined $str) {
    $str  = $cmap;
    $cmap = 'rfc1459';
  }
  bless [ $str, $cmap ], $class
}

sub as_string { $_[0]->[STR] }
sub casemap   { $_[0]->[CMAP] }
sub length    { length $_[0]->[STR] }

sub as_upper {
  my ($self) = @_;
  blessed($self)->new( 
    $self->[CMAP],
    uc_irc( $self->[STR], $self->[CMAP] )
  )
}

sub as_lower {
  my ($self) = @_;
  blessed($self)->new(
    $self->[CMAP],
    lc_irc( $self->[STR], $self->[CMAP] )
  )
}

sub _eq {
  my ($self) = @_;
  eq_irc( $_[1], $self->[STR], $self->[CMAP] )
}

sub _ne {
  my ($self) = @_;
  ! eq_irc( $_[1], $self->[STR], $self->[CMAP] )
}

sub _cmp {
  my ($self) = @_;
  uc_irc( $self->[STR], $self->[CMAP] ) cmp uc_irc( $_[1], $self->[CMAP] )
}

sub _gt {
  return _lt( @_[0,1] ) if $_[2];
  my ($self) = @_;
  uc_irc( $self->[STR], $self->[CMAP] ) gt uc_irc( $_[1], $self->[CMAP] )
}

sub _lt {
  return _gt( @_[0,1] ) if $_[2];
  my ($self) = @_;
  uc_irc( $self->[STR], $self->[CMAP] ) lt uc_irc( $_[1], $self->[CMAP] )
}

sub _ge {
  return _le( @_[0,1] ) if $_[2];
  my ($self) = @_;
  uc_irc( $self->[STR], $self->[CMAP] ) ge uc_irc( $_[1], $self->[CMAP] )
}

sub _le {
  return _ge( @_[0,1] ) if $_[2];
  my ($self) = @_;
  uc_irc( $self->[STR], $self->[CMAP] ) le uc_irc( $_[1], $self->[CMAP] )
}


1;

=pod

=head1 NAME

IRC::Toolkit::Case::MappedString - Strings with casemaps attached

=head1 SYNOPSIS

  use IRC::Toolkit::Case;
  my $str = irc_str( strict => 'Nick^[Abc]' );
  if ($str eq 'nick^{abc}') {
    # true
  }

=head1 DESCRIPTION

These overloaded objects represent IRC strings with a specific IRC casemap
attached (such as nick/channel names).

See L<IRC::Toolkit::Case> for more details on IRC casemapping peculiarities.

=head2 new

Creates a new string object.

Expects a casemap and string; if given a single argument, it is taken to be
the string and the casemap defaults to C<RFC1459>.

=head2 as_string

Returns the raw string.

=head2 as_upper

Returns a new string object containing the uppercased (per specified rules)
string.

=head2 as_lower

Returns a new string object containing the lowercased (per specified rules)
string.

=head2 casemap

Returns the currently-configured casemap setting.

=head2 length

Returns the string's length.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
