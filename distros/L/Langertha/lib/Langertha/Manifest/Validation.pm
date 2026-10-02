package Langertha::Manifest::Validation;
# ABSTRACT: Internal validation rules shared by the provider manifest value objects
our $VERSION = '0.503';
use Moose::Role;
use B ();
use Scalar::Util qw( blessed );
use URI;
use JSON::MaybeXS ();


# A field whose name contains one of these words is rejected explicitly,
# before the unknown-field check, so the error says WHY: a manifest comes from
# the network and never carries anything that could run a command, load code,
# point at a local secret or inject a prompt (langertha-raider ADR 0007). No v1
# field name contains any of these words. The closed field set is what actually
# keeps such fields out; this list only sharpens the message.
my %FORBIDDEN_WORD = map { $_ => 1 } qw(
  command commands cmd exec shell script run install hook hooks
  class module package code eval require plugin plugins perl
  secret secrets password token credential credentials key apikey env path file
  prompt mission mcp packs skills tools
);

sub _field_words {
  my ($name) = @_;
  ( my $split = $name ) =~ s/([a-z0-9])([A-Z])/$1_$2/g;
  return grep { length } split /[_\-.\s]+/, lc $split;
}

sub _is_forbidden_field {
  my ( $class, $name ) = @_;
  return scalar grep { $FORBIDDEN_WORD{$_} } _field_words($name);
}

# Untrusted text ends up in error messages a client prints: show it escaped
# and bounded, never raw (no terminal escapes, no bidi overrides).
sub _display {
  my ( $class, $text ) = @_;
  $text = '' unless defined $text;
  $text = substr( $text, 0, 64 ) . '...' if length $text > 64;
  $text =~ s/([^\x20-\x7e])/sprintf '\\x{%x}', ord $1/ge;
  return $text;
}

sub _error {
  my ( $class, $message ) = @_;
  die "Langertha::Manifest: $message\n";
}

# Re-raise an error from a nested entry with its location in the document.
sub _rethrow {
  my ( $class, $path, $error ) = @_;
  my $message = blessed($error) && $error->can('message') ? $error->message : "$error";
  $message =~ s/\s+\z//;
  $message =~ s/\ALangertha::Manifest: //;
  die "Langertha::Manifest: $path: $message\n";
}

sub _check_fields {
  my ( $class, $data, %spec ) = @_;
  $class->_error('must be a JSON object') unless ref $data eq 'HASH';
  my %allowed = map { $_ => 1 } @{ $spec{required} || [] }, @{ $spec{optional} || [] };
  for my $field ( sort keys %$data ) {
    next if $allowed{$field};
    my $shown = $class->_display($field);
    $class->_error( "forbidden field '$shown': a manifest never carries "
      . 'commands, code, secrets or prompts' )
      if $class->_is_forbidden_field($field);
    $class->_error("unknown field '$shown'");
  }
  for my $field ( @{ $spec{required} || [] } ) {
    $class->_error("field '$field' is required") unless defined $data->{$field};
  }
  return;
}

# A schema string field: a JSON string (a JSON number is accepted and
# stringified, so "id": 42 serializes back as "42"), never an object/array.
sub _string {
  my ( $class, $what, $value ) = @_;
  return undef unless defined $value;
  $class->_error("$what must be a string") if ref $value;
  return "$value";
}

my $ID_RE = qr/\A[A-Za-z0-9][A-Za-z0-9._-]{0,63}\z/;

sub _check_id {
  my ( $class, $what, $value ) = @_;
  $class->_error( "$what must match [A-Za-z0-9][A-Za-z0-9._-]* (max 64), got '"
    . $class->_display($value) . q{'} )
    unless defined $value && !ref $value && $value =~ $ID_RE;
  return;
}

sub _check_token {
  my ( $class, $what, $value ) = @_;
  $class->_error( "$what must match [a-z][a-z0-9_-]*, got '" . $class->_display($value) . q{'} )
    unless defined $value && !ref $value && $value =~ /\A[a-z][a-z0-9_-]{0,63}\z/;
  return;
}

# http/https, a host, printable ASCII only (IDN hosts go punycode), and no
# userinfo, query or fragment -- the usual places a credential is smuggled
# into a URL. This is best effort: a secret embedded in the PATH
# (/key/SECRET/v1, ;key=SECRET) cannot be told apart from a real path.
sub _check_url {
  my ( $class, $what, $value ) = @_;
  $class->_error("$what: must be an http or https URL")
    unless defined $value && !ref $value && length $value;
  $class->_error("$what: must be printable ASCII (no control, space or non-ASCII characters)")
    if $value =~ /[^\x21-\x7e]/;
  my $uri = URI->new($value);
  my $scheme = $uri->scheme // '';
  $class->_error( "$what: must be an http or https URL, got '" . $class->_display($value) . q{'} )
    unless ( $scheme eq 'http' || $scheme eq 'https' ) && length( $uri->host // '' );
  $class->_error("$what: must not carry userinfo (credentials) in the URL")
    if defined $uri->userinfo;
  $class->_error("$what: must not carry a query string (secrets hide there)")
    if defined $uri->query;
  $class->_error("$what: must not carry a fragment")
    if defined $uri->fragment;
  return;
}

sub _sv_flags {
  my ($value) = @_;
  return B::svref_2object( \$value )->FLAGS;
}

# Is this a NUMBER, not a string? Backend-independent: JSON::PP and
# Cpanel::JSON::XS disagree on whether 1e0 decodes to an integer or a float,
# so the test is "has a numeric slot" (IOK or NOK), and -- when a string is
# cached on it too (a printed number, or a numified string) -- the string must
# be a plain JSON number. A decoded JSON string ("1") has only a string slot
# and fails; a numified Perl string like "1abc" fails on its text.
my $JSON_NUMBER_RE = qr/\A-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][-+]?[0-9]+)?\z/;

sub _is_number {
  my ( $class, $value ) = @_;
  return 0 if !defined $value || ref $value;
  my $flags = _sv_flags($value);
  return 0 unless $flags & ( B::SVp_IOK | B::SVp_NOK );
  return 0 if ( $flags & B::SVp_POK ) && $value !~ $JSON_NUMBER_RE;
  return 1;
}

# A number whose value is whole: 1, 1.0 and 1e0 alike, on every backend.
sub _is_whole_number {
  my ( $class, $value ) = @_;
  return 0 unless $class->_is_number($value);
  return $value == int($value) ? 1 : 0;
}

# A boolean is a JSON boolean, \1 / \0, or the NUMBERS 1 / 0. A JSON string
# ("1", "true", "yes") is not a boolean.
sub _bool {
  my ( $class, $what, $value ) = @_;
  return $value ? 1 : 0 if JSON::MaybeXS::is_bool($value);
  return 0 + $$value if ref $value eq 'SCALAR' && defined $$value && $$value =~ /\A[01]\z/;
  return 0 + $value
    if $class->_is_number($value) && ( $value == 0 || $value == 1 );
  $class->_error("$what must be a boolean");
  return;
}

# Deep copy through JSON: proves the value is plain JSON data (no objects
# other than JSON booleans, no code refs) and detaches it from the caller.
my $CLONE_JSON = JSON::MaybeXS->new( utf8 => 1, canonical => 1, allow_nonref => 1 );

sub _json_clone {
  my ( $class, $what, $value ) = @_;
  my $copy = eval { $CLONE_JSON->decode( $CLONE_JSON->encode($value) ) };
  $class->_error("$what must hold plain JSON data") if $@;
  return $copy;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Manifest::Validation - Internal validation rules shared by the provider manifest value objects

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    package Langertha::Manifest::Endpoint;
    use Moose;
    with 'Langertha::Manifest::Validation';

=head1 DESCRIPTION

The rules every part of a L<Langertha::Manifest> shares: the explicit
rejection of command-, code-, secret- and prompt-shaped fields, the
rejection of unknown fields, and the value checks for ids, tokens, URLs,
numbers and booleans. Composed by L<Langertha::Manifest>,
L<Langertha::Manifest::Endpoint>, L<Langertha::Manifest::Auth> and
L<Langertha::Manifest::Model>.

B<Internal.> Every method of this role is private (underscore-prefixed) and
not part of the public API of the classes that compose it; it lives outside
C<Langertha::Role::> on purpose, because it is not an engine capability.

Validation errors are thrown as C<"Langertha::Manifest: E<lt>reasonE<gt>\n">
(no source location); the public entry points (C<from_hash>, C<from_json>,
the Builder) re-raise them with C<croak>, so the reported location is the
caller's.

=head1 SEE ALSO

=over

=item * L<Langertha::Manifest> - The provider manifest

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
