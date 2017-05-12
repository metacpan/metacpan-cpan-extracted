#!/usr/bin/perl
use strict;
use warnings;

use Test::Most;
use Test::MockModule;
use SOAP::Lite;
require Test::NoWarnings;
use Data::Dumper;

use lib 'lib';
use_ok('Experian::IDAuth');

my $tmp = $ENV{TEMP} || '/tmp';    # portability between windows and linux

unlink $_ for <"$tmp/proveid/*">;
rmdir "$tmp/proveid/*";

my $module = Test::MockModule->new('SOAP::Lite');
my $xml;

# create a return object
{

    package SOM;

    sub new {
        my ($class) = @_;
        my $self = {};
        bless $self, $class;
        return $self;
    }

    sub fault {
        return 0;
    }

    sub result {
        $xml = <<EOD;
<?xml version="1.0" encoding="utf-8"?>
<Search Type="Result">
  <CountryCode>GBR</CountryCode>
  <Person>
    <Name>
      <Forename>XXX</Forename>
      <Surname>XXX</Surname>
    </Name>
    <DateOfBirth>1960-11-08</DateOfBirth>
    <Age>52</Age>
  </Person>
  <Addresses>
    <Address Current="1">
      <Premise>XXX</Premise>
      <Postcode>SM6 0RA</Postcode>
      <CountryCode>GBR</CountryCode>
    </Address>
  </Addresses>
  <Telephones>
    <Telephone Type="U">
      <Number>448777777777</Number>
    </Telephone>
  </Telephones>
  <YourReference>PK_MX1003_1360909791</YourReference>
  <SearchOptions>
    <ProductCode>ProveID_KYC</ProductCode>
  </SearchOptions>
  <OurReference>17A0C43C-09D4-44BE-9C70-5C8B7904A260</OurReference>
  <SearchDate>2013-02-15T06:29:54</SearchDate>
  <Result>
    <Summary>
      <KYCSummary>
        <FullNameAndAddress>
          <Count>4</Count>
        </FullNameAndAddress>
        <SurnameAndAddress>
          <Count>4</Count>
        </SurnameAndAddress>
        <Address>
          <Count>4</Count>
        </Address>
        <DateOfBirth>
          <Count>1</Count>
        </DateOfBirth>
        <Alerts>
          <Count>0</Count>
        </Alerts>
      </KYCSummary>
      <ReportSummary>
        <DatablocksSummary>
          <DatablockSummary>
            <Name>Deceased</Name>
            <Decision />
          </DatablockSummary>
          <DatablockSummary>
            <Name>CreditReference</Name>
            <Decision>1</Decision>
          </DatablockSummary>
          <DatablockSummary>
            <Name>Telephony</Name>
            <Decision>-1</Decision>
          </DatablockSummary>
          <DatablockSummary>
            <Name>Fraud</Name>
            <Decision />
          </DatablockSummary>
          <DatablockSummary>
            <Name>Directors</Name>
            <Decision />
          </DatablockSummary>
          <DatablockSummary>
            <Name>ElectoralRoll</Name>
            <Decision />
          </DatablockSummary>
        </DatablocksSummary>
      </ReportSummary>
    </Summary>
    <Deceased Type="NoMatch" />
    <CreditReference Type="Result">
      <Summary>
        <Decision>1</Decision>
        <DecisionReasons>
          <DecisionReason>
            <Element>CreditReferenceSummary/TotalNumberOfVerifications</Element>
            <Decision>1</Decision>
          </DecisionReason>
          <DecisionReason>
            <Element>CreditReferenceSummary/OpenAccountsMatch</Element>
            <Decision>1</Decision>
          </DecisionReason>
          <DecisionReason>
            <Element>CreditReferenceSummary/DateOfBirthMatch</Element>
            <Decision>1</Decision>
          </DecisionReason>
          <DecisionReason>
            <Element>CreditReferenceSummary/ElectoralRollMatch</Element>
            <Decision>-1</Decision>
          </DecisionReason>
          <DecisionReason>
            <Element>CreditReferenceSummary/ElectoralRollDateOfBirthMatch</Element>
            <Decision>-1</Decision>
          </DecisionReason>
          <DecisionReason>
            <Element>CreditReferenceSummary/TelephoneDirectoryMatch</Element>
            <Decision>-1</Decision>
          </DecisionReason>
          <DecisionReason>
            <Element>CreditReferenceSummary/PhoneNumberMatch</Element>
            <Decision>-1</Decision>
          </DecisionReason>
          <DecisionReason>
            <Element>CreditReferenceSummary/BOEMatch</Element>
            <Decision>-1</Decision>
          </DecisionReason>
          <DecisionReason>
            <Element>CreditReferenceSummary/PEPMatch</Element>
            <Decision>-1</Decision>
          </DecisionReason>
          <DecisionReason>
            <Element>CreditReferenceSummary/OFACMatch</Element>
            <Decision>-1</Decision>
          </DecisionReason>
          <DecisionReason>
            <Element>CreditReferenceSummary/DeceasedMatch</Element>
            <Decision>-1</Decision>
          </DecisionReason>
          <DecisionReason>
            <Element>CreditReferenceSummary/COAMatch</Element>
            <Decision>-1</Decision>
          </DecisionReason>
          <DecisionReason>
            <Element>CreditReferenceSummary/CIFASMatch</Element>
            <Decision>-1</Decision>
          </DecisionReason>
          <DecisionReason>
            <Element>CreditReferenceSummary/NoOfCCJ</Element>
            <Decision>-1</Decision>
          </DecisionReason>
          <DecisionReason>
            <Element>CreditReferenceSummary/NoOfOpenAccountsLenders</Element>
            <Decision>1</Decision>
          </DecisionReason>
        </DecisionReasons>
      </Summary>
      <CreditReferenceSummary>
        <CreditReferenceDecision />
        <CreditReferenceScore />
        <TotalNumberOfVerifications>3</TotalNumberOfVerifications>
        <OpenAccountsMatch>1</OpenAccountsMatch>
        <DateOfBirthMatch>1</DateOfBirthMatch>
        <ElectoralRollMatch>0</ElectoralRollMatch>
        <ElectoralRollDateOfBirthMatch>0</ElectoralRollDateOfBirthMatch>
        <TelephoneDirectoryMatch>0</TelephoneDirectoryMatch>
        <PhoneNumberMatch>0</PhoneNumberMatch>
        <DriverLicenceMatch />
        <PassportMatch />
        <DFATMatch />
        <BOEMatch>0</BOEMatch>
        <PEPMatch>0</PEPMatch>
        <OFACMatch>0</OFACMatch>
        <DeceasedMatch>0</DeceasedMatch>
        <COAMatch>0</COAMatch>
        <CIFASMatch>0</CIFASMatch>
        <GoneAwayMatch />
        <HighRiskAddressMatch />
        <CommercialEntitiesAtAddressMatch />
        <NoOfCommercialEntitiesAtAddress />
        <NoOfCCJ>0</NoOfCCJ>
        <NoOfOpenAccountsLenders>2</NoOfOpenAccountsLenders>
        <IDVerified />
      </CreditReferenceSummary>
      <CreditReferenceDetails>
        <StandardisedAddress Current="1">
          <SubPremise />
          <Premise>TORWOOD</Premise>
          <Street>THE WOODEND</Street>
          <PostTown>WALLINGTON</PostTown>
          <Locality />
          <Region>SURREY</Region>
          <Postcode>SM6 0RA</Postcode>
          <CountryCode>GBR</CountryCode>
        </StandardisedAddress>
      </CreditReferenceDetails>
    </CreditReference>
    <Telephony Type="Result">
      <Summary>
        <Decision>-1</Decision>
        <DecisionReasons>
          <DecisionReason>
            <Element>TelephonyRecord/Person/Name/Forename</Element>
            <Decision>1</Decision>
          </DecisionReason>
          <DecisionReason>
            <Element>TelephonyRecord/Person/Name/Surname</Element>
            <Decision>1</Decision>
          </DecisionReason>
          <DecisionReason>
            <Element>TelephonyRecord/Address/Premise</Element>
            <Decision>1</Decision>
          </DecisionReason>
          <DecisionReason>
            <Element>TelephonyRecord/Address/Postcode</Element>
            <Decision>1</Decision>
          </DecisionReason>
          <DecisionReason>
            <Element>TelephonyRecord/Address/CountryCode</Element>
            <Decision>1</Decision>
          </DecisionReason>
          <DecisionReason>
            <Element>TelephonyRecord/Telephones/Telephone/Number</Element>
            <Decision>-1</Decision>
          </DecisionReason>
        </DecisionReasons>
      </Summary>
      <TelephonyRecord>
        <Person>
          <Name>
            <Title>MR</Title>
            <Forename>XXX</Forename>
            <OtherNames>D</OtherNames>
            <Surname>GGGG</Surname>
          </Name>
        </Person>
        <Address Current="1">
          <SubPremise />
          <Premise>TORWOOD</Premise>
          <SubStreet />
          <Street>STREET</Street>
          <SubLocality />
          <Locality />
          <PostTown />
          <Region>SSSSS</Region>
          <Postcode>SM6 0RA</Postcode>
          <CountryCode>GBR</CountryCode>
        </Address>
        <Telephones>
          <Telephone Type="U">
            <Number>020 7777 7777</Number>
            <CustomerType>R</CustomerType>
            <ListingType>DQ</ListingType>
          </Telephone>
        </Telephones>
      </TelephonyRecord>
    </Telephony>
    <Fraud Type="Provisional" />
    <Directors Type="NoMatch" />
    <ElectoralRoll Type="NoMatch" />
  </Result>
</Search>
EOD
        return $xml;
    }

    1;

}

my $som = SOM->new;
$module->mock(search => $som);

my $prove_id = Experian::IDAuth->new(
    client_id     => '45',
    search_option => 'CheckID',
    username      => 'my_user',
    password      => 'my_pass',
    residence     => 'gb',
    postcode      => '666',
    date_of_birth => '1977-04-10',
    first_name    => 'John',
    last_name     => 'Galt',
    phone         => '34878123',
    email         => 'john.galt@gmail.com',
    premise       => 'premise',
);

warning_like(
    sub {
        my $prove_id_result = $prove_id->get_result();
        my $xml_report      = $prove_id->get_192_xml_report();

        ok($xml_report eq $xml, 'get_192_xml_report');
    },
    qr/not a pdf/,
    'bad pdf warning'
);
Test::NoWarnings::had_no_warnings();
done_testing;

