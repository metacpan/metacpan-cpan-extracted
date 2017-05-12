#!/usr/bin/perl
#
# vim: ft=perl 
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Gentoo-Probe.t'
# 
#########################
use strict;
# change 'tests => 1' to 'tests => last_test_to_print';
our(@mods);
BEGIN {
	use lib qw(blib/lib);
	@mods = ('lib',undef);
	while(defined($_=shift @mods)){
		my $path = $_;
		if ( m{/CVS$} ) {
			next;
		}
		if ( -d $_ ) {
			unshift(@mods, glob("$_/*"));
			next;
		} 
		if ( -f ) {
			local $\="\n\t";
			s{^lib/}{} and s{\.pm$}{} and s{/+}{::}g and push(@mods, $_);
			next;
		}
		warn "ignore: $path";
	}
	eval "use Test::More tests => ".(3*@mods+1);
}
#########################
package main;
$DB::single++;
$DB::single++;
$DB::single--;
eval q(use Gentoo::Probe;);
my $ver = $Gentoo::Probe::VERSION;
print "ver: $ver\n";
for( @mods ) {
	my $ms = sprintf "%-40s", "$_:";
	my $tv;
	my $c1 = sprintf q[use %s;], $_;
	my $c2 = sprintf q[$%s::VERSION], $_;
	eval $c1;
	is("$@","","$ms use");
	$tv = eval $c2;
	is("$@","","$ms got version");
	is($ver, $tv,"$ms version match");
}
#########################
package Test::Gentoo::Probe;
our(@ISA)=qw(Gentoo::Probe);
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = $class->SUPER::new(@_);
	return $self;
};
sub output {
	my $self = shift;
	local $_ = join("/", shift , shift);
	if ( @_ ) {
		my $pkg = $_;
		push(@{$self->{lines}}, map { $pkg . "-" . $_  } @_);
	} else {
		push(@{$self->{lines}}, $_ );
	};
};
sub run {
	my $self = shift;
	$self->{lines}=[];
	$self->SUPER::run(@_);
	return @{$self->{lines}};
};
package main;
my $probe = Test::Gentoo::Probe->new();
is(ref $probe, q(Test::Gentoo::Probe), "Got right class");
