package Gentoo::Probe::PkgFiles;
our($VERSION)=__VERSION__;
our(@ISA)=qw(Gentoo::Probe::Cmd);
use strict;$|=1;

use Gentoo::Probe::Cmd;
use Gentoo::Util;
use IO::File;


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
};
sub files_output($$$@){
	return $_[0]->output($_[2]);
};
sub	pkg_output($$$@){
	return $_[0]->output($_[1].":".$_[2]);
};
sub new(@){
	my $self = Gentoo::Probe::Cmd::new(@_);
	if ( $self->verbose() ) {
		*do_output=*pkg_output;
	} else {
		*do_output=*files_output;
	};
	return $self;
};
sub accept($$$@) {
	my $self = shift;
	my $base = join("/",shift,shift);
	local $\="";
	for ( @_ ) {
		my $fn = $self->vdb_dir()."/".$base . "-" . $_ . "/CONTENTS";
		my $fh = IO::File->new($fn) or die "open:$fn:$!\n";
		while(<$fh>){
			chomp;
			next unless s/^obj\s+//;
			next unless s/\s.*//;
			$self->do_output($base,$_);
		};
		close($fh);
	};
};
1;
