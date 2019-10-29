use 5.008006;
use strict;
use warnings;

my $safe_eval = sub {
	package main;
	local $@;
	my $r = eval $_[0];
	return $r unless $@;
	package JSON::Eval;
	require Carp;
	Carp::croak($@);
};

package JSON::Eval;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Scalar::Util qw(blessed);

sub new {
	my $class = shift;
	my $json = @_ ? $_[0] : do { require JSON::MaybeXS; JSON::MaybeXS->new };
	bless \$json, $class;
}

sub AUTOLOAD {
	my $self = shift;
	our $AUTOLOAD;
	( my $method = $AUTOLOAD ) =~ s/.*:://;
	my $r = $$self->$method(@_);
	return $self if $r == $$self;
	$r;
}

sub decode {
	my $self = shift;
	my $o    = $$self->decode(@_);
	$self->eval_object($o);
}

sub encode {
	my $self = shift;
	my $o    = $self->deparse_object(@_);
	$$self->encode($o);
}

sub eval_object {
	my $self = shift;
	my ($o) = @_;
	if (ref $o eq 'HASH' and keys(%$o)==1 and exists $o->{'$eval'}) {
		return $safe_eval->($o->{'$eval'});
	}
	if (ref $o eq 'HASH' and keys(%$o)==1 and exists $o->{'$scalar'}) {
		my $x = $self->eval_object($o->{'$scalar'});
		return \$x;
	}
	if (ref $o eq 'ARRAY') {
		local $_;
		return [ map(ref($_)?$self->eval_object($_):$_, @$o) ];
	}
	if (ref $o eq 'HASH') {
		local $_;
		return { map { $_ => ref($o->{$_})?$self->eval_object($o->{$_}):$o->{$_} } keys %$o };
	}
	$o;
}

sub deparse_object {
	my $self = shift;
	my ($o) = @_;
	if (ref $o eq 'CODE') {
		require PadWalker;
		my $lexicals = PadWalker::closed_over($o);
		if (keys %$lexicals) {
			require Carp;
			Carp::croak("Cannot serialize coderef that closes over lexical variables to JSON: ".join ",", sort keys %$lexicals);
		}
		require B::Deparse;
		my $dp = 'B::Deparse'->new;
		$dp->ambient_pragmas(strict => 'all', warnings => 'all');
		return { '$eval' => 'sub ' . $dp->coderef2text($o) };
	}
	if (ref $o eq 'ARRAY') {
		local $_;
		return [ map(ref($_)?$self->deparse_object($_):$_, @$o) ];
	}
	if (ref $o eq 'SCALAR' or ref $o eq 'REF') {
		local $_;
		return { '$scalar' => $self->deparse_object($$o) };
	}
	if (ref $o eq 'HASH') {
		local $_;
		return { map { $_ => ref($o->{$_})?$self->deparse_object($o->{$_}):$o->{$_} } keys %$o };
	}
	if (blessed($o) and $o->isa('Type::Tiny')) {
		if ($o->has_library and not $o->is_anon and $o->library->has_type($o->name)) {
			require B;
			return { '$eval' => sprintf('do { require %s; %s->get_type(%s) }', $o->library, B::perlstring($o->library), B::perlstring($o->name)) };
		}
		else {
			require Carp;
			Carp::croak('Very limited support for serializing Type::Tiny objects right now');
		}
	}
	if (blessed($o) and $self->convert_blessed and $o->can('TO_JSON')) {
		my $unblessed = $o->TO_JSON;
		return $self->deparse_object($unblessed);
	}
	$o;
}

sub DESTROY { }

1;

__END__

=pod

=encoding utf-8

=head1 NAME

JSON::Eval - eval Perl code found in JSON

=head1 SYNOPSIS

  my $encoder = JSON::Eval->new();
  
  my $object = {
    coderef   => sub { 2 + shift },
    scalarref => do { my $x = 40; \$x },
  };
  
  my $jsontext = $encoder->encode($object);
  
  my $decoded   = $encoder->decode($jsontext);  
  my $coderef   = $decoded->{coderef};
  my $scalarref = $decoded->{scalarref};
  
  print $coderef->($$scalarref);   # 42

=head1 DESCRIPTION

Perl data structures can contain several types of reference which do not have
a JSON equivalent. This module provides a technique for encoding and decoding
two of those reference types as JSON: coderefs and scalarrefs. (It also has
partial support for L<Type::Tiny> objects.)

Coderefs must be self-contained, not closing over any variables. They will be
encoded as the following JSON:

  { "$eval": "sub { ... }" }

When decoding, any JSON object that contains a single key called "$eval" and
no other keys will be passed through eval to return the original coderef.
(Technically, when decoding, the Perl code being evaluated doesn't have to
return a coderef; it can return anything. This could allow for filehandles
or blessed objects, for example, to be decoded from JSON.)

Scalarrefs are encoded as:

  { "$scalar": ... }

So for example, the following JSON:

  { "foo": { "$scalar:" 42 } }

Will be decoded to this Perl structure:

  { 'foo' => \ 42 }

=head2 Object-Oriented Interface

=head3 C<< new >>

Use the C<new> method to make an encoder.

  my $encoder = JSON::Eval->new($backend);
  my $encoder = JSON::Eval->new();

C<< $backend >> is a JSON::PP-compatible object that JSON::Eval will
use to actually produce valid JSON. Any of L<JSON::PP>, L<JSON::XS>, or
L<Cpanel::JSON::XS> should work fine. If you don't provide a backend,
JSON::Eval will use L<JSON::MaybeXS> to find the best supported backend
available on your system.

=head3 C<< encode >>

Encode a Perl reference to JSON.

  my $jsontext = $encoder->encode($ref);

=head3 C<< decode >>

Decode a Perl reference from JSON.

  my $ref = $encoder->decode($jsontext);

=head3 C<< eval_object >> and C<< deparse_object >>

These don't directly operate on JSON data, but are used internally by
JSON::Eval. If you're a smart cookie, it shouldn't take long for you
to figure out what they do. They're a stable and supported part of the
API, but this is all you're getting in terms of their documentation.

=head3 AUTOLOAD

JSON::Eval uses AUTOLOAD to pass other method calls straight to the
backend.

  my $backend = JSON::PP->new;
  my $encoder = JSON::Eval->new($backend);
  
  $encoder->pretty(1); # $backend->pretty(1)

=head2 Function-Based Interface

there is no function-based interface lol

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=JSON-Eval>.

=head1 SEE ALSO

L<JSON::MaybeXS>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

