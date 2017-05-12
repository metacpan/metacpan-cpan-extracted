package Gentoo::Util;
our($VERSION)=__VERSION__;
our @ISA = qw(Exporter);
use strict;$|=1;

use Carp qw(confess croak longmess);
use IO::Handle;
require Exporter;
sub import { goto &Exporter::import; };
our (@EXPORT) = qw(
	xmkdir    croak   confess  longmess   xrmdir  assert_defined
	linedump  xchdir  xrename  file2map
);
sub fail;
*fail = \&Carp::confess;
sub xloadmod(@) {
	while(@_) {
		eval "use ".shift;
		die "$@" if "$@";
	};
};
sub xrename($$){
	rename($_[0],$_[1]) and return 1;
	fail join("rename",join(",",@_),$!);
};
sub xchdir($) {
	chdir($_[0]) and return 1;
	fail "chdir:",join(",",@_),":$!\n";
};
sub xrmdir($) {
	rmdir($_[0]) and return 1;
	-d $_[0] or return 0;
	fail "rmdir:", @_, $!;
};
sub xmkdir($;$) {
	mkdir($_[0],$_[1]||0755) and return 1;
	-d $_[0] and return 0;
	fail "mkdir:", @_, $!;
};
sub chomped(@){
	grep { chomp || 1 } @_;
};
sub file2map($) {
	my (%res,$cnt);
	($cnt,@_) = grep { length } map { split } suck(shift);
	$_=1 for ( @res{(@_)} );
	\%res;
};
sub suck($){
	local $_ = shift;
	open(my $fh, $_) or fail "open:$_:$!\n";
	$fh->getlines();
};
sub linedump($){
	my $line = eval q(
		use Data::Dumper;
		${$Data::Dumper::{$_}}=1 for qw(Terse Useqq Purity Deparse);
		Dumper($_[0]);
	);
	return join(" ", split /\s*\n\s*/, $line  );
};
sub assert_defined_failed() {
	croak("assert_defined(".linedump([@_]).")");
};
sub assert_defined(@){
	for ( @_ ) {
		goto &assert_defined_failed unless defined;
	};
	return;
};
1;
