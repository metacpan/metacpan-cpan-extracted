##############################################################################
# The Faq-O-Matic is Copyright 1997 by Jon Howell, all rights reserved.      #
#                                                                            #
# This program is free software; you can redistribute it and/or              #
# modify it under the terms of the GNU General Public License                #
# as published by the Free Software Foundation; either version 2             #
# of the License, or (at your option) any later version.                     #
#                                                                            #
# This program is distributed in the hope that it will be useful,            #
# but WITHOUT ANY WARRANTY; without even the implied warranty of             #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              #
# GNU General Public License for more details.                               #
#                                                                            #
# You should have received a copy of the GNU General Public License          #
# along with this program; if not, write to the Free Software                #
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.#
#                                                                            #
# Jon Howell can be contacted at:                                            #
# 6211 Sudikoff Lab, Dartmouth College                                       #
# Hanover, NH  03755-3510                                                    #
# jonh@cs.dartmouth.edu                                                      #
#                                                                            #
# An electronic copy of the GPL is available at:                             #
# http://www.gnu.org/copyleft/gpl.html                                       #
#                                                                            #
##############################################################################

use strict;

###
### A FAQ::OMatic::Part is a member of a FAQ::OMatic::Item, and contains one chunk of
### text, plus its attributions, modification date, and other
### characteristics.
###

package FAQ::OMatic::Part;

use FAQ::OMatic;
use FAQ::OMatic::Item;
use FAQ::OMatic::Appearance;
use FAQ::OMatic::Set;
use FAQ::OMatic::I18N;
use Text::Tabs;

sub new {
	my ($class) = shift;

	my $part = {};
	bless $part;
	$part->{'Type'} = '';			# type is always defined, since '' is a
									# valid type.
	$part->{'Text'} = '';			# might as well define the text, since
									# that's the point of a part.
	$part->{'Author-Set'} = new FAQ::OMatic::Set('keepOrdered');

	return $part;
}

sub loadFromCodeClosure {
	my $self = shift;
	my $closure = shift;	# a sub that returns one line for each call
	my $filename = shift;
	my $item = shift;
	my $partnum = shift;

	my ($lines) = 0;
	my ($text) = "";

	# THANKS to "John R. Jackson" <jrj@gandalf.cc.purdue.edu> for
	# grepping for unprotected while constructs.
	while (defined($_ = &{$closure})) {
		chomp;
		my ($key,$value) = FAQ::OMatic::keyValue($_);
		if ($key eq 'Author') {
			# convert old-style 'Author' keys to 'Author-Set' keys
			# transparently. Eventually all such items will get written
			# out with updated header keys.
			$key = 'Author-Set';
		}
		if ($key eq 'DateOfPart') {
			# convert old-style 'DateOfPart' keys to 'LastModifiedSecs' keys
			# transparently.
			$value = FAQ::OMatic::Item::compactDateToSecs($value);
				# turn back into seconds
			$key = 'LastModifiedSecs';
		}
		if ($key eq 'Lines') {
			# Lines header is always last before the text content of a Part
			$lines = $value;
			last;
		} elsif ($key =~ m/-Set$/) {
			# header key ends in '-Set' -- that means it may appear multiple
			# times.
			if (not defined($self->{$key})) {
				$self->{$key} = new FAQ::OMatic::Set;
			}
			$self->{$key}->insert($value);
		} elsif ($key ne '') {
			$self->{$key} = $value;
			if (($key eq 'Type') and ($value eq 'directory')) {
				# keep a quick way for the item object to find the part that
				# holds the directory
				$item->{'directoryHint'} = $partnum;
			}
		} else {
			FAQ::OMatic::gripe('problem',
			"FAQ::OMatic::Part::loadFromCodeClosure was confused by this header in file $filename: \"$_\"");
		}
	}
	# THANKS to "John R. Jackson" <jrj@gandalf.cc.purdue.edu> for
	# grepping for unprotected while constructs.
	while (($lines>0) and defined($_ = &{$closure})) {
		$text .= $_;
		$lines--;
	}
	# verify that EndPart shows up in the right place
	$_ = &{$closure};
	if (not defined $_) {
		FAQ::OMatic::gripe('problem',
		"FAQ::OMatic::Part::loadFromCodeClosure file $filename part $partnum didn't end right.");
	}
	my ($key,$value) = FAQ::OMatic::keyValue($_);
	if (($key ne 'EndPart') or ($value != $partnum)) {
		FAQ::OMatic::gripe('problem', "FAQ::OMatic::Part::loadFromCodeClosure file $filename part $partnum didn't end with EndPart.");
	}
	$self->{'Text'} = $text;
}

sub displayAsFile {
	my $self = shift;
	my $rt = "";

	my $key;
	foreach $key (sort keys %{$self}) {
		if (($key =~ m/^[a-z]/)
			or ($key eq 'Text')) {
			next;
			# these keys get ignored or written out later (Text)
		} elsif ($key =~ m/-Set$/) {
			my $a;
			foreach $a ($self->getSet($key)->getList()) {
				$rt .= "$key: $a\n";
			}
		} else {
			$rt .= "$key: ".$self->{$key}."\n";
		}
	}
	my $text = $self->{'Text'};
	$text =~ s/([^\n])\r([^\n])/$1\n$2/gs;	# standalone LF's become \n's.
	$text =~ s/\r//gs;						# Remove any bogus extra \r's
	$text .= "\n" if (not ($text =~ m/\n$/));	# ensure final \n
	$self->{'Text'} = $text;				# make sure in-memory copy
											# reflects the one we're saving

	$rt .= "Lines: ".countLines($text)."\n".$text;

	return $rt;
}

sub countLines {
	my $data = shift;
	my $datacopy = $data;
	$datacopy =~ s/[^\n]//gs;		# count \n's
	return length($datacopy);
}

sub display {
	my $self = shift;
	my @keys;
	my $rt = "";	# return text

	$rt .= "<ul>\n";
	my $key;
	foreach $key (sort keys %$self) {
		$rt .= "<li>$key => $self->{$key}<br>\n";
	}
	$rt .= "</ul>\n";

	return $rt;
}

sub displayHTML {
	my $self = shift;
	my $item = shift;
	my $partnum = shift;
	my $params = shift;
	my $showAttributions = FAQ::OMatic::getParam($params, 'showAttributions');
	my @boxes = ();		# return one table row per @boxes element

	my $rt = '';

	my $type = $self->{'Type'} || '';
	my $tmp = FAQ::OMatic::insertLinks($params, $self->{'Text'},
					   $type eq 'html',
					   $type eq 'directory');
	$tmp = FAQ::OMatic::highlightWords($tmp, $params);
	if ($type eq 'monospaced'){
		## monospaced text
		$tmp =~ s/\n$//;
		$tmp = "<pre>\n".$tmp."</pre>";
	} elsif ($type eq 'html') {
		## HTML text.  Just add a <br> at the end, and a comment that
	        ## it's untranslated.
	        $tmp = "<!-- This text is untranslated from the original;\n" .
		    "any errors are in the original text. -->\n" . $tmp .
			"\n<br>\n";
	} else {
		## standard format: double-CRs become <p>'s (whitespace between
		## paragraphs), and lines that start with whitespace get a <br>
		## tag. Note that directories are standard format too, we just
		## enforce a rule when editing to keep the structure consistent.
		$tmp .= "<br>";				# keep attributions below part
		# These are Andreas Kluﬂmann <Andreas.Klussmann@infosys.heitec.net>'s
		# cool rules: triple-space for a paragraph, double for a break,
		# indent for <pre>formatted text.
		$tmp =~ s/\n\n\n/\n<p>\n/gs;
		$tmp =~ s/\n\n/<br>\n/gs;
		$tmp =~ s/\n( +[^\n]*)(?=\n)/\n<pre>$1<\/pre>/gs;
		$tmp =~ s/<\/pre>\n<pre>/\n/gs;
	}
	$rt .= $tmp;

	# turn off attributions if this part has the HideAttributions property,
	# or if the item has the AttributionsTogether property.
	if ($showAttributions eq 'default') {
		if ($self->{'HideAttributions'} or $item->{'AttributionsTogether'}) {
			$showAttributions = 'hide';
		} else {
			$showAttributions = 'all';
		}
	}
	if ($showAttributions eq 'all') {
		#$rt .= "<i>".join(", ",
		# THANKS: DateOfPart courtesy Scott Hardin <scott@cs.dlh.de>
		my ($date_string) = '';
		if ($self->{'LastModifiedSecs'} and
			FAQ::OMatic::getParam($params, 'showLastModified') eq 'show') {
		        $date_string = FAQ::OMatic::Item::compactDate(
						$self->{'LastModifiedSecs'}) . " ";
		}
		$rt .= "<i>"
			.$date_string
			.join(", ",
				map { FAQ::OMatic::mailtoReference($params, $_) }
					$self->{'Author-Set'}->getList()
				)."</i>";
	}

	my $color = ($type eq 'directory')
			? $FAQ::OMatic::Config::directoryPartColor
			: $FAQ::OMatic::Config::regularPartColor;
	my $partBox = { 'type'=>'three',
				'text'=>$rt,
				'color'=>$color };
	# that's the end of the main part content

	if (FAQ::OMatic::getParam($params, 'editCmds') ne 'hide'
		and $item->ordinaryItem()) {
		my $aoc = $item->isCategory ? 'cat' : 'ans';
		my $filename = $item->{'filename'};
		my @rightEdits = ();
		my @belowEdits = ();

		push @rightEdits, {'text'=>FAQ::OMatic::button(
			FAQ::OMatic::makeAref('-command'=>'editPart',
				'-params'=>$params,
				'-changedParams'=>{'file'=>$filename,
							'partnum'=>$partnum,
							'checkSequenceNumber'=>$item->{'SequenceNumber'}}),
			gettext("Edit This Text"),
			"$aoc-edit-part", $params),
				'size'=>'edit'};
		push @rightEdits, {'text'=>FAQ::OMatic::button(
			FAQ::OMatic::makeAref('-command'=>'editPart',
				'-params'=>$params,
				'-changedParams'=>{'file'=>$filename,
							'partnum'=>$partnum,
							'_insertpart'=>1,
							'_duplicate'=>1,
							'checkSequenceNumber'=>$item->{'SequenceNumber'}}),
			gettext("Duplicate This Text"),
			"$aoc-dup-part", $params),
				'size'=>'edit'};
		if ($type ne 'directory') {
			push @rightEdits, {'text'=>FAQ::OMatic::button(
				FAQ::OMatic::makeAref('-command'=>'delPart',
					'-params'=>$params,
					'-changedParams'=>{"file"=>$filename,
						'partnum'=>$partnum,
						'checkSequenceNumber'=>$item->{'SequenceNumber'}}
				),
			gettext("Remove This Text"),
			"$aoc-del-part", $params),
				'size'=>'edit'};
		} elsif (scalar($self->getChildren())==0) {
			# directory, but has no children -- can just delete directory.
			# this is a minor variation on Item's Convert to Answer.
			push @rightEdits, {'text'=>FAQ::OMatic::button(
				FAQ::OMatic::makeAref('-command'=>'submitCatToAns',
					'-params'=>$params,
					'-changedParams'=>{"file"=>$filename,
						'_removePart'=>1,
						'checkSequenceNumber'=>$item->{'SequenceNumber'}}
				),
			gettext("Remove This Text"),
			"$aoc-del-part", $params),
				'size'=>'edit'};
		}

		my @baglist = $self->getBags();
		if (scalar(@baglist)==1) {
			push @rightEdits, {'text'=>FAQ::OMatic::button(
				FAQ::OMatic::makeAref('-command'=>'editBag',
					'-params'=>$params,
					'-changedParams'=>{'file'=>$filename,
						'_target'=>$baglist[0]}),
				gettexta("Replace %0 with new upload", $baglist[0])),
					'size'=>'edit'};
		} elsif (scalar(@baglist)>1) {
			push @rightEdits, {'text'=>FAQ::OMatic::button(
				FAQ::OMatic::makeAref('-command'=>'selectBag',
					'-params'=>$params,
					'-changedParams'=>{'file'=>$filename}),
				gettext("Select bag to replace with new upload")),
					'size'=>'edit'};
		}

		push @rightEdits, {'text'=>FAQ::OMatic::button(
			FAQ::OMatic::makeAref('-command'=>'editBag',
				'-params'=>$params,
				'-changedParams'=>{'file'=>$filename,
					'partnum'=>$partnum}),
			gettext("Upload New Bag Here")),
				'size'=>'edit'};

		# separate block of editing commands that don't apply to a specific
		# part, but their position between parts is relevant
		push @belowEdits, {'text'=>''};
		push @belowEdits, {'text'=>FAQ::OMatic::button(
			FAQ::OMatic::makeAref('-command'=>'editPart',
				'-params'=>$params,
				'-changedParams'=>{'file'=>$filename,
							'partnum'=>$partnum,
							'_insertpart'=>1,
							'checkSequenceNumber'=>$item->{'SequenceNumber'}}),
				gettext("Insert Text Here"),
			"$aoc-ins-part", $params),
				'size'=>'edit'};
		push @belowEdits, {'text'=>FAQ::OMatic::button(
			FAQ::OMatic::makeAref('-command'=>'editPart',
				'-params'=>$params,
				'-changedParams'=>{'file'=>$filename,
							'partnum'=>$partnum,
							'_insertpart'=>1,
							'_upload'=>1,
							'checkSequenceNumber'=>$item->{'SequenceNumber'}}),
				gettext("Insert Uploaded Text Here"),
			"$aoc-ins-part", $params),
				'size'=>'edit'};

		return { 'type'=>'three',
			'part'=>$self,
			'body'=>$partBox,
			'editbody'=>\@rightEdits,
			'afterbody'=>\@belowEdits,
			'id'=>'generated by Part::displayHTML'};
	}

	# no editing boxes
	return { 'type'=>'wide',
		'text'=>$partBox->{'text'},
		'color'=>$partBox->{'color'},
		'part'=>$self,
		};
}

sub displayText {
	my $self = shift;
	my $item = shift;
	my $partnum = shift;
	my $params = shift;
	my $showAttributions = FAQ::OMatic::getParam($params, 'showAttributions');
	my @boxes = ();		# return one table row per @boxes element

	my $rt = '';

	my $type = $self->{'Type'} || '';
	my $tmp = FAQ::OMatic::insertLinksText($params, $self->{'Text'},
					   $type eq 'html',
					   $type eq 'directory');
	if ($type eq 'monospaced'){
		## monospaced text -- display it as-is
	} elsif ($type eq 'html') {
		## HTML text. Eliminate all tags.
		$tmp =~ s#<([^>]("[^"]*")?)*>##sg;
	} else {
		## standard format: double-CRs are line breaks, triple-crs are
		## white-space, indented lines shouldn't be touched.
		my @whitespaces = split("\n\n\n", $tmp);
		my $out = '';
		$Text::Wrap::columns = 70;
		for (my $i=0; $i<@whitespaces; $i++) {
			my @lb = split("\n\n", $whitespaces[$i]);
			my @paragraph = map { wrapLeftLines($_) } @lb;
			$out .= join("\n", @paragraph);
			$out =~ s/\n?\n?$/\n\n/s;	# ensure text ends in a blank line
		}
		# TODO: already-indented lines are not to be wrapped.
		$tmp = $out;
	}
	$rt .= $tmp;

	# turn off attributions if this part has the HideAttributions property,
	# or if the item has the AttributionsTogether property.
	if ($showAttributions eq 'default') {
		if ($self->{'HideAttributions'} or $item->{'AttributionsTogether'}) {
			$showAttributions = 'hide';
		} else {
			$showAttributions = 'all';
		}
	}
	if ($showAttributions eq 'all') {
		my @authors = $self->{'Author-Set'}->getList();
		my $brt = FAQ::OMatic::authorList($params, \@authors);
		if ($self->{'LastModifiedSecs'} and
			FAQ::OMatic::getParam($params, 'showLastModified') eq 'show') {
				$brt = FAQ::OMatic::Item::compactDate(
						$self->{'LastModifiedSecs'})
					." ".$brt;
		}
		$rt.=$brt;
	}

	# no editing boxes
	return { 'type'=>'wide',
		'text'=>$rt,
		'part'=>$self,
		};
}

sub displayPartEditor {
	my $self = shift;
	my $item = shift;
	my $partnum = shift;
	my $params = shift;
	my $rt = ''; 	# return text

	# default number of rows is room for text plus a little new text.
	my $rows = countLines($self->{'Text'})+4;
	$rows = 15 if ($rows < 15);	# make sure it's never too teeny
	$rows = 30 if ($rows > 30);	# and never way big

	$rt .= FAQ::OMatic::makeAref('-command'=>'submitPart',
						'-params'=>$params,
						'-changedParams'=>{'partnum'=>$partnum},
						'-refType'=>'POST',
						'-multipart'=>($params->{'_upload'} ? 1 : ''),
						'-saveTransients'=>1);

	$rt.="<table><tr>\n";
	$rt.="<td colspan=2>\n";
	$rt .= "<input type=hidden name=\"checkSequenceNumber\" value=\""
		.$item->{'SequenceNumber'}."\">\n";

	if (not $params->{'_upload'}) {
		# Regular input screen -- provide a <textarea> to edit part's text
		#
		# no text boxes wrap anymore -- it breaks long URLs.
		# THANKS: to Billy Naylor <banjo@actrix.gen.nz> for the fix
		# THANKS: to "Alan R. Zimmerman" <mailto:alanz@mdhost.cse.tek.com>) for
		# noticing it a long time ago. I just forgot about his bug report!
		# Blush.
		# Wait -- it wouldn't if it were SOFT wrapping! Silly me.
		my $wrap = ($self->{'Type'} eq 'monospaced')
			? 'off'
			: 'soft';
		$rt .= "<input type=hidden name=\"_inputType\" value=\"textarea\">\n";
		$rt .= "<textarea cols=80 rows=$rows name=_newText wrap=$wrap>";
	
		my $text = $self->{'Text'};

		$text = addTitleToFaqomaticReferences($text);

		$text =~ s/&/&amp;/gs;		# all browsers I've met correctly
		$text =~ s/</&lt;/gs;		# convert textarea entities into the
									# real thing
		$text =~ s/>/&gt;/gs;
	
		$rt .= $text."</textarea>\n";
	
		$rt.="</td>\n";
		$rt.="</tr><tr>\n";
		$rt.="<td align=left valign=top width=\"50%\">\n";
	} else {
		# Upload file instead of typing in textarea
		# THANKS: to John Goerzen
		$rt .= "<p><input type=hidden name=\"_inputType\" value=\"file\">\n"
			.gettext("Upload file:")." ";
		$rt .= "<input type=file name=\"_newTextFile\"><br>";
		if ($self->{'Text'} ne '') {
			my @count = ($self->{'Text'} =~ m/\n/gs);
			my $count = scalar(@count);
			$rt .= gettext("Warning: file contents will <b>replace</b> previous text")." ($count lines).\n";
		}
	}

	# HideAttributions
	$rt .= "<p><input type=checkbox name=\"_HideAttributions\"";
	$rt .= " CHECKED" if $self->{'HideAttributions'};
	$rt .= "> ".gettext("Hide Attributions")."\n";

	# Type
	$rt .= "<p><dl>".gettext("Format text as:")."<br>\n\n";

	if ($self->{'Type'} eq 'directory') {
# TODO: delete this commented block. superseded by submitCatToAns.
#		if (scalar($self->getChildren()) == 0) {
#			$rt .= "<input type=checkbox name=\"_removeDirectory\" "
#				."value=\"1\"> Remove directory (turning this category "
#				."item into an answer item) if text box above is empty.\n";
#		}
		$rt .= "<nobr><input type=radio name=\"_Type\" value=\"directory\""
			."  CHECKED> ".gettext("Directory")."</nobr>\n";
	} else {
		# THANKS: Jim Spath (jes) got rid of <br>s to format more tightly
		# in Lynx; jonh put one back in, plus some <nobr> pairs to keep
		# layout from sucking in netscape/ie.
		$rt .= "<nobr><input type=radio name=\"_Type\" value=\"\"";
		$rt .= " CHECKED" if ($self->{'Type'} eq '');
		$rt .= "> ".gettext("Natural text")."</nobr>\n";

		$rt .= "<nobr><input type=radio name=\"_Type\" value=\"monospaced\"";
		$rt .= " CHECKED" if ($self->{'Type'} eq 'monospaced');
		$rt .= "> ".gettext("Monospaced text (code, tables)")."</nobr>\n";

		# THANKS: John Goerzen supplied the patches to introduce
		# THANKS: 'html'-type parts.
		my $url = FAQ::OMatic::Auth::ensurePerm($item, 'PermUseHTML',
			 FAQ::OMatic::commandName(), 
			 FAQ::OMatic::dispatch::cgi(), 0, 'useHTML');
		if ($url) {
			# $rt .= "<p><i>Untranslated HTML</i>\n";
			# THANKS: Jim Adler says: why even admit that it exists?
			# problem: how can a user authenticate if he should be able
			# to use HTML?
		} else {
	    	$rt .= "<nobr><input type=radio name=\"_Type\" value=\"html\"";
	    	$rt .= " CHECKED" if ($self->{'Type'} eq 'html');
	    	$rt .= "> ".gettext("Untranslated HTML")."</nobr>\n";
		}
	}
	$rt .= "</dl>\n";
	$rt.="</td>\n";

	# Submit
	# THANKS: to Jim Adler <jima@sr.hp.com> for suggesting using a
	# table to bring the Submit button up higher so users don't have
	# to scroll just to get past the rest of the form.
	$rt.="<td align=left valign=top width=\"50%\">\n";
	$rt .= "<br><input type=submit name=\"_submit\" value=\"".gettext("Submit Changes")."\">\n";
	$rt .= "<input type=reset name=\"_reset\" value=\"".gettext("Revert")."\">\n";
	$rt .= "<input type=hidden name=\"_zzverify\" value=\"zz\">\n";
		# this lets the submit script check that the whole POST was
		# received.
	$rt .= "</form>\n";
#	$rt .= FAQ::OMatic::button(
#			FAQ::OMatic::makeAref('-command'=>'faq',
#				'-params'=>$params,
#				'-changedParams'=>{'partnum'=>'',
#					'checkSequenceNumber'=>''}
#				),
#			'Cancel and return to FAQ');
	$rt.="</td>\n";
	$rt.="</tr></table>\n";

	return $rt;
}

# insert [item title] into faqomatic:XX references
sub addTitleToFaqomaticReferences {
	my $text = shift;
	my @splitty = splitLinksFromText($text);
	for (my $i=1; $i<scalar(@splitty); $i+=2) {
		$splitty[$i] =~ m/^faqomatic:(.*)$/;
		my $filename = $1;
		my $item = new FAQ::OMatic::Item($filename);
		my $title = $item->getTitle();
		$title =~ tr/\[\]/\(\)/;	# eliminate []'s
		$splitty[$i] = "faqomatic[$title]:$filename";
	}
	return join('', @splitty);
}

sub setText {
	my $self = shift;
	my $newText = shift;

	# eliminate tabs
	if ($newText =~ m/\t/) {
		# use Text::Tabs expand function to eliminate tabs
		$Text::Tabs::tabstop = 8;
		$newText = join("\n", Text::Tabs::expand(split(/\n/, $newText)));
	}
	$self->{'Text'} = $newText;
}

sub setProperty {
	my $self = shift;
	my $property = shift;
	my $value = shift;

	if ($value) {
		$self->{$property} = $value;
	} else {
		delete $self->{$property};
	}
}

sub getChildren {
	my $self = shift;

	if ($self->{'Type'} ne 'directory') {
		return ();
	}

	return $self->getLinks();
}

# returns a list of all faqomatic: links in this part
sub getLinks {
	my $self = shift;
	return getLinksFromText($self->{'Text'});
}

sub getLinksFromText {
	my $text = shift;
	my @splitty = splitLinksFromText($text);
	my @dirlist = ();
	for (my $i=1; $i<scalar(@splitty); $i+=2) {
		# strip off faqomatic: prefixes to leave item names
		$splitty[$i] =~ s/^faqomatic://;
		push @dirlist, $splitty[$i];
	}
	return @dirlist;
}

sub splitLinksFromText {
	# this function determines what is or isn't a faqomatic: link
	# it returns a split-style alternating array; even indices are
	# other stuff and odd indices are the faqomatic: links with
	# the "faqomatic:" still attached.
	my $text = shift;
	my @splitty = split(/(faqomatic:[^>\s.,\?!)]+)/, $text);
	#TODO debug delete
	#my @splitty = split(/(faqomatic:[^\>]*)/, $text);
	return @splitty;
}

# returns list of names of all bags this part references,
# either as inlines or as baglinks.
sub getBags() {
	my $self = shift;

	my $text = $self->{'Text'};
	my @regexlist = ($text =~
		m/(baginline:(\S*[^\s.,>)\?!]))|(baglink:(\S*[^\s.,>)\?!]))/gs);
	# the above regexp will return 4*number of matches, one entry for
	# each left parethesis.
	# We actually want either the second or fourth item from each 4-tuple.
	my $i;
	my @baglist = ();
	for ($i=0; $i<scalar(@regexlist); $i+=4) {
		push @baglist, $regexlist[$i+1] || $regexlist[$i+3];
		# Thanks to John Nolan <JNolan@cdnow.com> for finding another
		# Use of Uninitialized Value -w bug that was here.
	}
	# remove duplicates but keep order using a Set
	my $bagset = new FAQ::OMatic::Set('keepOrdered');
	$bagset->insert(@baglist);
	return $bagset->getList();
}

sub mergeDirectory {
	my $self = shift;
	my $filename = shift;

	if ($self->{'Type'} ne 'directory') {
		FAQ::OMatic::gripe('panic', "mergeDirectory: self is not a directory");
	}
	if (not -f "$FAQ::OMatic::Config::itemDir/$filename") {
		FAQ::OMatic::gripe('panic', "mergeDirectory: $filename isn't a file");
	}

	my @dirlist = $self->getChildren();
	my %dirhash = map { ($_,1) } @dirlist;
	return if ($dirhash{$filename});			# already done

	my $item = new FAQ::OMatic::Item($filename);
	my $headerpattern = gettext("Answers in this category:");
	if ((defined $item->{'directoryHint'})
		and ($self->{'Text'} =~ m/\n\n$headerpattern/)) {
		# Insert subcategories above "Answers in this category" header, if
		# one exists.
		$self->{'Text'} =~ s/(\n?\n\n$headerpattern)/\n\n<faqomatic:$filename>$&/s;
	} else {
		# just tack on the end with all the other answers
		$self->{'Text'} .= "\n<faqomatic:$filename>\n";
	}
	my ($id,$aq) = FAQ::OMatic::Auth::getID();			# user is now a coauthor of
	$self->addAuthor($id) if ($id);				# the directory part
}

sub unmergeDirectory {
	my $self = shift;
	my $filename = shift;

	if ($self->{'Type'} ne 'directory') {
		FAQ::OMatic::gripe('panic',
			"unmergeDirectory: self is not a directory");
	}

	# since directories can now contain textual content, we
	# unmerge by simply "substituting out" the faqomatic link:
	# THANKS: to erinker@beasys.com for helping me get the whitespace
	# removal right (or at least better)
	# THANKS: to "Mark D. Nagel" <nagel@intelenet.net> for finding
	# structure-corrputing bug where removing 'faqomatic:21' would also
	# change 'faqomatic:218' into 'faqomatic:21'. The fix was to add
	# a pattern at the end that forces the match to be complete.
	# Bad software engineering note: this regex needs to be kept in
	# agreement with the one in Part::getLinks(), because they both define
	# the boundaries of a faqomatic: link.
	my @splitty = splitLinksFromText($self->{'Text'});
	for (my $i=1; $i<scalar(@splitty); $i+=2) {
		if ($splitty[$i] eq 'faqomatic:'.$filename) {
			# found our target
			# try to remove any surrounding boilerplate
			$splitty[$i-1] =~ s/\n?\n? ?<?$//s;
			$splitty[$i] = '';		# delete the faqomatic: ref
			$splitty[$i+1] =~ s/^>//s;
			# return happy
			$self->{'Text'} = join('', @splitty);
			return;
		}
	}
	# Uh oh, never found the link!
	die "failed to unmerge $filename from directory of "
		.$self->{'filename'}
		.".";
}

sub addAuthor {
	my $self = shift;
	my $author = shift;

	$self->{'Author-Set'}->insert($author);
}

sub clone {
	# return a deep-copy of myself
	my $self = shift;

	my $newpart = new FAQ::OMatic::Part();

	# copy all of prototype's attributes
	my $key;
	foreach $key (keys %{$self}) {
		if ($key =~ m/-Set$/) {
			$newpart->{$key} = $self->{$key}->clone();
		} elsif (ref $self->{$key}) {
			# guarantee this is a deep copy -- if we missed
			# a ref, complain.
			FAQ::OMatic::gripe('error', "FAQ::OMatic::Part::clone: prototype has "
				."key '$key' that is a reference (".$self->{$key}.").");
		}
		$newpart->{$key} = $self->{$key};
	}

	# don't let rogue directories escape and mess up the item structure
	$newpart->{'Type'} = '' if ($newpart->{'Type'} eq 'directory');

	return $newpart;
}

sub getSet {
	my $self = shift;
	my $setName = shift;

	return $self->{$setName} || new FAQ::OMatic::Set;
}

sub wrapLeftLines {
	# wrap lines that are left-justified; preserve the others
	my $text = shift;

	my @lines = split(/\n/, $text);
	my @buffer = ();
	my $rt = '';
	my $line;
	while (defined($line = shift @lines)) {
		if ($line =~ m/^\s/) {
			# a concrete line -- wrap prior buffer, pass concrete line
			if (@buffer) {
				$rt .= faqwrap(@buffer);
				@buffer = ();
			}
			$rt.=$line."\n";
		} else {
			# a wrappable line -- group into buffer
			push @buffer, $line;
		}
	}
	# wrap remaining buffer
	if (@buffer) {
		$rt .= faqwrap(@buffer);
		@buffer = ();
	}
	return $rt;
}

sub faqwrap {
	my @lines = @_;

	# Text::Wrap() is pretty broken. The docs say it doesn't die
	# when given a word longer than $columns, but it still does.

	my $rt="Text::Wrap() failed\n";
	eval {
		require Text::Wrap;
		import Text::Wrap qw(wrap $columns);

		$rt=wrap('','',@lines);
	};
	return $rt;
}

sub touch {
	my $self = shift;
	my $time = shift || time();

	$self->setProperty('LastModifiedSecs', $time);
}

1;
