package Gentoo::Probe::Cmd;
our($VERSION)=__VERSION__;
our(@ISA)=qw(Gentoo::Probe);
use strict;$|=1;

sub import { goto \&Exporter::import };
#use Text::Number;
use Carp;
use Gentoo::Probe;
use Getopt::WonderBra qw();

sub do_args(\%@);
sub usage(@);
##############################################################################
#  info for parsing and help.
##############################################################################
our(%act) = (
		"u"=>["uninstalled",      "include (only) uninstalled"],
		"i"=>["installed",        "include (only) installed"],
		'l'=>["latest",           "show only latest (implies -v)"],
		"c"=>["no_case",          "ignore case"],
		"C"=>["case",             "don't ignore case"],
		"d"=>["debug",            "debug"],
		"v"=>["versions",         "show versions"],
		"V"=>["verbose",          "verbose output"],
		"b"=>["builds",           "show ebuilds"],
	);

##############################################################################
#  constructor: arsed cmd linish args, and generates opts therefrom.
##############################################################################
sub new(@){
	my $class = shift;
	my %opts = map { %{$_} } shift if ref $_[0];
	do_args(%opts,@_) or usage(2,"do_args failed\n");
	my $self = Gentoo::Probe::new($class,\%opts);
	$self->veto_args(\%opts);
	return $self;
};
#############################################################################
# display usage
#############################################################################
sub usage(@) {
	my $code = @_;
	select (STDERR) if $code;
	print STDERR @_, "\n\n" if @_;
	print split qr/^\s+/m, qq(
		usage: $0 [-opts] <regex> ...
	);
	for ( sort { uc($a) cmp uc($b) } keys %act ) {
		print "   -", $_, "   ", $act{$_}->[1], "\n";
	};
	exit $code;
}
{
	package main;
	sub help { goto &Gentoo::Probe::Cmd::usage; };
	sub version { goto &Gentoo::Probe::Cmd::usage; };
}
#############################################################################
# parse up those args.
#############################################################################
sub do_args(\%@){
	die "usage: do_args(\\\%opts,\\\@args)"
		unless @_;
	my $opts = shift;
	return 1 unless @_;
	local $_;
	for ( sort keys %act ) {
		$opts->{name($_,1)}=undef;
	};
	@_=Getopt::WonderBra::getopt(join("",keys %act),@_);
	while(($_=shift @_) ne '--'){
		die "no dash in '$_'" unless s/^-//;
		my ( $key, $val ) = do_arg(argdata($_),$_,@_);
		$opts->{$key}=$val;
	};
	confess "expected '--'" unless $_ eq '--';
	@{$opts->{pats}}=@_;
	return 1;
};
sub do_arg($$\@){
	our($argdata,$arg) = @_;
	die "internal error: $_ slipped past:\n" unless defined $argdata;
	die "arg is undef" unless defined $arg;
	if ( ref $argdata eq 'CODE' ) {
		$argdata->();
	} else {
		local $_ = $argdata->[0];
		die "internal error" unless defined($_);
		my $val = s/^no_// ? 0 : 1;
		return ( $_, $val );
	};
};
sub argdata($){
	confess "undef?" unless defined $act{$_[0]};
	return $act{$_[0]};
}
sub desc($){
	return argdata($_[0])->[1];
};
sub name($;$){
	my ($flag,$base) = @_;
	local $_ =argdata($flag)->[0];
	s/^no_// if ( $base);
	return $_;
}
1;
