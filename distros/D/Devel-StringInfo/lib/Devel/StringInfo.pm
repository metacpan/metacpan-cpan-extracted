#!/usr/bin/perl

package Devel::StringInfo;
use Moose;

use utf8 ();
use Encode qw(decode encode);
use Encode::Guess ();
use Scalar::Util qw(looks_like_number);
use Tie::IxHash;

use namespace::clean -except => 'meta';

our $VERSION = "0.04";

use Sub::Exporter -setup => {
    exports => [
        string_info => sub {
			my ( $class, $name, $args ) = @_;

			my $dumper = $class->new($args);

			return sub {
				my $str = shift;
				$dumper->dump_info($str);
			};
		}
    ],
};

has guess_encoding => (
	isa => "Bool",
	is  => "rw",
	default => 1,
);

has encoding_suspects => (
	isa => "ArrayRef",
	is  => "rw",
	auto_deref => 1,
	default    => sub { [] },
);

has include_value_info => (
	isa => "Bool",
	is  => "rw",
	default => 0,
);

has include_decoded => (
	isa => "Bool",
	is  => "rw",
	default => 1,
);

has include_hex => (
	isa => "Bool",
	is => "rw",
	default => 0,
);

has include_raw => (
	isa => "Bool",
	is  => "rw",
	default => 1,
);

sub sorted_hash {
	my ( @args ) = @_;
	tie my %hash, 'Tie::IxHash', @args;
	return \%hash,
}

sub dump_info {
	my ( $self, $string, @args ) = @_;

	require YAML;
	local $YAML::SortKeys = 0; # let IxHash decide
	local $YAML::UseHeader = 0;
	my $dump = YAML::Dump(sorted_hash @args, $self->filter_data( $self->gather_data($string) ));

	if ( $self->include_raw ) {
		if ( $string =~ /\n/s ) {
			$dump .= "raw = <<END_OF_STRING\n$string\nEND_OF_STRING\n";
		} else {
			$dump .= "raw = <<$string>>\n";
		}
	}

	if ( $self->include_hex ) {
		require Data::HexDump::XXD;
		$dump .= Data::HexDump::XXD::xxd($string) . "\n";
	}

	if ( defined wantarray ) {
		return $dump;
	} else {
		warn "$dump\n";
	}
}

sub filter_data {
	my ( $self, @args ) = @_;

	return @args; # FIXME strip out false keys if omit_false, etc
}

sub gather_data {
	my ( $self, $string ) = @_;

	my @ret = (
		string => $string,
		$self->gather_data_unicode($string),
		( $self->include_value_info ? $self->gather_data_value($string) : () ),,
	);

	wantarray ? @ret : sorted_hash(@ret);
}

sub gather_data_unicode {
	my ( $self, $string ) = @_;	

	if ( utf8::is_utf8($string) ) {
		return (
			$self->gather_data_is_unicode($string),
		);
	} else {
		return (
			$self->gather_data_is_octets($string),
		)
	}
}

sub gather_data_vlaue {
	my ( $self, $string ) = @_;

	for ( $string ) {
		return (
			is_alphanumeric   => 0+ /^[[:alnum:]]+$/s,
			is_printable      => 0+ /^[[:print:]+]$/s,
			is_ascii          => 0+ /^[[:ascii:]+]$/s,
			has_zero          => 0+ /\x{00}/s,
			has_line_ending   => 0+ /[\r\n]/s,
			looks_like_number => looks_like_number($string),
		);
	}	
}

sub gather_data_is_unicode {
	my ( $self, $string ) = @_;

	return (
		is_utf8      => 1,
		char_length  => length($string),
		octet_length => length(encode(utf8 => $string)),
		downgradable => 0+ do {
			my $copy = $string;
			utf8::downgrade($copy, 1); # fail OK
		},
	);
}

sub gather_data_is_octets {
	my ( $self, $string ) = @_;

	return (
		is_utf8      => 0,
		octet_length => length($string),
		( utf8::valid($string)
			? $self->gather_data_utf8_octets($string)
			: $self->gather_data_non_utf8_octets($string) ),
	);
}

sub gather_data_utf8_octets {
	my ( $self, $string ) = @_;

	my $decoded = decode( utf8 => $string );
	
	my $guessed = sorted_hash $self->gather_data_encoding_info($string);

	if ( ($guessed->{guessed_encoding}||'') eq 'utf8' ) {
		return (
			valid_utf8  => 1,
			( $self->include_decoded ? $self->gather_data_decoded( $decoded, $string ) : () ),,
		);
	} else {
		return (
			valid_utf8 => 1,
			( $self->include_decoded ? (
				as_utf8    => sorted_hash($self->gather_data_decoded( $decoded, $string ) ),
				as_guess   => $guessed,
			) : () ),
		);
	}
}

sub gather_data_non_utf8_octets {
	my ( $self, $string ) = @_;

	return (
		valid_utf8 => 0,
		$self->gather_data_encoding_info($string),
	);
}

sub gather_data_encoding_info {
	my ( $self, $string ) = @_;

	return unless $self->guess_encoding;

	my $decoder = Encode::Guess::guess_encoding( $string, $self->encoding_suspects );

	if ( ref $decoder ) {
		my $decoded = $decoder->decode($string);

		return (
			guessed_encoding => $decoder->name,
			( $self->include_decoded ? $self->gather_data_decoded( $decoded, $string ) : () ),
		);
	} else {
		return (
			guess_error => $decoder,
		);
	}
}

sub gather_data_decoded {
	my ( $self, $decoded, $string ) = @_;

	if ( $string ne $decoded ) {
		return (
			decoded_is_same => 0,
			decoded => {
				string => $decoded,
				$self->gather_data($decoded),
			}
		);
	} else {
		return (
			decoded_is_same => 1,
		);
	}
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Devel::StringInfo - Gather information about strings

=head1 SYNOPSIS

	my $string = get_string_from_somewhere();

	use Devel::StringInfo qw(string_info);

	# warn()s a YAML dump in void context
	string_info($string);



	# the above is actually shorthand for:
	Devel::StringInfo->new->dump_info($string);


	# you can also customize with options:
	my $d = Devel::StringInfo->new(
		guess_encoding => 0,
	);


	# and collect data instead of formatting it as a string
	my %hash = $d->gather_data( $string );

	warn "it's a utf8 string" if $hash{is_utf8};

=head1 DESCRIPTION

This module is a debugging aid that helps figure out more information about strings.

Perl has two main "types" of strings, unicode strings (C<utf8::is_utf8> returns
true), and octet strings (just a bunch of bytes).

Depending on the source of the data, what data it interacted with, as well as
the fact that Perl may implicitly upgrade octet streams which represent strings
in the native encoding to unicode strings, it's sometimes hard to know what
exactly is going on with a string.

This module clumps together a bunch of checks you can perform on a string to
figure out what's in it.

=head1 EXPORTS

This module optionally exports a C<string_info> subroutine. It uses
L<Sub::Exporter>, so you can pass any options to the import routine, and they
will be used to construct the dumper for your exported sub:

	use Devel::StringInfo string_info => { guess_encoding => 0 };

=head1 ATTRIBUTES

=over 4

=item guess_encoding

Whether or not to use L<Encode::Guess> to guess the encoding of the data if
it's not a unicode string.

=item encoding_suspects

The list of suspect encodings. See L<Encode::Guess>. Defaults to the empty
list, which is a special case for L<Encode::Guess>.

=item include_value_info

Include some information about the string value (does it contain C<0x00> chars,
is it alphanumeric, does it have newlines, etc).

=item include_decoded

Whether to include a recursive dump of the decoded versions of a non unicode
string.

=item include_hex

Whether to include a L<Data::HexDump::XXD> dump in C<dump_info>.

=item include_raw

Whether to include a simple interpolation of the string in C<dump_info>.

=back

=head1 METHODS

=over 4

=item dump_info $string, %extra_fields

Use L<YAML> to dump information about $string.

In void context prints, in other contexts returns the dump string.

If C<include_raw> is set then a "raw" version (no escaping of the string) is appended
with some boundry markings. This can help understand what's going on if
L<YAML>'s escaping is confusing.

If C<include_hex> is set then L<Data::HexDump::XXD> will be required and used
to dump the value as well.

=item gather_data $string, %opts

Gathers information about the string.

Calls various other C<gather_> methods internally.

Used by C<dump_info> to dump the results.

In scalar context returns a hash reference, in list context key value pairs.

All hash references are tied to L<Tie::IxHash> in order to be layed out
logically in the dump.

C<%opts> is not yet used but may be in the future.

=back

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT & LICENSE

	Copyright (c) 2007 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute it and/or modify it
	under the terms of the MIT license or the same terms as Perl itself.

=cut

