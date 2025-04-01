package MARC::Convert::Wikidata::Object::Work;

use strict;
use warnings;

use Mo qw(build default is);
use Mo::utils 0.21 qw(check_array_object check_isa check_required);

our $VERSION = 0.13;

has author => (
	is => 'ro',
);

has external_ids => (
	default => [],
	is => 'ro',
);

has title => (
	is => 'ro',
);

has title_language => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check author.
	check_isa($self, 'author', 'MARC::Convert::Wikidata::Object::People');

	# Check external_ids.
	check_array_object($self, 'external_ids', 'MARC::Convert::Wikidata::Object::ExternalId', 'External id');

	# Check title.
	check_required($self, 'title');

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

MARC::Convert::Wikidata::Object::Work - Bibliographic Wikidata object for work defined by MARC record.

=head1 SYNOPSIS

 use MARC::Convert::Wikidata::Object::Work;

 my $obj = MARC::Convert::Wikidata::Object::Work->new(%params);
 my $author = $obj->author;
 my $external_ids_ar = $obj->external_ids;
 my $title = $obj->title;
 my $title_language = $obj->title_language;

=head1 METHODS

=head2 C<new>

 my $obj = MARC::Convert::Wikidata::Object::Work->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<author>

Author of work.

Possible value is reference L<MARC::Convert::Wikidata::Object::People> instance.

Default value is undef.

=item * C<external_ids>

External ids.

Need to be a reference to array with L<MARC::Convert::Wikidata::Object::ExternalId> instances.

Default value is [].

=item * C<title>

Work title.

It's required.

Default value is undef.

=item * C<title_language>

Work title language.

Default value is undef.

=back

=head2 C<author>

 my $author = $obj->author;

Get author of work.

Returns L<MARC::Convert::Wikidata::Object::People> instance.

=head2 C<external_ids>

 my $external_ids_ar = $obj->external_ids;

Get list of external ids.

Returns reference to array with L<MARC::Convert::Wikidata::Object::ExternalId> instances.

=head2 C<title>

 my $title = $obj->title;

Get work title.

Returns string.

=head2 C<title_language>

 my $title_language = $obj->title_language;

Get work title language.

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
         From Mo::utils::Date::check_isa():
                 Parameter 'author' must be a 'MARC::Convert::Wikidata::Object::People' object.
                         Value: %s
                         Reference: %s
         From Mo::utils::Date::check_required():
                         Parameter 'title' is required.
                 

=head1 EXAMPLE1

=for comment filename=create_and_dump_work.pl

 use strict;
 use warnings;

 use Data::Printer;
 use MARC::Convert::Wikidata::Object::ExternalId;
 use MARC::Convert::Wikidata::Object::People;
 use MARC::Convert::Wikidata::Object::Work;
 use Unicode::UTF8 qw(decode_utf8);
 
 my $obj = MARC::Convert::Wikidata::Object::Work->new(
         'author' => MARC::Convert::Wikidata::Object::People->new(
                 'name' => decode_utf8('Tomáš Garrigue'),
                 'surname' => 'Masaryk',
         ),
         'external_ids' => [
                 MARC::Convert::Wikidata::Object::ExternalId->new(
                         'name' => 'nkcr_aut',
                         'value' => 'jn20000401266',
                 ),
         ],
         'title' => decode_utf8('O ethice a alkoholismu'),
         'title_language' => 'cze',
 );
 
 p $obj;

 # Output:
 # MARC::Convert::Wikidata::Object::Work  {
 #     parents: Mo::Object
 #     public methods (3):
 #         BUILD
 #         Mo::utils:
 #             check_array_object, check_isa
 #     private methods (0)
 #     internals: {
 #         author           MARC::Convert::Wikidata::Object::People,
 #         external_ids     [
 #             [0] MARC::Convert::Wikidata::Object::ExternalId
 #         ],
 #         title            "O ethice a alkoholismu",
 #         title_language   "cze"
 #     }
 # }

=head1 DEPENDENCIES

L<Mo>,
L<Mo::utils>.

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

© Michal Josef Špaček 2021-2025

BSD 2-Clause License

=head1 VERSION

0.13

=cut
