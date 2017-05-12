#!/usr/bin/perl
# vim: ft=perl 
#########################

use Carp; 
use strict;
use Test::More;
my %data=(
	uninstalled => 1,
	installed => 1,
	case => 1,
	versions => 1,
	latest => 3.14159,
	builds => 1,
	portdir => "$ENV{PWD}/t/sandbox/usr/portage/////",
	vdb_dir => "$ENV{PWD}/t/sandbox/var/db/pkg"
);
sub mod_name {
	local $_ = shift;
};
sub find_mods(){
	local @_ = qw(lib);
	my @res;
	while(@_){
		local $_ = shift;
		local $\="\n";
		for ( glob("$_/*"), glob("$_/.*") ) {
			next if m{/\.\.?$};
			if ( -d ) {
				push(@_,$_) unless m{/CVS$};
			} elsif ( m{\.pm$} ) {
				($_) = join("::", map { split m{/+}, $_ } m{^lib/(.*)\.pm});
				push(@res, $_);
			} else {
				print;
			};
		};
	};
	return map { mod_name $_ } @res;
};
my @mods = find_mods();
plan( tests => 1+(keys %data)+@mods);
for ( @mods ) {
	use_ok($_);
};
my $test2 = Gentoo::Probe->new({ %data });
sub data_test($){
	my $key = shift;
	my $val = $data{$key};
	$val =~ s{/*$}{/} if ( $key eq 'portdir' || $key eq 'vdb_dir' );

	my $objval = eval "\$test2->$_()";
	confess "$@" if "$@";
	is($objval,$val,$key);
}
for ( keys %data ) {
	data_test($_);
};
eval { xchdir("/"); };
is($@,"","xchdir without throw");
