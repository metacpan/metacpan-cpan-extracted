package ICANN::gTLD;
# ABSTRACT: an interface to the ICANN gTLD database.
use Carp;
use Data::Mirror qw(mirror_json);
use DateTime::Format::ISO8601;
use Net::DNS::Domain;
use Net::RDAP 0.34;
use Net::RDAP::Registry;
use Data::DNS;
use URI;
use constant GTLD_LIST_URL => q{https://www.icann.org/resources/registries/gtlds/v2/gtlds.json};
use vars qw($VERSION);
use warnings;
use strict;

$VERSION = '0.02';


sub get_json {
	my $package = shift;
	return mirror_json(GTLD_LIST_URL) || croak(q{Unable to retrieve gTLD list});
}

sub get_all {
	my $package = shift;

	my $json = $package->get_json;

	return map { $package->new($_) } @{$json->{gTLDs}};
}

sub get {
	my ($package, $gTLD) = @_;

	my $json = $package->get_json;

    my @array = @{$json->{gTLDs}};

    my $ref = [ grep { lc($_->{gTLD}) eq lc($gTLD) } @array ]->[0];

	return $ref ? $package->new($ref) : undef;
}

sub from_domain {
    my ($package, $domain) = @_;

    my @labels = grep { length > 0 } split(/\./, lc($domain));

    return $package->get(pop(@labels));
}

sub new {
    my ($package, $ref) = @_;

    croak(q{hashref expected, got a }.(ref($ref) || q{scalar})) unless (q{HASH} eq ref($ref));

    return bless($ref, $package);
}


sub gtld                                { Net::DNS::Domain->new(shift->{gTLD}) }
sub name                                { shift->gtld->name }
sub u_label                             { shift->{uLabel} }
sub registry_operator                   { shift->{registryOperator} }
sub registry_operator_country_code      { shift->{registryOperatorCountryCode} }
sub date_of_contract_signature          { DateTime::Format::ISO8601->parse_datetime(shift->{dateOfContractSignature} || return undef) }
sub delegation_date                     { DateTime::Format::ISO8601->parse_datetime(shift->{delegationDate} || return undef) }
sub removal_date                        { DateTime::Format::ISO8601->parse_datetime(shift->{removalDate} || return undef) }
sub contract_terminated                 { shift->{contractTerminated} }
sub application_id                      { shift->{applicationId} }
sub third_or_lower_level_registration   { shift->{thirdOrLowerLevelRegistration} }
sub registry_class_domain_name_list     { URI->new(shift->{registryClassDomainNameList} || return undef) }
sub specification_13                    { shift->{specification13} }
sub rdap_record                         { Net::RDAP->new->fetch(URI->new(q{https://rdap.iana.org/domain/}.shift->gtld->name)) }
sub rdap_server                         { Net::RDAP::Service->new_for_tld(shift->gtld->name) }
sub tld                                 { Data::DNS->get(shift->gtld->name)}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ICANN::gTLD - an interface to the ICANN gTLD database.

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    use ICANN::gTLD;

    # get info about a specific gTLD
    my $gtld = ICANN::gTLD->get('org');

    printf(
        "The .%s gTLD is operated by %s and was delegated in %s.\n",
        ($gtld->uLabel || $gtld->gtld)->name,
        $gtld->registryOperator,
        $gtld->delegationDate->year,
    );

    # get info about all gTLDs
    my @gtlds = ICANN::gTLD->get_all;

=head1 INTRODUCTION

ICANN publishes a machine-readable database of information about generic
top-level domains (TLDs) on its website. This module provides access to that
database.

B<Note:> a I<generic> TLD is a TLD like C<.org> or C<.机构> (C<.xn--nqv7f>), as
distinguished from (a) I<country-code> TLDs such as C<.uk> or C<.台灣>
(C<.xn--kpry57d>), (b) I<"sponsored"> TLDs (specifically C<.gov>, C<.mil> and
C<.edu>), and (c) the special "infrastructure" TLD, C<.arpa>.

B<Also note:> the DNS root zone is not static, and gTLDs are created and removed
regularly. It should not be assumed that the data elements provided by this
module will never change.

=head1 INTERNALS

C<ICANN::gTLD> uses L<Data::Mirror> to synchronise a local copy of the
database of gTLD information from the ICANN website. See the L<Data::Mirror>
documentation to find out how to control its behaviour.

=head1 GETTING TLD OBJECTS

    my $tld = ICANN::gTLD->get($name);

    my $tld = ICANN::gTLD->from_domain($name);

    my @all = ICANN::gTLD->get_all;

To get information about a specific gTLD, use C<get()>. To get information
about the parent TLD of a domain name, use C<from_domain()>. If the specified
string does not correspond to a gTLD, these methods will return C<undef>.

To get a list of I<all> gTLDs, use C<get_all()>.

=head1 OBJECT METHODS

The methods listed below list the available data elements for each TLD. Note
that not all fields are available or applicable for all TLDs, so all of these
methods (except C<gTLD()>) may return C<undef>.

=over

=item * C<$gtld-E<gt>name> - shortcut for C<$gtld-E<gt>gtld-E<gt>name>.

=item * C<$gtld-E<gt>gtld> - returns a L<Net::DNS::DomainName> object
representing the gTLD's A-label (eg C<org> or C<xn--nqv7f>).

=item * C<$gtld-E<gt>u_label> - returns the U-label (eg C<机构>) for an IDN
gTLD.

=item * C<$gtld-E<gt>registry_operator> - returns the legal name of the Registry
Operator.

=item * C<$gtld-E<gt>registry_operator_country_code> - returns the 2-character
ISO-3166 code in which the Registry Operator is based. I<Note: as of writing,
this field is C<null> for all entries in the data source, so this method will
always return C<undef> until the data source includes these values.>

=item * C<$gtld-E<gt>date_of_contract_signature> - returns a L<DateTime> object
corresponding to when the Registry Agreement between ICANN and the Registry
Operator was signed.

=item * C<$gtld-E<gt>delegation_date> - returns a L<DateTime> object
corresponding to when the TLD was delegated (if it has been, since new gTLDs
come along from time to time, otherwise C<undef>).

=item * C<$gtld-E<gt>removal_date> - returns a L<DateTime> object
corresponding to when the TLD was removed from the root zone (if it has been,
otherwise C<undef>).

=item * C<$gtld-E<gt>contract_terminated> - returns a L<DateTime> object
corresponding to when the Registry Agreement was terminated (if it has been,
otherwise C<undef>).

=item * C<$gtld-E<gt>application_id> - returns the unique ID of the application
for the gTLD received by ICANN (if any).

=item * C<$gtld-E<gt>specification_13> - returns a boolean indicating whether
the Registry Agreement includes L<an exemption from the Registry Operator Code of
Conduct|https://www.icann.org/en/blogs/details/new-gtld-registry-operator-code-of-conduct-12-6-2014-en>,
which indicates that the gTLD is a "brand" TLD that is exclusively used by the
Registry Operator, or its affiliates.

=item * C<$gtld-E<gt>third_or_lower_level_registration> - returns a boolean
indicating whether the gTLD accepts registrations at the third-level or lower
(i.e. accepts registrations of the form C<foo.bar.example> rather than
C<foo-bar.example>).

=item * C<$gtld-E<gt>registry_class_domain_name_list> - returns a L<URI> object
where a CSV (Comma Separated Values) file containing the list of "registry class
domain names" (see L<Section 3.1 of RFC
9022|https://www.rfc-editor.org/rfc/rfc9022.html#section-3.1>) may be found, if
available. C<Data::Mirror-E<gt>mirror_csv()> may be used to retrieve the
contents of this file.

=item * C<$gtld-E<gt>rdap_record> - returns a L<Net::RDAP::Object::Domain>
object containing registration data for the TLD, obtained from the IANA RDAP
Service.

=item * C<$gtld-E<gt>rdap_server> - returns a L<Net::RDAP::Service> object
that represents the gTLD's RDAP service, as specified in the RDAP DNS Bootstrap
Registry.

=item * C<$gtld-E<gt>tld> - returns a L<Data::DNS::TLD> object that represents
the gTLD's entry in the DNS root zone database.

=back

=head1 AUTHOR

Gavin Brown <gavin.brown@icann.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Internet Corporation For Assigned Names And Numbers (ICANN).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
