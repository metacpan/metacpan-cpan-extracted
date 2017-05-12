package Gentoo::Probe::PkgOf;
our($VERSION)=__VERSION__;
our(@ISA)=qw(Gentoo::Probe::PkgFiles);
use strict;$|=1;

use Gentoo::Probe::Cmd;
use Gentoo::Probe::PkgFiles;
use Gentoo::Util;

our %fixed_args = (
	installed=>1,
	uninstalled=>0,
	versions=>1,
	builds=>0,
);
sub veto_args(%){
	my ( $self, $args ) = @_;
	for ( sort keys %fixed_args ) {
		confess "$_ makes no sense here" if defined $args->{$_};
		$self->{$_} = $fixed_args{$_};
	};
	($self->{xpats}, $self->{pats}) = ( ($self->{pats}||[]), [] );
};
sub accept($$$@) {
	my $self = shift;
	my $base = join("/",shift,shift);
	my @pats = @{$self->{xpats}};
	local $\="";
	for ( @_ ) {
		my $fname = $self->{vdb_dir}.'/'.$base . "-" . $_ . "/CONTENTS";
		local *FILE;
		my $res = open(FILE,"< $fname");
		return unless defined $res;
		while(<FILE>){
			chomp;
			next unless ($_) = m/^obj\s+(.+)\s+\S+\s+/;
			next unless $self->check_pats($_, @pats);
			$self->output($base.":".$_);
		};
		close(FILE);
	};
};
sub output() {
	my $self = shift;
	return unless grep { length } @_;
	local ($,,$\)=(",","\n");
	print @_;
}
