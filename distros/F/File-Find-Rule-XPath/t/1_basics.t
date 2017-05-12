# $Id: 1_basics.t,v 1.1.1.1 2002/12/18 09:21:18 grantm Exp $
# vim: syntax=perl

use strict;
use Test::More;
use File::Spec;

my $have_xpath = 0;

if(eval { require XML::XPath; }) {
  $have_xpath++;
}

if(eval { require XML::LibXML; }) {
  $have_xpath++;
}

unless($have_xpath) {
  plan skip_all => 'no XPath module available';
}

plan tests => 8;

# Confirm the module compiles

use File::Find::Rule::XPath;

ok(1, "module compiled ok");


##############################################################################
# Simple XPath expression to find all documents with a <quote> element
# (there should be only one).
#

my $root = 't';
my $files;

$files = norm(File::Find::Rule->file->xpath( '//quote' )->in($root));

is($files, 't/testdata/quote.xml', "matched //quote");


##############################################################################
# Find all well-formed XML documents.
#

$files = norm(File::Find::Rule->file->xpath( '/' )->in($root));

is($files, 't/testdata/hello.xml t/testdata/quote.xml',
  "matched /");


##############################################################################
# Same again, but using default value for path expression.
#

$files = norm(File::Find::Rule->file->xpath()->in($root));

is($files, 't/testdata/hello.xml t/testdata/quote.xml',
  "matched default pattern");


##############################################################################
# Look for a particular string of text (anywhere).
#

$files = norm(File::Find::Rule->file
              ->xpath( '//*[contains(., "Hello World!")]' )->in($root));

is($files, 't/testdata/hello.xml t/testdata/quote.xml',
  qq(matched //*[contains(., "Hello World!")]));


##############################################################################
# Look for a particular string of text in a particular tag.
#

$files = norm(File::Find::Rule->file
              ->xpath( '//greeting[contains(., "Hello World!")]' )->in($root));

is($files, 't/testdata/hello.xml',
  qq(matched //greeting[contains(., "Hello World!")]));


##############################################################################
# Try the same match again but start search with absolute pathname
#

my $absroot = File::Spec->rel2abs($root);
$files = norm(File::Find::Rule->file
              ->xpath( '//greeting[contains(., "Hello World!")]' )
              ->in($absroot));

like($files, qr{^.*t/testdata/hello\.xml$},
  qq(same search from absolute root matched));


##############################################################################
# Now try the search using the procedural interface
#

$files = norm(
           find( file  =>
                 xpath => '//greeting[contains(., "Hello World!")]',
                 in    => $root
           )
         );

is($files, 't/testdata/hello.xml',
  qq(same search matched using procedural interface));

exit;



##############################################################################
# Take a list of pathnames, sort them, convert the path separators to '/'
# and return as a space delimited string.
#

sub norm {
  return join ' ',  map { join '/', split /[^\w\.]+/ } sort @_;
}

