use Test::More tests=>325;
eval {
	require Test::NoWarnings;
	Test::NoWarnings->import();
	1;
} or do {
	SKIP: {
		skip "Test::NoWarnings is not installed", 1;
		fail "This shouldn't really happen at all";
	};
};
chdir "t";
require Dtest;
BEGIN {
	*CORE::GLOBAL::localtime = sub { return(gmtime($_[0])) };
}

my @t=gmtime(1294484984);

dtest("filter_add.html","ABAB10A133AC123A579ABA\n",{A=>123,B=>456,C=>"A",D=>"B"});
dtest("filter_addslashes.html",q(A\\\\B\\"A\\'\\'\\\\CA\\\\B\\"\\"A\\'\\'\\\\)."\n",{});
dtest("filter_capfirst.html","ABaCAbA\n",{var=>"ab"});
dtest("filter_center.html","A  B  ACA  B   A--D---A\n",{var=>"ACA"});
dtest("filter_cut.html","ABACABA\n",{var1=>"NBNA",var2=>"BFOOAFOO"});
SKIP: {
	skip("Strange time handling detected, can't test for it then",6) unless $t[0] == "44" and $t[1] == 9 and $t[2] == 11;
	dtest("filter_date.html","A20th August 1970 12:11Aa.m.AMjan02Fri8:29January820 0820of292Friday001Jan1Jan.+00008:29 a.m.Fri, 1 Jan 2009 20:29:00 +000000nd300920091A2nd January 2009 21:31\n",{var1=>20002312,var2=>[36,31,21,2,0,109,5,1,0]});
};
dtest("filter_default.html","ABACCABA\n",{var=>undef,null=>0.0e1,empty=>"",zero=>"0",array=>[],hash=>{}});
dtest("filter_default_if_none.html","ABACABA\n",{var=>undef});
dtest("filter_dictsort.html","AbbcdhsA239103299AaabcccddOnTwThFiAFiOnThTwA\n",{"scalar",[qw/h c s d bb/],number=>[9,32,2,3,99,10],array=>[["dd","t9"],["b","t2"],["ccc","t5"],["aa","t1"]],hash=>[{name=>"3",val=>"Th"},{name=>"5",val=>"Fi"},{name=>"1",val=>"On"},{name=>"2",val=>"Tw"}]});
dtest("filter_dictsortreversed.html","AshdcbbA993210932AddcccbaaFiThTwOnATwThOnFiA\n",{"scalar",[qw/h c s d bb/],number=>[9,32,2,3,99,10],array=>[["dd","t9"],["b","t2"],["ccc","t5"],["aa","t1"]],hash=>[{name=>"3",val=>"Th"},{name=>"5",val=>"Fi"},{name=>"1",val=>"On"},{name=>"2",val=>"Tw"}]});
dtest("filter_divisibleby.html","ABACABA\n",{});
dtest("filter_escape.html","A&lt;&gt;A&lt;&amp;&gt;A&quot;&#39;&quot;A\n",{});
SKIP: {
	skip ("Can't trust perl 5.6 with Unicode",6) if ($] < 5.008);
	dtest("filter_escapejs.html","A\\\\\\'\\\"A\\&#39;C\\u34f4C\\&quot;A\\u4532 A\n",{var=>"\'C\x{34f4}C\""});
};
dtest("filter_filesizeformat.html","A3.76 MbA1012 bytesA5.31 TbA\n",{var=>"1012"});
dtest("filter_first.html","ABACABA\n",{array=>[qw/B D E/],hash=>{qw/1 C 2 G/},empty=>[]});
dtest("filter_fix_ampersands.html","A&amp;A&amp;amp;A&amp;A\n",{var=>"&"});
dtest("filter_floatformat.html","A1A1.000A1.001A2A\n",{});
dtest("filter_force_escape.html","A&lt;&amp;&gt;A&amp;amp;A&amp;lt;&amp;amp;&amp;gt;A\n",{var=>"&"});
dtest("filter_get_digit.html","A8AFooA0A\n",{});
SKIP: {
	skip ("Can't trust perl 5.6 with Unicode",6) if ($] < 5.008);
	dtest("filter_iriencode.html","A%CC%B4A%20A%20%CC%B4%20A\n",{});
};
dtest("filter_join.html","A123A1,2,3A11 2 321 2 33A\n",{var=>[1, 2, 3]});
dtest("filter_last.html","ABACABA\n",{array=>[qw/D E B/],hash=>{qw/1 V 2 C/},empty=>[]});
dtest("filter_length.html","A3A2A3A\n",{array=>[qw/D E B/],hash=>{qw/C V A G/},empty=>[]});
dtest("filter_length_is.html","A1AA1A\n",{array=>[qw/D E B/],hash=>{qw/C V A G/},empty=>[]});
dtest("filter_linebreaks.html","A<p>B</p><p>B<br />B</p><p>BB</p>A<p>&lt;b&gt;</p><p>&lt;/b&gt;<br />&lt;i&gt;C&lt;/i&gt;</p>A<p><b></p><p></b><br /><i>C</i></p>A\n",{});
dtest("filter_linebreaksbr.html","AB<br /><br />B<br />B<br /><br />BBA&lt;b&gt;<br /><br />&lt;/b&gt;<br />&lt;i&gt;C&lt;/i&gt;A<b><br /><br /></b><br /><i>C</i>A\n",{});
dtest("filter_linenumbers.html","A1: B\n2: \n3: B\n4: B\n5: \n6: BBA1: <b>\n2: \n3: </b>\n4: <i>C</i>A1: <b>\n2: \n3: </b>\n4: <i>V</i>A\n",{});
dtest("filter_ljust.html","AB    ACAB     AD-----A\n",{var=>"ACA"});
dtest("filter_lower.html","AbacabA\n",{var=>"ACA"});
dtest("filter_make_list.html","A1x2x3AC C CA1_-_2_-_3A\n",{});
dtest("filter_phone2numeric.html","A2A800-366227A43556, 96753A\n",{});
dtest("filter_pluralize.html","AsAAesAAiesAyAiesAyA\n",{});
#dtest("filter_pprint.html","A\$VAR1 = bless( [\n                 &quot;B&quot;,\n   1,\n                 &quot;&quot;,\n                 undef,\n\n",{}); #Can't test this one.
dtest("filter_random.html","ABACABA\n",{array=>[qw/B B B/],hash=>{qw/1 C V C G C/},empty=>[]}); #This is stupid to test.
dtest("filter_removetags.html","A<p>B</p><p>AC<b>A</b></p>BA\n",{});
dtest("filter_rjust.html","A    BACA     BA-----DA\n",{var=>"ACA"});
dtest("filter_safe.html","A<>A<&>A\"'\"A\n",{var1=>"<>",var2=>"<&>",var3=>"\"'\""});
dtest("filter_slice.html","AbAcAbAb c dAa bATAHATAT H FAO TA\n",{array=>[qw/a b c d/],hash=>{qw/1 O 2 T 3 H 4 F/}});
dtest("filter_slugify.html","Abac-aba\n",{});
dtest("filter_stringformat.html","A     (\"a\", \"b\", \"c\")A               a b cA+03A\n",{});
dtest("filter_striptags.html","ABACABA\n",{});
SKIP: {
	skip("Strange time handling detected, can't test for it then",6) unless $t[0] == "44" and $t[1] == 9 and $t[2] == 11;
	dtest("filter_time.html","A12:11A9:31 a.m.Aa.m.AM8:29820082029+00008:29 a.m.001740rnbfA\n",{var2=>[36,31,21,2,0,109,5,1,0]});
};
dtest("filter_timesince.html","A1 minuteA1 hour 40 minutesA1 weekA1 week 1 day 13 hours 47 minutesA6 days 22 hours 40 minutesA\n",{});
dtest("filter_timeuntil.html","A1 minuteA1 hour 40 minutesA1 weekA1 week 1 day 13 hours 47 minutesA6 days 22 hours 40 minutesA\n",{});
dtest("filter_title.html","ABaCa BA\n",{});
dtest("filter_truncatewords.html","AB C D...AB C D D C BA\n",{});
dtest("filter_truncatewords_html.html","A<b>B <span class=`5`>C D...</span></b>A<b>B <span class=`5`>C D D C</span> B</b>A\n",{});
dtest("filter_unordered_list.html","A<li>B\n<ul>\n\t<li>C\n\t<ul>\n\t\t<li>D</li>\n\t\t<li>E</li>\n\t</ul>\n\t</li>\n\t<li>F</li>\n</ul>\n</li>\nA\n",{var=>['B', ['C', ['D', 'E'], 'F']]}); #From Django example
dtest("filter_upper.html","ABACABA\n",{var=>"aca"});
dtest("filter_urlize.html","A&lt;<a href=\"http://www.google.com\" rel=\"nofollow\" >www.google.com</a>&gt;A<a href=\"http://www.sf.net\" rel=\"nofollow\" >www.sf.net</a>A\n",{});
dtest("filter_urlizetrunc.html","A&lt;<a href=\"http://www.google.com\" rel=\"nofollow\">www.g...</a>&gt;A<a href=\"http://www.sf.net\" rel=\"nofollow\">www....</a>A\n",{});
dtest("filter_urlencode.html","Ahttp%3A//www.google.com%3Fhl%3Den%3BAhttp://www.google.com?hl=en%3BA\n",{});
dtest("filter_wordcount.html","A2A3A4A\n",{});
dtest("filter_wordwrap.html","AThis is\nsome\ntext\nwithout\nmeaningA\n",{});
dtest("filter_yesno.html","ABACACADAEAFAGAHAHAIAJAKA\n",{t=>1,f=>0,n=>undef});


