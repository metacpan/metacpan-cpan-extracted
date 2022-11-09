#!/usr/bin/perl
use strict;
use warnings;

use Test::Most;
use Test::Warnings;
use Path::Tiny;

use Experian::IDAuth;

my $tmp_dir = Path::Tiny->tempdir(CLEANUP => 1);

my $proveid = Experian::IDAuth->new(
    client        => {},
    search_option => 'ProveID_KYC',
    folder        => $tmp_dir,
);

my $xml = <<EOD;
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

my $h = $proveid->set(result_as_xml => $xml)->_xml_as_hash;

my $num_keys = 10;
ok(scalar keys %$h == $num_keys, 'num keys of hashref');

my $person_age = 52;
ok($h->{Person}{Age} eq '52', 'person age');

done_testing;

