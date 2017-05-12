#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 51;

# The versions of the following packages are reported to help understanding
# the environment in which the tests are run.  This is certainly not a
# full list of all installed modules.
my @show_versions =
 qw/Mail::Box
    Mail::Box::Manager
    Mail::Transfer
   /;

foreach my $package (@show_versions)
{   eval "require $package";

    no strict 'refs';
    my $report
      = !$@    ? "version ". (${"$package\::VERSION"} || 'unknown')
      : $@ =~ m/^Can't locate/ ? "not installed"
      : "reports error";

    warn "$package $report\n";
}

require_ok('Mail::Box::FastScalar');
require_ok('Mail::Box::Parser');
require_ok('Mail::Box::Parser::Perl');
require_ok('Mail::Message::Body::Construct');
require_ok('Mail::Message::Body::Encode');
require_ok('Mail::Message::Body::File');
require_ok('Mail::Message::Body::Lines');
require_ok('Mail::Message::Body::Multipart');
require_ok('Mail::Message::Body::Nested');
require_ok('Mail::Message::Body');
require_ok('Mail::Message::Body::String');
require_ok('Mail::Message::Construct::Bounce');
require_ok('Mail::Message::Construct::Build');
require_ok('Mail::Message::Construct::Forward');
require_ok('Mail::Message::Construct');
require_ok('Mail::Message::Construct::Read');
require_ok('Mail::Message::Construct::Rebuild');
require_ok('Mail::Message::Construct::Reply');
require_ok('Mail::Message::Construct::Text');
require_ok('Mail::Message::Convert');
require_ok('Mail::Message::Field::Addresses');
require_ok('Mail::Message::Field::Address');
require_ok('Mail::Message::Field::AddrGroup');
require_ok('Mail::Message::Field::Attribute');
require_ok('Mail::Message::Field::Date');
require_ok('Mail::Message::Field::Fast');
require_ok('Mail::Message::Field::Flex');
require_ok('Mail::Message::Field::Full');
require_ok('Mail::Message::Field');
require_ok('Mail::Message::Field::Structured');
require_ok('Mail::Message::Field::Unstructured');
require_ok('Mail::Message::Field::URIs');
require_ok('Mail::Message::Head::Complete');
require_ok('Mail::Message::Head::FieldGroup');
require_ok('Mail::Message::Head::ListGroup');
require_ok('Mail::Message::Head::Partial');
require_ok('Mail::Message::Head');
require_ok('Mail::Message::Head::ResentGroup');
require_ok('Mail::Message::Head::SpamGroup');
require_ok('Mail::Message::Part');
require_ok('Mail::Message');
require_ok('Mail::Message::Replace::MailHeader');
require_ok('Mail::Message::Replace::MailInternet');
require_ok('Mail::Message::Test');
require_ok('Mail::Message::TransferEnc::Base64');
require_ok('Mail::Message::TransferEnc::Binary');
require_ok('Mail::Message::TransferEnc::EightBit');
require_ok('Mail::Message::TransferEnc');
require_ok('Mail::Message::TransferEnc::QuotedPrint');
require_ok('Mail::Message::TransferEnc::SevenBit');
require_ok('Mail::Reporter');

# The following modules only compile when optional modules are installed
#require_ok('Mail::Message::Convert::EmailSimple');
#require_ok('Mail::Message::Convert::HtmlFormatPS');
#require_ok('Mail::Message::Convert::HtmlFormatText');
#require_ok('Mail::Message::Convert::Html');
#require_ok('Mail::Message::Convert::MailInternet');
#require_ok('Mail::Message::Convert::MimeEntity');
#require_ok('Mail::Message::Convert::TextAutoformat');
