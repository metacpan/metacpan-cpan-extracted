package IRC::Toolkit::TS6;
$IRC::Toolkit::TS6::VERSION = '0.092002';
use strictures 2;
use Carp;

use parent 'Exporter::Tiny';
sub ts6_id { __PACKAGE__->new(@_) }
our @EXPORT = our @EXPORT_OK = 'ts6_id';

use overload
  bool  => sub { 1 },
  '&{}' => sub { my $s = shift; sub { $s->next } },
  '""'  => 'as_string',
  fallback => 1;

=pod

=for Pod::Coverage new

=cut

sub new { bless [ split '', $_[1] || 'A'x6 ], $_[0] }

sub as_string { join '', @{ $_[0] } }

sub next {
  my ($self) = @_;

  my $pos = @$self;
  while (--$pos) {
    if ($self->[$pos] eq 'Z') {
      $self->[$pos] = 0;
      return $self->as_string
    } elsif ($self->[$pos] ne '9') {
      $self->[$pos]++;
      return $self->as_string
    } else {
      $self->[$pos] = 'A';
    }
  }

  croak "Ran out of IDs!" if $self->[0] eq 'Z';

  ++$self->[$pos];

  $self->as_string
}

1;

=pod

=head1 NAME

IRC::Toolkit::TS6 - Generate TS6 IDs

=head1 SYNOPSIS

  use IRC::Toolkit::TS6;

  my $idgen = ts6_id();
  my $nextid = $idgen->next;

=head1 DESCRIPTION

Lightweight array-type objects that can produce sequential TS6 IDs.

=head2 ts6_id

The exported B<ts6_id> function will instance a new ID object. B<ts6_id>
optionally takes a start-point as a string (defaults to 'AAAAAA' similar to
C<ratbox>).

The object is overloaded in two ways; it stringifies to the current ID, and
calling it as a C<CODE> ref is the same as calling L</next>:

  my $idgen = ts6_id;
  my $current = "$idgen";  # 'AAAAAA'
  my $next = $idgen->();   # 'AAAAAB'

=head2 as_string

The C<as_string> method explicitly stringifies the current ID.

=head2 next

The C<next> will increment the current ID and return the ID as a string.

If no more IDs are available, B<next> will croak.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>; conceptually derived from the relevant
C<ratbox> function.

=cut
