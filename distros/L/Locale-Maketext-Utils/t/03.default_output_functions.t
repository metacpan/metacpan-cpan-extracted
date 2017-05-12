use Test::More tests => 197;
use Test::Warn;

BEGIN {
    chdir 't';
    unshift @INC, qw(lib ../lib);
    use_ok('Locale::Maketext::Utils');
    use_ok('MyTestLocale');
}

my %context = ( 'plain' => '', 'ansi' => '', 'html' => '' );

my $lh = MyTestLocale->get_handle('en');

my $bytes = "jalape\xc3\xb1o.b\xc3\xbcrn";    # explicitly be a bytes string (jalapeño.bürn)
my $punyd = 'xn--jalapeo-9za.xn--brn-hoa';

is( $lh->output_encode_puny($bytes), $punyd, "domain: unicode to punycode" );
is( $lh->output_encode_puny($punyd), $punyd, "domain: punycode to punycode does not re-encode" );
is( $lh->output_decode_puny($punyd), $bytes, "domain: punycode to unicode" );
is( $lh->output_decode_puny($bytes), $bytes, "domain: unicode to unicode does not re-encode" );

my $local = "caf\xc3\xa9";                    # explicitly be a bytes string (café)
my $punyl = "xn--caf-dma";
for my $at_sign ( '@', "\xef\xbc\xa0", "\xef\xb9\xab" ) {
    my $hex = unpack( "H*", $at_sign );
    diag "Starting $at_sign ($hex)";
    is( $lh->output_encode_puny("$local$at_sign$bytes"), "$punyl\@$punyd",       "email($at_sign): unicode to punycode" );
    is( $lh->output_encode_puny("$punyl\@$punyd"),       "$punyl\@$punyd",       "email($at_sign): punycode to punycode does not re-encode" );
    is( $lh->output_decode_puny("$punyl\@$punyd"),       "$local\@$bytes",       "email($at_sign): punycode to unicode" );
    is( $lh->output_decode_puny("$local$at_sign$bytes"), "$local$at_sign$bytes", "email($at_sign): unicode to unicode does not re-encode" );
}

# TODO: test decode error (much harder to trip …)
is( $lh->output_encode_puny("I \xe2\x99\xa5 perl"),                      "Error: invalid string for punycode", 'invalid domain returns encode error' );
is( $lh->output_encode_puny("I \xe2\x99\xa5 perl\@I \xe2\x99\xa5 perl"), "Error: invalid string for punycode", 'invalid email returns encode error' );

$lh->{'-t-STDIN'} = 1;
is( $lh->maketext('x [output,underline,y] z'), "x \e[4my\e[0m z", 'output underline text' );
is( $lh->maketext('x [output,strong,y] z'),    "x \e[1my\e[0m z", 'output strong text' );
is( $lh->maketext('x [output,em,y] z'),        "x \e[3my\e[0m z", 'output em text' );

is( $lh->maketext( 'Please [output,url,_1,plain,execute,html,click here].',                                       'CMD HERE' ), 'Please execute CMD HERE.',                                          'plain url append (cmd context)' );
is( $lh->maketext( 'Please [output,url,_1,plain,visit,html,click here].',                                         'URL HERE' ), 'Please visit URL HERE.',                                            'plain url append (url context)' );
is( $lh->maketext( q{Please [output,url,_1,plain,execute '_1' when you can,html,click here].},                    'CMD HERE' ), q{Please execute 'CMD HERE' when you can.},                          'plain url with placeholder' );
is( $lh->maketext( q{Please [output,url,_1,plain,go to '_1' (again that is '_1') when you can,html,click here].}, 'URL HERE' ), q{Please go to 'URL HERE' (again that is 'URL HERE') when you can.}, 'plain url with multiple placeholders' );

is( $lh->maketext( 'My favorite site is [output,url,_1,_type,offsite].', 'http://search.cpan.org' ), 'My favorite site is http://search.cpan.org.', 'plain no value uses URL' );

is( $lh->maketext('X [output,chr,34] Y'), "X \" Y", 'output chr() 34' );
is( $lh->maketext('X [output,chr,38] Y'), "X & Y",  'output chr() 38' );
is( $lh->maketext('X [output,chr,39] Y'), "X ' Y",  'output chr() 39' );
is( $lh->maketext('X [output,chr,60] Y'), "X < Y",  'output chr() 60' );
is( $lh->maketext('X [output,chr,62] Y'), "X > Y",  'output chr() 62' );
is( $lh->maketext('X [output,chr,42] Y'), "X * Y",  'output chr() non-spec' );

is( $lh->maketext('X [output,abbr,Abbr.,Abbreviation] Y'),          "X Abbr. (Abbreviation) Y",       'output abbr()' );
is( $lh->maketext('X [output,acronym,TLA,Three Letter Acronym] Y'), "X TLA (Three Letter Acronym) Y", 'output acronym()' );
is( $lh->maketext( 'X [output,img,SRC,ALT _1 ALT] Y', 'ARG1' ), 'X ALT ARG1 ALT Y', 'output img()' );

is( $lh->maketext('X [output,amp] Y'),  'X & Y',  'output_amp()' );
is( $lh->maketext('X [output,lt] Y'),   'X < Y',  'output_lt()' );
is( $lh->maketext('X [output,gt] Y'),   'X > Y',  'output_gt()' );
is( $lh->maketext('X [output,apos] Y'), q{X ' Y}, 'output_apos()' );
is( $lh->maketext('X [output,quot] Y'), 'X " Y',  'output_quot()' );

SKIP: {
    eval 'use Encode ();';
    skip "Could not load Encode.pm", 2 if $@;
    is( $lh->maketext('X [output,shy] Y'),     'X ' . Encode::encode_utf8( chr(173) ) . ' Y', 'output_shy()' );
    is( $lh->maketext('X [output,chr,173] Y'), 'X ' . Encode::encode_utf8( chr(173) ) . ' Y', 'output chr() 173 (soft-hyphen)' );
}

is( $lh->maketext( 'X [output,class,_1,daring] Y',      "jibby" ), "X \e[1mjibby\e[0m Y", 'class' );
is( $lh->maketext( 'X [output,class,_1,bold,daring] Y', "jibby" ), "X \e[1mjibby\e[0m Y", 'multi class' );

# embedded tests
is(
    $lh->maketext( 'You must [output,url,_1,html,click on _2,plain,go _2 to] to complete your registration.', 'URL', 'IMG' ),
    'You must go IMG to URL to complete your registration.',
    'embedded args in output,url’s “html” and “plain” values'
);
is(
    $lh->maketext( 'X [output,url,_1,I chr(38) Z] A.', 'URL' ),
    'X I & Z (URL) A.',
    'embedded methods in output,url’s simple form'
);
is(
    $lh->maketext( 'X [output,url,_1,html,Y chr(38) Z,plain,W chr(38) Z] A.', 'URL' ),
    'X W & Z URL A.',
    'embedded methods in output,url’s “html” and “plain” values'
);

is( $lh->maketext('X [asis,Truth amp() Justice] A.'), 'X Truth & Justice A.', 'embedded amp()' );

# TODO: "# arbitrary attribute key/value args" tests in non-HTML context

$lh->{'-t-STDIN'} = 0;
is( $lh->maketext('x [output,underline,y] z'), 'x <span style="text-decoration: underline">y</span> z', 'output underline html' );
is( $lh->maketext('x [output,strong,y] z'),    'x <strong>y</strong> z',                                'output strong html' );
is( $lh->maketext('x [output,em,y] z'),        'x <em>y</em> z',                                        'output em html' );

is( $lh->maketext( 'Please [output,url,_1,plain,visit,html,click here].', 'URL HERE' ), 'Please <a href="URL HERE">click here</a>.', 'HTML url' );
is( $lh->maketext( 'Please [output,url,_1,plain,visit,html,click here,_type,offsite].', 'URL HERE' ), 'Please <a target="_blank" class="offsite" href="URL HERE">click here</a>.', 'HTML url, _type => offsite' );

is( $lh->maketext( 'My favorite site is [output,url,_1,_type,offsite].', 'http://search.cpan.org' ), 'My favorite site is <a target="_blank" class="offsite" href="http://search.cpan.org">http://search.cpan.org</a>.', 'HTML no value uses URL' );

is( $lh->maketext('X [output,chr,34] Y'),  "X &quot; Y", 'output chr() 34' );
is( $lh->maketext('X [output,chr,38] Y'),  "X &amp; Y",  'output chr() 38' );
is( $lh->maketext('X [output,chr,39] Y'),  "X &#39; Y",  'output chr() 39' );
is( $lh->maketext('X [output,chr,60] Y'),  "X &lt; Y",   'output chr() 60' );
is( $lh->maketext('X [output,chr,62] Y'),  "X &gt; Y",   'output chr() 62' );
is( $lh->maketext('X [output,chr,42] Y'),  "X * Y",      'output chr() non-spec' );
is( $lh->maketext('X [output,chr,173] Y'), 'X &shy; Y',  'output chr() 173 (soft-hyphen)' );

is( $lh->maketext('X [output,amp] Y'),  'X &amp; Y',  'output_amp()' );
is( $lh->maketext('X [output,lt] Y'),   'X &lt; Y',   'output_lt()' );
is( $lh->maketext('X [output,gt] Y'),   'X &gt; Y',   'output_gt()' );
is( $lh->maketext('X [output,apos] Y'), q{X &#39; Y}, 'output_apos()' );
is( $lh->maketext('X [output,quot] Y'), 'X &quot; Y', 'output_quot()' );
is( $lh->maketext('X [output,shy] Y'),  "X &shy; Y",  'output_shy()' );

is( $lh->maketext( 'X [output,class,_1,daring] Y',      "jibby" ), "X <span class=\"daring\">jibby</span> Y",      'class' );
is( $lh->maketext( 'X [output,class,_1,bold,daring] Y', "jibby" ), "X <span class=\"bold daring\">jibby</span> Y", 'multi class' );

# embedded tests
is(
    $lh->maketext( 'You must [output,url,_1,html,click on _2,plain,go _2 to] to complete your registration.', 'URL', 'IMG' ),
    'You must <a href="URL">click on IMG</a> to complete your registration.',
    'embedded args in output,url’s “html” and “plain” values'
);
is(
    $lh->maketext( 'X [output,url,_1,html,Y chr(38) Z,plain,W chr(38) Z] A.', 'URL' ),
    'X <a href="URL">Y &amp; Z</a> A.',
    'embedded methods in output,url’s “html” and “plain” values'
);
is(
    $lh->maketext( 'X [output,url,_1,I chr(38) Z] A.', 'URL' ),
    'X <a href="URL">I &amp; Z</a> A.',
    'embedded methods in output,url’s simple form'
);

is(
    $lh->maketext('Y [output,strong,Hellosub(Z)Qsup(Y)Qchr(42)Qnumf(1)] Z'),
    'Y <strong>Hello<sub>Z</sub>Q<sup>Y</sup>Q*Q1</strong> Z',
    'Embedded methods: sub(), sup(), chr(), and numf()'
);

is( $lh->maketext('X [asis,Truth amp() Justice] A.'), 'X Truth &amp; Justice A.', 'embedded amp()' );

# arbitrary attribute key/value args

is( $lh->maketext('[output,inline,Foo Bar]'),         '<span>Foo Bar</span>',           'output inline() standard' );
is( $lh->maketext('[output,inline,Foo Bar,baz,wop]'), '<span baz="wop">Foo Bar</span>', 'ouput inline() w/ arbitrary attributes' );
is( $lh->maketext( '[output,inline,Foo Bar,baz,wop,_1]', { a => 1 } ), '<span baz="wop" a="1">Foo Bar</span>', 'ouput inline() w/ arbitrary attributes + hashref' );
is( $lh->maketext( '[output,inline,Foo Bar,_1]',         { a => 1 } ), '<span a="1">Foo Bar</span>',           'ouput inline() w/ hashref' );

is( $lh->maketext('[output,attr,Foo Bar]'),         '<span>Foo Bar</span>',           'output attr() standard' );
is( $lh->maketext('[output,attr,Foo Bar,baz,wop]'), '<span baz="wop">Foo Bar</span>', 'ouput attr() w/ arbitrary attributes' );
is( $lh->maketext( '[output,attr,Foo Bar,baz,wop,_1]', { a => 1 } ), '<span baz="wop" a="1">Foo Bar</span>', 'ouput attr() w/ arbitrary attributes + hashref' );
is( $lh->maketext( '[output,attr,Foo Bar,_1]',         { a => 1 } ), '<span a="1">Foo Bar</span>',           'ouput attr() w/ hashref' );

is( $lh->maketext('[output,block,Foo Bar]'),         '<div>Foo Bar</div>',           'output block() standard' );
is( $lh->maketext('[output,block,Foo Bar,baz,wop]'), '<div baz="wop">Foo Bar</div>', 'ouput block() w/ arbitrary attributes' );
is( $lh->maketext( '[output,block,Foo Bar,baz,wop,_1]', { a => 1 } ), '<div baz="wop" a="1">Foo Bar</div>', 'ouput block() w/ arbitrary attributes + hashref' );
is( $lh->maketext( '[output,block,Foo Bar,_1]',         { a => 1 } ), '<div a="1">Foo Bar</div>',           'ouput inline() w/ hashref' );

is( $lh->maketext('[output,sup,Foo Bar]'),         '<sup>Foo Bar</sup>',           'output sup() standard' );
is( $lh->maketext('[output,sup,Foo Bar,baz,wop]'), '<sup baz="wop">Foo Bar</sup>', 'ouput sup() w/ arbitrary attributes' );
is( $lh->maketext( '[output,sup,Foo Bar,baz,wop,_1]', { a => 1 } ), '<sup baz="wop" a="1">Foo Bar</sup>', 'ouput sup() w/ arbitrary attributes + hashref' );
is( $lh->maketext( '[output,sup,Foo Bar,_1]',         { a => 1 } ), '<sup a="1">Foo Bar</sup>',           'ouput sup() w/ hashref' );

is( $lh->maketext('[output,sub,Foo Bar]'),         '<sub>Foo Bar</sub>',           'output sub() standard' );
is( $lh->maketext('[output,sub,Foo Bar,baz,wop]'), '<sub baz="wop">Foo Bar</sub>', 'ouput sub() w/ arbitrary attributes' );
is( $lh->maketext( '[output,sub,Foo Bar,baz,wop,_1]', { a => 1 } ), '<sub baz="wop" a="1">Foo Bar</sub>', 'ouput sub() w/ arbitrary attributes + hashref' );
is( $lh->maketext( '[output,sub,Foo Bar,_1]',         { a => 1 } ), '<sub a="1">Foo Bar</sub>',           'ouput sub() w/ hashref' );

is( $lh->maketext('[output,strong,Foo Bar]'),         '<strong>Foo Bar</strong>',           'output strong() standard' );
is( $lh->maketext('[output,strong,Foo Bar,baz,wop]'), '<strong baz="wop">Foo Bar</strong>', 'ouput strong() w/ arbitrary attributes' );
is( $lh->maketext( '[output,strong,Foo Bar,baz,wop,_1]', { a => 1 } ), '<strong baz="wop" a="1">Foo Bar</strong>', 'ouput strong() w/ arbitrary attributes + hashref' );
is( $lh->maketext( '[output,strong,Foo Bar,_1]',         { a => 1 } ), '<strong a="1">Foo Bar</strong>',           'ouput strong() w/ hashref' );

is( $lh->maketext('[output,em,Foo Bar]'),         '<em>Foo Bar</em>',           'output em() standard' );
is( $lh->maketext('[output,em,Foo Bar,baz,wop]'), '<em baz="wop">Foo Bar</em>', 'ouput em() w/ arbitrary attributes' );
is( $lh->maketext( '[output,em,Foo Bar,baz,wop,_1]', { a => 1 } ), '<em baz="wop" a="1">Foo Bar</em>', 'ouput em() w/ arbitrary attributes + hashref' );
is( $lh->maketext( '[output,em,Foo Bar,_1]',         { a => 1 } ), '<em a="1">Foo Bar</em>',           'ouput em() w/ hashref' );

is( $lh->maketext('[output,abbr,FoBa.,Foo Bar]'),         '<abbr title="Foo Bar">FoBa.</abbr>',           'output abbr() standard' );
is( $lh->maketext('[output,abbr,FoBa.,Foo Bar,baz,wop]'), '<abbr title="Foo Bar" baz="wop">FoBa.</abbr>', 'ouput abbr() w/ arbitrary attributes' );
is( $lh->maketext( '[output,abbr,FoBa.,Foo Bar,baz,wop,_1]', { a => 1 } ), '<abbr title="Foo Bar" baz="wop" a="1">FoBa.</abbr>', 'ouput abbr() w/ arbitrary attributes + hashref' );
is( $lh->maketext('[output,abbr,FoBa.,Foo Bar,baz,wop,title,wrong]'), '<abbr title="Foo Bar" baz="wop">FoBa.</abbr>', 'ouput abbr() w/ arbitrary attributes - title ignored' );
is( $lh->maketext( '[output,abbr,FoBa.,Foo Bar,baz,wop,_1]', { a => 1, title => 'wrong' } ), '<abbr title="Foo Bar" baz="wop" a="1">FoBa.</abbr>', 'ouput abbr() w/ arbitrary attributes + hashref - title ignored' );
is( $lh->maketext( '[output,abbr,FoBa.,Foo Bar,_1]', { a => 1 } ), '<abbr title="Foo Bar" a="1">FoBa.</abbr>', 'ouput abbr() w/ hashref' );

is( $lh->maketext('[output,acronym,FB,Foo Bar]'),         '<abbr title="Foo Bar" class="initialism">FB</abbr>',           'output acronym() standard' );
is( $lh->maketext('[output,acronym,FB,Foo Bar,baz,wop]'), '<abbr title="Foo Bar" baz="wop" class="initialism">FB</abbr>', 'ouput acronym() w/ arbitrary attributes' );
is( $lh->maketext( '[output,acronym,FB,Foo Bar,baz,wop,_1]', { a => 1 } ), '<abbr title="Foo Bar" baz="wop" a="1" class="initialism">FB</abbr>', 'ouput acronym() w/ arbitrary attributes + hashref' );
is( $lh->maketext('[output,acronym,FB,Foo Bar,baz,wop,title,wrong]'), '<abbr title="Foo Bar" baz="wop" class="initialism">FB</abbr>', 'ouput acronym() w/ arbitrary attributes - title ignored' );
is( $lh->maketext( '[output,acronym,FB,Foo Bar,baz,wop,_1]', { a => 1, title => 'wrong' } ), '<abbr title="Foo Bar" baz="wop" a="1" class="initialism">FB</abbr>', 'ouput acronym() w/ arbitrary attributes + hashref - title ignored' );
is( $lh->maketext( '[output,acronym,FB,Foo Bar,_1]', { a => 1 } ), '<abbr title="Foo Bar" a="1" class="initialism">FB</abbr>', 'ouput acronym() w/ hashref' );

is( $lh->maketext('[output,acronym,FB,Foo Bar,class,fiddle]'), '<abbr title="Foo Bar" class="initialism fiddle">FB</abbr>', 'ouput acronym() does initialism class on arb arg' );
is( $lh->maketext( '[output,acronym,FB,Foo Bar,_1]', { class => "faddle" } ), '<abbr title="Foo Bar" class="initialism faddle">FB</abbr>', 'ouput acronym() does initialism class on arb args and arb hash' );
is( $lh->maketext( '[output,acronym,FB,Foo Bar,class,fiddle,_1]', { class => "faddle" } ), '<abbr title="Foo Bar" class="initialism fiddle" class="initialism faddle">FB</abbr>', 'ouput acronym() does initialism class w/ both arb args and arb hash' );

is( $lh->maketext('[output,underline,Foo Bar]'),         '<span style="text-decoration: underline">Foo Bar</span>',           'output inline() standard' );
is( $lh->maketext('[output,underline,Foo Bar,baz,wop]'), '<span style="text-decoration: underline" baz="wop">Foo Bar</span>', 'ouput underline() w/ arbitrary attributes' );
is( $lh->maketext( '[output,underline,Foo Bar,baz,wop,_1]', { a => 1 } ), '<span style="text-decoration: underline" baz="wop" a="1">Foo Bar</span>', 'ouput underline() w/ arbitrary attributes + hashref' );
is( $lh->maketext( '[output,inline,Foo Bar,_1]', { a => 1 } ), '<span a="1">Foo Bar</span>', 'ouput inline() w/ hashref' );

is( $lh->maketext('[output,img,SRC]'),             '<img src="SRC" alt="SRC"/>',           'output img() - no alt' );
is( $lh->maketext('[output,img,SRC,_1]'),          '<img src="SRC" alt="SRC"/>',           'output img() - ALT arg missing i.e. undef()' );
is( $lh->maketext('[output,img,SRC,]'),            '<img src="SRC" alt="SRC"/>',           'output img() - ALT empty string' );
is( $lh->maketext('[output,img,SRC,ALT]'),         '<img src="SRC" alt="ALT"/>',           'output img() - w/ ALT' );
is( $lh->maketext('[output,img,SRC,ALT,baz,wop]'), '<img src="SRC" alt="ALT" baz="wop"/>', 'output img() - w/ arbitrary attributes' );
is( $lh->maketext( '[output,img,SRC,ALT,baz,wop,_1]', { a => 1 } ), '<img src="SRC" alt="ALT" baz="wop" a="1"/>', 'output img() - w/ arbitrary attributes + hashref' );
is( $lh->maketext('[output,img,SRC,ALT,baz,wop,src,wrong,alt,wrong]'), '<img src="SRC" alt="ALT" baz="wop"/>', 'output img() - w/ arbitrary attributes - alt, src ignored' );
is( $lh->maketext( '[output,img,SRC,ALT,baz,wop,_1]', { a => 1, src => 'wrong', alt => 'wrong' } ), '<img src="SRC" alt="ALT" baz="wop" a="1"/>', 'output img() - w/ arbitrary attributes + hash - alt, src ignored' );
is( $lh->maketext( '[output,img,SRC,ALT,_1]', { a => 1 } ), '<img src="SRC" alt="ALT" a="1"/>', 'output img() w/ hashref' );

is( $lh->maketext('[output,url,http://foo,href,FOO,bar,baz]'),        '<a bar="baz" href="http://foo">http://foo</a>', 'output,url no text: ignored href passed in' );
is( $lh->maketext('[output,url,http://foo,IMTEXT,href,FOO,bar,baz]'), '<a bar="baz" href="http://foo">IMTEXT</a>',     'output,url w/ text: ignored href passed in' );

# output,url-trailing-var ambiguity
is( $lh->maketext( "[output,url,_1,I AM TEXT,title,imatitle,attr,_2]", "http://search.cpan.org", "what am i" ), '<a title="imatitle" attr="what am i" href="http://search.cpan.org">I AM TEXT</a>', "output,url-trailing-var ambiguity: link text end var string" );
is( $lh->maketext( "[output,url,_1,I AM TEXT,title,imatitle,attr,imaattr,_2]", "http://search.cpan.org", { "attr_x" => "what am i" } ), '<a title="imatitle" attr="imaattr" attr_x="what am i" href="http://search.cpan.org">I AM TEXT</a>', "output,url-trailing-var ambiguity: link text end var hash" );
is( $lh->maketext( "[output,url,_1,title,imatitle,attr,_2]", "http://search.cpan.org", "what am i" ), '<a title="imatitle" attr="what am i" href="http://search.cpan.org">http://search.cpan.org</a>', "output,url-trailing-var ambiguity: no link text end var string" );
is( $lh->maketext( "[output,url,_1,title,imatitle,attr,imaattr,_2]", "http://search.cpan.org", { "attr_x" => "what am i" } ), '<a title="imatitle" attr="imaattr" attr_x="what am i" href="http://search.cpan.org">http://search.cpan.org</a>', "output,url-trailing-var ambiguity: no link text end var hash" );
is( $lh->maketext( "[output,url,_1,I AM TEXT,title,imatitle,attr,val]", "http://search.cpan.org" ), '<a title="imatitle" attr="val" href="http://search.cpan.org">I AM TEXT</a>', "output,url-trailing-var ambiguity: link text end string" );
is( $lh->maketext( "[output,url,_1,title,imatitle,attr,val]", "http://search.cpan.org" ), '<a title="imatitle" attr="val" href="http://search.cpan.org">http://search.cpan.org</a>', "output,url-trailing-var ambiguity: no link text end string" );
is( $lh->maketext( "[output,url,_1,I AM TEXT,_2]", "http://search.cpan.org", "what am i" ), '<a I AM TEXT="what am i" href="http://search.cpan.org">http://search.cpan.org</a>', "output,url-trailing-var ambiguity: link text, end var (indicated caller mistake, pass a hash!)" );
is( $lh->maketext( "[output,url,_1,I AM TEXT,_2]", "http://search.cpan.org", { "attr_x" => "what am i" } ), '<a attr_x="what am i" href="http://search.cpan.org">I AM TEXT</a>', "output,url-trailing-var ambiguity: link text, end hash" );
is( $lh->maketext( "[output,url,_1,_2]", "http://search.cpan.org", "what am i" ), '<a href="http://search.cpan.org">what am i</a>', "output,url-trailing-var ambiguity: no link text, end var (indicated caller mistake, pass a hash!)" );
is( $lh->maketext( "[output,url,_1,_2]", "http://search.cpan.org", { "attr_x" => "what am i" } ), '<a attr_x="what am i" href="http://search.cpan.org">http://search.cpan.org</a>', "output,url-trailing-var ambiguity: no link text, end hash" );
is( $lh->maketext( "[output,url,_1,I AM TEXT]", "http://search.cpan.org", "what am i" ), '<a href="http://search.cpan.org">I AM TEXT</a>', "output,url-trailing-var ambiguity: end link test" );

#### context ##

delete $lh->{'-t-STDIN'};
like( $lh->get_context(), qr/(?:html|ansi|plain)/, 'get_context() returns context' );
ok( exists $lh->{'-t-STDIN'}, 'get_context() sets context if needed' );

for my $type ( qw(html ansi plain), "xustom-$$" ) {
    my $set = sub {
        is( $lh->set_context($type), $type, "set_context($type) returns context" );
        is( $lh->set_context( $type, 1 ), '', "set_context($type,1) returns empty string" );
    };

    if ( $type eq "xustom-$$" ) {
        warnings_like { $set->() }[ qr/Given context .* is unknown/, qr/Given context .* is unknown/ ], "Unknown context throws warning";
    }
    else {
        $set->();
    }

    is( $lh->get_context(), $type, "get_context() returns $type" );
    ok( $lh->context_is($type), "context_is($type) returns true under $type" );

    for my $xtype (qw(html ansi plain)) {
        my $meth = "context_is_$xtype";
        if ( $type eq $xtype ) {
            ok( $lh->$meth(), "$meth() returns true under $type" );
        }
        else {
            ok( !$lh->$meth(), "$meth() returns false under $type" );
        }
    }

    for my $xype ( sort keys %context ) {
        next if $xype eq $type;
        ok( !$lh->context_is($xype), "context_is($xype) returns false under $type" );
    }
}

is( $lh->set_context_html(), "xustom-$$", 'set_context_html() returns previous context' );
ok( $lh->context_is('html'), 'set_context_html() sets context to html' );

is( $lh->set_context_ansi(), 'html', 'set_context_ansi() returns previous context' );
ok( $lh->context_is('ansi'), 'set_context_ansi() sets context to ansi' );

is( $lh->set_context_plain(), 'ansi', 'set_context_plain() returns previous context' );
ok( $lh->context_is('plain'), 'set_context_plain() sets context to plain' );

$lh->set_context('plain');
is( $lh->maketext_html_context('X [output,strong,Y] z.'), 'X <strong>Y</strong> z.', 'maketext_html_context() does html context' );
is( $lh->get_context(), 'plain', 'maketext_html_context() does not reset context' );

is( $lh->maketext_ansi_context('X [output,strong,Y] z.'), "X \e[1mY\e[0m z.", 'maketext_ansi_context() does ansi context' );
is( $lh->get_context(),                                   'plain',            'maketext_ansi_context() does not reset context' );

$lh->set_context('html');
is( $lh->maketext_plain_context('X [output,strong,Y] z.'), 'X Y z.', 'maketext_plain_context() does plain context' );
is( $lh->get_context(),                                    'html',   'maketext_plain_context() does not reset context' );
