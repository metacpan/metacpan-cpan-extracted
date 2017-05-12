#!/usr/bin/perl

package Lingua::Phonology::Common;

# This module is used for functions needed at least in part by all other
# packages.

# We export everything. Since this is only for internal use, we know what we're
# getting, and the funcs all begin with _, so are unlikely to clash anyway
@ISA = qw(Exporter);
@EXPORT = qw(
    _err
	_is
	_is_features
	_is_symbols
	_is_syllable
	_is_seg
	_is_boundary
	_is_ruleseg
    _is_tier
    _to_handle
	_parse_from_file
	_parse_from_string
	_string_from_struct
    _parse_ext
    _parse_plain
    _deparse_ext
);

$VERSION = 0.1;

use strict;
use warnings::register;

use Carp qw/carp croak/;
our @CARP_NOT = qw/
    Lingua::Phonology
    Lingua::Phonology::Features
    Lingua::Phonology::Symbols
    Lingua::Phonology::Segment
    Lingua::Phonology::Segment::Rules
    Lingua::Phonology::Segment::Tier
    Lingua::Phonology::Segment::Boundary
    Lingua::Phonology::Rules
    Lingua::Phonology::Syllable
    Lingua::Phonology::Word
/;
use IO::Handle;
use XML::Simple;

# Global variables. In principle, modules using this module can change these if
# they want, but they probably shouldn't lest evil things transpire.
our %xmlin_opts = (
    KeyAttr => { feature => 'name', child => 'name', parent => 'name', symbol => 'label' },
    ForceArray => [qw/child parent feature symbol rule/],
    GroupTags => { features => 'feature', symbols => 'symbol', order => 'block', persist => 'rule', block => 'rule' }
);
our %xmlout_opts = (
    KeepRoot => 1,
    KeyAttr => { feature => 'name', child => 'name', parent => 'name', symbol => 'label', rule => 'name' }
);

# Concise synonym for UNIVERSAL::isa() with automatic error-writing
sub _is($$) {
	UNIVERSAL::isa(@_);
}

# Extensions of _is for our own classes
sub _is_features ($) { _is(shift, 'Lingua::Phonology::Features') }
sub _is_symbols ($) { _is(shift, 'Lingua::Phonology::Symbols') }
sub _is_syllable ($) { _is(shift, 'Lingua::Phonology::Syllable') }
sub _is_boundary ($) { _is(shift, 'Lingua::Phonology::Segment::Boundary') }
sub _is_ruleseg ($) { _is(shift, 'Lingua::Phonology::Segment::Rules') }
sub _is_tier ($) { _is(shift, 'Lingua::Phonology::Segment::Tier') }

# _is_seg is hacked to allow various segment lookalikes
sub _is_seg ($) { 
    my $seg = shift;
    return _is($seg, 'Lingua::Phonology::Segment') 
        || _is($seg, 'Lingua::Phonology::Segment::Rules')
        || _is($seg, 'Lingua::Phonology::Segment::Tier');
}

# Make a handle from a filename; don't touch existing handles
sub _to_handle($$) {
    my ($file, $mode) = @_;
    return $file if _is($file, 'GLOB');

    my $handle = IO::Handle->new();
    open $handle, $mode, $file or croak "Couldn't open $file: $!";
    return $handle;
}

# Get the parsed XML structure from a filename. Optional second arg specifies
# which key of the parse to return. You'd better specify a key that's present
# on the topmost level of the parse--this method won't look through the whole
# structure for you, like the previous version did.

sub _parse_from_file ($;$) {
	my $file = shift;

	# Open, slurp, close
    $file = _to_handle($file, '<') or return;
	my $string = join '', <$file>;
	close $file;

	return _parse_from_string($string, @_);
}

sub _parse_from_string ($;$) {
	my ($string, $element) = @_;

	# Parse the string, check for errors
	my $parse;
	eval { $parse = XMLin($string, %xmlin_opts) };
	croak "XML parsing error: $@" if ($@);

	if (defined $element) {
		return $parse->{$element} if exists $parse->{$element};
		croak "<$element> element not found";
	}
	return $parse;
}

# Turn a data structure into an XML string
sub _string_from_struct ($) {
	my $struct = shift;

	my $string;
	eval { $string = XMLout($struct, %xmlout_opts) };
	croak "Error creating XML: $@" if $@;

	return $string;
}

sub _parse_ext ($) {
    my $string = shift;
    $string =~ s/(-?\d+):/\$_[$1]->/g;
    return eval "return sub { package main; $string }";
}

sub _parse_plain ($) {
    return eval "return sub { package main; $_[0] }";
}

sub _deparse_ext ($$) {
    my ($code, $deparser) = @_;
    my $string = $deparser->coderef2text($code);
    $string =~ s/\{(.*)\}/$1/s; # Strip opening/closing brackets
    #$string =~ s/^\s*(.*?)\s*$/$1/s; # String leading/trailing whitespace
    $string =~ s/\$_\[(-?\d+)\]->/$1:/gs; # Do ext conversion
    return $string;
}

sub _err ($) {
    carp shift;
    return;
}

1;

