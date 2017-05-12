package IRC::Mode::Single;
$IRC::Mode::Single::VERSION = '0.092002';
use strictures 2;
use Carp;

=pod

=for Pod::Coverage FLAG MODE PARAM

=cut

sub FLAG  () { 0 }
sub MODE  () { 1 }
sub PARAM () { 2 }

use overload
  bool     => sub { 1 },
  '""'     => 'as_string',
  fallback => 1;


sub new {
  confess "Expected at least a flag and mode" unless @_ >= 3;
  bless [ @_[1 .. $#_] ], $_[0]
}

sub flag  { $_[0]->[FLAG] }
sub char  { $_[0]->[MODE] }
sub param { $_[0]->[PARAM] }

sub as_string {
  my ($self) = @_;
  $self->[FLAG] . $self->[MODE]
    . (defined $self->[PARAM] ? ' '.$self->[PARAM] : '')
}

sub export { [ @{$_[0]} ] }

1;

=pod

=head1 NAME

IRC::Mode::Single - A single IRC mode change

=head1 SYNOPSIS

  my $mode = IRC::Mode::Single->new(
    '+', 'o', 'avenj'
  );

  my $flag = $mode->flag;
  my $mode = $mode->char;
  my $arg  = $mode->param;

=head1 DESCRIPTION

A simple ARRAY-type object representing a single mode change.
These objects stringify into an IRC mode string.

Can be used to turn L<IRC::Toolkit::Modes/mode_to_array> mode ARRAYs
into objects:

  for my $mset (@$mode_array) {
    my $this_mode = IRC::Mode::Single->new( @$mset );
    . . .
  }

Also see L<IRC::Mode::Set>

=head2 new

Constructs a new mode change; expects at least a flag and mode.

=head2 char

The mode character.

=head2 flag

The '-' or '+' flag for this mode change.

=head2 param

The parameter attached to the mode, if any.

=head2 as_string

Produces a mode string (with params attached) for this single mode change.

=head2 export

Retrieve the backing ARRAY without bless/overload magic.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
