package MARC::Convert::Wikidata::Object::ISBN;

use strict;
use warnings;

use Business::ISBN;
use Error::Pure qw(err);
use Mo qw(build is);
use Mo::utils 0.08 qw(check_isa check_required);
use List::Util qw(none);
use Readonly;

Readonly::Array our @COVERS => qw(hardback paperback);

our $VERSION = 0.04;

has cover => (
	is => 'ro',
);

has isbn => (
	is => 'ro',
);

has publisher => (
	is => 'ro',
);

sub type {
	my $self = shift;

	if ($self->{'_isbn'}->as_isbn10->as_string eq $self->{'isbn'}) {
		return 10;
	} else {
		return 13;
	}
}

sub BUILD {
	my $self = shift;

	check_required($self, 'isbn');

	$self->{'_isbn'} = Business::ISBN->new($self->{'isbn'});
	if (! defined $self->{'_isbn'} || ! $self->{'_isbn'}->is_valid) {
		err "ISBN '$self->{'isbn'}' isn't valid.";
	}

	check_isa($self, 'publisher', 'MARC::Convert::Wikidata::Object::Publisher');

	if (defined $self->{'cover'}) {
		if (none { $self->{'cover'} eq $_ } @COVERS) {
			err "ISBN cover '$self->{'cover'}' isn't valid.";
		}
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

MARC::Convert::Wikidata::Object::ISBN - Bibliographic Wikidata object for ISBN number defined by MARC record.

=head1 SYNOPSIS

 use MARC::Convert::Wikidata::Object::ISBN;

 my $obj = MARC::Convert::Wikidata::Object::ISBN->new(%params);
 my $cover = $obj->cover;
 my $isbn = $obj->isbn;
 my $publisher = $obj->publisher;
 my $type = $obj->type;

=head1 METHODS

=head2 C<new>

 my $obj = MARC::Convert::Wikidata::Object::ISBN->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<cover>

ISBN cover.

Parameter is optional. Valid values are: hardback, paperback

Default value is undef.

=item * C<isbn>

ISBN number.

Parameter is required.

Default value is undef.

=item * C<publisher>

Publishing house object.
Instance of MARC::Convert::Wikidata::Object::Publisher.

Default value is undef.

=back

=head2 C<cover>

 my $cover = $obj->cover;

Get ISBN cover.

Returns string.

=head2 C<isbn>

 my $isbn = $obj->isbn;

Get ISBN number.

Returns string.

=head2 C<publisher>

 my $publisher = $obj->publisher;

Get publishing house name.

Returns instance of MARC::Convert::Wikidata::Object::Publisher.

=head2 C<type>

 my $type = $obj->type;

Get type of ISBN number (10 or 13 character length)

Returns number (10 or 13).

=head1 ERRORS

 new():
         Parameter 'isbn' is required.
         ISBN '%s' isn't valid.
         ISBN cover '%s' isn't valid.
         From check_isa():
                 Parameter 'publisher' must be a 'MARC::Convert::Wikidata::Object::Publisher' object.

=head1 EXAMPLE1

=for comment filename=create_and_dump_isbn.pl

 use strict;
 use warnings;

 use Data::Printer;
 use MARC::Convert::Wikidata::Object::ISBN;
 use MARC::Convert::Wikidata::Object::Publisher;
 
 my $obj = MARC::Convert::Wikidata::Object::ISBN->new(
         'isbn' => '978-80-00-05046-1',
         'publisher' => MARC::Convert::Wikidata::Object::Publisher->new(
                 'name' => 'Albatros',
         ),
 );
 
 p $obj;

 # Output:
 # MARC::Convert::Wikidata::Object::ISBN  {
 #     Parents       Mo::Object
 #     public methods (9) : BUILD, can (UNIVERSAL), DOES (UNIVERSAL), err (Error::Pure), check_isa (Mo::utils), check_required (Mo::utils), isa (UNIVERSAL), type, VERSION (UNIVERSAL)
 #     private methods (1) : __ANON__ (Mo::build)
 #     internals: {
 #         _isbn       Business::ISBN13,
 #         isbn        "978-80-00-05046-1",
 #         publisher   MARC::Convert::Wikidata::Object::Publisher
 #     }
 # }

=head1 DEPENDENCIES

L<Business::ISBN>,
L<Error::Pure>,
L<Mo>,
L<Mo::utils>,
L<List::Util>,
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

0.04

=cut
