package HTML::Tag::Lang;
use strict;
use warnings;


our $VERSION 	= '1.00';

use base qw(Exporter);
our (@EXPORT_OK, %bool_descr,@month);
@EXPORT_OK = qw(%bool_descr @month);

our $language	= '';

BEGIN {
my @installed_langs = qw(it en);
sub language {
	my $LC_MESSAGES	=	$language;
	if (! $LC_MESSAGES) {
		foreach (@installed_langs) {
			$LC_MESSAGES = $_ if(exists $INC{"HTML/Tag/Lang/$_.pm"});
		}
	}
	if (! $LC_MESSAGES) {
		if (exists $ENV{'LC_MESSAGES'}) {
			$LC_MESSAGES=substr($ENV{'LC_MESSAGES'},0,2);
		} elsif (exists $ENV{'LANG'}) {
			$LC_MESSAGES=substr($ENV{'LANG'},0,2);
		} else {
			$LC_MESSAGES='en';
		}
	}
	$LC_MESSAGES='en' unless ($LC_MESSAGES);
	return lc($LC_MESSAGES);
}

	my $pkg = __PACKAGE__ . '::' . &language;
	eval "require $pkg";
	if ($@) {
		# try to switch to english language
		$pkg = __PACKAGE__ . '::en';
		eval "require $pkg";
		if ($@) {
			die "Error from requiring $pkg: $@";
		}
	}
	eval "import $pkg qw(\%bool_descr \@month)";
  if ($@) {
    die "Error importing from $pkg: $@";
  }
}

1;

# vim: set ts=2:
