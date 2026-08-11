# ABSTRACT: A libgit2 OID (20-byte SHA-1)

package Git::Native::Oid;
use Moo;
use Carp ();
use Git::Libgit2 qw( oid_from_hex oid_to_hex );
use Git::Libgit2::FFI ();
use FFI::Platypus::Buffer qw( scalar_to_buffer );

# Every wrapper method that accepts "Oid|hex" funnels the caller's string in
# here (Repository->object / tree / commit / blob / commit_create / tag_create /
# reference_create, Reference->set_target, Revwalker->push_oid / hide_oid,
# TreeBuilder->insert), so a croak from from_hex would otherwise blame the
# wrapper's line inside this distribution instead of the line that passed the
# bad string. @CARP_NOT makes Carp walk past those frames to the caller - the
# same diagnosis object_by_prefix and commit_create give for their own argument
# checks. A caller class missing from this list only gets a worse blame line,
# never a different failure.
our @CARP_NOT = qw(
  Git::Native::Repository
  Git::Native::Reference
  Git::Native::Revwalker
  Git::Native::TreeBuilder
);

# Holds the raw 20-byte SHA. All other forms (hex, short, pointer) are
# derived. The scalar lives as long as the Oid object - that's the
# anchor libgit2 dereferences via the pointer we hand it.
has raw => (
  is       => 'ro',
  required => 1,
);

# A malformed OID string is a caller error, not a libgit2 error, and dies as a
# croak on purpose - the reasoning is in the POD under from_hex. The check is
# duplicated from Git::Libgit2::oid_from_hex (which croaks to the same effect)
# so the message names Git::Native::Oid->from_hex rather than an FFI helper the
# caller never called; oid_from_hex's own croak is unreachable from here.
sub from_hex {
  my ( $class, $hex ) = @_;
  unless ( defined $hex && $hex =~ /\A[0-9a-fA-F]{40}\z/ ) {
    my $got = defined $hex
      ? sprintf( "'%s' (%d characters)", $hex, length $hex )
      : 'undef';
    # A short run of hex digits is almost always an abbreviated OID, which is
    # a repository lookup rather than a conversion - name the method that does
    # it instead of leaving the caller to find it.
    my $hint = defined $hex && $hex =~ /\A[0-9a-fA-F]{1,39}\z/
      ? ', use Git::Native::Repository->object_by_prefix to resolve an'
        . ' abbreviated OID against a repository'
      : '';
    Carp::croak
      "Git::Native::Oid->from_hex requires a 40-character hex OID, got $got$hint";
  }
  return $class->new( raw => oid_from_hex($hex) );
}

sub from_raw {
  my ( $class, $raw ) = @_;
  Carp::croak 'Git::Native::Oid->from_raw requires exactly 20 bytes of raw OID, got '
    . ( defined $raw ? length($raw) . ' bytes' : 'undef' )
    unless defined $raw && length($raw) == 20;
  return $class->new( raw => $raw );
}

# Construct from a pointer libgit2 returned (e.g. git_reference_target).
# We copy the 20 bytes out so the resulting Oid owns its memory and
# doesn't dangle when the source handle is freed.
sub from_ptr {
  my ( $class, $ptr ) = @_;
  Carp::croak 'Git::Native::Oid->from_ptr: null pointer' unless $ptr;
  my $copy = Git::Libgit2::FFI::ffi()->cast( 'opaque', 'string(20)', $ptr );
  return $class->new( raw => $copy );
}

sub hex {
  my $self = shift;
  my ($ptr) = scalar_to_buffer( $self->{raw} );
  return oid_to_hex($ptr);
}

sub short {
  my ( $self, $n ) = @_;
  $n //= 7;
  return substr( $self->hex, 0, $n );
}

sub ptr {
  my $self = shift;
  my ($p) = scalar_to_buffer( $self->{raw} );
  return $p;
}

use overload
  '""'     => sub { $_[0]->hex },
  # Compare on the hex form so an Oid is equal both to another Oid and to
  # its hex string (the common `$ref->target eq $known_sha` pattern). raw-vs-
  # raw would also work for Oid pairs, but raw-vs-hex-string never matches.
  'eq'     => sub { $_[0]->hex eq (ref $_[1] ? $_[1]->hex : $_[1]) },
  fallback => 1;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Native::Oid - A libgit2 OID (20-byte SHA-1)

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  my $oid = Git::Native::Oid->from_hex('abcd...');
  say $oid;          # full hex
  say $oid->short;   # 7 chars
  $oid->ptr;         # C pointer for libgit2

=head1 DESCRIPTION

A SHA-1 OID. Holds the raw 20 bytes; everything else is derived.
The raw scalar is the anchor for any pointer libgit2 reads it through -
keep the Oid alive as long as the pointer is in use.

An Oid is a plain value object with no libgit2 handle behind it, so it
outlives the repository, reference or commit it came from. Methods all
over L<Git::Native> that take an OID accept either an Oid or a
40-character hex string.

Two operators are overloaded. Stringification (C<"">) gives the full hex
form, so an Oid interpolates and prints without an explicit C<< ->hex >>:

  say "commit $oid";   # 35104eb6815e52f24b06c95cbc53e95943cb532b

and C<eq> compares on hex against either another Oid or a plain hex
string, which is what makes C<< $ref->target eq $known_sha >> work. The
comparison is always on the full 40 characters — C<< $oid eq $oid->short >>
is false, an abbreviation never matches.

A malformed OID B<croaks>; it does not throw a L<Git::Native::Error>. Since
every C<Oid|hex> argument in L<Git::Native> is converted here, that applies
to the whole convenience — C<< $repo->object($hex) >>,
C<< $ref->set_target($hex) >>, C<< $walker->push_oid($hex) >>,
C<< $builder->insert( oid => $hex ) >> and the rest all croak on a string
that is not 40 hex characters. See L</from_hex> for why.

=head2 raw

  my $bytes = $oid->raw;   # 20 binary bytes

The OID as 20 B<binary> bytes, not hex — C<length> is always 20 and the
bytes are not printable. Required at construction; the other forms are
derived from it.

=head2 from_hex

  my $oid = Git::Native::Oid->from_hex('35104eb6815e52f24b06c95cbc53e95943cb532b');

Build an Oid from a full 40-character hex string. Anything shorter dies —
this is not abbreviation-aware, and resolving a short prefix against a
repository is a different operation:
L<Git::Native::Repository/object_by_prefix>, which the croak points at.

The failure is a C<Carp::croak> — a plain string blaming the caller's line,
B<not> a L<Git::Native::Error> — and that is deliberate rather than an
oversight:

A C<Git::Native::Error> carries a C<< ->code >> that came out of libgit2.
A string that is not 40 hex characters never reaches libgit2 at all
(C<git_oid_fromstr> is not called), so there is no code to report; a
synthetic one would be the only fabricated C<< ->code >> in the
distribution, with a C<< ->klass >> naming no libgit2 subsystem.

The code it would have to fabricate is C<GIT_EINVALIDSPEC>, which libgit2
does raise for real — for a refname or refspec it rejects. Sharing it would
make C<< $err->is_invalid_spec >> ambiguous inside a single call: after
C<< $repo->reference_create($name, $hex) >> the caller could no longer tell
a malformed refname (libgit2's verdict on the repository input) from its own
typo in the OID string. That is the same separation
L<Git::Native::Repository/object_by_prefix> keeps for C<is_ambiguous>, and
the same reason its own argument checks croak.

So catch it with C<eval> when the hex came from outside the program, exactly
as for any other argument the caller got wrong. There is no C<< ->code >> to
branch on because libgit2 never said anything about it.

=head2 from_raw

  my $oid = Git::Native::Oid->from_raw($twenty_bytes);

Build an Oid from exactly 20 binary bytes; croaks on any other length, and on
C<undef>. A caller error like L</from_hex>'s, and a croak for the same reason.

=head2 from_ptr

  my $oid = Git::Native::Oid->from_ptr($git_oid_ptr);

Build an Oid from a C<git_oid *> that libgit2 handed out. The 20 bytes are
B<copied>, so the result stays valid after the handle it came from is
freed. Internal plumbing — wrappers use it, callers rarely need it.

=head2 hex

  say $oid->hex;   # 35104eb6815e52f24b06c95cbc53e95943cb532b

The full 40-character lowercase hex form.

=head2 short

  say $oid->short;      # 35104eb
  say $oid->short(10);  # 35104eb681

The first C<$n> hex characters, 7 by default. Purely a prefix of C<hex> —
no uniqueness check against the repository, unlike C<git rev-parse --short>.

=head2 ptr

  Git::Libgit2::FFI::some_call( $oid->ptr );

A C pointer to the raw bytes, for passing into libgit2. It points into the
Oid's own scalar, so the Oid has to stay alive for as long as the pointer
is in use.

=head1 SEE ALSO

L<Git::Native::Reference>, L<Git::Native::Commit>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-git-native/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
