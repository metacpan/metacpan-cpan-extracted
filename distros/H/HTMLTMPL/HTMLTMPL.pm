# Bilstone html template parser
#
#		September 1999
#		Version 1.33	production
#		Author	Ian Steel	(ian@bilstone.co.uk)
#
#		For latest releases, documentation, faqs, etc see the homepage at
#			http://www.bilstone.co.uk/parser
#
#		History:
#
#			April 1999 - First cut
#			September 1999 - Added strict.
#			March 2000 - 1.20 - Allow for invisible templates.
#			March 2001 - 1.30 - Added to CPAN
#			March 2001 - 1.31 - Added getAllTokens, and srcString methods.
#			Sept. 2001 - 1.32 - Reset $/ to prior value (courtesy)
#			Oct.  2001 - 1.34 - Corrected operation of Invisible blocks.
#

package HTMLTMPL;

use strict;
use vars qw($AUTOLOAD);
use Carp;

no strict 'refs';

$HTMLTMPL::VERSION = '1.34';

sub new()
{
	my $class = shift;
	my %baseHtml = ();
	bless \%baseHtml, $class;
	return \%baseHtml
}

sub src()
{
    if ($#_ != 1)
    {
        bailout("Error! template function requires a single parameter\n");
    }

    my $self = shift;
    my $src = shift;

	my $tmp = $/;
	undef $/;
	open(HTML, "<$src") || bailout("Cannot open html template file!<br>$src");
	my $tmplString = <HTML>;
	close HTML;

	srcString($self, $tmplString);
	$/ = $tmp;
}

# If the template is within a string rather than a file, use this method to
#	populate the template object.
#
sub srcString()
{
    my $self = shift;
    my $src = shift;

    $self->{'_C__REPEAT__'} = 0;    # Not a repeating block as this is the
                                    # main html page.

    my $allToks = [];

	parseSegment($self, $allToks, $src);

	$self->{'_C__TOKLIST__'} = $allToks;	# Array of all tokens.
}

# Processes html given as third parameter.
# Adds segments to array within the given hash parameter.
#
sub parseSegment()
{
	my ($segHash, $allToks, $tmplString) = @_;

	my @segments = ();
	my $repeating = $segHash->{'_C__REPEAT__'};
	my $pos = 0;

	my ($padding, $token, $remainder);
	while ($tmplString =~ /(.*?)((__[ix]_.+?__\n)|(__.+?__))/sg)
	{
		$padding = $1;
		$token = $2;
		$remainder = $';

		$token =~ s/\n$//g;			# chomp $token (chomp bust as $/ undef'd)

		push @segments, $padding;

		$pos = pos $tmplString;

		if ($token =~ /__[ix]_.+__/)
		{
			# The start of a repeating block
			# Create a hash which is named after the repeating block.
			# Pass a reference to the hash into parseSegment (us) so that
			#	the block of repeating html is picked up and associated
			#	with this hash.
			#
			# We need to restart the search processing after the end of
			#	the repeating block.

			my $tokId = $token;
			$tokId =~ s/__[ix]_(.+)__/$1/;

			%$token = ();

			%$token->{'_C__ID__'} = $tokId;
			%$token->{'_C__REPEAT__'} = 1;

			my $block = $remainder;

			$block =~ /(.+)${token}/s;
			$block = $1;

			# Create an entry in the list of tokens for this block if we have
			# just found an 'invisible block'.
			#
			$segHash->{$token} = [] if $token =~ /^__i_/;

			push @segments, $token;
			parseSegment(\%$token, $allToks, $block);

			$pos += length($block) + length($token) + 1;
			pos $tmplString = $pos;

			next;
		}

		if (defined $token)
		{
			# This line contains a token.
			# Break up line to get out tokens, and store in array.
			#
			# my $padding = $1;
			# my $token = $2;
			my $tokId = $token;
			$tokId =~ s/__(.+)__/$1/;

			# For a repeating block, each token will have to hold an array
			# of values. For non-repeating, just a scalar.
			#
			$segHash->{$token} = ($repeating ? [] : '');

			push @segments, $token;

			push @$allToks, ($repeating ? 	
						$segHash->{'_C__ID__'} . ":" . $tokId : $tokId);
		}
	}

	pos $tmplString = $pos;
	$tmplString =~ m/(.*)/sg;

	push @segments, $1;

	$segHash->{'_C__HTML__'} = [ @segments ];
}

sub AUTOLOAD
{
	my $token = $AUTOLOAD;
	my ($self, $value, $block) = @_;

	if (defined $block)
	{
		# Self needs to refer to the repeating block now rather than this
		#	object because the user wants to store a repeating block value.
		#
		my $tmp = '__' . $block . '__';
		$self = \%$tmp;
	}

	$token =~ s/.*:://;
	my $tok = '__' . $token . '__';

	if (exists $self->{$tok})
	{
		if ($self->{"_C__REPEAT__"} == 1)
		{
			# within a block so add to array rather than storing raw value.
			#
			my $tmp = $self->{$tok};
			push @$tmp, $value;
			$self->{$tok} = [ @$tmp ];
		}
		else
		{
			$self->{$tok} = $value;
		}
	}
	else
	{
		bailout("Invalid token '$token'.<br>Maybe it needs qualifying within a " .
				"block?");
	}
}

#
#	Returns a blessed hash (the name is given as a parameter) which is in all
#	essence the invisible template object.
#
sub getBlock($)
{
	my ($self, $iBlock) = @_;
	$iBlock = "__" . $iBlock . "__";
	my $ret = bless \%$iBlock;

	# All none control entries in the hash, should be initialised.
	#
	my $repeating = $ret->{"_C__REPEAT__"};

	map {
		if (!/^_C__/)
		{
			$ret->{$_} = ($repeating ? [] : '');
		}
	} keys %$ret;

	return $ret;
}

sub output()
{
	my $self = shift;
	my $hdr;

	foreach $hdr (@_)
	{
		print "$hdr\n";
	}

	print "\n";

	print mergeData($self);
}

sub htmlString()
{
	my $self = shift;
	return mergeData($self);
}

sub mergeData()
{
	my ($leg) = @_;

	my $segs = $leg->{'_C__HTML__'};
	my $repeating = $leg->{'_C__REPEAT__'};
	my $entries = 1;

	my $htmlGen = '';						# Generated html to be output.

	if ($repeating)
	{
		# determine number of times we need to repeat putting out this
		#	segment.
		#
		my $key;
		foreach $key (keys %$leg)
		{
			next if ($key =~ /^_C__/);	# ignore control entries.

			my $tmp = $leg->{$key};
			$entries = $#$tmp;
			$entries++;
			last;
		}
	}

	my $ix;
	for ($ix=0; $ix < $entries; $ix++)
	{
		# Walk the array of html segments.
		#
		my $seg;
		foreach $seg (@$segs)
		{
			if ($seg =~ /__.*__/)			# Is it a token?
			{
				if ($seg =~ /^__x_.+__/)		# Repeating?
				{
					chomp($seg);
					# This is a repeating block rather than an individual token,
					# so process it seperately.
					#
					$htmlGen .= mergeData(\%$seg);
				}
				else
				{
					if ($repeating)
					{
						# Output next value from array for this token.
						#
						my $temp = $leg->{$seg};
						$htmlGen .= @$temp[$ix];
					}
					else
					{
						# Output token value.
						#
						$htmlGen .= $leg->{$seg};
					}
				}
			}
			else
			{
				# Straight html
				#
				$htmlGen .= $seg;
			}
		}
	}

	return $htmlGen;
}

#	Returns a ref to an array. Each element of the array contains the name of a
#	token within the template. Tokens within repeating blocks are prefixed
#	with 'block_name:'.
#
sub listAllTokens()
{
	my $self = shift;
	return $self->{'_C__TOKLIST__'};
}

# If called in a scalar context, returns a comma seperated list of tokens
#	found within the template.
# If called in array context, returns array of tokens found within the
#	template.
#
sub getAllTokens()
{
	my $self = shift;

	if (wantarray) {
		return @{$self->{'_C__TOKLIST__'}};
	}

	my $ret = ",";
	map { $ret .= "$_,"; } @{$self->{'_C__TOKLIST__'}};
	return $ret;
}

sub dumpAll()
{
	print << "EOHTML";
Content-type: text/html

<html><head><title>Dump of tokens and values</title></head>
<body bgcolor=beige>
<h3 align=center>Dump of tokens and values</h3>
<p>
<table border=1 align=center>
<tr align=center><th bgcolor=lightblue>Token</th><th colspan=2 bgcolor=lightblue>Value</th></tr>
EOHTML
	dumpit(@_);

	print "</table></body></html>";
}

sub dumpit()
{
	my ($self, $block) = @_;

	if (defined $block)
	{
		$self = \%$block if (defined $block);
	}

	my $repeating = $self->{'_C__REPEAT__'};

	if ($repeating)
	{
		my($entries);

		# Determine number of entries in block values.
		#
		my($key);
		foreach $key (keys %$self)
		{
			next if ($key =~ /^_C__/);	# ignore control entries.

			my $tmp = $self->{$key};
			$entries = $#$tmp;
			$entries++;
			last;
		}

		my($ix);
		for ($ix=0; $ix < $entries; $ix++)
		{
			my($key);
			foreach $key (keys %$self)
			{
				next if ($key =~ /^_C__/);	# ignore control entries.

				my $tmp = $self->{$key};
				print "<tr><td>$key" . "</td><td>[$ix]</td><td>@$tmp[$ix]</td><tr>\n";
			}
		}
	}
	else
	{
		# Walk the array of html segments.
		#
		my $segs = $self->{'_C__HTML__'};
		my($seg);
		foreach $seg (@$segs)
		{
			if ($seg =~ /^__.+__$/)
			{
				# dump only the tokens
				#
				if ($seg =~ /^__[ix]_.+__$/)
				{
					# repeating block so treat as seperate section
					#
					chomp $seg;
					print "<tr><td colspan=3 align=center>$seg</td></tr>\n";
					dumpit(\%$seg);
					print "<tr><td colspan=3 align=center>&nbsp;</td></tr>\n";
				}	
				else
				{
					print "<tr><td>$seg</td><td colspan=2>" . $self->{$seg} . "</td></tr>\n";
				}
			}
		}
	}

}

sub bailout()
{
	my $mess = splice @_;

	my($retVal) =<<HTML10;
content-type: text/html

<html><head></head>
<body bgcolor=red>
<p>
<font color=white>
<h3>Template Error!</h3>
<center>
$mess
</center>
</p>
<hr>
</body></html>
HTML10

	print $retVal;
	croak "Template Error : $mess";
}

sub DESTROY()
{
}
1;

__END__

=head1 NAME

HTMLTMPL - Merges runtime data with static HTML template file.

=head1 SYNOPSIS

How to merge data with a template.

The template :

 <html><head><title>parser Example 1</title></head>
 <body bgcolor=beige>
 My name is __firstname__ __surname__ but my friends call me __nickname__.
 <hr>
 </body>
 </html>

The code :

 use HTMLTMPL;

 # Create a template object and load the template source.
 $templ = new HTMLTMPL;
 $templ->src('example1.html');

 # Set values for tokens within the page
 $templ->surname('Smyth');
 $templ->firstname('Arthur');
 $templ->nickname('Art!');

 # Send the merged page and data to the web server as a standard text/html mime
 #   type document
 $templ->output('Content-Type: text/html');

Produces this output :

 <html><head><title>parser Example 1</title></head>
 <body bgcolor=beige>
 My name is Arthur Smyth but my friends call me Art!.
 <hr>
 </body>
 </html>

=head1 DESCRIPTION

In an ideal web system, the HTML used to build a web page would
be kept distinct from the application logic populating the web page.
This module tries to achieve this by taking over the chore of merging runtime
data with a static html template.

The HTMLTMPL module can address the following template scenarios :

=over 3

=item *

Single values assigned to tokens

=item *

Multiple values assigned to tokens (as in html table rows)

=item *

Single pages built from multiple templates (ie: header, footer, body)

=item *

html tables with runtime determined number of columns

=back

An html template consists of 2 parts; the boilerplate and the tokens (place
holders) where the variable data will sit.

A token has the format __tokenName__ and can be placed anywhere within the
template file. If it occurs in more than one location, when the data is merged
with the template, all occurences of the token will be replaced.

 <p>
 My name is __userName__ and I am aged __age__.
 My friends often call me __nickName__ although my name is __userName__.

When an html table is being populated, it will be necessary to
output several values for each token. This will result in multiple rows in the 
table. However, this will only work if the tokens appear within a repeating
block.

To mark a section of the template as repeating, it needs to be enclosed within
a matching pair of repeating block tokens. These have the format __x_blockName__. They must always come in pairs.

 and I have the following friends
 <table>
 __x_friends__
 <tr>
     <td>__friendName__</td><td>__friendNickName__</td>
 </tr>
 __x_friends__
 </table>

=head1 METHODS

src($)

The single parameter specifies the name of the template file to use.

srcString($)

If the template is within a string rather than a file, use this method to
populate the template object.

output(@)

Merges the data already passed to the HTMLTMPL instance with the template file
specified in src().
The optional parameter is output first, followed by a blank line. These form
the HTTP headers.

htmlString()

Returns a string of html produced by merging the data passed to the HTMLTMPL
instance with the template specified in the src() method. No http headers are
sent to the output string.

listAllTokens()

Returns an array ref. The array contains the names of all tokens found within
the template specifed to src() method.

getAlltokens()

If called in a scalar context, returns a comma seperated list of tokens
found within the template.
If called in array context, returns array of tokens found within the
template.

dumpAll()

Sends to stdout a web page containing an html table. This table lists all
tokens found in the src() template, and all values currently assigned to the
tokens.

getBlock($)

Returns an HTMLTMPL object which represents the repeating / invisible block of
html named in the parameter.

tokenName($)

Assigns to the 'tokenName' token the value specified as parameter.

tokenName($$)

Assigns to the 'tokenName' token, within the repeating block specified in 2nd
parameter, the value specified as the first parameter.

=head1 EXAMPLES

=head2 Example 1.

A simple template with single values assigned to each token.

The template :

 <html><head><title>parser Example 1</title></head>
 <body bgcolor=beige>
 My name is __firstname__ __surname__ but my friends call me __nickname__.
 <hr>
 </body>
 </html>

The code :

 use HTMLTMPL;

 # Create a template object and load the template source.
 $templ = new HTMLTMPL;
 $templ->src('example1.html');

 # Set values for tokens within the page
 $templ->surname('Smyth');
 $templ->firstname('Arthur');
 $templ->nickname('Art!');

 # Send the merged page and data to the web server as a standard text/html mime
 #   type document
 $templ->output('Content-Type: text/html');

Produces this output :

 <html><head><title>parser Example 1</title></head>
 <body bgcolor=beige>
 My name is Arthur Smyth but my friends call me Art!.
 <hr>
 </body>
 </html>

=head2 Example 2

Produces an html table with a variable number of rows.

The template :

 <html><head><title>Example 2 - blocks</title></head>
 <body bgcolor=beige>
 <table border=1>
 __x_details__
 <tr>
        <td>__id__</td>
        <td>__name__</td>
        <td>__desc__</td>
 </tr>
 __x_details__
 </table>
 <ul>
 __x_customer_det__
        <li>__customer__</li>
 __x_customer_det__
 </ul>
 <br>
 <hr>
 </body>
 </html>

The code :

 use HTMLTMPL;

 # Create the template object and load it.
 $templ = new HTMLTMPL;
 $templ->src('example2.html');

 # Simulate obtaining data from database, etc and populate 300 blocks.

 for ($i=0; $i<300; $i++)
 {
     # Ensure that the token is qualified by the name of the block and load
     #       values for the tokens.
     $templ->id($i, 'x_details');
     $templ->name("the name is $i", 'x_details');
     $templ->desc("the desc for $i", 'x_details');
 }

 for ($i=0; $i<4; $i++)
 {
     $templ->customer("And more $i", 'x_customer_det');
 }

 #    Send the completed html document to the web server.
 $templ->output('Content-Type: text/html');

=head2 Example 5.

Uses 2 seperate templates to produce a single web page :

The overall page template :

 <html>
 <head><title>Example 5 - sub templates</title></head>
 <body bgcolor=blue>

 Surname : __surname__
 First Name : __firstname__
 My friends (both of them) call me : __nickname__

 Now to include a sub template...
 __guts__

 And this is the end of the outer template.
 <hr>
 </body>
 </html>

The subtemplate which will be slotted into the 'guts' token position :

 <table border=1>
 <tr>
     <td>__widget__</td>
     <td>__wodget__</td>
 </tr>
 </table>

The code :

 use HTMLTMPL;

 # Create a template object and load the template source.
 my($templ) = new HTMLTMPL;
 $templ->src('example5.html');


 # Set values for tokens within the page
 $templ->surname('Smyth');
 $templ->firstname('Arthur');
 $templ->nickname('Art!');

 my $subTmpl = new HTMLTMPL;
 $subTmpl->src('example5a.html');
 $subTmpl->widget('this is widget');
 $subTmpl->wodget('this is wodget');

 $templ->guts($subTmpl->htmlString);

 # Send the merged page and data to the web server as a standard text/html mime
 #       type document
 $templ->output('Content-Type: text/html');

=head2 Example 6.

In this example the number of columns in the html table is not known until
runtime. It uses an 'invisible' block (obtained by calling getBlock() ) to
produce a single column <td></td> pair. Multiple values can then be assigned
to this to produce multiple columns.

The template :

 <html>
 <head><title>Example 6 - variable number of table cols</title></head>
 <body>
 A table with variable number of columns.

 <table border=1>
 __x_row__
 <tr>
     <td colspan=__maxCols__>This is item number : __itemNo__</td>
 </tr>
 <tr>
 __i_col__
     <td>__cell_data__</td>
 __i_col__
 </tr>
 __x_row__
 </table>
 and this is the end.
 </body>
 </html>

The code :

 use HTMLTMPL;

 my $tmpl = new HTMLTMPL;

 $tmpl->src('example6.html');

 foreach my $y (1..3)
 {
     $tmpl->itemNo($y, 'x_row');
     $tmpl->maxCols(3, 'x_row');

     my $row = $tmpl->getBlock('i_col');

     foreach my $x (qw(A B C))
     {
         $row->cell_data("$x - $y");
     }

     $tmpl->i_col($row->htmlString, 'x_row');
 }

 $tmpl->output('Content-Type: text/html');

=head1 HISTORY

 March 2000	Version 1.20	Added invisible template blocks
 April 1999 - First cut
 Sept. 1999 - Added strict.
 March 2000 - 1.20 - Allow for invisible templates.
 March 2001 - 1.30 - Added to CPAN
 March 2001 - 1.31 - Added getAllTokens, and srcString methods.
 Sept. 2001 - 1.32 - Reset $/ to prior value (courtesy)
 Sept. 2001 - 1.33 - Corrected operation of Invisible blocks.

=head1 AUTHOR

Ian Steel. ian@bilstone.co.uk
