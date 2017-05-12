package Gentoo::Config;
use Carp;

our($VERSION)=__VERSION__;
our(@ISA) = qw(Inline::Python::Object);

use strict;$|=1;
BEGIN { 
	my $dir = "$ENV{HOME}/.Inline";
	-d "$dir" || mkdir "$dir" || die "cannot make $dir\n";
	-o "$dir" || die "$dir ain't mine\n";
	$ENV{PERL_INLINE_DIRECTORY}=$dir;
	$ENV{"PORTAGE_CALLER"} = "stealth_caller"
};
use Inline Python => <<'EOF';
import sys, os
import portage
class portset:
	def __init__(self):
		self.name = "portset"
	def keys(self):
		return portage.settings.keys()
	def put(self,x,y):
		portage.settings[x] = y
	def has_key(self,x):
		if x in self.keys():
			return 1
		return 0
	def _get(self,x):
		return portage.settings[x]	
EOF
sub get {
	my $self = shift;
	my $key = shift;

	if ( $key eq 'KEYS' ) {
		return $self->keys();
	} elsif ( $self->has_key($key) ) {
		return $self->_get($key);
	} elsif ( @_ ) {
		return shift @_;
	} else {
		croak("No value for $key, and no default provided");
	};
};
sub new {
	my ($class) = map { ref $_  || $_ } $_[0];
	my $body = Inline::Python::Object->new('__main__','portset');
	return bless($body,$class);
};
1;
