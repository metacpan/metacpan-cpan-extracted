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
### The Slow module provides a mechanism for a long-running process to
### continue computing while letting the web browser get feedback sooner.

### An alternative would be nph-CGI (non-parsed headers, where flushed
### output is sent directly to the browser, rather than pausing in the
### server until it is complete), but
### (a) I don't know if browsers eventually give up on nph- input. (I don't
### think so, but it's an excuse. :v)
### (b) Using nph- would require that admin's web servers were configured
### to use it
### (c) admins would have to rename their CGI stub to nph-fom or somesuch;
### or have two CGI stubs, or something. What a mess.

package FAQ::OMatic::Slow;

use FAQ::OMatic;
use FAQ::OMatic::I18N;

my $reloadFrequency = 15;	# seconds
my $tailSize = 20;			# lines

sub split {
	my $cgi = FAQ::OMatic::dispatch::cgi();

	my $slowFile = "slow-output.".FAQ::OMatic::nonce();
	my $slowPath = $FAQ::OMatic::Config::metaDir."/".$slowFile;
	my $url = FAQ::OMatic::makeAref('-command'=>'displaySlow',
					'-changedParams' => { 'slowFile' => $slowFile },
					'-refType'=>'url');
	#$url .= "#cursor";	# make browser snap to bottom of page
	my $pid;

	if (($pid = fork())==0) {
		# child
		# close stdio so httpd will not wait for me to get done
		# and we'll let STDOUT go to the slow-output file, so we
		# can watch what has been happening
		open STDIN, "</dev/null";
		open SLOWFILE, ">$slowPath";
		open STDOUT, ">&SLOWFILE";	# redirect to $slowPath
		open STDERR, ">&SLOWFILE";
		# All "slow-capable" modules are expected to accept the filehandle
		# we return, and print to that instead.
		# This is because I thought mod_perl was somehow screwing up
		# my prints to STDOUT. It turns out I was just never flushing
		# them, and when the fork()ed child Apache::exit()ed, it went
		# back to its main loop to handle web requests(!), and the
		# file never got flushed. But this works pretty well, so we'll
		# stick with it.

		print SLOWFILE "<p>\n";

		return *SLOWFILE;
	} else {
		# parent
		# should display results in slowFile
		FAQ::OMatic::redirect($cgi, $url);
	}
}

sub childDone {
	close STDOUT;
	close STDERR;
	# can't unlink the file, as user will load it one more time?
	# But then he'll be gone -- what then? How to arrange for the
	# unlink?
}

sub display {
	my $params = shift;

	if (not $params->{'slowFile'} =~ m/^(slow-output.[p\d]+)$/) {
		FAQ::OMatic::gripe('error',
			"Taint check failed on ".$params->{'slowFile'});
	}

	my $slowFile = $1;
	my $url = FAQ::OMatic::makeAref('-command'=>'displaySlow',
					'-changedParams' => { 'slowFile' => $slowFile },
					'-refType'=>'url');
	#$url .= "#cursor";	# make browser snap to bottom of page
	# unfortunately, what appears to be a bug in Netscape foils
	# that trick. So I'll only display the bottom n lines
	# of the file, instead. Harrumph.

	my $slowPath = $FAQ::OMatic::Config::metaDir."/".$slowFile;
	if (not open SLOW, $slowPath) {
		FAQ::OMatic::gripe('error', "can't open $slowFile: $!");
	}
	print "Content-type: text/html\n";
	print "Refresh: $reloadFrequency; URL=$url\n";
	print "\n";

	my @tail = ();
	my $cropped = '<pre>';
	while (defined($_=<SLOW>)) {
		if ((not $params->{'wholeFile'})
			and (scalar(@tail) >= $tailSize)) {
			shift(@tail);
			$cropped = "<pre>...(cropped)...<br>\n";
		}
		push @tail, $_;
	}
	close(SLOW);
	print "<title>Slow page</title>\n";

	my $msg;
	print gettexta("This page will reload every %0 seconds,", $reloadFrequency);
	print " ";
	if ($params->{'wholeFile'}) {
		print gettexta("showing the entire process output.");
		$msg = gettexta("Show the tail of the process log");
	} else {
		print gettexta("showing the last %0 lines of the process output.", $tailSize);
		$msg = gettexta("Show the entire process log")
	}
	print "\n";
	my $url2 = FAQ::OMatic::makeAref('-command'=>'displaySlow',
		'-changedParams' => {'wholeFile' => !$params->{'wholeFile'}});
	print "[".$url2.$msg."</a>]\n";
	print "<hr>\n";

	print $cropped;
	print join('', @tail);
}

1;
