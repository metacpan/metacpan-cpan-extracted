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

package FAQ::OMatic::submitBag;

use CGI;
use FAQ::OMatic::Item;
use FAQ::OMatic;
use FAQ::OMatic::Auth;
use FAQ::OMatic::Bags;
use FAQ::OMatic::I18N;

sub main {
	my $cgi = FAQ::OMatic::dispatch::cgi();
	my $rt = '';
	
	my $params = FAQ::OMatic::getParams($cgi);

	FAQ::OMatic::mirrorsCantEdit($cgi, $params);
	
	#
	# jpell - Default filename if not specified.
	# THANKS to Jason Pell <jason.pell@callista.com.au> for submitting
	# these patches that improve bag handling.
	#
	my $clientFname = $params->{'_bagName'};
	# If _bagName not defined, use the filename instead.
	if($clientFname eq ''){
		my $bagData = $cgi->param('_bagData');
		if ($bagData){
			# Get the client clientFname here.
			$clientFname = $cgi->uploadInfo($bagData)->{'Content-Disposition'};
			if( $clientFname=~/ filename="?([^\";]*)"?/ ){
				$clientFname = $1;

				# Replace dos separators, so we can search for / only.
				$clientFname =~ tr/\\/\//;
				if($clientFname =~ m#^(.*/)?(.*)#s ){
					$clientFname = $2;
				}
			}
		}
	}

	my $bagName = FAQ::OMatic::Bags::untaintBagName($clientFname);

	if ($bagName eq '') {
		FAQ::OMatic::gripe('error', gettext("Bag names may only contain letters, numbers, underscores (_), hyphens (-), and periods (.), and may not end in '.desc'. Yours was")." \"$bagName\".");
	}

	if (-f $FAQ::OMatic::Config::bagsDir.$bagName) {
		# bag exists
		FAQ::OMatic::Auth::ensurePerm('-item'=>'',
			'-operation'=>'PermReplaceBag',
			'-restart'=>FAQ::OMatic::commandName(),
			'-cgi'=>$cgi,
			'-extraTime'=>1,
			'-xreason'=>'replace',
			'-failexit'=>1);
	} else {
		# new bag name
		FAQ::OMatic::Auth::ensurePerm('-item'=>'',
			'-operation'=>'PermNewBag',
			'-restart'=>FAQ::OMatic::commandName(),
			'-cgi'=>$cgi,
			'-extraTime'=>1,
			'-failexit'=>1);
	}

	# get the bag contents
	my $bagTmpName = 'newbag.'.FAQ::OMatic::nonce();
	if (not open(BAGFILE, ">".$FAQ::OMatic::Config::bagsDir.$bagTmpName)) {
		FAQ::OMatic::gripe('error', "Couldn't store incoming bag $bagName: $!");
	}
	# THANKS: to John Nolan <JNolan@n2k.com> for fixing the reference
	# to the filehandle returned by CGI.pm in the next line.
	my $sizeBytes = 0;
	my $buf;
	my $formDataHandle = $cgi->param('_bagData');

	if ($formDataHandle) {
		# The next line will make the 'use strict' pragma throw an error
		# if you're using an old CGI.pm. It has been tested and seen
		# to work with CGI.pm 2.46 and newer, so upgrade.
		while (bagread($formDataHandle, \$buf, 4096)) {
			print BAGFILE $buf;
			$sizeBytes += length($buf);
			# TODO: should have admin-configurable length limit here
			# TODO: and in similar submitPart.pm code
		}
		close BAGFILE;
	}

	if ($sizeBytes > 0) {
		if (not rename($FAQ::OMatic::Config::bagsDir.$bagTmpName,
					$FAQ::OMatic::Config::bagsDir.$bagName)) {
			FAQ::OMatic::gripe('error', "Couldn't rename "
					.$FAQ::OMatic::Config::bagsDir.$bagTmpName
					." to "
					.$FAQ::OMatic::Config::bagsDir.$bagName);
		}
		if (not chmod(0644, $FAQ::OMatic::Config::bagsDir.$bagName)) {
			FAQ::OMatic::gripe('problem', "chmod("
				.$FAQ::OMatic::Config::bagsDir.$bagName
				.") failed: $!");
		}
	} else {
		# no bag file sent; discard bag file
		if (not unlink($FAQ::OMatic::Config::bagsDir.$bagTmpName)) {
			FAQ::OMatic::gripe('problem', "Couldn't unlink "
					.$FAQ::OMatic::Config::bagsDir.$bagTmpName);
		}
	}

	# get bag description info
	my $bagDesc = FAQ::OMatic::Bags::getBagDesc($bagName);
	$bagDesc->setProperty('SizeWidth', $params->{'_sizeWidth'} || '');
	$bagDesc->setProperty('SizeHeight', $params->{'_sizeHeight'} || '');
	# don't change $sizeBytes property if we don't have a new valid value
	if ($sizeBytes > 0) {
		$bagDesc->setProperty('SizeBytes', $sizeBytes);
	}
	FAQ::OMatic::Bags::saveBagDesc($bagDesc);

	# add link to part if info provided
	my $partnum = $params->{'partnum'};
	$partnum = -1 if (not defined $partnum);
	if ($partnum>=0) {
		my $itemName = $params->{'file'} || '';
		my $item = new FAQ::OMatic::Item($itemName);
		my $part = $item->getPart($partnum);

		# TODO: Check that legal image extension!
		my $bagInline = $cgi->param('_bagInline');
		if("$bagInline" eq "y"){
			$part->{'Text'}.="\n<baginline:$bagName>\n";
		}else{
			$part->{'Text'}.="\n<baglink:$bagName>\n";
		}
		$item->saveToFile();
	}

	# update any items that depend on this bag
	# This is the only place that bags (or their .descs) can change,
	# currently, # so it's reasonable to do the dependency-drive
	# updates here. If it ever becomes the case that we write bags
	# in another place, factor this code out.
	foreach my $dependent
		(FAQ::OMatic::Item::getDependencies("bags.".$bagName)) {
		my $dependentItem = new FAQ::OMatic::Item($dependent);
		$dependentItem->writeCacheCopy();
	}

	my $url = FAQ::OMatic::makeAref('-command'=>'faq',
				'-params'=>$params,
				'-changedParams'=>{'partnum'=>'', 'checkSequenceNumber'=>''},
				'-refType'=>'url');
	FAQ::OMatic::redirect($cgi, $url);
}

sub bagread {
	my $formDataHandle = shift;
	my $buf = shift;

	my $rc;
	eval { $rc = read($formDataHandle, $$buf, 4096); };
	if ($@) {
		die "Error in multipart form code -- probably your version of "
			."CGI.pm. Message was:<br>\n"
			.$@;
	}
	return $rc;
}

1;
