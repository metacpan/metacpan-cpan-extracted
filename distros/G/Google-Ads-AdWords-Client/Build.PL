# Copyright 2011, Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Mobulde::Build build file. See
# http://search.cpan.org/~ewilhelm/Module-Build-0.32/lib/Module/Build.pm
# for explanation of format.

use Module::Build;

use strict;
use warnings;

use lib "lib";

my $build_sc = Module::Build->subclass(
    code => q(
      sub ACTION_testsmall {shift->generic_test(type => "small");}
      sub ACTION_testmedium {shift->generic_test(type => "medium");}
      sub ACTION_testnondeterministic {
        shift->generic_test(type => "nondeterministic");
      }
      sub ACTION_testfunctional {shift->generic_test(type => "functional");}
      sub ACTION_testsmoke {shift->generic_test(type => "smoke");}
    )
);

$build_sc->new(module_name => "Google::Ads::AdWords::Client",
               license => "apache",
               dist_author        => "Nadine Sundquist",
               create_makefile_pl => "traditional",
               dist_abstract      => "AdWords API Perl Client Library",
               dist_name          => "Google-Ads-AdWords-Client",
               dist_version       => "5.6.1",
               requires => {
                 "Class::Load" => 0,
                 "Class::Std::Fast" => 0,
                 "Crypt::OpenSSL::RSA" => 0,
                 "Cwd" => 0,
                 "Data::Uniqid" => 0,
                 "Date::Parse" => 0,
                 "Date::Format" => 0,
                 "Digest::SHA" => 0,
                 "File::Basename" => 0,
                 "File::HomeDir" => 0,
                 "File::Path" => 0,
                 "File::Spec" => 0,
                 "File::Temp" => 0,
                 "Getopt::Long" => 0,
                 "HTTP::Server::Simple::CGI" => 0,
                 "IO::Socket::SSL" => 0,
                 "JSON::Parse" => 0,
                 "List::Util" => 0,
                 "Log::Log4perl" => 0,
                 "LWP::Protocol::https" => 0,
                 "LWP::UserAgent" => 0,
                 "Math::Random::MT" => 0,
                 "POSIX" => 0,
                 "SOAP::WSDL" => "2.00.10",
                 "Template" => 0,
                 "URI::Escape" => 0,
                 "XML::Simple" => 0,
                 "XML::LibXML" => 0,
                 "XML::XPath" => 0,
                 "perl" => "5.14.0",
               },
               build_requires => {
                 "Class::Std::Fast" => q(0.0.5),
                 "Config::Properties" => 0,
                 "Module::Build" => 0,
                 "Test::Deep" => 0,
                 "Test::Exception" => 0,
                 "Test::MockObject" => 0,
                 "Test::MockObject::Extends" => 0,
                 "Test::More" => 0,
               },
               test_types => {
                 small => ["011_Client.t",
                           "012_Serialiazer.t",
                           "013_Deserializer.t",
                           "014_XPathSAXParser.t",
                           "015_RequestStats.t",
                           "017_OAuth2ApplicationsHandler.t",
                           "018_MapUtils.t",
                           "019_OAuth2ServiceAccountsHandler.t",
                           "020_GenerateOfflineCredentials.t",
                           "021_ReportingConfiguration.t",
                           "022_ReportUtils.t",
                           "023_AdsUtilityRegistry.t",
                           "024_BatchJobHandler.t",
                           "025_ReportQueryBuilder.t",
                           "026_ServiceQueryBuilder.t"],
                 medium => ["001_require.t"],
                 nondeterministic => [".ft"],
                 functional => [".ft"],
                 smoke => [".t"],
               })->create_build_script();
