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

package TestUtils;

use strict;
use vars qw(@EXPORT_OK @ISA);

use Config::Properties;
use Exporter;
use File::Basename;
use File::Spec;

@ISA       = qw(Exporter);
@EXPORT_OK = qw(read_test_properties read_client_properties replace_properties);

sub __read_properties($) {
  my $serializer_props = $_[0];
  open(PROPS, "< $serializer_props") or die "Unable to read test properties.";
  my $properties = new Config::Properties();
  $properties->load(*PROPS);
  return $properties;
}

sub read_test_properties() {
  return __read_properties(
    File::Spec->catdir(dirname($0), qw(testdata test.properties)));
}

sub read_client_properties() {
  return __read_properties(
    File::Spec->catdir(dirname($0), qw(testdata client.properties)));
}

sub replace_properties($$) {
  my ($input, $properties) = @_;
  for my $key (keys(%{$properties})) {
    my $value = $properties->{$key};
    $input =~ s/\{$key\}/$value/g;
  }
  return $input;
}

return 1;
