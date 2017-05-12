#!/usr/bin/perl -w

package Exception::ThrowUnless;

require Exporter;
use strict;
use File::Spec::Functions;

our(@ISA)=qw(Exporter);
our $VERSION = "1.11";
our @EXPORT_OK = qw(
	schdir      schmod  sclose       sexec  sfork      slink
	smkdir      sopen   sopendir     spipe  sreadlink  srename
	srename_nc  srmdir  ssocketpair  sspit  ssuck      ssymlink
	sunlink
);
our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

sub _throw(@) {
	eval q[
		use Carp;
		*Exception::_throw = \&Carp::confess;
	];
	goto &Carp::confess;
	die "$@";
};
sub _checktrue($@) {
	_throw splice(@_,1) unless $_[0];
	$_[0];
};
sub _checkdef($@) {
	_throw splice(@_,1) unless defined $_[0];
	$_[0];
};
sub schdir($){
	_checktrue(chdir($_[0]),"chdir:$_[0]:$!");
};
sub srmdir(;$) {
	local $_ = shift if @_;
	_checktrue(rmdir($_),"rmdir:$_:$!\n");
};
sub schmod(@) {
	local $"=',';
	return @_-1 if ( chmod(@_) == @_-1 );
	_throw("chmod:@_:$!");
};
sub sclose(*){
	local $_ = shift;
	return 1 if close($_);
	die "close:$_:$!";
};
sub sexec(@){
	exec @_;
	die _throw "exec (@_):$!";
};
sub sfork() {
	_checkdef(fork,"fork:$!");
};
sub slink($$) {
	my ($f,$t) = @_;
	_checkdef(link($f, $t),"link:$f,$t:$!");
};
sub smkdir($$) {
	my ( $dir, $mode ) = @_;
	my $res = mkdir $dir, $mode;
	return $res if $res;
	return $res if -d $dir && $! == 17;
	_throw "smkdir:$dir:$! and is not a directory" if $! == 17;
	_throw "smkdir:$dir:$!";
};
sub sopen(\*$) {
	_checkdef(open($_[0],$_[1]),"open:$_[0],$_[1]:$!");
};
sub sopendir(\*$){
	_checkdef(opendir($_[0],$_[1]),"opendir:$_[0],$_[1]:$!\n");
};
sub spipe(\*\*){
	_checkdef(pipe($_[0],$_[1]),"pipe:@_:$!");
};
sub sreadlink($) {
	_checkdef(readlink($_[0]),"readlink:$_[0]:$!");
};
sub srename($$) {
	my ($f,$t) = @_;
	_checkdef(rename($f,$t),"rename:$f,$t:$!");
};
sub srename_nc($$) {
	my ($f,$t) = @_;
	-e $t || -l $t && _throw "won't clobber '$t'";
	srename($f,$t);
};
sub ssocketpair(\*\*$$$) {
	_checkdef(socketpair($_[0],$_[1],$_[2],$_[3],$_[4]),"socketpair:@_:$!");
};
sub ssuck(@);
sub ssuck(@){
	warn "useless ssuck in void context" unless defined wantarray;
	return join("",ssuck(@_)) unless wantarray;
	map { local $_="<$_"; sopen(local *F,$_); $_=[<F>]; sclose(*F);@$_; } @_;
};
sub ssymlink($$) {
	_checktrue(symlink($_[0],$_[1]),"symlink:$_[0],$_[1]:$!");
};
sub sunlink(@) {
	unlink(@_) == @_ && return scalar(@_);
	for ( @_ ) {
		-l $_ || -e $_ || next;
		unlink($_) && next;
		_throw "unlink:$_:$!";
	}
	return scalar(@_);
};
{
	no warnings 'once';
	eval join("",<DATA>) unless caller;
}
1;
__DATA__
$\=undef;
$_=join("",<STDIN>);
s/\s*;\s*/;/;

@subs = grep { length && !/^\s*;\s*$/ } split /^(sub\s+.*?^})\s*;?\s*/ms;

print shift @subs;
print shift @subs;
$after = pop @subs;
$,=";\n";
print "", sort(@subs), $after;
