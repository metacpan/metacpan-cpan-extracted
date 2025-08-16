our @EXPORT_OK = qw(parse_address);
package Geo::Address::Parser::Rules::UK;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(parse_address);

=head1 NAME

Geo::Address::Parser::Rules::UK - Parsing rules for UK addresses

=head1 DESCRIPTION

Parses a flat UK address string into components: name, street, city, and postcode.

=head1 EXPORTS

=head2 parse_address($text)

Returns a hashref with keys:

=over

=item * name

=item * street

=item * city

=item * postcode

=back

=cut

my $postcode_re = qr/\b([A-Z]{1,2}\d{1,2}[A-Z]?)\s*(\d[A-Z]{2})\b/i;

my %uk_countries = map { $_ => 1 } qw(England Scotland Wales 'Northern Ireland');

my %uk_counties = map { $_ => 1 } (
# England
		'Bedfordshire', 'Berkshire', 'Bristol', 'Buckinghamshire', 'Cambridgeshire',
		'Cheshire', 'City of London', 'Cornwall', 'Cumbria', 'Derbyshire',
		'Devon', 'Dorset', 'Durham', 'East Riding of Yorkshire', 'East Sussex',
		'Essex', 'Gloucestershire', 'Greater London', 'Greater Manchester', 'Hampshire',
		'Herefordshire', 'Hertfordshire', 'Isle of Wight', 'Kent', 'Lancashire',
		'Leicestershire', 'Lincolnshire', 'Merseyside', 'Norfolk', 'North Yorkshire',
		'Northamptonshire', 'Northumberland', 'Nottinghamshire', 'Oxfordshire', 'Rutland',
		'Shropshire', 'Somerset', 'South Yorkshire', 'Staffordshire', 'Suffolk',
		'Surrey', 'Tyne and Wear', 'Warwickshire', 'West Midlands', 'West Sussex',
		'West Yorkshire', 'Wiltshire', 'Worcestershire',
# Scotland
		'Aberdeenshire', 'Angus', 'Argyll and Bute', 'Clackmannanshire', 'Dumfries and Galloway',
		'Dundee', 'East Ayrshire', 'East Dunbartonshire', 'East Lothian', 'East Renfrewshire',
		'Edinburgh', 'Falkirk', 'Fife', 'Glasgow', 'Highland',
		'Inverclyde', 'Midlothian', 'Moray', 'Na h-Eileanan Siar', 'North Ayrshire',
		'North Lanarkshire', 'Orkney Islands', 'Perth and Kinross', 'Renfrewshire', 'Scottish Borders',
		'Shetland Islands', 'South Ayrshire', 'South Lanarkshire', 'Stirling', 'West Dunbartonshire',
		'West Lothian',
# Wales
		'Blaenau Gwent', 'Bridgend', 'Caerphilly', 'Cardiff', 'Carmarthenshire',
		'Ceredigion', 'Conwy', 'Denbighshire', 'Flintshire', 'Gwynedd',
		'Isle of Anglesey', 'Merthyr Tydfil', 'Monmouthshire', 'Neath Port Talbot', 'Newport',
		'Pembrokeshire', 'Powys', 'Rhondda Cynon Taf', 'Swansea', 'Torfaen',
		'Vale of Glamorgan', 'Wrexham',
# Northern Ieland
		'Antrim', 'Armagh', 'Belfast', 'Castlereagh', 'Coleraine',
		'Cookstown', 'Craigavon', 'Down', 'Dungannon', 'Fermanagh',
		'Larne', 'Limavady', 'Lisburn', 'Londonderry', 'Magherafelt',
		'Moyle', 'Newry and Mourne', 'Newtownabbey', 'North Down', 'Omagh',
		'Strabane', 'Tyrone'
);

sub parse_address {
	my ($class, $text) = @_;
	return unless defined $text;

	my @parts = map { s/^\s+|\s+$//gr } split /,/, $text;
	@parts = grep { length $_ } @parts;

	my ($name, $street, $city, $county, $postcode, $country);

	# Remove trailing country if present
	if(@parts && exists $uk_countries{$parts[-1]}) {
		$country = 'UK';
		pop @parts;
	}

	# Look for postcode at end
	if(@parts && $parts[-1] =~ /$postcode_re/) {
		$postcode = uc("$1 $2");
		pop @parts;
	}

	# Check if last remaining token is a county
	if(@parts && exists $uk_counties{$parts[-1]}) {
		$county = pop @parts;
	}

	# Assign city: last remaining token
	if(@parts) {
		$city = pop @parts;
	}

	# Determine street and name
	if(@parts) {
		# Heuristic: if first remaining token contains a number, treat it as street
		if($parts[-1] =~ /\d/) {
			$street = pop @parts;
		}
	}

	# Remaining tokens form name
	$name = join(', ', @parts) if @parts;

	return {
		name => $name,
		street => $street,
		city => $city,
		county => $county,
		postcode => $postcode,
		country => $country // 'UK',
	};
}

1;
