# Copyright 2012, Google Inc. All Rights Reserved.
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
# Custom class generator based on SOAP::WSDL::Generator::Template::XSD, with
# some overriden methods via inheritance.

package Google::Ads::SOAP::Generator::Generator;

use strict;
use warnings;
use base qw(SOAP::WSDL::Generator::Template::XSD);

use Google::Ads::SOAP::Generator::TypemapVisitor;

use Class::Std::Fast::Storable;
use Cwd 'abs_path';
use File::Basename;
use File::Spec;

sub BUILD {
  my ($self, $ident, $arg_ref) = @_;

  $self->set_INCLUDE_PATH(
    $self->_get_local_include_path() . q{:} . $self->get_INCLUDE_PATH());
}

sub _get_local_include_path {

  my $template_path =
    File::Spec->catdir(File::Spec->rel2abs(dirname(__FILE__)), "Template");
  return abs_path($template_path);
}

sub generate_filename {
  my ($self, $name) = @_;

  $name =~ s{ \. }{::}xmsg;
  $name =~ s{ \- }{_}xmsg;
  $name =~ s{ :: }{/}xmsg;
  return "$name.pm";
}

sub visit_XSD_ComplexType {
  my ($self, $type) = @_;

  my $output =
    defined $SOAP::WSDL::Generator::Template::XSD::output_of{ident $self}
    ? $SOAP::WSDL::Generator::Template::XSD::output_of{ident $self}
    : $self->generate_filename(
    $self->get_name_resolver()->create_xsd_name($type));
  warn "Creating complexType class $output \n" if not $self->get_silent();
  $self->_process('complexType.tt', {complexType => $type, NO_POD => 1},
    $output);
}

sub generate_typemap {
  my ($self, $arg_ref) = @_;
  my $visitor = Google::Ads::SOAP::Generator::TypemapVisitor->new({
      type_prefix    => $self->get_type_prefix(),
      element_prefix => $self->get_element_prefix(),
      definitions    => $self->get_definitions(),
      typemap        => {
        'Fault'             => 'SOAP::WSDL::SOAP::Typelib::Fault11',
        'Fault/faultcode'   => 'SOAP::WSDL::XSD::Typelib::Builtin::anyURI',
        'Fault/faultactor'  => 'SOAP::WSDL::XSD::Typelib::Builtin::token',
        'Fault/faultstring' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        # PATCH Map our own FaultDetail object.
        'Fault/detail' => 'Google::Ads::AdWords::FaultDetail',
        # END OF PATCH.
      },
      resolver => $self->get_name_resolver(),
    });

  use SOAP::WSDL::Generator::Iterator::WSDL11;
  my $iterator = SOAP::WSDL::Generator::Iterator::WSDL11->new(
    {definitions => $self->get_definitions});

  for my $service (@{$self->get_definitions->get_service}) {
    $iterator->init({node => $service});
    while (my $node = $iterator->get_next()) {
      $node->_accept($visitor);
    }

    my $output =
        $arg_ref->{output}
      ? $arg_ref->{output}
      : $self->generate_filename(
      $self->get_name_resolver()->create_typemap_name($service));
    print "Creating typemap class $output\n" if not $self->get_silent();
    $self->_process(
      'Typemap.tt',
      {
        service => $service,
        typemap => $visitor->get_typemap(),
        NO_POD  => 1,
      },
      $output
    );
  }
}

return 1;
