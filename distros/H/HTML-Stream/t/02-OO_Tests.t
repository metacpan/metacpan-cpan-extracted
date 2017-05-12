
#use Test::More tests=>19;
use Test::More qw(no_plan);
use HTML::Stream;



# Test if we have all the normal stuff we are supposed to.
my $HTML = new HTML::Stream \*STDOUT;

# The directly defined methods.
can_ok($HTML, qw(auto_escape auto_format comment ent io nl tag t text text_nbsp
				output accept_tag private_tags set_tag tags
				));

# Check that we say we accept the 'historic' tag list by default.
# (The historic tag list is the list of all tags in HTML 4 plus other common tags.)
my @tags = $HTML->tags();
@tags = sort @tags;
my @historic_tags = qw(A ABBR ACRONYM ADDRESS APPLET AREA B BASE BASEFONT BDO
						BGSOUND BIG BLINK BLOCKQUOTE BODY BR BUTTON CAPTION 
						CENTER CITE CODE COL COLGROUP COMMENT DD DEL DFN DIR 
						DIV DL DT EM EMBED FIELDSET FONT FORM FRAME FRAMESET 
						H1 H2 H3 H4 H5 H6 HEAD HR HTML I IFRAME IMG INPUT INS 
						ISINDEX KBD KEYGEN LABEL LEGEND LI LINK LISTING MAP 
						MARQUEE MENU META NEXTID NOBR NOEMBED NOFRAME NOFRAMES NOSCRIPT 
						OBJECT OL OPTGROUP OPTION P PARAM PLAINTEXT PRE Q SAMP 
						SCRIPT SELECT SERVER SMALL SPAN STRIKE STRONG STYLE 
						SUB SUP TABLE TBODY TD TEXTAREA TFOOT TH THEAD TITLE 
						TR TT U UL VAR WBR XMP
					);

is_deeply (\@tags, \@historic_tags, "Tags List");

# Check that we can add tags as needed...
$HTML->accept_tag('DSTAAL');
push @historic_tags, 'DSTAAL';
@historic_tags = sort @historic_tags;
@tags = $HTML->tags();
@tags = sort @tags;
is_deeply (\@tags, \@historic_tags, "Tags List");


# Skip tests if we can't run them.
SKIP: {
 	eval { require Test::Output };
	skip "Test::Output is needed for OO tests to run.", 16 if $@;
	Test::Output->import();

	# Check that some of these tags actually work as expected...
	stdout_is( sub { $HTML->ABBR }, "<ABBR>" );
	stdout_is( sub { $HTML->ABBR->_ABBR }, "<ABBR></ABBR>" );
	stdout_is( sub { $HTML->A(HREF=>'mailto:DSTAAL@USA.NET') }, '<A HREF="mailto:DSTAAL@USA.NET">' );
	stdout_is( sub { $HTML->ADDRESS->_ADDRESS }, "<ADDRESS>\n</ADDRESS>\n" );
	stdout_is( sub { $HTML->AREA->_AREA }, "<AREA></AREA>\n" );
	stdout_is( sub { $HTML->BR->_BR }, "<BR>\n</BR>" );
	stdout_is( sub { $HTML->BUTTON->_BUTTON }, "\n<BUTTON></BUTTON>" );
	stdout_is( sub { $HTML->H1->_H1 }, "<H1></H1>\n" );
	stdout_is( sub { $HTML->TR(NOWRAP=>undef)->_TR }, "\n<TR NOWRAP></TR>\n" );
	
	# Check Escaping
	# (I really should be through about this, but these are the 
	# HTML _required_ escapes checked at least.)
	stdout_is( sub { $HTML->text("&") }, "&amp;" );
	stdout_is( sub { $HTML->t("<") }, "&lt;" );
	
	#Check a couple of the other methods...
	
	# 'Newline' is up first.
	stdout_is( sub { $HTML->nl }, "\n" );
	stdout_is( sub { $HTML->nl(3) }, "\n\n\n" );
	stdout_is( sub { $HTML->nl(0) }, "" );
	stdout_is( sub { $HTML->nl(-1) }, "" );
	stdout_is( sub { $HTML->nl("a") }, "" );  # This fails intentionally.
}