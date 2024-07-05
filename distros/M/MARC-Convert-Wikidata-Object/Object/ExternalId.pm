package MARC::Convert::Wikidata::Object::ExternalId;

use strict;
use warnings;

use Mo qw(build is);
use Mo::utils 0.15 qw(check_bool check_required check_strings);
use Readonly;

Readonly::Array our @NAMES => qw(cnb lccn nkcr_aut);

our $VERSION = 0.05;

has deprecated => (
	is => 'ro',
);

has name => (
	is => 'ro',
);

has value => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	if (! $self->{'deprecated'}) {
		$self->{'deprecated'} = 0;
	}
	check_bool($self, 'deprecated');

	check_required($self, 'name');
	check_strings($self, 'name', \@NAMES);

	check_required($self, 'value');

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

MARC::Convert::Wikidata::Object::ExternalId - Bibliographic Wikidata object for Kramerius link by MARC record.

=head1 SYNOPSIS

 use MARC::Convert::Wikidata::Object::ExternalId;

 my $obj = MARC::Convert::Wikidata::Object::ExternalId->new(%params);
 my $deprecated = $obj->deprecated;
 my $name = $obj->name;
 my $value = $obj->value;

=head1 METHODS

=head2 C<new>

 my $obj = MARC::Convert::Wikidata::Object::ExternalId->new(%params);

Constructor.

=over 8

=item * C<deprecated>

Flag for external id deprecation.

Default value is 0.

=item * C<name>

External id name.

Parameter is required.

Possible values are:

=over

=item * cnb

Czech national library cnb id.

=item * nkcr_aut

Czech national library aut id.

=item * lccn

Library of Congress Control Number.

=back

=item * C<value>

External id value.

Parameter is required.

=back

Returns instance of object.

=head2 C<deprecated>

 my $deprecated = $obj->deprecated;

Get deprecated flag.

Returns 0/1.

=head2 C<name>

 my $name = $obj->name;

Get external id name.

Returns string.

=head2 C<value>

 my $value = $obj->value;

Get external id value.

Returns string.

=head1 ERRORS

 new():
         From Mo::utils::check_bool():
                 Parameter 'deprecated' must be a bool (0/1).
                         Value: %s
         From Mo::utils::check_required():
                 Parameter 'name' is required.
                 Parameter 'value' is required.
         From Mo::utils::check_strings():
                 Parameter 'name' must have strings definition.
                 Parameter 'name' must have right string definition.
                 Parameter 'name' must be one of defined strings.
                         String: %s
                         Possible strings: %s 

=head1 EXAMPLE1

=for comment filename=create_and_dump_external_id.pl

 use strict;
 use warnings;

 use Data::Printer;
 use MARC::Convert::Wikidata::Object::ExternalId;

 my $obj = MARC::Convert::Wikidata::Object::ExternalId->new(
         'name' => 'cnb',
         'value' => 'cnb003597104',
 );

 p $obj;

 # Output:
 # MARC::Convert::Wikidata::Object::ExternalId  {
 #     parents: Mo::Object
 #     public methods (3):
 #         BUILD
 #         Mo::utils:
 #             check_bool, check_required
 #     private methods (0)
 #     internals: {
 #         deprecated   0,
 #         name         "cnb",
 #         value        "cnb003597104"
 #     }
 # }

=head1 DEPENDENCIES

L<Mo>,
L<Mo::utils>,
L<Readonly>.

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

0.05

=cut
