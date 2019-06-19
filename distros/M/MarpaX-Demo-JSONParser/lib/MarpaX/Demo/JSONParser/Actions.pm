package MarpaX::Demo::JSONParser::Actions;

use strict;
use warnings;

# Warning: Do not use Moo or anything similar.
# This class needs a sub new() due to the way
# Marpa calls the constructor.

our $VERSION = '1.08';

# ------------------------------------------------

sub do_array
{
	shift;

	return $_[1];

} # End of do_array.

# ------------------------------------------------

sub do_empty_array
{
	return [];

} # End of do_empty_array.

# ------------------------------------------------

sub do_empty_object
{
	return {};

} # End of do_empty_object.

# ------------------------------------------------

sub do_first_arg
{
	shift;

	return $_[0];

} # End of do_first_arg.

# ------------------------------------------------

sub do_join
{
	shift;

	return join '', @_;

} # End of do_join.

# ------------------------------------------------

sub do_list
{
	shift;

	return \@_;

} # End of do_list.

# ------------------------------------------------

sub do_null
{
	return undef;

} # End of do_null.

# ------------------------------------------------

sub do_object
{
	shift;

	return {map {@$_} @{$_[1]} };

} # End of do_object.

# ------------------------------------------------

sub do_pair
{
	shift;

	return [ $_[0], $_[2] ];

} # End of do_pair.

# ------------------------------------------------

sub do_string
{
	shift;

	my($s) = $_[0];

	$s =~ s/^"//;
	$s =~ s/"$//;

	$s =~ s/\\u([0-9A-Fa-f]{4})/chr(hex($1))/eg;

	$s =~ s/\\n/\n/g;
	$s =~ s/\\r/\r/g;
	$s =~ s/\\b/\b/g;
	$s =~ s/\\f/\f/g;
	$s =~ s/\\t/\t/g;
	$s =~ s/\\\\/\\/g;
	$s =~ s{\\/}{/}g;
	$s =~ s{\\"}{"}g;

	return $s;

} # End of do_string.

# ------------------------------------------------

sub do_true
{
	shift;

	return $_[0] eq 'true';

} # End of do_true.

# ------------------------------------------------

sub new
{
	my($class) = @_;

	return bless {}, $class;

} # End of new.

# ------------------------------------------------

1;

=pod

=head1 NAME

C<MarpaX::Demo::JSONParser::Actions> - A JSON parser with a choice of grammars

=head1 Synopsis

See L<MarpaX::Demo::JSONParser/Synopsis>.

The module is used automatically by L<MarpaX::Demo::JSONParser> as appropriate.

=head1 Description

See L<MarpaX::Demo::JSONParser/Description>.

=head1 Installation

See L<MarpaX::Demo::JSONParser/Installation>.

=head1 Methods

The functions are called automatically by L<Marpa::R2> as appropriate.

=head2 new()

The constructor is called automatically by L<Marpa::R2> as appropriate.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=MarpaX::Demo::JSONParser>.

=head1 Author

Peter Stuifzand wrote the code in 2013.

L<MarpaX::Demo::JSONParser> is now maintained by Ron Savage I<E<lt>ron@savage.net.auE<gt>>.

Home page: L<http://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2013, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License 2.0, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
