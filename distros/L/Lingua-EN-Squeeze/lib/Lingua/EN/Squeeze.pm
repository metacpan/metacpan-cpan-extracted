# Squeez.pm - Perl package to shorten text to minimum syllables
# $Id: Squeeze.pm,v 1.8 2005-12-05 09:02:49 jaalto Exp $
#
# This file is maintaned by using Emacs (The Editor) and add-on
# packages. See http://tiny-tools.sourceforge.net/
#
#   tinytab.el -- indent mode
#   tinyperl   -- Perl helper mode (pod docs, stubs etc)
#
# To generate HTML
#
#   $ perl -e 'use Pod::Html qw(pod2html); pod2html shift @ARGV' FILE.pm

package Lingua::EN::Squeeze;

use Scalar::Util qw/ reftype /;

use 5.006;
use strict;
use warnings;

my $LIB = "Lingua::EN::Squeeze";        # For debug printing

our $VERSION = '2015.01';

# ***********************************************************************
#
#   POD HEADER
#
# ***********************************************************************

=pod

=head1 NAME

Lingua::EN::Squeeze - Shorten text to minimum syllables using hash table lookup and vowel deletion

=head1 SYNOPSIS

    use Lingua::EN::Squeeze;              # import only function
    use Lingua::EN::Squeeze qw( :ALL );   # import all functions and variables
    use English;                          # to use readable variable names

    while (<>) {
        print "Original: $_\n";
        print "Squeezed: ", SqueezeText(lc $_), "\n";
    }

    #  Or you can use object oriented interface

    $squeeze = Lingua::EN::Squeeze->new();

    while (<>) {
        print "Original: $_\n";
        print "Squeezed: ", $squeeze->SqueezeText(lc $_);
    }

=head1 VERSION

This document describes version 2016.01

=head1 DESCRIPTION

This module squeezes English text to the most compact format possible,
so that it is barely readable.
Be sure to convert all text to lowercase before using the
SqueezeText() for maximum compression,
because optimizations have been
designed mostly for lower case letters.

B<Warning>:
Each line is processed multiple times, so prepare for slow conversion time

You can use this module e.g. to preprocess text before it is sent to
electronic media that has some maximum text size limit. For example pagers
have an arbitrary text size limit, typically around 200 characters, which
you want to fill as much as possible. Alternatively you may have GSM
cellular phone which is capable of receiving Short Messages (SMS), whose
message size limit is 160 characters. For demonstration of this module's
SqueezeText() function, this paragraph's conversion result is presented
below. See yourself if it's readable (Yes, it takes some time to get used
to). The compression ratio is typically 30-40%

    u _n use thi mod e.g. to prprce txt bfre i_s snt to
    elrnic mda has som max txt siz lim. f_xmple pag
    hv  abitry txt siz lim, tpcly 200 chr, W/ u wnt
    to fll as mch as psbleAlternatvly u may hv GSM cllar P8
    w_s cpble of rcivng Short msg (SMS), WS/ msg siz
    lim is 160 chr. 4 demonstrton of thi mods SquezText
    fnc ,  dsc txt of thi prgra has ben cnvd_ blow
    See uself if i_s redble (Yes, it tak som T to get usdto
    compr rat is tpcly 30-40

And if $SQZ_OPTIMIZE_LEVEL is set to non-zero

    u_nUseThiModE.g.ToPrprceTxtBfreI_sSntTo
    elrnicMdaHasSomMaxTxtSizLim.F_xmplePag
    hvAbitryTxtSizLim,Tpcly200Chr,W/UWnt
    toFllAsMchAsPsbleAlternatvlyUMayHvGSMCllarP8
    w_sCpbleOfRcivngShortMsg(SMS),WS/MsgSiz
    limIs160Chr.4DemonstrtonOfThiModsSquezText
    fnc,DscTxtOfThiPrgraHasBenCnvd_Blow
    SeeUselfIfI_sRedble(Yes,ItTakSomTToGetUsdto
    comprRatIsTpcly30-40

The comparision of these two show

    Original text   : 627 characters
    Level 0         : 433 characters    reduction 31 %
    Level 1         : 345 characters    reduction 45 %  (+14% improvement)

There are few grammar rules which are used to shorten some English
tokens considerably:

    Word that has _ is usually a verb

    Word that has / is usually a substantive, noun,
                    pronomine or other non-verb

Read following substituting tokens in order to understand the basics of
converted text. Hopefully, the text is not pure Geek code (tm) to you after
some practice. In Geek code (Like G++L--J) you would need an external
parser to understand it. Here some common sense and time is needed to adapt
oneself to the compressed format. I<For a complete up to date list, you
would be better off peeking the source code>

    automatically => 'acly_'

    for           => 4
    for him       => 4h
    for her       => 4h
    for them      => 4t
    for those     => 4t

    can           => _n
    does          => _s

    it is         => i_s
    that is       => t_s
    which is      => w_s
    that are      => t_r
    which are     => w_r

    less          => -/
    more          => +/
    most          => ++

    however       => h/ver
    think         => thk_

    useful        => usful

    you           => u
    your          => u/
    you'd         => u/d
    you'll        => u/l
    they          => t/
    their         => t/r

    will          => /w
    would         => /d
    with          => w/
    without       => w/o
    which         => W/
    whose         => WS/

Time is expressed with big letters

    time          => T
    minute        => MIN
    second        => SEC
    hour          => HH
    day           => DD
    month         => MM
    year          => YY

Other big letter acronyms, think 8 to represent the speaker and the
microphone.

    phone         => P8

=head1 EXAMPLES

To add new words e.g. to word conversion hash table, you'd define a custom
set and merge them to existing ones. Do similarly to
C<%SQZ_WXLATE_MULTI_HASH> and C<$SQZ_ZAP_REGEXP> and then start using the
conversion function.

    use English;
    use Squeeze qw( :ALL );

    my %myExtraWordHash =
    (
          new-word1  => 'conversion1'
        , new-word2  => 'conversion2'
        , new-word3  => 'conversion3'
        , new-word4  => 'conversion4'
    );

    #   First take the existing tables and merge them with the above
    #   translation table

    my %mySustomWordHash =
    (
          %SQZ_WXLATE_HASH
        , %SQZ_WXLATE_EXTRA_HASH
        , %myExtraWordHash
    );

    my $myXlat = 0;                             # state flag

    while (<>)
    {
        if ( $condition )
        {
            SqueezeHashSet \%mySustomWordHash;  # Use MY conversions
            $myXlat = 1;
        }

        if ( $myXlat and $condition )
        {
            SqueezeHashSet "reset";             # Back to default table
            $myXlat = 0;
        }

        print SqueezeText $ARG;
    }

Similarly you can redefine the multi word translation table by supplying
another hash reference in call to SqueezeHashSet(). To kill more text
immediately in addition to default, just concatenate regexps to variable
I<$SQZ_ZAP_REGEXP>

=head1 KNOWN BUGS

There may be lot of false conversions and if you think that some word
squeezing went too far, please 1) turn on the debug 2) send you example
text 3) debug log log to the maintainer. To see how the conversion goes
e.g. for word I<Messages>:

    use English;
    use Lingua::EN:Squeeze;

    #   Activate debug when case-insensitive word "Messages" is found from
    #   the line.

    SqueezeDebug( 1, '(?i)Messages' );

    $ARG = "This line has some Messages in it";
    print SqueezeText $ARG;

=head1 EXPORTABLE VARIABLES

The defaults may not apply to all types of text, so you may wish to extend
the hash tables and I<$SQZ_ZAP_REGEXP> to cope with your typical text.

=head2 $SQZ_ZAP_REGEXP

Text to kill immediately, like "Hm, Hi, Hello..." You can only set this
once, because this regexp is compiled immediately when C<SqueezeText()> is
called for the first time.

=head2 $SQZ_OPTIMIZE_LEVEL

This controls how optimized the text will be. Currently there is only level
0 (default) and level 1. Level 1 removes all spaces. That usually improves
compression by average of 10%, but the text is more harder to read. If
space is real tight, use this extended compression optimization.

=head2 %SQZ_WXLATE_MULTI_HASH

I<Multi Word> conversion hash table:  "for you" => "4u" ...

=head2 %SQZ_WXLATE_HASH

I<Single Word> conversion hash table: word => conversion. This table is applied
after C<%SQZ_WXLATE_MULTI_HASH> has been used.

=head2 %SQZ_WXLATE_EXTRA_HASH

Aggressive I<Single Word> conversions like: without => w/o are applied last.

=cut


# **********************************************************************
#
#   MODULE INTERFACE
#
# ***********************************************************************

# Somehow doesn't work in Perl 5.004 ?
# use autouse 'Carp' => qw( croak carp cluck confess );

use Carp;
use SelfLoader;
use English;

BEGIN
{
    # ......................................................... &use ...

    use vars qw
    (
        @ISA
        @EXPORT
        @EXPORT_OK
        %EXPORT_TAGS

        $FILE_ID

        $debug
        $debugRegexp

        $SQZ_ZAP_REGEXP
        $SQZ_OPTIMIZE_LEVEL

        %SQZ_WXLATE_HASH
        %SQZ_WXLATE_EXTRA_HASH
        %SQZ_WXLATE_MULTI_HASH
    );

    $FILE_ID =
        q$Id: Squeeze.pm,v 1.8 2005-12-05 09:02:49 jaalto Exp $;

    #   Here woudl be the real version number, which you use like this:
    #
    #       use Squeeze 1.34;
    #
    #   Derive version number, the index is 1 if matches
    #   Clearcase @@ in file_id string. index is 2 if this was
    #   RCS identifier.

    my $ver = (split ' ', $FILE_ID)[$FILE_ID =~ /@@/ ? 1 : 2];

    #   Commented out. Better to use the date based version number,
    #   because it is more informative
    #
    #   $VERSION = sprintf "%d.%02d",  $ver =~ /(\d+)\.(\d+)/;

    # ...................................................... &export ...

    use Exporter ();

    @ISA         = qw(Exporter);

    @EXPORT      = qw
    (
        &SqueezeText
        &SqueezeControl
        &SqueezeDebug
    );

    @EXPORT_OK   = qw
    (
        &SqueezeHashSet

        $SQZ_ZAP_REGEXP
        $SQZ_OPTIMIZE_LEVEL

        %SQZ_WXLATE_HASH
        %SQZ_WXLATE_EXTRA_HASH
        %SQZ_WXLATE_MULTI_HASH
    );

    %EXPORT_TAGS =
    (
        ALL => [ @EXPORT_OK, @EXPORT ]
    );
}

# ********************************************************* &globals ***
#
#   GLOBALS
#
# **********************************************************************

$debug          = 0;
$debugRegexp    = '(?i)DummyYummy';

$SQZ_ZAP_REGEXP =
        '\b(a|an|the|shall|hi|hello|cheers|that)\b'
    .   '|Thanks (in advance)?|thank you|well'
    .   '|N\.B\.|\beg.|\btia\b'
    .   '|\bHi,?\b|\bHm+,?\b'
    .   '|!'
    .   '|wrote:|writes:'

    #   Finnish greetings

    .   '|\b(Terve|Moi|Hei|Huomenta)\b'

    ;

$SQZ_OPTIMIZE_LEVEL = 0;

# ............................................................ &word ...
#   A special mnemonic is signified by postfixing it with either
#   of these characters:
#
#       /       prononym, noun
#       _       verb

%SQZ_WXLATE_HASH =
(
      above         => 'abve'
    , address       => 'addr'
    , adjust        => 'adj'
    , adjusted      => 'ajusd'
    , adjustable    => 'ajutbl'
    , arbitrary     => 'abitry'
    , argument      => 'arg'

    , background    => 'bg'
    , below         => 'blow'

    , change        => 'chg'
    , character     => 'chr'
    , control       => 'ctl'
    , command       => 'cmd'
    , compact       => 'cpact'
    , convert       => 'cnv_'
    , converted     => 'cnvd_'
    , conversion    => 'cnv'
    , cooperation   => 'c-o'
    , correct       => 'corr'
    , correlate     => 'corrl'
    , create        => 'creat'

    , database      => 'db'
    , day           => 'DD'
    , date          => 'DD'
    , definition    => 'defn'
    , description   => 'desc'
    , different     => 'dif'
    , differently   => 'difly'
    , directory     => 'dir'
    , documentation => 'doc'
    , document      => 'doc/'

    , 'each'        => 'ech'
    , electronic    => 'elrnic'
    , electric      => 'elric'
    , enable        => 'enbl'
    , english       => 'eng'
    , environment   => 'env'
    , everytime     => 'when'
    , example       => 'xmple'
    , expire        => 'xpre'
    , expect        => 'exp'
    , extend        => 'extd'

    , field         => 'fld'
    , following     => 'fwng'
    , 'for'         => '4'
    , 'format'      => 'fmt'
    , forward       => 'fwd'
    , function      => 'func'

    , gateway       => 'gtw'
    , generated     => 'gntd'

    , have          => 'hv'
    , herself       => 'hself'
    , himself       => 'hself'
    , hour          => 'HH'

    , identifier    => 'id'
    , information   => 'inf'
    , inform        => 'ifrm'
    , increase      => 'inc'
    , installed     => 'ins'

    , level         => 'lev'
    , limit         => 'lim'
    , limiting      => 'limg'
    , located       => 'loctd'
    , lowercase     => 'lc'

    , managed       => 'mged'
    , megabyte      => 'meg'
    , maximum       => 'max'
    , member        => 'mbr'
    , message       => 'msg'
    , minute        => 'MIN'
    , minimum       => 'min'
    , module        => 'mod'
    , month         => 'MM'

    , 'name'        => 'nam'
    , 'number'      => 'nbr'

    , okay          => 'ok'
    , 'other'       => 'otr'
    , 'others'      => 'otr'

    , 'package'     => 'pkg'
    , page          => 'pg'
    , parameter     => 'param'
    , password      => 'pwd'
    , pointer       => 'ptr'
    , public        => 'pub'
    , private       => 'priv'
    , problem       => 'prb'
    , process       => 'proc'
    , project       => 'prj'

    , recipient     => 'rcpt'       # this is SMTP acronym
    , released      => 'relsd'
    , reserve       => 'rsv'
    , register      => 'reg'
    , resource      => 'rc'
    , return        => 'ret'
    , returned      => 'ret'
    , 'require'     => 'rq'

    , subject       => 'sbj'
    , soconds       => 'SEC'
    , service       => 'srv'
    , squeeze       => 'sqz'
    , something     => 'stng'
    , sometimes     => 'stims'
    , status        => 'stat'
    , still         => 'stil'
    , straightforward => 'sfwd'
    , submit        => 'sbmit'
    , submitting    => 'sbmtng'
    , symbol        => 'sym'
    , 'system'      => 'sytm'

    , 'time'        => 'T'
    , translate     => 'tras'

    , understand    => 'untnd'
    , uppercase     => 'uc'
    , usually       => 'usual'

    , year          => 'YY'
    , you           => 'u'
    , your          => 'u/'
    , yourself      => 'uself'

    , 'version'     => 'ver'

    , warning       => 'warng'
    , with          => 'w/'
    , work          => 'wrk'

);

%SQZ_WXLATE_EXTRA_HASH =
(
      anything      => 'atng'
    , automatically => 'acly_'

    , can           => '_n'

    , does          => '_s'
    , dont          => '_nt'
    , "don't"       => '_nt'
    , 'exists'      => 'ex_'

    , everything    => 'etng/'

    , however       => 'h/ver'

    , increment     => 'inc/'
    , interesting   => 'inrsg'
    , interrupt     => 'irup'

    #    not spelled like 'less', because plural substitution seens
    #    this first 'less' -> 'les'

    , 'les'         => '-/'

    , 'more'        => '+/'
    , most          => '++'

    , phone         => 'P8'
    , please        => 'pls_'
    , person        => 'per/'

    , should        => 's/d'
    , they          => 't/'
    , their         => 't/r'
    , think         => 'thk_'
    , 'which'       => 'W/'
    , without       => 'w/o'
    , whose         => 'WS/'
    , will          => '/w'
    , would         => '/d'

    , "you'd"       => 'u/d'
    , "you'll"      => 'u/l'

);

# ........................................................... &multi ...

%SQZ_WXLATE_MULTI_HASH =
(
      'for me'      => '4m'
    , 'for you'     => '4u'
    , 'for him'     => '4h'
    , 'for her'     => '4h'
    , 'for them'    => '4t'
    , 'for those'   => '4t'

    , 'for example' => 'f_xmple'

    , 'with or without' => 'w/o'

    , 'it is'       => 'i_s'
    , "it's"        => 'i_s'

    , 'that is'     => 't_s'
    , "that's"      => 't_s'
    , "that don't"  => 't_nt'

    , 'which is'    => 'w_s'
    , "which's"     => 'w_s'
    , "which don't" => 'w_nt'

    , 'that are'        => 't_r'
    , "that're"         => 't_r'
    , "that are not"    => 't_rt'

    , 'which are'       => 'w_r'
    , 'which are not'   => 'w_rt'
    , "which aren't"    => 'w_rt'

    , "has not"         => 'hs_t'
    , "have not"        => 'hv_t'

    , "that has"        => 't_hs'
    , "that has not"    => 't_hst'
    , "that hasn't"     => 't_hst'

    , 'which has'       => 'w_hs'
    , 'which has not'   => 'w_hst'
    , "which hasn't"    => 'w_hst'

    , "that have"       => 't_hv'
    , "that have not"   => 't_hvt'
    , "that haven't"    => 't_hvt'

    , 'which have'      => 'w_hv'
    , "which have not"  => 'w_hvt'
    , "which haven't"   => 'w_hvt'

    , "that had"        => 't_hd'
    , "that had not"    => 't_hdt'
    , "that hadn't"     => 't_hdt'

    , 'which had'       => 'w_hd'
    , 'which had not'   => 'w_hdt'
    , "which hadn't"    => 'w_hdt'

    , 'used to'     => 'usdto'
    , 'due to'      => 'd_to'

    , 'United Kingdom' => 'UK'
    , 'United States'  => 'US'
);

# ********************************************************* &private ***
#
#   PRIVATE VARIABLES
#
# **********************************************************************

#   We must declare package globals sot hat SelfLoader sees them after
#   __DATA__

use vars qw
(
    %SQZ_WXLATE_MULTI_HASH_MEDIUM
    %SQZ_WXLATE_MULTI_HASH_MAX
    %SQZ_WXLATE_HASH_MEDIUM
    %SQZ_WXLATE_HASH_MAX
);

%SQZ_WXLATE_MULTI_HASH_MEDIUM = %SQZ_WXLATE_MULTI_HASH;
%SQZ_WXLATE_MULTI_HASH_MAX    = %SQZ_WXLATE_MULTI_HASH;

%SQZ_WXLATE_HASH_MEDIUM       = %SQZ_WXLATE_HASH;
%SQZ_WXLATE_HASH_MAX          = ( %SQZ_WXLATE_HASH, %SQZ_WXLATE_EXTRA_HASH);

#   The Active translate tables
#
#   User isn't suppose to touch this, but in case you need to know
#   exactly what traslations are going and what table is in use, then peeek
#   these.
#
#       $Lingua::EN::Squeeze::wordXlate{above}

use vars qw
(
    %wordXlate
    %multiWordXlate
    $STATE
);

%wordXlate      = %SQZ_WXLATE_HASH_MAX;
%multiWordXlate = %SQZ_WXLATE_MULTI_HASH;
$STATE          = "max";                # Squeeze level

# **********************************************************************
#
#   I N T E R F A C E
#
# *********************************************************************

=pod

=head1 INTERFACE FUNCTIONS

=cut


# **********************************************************************
#
#   PUBLIC FUNCTION
#
# *********************************************************************

=pod

=head2 SqueezeObjectArg($)

=over

=item Description

Return subroutine argument in both function and object cases.
This is a wrapper utility to make package work as a function
library as well as OO class.

=item @list

List of arguments. Usually the first one is object if class
interface is used.

=item Return values

Return arguments without the first object parameter.

=back

=cut

sub SqueezeObjectArg (@)
{
    my @list = @ARG;
    my $ref  = ref( $list[0] );

    #  This test may not be the bets, but we suppose this is
    #  class if we find text like 'Linguag::EN::Squeeze'.
    #
    #   FIXME: What about derived classes (although unlikely)

    if ( $ref =~ /::[a-z]+::/i )
    {
        shift @list;   # Remove arg
    }

    @list;
}

# **********************************************************************
#
#   PUBLIC FUNCTION
#
# *********************************************************************

=pod

=head2 SqueezeText($)

=over

=item Description

Squeeze text by using vowel substitutions and deletions and hash tables
that guide text substitutions. The line is parsed multiple times and
this will take some time.

=item arg1: $text

String. Line of Text.

=item Return values

String, squeezed text.

=back

=cut

sub SqueezeText ($)
{
    #   If you wonder how these substitutions were selected ...
    #   Just by feeding text after text to this function and
    #   seeing how it could be compressed even more
    #
    #   => Trial and error. The order of these substitutions
    #   => is highly significant.

    # ....................................................... &start ...

    my    $id   = "$LIB.SqueezeText";

    local($ARG) = SqueezeObjectArg(@ARG);

    return $ARG if $STATE eq 'noconv';  # immediate return, no conversion

    my $vow     = '[aeiouy]';           # vowel
    my $nvow    = '[^aeiouy\s_/\']';    # non-vowel

    my $orig    = $ARG;                 # for debug
    my $tab     = "";                   # tab

    # ........................................................ &kill ...

    if ( /^\s*[^\s]{30,}/ )     # Any continuous block. UU line ?
    {
        return "";
    }

    if ( /^[A-Z][^\s]+: / )     # Email headers "From:"
    {
        return "";
    }

    s/^\s+//;           # delete leading spaces
    s/[ \t]+$//;        # delete trailing spaces
    s/[ \t]+/ /g;       # collapse multiple spaces inside text

    # ........................................................ words ...

        #   Kill URLs

    s{\b\S+://\S+\b}{URL}ig;

        #   Delete markup +this+ *emphasised* *strong* `text'

    s/\b[_*+`'](\S+)[_*+`']\b/$1/ig;

        #  DON'T REMOVE. This comment fixes Emacs font-lock problem: s///
        #  From above statement.

    $debug and warn $tab,"[markup]\t[$ARG]" if $orig =~ /$debugRegexp/;

        #   Delete 3rd person voice
        #   expires => expire
        #
        #   But do not touch 'was'

    s/\b($vow\S+$vow)s\b/$1/ogi;

        #   says    => say

    s/\b($nvow+\S$vow+)s\b/$1/ogi;

        #   vowel .. nvowel + 2
        #   interests => interest

    s/\b($vow\S+$nvow)s\b/$1/ogi;
    $debug and warn $tab,"[3voice]\t[$ARG]" if $orig =~ /$debugRegexp/;

        #   Delete plurals: non-vowel .. non-vowel + s
        #   problems  => problem

    s/\b($nvow\S+$nvow)s\b/$1/ogi;
    $debug and warn $tab,"[plural]\t[$ARG]" if $orig =~ /$debugRegexp/;

        #   Delete plurals: non-vowel .. vowel + s
        #   messages => message

    s/\b($nvow\S+$vow)s\b/$1/ogi;
    $debug and warn $tab,"[plural2]\t[$ARG]" if $orig =~ /$debugRegexp/;

        #   zap

    s/$SQZ_ZAP_REGEXP//oig;
    $debug and warn $tab,"[zap]\t\t[$ARG]" if $orig =~ /$debugRegexp/;

    # ................................................... &translate ...

    my ($from, $to);

    for $from ( keys %multiWordXlate  )
    {
        $to = $multiWordXlate{ $from };
        s/\b$from\b/$to/ig;
    }

    $debug and warn $tab,"[xlate-multi]\t[$ARG]" if $orig =~ /$debugRegexp/;

    for $from ( keys %wordXlate )
    {
        $to = $wordXlate{ $from };
        s/\b$from\b/$to/ig;
    }

    $debug and warn $tab,"[xlate-word]\t[$ARG]" if $orig =~ /$debugRegexp/;

    # ...................................................... &suffix ...

        #   From Imperfect to active voice
        #   converted => convert

    s/\b($nvow\S\S+)ed\b/$1/igo;

        #   shorten words with -cally suffix => cly

    s/cally\b/cly/g;

        #   shorten comparision: bigger
        #   We can't deduce quicker --> quick, becasue further on
        #   the word would be converted quick --> qck. Not good.

    s/\b($nvow+\S+e)r\b/$1/ogi;
    $debug and warn $tab,"[comparis]\t[$ARG]" if $orig =~ /$debugRegexp/;

        #       leaning --> leang

    s/ing\b/ng/ig;
    s/io\b/o/ig;

        #       uniqe       --> uniq

    $debug and warn $tab,"[-io]\t\t[$ARG]" if $orig =~ /$debugRegexp/;

        #   Watch out "due to"

    s/(\S\S)ue(ness?)?\b/$1/ig;

        #       authenticate -> authentic
        #       Watch out 'state' !

    s/(\S\S\S)ate\b/$1/ig;

    $debug and warn $tab,"[-ate]\t\t[$ARG]" if $orig =~ /$debugRegexp/;

    # .................................................. &heuristics ...

    $debug and warn $tab,"[0]\t\t[$ARG]" if $orig =~ /$debugRegexp/;

        #       Vocal only at the beginning and end ==> drop last
        #       info    => inf
        #
        #       Don't touch away

    s/\b($vow+$nvow$nvow)$vow+\b/$1/ogi;
    $debug and warn $tab,"[vowel-last]\t[$ARG]" if $orig =~ /$debugRegexp/;

        #       only one vowel in string
        #       help ==> hlp
        #       stat            BUT can't deduce to stt

    s/\b($nvow)$vow($nvow$nvow)\b/$1$2/ogi;
    $debug and warn $tab,"[vowel-one]\t[$ARG]" if $orig =~ /$debugRegexp/;

        #       asked --> skd

    s/\b($vow+$nvow$nvow)$vow($nvow)\b/$1$2/ogi;
    $debug and warn $tab,"[vowel-two]\t[$ARG]" if $orig =~ /$debugRegexp/;

        #       Delete two vowels; through --> thrgh
        #       Don't touch words ending to -ly: diffrently, difly

    s/\b($nvow+)$vow$vow($nvow$nvow+)(?!y)\b/$1$2/ogi;
    $debug and warn $tab,"[vowel-many]\t[$ARG]" if $orig =~ /$debugRegexp/;

        #       type => typ

    s/\b($nvow+$vow$nvow+(?!y))$vow\b/$1/ogi;
    $debug and warn $tab,"[vowel-end]\t[$ARG]" if $orig =~ /$debugRegexp/;

        #       many vowels, remove first two
        #       detected    => dtcted
        #       service     => srvce

    s/\b(\S+)$vow+($nvow+)$vow+(\S*$vow\S*)\b/$1$2$3/ogi;
    $debug and warn $tab,"[vowel-more]\t[$ARG]" if $orig =~ /$debugRegexp/;

        #       Two consequent vowels
        #       obtain      => obtan

    s/\b(\S*$vow$nvow+$vow)$vow(\S+)\b/$1$2/ogi;
    $debug and warn $tab,"[vowel-22more]\t[$ARG]" if $orig =~ /$debugRegexp/;

        #       Two non-vowels at the end
        #       contact     => contac

#    s/($nvow)$nvow\b/$1/ogi;
#   $debug and warn $tab,"[non-vowel-2end][$ARG]" if $orig =~ /$debugRegexp/;

        #       Two same vowels
        #       took        => tok
        #       keep        => kep

    s/\b(\S+)($vow)\2(\S+)\b/$1$2$3/ogi;
    $debug and warn $tab,"[vowel-2same]\t[$ARG]" if $orig =~ /$debugRegexp/;

    # .................................................... &suffixes ...

    #   frequency   => freq
    #   acceptance  => accept
    #   distance    => dist

    s/u?[ae]nc[ye]\b//ig;

        #       management      => manag
        #       establishement  => establish

    s/ement\b/nt/ig;

        #       allocation => allocan

    s/[a-z]ion\b/n/ig;

        #       hesitate --> hesit

    s/tate\b/t/ig;

    # ................................................. &multi-chars ...

    s/ph\b//g;                  # paragraph --> paragra
    s/ph/f/g;                   # photograph --> fotogra

    $debug and warn $tab,"[multi]\t[$ARG]" if $orig =~ /$debugRegexp/;

    # .................................................. simple rules ...

    s/([0-9])(st|nd|th)/$1/ig;  # get rid of 1st 2nd ...

        # Shorted full month names

    s/\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]+\b/$1/ig;

        #       "This is the end. And new sentence."
        #       We can leave out the period.

    s/\.\s+([A-Z])/$1/g;

        #       Any line starting that does not start with aphanumeric can be
        #       deleted. Like
        #
        #           Well, this is
        #
        #       is previously shortened to ", this is" and the leading is now
        #       shortened to
        #
        #           this is

    s/^\s*[.,;:]\s*//;
    s/\s*\W+$/\n/;      # ending similarly.

    $debug and warn $tab,"[shorthand]\t[$ARG]" if $orig =~ /$debugRegexp/;

        #       we don't need these,

    s/[!#\$'\"*|\\^]//g;                # dummy "' to restore Emacs font-lock

        #       carefully => carefuly
        #       Don't touch 'all'

    s/([flkpsy])\1\B/$1/ig;             # Any double char to one char

    $debug and warn $tab,"[double]\t[$ARG]" if $orig =~ /$debugRegexp/;

        #   Any double chars at the END of work

    s/\b(\S*$vow\S*)([^0-9])\2\b/$1$2/i;

    $debug and warn $tab,"[double-end]\t[$ARG]" if $orig =~ /$debugRegexp/;

        #       short => shor

    s/\rt\b/r/ig;               # Any double char to one char

    $debug and warn $tab,"[rt]\t[$ARG]" if $orig =~ /$debugRegexp/;

    # .................................................... &optimize ...

    if ( $SQZ_OPTIMIZE_LEVEL )
    {
        s/\s+(.)/\U$1/g;        # kill empty spaces
    }

    $ARG;
}

#   This section is automatically updated by Emacs function
#   tinyperl.el::tiperl-selfstubber-stubs. Do not touch the BEGIN END tokens.
#   See http://tiny-tools.sourceforge.net/

# BEGIN: Devel::SelfStubber

sub Lingua::EN::Squeeze::SqueezeHashSet ($;$);
sub Lingua::EN::Squeeze::SqueezeControl (;$) ;
sub Lingua::EN::Squeeze::SqueezeDebug   (;$$);

# END: Devel::SelfStubber

1;
__DATA__

#  -- A U T O L O A D  -- A U T O L O A D  -- A U T O L O A D  --

# **********************************************************************
#
#   PUBLIC FUNCTION
#
# **********************************************************************

=pod

=head2 new()

=over

=item Description

Return new class object.

=item Return values

Object.

=back

=cut

sub new
{
    my $pkg   = shift;
    my $type  = ref($pkg) || $pkg;

    my $this  = { @ARG };
    bless $this, $type;

    $this;
}

# **********************************************************************
#
#   PUBLIC FUNCTION
#
# *********************************************************************

=pod

=head2 SqueezeHashSet($;$)

=over

=item Description

Set hash tables to use for converting text. The multiple word conversion
is done first and after that the single words conversions.

=item arg1: \%wordHashRef

Pointer to a hash to be used to convert single words. If "reset", use
default hash table.

=item arg2: \%multiHashRef [optional]

Pointer to a hash to be used to convert multiple words. If "reset", use
default hash table.

=item Return values

None.

=back

=cut

sub SqueezeHashSet ($;$)
{
    my    $id   = "$LIB.SqueezeHashSet";
    my( $wordHashRef, $multiHashRef ) = SqueezeObjectArg(@ARG);

    if ( $wordHashRef eq 'reset' or $wordHashRef eq 'default' )
    {
        %wordXlate  = %SQZ_WXLATE_HASH_MAX;
    }
    elsif ( ref($wordHashRef) && reftype($wordHashRef) eq 'HASH' )
    {
        %wordXlate  = %$wordHashRef;
    }
    else
    {
        confess "$id: ARG1 must be a hash reference";
    }

    if ( defined $multiHashRef )
    {

        if (  $multiHashRef eq 'reset' or $multiHashRef eq 'default'  )
        {
            %multiWordXlate = %SQZ_WXLATE_MULTI_HASH;
        }
        elsif ( ref($multiHashRef) && reftype($multiHashRef) eq 'HASH' )
        {
            %multiWordXlate = %$multiHashRef;
        }
        else
        {
            confess "$id: ARG2 must be a hash reference";
        }
    }
}

# **********************************************************************
#
#   PUBLIC FUNCTION
#
# *********************************************************************

=pod

=head2 SqueezeControl(;$)

=over

=item Description

Select level of compression, which can be one of noconv, enable, medium,
maximum.

=item arg1: $state

String. If nothing, use maximum squeeze level. Other string values accepted
are:

    noconv      Turn off squeeze
    conv        Turn on squeeze
    med         Set squeezing level to medium
    max         Set squeezing level to maximum

=item Return values

None.

=back

=cut

sub SqueezeControl (;$)
{
    my  $id     = "$LIB.SqueezeControl";

    $STATE      = "max";
    ($STATE)    = SqueezeObjectArg(@ARG)  if @ARG;

    if ( $STATE eq ''  or  $STATE =~ /^max/i  )
    {
        SqueezeHashSet "reset", "reset";
    }
    elsif ( $STATE =~ /^med/i )
    {
        SqueezeHashSet  \%SQZ_WXLATE_HASH_MEDIUM ,
                        \%SQZ_WXLATE_MULTI_HASH_MEDIUM;
    }
    elsif ( $STATE =~ /^(conv|noconv)/i )
    {
        # do nothing
    }
    else
    {
        confess "$id: Unknown ARG {$ARG]";
    }
}

# **********************************************************************
#
#   PUBLIC FUNCTION
#
# *********************************************************************

=pod

=head2 SqueezeDebug(;$$)

=over

=item Description

Activate or deactivate debug.

=item arg1: $state [optional]

If not given, turn debug off. If non-zero, turn debug on. You must also
supply C<regexp> if you turn on debug, unless you have given it previously.

=item arg2: $regexp [optional]

If given, use regexp to trigger debug output when debug is on.

=item Return values

None.

=back

=cut

sub SqueezeDebug (;$$)
{
    my  $id = "$LIB.SqueezeDebug";
    my ( $state, $regexp ) = SqueezeObjectArg(@ARG);

    $debug  = $state;
    defined $regexp and $debugRegexp = $regexp;
}

# **********************************************************************
#
#   POD FOOTER
#
# *********************************************************************

=pod

=head1 AVAILABILITY

Latest version of this module can be found at CPAN/modules/by-module/Lingua/

=head1 AUTHOR

Jari Aalto E<lt>jariaalto@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998-2016 by Jari Aalto.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

You can redistribute it and/or modify it under the
terms of GNU General Public License v2 or later.

=cut

__END__

# End of file Squeeze.pm
