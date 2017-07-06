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
# Custom MessageParser based on SOAP::WSDL::Expat::MessageParser, with some
# overriden methods via inheritance.

package Google::Ads::SOAP::Deserializer::MessageParser;

use strict;
use warnings;
use base qw(SOAP::WSDL::Expat::MessageParser);

use Google::Ads::Common::XPathSAXParser;

use Carp;
use Scalar::Util qw(blessed);
use SOAP::WSDL::Expat::Base;
use SOAP::WSDL::Expat::MessageParser;
use SOAP::WSDL::XSD::Typelib::ComplexType;

# PATCH Overriding the SAX Parser initialization to use ours.
sub parse_string {
  my $xml    = $_[1];
  my $parser = $_[0]->_initialize(Google::Ads::Common::XPathSAXParser->new());
  eval { $parser->parse($xml); };
  croak($@) if $@;
  delete $_[0]->{parser};
  return $_[0]->{data};
}
# END PATCH

sub _initialize {
  my ($self, $parser) = @_;

  # Removing potential old results.
  delete $self->{data};
  delete $self->{header};
  my $characters;
  my $current = undef;

  # Setting up variables for depth-first tree traversal.
  my $list  = [];
  my $path  = [];
  my $skip  = 0;
  my $depth = 0;

  # Executing sanity checks of main SOAP response headers.
  my %content_check = $self->{strict}
    ? (
    0 => sub {
      die "Bad top node $_[1]" if $_[1] ne "Envelope";
      die "Bad namespace for SOAP envelope: " . $_[0]->recognized_string()
        if $_[0]->namespace() ne "http://schemas.xmlsoap.org/soap/envelope/";
      $depth++;
      return;
    },
    1 => sub {
      $depth++;
      if ($_[1] eq "Body") {
        if (exists $self->{data}) {
          $self->{header} = $self->{data};
          delete $self->{data};
          $list = [];
          $path = [];
          undef $current;
        }
      }
      return;
    })
    : (
    0 => sub {
      $depth++;
    },
    1 => sub {
      $depth++;
    });

  # Using "globals" for speed.
  # PATCH Added global variables to check if a method package exists at
  # runtime.
  my ($_prefix, $_add_method, $_add_method_package, $_set_method,
    $_set_method_package, $_class, $_leaf)
    = ();
  # END OF PATCH
  my $char_handler = sub {
    # Returning if not a leaf.
    return if (!$_leaf);
    $characters .= $_[1];
    return;
  };
  $parser->set_handlers({
      Start => sub {
        # PATCH Added more input coming from the SAX parser
        my ($parser, $element, $attrs, $node) = @_;
        # END PATCH

        $_leaf = 1;

        return &{$content_check{$depth}} if exists $content_check{$depth};

        # Resolving class of this element.
        my $typemap = $self->{class_resolver}->get_typemap();
        my $name    = "";

        # PATCH Checking if the xsi:type attribute is set hence generating a
        # different path to look in the typemap.
        if (not $attrs->{"type"}) {
          $name = $_[1];
        } else {
          my $attr_type = $attrs->{"type"};
          $attr_type =~ s/(.*:)?(.*)/$2/;
          $name = $_[1] . "[$attr_type]";
        }
        # END PATCH

        # Adding one more entry to the path
        push @{$path}, $name;

        # Skipping the element if is marked __SKIP__.
        return if $skip;

        $_class = $typemap->{join("/", @{$path})};

        if (!defined($_class) and $self->{strict}) {
          die "Cannot resolve class for " . $name . " path " .
            join("/", @{$path}) . " via " . $self->{class_resolver};
        }
        if (!defined($_class) or ($_class eq "__SKIP__")) {
          $skip = join("/", @{$path});
          $_[0]->setHandlers(Char => undef);
          return;
        }

        # Stepping down, adding $current to the list element of the current
        # branch being visited.
        push @$list, $current;

        # Cleaning up current. Mainly to help profilers find the real hot spots.
        undef $current;

        $characters = q{};

        no warnings "once";
        $current =
          pop @{$SOAP::WSDL::Expat::MessageParser::OBJECT_CACHE_REF->{$_class}};
        if (not defined $current) {
          my $o = Class::Std::Fast::ID();
          $current = bless \$o, $_class;
        }

        # PATCH Creating a double link between the SOAP Object and the parser
        # node, so it can be later use for XPath searches.
        Google::Ads::Common::XPathSAXParser::link_object_to_node($current,
          $node);
        # END PATCH

        # Setting attributes if there are any.
        if ($attrs && $current->can("attr")) {
          $current->attr($attrs);
        }
        $depth++;
        return;
      },
      Char => $char_handler,
      End  => sub {
        # End of the element stepping up in the current branch path.
        pop @{$path};

        # Checking if element need to be skipped __SKIP__.
        if ($skip) {
          return if $skip ne join "/", @{$path}, $_[1];
          $skip = 0;
          $_[0]->setHandlers(Char => $char_handler);
          return;
        }
        $depth--;

        # Setting character values only if a leaf.
        if ($_leaf) {
          $SOAP::WSDL::XSD::Typelib::Builtin::anySimpleType::___value->
            {$$current} = $characters
            if defined $characters && defined $current;
        }

        $characters = q{};
        $_leaf      = 0;

        # Finishing if at the top of the tree of elements, no more parents.
        if (not defined $list->[-1]) {
          $self->{data} = $current if (not exists $self->{data});
          return;
        }

        # Method to be called in the parent to add the current object to it.
        $_add_method = "add_$_[1]";

        # Fixing up XML names for Perl names.
        $_add_method =~ s{\.}{__}xg;
        $_add_method =~ s{\-}{_}xg;

        # PATCH Adding the element if the method to add is defined in the
        # parent.
        eval('use ' . ref($list->[-1]));
        eval { $list->[-1]->$_add_method($current); };
        if ($@) {
          warn("Couldn't find a setter $_add_method for object of type " .
              ref($current) . " in object of type " .
              ref($list->[-1]) . " method " . $_add_method);
        }
        # END PATCH

        #Stepping up in the current object hierarchy.
        $current = pop @$list;
        return;
        }
    });
  return $parser;
}

return 1;
