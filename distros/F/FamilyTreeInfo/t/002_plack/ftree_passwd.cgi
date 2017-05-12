use strict;
use warnings;

use CGI qw(param);

#
# What it does:
# * Generates a family tree from a simple underlying data file.
# * A tree can be plotted based around any person in the tree.
# * Any number of levels of ancestors/descendants can be shown,
#   using the zoom in/out buttons.
# * Additional information can be entered about each person:
#      dates, email, web-page for any further info
#
#######################################################
# * Call the script with the following parameters
#   - type (tree, email, bdays, snames, etc)
#   - name (tree will be drawn for this person)
#   - levels (tree will have this no. levels above and below)
#   - password (if a password is required, or "demo")
#   - lang (languages, i.e en, de, hu, it, fr)
# * Pass these parameters or in GET format (like
#   type=tree;name=fred;levels=1;lang=en;password=dummy)
#
#######################################################
#
# For a demonstration of this software, and details of how the
# underlying data file is formatted, visit here:
# http://www.cs.bme.hu/~bodon/Simpsons/cgi/ftree.cgi
#

use FindBin;
use lib "$FindBin::Bin";
use lib "$FindBin::Bin/lib";
use FindBin qw($Bin);
use lib "$Bin/../lib";

my $family_tree;
my $type = CGI::param("type");
if(defined $type && $type eq "tree")
{
   require Ftree::FamilyTreeGraphics;
   $family_tree = Ftree::FamilyTreeGraphics->new($Bin.'/ftree_passwd.config');
}
else {
   require Ftree::FamilyTreeInfo;
   $family_tree = Ftree::FamilyTreeInfo->new($Bin.'/ftree_passwd.config');
}
$family_tree->main();

exit;
