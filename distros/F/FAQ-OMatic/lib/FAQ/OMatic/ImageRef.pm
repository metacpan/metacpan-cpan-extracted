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
### ImageRef.pm
###
### Generates references to the images encoded in ImageData.pm
### (note this only makes sense for built-in images, not those sumbitted
### into the serve/bags/ directory.)
###

package FAQ::OMatic::ImageRef;

use FAQ::OMatic::Bags;

my %img_type = ();		# type of each image. constant; no mod_perl
						# cache problem
my %img_prop = ();		# properties of each image. constant; no mod_perl
						# cache problem

sub getImage {
	my $name = shift;

	require FAQ::OMatic::ImageData;	# put off loading this file unless someone
							# actually requests data (meaning we're running
							# img.pm). No reason any other invocation should
							# have to load all that image data up.
	my $data = $FAQ::OMatic::ImageData::img{$name};
	return '' if (not defined $data);

	$data =~ s/\n//gs;	# get rid of line terminators
	return pack("H".length($data), $data);
}

sub validImage {
	my $name = shift;

	return defined($img_type{$name});
}

sub getType {
	my $name = shift;

	my $typek = $img_type{$name};
	return '' if (not defined $typek);

	return "jpeg"	if ($typek eq 'jpg');
	return "gif"	if ($typek eq 'gif');
	return "beats-me";
}

sub getBagForImage {
	my $name = shift;
	my $typek = $img_type{$name};
	die "undefined name" if (not defined $name);
	die "undefined typek for img $name" if (not defined $typek);
	return "$name.$typek";
}

sub getImageUrl {
	my $name = shift;
	my $params = shift;
	my $forceBagWrite = shift || '';

	my $bagName = getBagForImage($name);

	my $bagUrl = FAQ::OMatic::makeBagRef($bagName, $params);

	my $bagPath = $FAQ::OMatic::Config::bagsDir.$bagName;
	if (-f $bagPath and not $forceBagWrite) {
		return $bagUrl;
	}
	if (not defined $FAQ::OMatic::Config::bagsDir) {
		# fail obviously if bagsDir not configured -- this
		# happens when upgrading versions
		return "x:";
	}

	# attempt to cache this image file in $bagsDir
	if (not open(CACHEIMAGE, ">$bagPath")) {
		FAQ::OMatic::gripe('problem',
			"write to $bagPath failed: $!");
		# TODO: write to cache failed. Notify admin?
		# in the meantime, supply user with dynamically-generated image file
		return FAQ::OMatic::makeAref('-command'=>'img',
			'-blastAll'=>1,
			'-changedParams'=>{'name'=>$name},
			'-refType'=>'url');
	}

	# bag is saved, now write a .desc file
	my $bagDesc = FAQ::OMatic::Bags::getBagDesc($bagName);

	$bagDesc->setProperty('SizeWidth', $img_prop{$name}{'SizeWidth'});
	$bagDesc->setProperty('SizeHeight', $img_prop{$name}{'SizeHeight'});
	$bagDesc->setProperty('SizeBytes', $img_prop{$name}{'SizeBytes'});
	$bagDesc->setProperty('Alt', $img_prop{$name}{'Alt'});
	FAQ::OMatic::Bags::saveBagDesc($bagDesc);

	print CACHEIMAGE getImage($name);
	close CACHEIMAGE;
	return $bagUrl;
}

sub getImageRef {
	my $name = shift;
	my $imgargs = shift;
	my $params = shift;

	return '&nbsp;' if (defined($FAQ::OMatic::Config::noImages));

	my $url = getImageUrl($name, $params);
	return "[bad image $name]" if (not $url);

	# look up size information to append to img tag
	my $bagName = getBagForImage($name);
	my $sw = FAQ::OMatic::Bags::getBagProperty($bagName, 'SizeWidth', '');
	my $swt = ($sw ne '') ? " width=$sw" : '';
	my $sh = FAQ::OMatic::Bags::getBagProperty($bagName, 'SizeHeight', '');
	my $sht = ($sh ne '') ? " height=$sh" : '';
	my $alt = FAQ::OMatic::Bags::getBagProperty($bagName, 'Alt', $name);

	if (wantarray) {
		return ("<img src=\"$url\" alt=$alt $imgargs$swt$sht>", $sw, $sh);
	} else {
		return "<img src=\"$url\" alt=\"$alt \" $imgargs$swt$sht>";
	}
}

sub getImageRefCA {
	my $name = shift;
	my $imgargs = shift;
	my $ca = shift;	 # Category or Answer
	my $params = shift;

	$name = ($ca ? 'cat' : 'ans').$name;

	return getImageRef($name, $imgargs, $params);
}

sub bagAllImages {
	# writes every image in ImageData to the bags dir
	my $imgname;
	foreach $imgname (sort keys %img_type) {
		FAQ::OMatic::maintenance::hprint(
				"<br>bagging ".getBagForImage($imgname)."\n");
		FAQ::OMatic::maintenance::hflush();
		getImageUrl($imgname, {}, 'forceBagWrite');
	}
}

# these properties are manually-defined, so they're not in the
# section of this file that gets automatically regenerated.
$img_prop{'ans-also'}{'Alt'}		= '(Xref)';
$img_prop{'ans'}{'Alt'}				= '(Answer)';
$img_prop{'ans-small'}{'Alt'}		= '(Answer)';
$img_prop{'baglink'}{'Alt'}			= '(Download)';
$img_prop{'cat-also'}{'Alt'}		= '(Xref)';
$img_prop{'cat-small'}{'Alt'}		= '(Category)';
$img_prop{'cat'}{'Alt'}				= '(Category)';
$img_prop{'help-small'}{'Alt'}		= '(?)';
$img_prop{'help'}{'Alt'}			= '(?)';

# to regenerate:
#:.,$-2!(cd ../../../img; ../dev-bin/encodeBin.pl -desc *)
$img_type{'ans-also'} = 'gif';

$img_prop{'ans-also'}{'SizeWidth'} = '21';
$img_prop{'ans-also'}{'SizeHeight'} = '14';
$img_prop{'ans-also'}{'SizeBytes'} = '128';

$img_type{'ans-del-part'} = 'gif';

$img_prop{'ans-del-part'}{'SizeWidth'} = '23';
$img_prop{'ans-del-part'}{'SizeHeight'} = '28';
$img_prop{'ans-del-part'}{'SizeBytes'} = '183';

$img_type{'ans-dup-ans'} = 'gif';

$img_prop{'ans-dup-ans'}{'SizeWidth'} = '24';
$img_prop{'ans-dup-ans'}{'SizeHeight'} = '23';
$img_prop{'ans-dup-ans'}{'SizeBytes'} = '182';

$img_type{'ans-dup-part'} = 'gif';

$img_prop{'ans-dup-part'}{'SizeWidth'} = '23';
$img_prop{'ans-dup-part'}{'SizeHeight'} = '32';
$img_prop{'ans-dup-part'}{'SizeBytes'} = '194';

$img_type{'ans-edit-part'} = 'gif';

$img_prop{'ans-edit-part'}{'SizeWidth'} = '32';
$img_prop{'ans-edit-part'}{'SizeHeight'} = '31';
$img_prop{'ans-edit-part'}{'SizeBytes'} = '285';

$img_type{'ans-ins-part'} = 'gif';

$img_prop{'ans-ins-part'}{'SizeWidth'} = '32';
$img_prop{'ans-ins-part'}{'SizeHeight'} = '32';
$img_prop{'ans-ins-part'}{'SizeBytes'} = '261';

$img_type{'ans-opts'} = 'gif';

$img_prop{'ans-opts'}{'SizeWidth'} = '23';
$img_prop{'ans-opts'}{'SizeHeight'} = '28';
$img_prop{'ans-opts'}{'SizeBytes'} = '131';

$img_type{'ans-reorder'} = 'gif';

$img_prop{'ans-reorder'}{'SizeWidth'} = '23';
$img_prop{'ans-reorder'}{'SizeHeight'} = '28';
$img_prop{'ans-reorder'}{'SizeBytes'} = '191';

$img_type{'ans-small'} = 'gif';

$img_prop{'ans-small'}{'SizeWidth'} = '18';
$img_prop{'ans-small'}{'SizeHeight'} = '14';
$img_prop{'ans-small'}{'SizeBytes'} = '100';

$img_type{'ans-title'} = 'gif';

$img_prop{'ans-title'}{'SizeWidth'} = '32';
$img_prop{'ans-title'}{'SizeHeight'} = '32';
$img_prop{'ans-title'}{'SizeBytes'} = '257';

$img_type{'ans-to-cat'} = 'gif';

$img_prop{'ans-to-cat'}{'SizeWidth'} = '29';
$img_prop{'ans-to-cat'}{'SizeHeight'} = '26';
$img_prop{'ans-to-cat'}{'SizeBytes'} = '223';

$img_type{'ans'} = 'gif';

$img_prop{'ans'}{'SizeWidth'} = '23';
$img_prop{'ans'}{'SizeHeight'} = '28';
$img_prop{'ans'}{'SizeBytes'} = '150';

$img_type{'baglink'} = 'gif';

$img_prop{'baglink'}{'SizeWidth'} = '21';
$img_prop{'baglink'}{'SizeHeight'} = '14';
$img_prop{'baglink'}{'SizeBytes'} = '103';

$img_type{'cat-also'} = 'gif';

$img_prop{'cat-also'}{'SizeWidth'} = '25';
$img_prop{'cat-also'}{'SizeHeight'} = '14';
$img_prop{'cat-also'}{'SizeBytes'} = '139';

$img_type{'cat-del-part'} = 'gif';

$img_prop{'cat-del-part'}{'SizeWidth'} = '32';
$img_prop{'cat-del-part'}{'SizeHeight'} = '27';
$img_prop{'cat-del-part'}{'SizeBytes'} = '208';

$img_type{'cat-dup-ans'} = 'gif';

$img_prop{'cat-dup-ans'}{'SizeWidth'} = '26';
$img_prop{'cat-dup-ans'}{'SizeHeight'} = '23';
$img_prop{'cat-dup-ans'}{'SizeBytes'} = '201';

$img_type{'cat-dup-part'} = 'gif';

$img_prop{'cat-dup-part'}{'SizeWidth'} = '32';
$img_prop{'cat-dup-part'}{'SizeHeight'} = '27';
$img_prop{'cat-dup-part'}{'SizeBytes'} = '201';

$img_type{'cat-edit-part'} = 'gif';

$img_prop{'cat-edit-part'}{'SizeWidth'} = '32';
$img_prop{'cat-edit-part'}{'SizeHeight'} = '31';
$img_prop{'cat-edit-part'}{'SizeBytes'} = '286';

$img_type{'cat-ins-part'} = 'gif';

$img_prop{'cat-ins-part'}{'SizeWidth'} = '32';
$img_prop{'cat-ins-part'}{'SizeHeight'} = '27';
$img_prop{'cat-ins-part'}{'SizeBytes'} = '250';

$img_type{'cat-new-ans'} = 'gif';

$img_prop{'cat-new-ans'}{'SizeWidth'} = '32';
$img_prop{'cat-new-ans'}{'SizeHeight'} = '32';
$img_prop{'cat-new-ans'}{'SizeBytes'} = '253';

$img_type{'cat-new-cat'} = 'gif';

$img_prop{'cat-new-cat'}{'SizeWidth'} = '32';
$img_prop{'cat-new-cat'}{'SizeHeight'} = '32';
$img_prop{'cat-new-cat'}{'SizeBytes'} = '245';

$img_type{'cat-opts'} = 'gif';

$img_prop{'cat-opts'}{'SizeWidth'} = '32';
$img_prop{'cat-opts'}{'SizeHeight'} = '27';
$img_prop{'cat-opts'}{'SizeBytes'} = '165';

$img_type{'cat-reorder'} = 'gif';

$img_prop{'cat-reorder'}{'SizeWidth'} = '32';
$img_prop{'cat-reorder'}{'SizeHeight'} = '27';
$img_prop{'cat-reorder'}{'SizeBytes'} = '207';

$img_type{'cat-small'} = 'gif';

$img_prop{'cat-small'}{'SizeWidth'} = '18';
$img_prop{'cat-small'}{'SizeHeight'} = '14';
$img_prop{'cat-small'}{'SizeBytes'} = '104';

$img_type{'cat-title'} = 'gif';

$img_prop{'cat-title'}{'SizeWidth'} = '32';
$img_prop{'cat-title'}{'SizeHeight'} = '32';
$img_prop{'cat-title'}{'SizeBytes'} = '232';

$img_type{'cat'} = 'gif';

$img_prop{'cat'}{'SizeWidth'} = '32';
$img_prop{'cat'}{'SizeHeight'} = '27';
$img_prop{'cat'}{'SizeBytes'} = '185';

$img_type{'checked-large'} = 'gif';

$img_prop{'checked-large'}{'SizeWidth'} = '20';
$img_prop{'checked-large'}{'SizeHeight'} = '24';
$img_prop{'checked-large'}{'SizeBytes'} = '139';

$img_type{'checked'} = 'gif';

$img_prop{'checked'}{'SizeWidth'} = '16';
$img_prop{'checked'}{'SizeHeight'} = '17';
$img_prop{'checked'}{'SizeBytes'} = '104';

$img_type{'help-small'} = 'gif';

$img_prop{'help-small'}{'SizeWidth'} = '16';
$img_prop{'help-small'}{'SizeHeight'} = '12';
$img_prop{'help-small'}{'SizeBytes'} = '108';

$img_type{'help'} = 'gif';

$img_prop{'help'}{'SizeWidth'} = '32';
$img_prop{'help'}{'SizeHeight'} = '24';
$img_prop{'help'}{'SizeBytes'} = '181';

$img_prop{'picker'}{'SizeWidth'} = '256';
$img_prop{'picker'}{'SizeHeight'} = '128';
$img_prop{'picker'}{'SizeBytes'} = '3189';

$img_type{'picker'} = 'jpg';

$img_type{'space-large'} = 'gif';

$img_prop{'space-large'}{'SizeWidth'} = '20';
$img_prop{'space-large'}{'SizeHeight'} = '25';
$img_prop{'space-large'}{'SizeBytes'} = '61';

$img_type{'space'} = 'gif';

$img_prop{'space'}{'SizeWidth'} = '16';
$img_prop{'space'}{'SizeHeight'} = '16';
$img_prop{'space'}{'SizeBytes'} = '55';

$img_type{'unchecked'} = 'gif';

$img_prop{'unchecked'}{'SizeWidth'} = '16';
$img_prop{'unchecked'}{'SizeHeight'} = '16';
$img_prop{'unchecked'}{'SizeBytes'} = '79';

$img_type{'cat-to-ans'} = 'gif';

$img_prop{'cat-to-ans'}{'SizeWidth'} = '29';
$img_prop{'cat-to-ans'}{'SizeHeight'} = '26';
$img_prop{'cat-to-ans'}{'SizeBytes'} = '213';


1;
