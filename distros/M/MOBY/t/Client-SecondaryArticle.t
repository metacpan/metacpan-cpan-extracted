# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

# Note added by Frank Gibbons.
# Tests should, as far as possible, avoid the use of literals.
# If you register a service with authURI => mysite.com,
# and you want to test a retrieved description of the service,
# don't test that the service returns authURI eq "mysite.com",
# test so that it returns the same value as you used to register it in the first place.

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
#use SOAP::Lite +trace;
use Test::More 'no_plan'; # perldoc Test::More for details
use strict;
use English;
use Data::Dumper;
use MOBY::Client::SecondaryArticle;
#Is the client-code even installed?
BEGIN { use_ok('MOBY::Client::SecondaryArticle') };
 
END {
  # Clean up after yourself, in case tests fail, or the interpreter is interrupted partway though...
};

my @autoload = qw/articleName objectType namespaces 
  XML XML_DOM isSimple isCollection isSecondary
 datatype default max min enum value description/;
my @API = (@autoload, qw/new /); # createFrom[XML|DOM] are not meant to be public

my $scndry = MOBY::Client::SecondaryArticle->new();
foreach (@autoload) {eval{$scndry->$_};} # Call all AUTOLOAD methods, to create them.
can_ok("MOBY::Client::SecondaryArticle", @API)
  or diag("SecondaryArticle doesn't implement full API");

#my $scndry = MOBY::Client::SecondaryArticle->new();
is($scndry->isSimple, 0)     or diag("SecondaryArticle cannot be Simple");
is($scndry->isSecondary, 1)  or diag("SecondaryArticle must return isSecondary=1");
is($scndry->isCollection, 0) or diag("SecondaryArticle cannot be Collection");

my $aName = 'my Article';
is($scndry->articleName($aName), $aName) or diag("Couldn't set articleName");
is($scndry->articleName(), $aName) or diag("Couldn't get articleName");

my $obj_type = 'String';
is($scndry->objectType($obj_type), $obj_type) or diag("Couldn't set objectType");
is($scndry->objectType(), $obj_type) or diag("Couldn't get objectType");

my @ns = qw/SGD FB GO/;
eq_array($scndry->namespaces(\@ns), \@ns) or diag("Couldn't set namespaces");
eq_array($scndry->namespaces(), \@ns) or diag("Couldn't get namespaces");


my @datatypes = qw/Integer Float String DateTime Boolean/;
foreach (@datatypes) {  # Correct stuff should be possible
  is($scndry->datatype($_), $_) or diag("Couldn't set datatype to '$_'");
  is($scndry->datatype(), $_) or diag("Couldn't get datatype to '$_'");
}

my @enums = (-100, -50, 0, 10, 50, 100);
eq_array($scndry->enum(\@enums), \@enums) or diag("Couldn't set enumerated values");
eq_array($scndry->enum(), \@enums) or diag("Couldn't get enumerated values");
# Check XML-generation code.
# In reality, (XML, createFromXML) and (XML_DOM, createFromDOM) should behave the same.
# Let's not assume that though.

my ($artName, $ns, $id, $value) = ('my Article', 'SGD', 'S0005111', 10);
my $xml_scndry = <<XML;
<Parameter articleName='$artName'>
<Value>$value</Value>
</Parameter>
XML

$scndry = MOBY::Client::SecondaryArticle->new( XML => $xml_scndry);
is($scndry->articleName(), $artName)
  or diag("SecondaryArticle not correctly built from XML (articleName wrong)");
is($scndry->value(), $value) 
  or diag("SecondaryArticle not correctly built from XML (value wrong)");


# Now test parsing of template parameter.
# This doesn't hold actual data, it's the template that's used in service registration.
# The content is quite different.

sub maxval { # Return maximum value in array(ref)
  my @arr = ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_;
  my $maxval = 0;
  foreach (@arr) { ($maxval < $_) and $maxval = $_ }
  return $maxval;
}

sub minval { # Return minimum value in array(ref)
  my @arr = ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_;
  my $minval = 0;
  foreach (@arr) { ($minval > $_) and $minval = $_ }
  return $minval;
}


my ($maxval, $minval, $default, $obj, $desc) = (maxval(@enums), minval(@enums), -50, "Integer", "some input integer");
my $xml_tmplt = <<XML;
<Parameter articleName="$artName">
<datatype>$obj</datatype>
<description>$desc</description>
<default>$default</default>
<max>$maxval</max> 
<min>$minval</min> 
XML

foreach (@enums) { $xml_tmplt .= "<enum>$_</enum>" }
$xml_tmplt .= "</Parameter>";
$scndry = MOBY::Client::SecondaryArticle->new( XML => $xml_tmplt);

is($scndry->max, $maxval) 
  or diag("SecondaryArticle not correctly built from XML (max wrong)");
is($scndry->min(), $minval) 
  or diag("SecondaryArticle not correctly built from XML (min wrong)");
is($scndry->description(), $desc) 
  or diag("SecondaryArticle not correctly built from XML (description wrong)");
is($scndry->default(), $default) 
  or diag("SecondaryArticle not correctly built from XML (default wrong)");
eq_array($scndry->enum(), \@enums) 
  or diag("SecondaryArticle not correctly built from XML (enums wrong: " 
	  . @{$scndry->enum()} . ")");


sub XML_maker { # Turn XML text into DOM.
  my $XML = shift;
  my $parser = XML::LibXML->new();
  my $doc;
  eval { $doc = $parser->parse_string( $XML ); };
  return '' if ( $EVAL_ERROR ); #("Couldn't parse '$XML' because:\n\t$EVAL_ERROR") 
  return $doc->getDocumentElement();
}


# Now test XML_DOM argument, first with (abstract) template parameter,
# then with (real) instantiated parameter
$scndry = MOBY::Client::SecondaryArticle->new( XML_DOM => XML_maker($xml_scndry));

is($scndry->articleName(), $artName)
  or diag("SecondaryArticle not correctly built from XML_DOM (articleName wrong)");
is($scndry->value(), $value) 
  or diag("SecondaryArticle not correctly built from XML (value wrong)");

$scndry = MOBY::Client::SecondaryArticle->new( XML_DOM => XML_maker($xml_tmplt));
is($scndry->max, $maxval) 
  or diag("SecondaryArticle not correctly built from XML_DOM (max wrong)");
is($scndry->min(), $minval) 
  or diag("SecondaryArticle not correctly built from XML_DOM (min wrong)");
is($scndry->default(), $default) 
  or diag("SecondaryArticle not correctly built from XML_DOM (default wrong)");
eq_array($scndry->enum(), \@enums) 
  or diag("SecondaryArticle not correctly built from XML_DOM (enums wrong: " 
	  . @{$scndry->enum()} . ")");


TODO: {
  local $TODO = <<TODO;
When I call SecondaryArticle->new()->XML(\$xml), 
I expect that the XML will be *parsed*, to modify the object, 
not that the attribute 'XML' will be set, and the rest left unchanged."
TODO

  $scndry = MOBY::Client::SecondaryArticle->new();
  $scndry->XML($xml_scndry);
  is($scndry->articleName, $artName) 
    or diag("Couldn't create SecondaryArticle from autoloaded method XML(): articleName wrong");

  is($scndry->objectType(), $obj) 
    or diag("Couldn't create SecondaryArticle from autoloaded method XML(): objectType wrong");

#  eq_array($scndry->namespaces(), [$ns])
#    or diag("Couldn't create SecondaryArticle from autoloaded method XML(): namespaces wrong");


}
