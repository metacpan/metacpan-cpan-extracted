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

package Google::Ads::AdWords::FaultDetail;

use strict;
use warnings;
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

# The following needs to be on one line because CPAN uses a particularly hacky
# eval() to determine module versions.
use Google::Ads::AdWords::Constants; our $VERSION = ${Google::Ads::AdWords::Constants::VERSION};

use Class::Std::Fast::Storable constructor => 'none';

__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'http://schemas.xmlsoap.org/soap/envelope/' }

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
  return $XML_ATTRIBUTE_CLASS;
}

sub AUTOMETHOD {
  my ($self, $ident) = @_;
  my $method_name = $_;

  # Storing any exception into ApiExceptionFault property.
  if ($method_name =~ /^(set_|add_)\w+$/) {
    return sub {
      my ($self, $exception) = @_;
      $self->set_ApiExceptionFault($exception);
    };
  }
  # Retrieving any exception from the ApiExceptionFault property.
  if ($method_name =~ /^(get_)\w+$/) {
    return sub {
      my ($self) = @_;
      $self->get_ApiExceptionFault();
    };
  }
}

{    # BLOCK to scope variables

  my %ApiExceptionFault_of : ATTR(:get<ApiExceptionFault>);

  __PACKAGE__->_factory(
    [qw(exception)],
    {'ApiExceptionFault' => \%ApiExceptionFault_of},
    {'ApiExceptionFault' => 'SOAP::WSDL::XSD::Typelib::ComplexType'},
    {'ApiExceptionFault' => 'ApiExceptionFault'});

}    # end BLOCK

1;

=pod

=head1 NAME

Google::Ads::AdWords::FaultDetail

=head1 SYNOPSIS

Class that wraps API exceptions and it is accesible through
C<SOAP::WSDL::SOAP::Typelib::Fault11->get_detail()>.

=head1 DESCRIPTION

This class holds full API exception objects.

=head1 ATTRIBUTES

=head2 exception

The API exception(s) object returned by the service.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Google Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 REPOSITORY INFORMATION

 $Rev: $
 $LastChangedBy: $
 $Id: $

=cut
