package MARC::Convert::Wikidata::Object::Publisher;

use strict;
use warnings;

use Mo qw(build is);
use Mo::utils qw(check_required);

our $VERSION = 0.10;

has id => (
	is => 'ro',
);

has name => (
	is => 'ro',
);

has place => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	check_required($self, 'name');

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

MARC::Convert::Wikidata::Object::Publisher - Bibliographic Wikidata object for publisher defined by MARC record.

=head1 SYNOPSIS

 use MARC::Convert::Wikidata::Object::Publisher;

 my $obj = MARC::Convert::Wikidata::Object::Publisher->new(%params);
 my $id = $obj->id;
 my $name = $obj->name;
 my $place = $obj->place;

=head1 METHODS

=head2 C<new>

 my $obj = MARC::Convert::Wikidata::Object::Publisher->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<id>

Id of publishing house.

Parameter is optional.

Default value is undef.

=item * C<name>

Name of publishing house.

Parameter is required.

Default value is undef.

=item * C<place>

Location of publishing house.

Default value is undef.

=back

=head2 C<id>

 my $id = $obj->id;

Get id of publishing house.

Returns string.

=head2 C<name>

 my $name = $obj->name;

Get name of publishing house.

Returns string.

=head2 C<place>

 my $place = $obj->place;

Get place of publishing house.

Returns string.

=head1 ERRORS

 new():
         Parameter 'name' is required.

=head1 EXAMPLE1

=for comment filename=create_and_dump_publisher.pl

 use strict;
 use warnings;

 use Data::Printer;
 use MARC::Convert::Wikidata::Object::Publisher;
 
 my $obj = MARC::Convert::Wikidata::Object::Publisher->new(
         'id' => '000010003',
         'name' => 'Academia',
         'place' => 'Praha',
 );
 
 p $obj;

 # Output:
 # MARC::Convert::Wikidata::Object::Publisher  {
 #     Parents       Mo::Object
 #     public methods (4) : can (UNIVERSAL), DOES (UNIVERSAL), isa (UNIVERSAL), VERSION (UNIVERSAL)
 #     private methods (1) : __ANON__ (Mo::is)
 #     internals: {
 #         id      "000010003",
 #         name    "Academia",
 #         place   "Praha"
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

0.10

=cut
