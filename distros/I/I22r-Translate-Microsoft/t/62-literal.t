use Test::More;
use utf8;
use Data::Dumper;
use I22r::Translate;
use t::Constants;
use strict;
use warnings;

binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
if (defined $DB::OUT) {
    # if Perl debugger is running
    binmode $DB::OUT, ':encoding(UTF-8)';
}

ok(1, 'starting test');
t::Constants::skip_remaining_tests() unless $t::Constants::CONFIGURED;

my $src = 'en';
my $dest = $ARGV[0] || 'es';

t::Constants::basic_config();

my %INPUT = (
    literal => "The Vietnamese word for person is {{người}}.",
    literal2 => "My friends {{Jack Morris}} and " . 
    	"Mrs. {{Yamaguchi}} were there.",
    literal3 => "{{Alice}}, {{Bob}}, {{Charlie}}, and {{David}} " . 
	            "did a great job.",

    html1 => "This is called <b>sedimentary</b> rock.",
    html2 => "<i>Asia</i> is the <i>largest</i> continent.",
    html3 => "The <a href='http://en.wikipedia.org/wiki/Berlin_Wall'>" .
	         "Berlin Wall</a> was very tall.",
    html4 => "The three countries are <i>Canada</i>, " . 
	         "<i>the United States</i>, and <b>Mexico</b>.",
    both => "The capital of <i>Russia</i> is {{Moskva}}.",

    nested => "My name is {{<b>Michele</b>}}, not <i>{{Miguel}}</i>.",

    mt108 => "This page is by {{_1}} published on <em>{{_2}}</em>.",
    mt109 => '<a href="{{_1}}">{{_2}}</a> was the previous entry.',

    consec => '{{_1}}{{_2}}, {{_3}} @ {{_4}} : {{_5}}',
    lcase  => 'View all posts by {{_1}}',

    );

my %R = I22r::Translate->translate_hash(
    src => $src, dest => $dest, text => \%INPUT,
    filter => [ 'HTML', 'Literal' ],
    return_type => 'hash' );

#local $Data::Dumper::Indent = 1;
#diag("translate results ", Data::Dumper::Dumper(\%INPUT, \%R));

ok(scalar keys %R == scalar keys %INPUT,
   "output count equals input count");

ok(defined($R{literal}{ID}) && defined($R{literal2}{OLANG}) &&
   defined($R{literal3}{LANG}) && defined($R{html1}{TEXT}) &&
   defined($R{html2}{TIME}) && defined($R{html3}{SOURCE}) &&
   defined($R{both}{OTEXT}),
   "all fields are defined");

ok(join ("\n",map { $INPUT{$_} }sort keys %INPUT) eq
   join ("\n",map { $R{$_}{OTEXT} }sort keys %R),
   "original text is maintained");

ok($R{literal}{TEXT} =~ /người/ &&
   $R{literal2}{TEXT} =~ /Jack Morris/ &&
   $R{literal2}{TEXT} =~ /Yamaguchi/ &&
   $R{literal3}{TEXT} =~ /Alice/ && $R{literal3}{TEXT} =~ /Bob/ &&
   $R{literal3}{TEXT} =~ /Charlie/ && $R{literal3}{TEXT} =~ /David/ &&
   $R{both}{TEXT} =~ /Moskva/,
   "literal text is preserved");

ok($R{literal}{TEXT} =~ /người/, 'literal text is preserved')
    or diag $R{literal}{TEXT};
ok(   $R{literal2}{TEXT} =~ /Jack Morris/, 'literal text is preserved');
ok(   $R{literal2}{TEXT} =~ /Yamaguchi/, 'literal text is preserved');
ok(   $R{literal3}{TEXT} =~ /Alice/, 'literal text is preserved');
ok( $R{literal3}{TEXT} =~ /Bob/, 'literal text is preserved');
ok(   $R{literal3}{TEXT} =~ /Charlie/ && $R{literal3}{TEXT} =~ /David/, 'literal text is preserved');
ok(   $R{both}{TEXT} =~ /Moskva/, 'literal text is preserved');

ok($R{html1}{TEXT} =~ m[<b>.*</b>] &&
   $R{html2}{TEXT} =~ m[<i>.*</i>.*<i>.*</i>] &&
   $R{html3}{TEXT} =~ m[<a href='http://en.\w+.org/wiki/\w+'>.*</a>] &&
   $R{html4}{TEXT} =~ m[<i>.*</i>] && $R{html4}{TEXT} =~ m[<b>.*</b>],
   "html tags are preserved");

ok($R{nested}{TEXT} =~ m[Michele] && $R{nested}{TEXT} =~ m[Miguel] &&
   $R{nested}{TEXT} =~ m[<i>.*</i>] && $R{nested}{TEXT} =~ m[<b>.*</b>],
   "nested literal/html are preserved");

ok($R{mt108}{TEXT} =~ m/\{\{_1\}\}/                 # <-- preferred
   || $R{mt108}{TEXT} =~ m/_1/,                 # <-- the least you can do
   "mt108: literal 1 preserved");
ok($R{mt108}{TEXT} =~ m!<em>\s*\{\{_2\}\}\s*</em>!  # <-- preferred
   || $R{mt108}{TEXT} =~ m!<em>\s*_2\s*</em>!,  # <-- tolerable
   "mt108: literal 2 preserved inside tags");

ok($R{mt109}{TEXT} =~ '<a href="\{\{_1\}\}">',
   "mt109: literal 1 was preserved");
ok($R{mt109}{TEXT} =~ '<a.*>\{*_2\}*</a>',
   "mt109: literal 2 was preserved inside <a/> tags");

ok($R{consec}{TEXT} =~ /\{\{_1\}\}/ && $R{consec}{TEXT} =~ /\{\{_2\}\}/,
   "consec: consecutive literal elements preserved")
    or diag( "translation was: ", $R{consec}{TEXT} );
ok($R{consec}{TEXT} =~ /\{\{_3\}\}/ && $R{consec}{TEXT} =~ /\{\{_4\}\}/
   && $R{consec}{TEXT} =~ /\{\{_5\}\}/,
   "consec: other literal elements preserved");

ok($R{lcase}{TEXT} =~ /\{\{_1\}\}/,
   "lcase: literal element preserved");

done_testing();
