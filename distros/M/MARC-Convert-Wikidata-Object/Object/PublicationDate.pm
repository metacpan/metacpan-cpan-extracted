package MARC::Convert::Wikidata::Object::PublicationDate;

use strict;
use warnings;

use Error::Pure qw(err);
use Mo qw(build is);
use Mo::utils 0.15 qw(check_bool check_strings);
use Mo::utils::Date 0.02 qw(check_date);
use Readonly;

Readonly::Array our @SOURCING_CIRCUMSTANCES => qw(circa near presumably disputed);

our $VERSION = 0.06;

has copyright => (
	is => 'ro',
);

has date => (
	is => 'ro',
);

has earliest_date => (
	is => 'ro',
);

has end_time => (
	is => 'ro',
);

has latest_date => (
	is => 'ro',
);

has sourcing_circumstances => (
	is => 'ro',
);

has start_time => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Conflicts.
	_check_conflict($self, 'date', 'earliest_date');
	_check_conflict($self, 'date', 'latest_date');
	_check_conflict($self, 'date', 'start_time');
	_check_conflict($self, 'date', 'end_time');
	_check_conflict($self, 'earliest_date', 'start_time');
	_check_conflict($self, 'earliest_date', 'end_time');
	_check_conflict($self, 'latest_date', 'start_time');
	_check_conflict($self, 'latest_date', 'end_time');

	if (! defined $self->{'copyright'}) {
		$self->{'copyright'} = 0;
	}
	check_bool($self, 'copyright');

	check_date($self, 'date');

	check_date($self, 'earliest_date');

	check_date($self, 'end_time');

	check_date($self, 'latest_date');

	check_strings($self, 'sourcing_circumstances', \@SOURCING_CIRCUMSTANCES);

	check_date($self, 'start_time');

	return;
}

# TODO To Mo::utils.
sub _check_conflict {
	my ($self, $param1, $param2) = @_;

	if (defined $self->{$param1} && defined $self->{$param2}) {
		err "Parameter '$param1' is in conflict with parameter '$param2'.";
	}

	return;	
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

MARC::Convert::Wikidata::Object::PublicationDate - Bibliographic Wikidata object for publication date defined by MARC record.

=head1 SYNOPSIS

 use MARC::Convert::Wikidata::Object::PublicationDate;

 my $obj = MARC::Convert::Wikidata::Object::PublicationDate->new(%params);
 my $copyright = $obj->copyright;
 my $date = $obj->date;
 my $earliest_date = $obj->earliest_date;
 my $end_time = $obj->end_time;
 my $latest_date = $obj->latest_date;
 my $sourcing_circumstances = $obj->sourcing_circumstances;
 my $start_time = $obj->start_time;

=head1 DESCRIPTION

The object for store publication date in book editions in the Czech National
Library.

Possible scenarios are:

=over

=item Precise date

We could use 'date' parameter to store publication date.

=item Date between

We could use 'earliest_date' and 'latest_date' parameters to store publication
date.

=item Date defined as period of time

We could use 'start_time' and 'end_time' parameters to store publication date.
e.g. For book series which one volume is from 'start_time' and last volume from
'end_time' publication date.

=item Date which is with some accuracy

We could use 'date' and 'sourcing_circumstances' parameters do define accuracy
(e.g. circa).

=item Date for copyright

We could use previous versions with 'copyright' parameter.

=back

=head1 METHODS

=head2 C<new>

 my $obj = MARC::Convert::Wikidata::Object::PublicationDate->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<copyright>

Flag, that date is for copyright.

Default value is 0.

=item * C<date>

Precise date.

Date is in YYYY-MM-DD, YYYY-M-D, YYYY-MM, YYYY-M or YYYY format.

The parameter is in conflict with (earliest_date and latest_date) and (start_time
and end_time).

Default value is undef.

=item * C<earliest_date>

Earliest date for definition publication date between dates.

Date is in YYYY-MM-DD, YYYY-M-D, YYYY-MM, YYYY-M or YYYY format.

The parameter is in conflict with (date) and (start_time
and end_time).

Default value is undef.

=item * C<end_time>

End date for definition publication date via period of time.

Date is in YYYY-MM-DD, YYYY-M-D, YYYY-MM, YYYY-M or YYYY format.

The parameter is in conflict with (date) and (earliest_date and latest_date).

Default value is undef.

=item * C<latest_date>

Latest date for definition publication date between dates.

Date is in YYYY-MM-DD, YYYY-M-D, YYYY-MM, YYYY-M or YYYY format.

The parameter is in conflict with (date) and (start_time
and end_time).

Default value is undef.

=item * C<sourcing_circumstances>

Sourcing circumstances string.

Possible values are:

=over

=item * circa

=item * near

=item * presumably

=item * disputed

=back

=item * C<start_time>

Start date for definition publication date via period of time.

Date is in YYYY-MM-DD, YYYY-M-D, YYYY-MM, YYYY-M or YYYY format.

The parameter is in conflict with (date) and (earliest_date and latest_date).

Default value is undef.

=back

=head2 C<copyright>

 my $copyright = $obj->copyright;

Get copyright flag.

Returns 0/1.

=head2 C<date>

 my $date = $obj->date;

Get date.

Returns string.

=head2 C<earliest_date>

 my $earliest_date = $obj->earliest_date;

Get earlest date.

Returns string.

=head2 C<end_time>

 my $end_time = $obj->end_time;

Get end time.

Returns string.

=head2 C<latest_date>

 my $latest_date = $obj->latest_date;

Get latest date.

Returns string.

=head2 C<sourcing_circumstances>

 my $sourcing_circumstances = $obj->sourcing_circumstances;

Get sourcing circumstances string.

Returns string.

=head2 C<start_time>

 my $start_time = $obj->start_time;

Get start time.

Returns string.

=head1 ERRORS

 new():
         From Mo::utils::check_bool():
                 Parameter 'copyright' must be a bool (0/1).
                         Value: %s
         From Mo::utils::check_strings():
                 Parameter 'sourcing_circumstances' must have strings definition.
                 Parameter 'sourcing_circumstances' must have right string definition.
                 Parameter 'sourcing_circumstances' must be one of defined strings.
                         String: %s
                         Possible strings: %s
         From Mo::utils::Date::check_date():
                 Parameter 'date' for date is in bad format.
                         Value: %s
                 Parameter 'date' has year greater than actual year.
                 Parameter 'earliest_date' for date is in bad format.
                         Value: %s
                 Parameter 'earliest_date' has year greater than actual year.
                 Parameter 'end_time' for date is in bad format.
                         Value: %s
                 Parameter 'end_time' has year greater than actual year.
                 Parameter 'start_time' for date is in bad format.
                         Value: %s
                 Parameter 'start_time' has year greater than actual year.
         Parameter 'date' is in conflict with parameter 'earliest_date'.
         Parameter 'date' is in conflict with parameter 'latest_date'.
         Parameter 'date' is in conflict with parameter 'start_time'.
         Parameter 'date' is in conflict with parameter 'end_time'.
         Parameter 'earliest_date' is in conflict with parameter 'start_time'.
         Parameter 'earliest_date' is in conflict with parameter 'end_time'.
         Parameter 'latest_date' is in conflict with parameter 'start_time'.
         Parameter 'latest_date' is in conflict with parameter 'end_time'.

=head1 EXAMPLE1

=for comment filename=create_and_dump_publication_date1.pl

 use strict;
 use warnings;

 use Data::Printer;
 use MARC::Convert::Wikidata::Object::PublicationDate;
 
 my $obj = MARC::Convert::Wikidata::Object::PublicationDate->new(
         'date' => '2014',
 );
 
 p $obj;

 # Output:
 # MARC::Convert::Wikidata::Object::PublicationDate  {
 #     parents: Mo::Object
 #     public methods (5):
 #         BUILD
 #         Error::Pure:
 #             err
 #         Mo::utils:
 #             check_bool, check_strings
 #         Readonly:
 #             Readonly
 #     private methods (1): _check_conflict
 #     internals: {
 #         date   2014
 #     }
 # }

=head1 EXAMPLE2

=for comment filename=create_and_dump_publication_date2.pl

 use strict;
 use warnings;

 use Data::Printer;
 use MARC::Convert::Wikidata::Object::PublicationDate;
 
 my $obj = MARC::Convert::Wikidata::Object::PublicationDate->new(
         'earliest_date' => '2014',
         'latest_date' => '2020',
 );
 
 p $obj;

 # Output:
 # MARC::Convert::Wikidata::Object::PublicationDate  {
 #     parents: Mo::Object
 #     public methods (5):
 #         BUILD
 #         Error::Pure:
 #             err
 #         Mo::utils:
 #             check_bool, check_strings
 #         Readonly:
 #             Readonly
 #     private methods (1): _check_conflict
 #     internals: {
 #         earliest_date   2014,
 #         latest_date     2020
 #     }
 # }

=head1 EXAMPLE3

=for comment filename=create_and_dump_publication_date3.pl

 use strict;
 use warnings;

 use Data::Printer;
 use MARC::Convert::Wikidata::Object::PublicationDate;
 
 my $obj = MARC::Convert::Wikidata::Object::PublicationDate->new(
         'start_time' => '2014',
         'end_time' => '2020',
 );
 
 p $obj;

 # Output:
 # MARC::Convert::Wikidata::Object::PublicationDate  {
 #     parents: Mo::Object
 #     public methods (5):
 #         BUILD
 #         Error::Pure:
 #             err
 #         Mo::utils:
 #             check_bool, check_strings
 #         Readonly:
 #             Readonly
 #     private methods (1): _check_conflict
 #     internals: {
 #         end_time     2020,
 #         start_time   2014
 #     }
 # }

=head1 EXAMPLE4

=for comment filename=create_and_dump_publication_date4.pl

 use strict;
 use warnings;

 use Data::Printer;
 use MARC::Convert::Wikidata::Object::PublicationDate;
 
 my $obj = MARC::Convert::Wikidata::Object::PublicationDate->new(
         'date' => '2014',
         'sourcing_circumstances' => 'circa',
 );
 
 p $obj;

 # Output:
 # MARC::Convert::Wikidata::Object::PublicationDate  {
 #     parents: Mo::Object
 #     public methods (5):
 #         BUILD
 #         Error::Pure:
 #             err
 #         Mo::utils:
 #             check_bool, check_strings
 #         Readonly:
 #             Readonly
 #     private methods (1): _check_conflict
 #     internals: {
 #         date                     2014,
 #         sourcing_circumstances   "circa"
 #     }
 # }

=head1 EXAMPLE5

=for comment filename=create_and_dump_publication_date5.pl

 use strict;
 use warnings;

 use Data::Printer;
 use MARC::Convert::Wikidata::Object::PublicationDate;
 
 my $obj = MARC::Convert::Wikidata::Object::PublicationDate->new(
         'copyright' => 1,
         'date' => '2014',
 );
 
 p $obj;

 # Output:
 # MARC::Convert::Wikidata::Object::PublicationDate  {
 #     parents: Mo::Object
 #     public methods (5):
 #         BUILD
 #         Error::Pure:
 #             err
 #         Mo::utils:
 #             check_bool, check_strings
 #         Readonly:
 #             Readonly
 #     private methods (1): _check_conflict
 #     internals: {
 #         copyright   1,
 #         date        2014
 #     }
 # }

=head1 DEPENDENCIES

L<Error::Pure>,
L<Mo>,
L<Mo::utils>,
L<Mo::utils::Date>,
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

0.06

=cut
