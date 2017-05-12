package Mac::PropertyList;
use strict;

use warnings;
no warnings;

use vars qw($ERROR $XML_head $XML_foot $VERSION @EXPORT_OK %EXPORT_TAGS);
use Carp qw(croak carp);
use Data::Dumper;
use XML::Entities;

use parent qw(Exporter);

@EXPORT_OK = qw(
	parse_plist
	parse_plist_fh
	parse_plist_file
	plist_as_string
	create_from_hash
	create_from_array
	);

%EXPORT_TAGS = (
	'all' => \@EXPORT_OK,
	);

$VERSION = '1.41';

=encoding utf8

=head1 NAME

Mac::PropertyList - work with Mac plists at a low level

=head1 SYNOPSIS

	use Mac::PropertyList qw(:all);

	my $data  = parse_plist( $text );
	my $perl  = $data->as_perl;

		# == OR ==
	my $data  = parse_plist_file( $filename );

		# == OR ==
	open my( $fh ), $filename or die "...";
	my $data  = parse_plist_fh( $fh );


	my $text  = plist_as_string( $data );

	my $plist = create_from_hash(  \%hash  );
	my $plist = create_from_array( \@array );

	my $plist = Mac::PropertyList::dict->new( \%hash );

	my $perl  = $plist->as_perl;

=head1 DESCRIPTION

This module is a low-level interface to the Mac OS X Property List
(plist) format. You probably shouldn't use this in applications–build
interfaces on top of this so you don't have to put all the heinous
multi-level object stuff where people have to look at it.

You can parse a plist file and get back a data structure. You can take
that data structure and get back the plist as XML. If you want to
change the structure inbetween that's your business. :)

You don't need to be on Mac OS X to use this. It simply parses and
manipulates a text format that Mac OS X uses.

=head2 The Property List format

The MacOS X Property List format is simple XML. You can read the DTD
to get the details.

	http://www.apple.com/DTDs/PropertyList-1.0.dtd

One big problem exists—its dict type uses a flat structure to list
keys and values so that values are only associated with their keys by
their position in the file rather than by the structure of the DTD.
This problem is the major design hinderance in this module. A smart
XML format would have made things much easier.

If the parse_plist encounters an empty key tag in a dict structure
(i.e. C<< <key></key> >> ) the function croaks.

=head2 The Mac::PropertyList classes

A plist can have one or more of any of the plist objects, and we have
to remember the type of thing so we can go back to the XML format.
Perl treats numbers and strings the same, but the plist format
doesn't.

Therefore, everything C<Mac::PropertyList> creates is an object of some
sort. Container objects like C<Mac::PropertyList::array> and
C<Mac::PropertyList::dict> hold other objects.

There are several types of objects:

	Mac::PropertyList::string
	Mac::PropertyList::data
	Mac::PropertyList::real
	Mac::PropertyList::integer
	Mac::PropertyList::date
	Mac::PropertyList::array
	Mac::PropertyList::dict
	Mac::PropertyList::true
	Mac::PropertyList::false

Note that the Xcode property list editor abstracts the C<true> and
C<false> objects as just C<Boolean>. They are separate tags in the
plist format though.

=over 4

=item new( VALUE )

Create the object.

=item value

Access the value of the object. At the moment you cannot change the
value

=item type

Access the type of the object (string, data, etc)

=item write

Create a string version of the object, recursively if necessary.

=item as_perl

Turn the plist data structure, which is decorated with extra
information, into a lean Perl data structure without the value type
information or blessed objects.

=back

=cut

my $Debug = $ENV{PLIST_DEBUG} || 0;

$XML_head =<<"XML";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
XML

$XML_foot =<<"XML";
</plist>
XML

my %Readers = (
	"dict"    => \&read_dict,
	"string"  => \&read_string,
	"date"    => \&read_date,
	"real"    => \&read_real,
	"integer" => \&read_integer,
	"string"  => \&read_string,
	"array"   => \&read_array,
	"data"    => \&read_data,
	"true"    => \&read_true,
	"false"   => \&read_false,
	);

my $Options = {ignore => ['<true/>', '<false/>']};

=head1 FUNCTIONS

These functions are available for individual or group import. Nothing
will be imported unless you ask for it.

	use Mac::PropertyList qw( parse_plist );

	use Mac::PropertyList qw( :all );

=over 4

=item parse_plist( TEXT )

Parse the XML plist in TEXT and return the C<Mac::PropertyList>
object.

=cut

# This will change to parse_plist_ref when we create the dispatcher

sub parse_plist {
	my $text = shift;

	my $plist = do {
		if( $text =~ /\A<\?xml/ ) { # XML plists
			# we can handle either 0.9 or 1.0
			$text =~ s|^<\?xml.*?>\s*<!DOC.*>\s*<plist.*?>\s*||;
			$text =~ s|\s*</plist>\s*$||;

			my $text_source = Mac::PropertyList::TextSource->new( $text );
			read_next( $text_source );
			}
		elsif( $text =~ /\Abplist/ ) { # binary plist
			require Mac::PropertyList::ReadBinary;
			my $parser = Mac::PropertyList::ReadBinary->new( \$text );
			$parser->plist;
			}
		else {
			croak( "This doesn't look like a valid plist format!" );
			}
		};
	}

=item parse_plist_fh( FILEHANDLE )

Parse the XML plist from FILEHANDLE and return the C<Mac::PropertyList>
data structure. Returns false if the arguments is not a reference.

You can do this in a couple of ways. You can open the file with a
lexical filehandle (since Perl 5.6).

	open my( $fh ), $file or die "...";
	parse_plist_fh( $fh );

Or, you can use a bareword filehandle and pass a reference to its
typeglob. I don't recommmend this unless you are using an older
Perl.

	open FILE, $file or die "...";
	parse_plist_fh( \*FILE );

=cut

sub parse_plist_fh {
	my $fh = shift;

	my $text = do { local $/; <$fh> };

	parse_plist( $text );
	}

=item parse_plist_file( FILE_PATH )

Parse the XML plist in FILE_PATH and return the C<Mac::PropertyList>
data structure. Returns false if the file does not exist.

Alternately, you can pass a filehandle reference, but that just
calls C<parse_plist_fh> for you.

=cut

sub parse_plist_file {
	my $file = shift;

	if( ref $file ) { return parse_plist_fh( $file ) }

	unless( -e $file ) {
		croak( "parse_plist_file: file [$file] does not exist!" );
		return;
		}

	my $text = do { local $/; open my($fh), $file; <$fh> };

	parse_plist( $text );
	}

=item create_from_hash( HASH_REF )

Create a plist dictionary from the hash reference.

The values of the hash can only be simple scalars–not references.
Reference values are silently ignored.

Returns a string representing the hash in the plist format.

=cut

sub create_from_hash {
	my $hash  = shift;

	return unless UNIVERSAL::isa( $hash, 'HASH' );

	my $string = "$XML_head" . Mac::PropertyList::dict->write_open . "\n";

	foreach my $key ( keys %$hash ) {
		next if ref $hash->{$key};

		my $bit   = Mac::PropertyList::dict->write_key( $key ) . "\n";
		my $value = Mac::PropertyList::string->new( $hash->{$key} );

		$bit  .= $value->write . "\n";

		$bit =~ s/^/\t/gm;

		$string .= $bit;
		}

	$string .= Mac::PropertyList::dict->write_close . "\n$XML_foot";

	return $string;
	}

=item create_from_array( ARRAY_REF )

Create a plist array from the array reference.

The values of the array can only be simple scalars–not references.
Reference values are silently ignored.

Returns a string representing the array in the plist format.

=cut

sub create_from_array {
	my $array  = shift;

	return unless UNIVERSAL::isa( $array, 'ARRAY' );

	my $string = "$XML_head" . Mac::PropertyList::array->write_open . "\n";

	foreach my $element ( @$array ) {
		my $value = Mac::PropertyList::string->new( $element );

		my $bit  .= $value->write . "\n";
		$bit =~ s/^/\t/gm;

		$string .= $bit;
		}

	$string .= Mac::PropertyList::array->write_close . "\n$XML_foot";

	return $string;
	}

=item read_string

=item read_data

=item read_integer

=item read_date

=item read_real

=item read_true

=item read_false

Reads a certain sort of property list data

=cut

sub read_string  { Mac::PropertyList::string ->new( XML::Entities::decode( 'all', $_[0] ) )  }
sub read_integer { Mac::PropertyList::integer->new( $_[0] )  }
sub read_date    { Mac::PropertyList::date   ->new( $_[0] )  }
sub read_real    { Mac::PropertyList::real   ->new( $_[0] )  }
sub read_true    { Mac::PropertyList::true   ->new           }
sub read_false   { Mac::PropertyList::false  ->new           }

=item read_next

Read the next data item

=cut

sub read_next {
	my $source = shift;

	local $_ = '';
	my $value;

	while( not defined $value ) {
		croak "Couldn't read anything!" if $source->eof;
		$_ .= $source->get_line;

		if( s[^\s* < (string|date|real|integer|data) >
			   \s*(.*?)\s* </\1> ][]sx ) {
			$value = $Readers{$1}->( $2 );
			}
	    elsif( s[^\s* < (dict|array) > ][]x ) {
			$value = $Readers{$1}->( $source );
			}
	    # these next two are some wierd cases i found in the iPhoto Prefs
		elsif( s[^\s* < dict / > ][]x ) {
			$value = Mac::PropertyList::dict->new();
			}
	    elsif( s[^\s* < array / > ][]x ) {
			$value = Mac::PropertyList::array->new();
			}
	    elsif( s[^\s* < (true|false) /> ][]x ) {
			$value = $Readers{$1}->();
			}
		}
	$source->put_line($_);
	return $value;
	}

=item read_dict

Read a dictionary

=cut

sub read_dict {
	my $source = shift;

	my %hash;
	local $_ = $source->get_line;
	while( not s|^\s*</dict>|| ) {
		my $key;
		while (not defined $key) {
			if (s[^\s*<key>(.*?)</key>][]s) {
				$key = $1;
				# Bring this back if you want this behavior:
				# croak "Key is empty string!" if $key eq '';
				}
			else {
				croak "Could not read key!" if $source->eof;
				$_ .= $source->get_line;
				}
			}

		$source->put_line( $_ );
		$hash{ $key } = read_next( $source );
		$_ = $source->get_line;
		}

	$source->put_line( $_ );
	return Mac::PropertyList::dict->new( \%hash );
	}

=item read_array

Read an array

=cut

sub read_array {
	my $source = shift;

	my @array = ();

	local $_ = $source->get_line;
	while( not s|^\s*</array>|| ) {
		$source->put_line( $_ );
		push @array, read_next( $source );
		$_ = $source->get_line;
		}

	$source->put_line( $_ );
	return Mac::PropertyList::array->new( \@array );
	}

sub read_data {
	my $string = shift;

	require MIME::Base64;

	$string = MIME::Base64::decode_base64($string);

	return Mac::PropertyList::data->new( $string );
	}

=item plist_as_string

Return the plist data structure as XML in the Mac Property List format.

=cut

sub plist_as_string {
	my $object = CORE::shift;

	my $string = $XML_head;

	$string .= $object->write . "\n";

	$string .= $XML_foot;

	return $string;
	}

=item plist_as_perl

Return the plist data structure as an unblessed Perl data structure.
There won't be any C<Mac::PropertyList> objects in the results. This
is really just C<as_perl>.

=cut

sub plist_as_perl { $_[0]->as_perl }

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
package Mac::PropertyList::Source;
sub new {
	my $self = bless { buffer => [], source => $_[1] }, $_[0];
	return $self;
	}

sub eof { (not @{$_[0]->{buffer}}) and $_[0]->source_eof }

sub get_line {
	my $self = CORE::shift;

	local $_ = '';
	while (defined $_ && /^[\r\n\s]*$/) {
		if( @{$self->{buffer}} ) {
			$_ = shift @{$self->{buffer}};
			}
		else {
			$_ = $self->get_source_line;
			}
		}

	return $_;
	}

sub put_line { unshift @{$_[0]->{buffer}}, $_[1] }

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
package Mac::PropertyList::LineListSource;
use base qw(Mac::PropertyList::Source);

sub get_source_line { return shift @{$_->{source}} if @{$_->{source}} }

sub source_eof { not @{$_[0]->{source}} }

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
package Mac::PropertyList::TextSource;
use base qw(Mac::PropertyList::Source);

sub get_source_line {
	my $self = CORE::shift;
	$self->{source} =~ s/(.*(\r|\n|$))//;
	$1;
	}

sub source_eof { not $_[0]->{source} }

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
package Mac::PropertyList::Item;
sub type_value { ( $_[0]->type, $_[0]->value ) }

sub value {
	my $ref = $_[0]->type;

	do {
		   if( $ref eq 'array' ) { wantarray ? @{ $_[0] } : $_[0] }
		elsif( $ref eq 'dict'  ) { wantarray ? %{ $_[0] } : $_[0] }
		else                     { ${ $_[0] } }
		};
	}

sub type { my $r = ref $_[0] ? ref $_[0] : $_[0]; $r =~ s/.*:://; $r; }

sub new {
	#print STDERR "Got [@_]\n";

	bless $_[1], $_[0]
	}

sub write_open  { $_[0]->write_either(); }
sub write_close { $_[0]->write_either('/'); }

sub write_either {
	my $slash = defined $_[1] ? '/' : '';

	my $type = $_[0]->type;

	"<$slash$type>";
	}

sub write_empty { my $type = $_[0]->type; "<$type/>"; }

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
package Mac::PropertyList::Container;
use base qw(Mac::PropertyList::Item);

sub new {
	my $class = CORE::shift;
	my $item  = CORE::shift;

	if( ref $item ) {
		return bless $item, $class;
		}

	my $empty = do {
		   if( $class =~ m/array$/ ) { [] }
		elsif( $class =~ m/dict$/  ) { {} }
		};

	$class->SUPER::new( $empty );
	}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
package Mac::PropertyList::array;
use base qw(Mac::PropertyList::Container);

sub shift   { CORE::shift @{ $_[0]->value } }
sub unshift { }
sub pop     { CORE::pop @{ $_[0]->value }   }
sub push    { }
sub splice  { }
sub count   { return scalar @{ $_[0]->value } }
sub _elements { @{ $_[0]->value } } # the raw, unprocessed elements
sub values {
	my @v = map { $_->value } $_[0]->_elements;
	wantarray ? @v : \@v
	}

sub as_basic_data {
	my $self = CORE::shift;
	return
		[ map
		{
		eval { $_->can('as_basic_data') } ? $_->as_basic_data : $_
		} @$self
		];
	}

sub write {
	my $self  = CORE::shift;

	my $string = $self->write_open . "\n";

	foreach my $element ( @$self ) {
		my $bit = $element->write;

		$bit =~ s/^/\t/gm;

		$string .= $bit . "\n";
		}

	$string .= $self->write_close;

	return $string;
	}

sub as_perl {
	my $self  = CORE::shift;

	my @array = map { $_->as_perl } $self->_elements;

	return \@array;
	}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
package Mac::PropertyList::dict;
use base qw(Mac::PropertyList::Container);

sub new {
	#print STDERR Data::Dumper::Dumper( $_[1] );

	$_[0]->SUPER::new( $_[1] );
	}

sub delete { delete ${ $_[0]->value }{$_[1]}         }
sub exists { exists ${ $_[0]->value }{$_[1]} ? 1 : 0 }
sub count  { scalar CORE::keys %{ $_[0]->value }     }

sub value {
	my $self = shift;
	my $key  = shift;

	do
		{
		if( defined $key ) {
			my $hash = $self->SUPER::value;

			if( exists $hash->{$key} ) { $hash->{$key}->value }
			else                       { return }
			}
		else { $self->SUPER::value }
		};

	}

sub keys   { my @k = CORE::keys %{ $_[0]->value }; wantarray ? @k : \@k; }
sub values {
	my @v = map { $_->value } CORE::values %{ $_[0]->value };
	wantarray ? @v : \@v;
	}

sub as_basic_data {
	my $self = shift;

	my %dict = map {
		my ($k, $v) = ($_, $self->{$_});
		$k => eval { $v->can('as_basic_data') } ? $v->as_basic_data : $v
		} CORE::keys %$self;

	return \%dict;
	}

sub write_key   { "<key>$_[1]</key>" }

sub write {
	my $self  = shift;

	my $string = $self->write_open . "\n";

	foreach my $key ( $self->keys ) {
		my $element = $self->{$key};

		my $bit  = __PACKAGE__->write_key( $key ) . "\n";
		   $bit .= $element->write . "\n";

		$bit =~ s/^/\t/gm;

		$string .= $bit;
		}

	$string .= $self->write_close;

	return $string;
	}

sub as_perl {
	my $self  = CORE::shift;

	my %dict = map {
		my $v = $self->value($_);
		$v = $v->as_perl if eval { $v->can( 'as_perl' ) };
		$_, $v
		} $self->keys;

	return \%dict;
	}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
package Mac::PropertyList::Scalar;
use base qw(Mac::PropertyList::Item);

sub new { my $copy = $_[1]; $_[0]->SUPER::new( \$copy ) }

sub as_basic_data { $_[0]->value }

sub write { $_[0]->write_open . $_[0]->value . $_[0]->write_close }

sub as_perl { $_[0]->value }

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
package Mac::PropertyList::date;
use base qw(Mac::PropertyList::Scalar);

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
package Mac::PropertyList::real;
use base qw(Mac::PropertyList::Scalar);

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
package Mac::PropertyList::integer;
use base qw(Mac::PropertyList::Scalar);

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
package Mac::PropertyList::string;
use base qw(Mac::PropertyList::Scalar);

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
package Mac::PropertyList::ustring;
use base qw(Mac::PropertyList::Scalar);

# XXX need to do some fancy unicode checking here

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
package Mac::PropertyList::data;
use base qw(Mac::PropertyList::Scalar);

sub write {
	my $self  = shift;

	my $type  = $self->type;
	my $value = $self->value;

	require MIME::Base64;

	my $string = MIME::Base64::encode_base64($value);

	$self->write_open . $string . $self->write_close;
	}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
package Mac::PropertyList::Boolean;
use base qw(Mac::PropertyList::Item);

sub new {
	my $class = shift;

	my( $type ) = $class =~ m/.*::(.*)/g;

	$class->either( $type );
	}

sub either { my $copy = $_[1]; bless \$copy, $_[0]  }

sub write  { $_[0]->write_empty }

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
package Mac::PropertyList::true;
use base qw(Mac::PropertyList::Boolean);

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
package Mac::PropertyList::false;
use base qw(Mac::PropertyList::Boolean);


=back

=head1 SOURCE AVAILABILITY

This project is in Github:

	git://github.com/briandfoy/mac-propertylist.git

=head1 CREDITS

Thanks to Chris Nandor for general Mac kung fu and Chad Walker for
help figuring out the recursion for nested structures.

Mike Ciul provided some classes for the different input modes, and
these allow us to optimize the parsing code for each of those.

Ricardo Signes added the C<as_basic_types()> methods so you can dump
all the plist junk and just play with the data.

=head1 TO DO

* change the value of an object

* validate the values of objects (date, integer)

* methods to add to containers (dict, array)

* do this from a filehandle or a scalar reference instead of a scalar
	+ generate closures to handle the work.

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2004-2014 brian d foy.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

http://www.apple.com/DTDs/PropertyList-1.0.dtd

=cut

"See why 1984 won't be like 1984";
