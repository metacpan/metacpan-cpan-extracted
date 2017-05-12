package HTTP::UserAgentString::Sys;

# Superclass for OS, Robot and Browser

use strict;

sub new($) {
	my ($pkg, $data) = @_;
	return bless($data, $pkg);
}

sub name($) { $_[0]->{name} }
sub url($) { $_[0]->{url} }
sub company($) { $_[0]->{company} }
sub company_url($) { $_[0]->{company_url} }
sub ico($) { $_[0]->{ico} }

1;
