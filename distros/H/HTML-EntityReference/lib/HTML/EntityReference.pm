use 5.10.1;
use utf8;
use strict;
use warnings;

package HTML::EntityReference;

=head1 NAME

HTML::EntityReference - A minimal, abstract, and reusable list of HTML entities

=head1 VERSION

Version 0.011

=cut

our $VERSION = '0.011';

=head1 SYNOPSIS

This is a listing of HTML character entities.  It is intended to be the last time such a list is compiled into a module, being meant to be exposed and usable in any situation.  I found several modules that dealt with Entities, but did not do what I needed, or were for internal use.

The essential characteristic of this data is that "entities exist".

The entity is nothing more than a name for a Unicode character. Everything else having to do with it is attached to the character, and should be something I can find in the Unicode database and related Unicode Perl stuff.  The most fundamental thing is a map of names to code point numbers. I mean the number itself (an integer), not some string representation of the number in hex or decimal or decorated with some other escape system.  From the code point value, it is a single step to get the actual character, or the formatted numeric entity, or whatever.

You can use the supplied hash directly.  Or, this module provides some simple functions that abstract the way the data is actually stored and return the common cases.

The function calls also provide for an easy way to check multiple tables in one go.  So non-standard entities recognised by some browsers or historically are documented here also.

    use HTML::EntityReference;
    my $codepoint= HTML::EntityReference::ordinal('ldquo');  # the integer 8220
    say "Character is known formally as ", charnames::viacode($codepoint), '.';
    my $char= HTML::EntityReference::character('amp');  # the string '&'
    
    # can look up the other way too
    my $entity= HTML::EntityReference::from_ordinal(0x2026);
    say "You can use &$entity; on a web page."  # "hellip"
    
    # use non-standard definitions
    $codepoint= HTML::EntityReference::ordinal($whatsit, ':all');

=cut

use constant INVERSE => '; INVERSE';
use Carp;

=head1 Data Tables

=head2 %W3C_Entities

The package variable C<%W3C_Entities> contains the standard HTML entities as keys, and the code point (integer) as the value.  The source also contains comments copied from L<http://www.w3.org/TR/html4/sgml/entities.html>.

=cut

# see <http://www.w3.org/TR/html4/sgml/entities.html>
our %W3C_Entities= (
    # %HTMLlat1;  Latin 1
    nbsp   => 160, # no-break space = non-breaking space,
    iexcl  => 161, # inverted exclamation mark
    cent   => 162, # cent sign
    pound  => 163, # pound sign
    curren => 164, # currency sign
    yen    => 165, # yen sign = yuan sign
    brvbar => 166, # broken bar = broken vertical bar
    sect   => 167, # section sign
    uml    => 168, # diaeresis = spacing diaeresis
    copy   => 169, # copyright sign
    ordf   => 170, # feminine ordinal indicator
    laquo  => 171, # left-pointing double angle quotation mark = left pointing guillemet
    not    => 172, # not sign
    shy    => 173, # soft hyphen = discretionary hyphen
    reg    => 174, # registered sign = registered trade mark sign
    macr   => 175, # macron = spacing macron = overline = APL overbar
    deg    => 176, # degree sign
    plusmn => 177, # plus-minus sign = plus-or-minus sign
    sup2   => 178, # superscript two = superscript digit two
    sup3   => 179, # superscript three = superscript digit three
    acute  => 180, # acute accent = spacing acute
    micro  => 181, # micro sign, U+00B5 ISOnum 
    para   => 182, # pilcrow sign = paragraph sign
    middot => 183, # middle dot = Georgian comma
    cedil  => 184, # cedilla = spacing cedilla
    sup1   => 185, # superscript one = superscript digit one
    ordm   => 186, # masculine ordinal indicator
    raquo  => 187, # right-pointing double angle quotation mark = right pointing guillemet
    frac14 => 188, # vulgar fraction one quarter = fraction one quarter
    frac12 => 189, # vulgar fraction one half = fraction one half
    frac34 => 190, # vulgar fraction three quarters = fraction three quarters
    iquest => 191, # inverted question mark = turned question mark
    Agrave => 192, # latin capital letter A with grave = latin capital letter A grave
    Aacute => 193, # latin capital letter A with acute
    Acirc  => 194, # latin capital letter A with circumflex
    Atilde => 195, # latin capital letter A with tilde
    Auml   => 196, # latin capital letter A with diaeresis
    Aring  => 197, # latin capital letter A with ring above = latin capital letter A ring
    AElig  => 198, # latin capital letter AE = latin capital ligature AE
    Ccedil => 199, # latin capital letter C with cedilla
    Egrave => 200, # latin capital letter E with grave
    Eacute => 201, # latin capital letter E with acute
    Ecirc  => 202, # latin capital letter E with circumflex
    Euml   => 203, # latin capital letter E with diaeresis
    Igrave => 204, # latin capital letter I with grave
    Iacute => 205, # latin capital letter I with acute
    Icirc  => 206, # latin capital letter I with circumflex
    Iuml   => 207, # latin capital letter I with diaeresis
    ETH    => 208, # latin capital letter ETH
    Ntilde => 209, # latin capital letter N with tilde
    Ograve => 210, # latin capital letter O with grave
    Oacute => 211, # latin capital letter O with acute
    Ocirc  => 212, # latin capital letter O with circumflex
    Otilde => 213, # latin capital letter O with tilde
    Ouml   => 214, # latin capital letter O with diaeresis
    times  => 215, # multiplication sign
    Oslash => 216, # latin capital letter O with stroke = latin capital letter O slash
    Ugrave => 217, # latin capital letter U with grave
    Uacute => 218, # latin capital letter U with acute
    Ucirc  => 219, # latin capital letter U with circumflex
    Uuml   => 220, # latin capital letter U with diaeresis
    Yacute => 221, # latin capital letter Y with acute
    THORN  => 222, # latin capital letter THORN
    szlig  => 223, # latin small letter sharp s = ess-zed
    agrave => 224, # latin small letter a with grave = latin small letter a grave
    aacute => 225, # latin small letter a with acute
    acirc  => 226, # latin small letter a with circumflex
    atilde => 227, # latin small letter a with tilde
    auml   => 228, # latin small letter a with diaeresis
    aring  => 229, # latin small letter a with ring above = latin small letter a ring
    aelig  => 230, # latin small letter ae = latin small ligature ae
    ccedil => 231, # latin small letter c with cedilla
    egrave => 232, # latin small letter e with grave
    eacute => 233, # latin small letter e with acute
    ecirc  => 234, # latin small letter e with circumflex
    euml   => 235, # latin small letter e with diaeresis
    igrave => 236, # latin small letter i with grave
    iacute => 237, # latin small letter i with acute
    icirc  => 238, # latin small letter i with circumflex
    iuml   => 239, # latin small letter i with diaeresis
    eth    => 240, # latin small letter eth
    ntilde => 241, # latin small letter n with tilde
    ograve => 242, # latin small letter o with grave
    oacute => 243, # latin small letter o with acute
    ocirc  => 244, # latin small letter o with circumflex
    otilde => 245, # latin small letter o with tilde
    ouml   => 246, # latin small letter o with diaeresis
    divide => 247, # division sign
    oslash => 248, # latin small letter o with stroke = latin small letter o slash
    ugrave => 249, # latin small letter u with grave
    uacute => 250, # latin small letter u with acute
    ucirc  => 251, # latin small letter u with circumflex
    uuml   => 252, # latin small letter u with diaeresis
    yacute => 253, # latin small letter y with acute
    thorn  => 254, # latin small letter thorn
    yuml   => 255, # latin small letter y with diaeresis

    # %HTMLsymbol; Mathematical, Greek and Symbolic characters
    #     Latin Extended-B
    fnof     => 402, # latin small f with hook = function  = florin
    #     Greek
    Alpha    => 913, # greek capital letter alpha
    Beta     => 914, # greek capital letter beta
    Gamma    => 915, # greek capital letter gamma
    Delta    => 916, # greek capital letter delta
    Epsilon  => 917, # greek capital letter epsilon
    Zeta     => 918, # greek capital letter zeta
    Eta      => 919, # greek capital letter eta
    Theta    => 920, # greek capital letter theta
    Iota     => 921, # greek capital letter iota
    Kappa    => 922, # greek capital letter kappa
    Lambda   => 923, # greek capital letter lambda
    Mu       => 924, # greek capital letter mu
    Nu       => 925, # greek capital letter nu
    Xi       => 926, # greek capital letter xi
    Omicron  => 927, # greek capital letter omicron
    Pi       => 928, # greek capital letter pi
    Rho      => 929, # greek capital letter rho
        # there is no Sigmaf, and no U+03A2 character either
    Sigma    => 931, # greek capital letter sigma
    Tau      => 932, # greek capital letter tau
    Upsilon  => 933, # greek capital letter upsilon
    Phi      => 934, # greek capital letter phi
    Chi      => 935, # greek capital letter chi
    Psi      => 936, # greek capital letter psi
    Omega    => 937, # greek capital letter omega
    alpha    => 945, # greek small letter alpha
    beta     => 946, # greek small letter beta
    gamma    => 947, # greek small letter gamma
    delta    => 948, # greek small letter delta
    epsilon  => 949, # greek small letter epsilon
    zeta     => 950, # greek small letter zeta
    eta      => 951, # greek small letter eta
    theta    => 952, # greek small letter theta
    iota     => 953, # greek small letter iota
    kappa    => 954, # greek small letter kappa
    lambda   => 955, # greek small letter lambda
    mu       => 956, # greek small letter mu
    nu       => 957, # greek small letter nu
    xi       => 958, # greek small letter xi
    omicron  => 959, # greek small letter omicron
    pi       => 960, # greek small letter pi
    rho      => 961, # greek small letter rho
    sigmaf   => 962, # greek small letter final sigma
    sigma    => 963, # greek small letter sigma
    tau      => 964, # greek small letter tau
    upsilon  => 965, # greek small letter upsilon
    phi      => 966, # greek small letter phi
    chi      => 967, # greek small letter chi
    psi      => 968, # greek small letter psi
    omega    => 969, # greek small letter omega
    thetasym => 977, # greek small letter theta symbol
    upsih    => 978, # greek upsilon with hook symbol
    piv      => 982, # greek pi symbol
    #     General Punctuation
    bull     => 8226, # bullet = black small circle,
        # bullet is NOT the same as bullet operator, U+2219
    hellip   => 8230, # horizontal ellipsis = three dot leader
    prime    => 8242, # prime = minutes = feet
    Prime    => 8243, # double prime = seconds = inches,
    oline    => 8254, # overline = spacing overscore
    frasl    => 8260, # fraction slash
    #    Letterlike Symbols
    weierp   => 8472, # script capital P = power set = Weierstrass p
    image    => 8465, # blackletter capital I = imaginary part
    real     => 8476, # blackletter capital R = real part symbol
    trade    => 8482, # trade mark sign
    alefsym  => 8501, # alef symbol = first transfinite cardinal
        # alef symbol is NOT the same as hebrew letter alef, U+05D0 although the same glyph could be used to depict both characters
    #     Arrows
    larr     => 8592, # leftwards arrow
    uarr     => 8593, # upwards arrow
    rarr     => 8594, # rightwards arrow
    darr     => 8595, # downwards arrow
    harr     => 8596, # left right arrow
    crarr    => 8629, # downwards arrow with corner leftwards = carriage return
    lArr     => 8656, # leftwards double arrow
        # ISO 10646 does not say that lArr is the same as the 'is implied by' arrow but also does not have any other character for that function. So ? lArr can be used for 'is implied by' as ISOtech suggests
    uArr     => 8657, # upwards double arrow
    rArr     => 8658, # rightwards double arrow
        # ISO 10646 does not say this is the 'implies' character but does not have another character with this function so ? rArr can be used for 'implies' as ISOtech suggests
    dArr     => 8659, # downwards double arrow
    hArr     => 8660, # left right double arrow
    #     Mathematical Operators
    forall   => 8704, # for all
    part     => 8706, # partial differential
    exist    => 8707, # there exists
    empty    => 8709, # empty set = null set = diameter
    nabla    => 8711, # nabla = backward difference
    isin     => 8712, # element of
    notin    => 8713, # not an element of
    ni       => 8715, # contains as member
        # should there be a more memorable name than 'ni'?
    prod     => 8719, # n-ary product = product sign
        # prod is NOT the same character as U+03A0 'greek capital letter pi' though the same glyph might be used for both
    sum      => 8721, # n-ary sumation
        # sum is NOT the same character as U+03A3 'greek capital letter sigma' though the same glyph might be used for both
    minus    => 8722, # minus sign
    lowast   => 8727, # asterisk operator
    radic    => 8730, # square root = radical sign
    prop     => 8733, # proportional to
    infin    => 8734, # infinity
    ang      => 8736, # angle
    and      => 8743, # logical and = wedge
    or       => 8744, # logical or = vee
    cap      => 8745, # intersection = cap
    cup      => 8746, # union = cup
    int      => 8747, # integral
    there4   => 8756, # therefore
    sim      => 8764, # tilde operator = varies with = similar to,
        # tilde operator is NOT the same character as the tilde, U+007E, although the same glyph might be used to represent both 
    cong     => 8773, # approximately equal to
    asymp    => 8776, # almost equal to = asymptotic to
    ne       => 8800, # not equal to
    equiv    => 8801, # identical to
    le       => 8804, # less-than or equal to
    ge       => 8805, # greater-than or equal to
    sub      => 8834, # subset of
    sup      => 8835, # superset of
        # note that nsup, 'not a superset of, U+2283' is not covered by the Symbol font encoding and is not included. Should it be, for symmetry?  It is in ISOamsn  
    nsub     => 8836, # not a subset of
    sube     => 8838, # subset of or equal to
    supe     => 8839, # superset of or equal to
    oplus    => 8853, # circled plus = direct sum
    otimes   => 8855, # circled times = vector product
    perp     => 8869, # up tack = orthogonal to = perpendicular
    sdot     => 8901, # dot operator
        # dot operator is NOT the same character as U+00B7 middle dot
    # Miscellaneous Technical
    lceil    => 8968, # left ceiling = apl upstile
    rceil    => 8969, # right ceiling
    lfloor   => 8970, # left floor = apl downstile
    rfloor   => 8971, # right floor
    lang     => 9001, # left-pointing angle bracket = bra
        # lang is NOT the same character as U+003C 'less than'  or U+2039 'single left-pointing angle quotation mark'
    rang     => 9002, # right-pointing angle bracket = ket
        # rang is NOT the same character as U+003E 'greater than'  or U+203A 'single right-pointing angle quotation mark'
    #     Geometric Shapes
    loz      => 9674, # lozenge
    #     Miscellaneous Symbols
    spades   => 9824, # black spade suit
        # black here seems to mean filled as opposed to hollow
    clubs    => 9827, # black club suit = shamrock
    hearts   => 9829, # black heart suit = valentine
    diams    => 9830, # black diamond suit

    # %HTMLspecial;  markup-significant and internationalization characters
    #     C0 Controls and Basic Latin
    quot    => 34,   # quotation mark
    amp     => 38,   # ampersand
    lt      => 60,   # less-than sign
    gt      => 62,   # greater-than sign
    #     Latin Extended-A
    OElig   => 338,  # latin capital ligature OE
    oelig   => 339,  # latin small ligature oe
        # ligature is a misnomer, this is a separate character in some languages
    Scaron  => 352,  # latin capital letter S with caron
    scaron  => 353,  # latin small letter s with caron
    Yuml    => 376,  # latin capital letter Y with diaeresis
    #   Spacing Modifier Letters
    circ    => 710,  # modifier letter circumflex accent
    tilde   => 732,  # small tilde
    #   General Punctuation
    ensp    => 8194, # en space
    emsp    => 8195, # em space
    thinsp  => 8201, # thin space
    zwnj    => 8204, # zero width non-joiner
    zwj     => 8205, # zero width joiner
    lrm     => 8206, # left-to-right mark
    rlm     => 8207, # right-to-left mark
    ndash   => 8211, # en dash
    mdash   => 8212, # em dash
    lsquo   => 8216, # left single quotation mark
    rsquo   => 8217, # right single quotation mark
    sbquo   => 8218, # single low-9 quotation mark
    ldquo   => 8220, # left double quotation mark
    rdquo   => 8221, # right double quotation mark
    bdquo   => 8222, # double low-9 quotation mark
    dagger  => 8224, # dagger
    Dagger  => 8225, # double dagger
    permil  => 8240, # per mille sign
    lsaquo  => 8249, # single left-pointing angle quotation mark
        # lsaquo is proposed but not yet ISO standardized
    rsaquo  => 8250, # single right-pointing angle quotation mark
        # rsaquo is proposed but not yet ISO standardized
    euro   => 8364,  # euro sign
    );

our %HTML5_draft;

=head2 %HTML5_draft

The package variable C<%HTML5_draft> contains the entities defined as part of the HTML5 standard, a work in progress.  These are taken from L<http://dev.w3.org/html5/spec/named-character-references.html#named-character-references>.  This is loaded on demand, since there are over two thousand of them.  So if you want to use this hash directly, be sure to call one of the functions specifying 'HTML5_draft' first.

Unlike the existing standard HTML Entity chart, this chart contains some entries that expand to more than one code point.  They can be combining characters, variation selectors, and in a couple cases really are two separate characters.

=head2 other charts

Others will be added.

=head2 custom charts

You can pass your own chart data to the various functions, to be used instead of or in addtion to the built-in charts.  Do this by passing a reference to the hash as an element in the I<include> or I<exclude> list.

In addition to adding your own custom entities, you can also duplicate existing entities in order to override what gets generated (e.g. precomposed vs decomposed form), or provide priority in inverse lookups.

(This might work in this version but has not been tested yet)

=cut
    
## >> Other charts will go here.


my %arg_map= (
    HTML4 => \%W3C_Entities,
    HTML5_draft => [ \%HTML5_draft,  "HTML/Entity-HTML5_draft.pl.inc" ],
    ':all' => [qw/ HTML4 HTML5_draft /]
    );


=head1 Functions

The function calls also provide for an easy way to check multiple tables in one go.  They also abstract the way data is actually stored, and provide handling of simple cases, and take care of busy details that you might not have thought of like multi-valued entities.

=head2 (parameters)

In general, the functions take the thing to be converted as the first parameter, and can take one or two additonal optional arguments.  Only the C<format> function doesn't follow this pattern exactly, taking another parameter first.

The second parameter specifies the chart or charts to use.  This is commonly referred to as the C<include> parameter.  That's because the 3rd works the same way but specifies things to C<exclude>.

The C<include> parameter may be a string or an array reference.  The string is the name of a chart or the name of a bundle.  The chart names available are C<"HTML4"> and C<"HTML5_draft">.  The only bundle name available is C<":all">.  Others will be added in later versions.  If no parameter is given at all, it is the same as using  C<"HTML4">.

If you have more to say than just one string, you can use an array reference instead.  Each element of the array can be a string as explained above.  An item can also be a hash reference, which is a custom chart.

If more than one item is given as the include parameter, they are checked in order until something is found or the list exhausted.

The C<exclude> parameter is not implemented yet.

=cut

sub _next_arg
 {
 my $arglist= shift;
 my $arg= shift(@$arglist) // return ;  # pop off next argument
 return $arg  if ref($arg);  # user put table ref directly in list, not a name.
 if ($arg =~ /^:/) {
    # it is a name for more arguments
    my $list= $arg_map{$arg} // croak "No such option $arg.";
    unshift @$arglist, @$list;
    $arg= shift(@$arglist);
    }
 # look up the argument, and load if necessary.
 my $value= $arg_map{$arg} // croak "No such table $arg.";
 if (ref $value eq 'ARRAY') {  # as opposed to a hash
    # it is a delay load entry
    my ($table, $name)= @$value;
    require $name unless %$table;
    $arg_map{$arg}= $table;  # don't check again next time.
    $value= $table;
    }
 return $value;
 }

=head2 ordinal

Calling C<$n=HTML::EntityReference::ordinal($entity);> is simply the same as looking it up in the data hash: C<$n=$HTML::EntityReference::W3C_Entities{$entity};>.  It will return the code point if the C<$entity> is listed, or C<undef> otherwise.

The return value is normally a number, the integer value of the code point that the entity refers to.  In the case of multi-valued entities, the return value is an array reference.

=cut

sub ordinal
 {
 my ($entity, $include, $exclude)= @_;
 # >> TODO: handle excludes
 return $W3C_Entities{$entity}  unless defined $include;  # default meaning if no argument
 $include= [ $include ]  unless ref $include;  # single name allowed to be given directly
 while (my $table= _next_arg($include)) {
    my $val= $$table{$entity};
    return $val if defined $val;
    }
 return;  # not found anywhere it looked.
 }

=head2 character

This is the same as calling the built-in chr on the result of ordinal, except that if the named entity was not listed it returns C<undef>.  It also takes care of entities that expand into multiple code points.  For multi-valued entities, it simply produces a string with more than one character in it.

=cut

sub character
 {
 my $ord= ordinal (@_)  // return;
 if (ref $ord) {  # it is a list, not a number
    return join('', map { chr($_) } @$ord);
    }
 return chr($ord);
 }

=head2 hex

This is the same as calling the C<sprintf("%04x", $ord);> on the result of C<ordinal>, except that if the named entity was not listed it returns C<undef>.  Note that this returns the 4 hex digits I<only>, without any decorations or prefix.  You can incorporate this into a hex notation or hex entity notation, as desired.  However, that might be awkward for multi-value returns, so this function doesn't handle those.  See the C<format> function instead.

=cut

sub hex
 {
 my $ord= ordinal (@_) // return;
 carp "multi-value entities are not handled by hex.  Use format instead"  if (ref $ord);
 return sprintf ("%04x", $ord);
 }

=head2 format

This takes a format string as a first argument.  After that are the usual entity, include, and exclude parameters.  The format string is used with C<sprintf>.  For example, C<format ('&#x%X;', 'NotHumpDownHump', 'HTML5_draft')> will produce C<"&#x224E; &#x338;"> in scalar context.

For multi-value entities, it will format each code point.  In scalar context, they are returned as one string with separating spaces.  In list context, returns a list of formatted numbers.

=cut
 
sub format
 {
 my $fmt= shift;
 my $ord= ordinal (@_) // return;
 unless (ref $ord) {
    return sprintf ($fmt, $ord);
    }
 my @results= map { sprintf ($fmt, $_) } @$ord;
 return @results  if wantarray;
 return join (' ', @results);
 }
 

=head2 valid

This returns a truth value indicating whether the specified entity name is listed.

=cut

sub valid
 {
 my ($entity, $include, $exclude)= @_;
 # >> TODO: handle excludes
 return exists $W3C_Entities{$entity}  unless defined $include;  # default meaning if no argument
 $include= [ $include ]  unless ref $include;  # single name allowed to be given directly
 while (my $table= _next_arg($include)) {
    return 1  if exists $$table{$entity};
    }
 return;  # not found anywhere it looked.
 }

# be sure this is performed in a consistent manner between building and looking up
sub array_key
 {
 return join (' ',  map { +$_} (@_) );
 }

sub invert_table
 {
 my $tab= shift;
 my %result;
 while (my ($key, $value)= each %$tab) {
    my $x= ref($value) ? array_key (@$value) : +$value;
    $result{$x}= $key;
    }
 return \%result;
 }

sub get_reverse
 {
 my $table= shift;
 my $inverse= $$table{+INVERSE};
 $inverse= $$table{+INVERSE}= invert_table ($table)  unless defined $inverse;
 return $inverse;
 }


=head2 from_... Inverse Functions

Since Perl doesn't provide for overloading in the C++ sense, we need to clearly distinguish whether you are passing in a code point integer, or the character itself, or whatever other forms might be available.  So the inverse functions match the names of the primary functions with the additon of C<from_> in front.

The inverse lookup table is not created until it is needed, the first time this function is called.  The inverse table is stored inside the main table, under a key whose name begins with a "C<;>" character.  Because entities are normally parsed out as terminating with a semicolon, you won't have an entity with a semicolon I<within> the name!  So names beginning with a semicolon are used for "internal use" and if you access the charts directly (or use your custom charts), ignore these.

=head2 from_ordinal

If the argument contains more than one code point, it will try to match a multi-valued entity exactly.  It will not take prefixes, change normalizations, or anything like that.  You can pass an integer or an array ref containing integers to this function.

If multiple entities are defined that map to the same code point(s), it will simply return one of them essentially at random.  There is no way to know which one is "better" for your purpose.  However, it does check the tables in the order specified by the second argument, so you can put a custom table first that includes the answers you specifically want.

=cut

sub from_ordinal
 {
 my ($codepoint, $include, $exclude)= @_; 
 use integer;
 my $key= ref($codepoint) ? array_key(@$codepoint) : 0+$codepoint;
 # >> TODO: handle exclude option
 $include //= [ \%W3C_Entities ];
 $include= [ $include ] unless ref $include;
 while (my $table= _next_arg($include)) {
    $table= get_reverse ($table);
    my $result= $$table{$key};
    return $result  if defined $result;
    }
 }


=head2 from_character

This is the inverse of C<character>.  It will return undef if no entity matches the argument.  See notes on from_ordinal.

=cut
 
sub from_character
 {
 my $char= shift; 
 my $ord= (length($char) == 1) ? ord($char) : [ map{ord($_)}(split('',$char)) ];
 return from_ordinal ($ord, @_);
 }
 
return 1;  # module loaded OK.


=head1 AUTHOR

John M. Dlugosz, C<< <dlugosz AT cpan DOT com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-html-entityreference at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-EntityReference>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::EntityReference


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-EntityReference>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-EntityReference>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-EntityReference>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-EntityReference/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to Zsbán Ambrus for suggesting the handling of multiple charts.  That pretty much made the module what it became.

Thanks to those on PerlMonks who chatted with me regarding the specifications and ideas.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 John M. Dlugosz.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of HTML::EntityReference
