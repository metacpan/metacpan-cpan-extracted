package Locale::Geocode::Division;

use warnings;
use strict;

=head1 NAME

Locale::Geocode::Division

=head1 DESCRIPTION

Locale::Geocode::Division provides methods for
accessing information regarding administrative
divisions within territories as defined by
ISO-3166-2.

=head1 SYNOPSIS

 my $lct    = new Locale::Geocode::Division 'US';

 # lookup a subdivision of US
 my $lcd    = $lct->lookup('TN');

 # retrieve ISO-3166-2 information for US-TN
 my $name   = $lcd->name;   # Tennessee
 my $code   = $lcd->code;   # TN

 # returns an array of Locale::Geocode::Division
 # objects representing all divisions of US
 my @divs   = $lct->divisions;

=cut

use overload '""' => sub { return shift->code };

our @meta = qw(name code fips region has_notes num_notes);

=head1 METHODS

=over 4

=item new

=cut

sub new
{
	my $proto	= shift;
	my $key		= lc(shift);
	my $lct		= shift;

	my $class	= ref($proto) || $proto;
	my $self	= {};

	$self->{territory} = $lct;

	$self->{data} =	$lct->{data}->{divs_code}->{$key} ||
					$lct->{data}->{divs_fips}->{$key} ||
					$lct->{data}->{divs_name}->{$key};

	return undef if not defined $self->{data};
	return undef if not $lct->lg->chkext($self->{data});

	return bless $self, $class;
}

=item name

=cut

sub name { return shift->{data}->{name} }

=item code

=cut

sub code { return shift->{data}->{code} }

=item fips

=cut

sub fips { return shift->{data}->{fips} }

=item region

=cut

sub region { return shift->{data}->{region} }

=item parent

=cut

sub parent { return shift->{territory} }

=item has_notes

=cut

sub has_notes { return scalar @{ shift->{notes} } > 0 ? 1 : 0 }

=item num_notes

=cut

sub num_notes { return scalar @{ shift->{notes} } }

=item notes

=cut

sub notes { return @{ shift->{notes} } }

=item note

=cut

sub note { return shift->{notes}->[shift] }

=back

=head1 AUTHOR

 Mike Eldridge <diz@cpan.org>

=head1 CREDITS

 Kim Ryan

=head1 SEE ALSO

 L<Locale::Geocode>
 L<Locale::Geocode::Territory>

=cut

1;
