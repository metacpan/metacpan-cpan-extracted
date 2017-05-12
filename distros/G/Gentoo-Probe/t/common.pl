#!/usr/bin/perl
$|++;

package main;
use strict;
use Gentoo::Util;
use Test::More;
use Carp qw(confess);
use Cwd;
use IO::File;
use Gentoo::Probe;
use vars qw( $sandbox $portdir $vdb_dir %data );
use Tie::Handle;
$sandbox = getcwd()."/t/sandbox";
$portdir = "$sandbox/usr/portage/";
$vdb_dir = "$sandbox/var/db/pkg/";
%data = ( vdb_dir => $vdb_dir, portdir => $portdir,);

sub runtest(@) {
	my (%data,$k,$v) = %data;
	while(@_ > 1){
		($k,$v,@_) = @_;
		$data{$k}=$v;
	};
	confess "uneven args" if @_;
	confess "no base" unless length $data{base};
	confess "no file" unless length $data{rfile};
	$data{rfile}=$sandbox."/".$data{rfile};
	$data{base}="Gentoo::Probe::".$data{base};

	@Test::Gentoo::Probe::ISA = $data{base};
	unless ( -e $data{rfile} ) {
		print STDERR "Creating new ref file: ", $data{rfile},"\n";
		my $obj = new Test::Gentoo::Probe(\%data);
		$obj->make_ref();
		exit(1);
	};
	confess "$data{rfile} doesn't exist" unless -e $data{rfile};
	my $obj = new Test::Gentoo::Probe(\%data);
	$obj->run();
	return $obj;
};


package Test::Gentoo::Probe;
use Gentoo::Probe;
use Gentoo::Util;
use UNIVERSAL qw(can);
use Test::More;
our(@ISA);
sub new {
	my ($self,$can);
	eval "use $_;" for @ISA;
	confess unless ($can=$ISA[0]->can("new")) and ($self=$can->(@_));
	$self->{plist}=[];
	$self->{rlist}=[];
	return $self;
};
sub rlist {
	confess "usage: obj->rlist()" unless @_ == 1;
	confess "usage: Test::Gentoo::Probe->new()->rlist()" unless $_[0]->isa("Test::Gentoo::Probe");
	my $rlist = $_[0]->{rlist};
	confess "rlist not defined" unless defined $rlist;
	return $rlist;
};
sub plist {
	confess "usage: obj->plist()" unless @_ == 1;
	confess "usage: Test::Gentoo::Probe->new()->plist()" unless $_[0]->isa("Test::Gentoo::Probe");
	my $plist = $_[0]->{plist};
	confess "plist not defined" unless defined $plist;
	return $plist;
};
sub output {
	my $self = shift;
	confess "bad output: (@_)" unless grep({ defined } @_) == @_;
	local $_ = join("/",@_);
	$self->process;
	return unless defined;
	confess "bad process: $_\n" unless length;
	push(@{$self->plist},$_);
};
sub rfile() {
	return ( $_[0]->{rfile} || confess "rfile not set" );
}
sub make_ref() {
	my $self = $_[0];
	my $rfile = $self->rfile();
	my $plist = $self->plist();
	$self->Gentoo::Probe::run;
	local ($,=$\="\n");
	unshift(@{$plist},scalar(@{$plist}));
	new IO::File($rfile,">")->print(@{$plist});
};
sub run {
	my ($self, $rlist, $plist,$cnt) = ($_[0],$_[0]->rlist,$_[0]->plist);
	($cnt,@{$rlist}) = (new IO::File($self->rfile(),"<")->getlines());
	chomp(@{$rlist});
	confess "line count != #lines in ".$self->rfile() unless $cnt == @{$rlist};
	$self->SUPER::run();
	is(scalar(@$plist),scalar(@$rlist),"sizes match '".$self->rfile()."'");
	is_deeply($plist,$rlist,"lists match '".$self->rfile()."'");
	delete $self->{rlist};
	delete $self->{plist};
};
1;
