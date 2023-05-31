package MARC::Convert::Wikidata;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use MARC::Convert::Wikidata::Item::AudioBook;
use MARC::Convert::Wikidata::Item::BookEdition;
use MARC::Convert::Wikidata::Item::Periodical;
use MARC::Convert::Wikidata::Transform;
use Scalar::Util qw(blessed);

our $VERSION = 0.02;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Cover callback.
	$self->{'callback_cover'} = undef;

	# Lang callback.
	$self->{'callback_lang'} = undef;

	# People callback.
	$self->{'callback_people'} = undef;

	# Place of publication Wikidata lookup callback.
	$self->{'callback_publisher_place'} = undef;

	# Publisher Wikidata lookup callback.
	$self->{'callback_publisher_name'} = undef;

	# Book series Wikidata lookup callback.
	$self->{'callback_series'} = undef;

	# Retrieved date.
	$self->{'date_retrieved'} = undef;

	# MARC::Record object.
	$self->{'marc_record'} = undef;

	# Process parameters.
	set_params($self, @params);

	if (! defined $self->{'marc_record'}) {
		err "Parameter 'marc_record' is required.";
	}
	if (! blessed($self->{'marc_record'})
		|| ! $self->{'marc_record'}->isa('MARC::Record')) {

		err "Parameter 'marc_record' must be a MARC::Record object.";
	}

	$self->{'_transform_object'} = MARC::Convert::Wikidata::Transform->new(
		'marc_record' => $self->{'marc_record'},
	)->object;

	return $self;
}

sub object {
	my $self = shift;

	return $self->{'_transform_object'};
}

sub type {
	my $self = shift;

	my $leader = $self->{'marc_record'}->leader;
	# XXX Use MARC::Leader if exist.
	my $leader_hr = $self->_leader($leader);

	# Language material
	if ($leader_hr->{'type_of_record'} eq 'a' && $leader_hr->{'bibliographic_level'} eq 'm') {
		return 'monograph';

	# XXX Notated music
	} elsif ($leader_hr->{'type_of_record'} eq 'c' && $leader_hr->{'bibliographic_level'} eq 'm') {
		return 'monograph';

	# Nonmusical sound recording
	} elsif ($leader_hr->{'type_of_record'} eq 'i' && $leader_hr->{'bibliographic_level'} eq 'm') {
		return 'audiobook';

	# Serial
	} elsif ($leader_hr->{'bibliographic_level'} eq 's') {
		return 'periodical';
	} else {
		err "Unsupported item with leader '$leader'.";
	}
}

sub wikidata {
	my $self = shift;

	# Parameters.
	my %params = (
		'callback_cover' => $self->{'callback_cover'},
		'callback_lang' => $self->{'callback_lang'},,
		'callback_publisher_place' => $self->{'callback_publisher_place'},,
		'callback_people' => $self->{'callback_people'},
		'callback_publisher_name' => $self->{'callback_publisher_name'},
		'callback_series' => $self->{'callback_series'},
		'marc_record' => $self->{'marc_record'},
		'transform_object' => $self->{'_transform_object'},
	);

	my $wikidata;
	my $marc_type = $self->type;
	if ($marc_type eq 'monograph') {
		$wikidata = MARC::Convert::Wikidata::Item::BookEdition->new(
			%params,
		)->wikidata;
	} elsif ($marc_type eq 'audiobook') {
		$wikidata = MARC::Convert::Wikidata::Item::AudioBook->new(
			%params,
		)->wikidata;
	} elsif ($marc_type eq 'periodical') {
		$wikidata = MARC::Convert::Wikidata::Item::Periodical->new(
			%params,
		)->wikidata;
	} else {
		err "Item '$marc_type' doesn't supported.";
	}

	return $wikidata;
}

sub _leader {
	my ($self, $leader) = @_;

	# Example '03691nam a2200685 aa4500'
	my $length = substr $leader, 0, 5;
	my $record_status = substr $leader, 5, 1;
	my $type_of_record = substr $leader, 6, 1;
	my $bibliographic_level = substr $leader, 7, 1;

	return {
		'length' => $length,
		'record_status' => $record_status,
		'type_of_record' => $type_of_record,
		'bibliographic_level' => $bibliographic_level,
	}
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

MARC::Convert::Wikidata - Conversion class between MARC file to Wikibase::Datatype item.

=head1 SYNOPSIS

 use MARC::Convert::Wikidata;

 my $obj = MARC::Convert::Wikidata->new(%params);
 my $object = $obj->object;
 my $type = $obj->type;
 my $wikidata = $obj->wikidata;

=head1 DESCRIPTION

Original intent of this class was conversion from MARC records in National Library of the
Czech Republic to Wikidata. The conversion is not simple, this mean that many
things are concrete for this concrete national library.

=head1 METHODS

=head2 C<new>

 my $obj = MARC::Convert::Wikidata->new(%params);

Constructor.

=over 8

=item * C<callback_cover>

Cover callback

Default value is undef.

=item * C<callback_lang>

Language callback.

Default value is undef.

=item * C<callback_people>

People callback.

Default value is undef.

=item * C<callback_publisher_place>

Place of publication Wikidata lookup callback.

Default value is undef.

=item * C<callback_publisher_name>

Publisher Wikidata lookup callback.

Default value is undef.

=item * C<callback_series>

Book series Wikidata lookup callback.

Default value is undef.

=item * C<date_retrieved>

Retrieved date.

Default value is undef.

=item * C<marc_record>

MARC::Record object.

It's required.

=back

Returns instance of object.

=head2 C<object>

 my $object = $obj->object;

Get data object created from MARC record.

Returns MARC::Convert::Wikidata::Object instance.

=head2 C<type>

 my $type = $obj->type;

Process MARC record and detect which record type is.
Supported values are: monograph, audiobook and periodical.

Returns string.

=head2 C<wikidata>

 my $wikidata = $obj->wikidata;

Process conversion from MARC record to Wikibase::Datatype::Item which is
possible to load to Wikidata.

Returns Wikibase::Datatype instance.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.
         Parameter 'marc_record' is required.
         Parameter 'marc_record' must be a MARC::Record object.

 type():
         Unsupported item with leader '%s'.

 wikidata():
         Item '%s' doesn't supported.
         Unsupported item with leader '%s'.

=head1 EXAMPLE

=for comment filename=marc_to_wikidata_print.pl

 use strict;
 use warnings;

 use File::Temp ();
 use MARC::Convert::Wikidata;
 use MARC::File::XML;
 use MARC::Record;
 use Unicode::UTF8 qw(decode_utf8 encode_utf8);
 use Wikibase::Datatype::Print::Item;

 my $marc_xml = decode_utf8(<<'END');
 <?xml version="1.0" encoding="UTF-8"?>
 <collection
   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
   xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd"
   xmlns="http://www.loc.gov/MARC21/slim">
 <record>
   <leader>01177nam a2200349 i 4500</leader>
   <controlfield tag="001">nkc20193102359</controlfield>
   <controlfield tag="003">CZ PrNK</controlfield>
   <controlfield tag="005">20190813103856.0</controlfield>
   <controlfield tag="007">ta</controlfield>
   <controlfield tag="008">190612s1917    xr af  b      000 f cze  </controlfield>
   <datafield tag="015" ind1=" " ind2=" ">
     <subfield code="a">cnb003102359</subfield>
   </datafield>
   <datafield tag="020" ind1=" " ind2=" ">
     <subfield code="q">(Vázáno)</subfield>
   </datafield>
   <datafield tag="040" ind1=" " ind2=" ">
     <subfield code="a">ABA001</subfield>
     <subfield code="b">cze</subfield>
     <subfield code="e">rda</subfield>
   </datafield>
   <datafield tag="072" ind1=" " ind2="7">
     <subfield code="a">821.162.3-3</subfield>
     <subfield code="x">Česká próza</subfield>
     <subfield code="2">Konspekt</subfield>
     <subfield code="9">25</subfield>
   </datafield>
   <datafield tag="072" ind1=" " ind2="7">
     <subfield code="a">821-93</subfield>
     <subfield code="x">Literatura pro děti a mládež (beletrie)</subfield>
     <subfield code="2">Konspekt</subfield>
     <subfield code="9">26</subfield>
   </datafield>
   <datafield tag="080" ind1=" " ind2=" ">
     <subfield code="a">821.162.3-34</subfield>
     <subfield code="2">MRF</subfield>
   </datafield>
   <datafield tag="080" ind1=" " ind2=" ">
     <subfield code="a">821-93</subfield>
     <subfield code="2">MRF</subfield>
   </datafield>
   <datafield tag="080" ind1=" " ind2=" ">
     <subfield code="a">(0:82-34)</subfield>
     <subfield code="2">MRF</subfield>
   </datafield>
   <datafield tag="100" ind1="1" ind2=" ">
     <subfield code="a">Karafiát, Jan,</subfield>
     <subfield code="d">1846-1929</subfield>
     <subfield code="7">jk01052941</subfield>
     <subfield code="4">aut</subfield>
   </datafield>
   <datafield tag="245" ind1="1" ind2="0">
     <subfield code="a">Broučci :</subfield>
     <subfield code="b">pro malé i veliké děti /</subfield>
     <subfield code="c">Jan Karafiát</subfield>
   </datafield>
   <datafield tag="250" ind1=" " ind2=" ">
     <subfield code="a">IV. vydání</subfield>
   </datafield>
   <datafield tag="264" ind1=" " ind2="1">
     <subfield code="a">V Praze :</subfield>
     <subfield code="b">Alois Hynek,</subfield>
     <subfield code="c">[1917?]</subfield>
   </datafield>
   <datafield tag="300" ind1=" " ind2=" ">
     <subfield code="a">85 stran, 5 nečíslovaných listů obrazových příloh :</subfield>
     <subfield code="b">ilustrace (některé barevné) ;</subfield>
     <subfield code="c">24 cm</subfield>
   </datafield>
   <datafield tag="336" ind1=" " ind2=" ">
     <subfield code="a">text</subfield>
     <subfield code="b">txt</subfield>
     <subfield code="2">rdacontent</subfield>
   </datafield>
   <datafield tag="337" ind1=" " ind2=" ">
     <subfield code="a">bez média</subfield>
     <subfield code="b">n</subfield>
     <subfield code="2">rdamedia</subfield>
   </datafield>
   <datafield tag="338" ind1=" " ind2=" ">
     <subfield code="a">svazek</subfield>
     <subfield code="b">nc</subfield>
     <subfield code="2">rdacarrier</subfield>
   </datafield>
   <datafield tag="655" ind1=" " ind2="7">
     <subfield code="a">české pohádky</subfield>
     <subfield code="7">fd133970</subfield>
     <subfield code="2">czenas</subfield>
   </datafield>
   <datafield tag="655" ind1=" " ind2="7">
     <subfield code="a">publikace pro děti</subfield>
     <subfield code="7">fd133156</subfield>
     <subfield code="2">czenas</subfield>
   </datafield>
   <datafield tag="655" ind1=" " ind2="9">
     <subfield code="a">Czech fairy tales</subfield>
     <subfield code="2">eczenas</subfield>
   </datafield>
   <datafield tag="655" ind1=" " ind2="9">
     <subfield code="a">children's literature</subfield>
     <subfield code="2">eczenas</subfield>
   </datafield>
   <datafield tag="910" ind1=" " ind2=" ">
     <subfield code="a">ABA001</subfield>
   </datafield>
   <datafield tag="998" ind1=" " ind2=" ">
     <subfield code="a">003102359</subfield>
   </datafield>
 </record>
 </collection>
 END
 my $marc_record = MARC::Record->new_from_xml($marc_xml, 'UTF-8');

 # Object.
 my $obj = MARC::Convert::Wikidata->new(
         'marc_record' => $marc_record,
 );

 # Convert MARC record to Wikibase object.
 my $item = $obj->wikidata;

 # Print out.
 print encode_utf8(scalar Wikibase::Datatype::Print::Item::print($item));

 # Output like:
 # TODO Add callbacks.
 # No callback method for translation of people in 'authors' method.
 # No callback method for translation of language.
 # Label: Broučci: pro malé i veliké děti (en)
 # Description: 1917 Czech book edition (en)
 # Statements:
 #   P31: Q3331189 (normal)
 #   P3184: cnb003102359 (normal)
 #   References:
 #     {
 #       P248: Q86914821
 #       P3184: cnb003102359
 #       P813: 26 May 2023 (Q1985727)
 #     }
 #   P393: 4 (normal)
 #   References:
 #     {
 #       P248: Q86914821
 #       P3184: cnb003102359
 #       P813: 26 May 2023 (Q1985727)
 #     }
 #   P1104: 85 (normal)
 #   References:
 #     {
 #       P248: Q86914821
 #       P3184: cnb003102359
 #       P813: 26 May 2023 (Q1985727)
 #     }
 #   P577: 1917 (Q1985727) (normal)
 #   References:
 #     {
 #       P248: Q86914821
 #       P3184: cnb003102359
 #       P813: 26 May 2023 (Q1985727)
 #     }
 #   P1680: pro malé i veliké děti (cs) (normal)
 #   References:
 #     {
 #       P248: Q86914821
 #       P3184: cnb003102359
 #       P813: 26 May 2023 (Q1985727)
 #     }
 #   P1476: Broučci (cs) (normal)
 #   References:
 #     {
 #       P248: Q86914821
 #       P3184: cnb003102359
 #       P813: 26 May 2023 (Q1985727)
 #     }

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<MARC::Convert::Wikidata::Item::AudioBook>,
L<MARC::Convert::Wikidata::Item::BookEdition>,
L<MARC::Convert::Wikidata::Item::Periodical>,
L<MARC::Convert::Wikidata::Transform>,
L<Scalar::Util>.

=head1 SEE ALSO

=over

=item L<MARC::Record>

Perl extension for handling MARC records

=item L<Wikibase::Datatype::Item>

Wikibase item datatype.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/MARC-Convert-Wikidata>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2021-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
