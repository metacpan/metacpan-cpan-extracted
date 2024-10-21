use strict;
use warnings;

package Health::SHC;

# ABSTRACT: Extract and verify Smart Health Card information

our $VERSION = '0.006';

=head1 NAME

Health::SHC - Verify Smart Health Card Signature and Extract data.

=head1 SYNOPSIS

    use Health::SHC::Validate;
    my $shc_valid = Health::SHC::Validate->new();

    # Use builtin trusted keys
    my $data = $shc_valid->get_valid_data($qr);

    # Use your own keys to validate - you may trust them
    my $data = $shc_valid->get_valid_data($qr, $keys_json);

    use Health::SHC;
    my $sh = Health::SHC->new();
    my @patients = $sh->get_patients($data);

    foreach (@patients) {
        print "Patient: ", $_->{given}, " ", $_->{middle}, " ", $_->{family}, "\n";
    }

    my @immunizations = $sh->get_immunizations($data);

    print "Vacination Provider", "\t", "Date", "\n";
    foreach (@immunizations) {
        print $_->{provider}, "\t", $_->{date}, "\n";
    }

    my @vaccines = $sh->get_vaccines($data);

    print "Manufacturer\tLot Number\tCode\tCode System\n";
    foreach (@vaccines) {
        print $_->{manufacturer}, "\t\t", $_->{lotNumber}, "\t\t";
        my $codes = $_->{codes};
        foreach my $tmp (@$codes) {
            print   $tmp->{code}, "\t",
                    $tmp->{system}, "\t";
        }
        print "\n";
    }

=head1 DESCRIPTION

=encoding utf-8

This perl module can extract a Smart Health Card's data from PDFs or image file.
The extracted shc:/ Smart Health Card URI is decoded and the signature checked.
The module provide several methods to retrieve the data in a more usable format.

Health::SHC supports QR codes for the following regions:

    * Québec
    * British Columbia
    * Saskatchewan
    * Alberta
    * Newfoundland and Labrador
    * Nova Scotia
    * Ontario
    * Northwest Territories
    * Yukon
    * New Brunswick/Nouveau-Brunswick
    * Japan

The keys in share/keys.json (and supported regions) are based on the keys
included with https://github.com/obrassard/shc-extractor.

Additional regions can be added with a pull request or by logging an issue
at https://github.com/timlegge/perl-Health-SHC/issues.

=cut

=head1 COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright 2021 - 2024 Timothy Legge <timlegge@gmail.com>

=head1 LICENCE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 METHODS

=head3 B<new(...)>

Constructor; see OPTIONS above.

=cut

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;
}

=head3 B<get_patients($data)>

Arguments:
    $data:     string Smart Health Card data without the "shc:/" prefix

Returns: hash containing the Patient information

=cut

sub get_patients {
    my $self = shift;
    my $data = shift;

    my $entrys = $data->{vc}{credentialSubject}{fhirBundle}{entry};
    my %lookup = map { $_->{fullUrl} => $_ } @$entrys;

    my (@p) = grep { 'Patient' eq $lookup{$_}->{resource}{resourceType} } keys %lookup;

    my @patients;
    foreach (@p) {
        my %patient;
        $patient{family} = $lookup{$_}->{resource}{name}[0]{family} || "";
        $patient{given}  = $lookup{$_}->{resource}{name}[0]{given}[0] || "";
        $patient{middle} = $lookup{$_}->{resource}{name}[0]{given}[1] || "";
        push (@patients, {%patient});
    }
    return @patients;
}

=head3 B<get_immunizations($data)>

Arguments:
    $data:     string Smart Health Card data without the "shc:/" prefix

Returns: hash containing the Immunization data

=cut

sub get_immunizations {
    my $self = shift;
    my $data = shift;

    my $entrys = $data->{vc}{credentialSubject}{fhirBundle}{entry};
    my %lookup = map { $_->{fullUrl} => $_ } @$entrys;

    my (@i) = grep { 'Immunization' eq $lookup{$_}->{resource}{resourceType} } keys %lookup;

    my @immunizations;
    foreach (@i) {
        my %immunization;
        $immunization{provider} = $lookup{$_}->{resource}{performer}[0]{actor}{display} || "";
        $immunization{date} = $lookup{$_}->{resource}{occurrenceDateTime} || "";
        push (@immunizations, {%immunization});
    }
    return @immunizations;
}

=head3 B<get_vaccines($data)>

Arguments:
    $data:     string Smart Health Card data without the "shc:/" prefix

Returns: hash containing the Vaccine data

=cut

sub get_vaccines {
    my $self = shift;
    my $data = shift;

    my $entrys = $data->{vc}{credentialSubject}{fhirBundle}{entry};
    my %lookup = map { $_->{fullUrl} => $_ } @$entrys;

    my (@i) = grep { $lookup{$_}->{resource}{lotNumber} } keys %lookup;

    my @vaccines;
    foreach (@i) {
        my $resource = $lookup{$_}->{resource};
        my %vaccine;
        $vaccine{lotNumber} = $resource->{lotNumber} || "";
        $vaccine{manufacturer} = $resource->{manufacturer}{identifier}{value} || "";
        my $codes = $resource->{vaccineCode}{coding};
        my @retcodes;
        foreach my $code (@$codes) {
            my %tmp = (
                        code => $code->{code},
                        system => $code->{system},
                      );
            push (@retcodes, {%tmp});
        }
        $vaccine{codes} = [@retcodes];
        push (@vaccines, {%vaccine});
    }
    return @vaccines;
}

1;
