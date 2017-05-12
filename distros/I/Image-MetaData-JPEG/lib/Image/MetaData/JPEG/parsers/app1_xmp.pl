###########################################################
# A Perl package for showing/modifying JPEG (meta)data.   #
# Copyright (C) 2004,2005,2006 Stefano Bettelli           #
# See the COPYING and LICENSE files for license terms.    #
###########################################################
use Image::MetaData::JPEG::data::Tables qw(:TagsAPP1_XMP);
no  integer;
use strict;
use warnings;

###########################################################
# This method is the entry point for APP1 XMP segments.   #
# Such APP1 segments are used by Adobe for recording an   #
# XMP packet in JPEG files (this is a special XML block   #
# storing metadata information, similarly to Exif APP1 or #
# IPTC APP13). The advantage of XMP is that it is exten-  #
# sible and that it can be embedded in many file types,   #
# like JPEG, PNG, GIF, HTML, PDF, PostScript, ecc...      #
# Only the envelope changes. The format is the following: #
#---------------------------------------------------------#
# 29 bytes  namespace = http://ns.adobe.com/xap/1.0/\000  #
#  ....     XMP packet (in some Unicode encoding)         #
#=========================================================#
# First, check that the mandatory Adobe namespace string  #
# is there. Then, parse the XML and save the intermediate #
# results. Last, Check that the XML block conforms to the #
# RDF and XMP specifications (issue an error otherwise).  #
###########################################################
# Ref: "XMP Specification", version 3.2, June 2005, Adobe #
#      Systems Inc., San Jose, CA, http://www.adobe.com   #
###########################################################
sub parse_app1_xmp {
    my ($this) = @_;
    # slurp the segment as a single string
    my $packet = $this->read_record($ASCII, 0, $this->size());
    # get rid of newline chars
    $packet =~ y/\n\r//d;
    # the ID must be Adobe's namespace; die if it is not correct
    $packet =~ s/^($APP1_XMP_TAG|.{0,15})(.*)$/$2/;
    $this->die("Incorrect XMP namespace ($1)") unless $1 eq $APP1_XMP_TAG;
    $this->store_record('NAMESPACE', $ASCII, \ "$1");
    # (TODO): find the used Unicode encoding and deal with it
    use Encode; Encode::_utf8_on($packet);
    # analyse the XML packet (this cannot fail)
    $this->parse_xml_string(\ $packet); # writes into $this->{private_list}
    #print join '::', @$_, "\n" for @{$this->{private_list}};
    # check header (xpacket, x:x[am]pmeta and the outer rdf:RDF)
    $this->test_xmp_header();
    # test that XMP syntax is correct; [Dlist(ABOUT)] := [Desc(ABOUT)]+
    $this->parse_rdf_description() 
	while $this->list_equal(['OPEN', 'rdf:Description']);
    # cleanup
    delete $this->{private_list};
}

###########################################################
# This private method runs a series of regular expression #
# match tests against the private list (starting at posi- #
# tion $offset). $regexps_array is either a reference to  #
# a list of references to regexp rules, or a reference to #
# a single such list. A regexp rule consists of a list of #
# regular express.s and variables to assign submatches to.#
###########################################################
sub list_equal {
    my ($this, $regexps_array, $offset) = (@_, 0);
    # convert a single rule into a list of rules
    $regexps_array = [$regexps_array] unless ref $$regexps_array[0] eq 'ARRAY';
    # check each rule separately, return as soon as possible
    for my $pos ($offset..$offset + $#$regexps_array) {
	return 0 unless exists $this->{private_list}->[$pos];
	# do not modify the private list for the time being
	my $elements = [ @{$this->{private_list}->[$pos]} ];
	my $regexps  = $regexps_array->[$pos]; 
	while (@{$regexps}) {
	    return 0 unless @$elements;
	    my ($e, $r) = (shift(@$elements), shift(@$regexps));
	    my @matches = $e =~ /^$r$/; return 0 unless @matches;
	    ${shift @$regexps} = shift @matches while ref $$regexps[0]; } } 
    return 1 + $#$regexps_array; }

###########################################################
# This private method is almost the same as list_equal,   #
# but, if the match is positive, it also removes matching #
# lines from the private list.                            #
###########################################################
sub list_extract {
    my ($this, $regexps_array, $offset, $number) = (@_, 0);
    my $lines = $this->list_equal($regexps_array, $offset) || return 0;
    splice @{$this->{private_list}}, $offset, $lines; return 1; }

###########################################################
# Private method for saving a piece of information into   #
# the private list (always undefined type). Arguments are:#
# $pdir --> (list ref) identifies a subdirectory          #
# $name --> of the Record to be saved                     #
# $value --> content to be saved in the Record            #
# $extra --> optonal info for {extra} field of a Record   #
###########################################################
sub store_xmp_value {
    my ($this, $pdir, $name, $value, $extra) = @_;
    my $rec = $this->store_record
	($this->provide_subdirectory(@$pdir), $name, $UNDEF, \$value);
    $rec->{extra} = $extra if $extra; }

###########################################################
# Private method for the extracting a list of attributes  #
# and saving them in the private list; the arguments are: #
# $pdir --> (list ref) identifies a subdirectory          #
# $regexp --> to match the attribute name against         #
# $extra --> info for the {extra} field of a Record       #
###########################################################
sub extract_attributes {
    my ($this, $pdir, $regexp, $extra) = @_; my ($name, $value, %summary)= ();
    $this->store_xmp_value($pdir, $name, $value, $extra),
    $summary{$name} = $value while $this->list_extract
	(['ATTRIBUTE', $regexp, \$name, '(.*)', \$value]); 
    return \ %summary; }

###########################################################
# This private method parses a generic XML string and     #
# writes its findings in an array of array references.    #
# Each sublist in the main list starts with a sublist     #
# type, which can be OPEN, OPEN_ABBR, OPEN_SPECIAL,       #
# ATTRIBUTE, COMMENT, CONTENT or CLOSE. The parsing algo- #
# rithm is my current understanding of what XML is .....  #
# ------------------------------------------------------- #
# Spaces before a tag are not meaningful, but they cannot #
# be thrown away before textual values. Keeping track of  #
# this condition is the reason for the $f flag.           #
###########################################################
sub parse_xml_string {
    my ($this, $string) = @_;
    # initialisation of this private, intermediate list
    $this->{private_list} = [] unless exists $this->{private_list};
    # some variables and their initialisation
    my $mkp_tag = qr/[\w:-]+/o; my $spaces; my $f = 0;
    # how to push a new list of strings onto the private list
    my $lpush = sub { push @{$this->{private_list}}, [@_] };
    # how to extract the attribute list of a tag
    my $apush = sub { my ($p) = @_; &$lpush('ATTRIBUTE', $1, $3) while $p
			  =~ s/^\s*($mkp_tag)=([\'\"])([^\'\"]*)\2//o;
		      &$lpush('IMPOSSIBLE', $p) if $p; };
  PARSE_LOOP:
    # extract spaces at the beginning (they are important for content!)
    $$string =~ s/^(\s*)//o; $spaces = $1 || '';
    # try to speed regular expressions up by lookint at the
    # first two characters of the current string
    if (substr($$string, 0, 1) eq '<') {
	my $s = substr($$string, 1, 1);
	# extract a closing markup
	if ($s eq '/' && $$string =~ s/^<\/($mkp_tag)>//o) {
	    &$lpush('CONTENT', $spaces) if $f; $f=0; &$lpush('CLOSE', $1); }
	# extract a comment, if present ( <!-- comment --> )
	elsif ($s eq '!' && $$string =~ s/^<!-- *(.*?) *-->//o) {
	    &$lpush('COMMENT', $1); $f=0; }
	# extract header tags ( <?some:thing val='1'?> ) + attributes
	elsif ($s eq '?' && $$string =~ s/^<\?($mkp_tag) ?([^\?]*?)\?>//o) {
	    &$lpush('OPEN_SPECIAL', $1); &$apush($2) if $2; $f=0; }
	# extract an opening markup with or without attributes
	# extract also self-contained tags ( <.... /> ), (not closing)
	elsif ($$string =~ s/^<($mkp_tag) ?([^\?]*?)(\/?)>//o) {
	    &$lpush($3 ? 'OPEN_ABBR' : 'OPEN', $1); &$apush($2) if $2;
	    $3 ? &$lpush ('CLOSE_ABBR') : $f = 1; }
	# an impossible case
	else { &$lpush('IMPOSSIBLE', $$string) if $string; $$string = ""; }
	# extract content (spaces are important ...)
    } else { $$string =~ s/^([^<]+)//o; &$lpush('CONTENT', $spaces.$1); $f=0; }
    # parse the rest of the string
    $$string ? goto PARSE_LOOP : return;
}

###########################################################
# Framework for the XMP packet. The packet content is     #
# sandwiched between a header and a trailer, and may      #
# contain padding whitespaces at the end. The 'xpacket'   #
# header has two mandatory attributes, 'begin' and 'id'   #
# (order is important), separated by exactly one space.   #
# Attribute values, here and in the following, are enclo- #
# sed by single quotes or double quotes. The value of     #
# 'begin' must be the Unicode "zero-width non-breaking    #
# space" (U+FEFF); an empty value is also acceptable (for #
# backward compatibility), and means UTF-8. The value of  #
# 'id' is fixed. Other attributes may be ignored. A pad-  #
# ding of 2KB or 4KB, with a newline every 100 spaces, is #
# recommended. The 'end' attribute of the trailer may     #
# have a value of "r" (read-only) or "w" (modifiable).    #
# ------------------------------------------------------- #
# The structure of the packet content is as follows.      #
# There is an optional x:xmpmeta (or x:xapmeta for older  #
# files) element, with a mandatory xmlns:x attribute set  #
# to "adobe:ns:meta/" and other optional attributes,      #
# which can be ignored. Inside it (or at top level, if it #
# is absent), there is exactly one rdf:RDF element with   #
# an attribute specifying the xmlns:rdf namespace (other  #
# namespaces can be listed here as additional attributes).#
# Inside the 'rdf:RDF' element then, all XMP properties   #
# are stored inside one or more rdf:Description element.  #
# ------------------------------------------------------- #
# <?xpacket begin="..." id="...XMP id ..." ...?>          #
#   <x:xmpmeta xmlns:x='adobe:ns:meta/' ..attributes..>   #
#     <rdf:RDF xmlns:rdf="...URI...">                     #
#       [rdf:Description]+                                #
#     </rdf:RDF>                                          #
#   </x:xmpmeta>                                          #
#   ... padding with XML whitespaces ...                  #
# <?xpacket end="w"?>                                     #
###########################################################
sub test_xmp_header {
    my ($this) = @_; 
    my ($rw, $filter, $f1, $f2, $meta, $ns, $URI) = ();
    # search for <?xpacket begin="..." id="...XMP id ...";
    $this->list_extract(['OPEN_SPECIAL', 'xpacket'])
	|| $this->die('XMP not starting with "xpacket"');
    $this->list_extract(['ATTRIBUTE', 'begin', $APP1_XMP_XPACKET_BEGIN])
	|| $this->die('XMP xpacket-begin not zero-width Unicode space');
    $this->list_extract(['ATTRIBUTE', 'id', $APP1_XMP_XPACKET_ID])
	|| $this->die('XMP xpacket-id not correct');
    # extract all additional attributes in the opening tag
    $this->extract_attributes(['XMP_HEADER'], '(.*)', 'xpacket');
    # search for <?xpacket end="w|r"?> at the end
    $this->list_extract(['ATTRIBUTE', 'end', '(w|r)', \$rw], -1)
	|| $this->die('XMP xpacket end attribute not found');
    $this->list_extract(['OPEN_SPECIAL', 'xpacket'], -1) # OPEN, not CLOSE ...
	|| $this->die('XMP not ending with "xpacket"');
    $this->store_xmp_value(['XMP_HEADER'], 'xpacket-rw', $rw);
    # extract additional filters (are these undocumented?)
    while ($this->list_extract(['OPEN_SPECIAL', '(.*)', \$filter])) {
	$this->list_extract(['ATTRIBUTE', '(.*)', \$f1, '(.*)', \$f2]);
	$this->store_xmp_value(['XMP_HEADER'], $filter, "$f1=\"$f2\""); }
    # take care of the xmpmeta/xapmeta tags, if present
    $this->list_extract(['OPEN', '(x:x[am]pmeta)', \$meta]) || goto NO_XMPMETA;
    $this->store_xmp_value(['XMP_HEADER'], 'meta', $meta);
    $this->list_extract(['CLOSE', $meta], -1)
	|| $this->die('XMP x:x[am]pmeta not closing');
    $this->list_extract(['ATTRIBUTE', 'xmlns:x', $APP1_XMP_META_NS])
	|| $this->die('XMP x:x[am]pmeta without namespace');
    $this->extract_attributes(['XMP_HEADER'], '(.*)', 'meta');
  NO_XMPMETA:
    # take care of the outer rdf:RDF and its namespace
    $this->list_extract(['OPEN', 'rdf:RDF'])
	|| $this->die('Outer rdf:RDF not found');
    $this->list_extract(['ATTRIBUTE', 'xmlns:rdf', $APP1_XMP_OUTER_RDF_NS])
	|| $this->die('Namespace not correct/found in outer rdf:RDF');
    $this->list_extract(['CLOSE', 'rdf:RDF'], -1)
	|| $this->die('Outer rdf:RDF not closing');
    # save additional namespaces if present (undocumented?)
    $this->extract_attributes(['SCHEMAS'], 'xmlns:(.*)', 'rdf:RDF');
    # extract all rdf:about and check that they are the same
    # (sometimes 'rdf:' is missing, how should I treat this case?)
    my @abouts = map { $$_[2] } grep { $$_[1] =~ /(rdf:|)about/ }
                 grep { $$_[0] eq 'ATTRIBUTE' } @{$this->{private_list}};
    $this->die("Inconsistent rdf:about's") if grep { $_ ne $abouts[0]} @abouts;
    $this->store_xmp_value(['XMP_HEADER'], 'rdf:about', $abouts[0]);
}

###########################################################
# Description elements: rdf:Description elements and XMP  #
# schemas are usually in one-to-one correspondence. Each  #
# element has two mandatory attributes, 'rdf:about' and   #
# 'xmlns:NAME'. 'rdf:about' is usually empty (however, it #
# can contain an application specific URI), and its value #
# *must* be shared among all rdf:Description elements.    #
# 'xmlns:NAME' specifies the local namespace prefix (NAME #
# stands for the actual prefix). Additional namespaces    #
# can be specified via 'xmlns' attributes.                #
# ------------------------------------------------------- #
# [rdf:Description] := <rdf:Description rdf:About='ABOUT' #
#                           xmlns:NAME='text' ..ns..>     #
#                         [property(NAME)]+               #
#                      </rdf:Description>                 #
# ------------------------------------------------------- #
# There exists also an abbreviated form where properties  #
# are listed as attributes of the rdf:Description tag (in #
# this case there is no closing rdf:Description> tag, and #
# the opening tags ends with the '/' character).          #
# ------------------------------------------------------- #
# [rdf:Description] := <rdf:Description rdf:About='ABOUT' #
#                    xmlns:NAME='text' [inlineP(NAME)]+/> #
# [inlineP(NAME)] := "NAME:name='value'"                  #
###########################################################
sub parse_rdf_description {
    my ($this) = @_; my ($type, $ns) = ();
    # extract description opening ($type is OPEN or OPEN_ABBR)
    $this->list_extract(['(OPEN.*)', \$type, 'rdf:Description']) ||
	$this->die('first-level rdf:Description opening tag not found');
    # mandatory rdf:about attribute (its value is already checked)
    $this->list_extract(['ATTRIBUTE', '(rdf:|)about', '.*'])
	|| $this->die('rdf:about failure (missing or inconsistent)');
    # mandatory main namespace in xmlns:abbreviation
    $this->list_equal(['ATTRIBUTE', 'xmlns:.*', '.*'])
	|| $this->die('rdf:Description namespace not found');
    # extract all additional namespaces (and find the secondary one)
    # the exact meaning of this operation is to be clarified (TODO)
    my $nss = $this->extract_attributes(['SCHEMAS'], 'xmlns:(.*)');
    do { $ns = $_ if $$nss{$_}!~ /\#$/ && ! defined $ns } for keys %$nss;
    # if $type is OPEN_ABBR, all simple properties are attributes
    $this->extract_attributes(['PROPERTIES'], '(.*)', 'abbr'), return
	if $type eq 'OPEN_ABBR';
    # some rdf:Description's are there only as placeholders (only empty
    # content) --> do not try to extract properties in this case. In
    # the general case, parse all properties in this rdf:Description
    unless ($this->list_extract(['CONTENT', '\s*'])) {
	$this->parse_rdf_property($ns, ['PROPERTIES'])
	    while ! $this->list_equal(['CLOSE', 'rdf:Description']); }
    # parse the close tag of rdf:Description
    $this->list_extract(['CLOSE', 'rdf:Description'])
	|| $this->die('first-level rdf:Description closing tag not found');
    1 }

###########################################################
# This private method is a dispatcher for the abstract    #
# concept of XMP property. Actual properties are either   #
# simple or structured or they are array properties.      #
# ------------------------------------------------------- #
# [property(NAME)] := [simpleP(NAME)]                     #
#                  or [structuredP(NAME)]                 #
#                  or [arrayP(NAME)]                      #
###########################################################
sub parse_rdf_property {
    my ($this, $ns, $pdir) = @_;
    $this->parse_comment                ($ns, $pdir) ||
	$this->parse_rdf_simple_property($ns, $pdir) ||
	$this->parse_rdf_struct_property($ns, $pdir) ||
	$this->parse_rdf_array_property ($ns, $pdir) ||
	$this->die('parse_rdf_property: unhandled case');
    1 }

###########################################################
# Comments: this is undocumented in the XMP manual by     #
# Adobe, but there is evidence that some properties may   #
# be replaced by a comment, usually carrying its name.    #
# ------------------------------------------------------- #
# [comment] := <!-- this is a comment -->                 #
###########################################################
sub parse_comment {
    my ($this, $ns, $pdir) = @_; my $comment = '';
    return 0 unless $this->list_extract(['COMMENT', '(.*)', \$comment]);
    $this->store_xmp_value($pdir, "$ns:COMMENT", $comment);
    1 }

###########################################################
# Simple properties: a simple property is usually just    #
# some literal value between opening and closing tags     #
# carrying the property name; it can have qualifiers      #
# (attributes). Just to make things easier, it seems that #
# there is the (undocumented) possibility of replacing    #
# the property value (text) with a sequence of general    #
# properties (i.e., a clone of a structured property ...) #
# ------------------------------------------------------- #
# [simpleP(NAME)] := <NAME:name [qualifier]*>text</NAME:name>
#                 or <NAME:name [qualifier]*>[property(name)]+</NAME:name>
# [qualifier] := "name:pnam='text'"                       #
###########################################################
sub parse_rdf_simple_property {
    my ($this, $ns, $pdir) = @_; my ($name, $n, $content, $v) = ();
    # try to match structure and return on failure; indeed, it
    # is difficult to "match" a simple property, so, we try to
    # exclude all other cases here ...
    return 0 if $this->list_equal([['OPEN', '.*'], ['OPEN', 'rdf:.*']]);
    # extract the opening tag with the property name
    $this->list_extract(['OPEN', "($ns:.*)", \$name])
	|| $this->die('simple property: error at opening tag');
    # property qualifiers not yet supported yet!! (TODO)
    # case I: the value is simply text
    if ($this->list_extract(['CONTENT', '(.*)', \$content])) {
	$this->store_xmp_value($pdir, $name, $content); }
    # case II: the "value" is a sequence of properties
    # this is to be clarified .... (TODO)
    else { push @$pdir, $name; 
	   $this->extract_attributes($pdir, '(.*)', 'ATTRIBUTE');
	   $this->store_xmp_value($pdir, 'CONTENT', $v)
	       while $this->list_extract(['CONTENT', '(.*)', \$v]);
	   $this->parse_rdf_simple_property($ns, $pdir)
	       while ! $this->list_equal(['CLOSE', "$name"]); 
	   pop @$pdir; }
    # closing tag
    $this->list_extract(['CLOSE', "$name"])
	|| $this->die('simple property: error at closing tag');
    1 }

###########################################################
# Structured properties: agglomerates of properties of    #
# different type. The inner properties are stored inside  #
# a secondary rdf:Description tag, which also contains a  #
# secondary namespace definition, to be used by inner     #
# properties. I hope this is all.                         #
# ------------------------------------------------------- #
# [structuredP(NAME)] := <NAME:name>                      #
#                          <rdf:Description xmlns:N2="...">
#                            [property(N2)]+              #
#                          </rdf:Description>             #
#                        </NAME:name>                     #
###########################################################
sub parse_rdf_struct_property {
    my ($this, $ns, $pdir) = @_; my ($name, $ns_2, $ns_2_v) = ();
    # try to match structure and return on failure
    return 0 unless $this->list_extract
	(['OPEN', "$ns:(.*)", \$name], ['OPEN', 'rdf:Description'],
	 ['ATTRIBUTE', 'xmlns:(.*)', \$ns_2, '(.*)', \$ns_2_v]);
    # store the property content
    $this->store_xmp_value(['SCHEMAS'], $ns_2, $ns_2_v);
    # get all embedded properties
    $this->parse_rdf_property($ns_2, [@$pdir, $name])
	while ! $this->list_equal(['CLOSE', $name]);
    # find where tags are closing
    $this->list_extract(['CLOSE', $name])
	|| $this->die('structured property: error at closing tag'); 
    1 }

###########################################################
# Array properties: rdf:Seq is for an ordered list of     #
# properties, rdf:Bag for an unordered set of properties  #
# and rdf:Alt for a list of alternatives. Items are most  #
# often homogeneous, but this is not a rule. There is a   #
# namespace problem for qualified items (TODO)            #
# ------------------------------------------------------- #
# [arrayP(NAME)] := <NAME:name>                           #
#                     <rdf:[Bag|Seq|Alt]>                 #
#                       [item]+                           #
#                     </rdf:[Bag|Seq|Alt]>                #
#                   </NAME:name>                          #
# [item] := [simple_item] or [prop_item] or               #
#              [qualif_item(N2)] or [lang_item]           #
# ------------------------------------------------------- #
# Note: a [lang_item] can be found only in an rdf:Alt,    #
# and this rdf:Alt must in turn contain only [lang_item]  #
# items, but this check is not yet implemented (TODO).    #
###########################################################
sub parse_rdf_array_property {
    my ($this, $ns, $pdir) = @_; my ($name, $type) = ();
    # try to match structure and return on failure
    return 0 unless $this->list_extract
	([['OPEN',"($ns:.*)",\$name], ['OPEN','(rdf:(Bag|Seq|Alt))',\$type]]);
    # get all items in this array property
    while (! $this->list_equal(['CLOSE', $type])) {
	$this->parse_rdf_item          ([@$pdir, $name]) && next;
	$this->parse_rdf_item_lang     ([@$pdir, $name]) && next;
	$this->parse_rdf_item_property ([@$pdir, $name]) && next;
	$this->parse_rdf_item_qualified([@$pdir, $name]) && next;
	$this->die('parse_rdf_array_property: unhandled case'); }
    # store the property type in the subdirectory
    $this->search_record(@$pdir, $name)->{extra} = $type;
    # find where tags are closing
    $this->list_extract([['CLOSE', $type], ['CLOSE', "$name"]])
	|| $this->die('array property: error at closing tag');
    1 }

###########################################################
# Simple items: just text strings inside rdf:li tags. It  #
# is the simplest case for rdf:Bag, rdf:Set and rdf:Alt   #
# array properties. It does not need a subdirectory.      #
# ------------------------------------------------------- #
# [simple_item] := <rdf:li>text<rdf:li>                   #
###########################################################
sub parse_rdf_item {
    my ($this, $pdir) = @_; my ($content) = ();
    # try to match structure and return on failure
    return 0 unless $this->list_extract
	([['OPEN','rdf:li'],['CONTENT','(.*)',\$content],['CLOSE','rdf:li']]);
    # store the property content
    $this->store_xmp_value($pdir, 'ITEM', $content);
    1 }

###########################################################
# Property items: these items contain another property    #
# which is not simple text, e.g., a structured property   #
# or an array property. Additional qualifiers can be spe- #
# cified as attributes of the rdf:li tag. Such properties #
# in general require their own subdirectories.            #
# ------------------------------------------------------- #
# [prop_item] := <rdf:li [qualifier]>[simplP(NAME)]<rdf:li>
###########################################################
sub parse_rdf_item_property {
    my ($this, $pdir) = @_; my ($name, $value) = ();
    # try to match structure and return on failure
    return 0 unless $this->list_equal
	([['OPEN', 'rdf:li'], ['ATTRIBUTE', 'rdf:.*', '.*'], ['OPEN', '.*']]);
    $this->list_extract([['OPEN', 'rdf:li'],
			 ['ATTRIBUTE', '(rdf:.*)', \$name, '(.*)', \$value]]);
    # store the property content
    $this->store_xmp_value([@$pdir, 'ITEM'], $name, $value, 'QUALIFIER');
    # this is plainly wrong: how to extract the correct namespace? TODO
    $this->parse_rdf_property('stJob', [@$pdir, 'ITEM']);
    $this->list_extract(['CLOSE', 'rdf:li'])
	|| $this->die('item_property: error at closing tag'); 
    1 }

###########################################################
# Qualified items: these items can be found inside an     #
# array property ('Bag', 'Seq' or 'Alt') and differ from  #
# standard items because they do not only have a value,   #
# but also one or more "qualifiers"; they remain unnamed, #
# however. The namespace of the qualifiers can be diffe-  #
# rent from the main namespace, but this is not yet taken #
# into account (TODO).                                    #
# ------------------------------------------------------- #
# [qualif_item(N2)] := <rdf:li>                           #
#                        <rdf:Description>                #
#                          <rdf:value>text</rdf:value>    #
#                          [qualifier(N2)]*               #
#                        </rdf:Description>               #
#                      </rdf:li>                          #
# [qualifier(N2)] := <N2:role>text</N2:role>              #
###########################################################
sub parse_rdf_item_qualified {
    my ($this, $pdir) = @_; my ($name, $value) = ('qualified-ITEM');
    # try to match structure and return on failure
    return 0 unless $this->list_extract
	([['OPEN','rdf:li'], ['OPEN','rdf:Description'], ['OPEN','rdf:value'],
	  ['CONTENT', '(.*)', \$value], ['CLOSE', 'rdf:value']]);
    # store the qualified property value, then all qualifiers;
    # we need a new subdirectory to store all this stuff
    $this->store_xmp_value([@$pdir, $name], 'ITEM', $value);
    1 while $this->parse_rdf_simple_property('.*', [@$pdir, $name]);
    # find where tags are closing
    $this->list_extract([['CLOSE', 'rdf:Description'], ['CLOSE', 'rdf:li']])
	|| $this->die('item_qualified: error at closing tag'); 
    1 }

###########################################################
# Language alternatives: these are items inside an 'Alt'  #
# array properties. It should not be possible to mix      #
# language alternatives and normal items, but this is not #
# currently checked (TODO ?)                              #
# ------------------------------------------------------- #
# [lang_item] := <rdf:li xml:lang='...'>text</rdf:li>     #
###########################################################
sub parse_rdf_item_lang {
    my ($this, $pdir) = @_; my ($language, $content) = ();
    # try to match structure and return on failure
    return 0 unless $this->list_extract
	([['OPEN', 'rdf:li'], ['ATTRIBUTE', 'xml:lang', '(.*)', \$language], 
	  ['CONTENT', '(.*)', \$content], ['CLOSE', 'rdf:li']]);
    # store the property content
    $this->store_xmp_value($pdir, $language, $content, 'lang-alt');
    1 }

# successful load
1;
