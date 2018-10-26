#!perl
package Digest::SRI;
use warnings;
use strict;
use Carp;
use Scalar::Util qw/blessed/;
require Digest;
require MIME::Base64;

# For AUTHOR, COPYRIGHT, AND LICENSE see the bottom of this file

our $VERSION = '0.02';

use Exporter 'import';
our @EXPORT_OK = qw/ sri verify_sri /;

my $DEFAULT_ALGO = 'sha512';
my %KNOWN_ALGOS = (
	sha512 => 'SHA-512',
	sha384 => 'SHA-384',
	sha256 => 'SHA-256',
	sha1   => 'SHA-1',
	md5    => 'MD5',
);
my ($KNOWN_ALGO_RE) = map { qr/$_/ } join '|', map {quotemeta}
	sort { length $b <=> length $a or $a cmp $b } keys %KNOWN_ALGOS;

## no critic (RequireArgUnpacking)

sub new {
	my $class = shift;
	if (ref $class) {
		croak "bad argument to new: must be ".__PACKAGE__." instance"
			unless blessed($class) && $class->isa(__PACKAGE__);
		$class->{dig}->reset;
		return $class;
	}
	my $param = @_ ? shift : $DEFAULT_ALGO;
	my ($algo,$expected);
	if ( $param =~ m{\A(${KNOWN_ALGO_RE})-([A-Za-z0-9+/=]+)\z} )
		{ $algo = $1; $expected = $2 }
	else {
		( $algo = lc $param ) =~ s/[\s\-]+//g;
		croak "unknown/unsupported algorithm '$param'"
			unless exists $KNOWN_ALGOS{$algo};
	}
	my $self = {
		algo => $algo,
		dig  => Digest->new( $KNOWN_ALGOS{$algo} ),
	};
	$self->{exp} = $algo.'-'.$expected if defined $expected;
	return bless $self, $class;
}
*reset = \&new;

sub clone {
	my $self = shift;
	my $new_self = {
		algo => $self->{algo},
		dig  => $self->{dig}->clone,
	};
	$new_self->{exp} = $self->{exp} if defined $self->{exp};
	return bless $new_self, ref $self;
}

sub _grokdata {
	my ($obj,$what) = @_;
	if ( my $r = ref $what ) {
		if ($r eq 'GLOB')
			{ return $obj->addfile($what) }
		elsif ($r eq 'SCALAR')
			{ return $obj->new(@_)->add($$what) }
		else
			{ croak "can't handle reference to $r" }
	} else
		{ return $obj->addfilename($what) }
}

sub sri {
	if ( blessed($_[0]) && $_[0]->isa(__PACKAGE__) ) { # method call
		my $self = shift;
		# Note: ->b64digest strips of the trailing padding
		return $self->{algo} . '-' . MIME::Base64::encode($self->{dig}->digest(@_), "");
	} # else, regular function call
	croak "not enough arguments to sri()" unless @_;
	croak "too many arguments to sri()" if @_>2;
	my $data = pop @_;
	return _grokdata(Digest::SRI->new(@_), $data)->sri;
}

sub verify_sri {
	croak "expected two arguments to verify_sri()" unless @_==2;
	my $data = pop @_;
	return _grokdata(Digest::SRI->new(@_), $data)->verify;
}

sub verify {
	my $self = shift;
	( my $l = $self->sri   ) =~ s/=+\z//;
	( my $r = $self->{exp} ) =~ s/=+\z//;
	return $l eq $r;
}

sub addfilename {
	my $self = shift;
	my $fn = shift;
	open my $fh, '<', $fn or croak "couldn't open $fn: $!";
	binmode $fh;
	$self->addfile($fh);
	close $fh;
	return $self;
}

# see Digest::base
sub add       { my $self = shift; $self->{dig}->add(@_);      return $self }
sub addfile   { my $self = shift; $self->{dig}->addfile(@_);  return $self }
sub add_bits  { my $self = shift; $self->{dig}->add_bits(@_); return $self }
sub digest    { my $self = shift; return $self->{dig}->digest(@_)    }
sub hexdigest { my $self = shift; return $self->{dig}->hexdigest(@_) }
sub b64digest { my $self = shift; return $self->{dig}->b64digest(@_) }

1;
__END__

=head1 Name

Digest::SRI - Calculate and verify Subresource Integrity hashes (SRI)

=head1 Synopsis

 use Digest::SRI qw/sri verify_sri/;
 
 print sri($filename),   "\n";       # current default: SHA-512
 print sri($filehandle), "\n";
 print sri(\$string),    "\n";
 print sri("SHA-256", $data), "\n";  # SHA-256, SHA-384, or SHA-512
 
 die "SRI mismatch" unless verify_sri('sha256-...base64...', $data);
 
 my $sri = Digest::SRI->new("SHA-256");
 $sri->addfilename($filename);
 $sri->addfile($filehandle);
 $sri->add($string);
 print $sri->sri, "\n";
 
 my $sri = Digest::SRI->new("sha256-...base64...");
 $sri->add...(...);
 die "SRI mismatch" unless $sri->verify;

=head1 Description

This module provides functions to calculate and verify Subresource
Integrity hashes (SRI). All of the usage is shown in the
L</Synopsis>, with some usage notes here:

=over

=item *

The C<sri> and C<verify_sri> functions both accept either:

=over

=item *

a filename as a plain scalar,

=item *

a filehandle as a reference to a glob, or

=item *

a string of data as a reference to a scalar.

=back

=item *

C<< Digest::SRI->new >> accepts either:

=over

=item *

no argument, which will use the "strongest" hashing algorithm
(currently SHA-512),

=item *

the strings C<"SHA-256">, C<"SHA-384">, or C<"SHA-512"> (or
variants thereof, such as C<"SHA256"> or C<"sha512">) to specify
those algorithms, or

=item *

a string representing a Subresource Integrity hash, which is to be
used for later verification with C<< ->verify >>.

=item *

Some other hashing algorithms, such as C<"MD5">, are currently
accepted, but known-weak hashing algorithms are I<not> recommended
by the W3C spec and they may be rejected by browsers.

=back

=item *

The methods C<< ->sri >> and C<< ->verify >> are destructive
operations, meaning the state of the underlying L<Digest> object
will be reset once you call one of these methods.

=item *

The other methods provided by the L<Digest> family of modules,
such as C<reset> and C<clone>, are also provided by this module.

=item *

Differences in Base64 padding (C<=>) are currently ignored on
verification, but future versions of this module I<may> add
warnings if this is deemed necessary.

=back

This documentation describes version 0.02 of this module.

=head2 References

=over

=item *

L<https://developer.mozilla.org/en-US/docs/Web/Security/Subresource_Integrity>

=item *

L<https://www.w3.org/TR/SRI/#the-integrity-attribute>

=item *

L<https://www.w3.org/TR/CSP2/#source-list-syntax>

=item *

L<https://html.spec.whatwg.org/multipage/scripting.html#attr-script-integrity>

=item *

L<https://tools.ietf.org/html/rfc2045#section-6.8>

=back

=head1 Author, Copyright, and License

Copyright (c) 2018 Hauke Daempfling (haukex@zero-g.net)
at the Leibniz Institute of Freshwater Ecology and Inland Fisheries (IGB),
Berlin, Germany, L<http://www.igb-berlin.de/>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see L<http://www.gnu.org/licenses/>.

=cut

