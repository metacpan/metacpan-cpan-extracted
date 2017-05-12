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
use locale;

###
### The FAQ::OMatic::API provides ways to programmatically modify
### the contents of your FAQ-O-Matic.
###

package FAQ::OMatic::API;

=head1 NAME

FAQ::OMatic::API - a Perl API to manipulate FAQ-O-Matics

=head1 SYNOPSIS

 use FAQ::OMatic::API;
 my $fom_api = new FAQ::OMatic::API();

=head1 DESCRIPTION

C<FAQ::OMatic::API> is a class that makes HTTP requests to a FAQ-O-Matic.
It provides a way to manipulate a FAQ-O-Matic from Perl code. Operations
are performed by making HTTP requests on the FAQ-O-Matic server;
this ensures that any operation is performed in exactly the same environment
as it would be if it were requested by a human using a web browser.

=head1 Setup

The following methods are used to set up an API object.

=over 4

=cut

use FAQ::OMatic;
use LWP::UserAgent;
use URI;
use HTTP::Request::Common qw(GET POST);

=item $fom_api = new FAQ::OMatic::API([$url, [$id, $pass]]);

Constructs a new C<FAQ::OMatic::API> object that points at the FAQ
whose CGI is at C<$url>. Requests will be authenticated on behalf of
FAQ user C<$id> using password C<$pass>.

=cut

sub new {
	my ($class) = shift;

	my $api = {};
	$api->{'auth'} = [];
	$api->{'cacheTimeout'} = 24*60*60;
	bless $api;

	if (scalar(@_)>=1) {
		$api->setURL(shift(@_));
	}

	if (scalar(@_)>=2) {
		$api->setAuth(shift(@_), shift(@_));
	}

	return $api;
}

=item $fom_api->setURL($url);

Sets the URL of the target FAQ's CGI. This is where requests will be sent.

=cut

sub setURL {
	my $self = shift;
	my $url = shift;
	$self->{'url'} = $url;
}

=item $fom_api->setAuth($id, $pass);

Sets the ID and password that will be used to authenticate requests.

=item $fom_api->setAuth('query');

Passing in 'query' will cause the script to query the terminal for
the C<id> and C<password> at runtime.

=cut

sub setAuth {
	my $self = shift;
	my $id = shift;
	my $pass = shift;

	if ($id eq 'query') {
		# defer auth to input from user
		$self->{'auth'} = 'query';
	} else {
		$self->{'auth'} =
			[ 'auth'=>'pass', '_pass_id'=>$id, '_pass_pass'=>$pass ];
	}
}

# THANKS to Dirk Husemann <hud@zurich.ibm.com> for this feature diff.
sub setCachePath {
    my $self = shift;
    my $cachePath = shift;

    $self->{'cachePath'} = $cachePath;
}

sub setCacheTimeout {
    my $self = shift;
    $self->{'cacheTimeout'} = shift || 24*60*60;
}
=back

=head1 Queries

The following methods retrieve information about a FAQ-O-Matic.

=over 4

=item $fom_api->getCategories()

Returns a list of the categories (by file name) in the FAQ.

=cut

sub getCategories {
	my $self = shift;

	$self->getMirrorList();
	return map { $_->[0]->[1] } @{$self->{'categories'}};
}

=item $item = $fom_api->getItem($filename)

Returns a local FAQ::OMatic::Item object created by retrieving C<$filename>
from the FAQ. You can perform operations on the result such as:

 print $item->getTitle();

 $parentItem = $item->getParent();

 print $item->displayHTML({'render'=>'text'});

=cut

sub getItem {
	my $self = shift;
	my $filename = shift;

	my ($rc, $msg) = $self->getMirrorList();
	return ($rc, $msg) if (not $rc);

	my $uri = new URI($self->{'url'});
	$uri->path($self->{'itemURL'}.$filename);
	my $req = GET($uri);
	my $rep = $self->userAgent()->request($req);

	if (not $rep->is_success()) {
		if ($self->{'debug'} || '') {
			print "Request: ".$uri->as_string()."\n";
			$self->dumpresp($rep);
		}
		return (0, "\$rep reports failure: ".$rep->status_line."\nrequest was: ".$uri);
	}

	my $item = new FAQ::OMatic::Item();
	$item->{'filename'} = $filename;
	$item->loadFromString($rep->content(), $filename);

	return (1, $item);
}

=item my ($rc, $result) = $fom_api->fuzzyMatch(['Parent Category','child cat'])

 my ($rc, $result) = $fom_api->fuzzyMatch(['Parent Category','child cat'])
 die $result if (not $rc);
 my $item = $fom_api->getItem($result->[0]);

C<fuzzyMatch()> attempts to figure out which category the last string
in its array argument represents. The category name is matched "fuzzily"
against existing categories. If a unique match is found, it is returned
(as an array ref C<[$filename, $parent, $title]>). If the match is
ambiguous, the previous array element is matched against the parents
of the set of fuzzy matches. This is performed recursively until the
child category is disambiguated.

Fuzzy matching means that

=over 4

=item (a)

You don't have to get the parent category
names right if they're not needed to disambiguate the child category.

=item (b)

Category names are matched without respect to case, spacing, or punctuation:
only alphanumerics matter. Also, the name you supply only has to appear
somewhere inside the one you want to match. (Exact matches are preferred;
this allows you to match categories whose names are prefixes of other
category names.)

=back

=cut

# TODO: It wouldn't be a difficult modification to let you match
# answers as well as categories, which would be useful for appending
# to existing answers (rather than creating new answers in existing
# categories).

sub fuzzyMatch {
	my $self = shift;
	my $path = shift;	# ary ref

	my $cats = $self->catnames();
	my @rpath = reverse (@{$path});
	for (my $depth = 0; $depth<@rpath; $depth++) {
		# look for match at leaf node; disambiguate by rising up tree
		my $matchname = $rpath[$depth];
		$matchname = lc($matchname);		# lowercase
		$matchname =~ s/\W//g;				# only alphanumerics + '_'
		# try for an exact match
		my @matchcats = grep {
				my $catname = $_->[2];
				$catname = lc($catname);	# lowercase
				$catname =~ s/\W//g;		# only alphanumerics + '_'
				$catname =~ m/^$matchname$/;	# check for exact match
			} @{$cats};
		if (@matchcats == 0) {
			# fall back to fuzzier match (allow any prefix, suffix)
			@matchcats = grep {
					my $catname = $_->[2];
					$catname = lc($catname);	# lowercase
					$catname =~ s/\W//g;		# only alphanumerics + '_'
					$catname =~ m/$matchname/;		# check for inclusion
				} @{$cats};
		}
		if (scalar(@matchcats)==1) {
			# unambiguous -- unwind the parent chain to get to the leaf
			my $cat = $matchcats[0];
			while (defined $cat->[3]) {
				$cat = $cat->[3];	# has child? unwind child.
			}
			return (1, $cat);
		} elsif (scalar(@matchcats)==0) {
			# unmatched
			return (0, "no names match ".join(":", @{$path}));
		} else {
			# ambiguous: attempt to disambiguate at next higher depth
			$cats = [ map {
					my $parentcat = $self->catByName($_->[1]);
					[ @{$parentcat}, $_ ];
				} @matchcats ];
			if ($self->{'debug'}) {
				print "matched ".scalar(@{$cats})." items at level $depth\n";
				print map {"  m: ".join(",", @{$_})."\n"} @{$cats};
			}
			next;
		}
	}
	# ran out of names to disambiguate with
	return (0, join(":", @{$path})." -- not enough levels to disambiguate");
}

=back

=head1 Operations

The following methods perform operations on a FAQ-O-Matic.

=over 4

=item $fom_api->newAnswer($parent, $title, $text)

A new answer is created as a child of item C<$parent>.
The new answer has title C<$title> and a single text part containing
C<$text>.

=cut

sub newAnswer {
	my $self = shift;
	my $parent = shift;
	my $title = shift;
	my $text = shift;

	my ($rc, $msg);
	($rc, $msg) = $self->transaction(['cmd'=>'addItem', 'file'=>$parent]);
	if (not $rc) {
		return ($rc, "(addItem) ".$msg);
	}

	my $filename = $msg->{'file'} || die "no filename in reply";
	my $seq = $msg->{'checkSequenceNumber'};
	die "no sequenceNumber in reply" if (not defined $seq);

	($rc, $msg) = $self->transaction(
		['cmd'=>'submitItem',
			'file'=>$filename,
			'_Title'=>$title,
			'checkSequenceNumber'=>$seq,
			'_zzverify'=>'zz']);
	if (not $rc) {
		return ($rc, "(submitItem) ".$msg);
	}

	my $filename2 = $msg->{'file'} || die "no filename in reply";
	if ($filename2 ne $filename) {
		return (0, "submitItem(file=$filename) = $filename2");
	}
	$seq = $msg->{'checkSequenceNumber'};
	die "no sequenceNumber in reply" if (not defined $seq);

	($rc, $msg) = $self->transaction(
		['cmd'=>'submitPart',
			'_insertpart'=>'1',
			'partnum'=>'-1',
			'file'=>$filename,
			'_Type'=>'',
			'_newText'=>$text,
			'checkSequenceNumber'=>$seq,
			'_zzverify'=>'zz']);
	my $seq2 = $msg->{'checkSequenceNumber'};
	die "no sequenceNumber in reply" if (not defined $seq2);
	die "sequence number didn't advance" if ($seq2 != $seq+1);

	# THANKS Scott M Parrish <sparrish@fc.hp.com> for pointing out
	# that by returning $filename allocated here, the caller will be able to
	# add a hierarchy of answers.
	return ($rc, $filename, "(submitPart) ".$msg);

	# TODO: allow user to give alternate ID
}

=back

=head1 REQUIRES

=over 4

=item L<LWP> and its hierarchy of helper classes.

=back

=cut

# =head1 EXAMPLES
# 
# =over 4
# 
#  my $item = $fom->getItem('1');
#  print $fom->displayHTML({'render'=>'text'});
# 
# Displays a sloppy text rendering of item number 1. (It is far better to
# ask the CGI to do the rendering, however.)

# private functions

sub getMirrorList {
	my $self = shift;

	if (not $self->{'force'}
		and defined $self->{'mirrorCached'}) {
		return (1, 'mirror list in cache');
	}
	
	# attempt to get a local copy from disk
	my $mirrorFilename = $self->{'cachePath'} . "/.fomapi-mirrorCached";
	my $cachetime = -M $mirrorFilename;
	if (not defined $cachetime
		or $cachetime > $self->{'cacheTimeout'}) {
		# cache not there or too old to be useful. Go to server to get info.
		my ($rc, $msg) = $self->transaction(['cmd'=>'mirrorServer'], 'raw');
		return ($rc, $msg) if (not $rc);
	
		$self->{'mirrorCached'} = $msg;

		# write cache file
		open MCACHE, ">$mirrorFilename";
		print MCACHE $msg;
		close MCACHE;
	} else {
		# cache is valid enough for today
		open MCACHE, "<$mirrorFilename";
		my @lines = <MCACHE>;
		close MCACHE;

		$self->{'mirrorCached'} = join('', @lines);
	}

	$self->parseMirrorList();
	return (1, 'mirror list retrieved');
}

sub parseMirrorList {
	my $self = shift;

	my @lines = split(/\n/, $self->{'mirrorCached'});
	my @items = grep { m/^item / } @lines;
	@items = map { my @f = split(' '); \@f; } @items;
	my @cats = grep { $_->[3] eq 'Category' } @items;

	if ($self->{'debug'} || '') {
		print map { "c: ".join(" ", @{$_})."\n" } @cats;
	}

	$self->{'categories'} = [ map { [ $_ ] } @cats ];

	my $itemURL = (split(' ', (grep { m/^itemURL/ } @lines)[0]))[1];
	$self->{'itemURL'} = $itemURL;

	return (1, 'successfully acquired mirror list');
}

sub catByName {
	my $self = shift;
	my $fn = shift;

	if (not $self->{'cathash'}) {
		$self->{'cathash'} = { map { ($_->[0], $_) } @{$self->catnames()} };
	}

	return $self->{'cathash'}->{$fn};
}

sub catnames {
	my $self = shift;

	if ($self->{'force'}
		or not defined $self->{'catsCached'}) {

		my $catFilename = $self->{'cachePath'} . "/.fomapi-catCached";
		my $cachetime = -M $catFilename;
		if (not defined $cachetime
			or $cachetime > $self->{'cacheTimeout'}) {
			my @catlist = ();
			$self->getMirrorList();
			foreach my $cat ($self->getCategories()) {
				my ($rc, $item) = $self->getItem($cat);
				return(wantarray() ? (0, $item) : 0) if (not $rc);
				my $itemfn = $item->getProperty('filename');
				my $parentfn = $item->getProperty('Parent');
				my $title = $item->getTitle();
				if ($self->{'debug'}||'') {
					print sprintf("%-5s %-5s %-30s\n",
						$itemfn, $parentfn, $title);
				}
				push @catlist, [$itemfn, $parentfn, $title];
			}
			open CCACHE, ">$catFilename";
			print CCACHE map {join(" ", @{$_})."\n"} @catlist;
			close CCACHE;
			$self->{'catsCached'} = \@catlist;
		} else {
			open CCACHE, "<$catFilename";
			my @lines = <CCACHE>;
			close CCACHE;
	
			@lines = map {chomp; [split(' ',$_,3)];} @lines;
	
			$self->{'catsCached'} = \@lines;
		}
	}

	return wantarray()
		? (1, $self->{'catsCached'})
		: $self->{'catsCached'};
}

sub userAgent {
	my $self = shift;

	my $ua = $self->{'userAgent'};
	if (not defined $ua) {
		# create a user agent object
		$ua = new LWP::UserAgent;
		$ua->agent("FAQ-OMatic-API/".$FAQ::OMatic::VERSION
			."-".$ua->agent());
		$self->{'userAgent'} = $ua;
	}

	return $ua;
}

sub getAuth {
	my $self = shift;

	if ($self->{'auth'} eq 'query') {
		print "FAQ username: ";
		FAQ::OMatic::flush('STDOUT');
		my $user = <STDIN>;
		chomp $user;

		print "FAQ password: ";
		FAQ::OMatic::flush('STDOUT');
		system('stty -echo');	# avoid echoing password if possible
		my $pass = <STDIN>;
		chomp $pass;
		system('stty echo');
		print "\n";				# we didn't echo the user's CR, so supply one
		FAQ::OMatic::flush('STDOUT');

		$self->setAuth($user, $pass);
	}

	return @{$self->{'auth'}};
}

sub transaction {
	my $self = shift;
	my $newparams = shift || [];
	my $rawContent = shift || '';	# don't try to parse content for 'isapi'

	# request the item to be added
	my $url = $self->{'url'};
	my $req = POST($url,
		'Content_Type'=>'form-data',
		'Content'=> [ 'isapi'=>'1', $self->getAuth(), @{$newparams}
		]);
	my $rep = $self->userAgent()->request($req);

	my $auth_content = $rep->content();
		# not sure why this comes out differently
	if ($auth_content =~ m/cmd=authenticate/) {
		return (undef, 'need authentication: '.$auth_content);
	}

	# return (0, 'debug');

	my $content = $rep->content();
	if (not $rawContent) {
		if (not $content =~ m/^isapi=1/) {
			$self->dumpresp($rep);
			return (undef, 'CGI did not understand isapi mode: '.$content);
		}
	
		# my %values = split(/[=\n]/, $content);
		my %values = ();
		my $pair;
		foreach $pair (split(/\n+/, $content)) {
			my ($key,$value) = split(/=/, $pair);
			$values{$key} = $value;
		}
		if ($self->{'debug'} || '') {
			print "successful reply to ".$req->content().":\n";
			print map { "v: $_ => ".$values{$_}."\n" } sort keys %values;
		}
		return (1, \%values);
	} else {
		# return unparsed content
		return (1, $content);
	}
}

sub dumpresp {
	my $self = shift;
	my $rep = shift;

	if ($self->{'debug'} || '') {
		print map { "r: $_ => ".$rep->{$_}."\n" } sort keys %{$rep};
		my $hdrs = $rep->headers();
		print map { "h: $_ => ".$hdrs->header($_)."\n" }
			sort keys %{$hdrs};
	}
}

1;
