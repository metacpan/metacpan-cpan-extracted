package MARC::Convert::Wikidata::Object::Kramerius;

use strict;
use warnings;

use Mo qw(is);

our $VERSION = 0.03;

has kramerius_id => (
	is => 'ro',
);

has object_id => (
	is => 'ro',
);

# TODO Remove if i could construct URL by some method.
has url => (
	is => 'ro',
);

1;

__END__

=pod

=encoding utf8

=head1 NAME

MARC::Convert::Wikidata::Object::Kramerius - Bibliographic Wikidata object for Kramerius link by MARC record.

=head1 SYNOPSIS

 use MARC::Convert::Wikidata::Object::Kramerius;

 my $obj = MARC::Convert::Wikidata::Object::Kramerius->new(%params);
 my $kramerius_id = $obj->kramerius_id;
 my $object_id = $obj->object_id;
 my $url = $obj->url;

=head1 METHODS

=head2 C<new>

 my $obj = MARC::Convert::Wikidata::Object::Kramerius->new(%params);

Constructor.

=over 8

=item * C<kramerius_id>

Kramerius system id.

Parameter is optional.

Default value is undef.

=item * C<object_id>

Kramerius system object id.

Parameter is optional.

Default value is undef.

=item * C<url>

URL of Kramerius link.

Parameter is optional.

Default value is undef.

=back

Returns instance of object.

=head2 C<kramerius_id>

 my $kramerius_id = $obj->kramerius_id;

Get Kramerius system id.

Returns string.

=head2 C<object_id>

 my $object_id = $obj->object_id;

Get Kramerius system object id.

Returns string.

=head2 C<url>

 my $url = $obj->url;

Get Kramerius system object url.

Returns string.

=head1 EXAMPLE1

=for comment filename=create_and_dump_kramerius.pl

 use strict;
 use warnings;

 use Data::Printer;
 use MARC::Convert::Wikidata::Object::Kramerius;

 my $obj = MARC::Convert::Wikidata::Object::Kramerius->new(
         'kramerius_id' => 'mzk',
         'object_id' => '814e66a0-b6df-11e6-88f6-005056827e52',
         'url' => 'https://www.digitalniknihovna.cz/mzk/view/uuid:814e66a0-b6df-11e6-88f6-005056827e52',
 );

 p $obj;

 # Output:
 # MARC::Convert::Wikidata::Object::Kramerius  {
 #     parents: Mo::Object
 #     public methods (0)
 #     private methods (0)
 #     internals: {
 #         kramerius_id   "mzk",
 #         object_id      "814e66a0-b6df-11e6-88f6-005056827e52" (dualvar: 8.14e+68),
 #         url            "https://www.digitalniknihovna.cz/mzk/view/uuid:814e66a0-b6df-11e6-88f6-005056827e52"
 #     }
 # }

=head1 DEPENDENCIES

L<Mo>.

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

© Michal Josef Špaček 2021-2023

BSD 2-Clause License

=head1 VERSION

0.03

=cut
