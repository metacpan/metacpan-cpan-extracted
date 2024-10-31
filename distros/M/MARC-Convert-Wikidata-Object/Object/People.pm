package MARC::Convert::Wikidata::Object::People;

use strict;
use warnings;

use Mo qw(build default is);
use Mo::utils 0.21 qw(check_array_object);
use Mo::utils::Date 0.04 qw(check_date check_date_order);

our $VERSION = 0.07;

has date_of_birth => (
	is => 'ro',
);

has date_of_death => (
	is => 'ro',
);

has external_ids => (
	default => [],
	is => 'ro',
);

has name => (
	is => 'ro',
);

has surname => (
	is => 'ro',
);

has work_period_start => (
	is => 'ro',
);

has work_period_end => (
	is => 'ro',
);

sub full_name {
	my $self = shift;

	my $full_name = $self->name;
	if (defined $self->surname) {
		if ($full_name) {
			$full_name .= ' ';
		}
		$full_name .= $self->surname;
	}

	return $full_name;
}

sub BUILD {
	my $self = shift;

	check_date($self, 'date_of_birth');
	check_date($self, 'date_of_death');

	check_date_order($self, 'date_of_birth', 'date_of_death');

	check_array_object($self, 'external_ids', 'MARC::Convert::Wikidata::Object::ExternalId', 'External id');

	check_date($self, 'work_period_start');
	check_date($self, 'work_period_end');

	check_date_order($self, 'work_period_start', 'work_period_end');

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

MARC::Convert::Wikidata::Object::People - Bibliographic Wikidata object for people defined by MARC record.

=head1 SYNOPSIS

 use MARC::Convert::Wikidata::Object::People;

 my $obj = MARC::Convert::Wikidata::Object::People->new(%params);
 my $date_of_birth = $obj->date_of_birth;
 my $date_of_death = $obj->date_of_death;
 my $external_ids_ar = $obj->external_ids;
 my $full_name = $obj->full_name;
 my $name = $obj->name;
 my $surname = $obj->surname;
 my $work_period_start = $obj->work_period_start;
 my $work_period_end = $obj->work_period_end;

=head1 METHODS

=head2 C<new>

 my $obj = MARC::Convert::Wikidata::Object::People->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<date_of_birth>

Date of birth of people.

Parameter is string with date. See L<Mo::utils::Date/check_date> for more information.

Default value is undef.

=item * C<date_of_death>

Date of death of people.

Parameter is string with date. See L<Mo::utils::Date/check_date> for more information.

Default value is undef.

=item * C<external_ids>

External ids.

Need to be a reference to array with L<MARC::Convert::Wikidata::Object::ExternalId> instances.

Default value is [].

=item * C<name>

Given name of people.

Default value is undef.

=item * C<surname>

Surname of people.

Default value is undef.

=back

=head2 C<date_of_birth>

 my $date_of_birth = $obj->date_of_birth;

Get date of birth.

Returns string.

=head2 C<date_of_death>

 my $date_of_death = $obj->date_of_death;

Get date of death.

Returns string.

=head2 C<external_ids>

 my $external_ids_ar = $obj->external_ids;

Get list of external ids.

Returns reference to array with L<MARC::Convert::Wikidata::Object::ExternalId> instances.

=head2 C<full_name>

 my $full_name = $obj->full_name;

Get full name.

Returns string.

=head2 C<name>

 my $name = $obj->name;

Get given name.

Returns string.

=head2 C<surname>

 my $surname = $obj->surname;

Get surname.

Returns string.

=head2 C<work_period_start>

 my $work_period_start = $obj->work_period_start;

Get start date of work period.

Returns string.

=head2 C<work_period_end>

 my $work_period_end = $obj->work_period_end;

Get end date of work period.

Returns string.

=head1 ERRORS

 new():
         From Mo::utils::check_array_object():
                 External id isn't 'MARC::Convert::Wikidata::Object::ExternalId' object.
                         Value: %s
                         Reference: %s
                 Parameter 'external_ids' must be a array.
                         Value: %s
                         Reference: %s
         From Mo::utils::Date::check_date():
                 Parameter 'date_of_birth' for date is in bad format.
                 Parameter 'date_of_birth' has year greater than actual year.
                 Parameter 'date_of_death' for date is in bad format.
                 Parameter 'date_of_death' has year greater than actual year.
         From Mo::utils::Date::check_date_order():
                 Parameter 'date_of_birth' has date greater or same as parameter 'date_of_death' date.

=head1 EXAMPLE1

=for comment filename=create_and_dump_people.pl

 use strict;
 use warnings;

 use Data::Printer;
 use MARC::Convert::Wikidata::Object::ExternalId;
 use MARC::Convert::Wikidata::Object::People;
 use Unicode::UTF8 qw(decode_utf8);
 
 my $obj = MARC::Convert::Wikidata::Object::People->new(
         'date_of_birth' => '1952-12-08',
         'external_ids' => [
                 MARC::Convert::Wikidata::Object::ExternalId->new(
                         'name' => 'nkcr_aut',
                         'value' => 'jn20000401266',
                 ),
         ],
         'name' => decode_utf8('Jiří'),
         'surname' => 'Jurok',
 );
 
 p $obj;

 # Output:
 # MARC::Convert::Wikidata::Object::People  {
 #     parents: Mo::Object
 #     public methods (4):
 #         BUILD
 #         Mo::utils:
 #             check_array_object
 #         Mo::utils::Date:
 #             check_date, check_date_order
 #     private methods (0)
 #     internals: {
 #         date_of_birth   "1952-12-08" (dualvar: 1952),
 #         external_ids    [
 #             [0] MARC::Convert::Wikidata::Object::ExternalId
 #         ],
 #         name            "Jiří",
 #         surname         "Jurok"
 #     }
 # }

=head1 DEPENDENCIES

L<Mo>,
L<Mo::utils>,
L<Mo::utils::Date>.

=head1 SEE ALSO

=over

=item L<MARC::Convert::Wikidata>

Conversion class between MARC record and Wikidata object.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/MARC-Convert-Wikidata-Object>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2021-2024

BSD 2-Clause License

=head1 VERSION

0.07

=cut
