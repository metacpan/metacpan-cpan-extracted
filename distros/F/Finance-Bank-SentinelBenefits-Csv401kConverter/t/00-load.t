use Test::More tests => 10;
use lib './lib';


BEGIN {
#http://blogs.perl.org/users/ovid/2010/02/tracking-down-bug-reports.html
    local $^W;
    use_ok('Finance::Bank::SentinelBenefits::Csv401kConverter')
      or BAIL_OUT("Cannot load Finance::Bank::SentinelBenefits::Csv401kConverter");

    diag(
	 "Testing Finance::Bank::SentinelBenefits::Csv401kConverter $Finance::Bank::SentinelBenefits::Csv401kConverter::VERSION, Perl $], $^X"
	);

    my @dependencies = qw(
      Modern::Perl
      Finance::QIF
      DateTime
      Moose
      MooseX::Method::Signatures
      MooseX::StrictConstructor
      Scalar::Util
      Moose::Util::TypeConstraints
      DateTime::Format::Flexible
    );
    foreach my $module (@dependencies) {
        use_ok $module or BAIL_OUT("Cannot load $module");
        my $version = $module->VERSION;
        diag("    $module version is $version");
    }
}

# Copyright 2009-2011 David Solimano
# This file is part of Finance::Bank::SentinelBenefits::Csv401kConverter

# Finance::Bank::SentinelBenefits::Csv401kConverter is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# Finance::Bank::SentinelBenefits::Csv401kConverter is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with Finance::Bank::SentinelBenefits::Csv401kConverter.  If not, see <http://www.gnu.org/licenses/>.

