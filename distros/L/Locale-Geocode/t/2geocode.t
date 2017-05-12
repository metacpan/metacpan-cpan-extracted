use Test::More tests => 78;

use_ok('Locale::Geocode');

my $lg;
my $lgt;
my $lgd;
my @lgds;
my $lgt2;

$lg = new Locale::Geocode;
ok(defined($lg), 'new Locale::Geocode object');

$lgt = $lg->lookup('US');
ok(defined($lgt), 'lookup territory via ISO 3166-1 alpha-2 code "US"');
is($lgt && $lgt->alpha2, 'US', 'US: ISO 3166-1 alpha-2 code: ' . $lgt->alpha2);
is($lgt && $lgt->alpha3, 'USA', 'US: ISO 3166-1 alpha-3 code: ' . $lgt->alpha3);
cmp_ok($lgt && $lgt->num, '==', 840, 'US: ISO 3166-1 numeric code: ' . $lgt->num);
ok($lgt && $lgt->name =~ /United States/, 'US: ISO 3166-1 name: ' . $lgt->name);
is("$lgt", "US", 'US: object stringifies to "US"');

$lgt2 = $lg->lookup('CA');
ok(defined($lgt2), 'lookup territory via ISO 3166-1 alpha-2 code "CA"');
is($lgt2 && $lgt2->alpha2, 'CA', 'CA: ISO 3166-1 alpha-2 code: ' . $lgt2->alpha2);
is($lgt2 && $lgt2->alpha3, 'CAN', 'CA: ISO 3166-1 alpha-3 code: ' . $lgt2->alpha3);
cmp_ok($lgt2 && $lgt2->num, '==', 124, 'CA: ISO 3166-1 numeric code: ' . $lgt2->num);
ok($lgt2 && $lgt2->name =~ /Canada/, 'CA: ISO 3166-1 name: ' . $lgt2->name);
is("$lgt2", "CA", 'CA: object stringifies to "CA"');

# we can't use cmp_ok here because Test::Builder tries to add
# 0 to each argument in order to detect "dualvars" such as $!
ok($lgt != $lgt2, 'overloaded inequality operator');

$lgt2 = $lg->lookup('US');
ok(defined($lgt2), 'lookup territory via ISO 3166-1 alpha-2 code "US"');
is($lgt2 && $lgt2->alpha2, 'US', 'US: ISO 3166-1 alpha-2 code: ' . $lgt2->alpha2);
is($lgt2 && $lgt2->alpha3, 'USA', 'US: ISO 3166-1 alpha-3 code: ' . $lgt2->alpha3);
cmp_ok($lgt2 && $lgt2->num, '==', 840, 'US: ISO 3166-1 numeric code: ' . $lgt2->num);
ok($lgt2 && $lgt2->name =~ /United States/, 'US: ISO 3166-1 name: ' . $lgt2->name);
is("$lgt2", "US", 'US: object stringifies to "US"');

# we can't use cmp_ok here because Test::Builder tries to add
# 0 to each argument in order to detect "dualvars" such as $!
ok($lgt == $lgt2, 'overloaded equality operator');

$lgd = $lgt->lookup('TN');
ok(defined($lgd), 'US: lookup division via ISO 3166-2 code "TN"');
is($lgd && $lgd->code, 'TN', 'US-TN: ISO 3166-2 code: ' . $lgd->code);
is($lgd && $lgd->name, 'Tennessee', 'US-TN: ISO 3166-2 name: ' . $lgd->name);
is("$lgd", "TN", 'US-TN: object stringifies to "TN"');

$lgd = $lgt->lookup('AP');
ok(!defined($lgd), 'US: lookup non ISO 3166-2 code "AP"');

$lgt = $lg->lookup('UK');
ok(!defined($lgd), 'lookup ISO 3166-1 reserved alpha-2 code "UK"');

# enabling single extension for UK->GB mapping
$lg->ext(qw(uk));
ok(eq_array([ sort $lg->ext ], [ qw(uk ust) ]), 'set extensions for reserved ISO 3166-1 alpha-2 code "UK"');

$lgt = $lg->lookup('UK');
ok(!defined($lgd), 'lookup ISO 3166-1 reserved alpha-2 code "UK"');
is($lgt && $lgt->alpha2, 'UK', 'UK: ISO 3166-1 alpha-2 code: ' . $lgt->alpha2);
ok($lgt && !defined($lgt->alpha3), 'UK: ISO 3166-1 alpha-3 code: N/A');
ok($lgt && !defined($lgt->num), 'UK: ISO 3166-1 numeric code: N/A');
ok($lgt && $lgt->name =~ /United Kingdom/, 'UK: ISO 3166-1 name: ' . $lgt->name);

# usm extension still disabled
$lgt = $lg->lookup('US');
ok(defined($lgt), 'lookup territory via ISO 3166-1 alpha-2 code "US"');

$lgd = $lgt->lookup('AP');
ok(!defined($lgd), 'US: lookup non ISO 3166-2 code "AP"');

@lgds = $lgt->divisions;
cmp_ok($lgt->num_divisions, '==', 57, 'US: num_divisions is 57');
cmp_ok(scalar(@lgds), '==', 57, 'US: divisions method returns a 57 member list');
cmp_ok(
	scalar(grep { ref $_ eq 'Locale::Geocode::Division' } @lgds), '==', 57,
	'US: divisions method returns only Locale::Geocode::Division objects'
);

# disable ust extension with the ext method
$lg->ext(qw(uk -ust));
ok(eq_array([ sort $lg->ext ], [ qw(uk) ]), 'disable ust extension using ext method');

@lgds = $lgt->divisions;
cmp_ok($lgt->num_divisions, '==', 51, 'US: num_divisions is 51');
cmp_ok(scalar(@lgds), '==', 51, 'US: divisions method returns a 51 member list');
cmp_ok(
	scalar(grep { ref $_ eq 'Locale::Geocode::Division' } @lgds), '==', 51,
	'US: divisions method returns only Locale::Geocode::Division objects'
);

# re-enable ust extension using the ext_enable method
$lg->ext_enable('ust');
ok(eq_array([ sort $lg->ext ], [ qw(uk ust) ]), 'enable ust extension using ext_enable method');

@lgds = $lgt->divisions;
cmp_ok($lgt->num_divisions, '==', 57, 'US: num_divisions is 57');
cmp_ok(scalar(@lgds), '==', 57, 'US: divisions method returns a 57 member list');
cmp_ok(
	scalar(grep { ref $_ eq 'Locale::Geocode::Division' } @lgds), '==', 57,
	'US: divisions method returns only Locale::Geocode::Division objects'
);

# re-disable ust extension using the ext_disable method
$lg->ext_disable('ust');
ok(eq_array([ sort $lg->ext ], [ qw(uk) ]), 'disable ust extension using ext_disable method');

@lgds = $lgt->divisions;
cmp_ok($lgt->num_divisions, '==', 51, 'US: num_divisions is 51');
cmp_ok(scalar(@lgds), '==', 51, 'US: divisions method returns a 51 member list');
cmp_ok(
	scalar(grep { ref $_ eq 'Locale::Geocode::Division' } @lgds), '==', 51,
	'US: divisions method returns only Locale::Geocode::Division objects'
);

# enabling multiple extensions at once (US military, UK->GB alias)
$lg->ext(qw(usm uk));
ok(eq_array([ sort $lg->ext ], [ qw(uk usm ust) ]), 'enable extensions for non ISO 3166 United States Military Postal Service Agency codes');

$lgd = $lgt->lookup('AP');
ok(defined($lgd), 'US: lookup non ISO 3166-2 code "AP"');
is($lgd && $lgd->name, 'Armed Forces Pacific', 'US MPSA division name: Armed Forces Pacific');
is($lgd && $lgd->code, 'AP', 'US MPSA division code: AP');

$lgd = $lgt->lookup('FM');
ok(!defined($lgd), 'US: lookup non 3166-2 code "FM"');

@lgds = $lgt->divisions;
cmp_ok($lgt->num_divisions, '==', 60, 'US: num_divisions is 60');
cmp_ok(scalar(@lgds), '==', 60, 'US: divisions method returns a 60 member list');
cmp_ok(
	scalar(grep { ref $_ eq 'Locale::Geocode::Division' } @lgds), '==', 60,
	'US: divisions method returns only Locale::Geocode::Division objects'
);

# usps extension for blanket coverage of USPS recognized postal abbreviations
$lg->ext(qw(usps uk));
ok(eq_array([ sort $lg->ext ], [ qw(uk usps ust) ]), 'enable extensions for non ISO 3166 United States Postal Service codes');

$lgd = $lgt->lookup('AP');
ok(defined($lgd), 'US: lookup non ISO 3166-2 code "AP"');
is($lgd && $lgd->name, 'Armed Forces Pacific', 'US MPSA division name: Armed Forces Pacific');
is($lgd && $lgd->code, 'AP', 'USPS division code: AP');

$lgd = $lgt->lookup('FM');
ok(defined($lgd), 'US: lookup non ISO 3166-2 code "FM"');
is($lgd && $lgd->name, 'Federated States of Micronesia', 'USPS division name: Federated States of Micronesia');
is($lgd && $lgd->code, 'FM', 'USPS division code: FM');

@lgds = $lgt->divisions;
ok($lgt->num_divisions == 63, 'US: num_divisions is 63');
cmp_ok(scalar(@lgds), '==', 63, 'US: divisions method returns a 63 member list');
cmp_ok(
	scalar(grep { ref $_ eq 'Locale::Geocode::Division' } @lgds), '==', 63,
	'US: divisions method returns only Locale::Geocode::Division objects'
);

# enabling multiple extensions at once (European Union and WCO)
$lg->ext(qw(eu wco));
ok(eq_array([ sort $lg->ext ], [ qw(eu ust wco) ]), 'set extensions for reserved ISO 3166 codes for EU/WCO statistical purposes');

$lgt = $lg->lookup('IC');
ok(defined($lgt), 'IC: lookup territory via reserved ISO 3166-1 alpha-2 code "IC"');
ok($lgt && $lgt->alpha2 eq 'IC', 'IC: ISO 3166-1 alpha-2 code: ' . $lgt->alpha2);
ok($lgt && !defined($lgt->alpha3), 'IC: ISO 3166-1 alpha-3 code: N/A');
ok($lgt && !defined($lgt->num), 'IC: ISO 3166-1 numeric code: N/A');
ok($lgt && $lgt->name eq 'Canary Islands', 'IC: ISO 3166-1 name: ' . $lgt->name);
ok($lgt && $lgt->has_notes, 'IC: has notes');
ok($lgt && $lgt->num_notes == 1, 'IC: number of notes: ' . $lgt->num_notes);
ok($lgt && $lgt->note(0) eq 'reserved on request of WCO to represent area outside EU customs territory', 'IC: note 0: ' . $lgt->note(0));

