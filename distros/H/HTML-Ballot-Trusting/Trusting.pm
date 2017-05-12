package HTML::Ballot::Trusting;
our $VERSION = 0.2;		# Thu Jul 26 15:03:11 2001
use strict;
use warnings;
use Carp;
use HTML::Entities ();

# Later: CGI and use HTML::EasyTemplate 0.985;


our $CHAT = undef;		# Set for reports to STDERR.


=head1 NAME

HTML::Ballot::Trusting - HTML-template-based insercure multiple-choice ballot

=head1 SYNOPSIS

# Create the poll

	use HTML::Ballot::Trusting;
	$HTML::Ballot::Trusting::CHAT = 3;
	my $p = new HTML::Ballot::Trusting {
		ARTICLE_ROOT => 'E:/www/leegoddard_com',
		URL_ROOT 	=> 'http://localhost/leegoddard_com',
		RPATH 	 => 'E:/www/leegoddard_com/vote/results.html',
		TPATH	 => 'E:/www/leegoddard_com/vote/template.html',
		QPATH	 =>	'E:/www/leegoddard_com/vote/vote.html',
		CPATH 	 => 'E:/www/leegoddard_com/CGI_BIN/vote.pl',
		ASKNAMES => 1,
		QUESTIONS => [
			'Why?',
			'Why not?',
			'Only for £300.'
		]
	};
	$p->create();

=head1 DESCRIPTION

A simple module for inseucre web ballots.

This is a very beta version that will mature over the
next week or so.  Please let me know how it breaks.

Features:

=over 4

=item *

no test is made of who is voting, so users may vote any number of
times, or may even vote (and surely will) thousands of times using a
"LWP" hack.

=item *

a HTML page of voting options and one of the results of votes so far
is generated from a single HTML template, and it is in these pages
that ballot status is maintained, so no additional file access is
required.

=item *

HTML output into the template is minimal, but all unique entities
are given a "class" attribute for easy CSS re-definitions.

=item *

simple bar charts of results are generated using HTML.

=item *

users may submit a comment with thier vote, though no connection
between the value of the vote and the user is recorded

=item *

users' IP addresses may be recorded, and displayed, and a chart
of the IP addresses from which communication has been received
the most may be displayed.

=back

In future these features may be added:

=over 4

=item *

A more secure version is being considered, which uses
simple e-mail authentication of users, sending ony one voting
password to any e-mail address: this may appear as
"HTML::Ballot::MoreCynical".

=item *

This may be extended to include a ballot `time out'.

=item *

Options to have graphs based on single-pixels, or using the "GD"
interface will arrive some time in the future.

=back

=head1 USE

=over 4

=item 1.

Construct an HTML template that can be used to generate the question
and answer pages.  Where you wish the questions and answers to
appear, insert the following element:

	<TEMPLATEITEM name='QUESTIONS'></TEMPLATEITEM>

The template should at least define the CSS representation for
C<votehighscorebar> and C<votebar> as having a coloured background,
or you will not be able to view the results' bar graph.
See L</CSS SPECIFICATION> for more details on other CSS classes
employed.

Other functions may be included as below. Note that C<TEMPLATEITEM>s
may require some minimal content of at least a space character, I'm
not sure, I'd better check.

=over 4

=item *

If you wish to allow a user to submit a comment with their vote,
include the following element:

	<TEMPLATEITEM name='COMMENT'>
		This is what voter's have said:
	</TEMPLATEITEM>

Unlike the C<QUESTIONS TEMPLATEITEM>, any text you include	in this
block will be reatained at the top of a list of users' comments.

=item *

If you wish to have the result page display a list of the names
entered by voters, also include:

	<TEMPLATEITEM name='VOTERLIST'>
		Here is the voterlist...
	</TEMPLATEITEM>

This acts in the manner of the C<COMMENT TEMPLATEITEM>, above.

=item *

If you wish to have the result page display a list of the most
frequently-posting IP addresses, include:

	<TEMPLATEITEM name='IPCHART'>
		<H2>Top IP Addresses To Post To This Ballot</H2>
	</TEMPLATEITEM>

To this, the module will add a C<SPAN> of HTML that lists the
top posters.  Anything before that span (in this example,
the C<H2> element) will remain.

=back

=item 2.

Initiate the ballot by constructnig an HTML::Ballot::Trusting object and
calling C<create> method upon it in a manner simillar to that described
in L</SYNOPSIS>.

In response, you should receive a list of the locations of files used and
dynamically created by the process.

=back

=head1 GLOBAL VARIABLES

Several global variables exist as system defaults.  Most may be over-riden
using the constructor (see the sections C<ARTICLE_ROOT>, C<URL_ROOT>,
C<STARTGRAPHIC>, C<SHEBANG> in L</CONSTRUCTOR (new)>.>

=cut

#
# These defaults can be over-ridden by using their
# names as values in the hash passed to the constructor
#
our $ARTICLE_ROOT 	= 'E:/www/leegoddard_com';
our $URL_ROOT 		= 'http://localhost/leegoddard_com';
our $STARTGRAPHIC 	= "STARTGRAPHICHERE__";
our $STARTPC		= "STARTPCHERE__";
our $SHEBANG		= '';
our $ASKNAMETEXT	= 'Your name, please';
our $ASKCOMMENTTEXT	= 'Optionally, your comment optional';
our $MAXTOTALCOMMENTLENGTH = 2000000;	# Maxium size of all comment mark up permitted

=item IPCHART

THe number of items to include in the IP chart of frequent posters

=cut

our $IPCHART 		= 5;

=head1 CONSTRUCTOR (new)

Requires a reference to the class into which to bless, as well
as a hash (or reference to such) with the following key/value
content:

=over 4

=item ARTICLE_ROOT

the root, in the filesystem, where these HTML pages begin - can over-ride the global constant of the same name;

=item URL_ROOT

the root, on the internet, where these HTML pages begin - can over-ride the global constant of the same name;

=item QUESTIONS

an array of questions to use in the ballot

=item TPATH

Path at which the HTML Template may be found

=item QPATH

Path at which to save the HTML ballot Questions' page

=item RPATH

Path at which to save the HTML Results page

=item CPATH

If you do not use the C<SUBMITTO> attribute (below), you must use this: Path at
which to save a dynamically-generated perl script that processes
form submissions. Obviously must be CGI accessible and CHMOD appropriately.

=item SUBMITTO

If you do not use the C<CPATH> attribute (above), you must use this:
Path to the script that processes submission of the CGI voting form

=item SHEBANG

Represents the Shebang line you place at the start of your perl scrpts:
set this to over-ride the default value taken from the global constant scalar
of the same name.  Could adjust this to suss the path from C<Config.pm> or
even C<MakeMaker>, if it came to it, but time....

=item COMMENTLENGTH

Maximum acceptable length of text comments.

=item ASKNAMES

Set if users should supply their name when voting.

=item NAMELENGTH

If C<ASKNAMES> (above) is defined, this value may be set to
limit the possible length of a name.

=back

=cut

sub new {
	my $class = shift or die "Called without class";
	my %args;
	my $self = {};
	bless $self,$class;

	# Default instance variables
	$self->{ARTICLE_ROOT} 	= $ARTICLE_ROOT;
	$self->{URL_ROOT} 		= $URL_ROOT;
	$self->{COMMENTLENGTH}	= 75;
	$self->{NAMELENGTH}		= 30;

	# Take parameters and place in object slots/set as instance variables
	if (ref $_[0] eq 'HASH'){	%args = %{$_[0]} }
	elsif (not ref $_[0]){		%args = @_ }

	# Overwrite default instance variables with user's values
	foreach (keys %args) { $self->{uc $_} = $args{$_} }
	undef %args;

	# Calling-paramter error checking
	croak "Template path TPATH does not exist" if exists $self->{TPATH} and not -e $self->{TPATH};
	croak "No RPATH" if not exists $self->{RPATH} and not defined $self->{RPATH};

	return $self;
} # End sub new



=head1 METHODS

=head2 METHOD create

Creates the HTML voting page.

Accepts: just the calling object: all properties used should be set
during construction (see L</CONSTRUCTOR (new)>).

If the page contains a C<COMMENT TEMPLATEITEM>, will include a text box
in the voting page, to allow users to submit comments.  Setting
C<COMMENTLENGTH> to a value when calling the constructor will
restrict the length of acceptable comments.

If the page contains a <VOTERLIST TEMPLATEITEM>, this will be updated
with the name supplied by the user.

Returns: the path to the saved HTML question document.

See also L</USE> and L</CSS SPECIFICATION>.

=item QUESTION PAGE

The C<action> attribute of the C<FORM> element is set to the CGI
environment variable, C<SCRIPT_NAME> (that is, the location of this script).

Form elements are simply seperated by linebreaks (C<BR>): use CSS to control
the layout: the radio-button HTML elements are set to be class C<voteoption>;
the C<SUBMIT> button element is set to be class C<votesubmit>.

=item RESULTS PAGE

HTML is used to create bar charts, but this should be easy to replace with
a C<GD> image, or a stretched single-pixel.  Each question is given a
C<TEMPLATEITEM> element, and results will be placed within by the C<vote>
method (see L</METHOD vote>).

See also L<CSS SPECIFICATION>.

=cut

sub create { my $self = shift;
	local *OUT;
	my %template_items;
	my $form_processing_url ;
	croak "No path to HTML template" if not exists $self->{TPATH} or not defined $self->{TPATH};
	croak "No path to save HTML at" if not exists $self->{QPATH} or not defined $self->{QPATH};
	croak "No questions" if not exists $self->{QUESTIONS} or not defined $self->{QUESTIONS};
	if ((not exists $self->{SUBMITTO} or not defined $self->{SUBMITTO})
	and (not exists $self->{CPATH} or not defined $self->{CPATH})){
		croak "No SUBMITTO or CPATH value defined - one or the other is required"
	}

	use HTML::EasyTemplate 0.985;

	# Create question poll page QPATH #############################################
	#
	# Create radio button HTML from questions
	my $TEMPLATE = new HTML::EasyTemplate(
		{	ADD_TAGS => 1,
			SOURCE_PATH => $self->{TPATH},
			ARTICLE_ROOT => $self->{ARTICLE_ROOT},
			URL_ROOT => $self->{URL_ROOT},
		});
	$TEMPLATE -> process('collect');					# Collect the values

	# Where should the form ACTION point? Set now so can use TEMPLATE methods
	if (exists $self->{CPATH}){
		$form_processing_url = $TEMPLATE->set_article_url($self->{CPATH});
	} else {
		$form_processing_url = $self->{SUBMITTO}
	}

	# Construct form
	my $qhtml =	"<form name=\"".__PACKAGE__."\" method=\"post\" action=\"$form_processing_url\" ";
	$qhtml .= "onSubmit=\"";
	$qhtml .= "if (this.usrcomment.value=='$ASKCOMMENTTEXT'){this.usrcomment.value=''}";
	$qhtml .= "if (this.usrname.value==''){alert('Please, please, please enter your name.... it will not be recorded against your vote');this.usrname.focus();return false;}";
	$qhtml .= "if (this.usrname.value=='$ASKNAMETEXT'){alert('Please enter your name.. It will not be recorded against your vote');this.usrname.focus();return false;}";
	$qhtml .= "return true;";
	$qhtml .= "\">\n";

	foreach (@{$self->{QUESTIONS}}) {
		$_ = HTML::Entities::encode($_);
 		$qhtml .= "<input class=\"voteoptionradio\" type=\"radio\" name=\"question\" value=\"$_\"><SPAN class=\"voteoptiontext\">$_</SPAN></input><BR>\n";
	}
	$qhtml.="<INPUT type=\"HIDDEN\" name=\"rpath\" value=\"$self->{RPATH}\">\n";

	# Add name input field if appropriate
	if (exists $self->{ASKNAMES}){
		$qhtml.="<INPUT name=\"usrname\" value=\"$ASKNAMETEXT\" onFocus=\"this.value=''\" class=\"votenametextbox\" type=\"TEXT\" MAXLENGTH=\"$self->{NAMELENGTH}\" SIZE=\"40\">\n";
	}

	# Add comment input field if comment output area is defined:
	if (exists $TEMPLATE->{TEMPLATEITEMS}->{COMMENT} and defined $TEMPLATE->{TEMPLATEITEMS}->{COMMENT}){
		$qhtml.="<INPUT name=\"usrcomment\" value=\"$ASKCOMMENTTEXT\" onFocus=\"this.value=''\" class=\"votecommenttextbox\" type=\"TEXT\" MAXLENGTH=\"$self->{COMMENTLENGTH}\" SIZE=\"40\">\n";
	}

	$qhtml.="<INPUT type=\"SUBMIT\" class=\"voteoptionsubmit\" value=\"Cast Vote\">\n</FORM>\n";
	$template_items{QUESTIONS} 	= $qhtml;				# Make new values, for example:
	$TEMPLATE -> process('fill', \%template_items );	# Add them to the page
	$TEMPLATE -> save($self->{QPATH});

	# Create initial results page RPATH template ####################################
	#
	my $rhtml = "<DIV class=\"voteresults\">\n<TABLE width=\"100%\">\n";
	foreach (@{$self->{QUESTIONS}}) {
		$rhtml .= "<TR>\n<TD class=\"votequestion\" align=\"left\" nowrap width=\"25%\">$_</TD>\n\t";
		$rhtml .= "<TD class=\"votescore\" align=\"right\"><TEMPLATEITEM name=\"$_\">0</TEMPLATEITEM></TD>\n";
		$rhtml .= "<TD class=\"votepc\" nowrap align=\"right\"><TEMPLATEITEM name=\"$STARTPC$_\">0%</TEMPLATEITEM></TD>\n";
		$rhtml .= "<TD class=\"chart\" width=\"75%\" align=\"left\"><TEMPLATEITEM name=\"$STARTGRAPHIC$_\">No votes yet cast.</TEMPLATEITEM></TD>\n";
		$rhtml .= "</TR>\n";
	}
	$rhtml .= "</TABLE>\n</DIV>\n";

	$TEMPLATE = new HTML::EasyTemplate(
		{	ADD_TAGS => 1,
			SOURCE_PATH => $self->{TPATH},
			ARTICLE_ROOT => $self->{ARTICLE_ROOT},
			URL_ROOT => $self->{URL_ROOT},
		});
	$TEMPLATE -> process('collect');					# Collect the values

	$template_items{QUESTIONS} 	= $rhtml;				# Make new values, for example:

	if (exists $TEMPLATE->{TEMPLATEITEMS}->{COMMENT} and defined $TEMPLATE->{TEMPLATEITEMS}->{COMMENT}){
		#die "<XMP>",$TEMPLATE->{TEMPLATEITEMS}->{COMMENT},"</XMP>";
		$template_items{COMMENT} = $TEMPLATE->{TEMPLATEITEMS}->{COMMENT};
	}
	if (exists $TEMPLATE->{TEMPLATEITEMS}->{VOTERLIST}){
		$template_items{VOTERLIST} =  $TEMPLATE->{TEMPLATEITEMS}->{VOTERLIST};
	}
	# Add IP chart if requested
	if (exists $TEMPLATE->{TEMPLATEITEMS}->{IPCHART} ){
		$template_items{IPCHART} = $TEMPLATE->{TEMPLATEITEMS}->{IPCHART}
	}
	$TEMPLATE -> process('fill', \%template_items );	# Add them to the page
	$TEMPLATE -> save($self->{RPATH});

	# Create the script to submit the form ##########################################
	# Could have this sciprt's functionality within the module, checking for CGI
	# param on every calling, and that may be more economical, but is less clean.
	$_ = scalar __PACKAGE__;
	my $Perl =<<EOPERL;

$SHEBANG
\# Caller script located at $self->{CPATH} ($form_processing_url)
\# Dynamically generated by and for $_ :: create

use HTML::Ballot::Trusting;
use CGI;
our \$cgi = new CGI;
if (\$cgi->param() and \$cgi->param('question') and \$cgi->param('rpath') ){
	\$v = new HTML::Ballot::Trusting ( {RPATH=>\$cgi->param('rpath')});
	\$v->cast_vote( \$cgi->param('question'),\$cgi->param('usrcomment'),\$cgi->param('usrname') );
} else {print "Location: $form_processing_url\\n\\n\\n";}
exit;

EOPERL

	open OUT, ">$self->{CPATH}" or croak "Could not open <$self->{CPATH}> for writing";
	print OUT $Perl;
	close OUT;

	# Report #######################################################################
	print "Created poll.\n",
		"Calling-script at: $self->{CPATH}\n",
		"HTML template at: $self->{TPATH}\n",
		"Qustion HTML is at: $self->{QPATH}\n",
		"Results HTML is at: $self->{RPATH}\n\n";

	return 1;
}




=head2 METHOD cast_vote

Casts a vote and updates the results file.

Accepts:

1. the question voted for, as defined in the HTML vote form's C<INPUT>/C<value>.

2. optionally, a user-submitted comment.

3. optionally, a user-submitted name.

=cut

sub cast_vote { my ($self, $q_answered,$usrcomment,$usrname) = (shift,shift,shift,shift);
	croak "No object" if not defined $self;
	croak "No answer" if not defined $q_answered;
	croak "No RPATH" if not exists $self->{RPATH};
	croak "No RPATH path to save results at" if not exists $self->{RPATH};

	@_ = split/ /,(scalar localtime); # Create the date
	my $todaydate = "$_[2] $_[1] $_[4] $_[3]";

	# Get existing results
	my $TEMPLATE = new HTML::EasyTemplate(
		{	ADD_TAGS => 1,
			SOURCE_PATH => $self->{RPATH},
			ARTICLE_ROOT => $self->{ARTICLE_ROOT},
			URL_ROOT => $self->{URL_ROOT},
			FLOCK => 1,
		});
	$TEMPLATE -> process('collect');						# Collect the values
	my %template_items = %{$TEMPLATE->{TEMPLATEITEMS}};		# Do something with them

	my %scores;												# Keyed by question
	my ($total_cast,$hi_score) = (0,0);
	# Aquire results from template
	foreach (keys %template_items){
		if ($_!~/^(VOTERLIST|IPCHART|COMMENT|\Q$STARTGRAPHIC\E|\Q$STARTPC\E)/ and $_ ne 'QUESTIONS'){
			$template_items{$_}++ if $_ eq $q_answered;
			$scores{$_} = $template_items{$_}; # Will create a warning, not-numeric, but works...:(
			$total_cast += $scores{$_};
			$hi_score = $scores{$_} if $scores{$_} > $hi_score;
		}
	}
	# Create new results
	foreach (keys %scores){
		warn "$_...$template_items{$_}\n" if $CHAT;
		my $pc = ((100 / $total_cast) * $template_items{$_} );
		$template_items{$_} = $scores{$_};
		$template_items{"$STARTGRAPHIC$_"} = '<TABLE width="100%"><TR><TD ';
		if ($scores{$_} == $hi_score){
			$template_items{"$STARTGRAPHIC$_"}.= 'class="votehighscorebar" ';
		} elsif ($scores{$_}>0) {
			$template_items{"$STARTGRAPHIC$_"}.= 'class="votebar" ';
		}
		$template_items{"$STARTGRAPHIC$_"}.= 'width="';
		if ($scores{$_}==0){
			$template_items{"$STARTGRAPHIC$_"}.='0%">';
		} else {
			$template_items{"$STARTGRAPHIC$_"} .= $pc;
			$template_items{"$STARTGRAPHIC$_"}.= '%" ';
			$template_items{"$STARTGRAPHIC$_"}.= 'bgcolor="red"' if exists $self->{NOCSS};
			$template_items{"$STARTGRAPHIC$_"}.= '>&nbsp;';
		}
		$template_items{"$STARTPC$_"} = sprintf("%.2f", $pc)."%";
		$template_items{"$STARTGRAPHIC$_"}.= '</TD><TD></TD></TR></TABLE>'."\n";
	}
	# Include user's comments
	if (defined $usrcomment and $usrcomment!~/^\s*$/g
	and length $template_items{COMMENT}<$MAXTOTALCOMMENTLENGTH		# No overstuffing of the file
	){
		$usrcomment = substr $usrcomment,$self->{COMMENTLENGTH} if length $usrcomment>$self->{COMMENTLENGTH};
		$usrcomment = HTML::Entities::encode($usrcomment);
		$template_items{COMMENT} .= "<DIV class=\"comment\"><SPAN class=\"votecommentdate\">$todaydate</SPAN><SPAN class=\"voteusrname\">$usrname</SPAN><SPAN class=\"votecommenttext\">$usrcomment</SPAN></DIV>\n";
	}

	# Include user's name
	if (exists $template_items{VOTERLIST}){
		$template_items{VOTERLIST}.="<SPAN class\"listvoteusrname\"><SPAN class=\"voteusrname\">$usrname </SPAN>";
	}
	# Include IP?
	if (exists $template_items{VOTERLIST}){
		$template_items{VOTERLIST}.="<SPAN class=\"voteusrip\">($ENV{REMOTE_HOST})</SPAN>";
	}
	# Finish user's name list
	if (exists $template_items{VOTERLIST}){
		$template_items{VOTERLIST}.="</SPAN>\n";
	}
	# Top-X IPs
	if (exists $template_items{IPCHART}){
		# Collect IP addresses from VOTERLIST
		my %ips;
		while ($template_items{VOTERLIST} =~ m/\QSPAN class="voteusrip">(\E(127.0.0.1)\Q)<\/SPAN>\E/g){
			$ips{$1}++;
		}
		# Remove previous chart (as defined below) from page
		$template_items{IPCHART} =~ s/<SPAN class="ipchart">.*//s;
		# Add the chart
		$template_items{IPCHART} .= '<SPAN class="ipchart">';
		my @ips = sort { $ips{$b} <=> $ips{$a} } keys %ips;
		for (0..$IPCHART-1){
			$template_items{IPCHART} .= "<SPAN class=\"ipchartitem\">".($_+1).": $ips[$_]</SPAN>\n";
		}
		$template_items{IPCHART} .= '</SPAN>';
	}

	$TEMPLATE -> process('fill', \%template_items );		# Add them to the page
	$TEMPLATE -> save($self->{RPATH});
	# Redirect
	print "Location: $TEMPLATE->{ARTICLE_PATH}\n\n";
	return 1;
}



1;
__END__

=head1 CSS SPECIFICATION

The following CSS classes are employed (and expected) in the HTML:

=over 4

=item C<votehighscorebar> and C<votebar>

the C<TD> within the chart (above) that represent volume of votes cast.
These B<must> be defined for results to be visable, though if the C<NOHTML>
flag is set in the constructor, a red background will be used as well.

	<style type="text/css">
	<!--
	.votebar {  background-color: #990000}
	.votebar {  background-color: red}
	-->
	</style>

=item C<chart>

the right-most C<TD>, containg the chart C<TABLE>

=item C<voteresults>

the layer of the whole results section;

=item C<votequestion>

the left-most C<TD>, containing the text representing the questions;

=item C<votescore>

the centre-left C<TD>, containing the text representing the number of votes recieved by the item;

=item C<votepc>

the centre-right C<TD>, containing the text representing the percentage of vote obtained

=item C<voteoptionradio>

The radio button in the question-asking phase.

=item C<voteoptiontext>

The text associated with radio buttons, as above.

=item C<voteoptionsubmit>

The submit button as above.

=item C<votecommenttextbox>

The text box used to accept comments.

=item C<votecommenttext>

Text associated with the textbox (above).

=item C<votecommentdate>

The date C<SPAN> of a comment.

=item C<voteusrname>

The C<SPAN> that covers a user-entered name in the report.

=item C<listvoteusrname>

The C<SPAN> that covers user-entered names and IP address in list context

=item C<voteusrname>

The C<SPAN> that covers the user name within C<listvoteusrname>.

=item C<voteusrip>

As above, but for IP address.

=item C<ipchartitem>

An item in the IP chart.

=back



=head1 SEE ALSO

L<HTML::EasyTemplate>.

=head1 AUTHOR

Lee Goddard (L<LGoddard@CPAN.org|mailto:LGoddard@CPAN.org>)

=head1 COPYRIGHT AND LICENCE

This module and all associated code is Copyright (C) Lee Goddard 2001. All rights reserved.

This is free software and may be used under the same terms as Perl itself with
the added condition that it not be used in a commercial setting, to make money,
either directly or indirectly, without the advanced and explicit prior signed
permission of the author.

=cut

