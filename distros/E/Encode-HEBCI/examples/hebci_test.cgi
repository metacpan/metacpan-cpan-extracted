#!/usr/bin/perl -w

use strict;
use Encode;
use Encode::Alias;
use Encode::Byte;
use Encode::CN;
use Encode::JP;
use Encode::KR;
use Encode::TW;
use Encode::Unicode;
use CGI qw/:standard/;

use Encode::HEBCI;

print "Content-Type: text/html; charset=utf-8\r\n\r\n";


#####################
# General setup steps

# Create our HEBCI handle
my $hebci = new Encode::HEBCI();

# Get a list of supported encodings, all upper-case
my @available_encodings = map { uc($_) } Encode->encodings(":all");

# Get the list of entities we should pass on
my @ents = ($hebci->supported_entities())[0..4];

# Create a set of hidden form inputs to include below
my @form_elems_a = 
  map { "<input type=\"hidden\" name=\"_fp_${_}\" value=\"\&${_};\"/>" } @ents;
my $form_elements = join("\n", @form_elems_a);

#############################
# Get fingerprint information
our %fp_vals;
foreach my $ent (@ents) {
  my $c = param("_fp_${ent}");
  my $ch = unpack("H*", $c) if(defined($c));
  print "<!-- $ent : $ch -->\n" if(defined($c));
  $fp_vals{$ent} = $c if(defined($c));
}
#####################
# Run the fingerprint

my @possible_encodings = map { uc($_) } $hebci->fingerprint(\%fp_vals);

print "<!-- available encodings: @available_encodings -->\n";
print "<!-- possible encodings: @possible_encodings -->\n";

# Default encoding to use...
my $encoding = "ISO-8859-1";

# If we get more than one encoding... take the first one.
#
#  You might want to keep a list of encodings in order of decreasing
#  probability, and see if each is in there; if so, use that one.
#
if(scalar(@possible_encodings) > 0) {
  $encoding = $possible_encodings[0];
}

# A flag for: "current encoding is supported"
my $encoding_is_supported = 0;

foreach my $enc (@available_encodings) {
  if($enc eq $encoding) {
    $encoding_is_supported = 1;
  }
}

if(!$encoding_is_supported) {
  print "<!-- OH BURN!  Your encoding ($encoding) isn't supported here! -->\n";
  $encoding = "ISO-8859-1";
}


#################################
# Get the user input to translate
my $str = param("str") || "";
$str =~ s/</&lt;/g; # Dirty kludge

# Copy of the input for the input value attribute
my $valstr = ($str ? $str : "sch&ouml;n");
$valstr =~ s/"/&quot;/g;
my $outstr = "";

if(defined($encoding)) {
  my $tmpstr = decode($encoding, $str);
  $outstr = encode("UTF-8", $tmpstr);
}


print <<EOT;

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
<title>Stupid Character Encoding Trick: Inferring Codepage</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
</head>
<body>
Results: You're using the encoding "$encoding" !! (but this page is in UTF-8)<br/>
You gave me: $str <br/>
in UTF-8: $outstr <br/>
<form method="GET" ACTION="hebci_test.cgi">
String to print: <input type="text" name="str" value="$valstr" />
$form_elements
<input type="submit" value="Check my codepage">
</form>
</body>
</html>

EOT
