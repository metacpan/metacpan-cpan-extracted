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

our $VERSION = 0.01;

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

=for comment filename=get_random_day.pl

 use strict;
 use warnings;

 use File::Temp;
 use MARC::Convert::Wikidata;

 # Object.
 my $obj = MARC::Convert::Wikidata->new;

 # TODO

 # Output like:
 # TODO

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

0.01

=cut
