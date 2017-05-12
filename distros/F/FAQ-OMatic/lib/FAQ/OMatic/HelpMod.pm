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

### Help.pm
###
### Online, context-sensitive help system
###

package FAQ::OMatic::HelpMod;

use FAQ::OMatic;

my $helpIndex = {};		# constant; no mod_perl cache problems

sub hr {
	my $fileName = shift;
	my $title = shift;
	my $nick;
	$helpIndex->{$title} = [ $fileName, $title ];
	foreach $nick (@_) {
		$helpIndex->{$nick} = [ $fileName, $title ];
	}
}

hr('help000', 'Online Help', 'faq', '');
hr('help001', 'How can I contribute to this FAQ?');
hr('help002', 'Search Tips', 'search', 'searchForm');
hr('help003', 'Appearance Options', 'appearanceForm');
hr('help004', 'Authentication', 'authenticate');
hr('help005', "Editing an Item's Title and Options", 'editItem');
hr('help006', 'Moderator Options', 'moderatorOptions');
hr('help007', 'Editing Text Parts', 'editPart');
hr('help008', 'Making Links To Other Sites', 'makingLinks');
hr('help009', 'Making Links To Other FAQ-O-Matic Items', 'seeAlso');
hr('help010', 'Moving Answers and Categories', 'moveItem');

sub helpLookup {
	my $params = shift;
	my $target = shift;

	return @{ $helpIndex->{$target} || ["inv $target", 'Invalid Help Target'] };
}

sub helpFor {
	my $params = shift;
	my $target = shift;
	my $punctuation = shift || '';	# add only if button is presented

	return '' if (not $params->{'help'});
	my $file = $params->{'file'} || '';
	return '' if ($file =~ m/^help/);

	my ($helpFile, $helpName) = helpLookup($params, $target);

	return FAQ::OMatic::button(
		FAQ::OMatic::makeAref('-params'=>$params,
			'-changedParams'=>{'file'=>$helpFile,
				'editCmds'=>'hide'},
			'-target'=>'help'),
		"HELP: $helpName")
		.$punctuation
		."\n";
}

sub helpURL {
	my $params = shift;
	my $target = shift;

	my ($file, $name) = helpLookup($params, $target);

	return FAQ::OMatic::makeAref('-params'=>$params,
		'-changedParams'=>{'file'=>$file,
			'editCmds'=>'hide'},
		'-target'=>'help',
		'-refType'=>'url');
}

1;
