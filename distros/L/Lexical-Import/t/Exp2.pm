package t::Exp2;

use warnings;
use strict;

sub VERSION {
	return undef if @_ == 1;
	my($exporter, $version) = @_;
	my $importer = caller(0);
	no strict "refs";
	if($version == 1) {
		*{"${importer}::successor"} = sub ($) { $_[0] + 1 };
	} elsif($version == 2) {
		*{"${importer}::predecessor"} = sub ($) { $_[0] - 1 };
	} else {
		die "unrecognised version for importation";
	}
}

sub import { die if @_ != 1; }

sub unimport {
	die if @_ != 1;
	my $importer = caller(0);
	no strict "refs";
	*{"${importer}::identity"} = sub ($) { $_[0] };
}

1;
