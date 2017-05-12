package Digest::ED2K;
use common::sense;
use Digest::MD4 ();
use Exporter 'import';
our @EXPORT_OK = qw(ed2k ed2k_hex ed2k_base64);

use Digest::base 1.03;
BEGIN { push @Digest::ED2K::ISA, 'Digest::base' }

use version 0.77; our $VERSION = version->declare('v1.1');

sub CHUNK_SIZE() { 9728000 }

sub new {
	my $class = shift;
	bless {
		chunk_ctx => Digest::MD4->new,
	}, ref $class || $class;
}

sub clone {
	my $self = shift;
	bless {
		($self->{ctx} ? (ctx => $self->{ctx}->clone) : ()),
		chunk_ctx => $self->{chunk_ctx}->clone,
		chunk_length => $self->{chunk_length},
	}, ref($self);
}

sub add {
	return shift->add(join '', @_) if @_ > 2;

	my $self = shift;

	# Adding buffer won't cross chunk border.
	# Avoid copying.
	if (CHUNK_SIZE - $self->{chunk_length} > length $_[0]) {
		$self->{chunk_ctx}->add($_[0]);
		$self->{chunk_length} += length $_[0];

		return $self;
	}

	# Buffer crosses chunk border, copy for modification.
	my $buffer = shift;

	while ($buffer) {
		my $need_length = CHUNK_SIZE - $self->{chunk_length};

		my $substr = substr $buffer, 0, $need_length;
		$self->{chunk_ctx}->add($substr);
		$self->{chunk_length} += length $substr;

		# Completed chunk
		if ($self->{chunk_length} == CHUNK_SIZE) {
			my $ctx = $self->{ctx} ||= Digest::MD4->new;

			$ctx->add( $self->{chunk_ctx}->digest );
			$self->{chunk_length} = 0;
		}

		$buffer = substr $buffer, $need_length;
	}

	return $self;
}

sub digest {
	my $self = shift;
	my ($ctx, $chunk_ctx) = delete @$self{qw( ctx chunk_ctx chunk_length )};
	$self->{chunk_ctx} = Digest::MD4->new;

	# One chunk
	return $chunk_ctx->digest unless $ctx;

	# Multi chunk
	$ctx->add( $chunk_ctx->digest )->digest;
}

sub ed2k(@) {
	Digest::ED2K->new->add(@_)->digest;
}

sub ed2k_hex(@) {
	Digest::ED2K->new->add(@_)->hexdigest;
}

sub ed2k_base64(@) {
	Digest::ED2K->new->add(@_)->b64digest;
}

0x6B63;
__END__

=head1 NAME

Digest::ED2K - Calculate ED2K digests

=head1 SYNOPSIS

	# Functional
	use Digest::ED2K qw(ed2k ed2k_hex ed2k_base64);

	my $digest = ed2k $data;
	my $hexdigest = ed2k_hex $data
	my $base64_digest = ed2k_base64 $data;

	# Object Oriented
	use Digest::ED2K;

	my $ctx = Digest::ED2K->new;

	$ctx->add($bytes);
	$ctx->addfile(*FILE);

	my $digest = $ctx->digest;
	my $hexdigest = $ctx->hexdigest;
	my $base64_digest = $ctx->b64digest;

=head1 DESCRIPTION

L<Digest::ED2K> progressively calculates ED2K digests of data.

=head1 FUNCTIONS

L<Digest::ED2K> implements the following functions.

=head2 C<ed2k>

	my $digest = ed2k $bytes, ...;

Generate binary ED2K digest for string.

=head2 C<ed2k_hex>

	my $hexdigest = ed2k_hex $bytes, ...;

Generate hex ED2K digest for string.

=head2 C<ed2k_base64>

	my $base64_digest = ed2k_base64 $bytes, ...;

Generate base64 ED2K digest for string.

=head1 METHODS

L<Digest::ED2K> inherits all methods from L<Digest::base> (See L<Digest> for
documentation) and implements the following new ones.

=head2 C<new>

	my $ctx = Digest->new('ED2K');
	my $ctx = Digest::ED2K->new;

Construct a new L<Digest::ED2K> object.

=head2 C<add>

	$ctx = $ctx->add($bytes, ...);

Append binary data.

=head2 C<clone>

	my $ctx_clone = $ctx->clone;

Clone this message context.

=head2 C<digest>

	my $digest = $ctx->digest;

Binary ED2K digest for this message context.

=head1 REPOSITORY

http://github.com/Kulag/Digest-ED2K

=head1 SEE ALSO

L<Digest>, L<Digest::MD4>

=head1 AUTHOR

Benjamin Herweyer <benjamin.herweyer@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2012, Benjamin Herweyer.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.
