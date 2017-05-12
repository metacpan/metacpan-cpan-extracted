#
# $Id: code.pl,v 1.1.1.1 2004/09/22 17:32:58 coppit Exp $
#
#  Copyright (c) 2000-2001, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: code.pl,v $
# Revision 1.1.1.1  2004/09/22 17:32:58  coppit
# initial import
#
# Revision 0.1.1.1  2001/03/02 17:59:48  ram
# patch1: added.
#
# Revision 0.1  2001/03/01 14:46:55  manfredi
# Initial revision.
#
# $EndLog$
#

sub contains {
	my ($file, $pattern) = @_;
	local *FILE;
	local $_;
	open(FILE, $file) || die "can't open $file: $!\n";
	my $found = 0;
	while (<FILE>) {
		if (/$pattern/) {
			$found = 1;
			last;
		}
	}
	close FILE;
	return $found;
}

1;

