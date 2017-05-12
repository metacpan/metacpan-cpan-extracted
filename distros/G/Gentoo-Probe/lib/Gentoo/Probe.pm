package Gentoo::Probe;
our ($VERSION) = q(1.0.6);
use strict; $|=1;

sub import { goto \&Exporter::import };
use Gentoo::Util;
use Cwd;
our(@mods);
my (%defs) = (
			'uninstalled'  =>  0,
			'installed'    =>  0,
			'case'         =>  1,
			'versions'     =>  0,
			'builds'       =>  0,
			'verbose'      =>  0,
			'latest'       =>  0,
			'pats'         =>  [],
			'cfgdir'       =>  undef,
			'portdir'      =>  undef,
			'vdb_dir'      =>  undef,
);
my $cfg;
sub cfg {
	$cfg ||= do {
		local $_ = eval q{
			use Gentoo::Config;
			new Gentoo::Config;
		};
		die "$@" if "$@";
		die "no cfg!" unless defined $_;
		$_;
	};
	$cfg;
};
sub output {
	my $self = shift;
	print @_, "\n";
};
sub portdir  {
	$_[0]->{portdir};
};
sub overdir {
	$_[0]->{overdir};
};
sub vdb_dir {
	$_[0]->{vdb_dir};
};
sub new {
	local $_;
	my $class = shift;
	my $passed = @_ ? shift : {};
	confess "usage: new Gentoo::Probe(\%parms) [got: ", $passed, "]" 
		unless ref $passed;
	my %data = ( %defs, %{$passed} );
	my $self=\%data;
	bless($self,$class);
	$self->gen_methods();
	for($self->{portdir}) {
		$_= cfg()->get(qw(PORTDIR)) unless defined;
	};
	for($self->{vdb_dir}) {
		$_= cfg()->get(qw(VDB_DIR),"/var/db/pkg") unless defined;
	}
	for($self->{overdir}) {
		$_= cfg()->get(qw(PORTDIR_OVERLAY),"") unless defined;
	};
	for ( @{$self}{qw(portdir vdb_dir overdir)} ) {
		next unless defined;
		$_ = getcwd()."/".$_ unless m{^/};
		$_.="/";
		s{/[./]*/}{/}g;
	};
	my $pats = $data{pats};
	if ( !defined($pats) ) {
		$pats = $data{pats} = [ ];
	} elsif ( ref $pats eq 'ARRAY' ) {
		# all is well
	} elsif ( ref $pats ) {
		die "got a ", ref $pats, " as pats\n";
	} else {
		$pats = $data{pats} = [ $pats ];
	}
	for ( @$pats ) {
		$_ = qr($_);
	}
	confess "\$pats should be an array ref!" unless ref $pats eq 'ARRAY';

	$self->{versions}=1 if $self->builds() || $self->latest();
	unless ( $self->{installed} || $self->{uninstalled} ) {
		$self->{installed} = $self->{uninstalled} = 1
	};
	return $self;
};
sub ls_uver($$) {
	my $self = shift;
	my $cat = shift;
	my $pkg = shift;
	my $pre = $self->{portdir}."/".$cat."/".$pkg."/$pkg-";
	my $len = length($pre);
	@_ = glob("${pre}*.ebuild");
	@_ = map { substr($_,$len) } @_;
	@_ = map { substr($_,0,-7) } @_;
	@_;
};
sub ls_iver($$) {
	my $self = shift;
	my $cat = shift;
	my $pkg = shift;
	my $pre = $self->{vdb_dir}."/".$cat."/".$pkg."-";
	my $len = length($pre);
	@_ = glob("${pre}[0-9]*");
	@_ = map { substr($_,$len) } @_;
	@_;
};
sub ls_pkgs($$){
	return map {
		if ( /^canna-2ch/ ) {
			s/-2ch-[0-9].*/-2ch/;
		} elsif ( /^font-adobe-\d+dpi/ ) {
			s/dpi-[0-9].*/dpi/;
		} else {
			s/-[0-9].*//;
		};
		$_;
	} ls_dirs( $_[0],$_[1] );
};
sub ls_dirs($$){
	my ( $dir, $allowfail ) = (shift,shift);
	if ( opendir(my $DIR, $dir) ) {
		my @x= readdir($DIR);
		@x=grep {
			$_ ne '.' && $_ ne 'CVS' && $_ ne '..' && -d $dir."/".$_
		} @x;
		return @x;
	};
	return () if $allowfail;
	confess "opendir:$dir:$!\n";
};
sub accept($$$@) {
	my ( $self, $cat, $pkg, @vers ) = @_;

	splice(@vers,0,-1) if ( $self->latest() );
	if ( $self->builds() ) {
		$cat = join("/", $self->portdir(),$cat);
		for ( @vers ) {
			$self->output(join("/",$cat,$pkg,$pkg."-".$_ .".ebuild"));
		};
	} elsif ( $self->versions() ) {
		for (@vers ) {
			$self->output($cat."/".$pkg."-".$_);
		};
	} else {
		$self->output($cat."/".$pkg);
	};
};
sub not_installed($$$){
	my ( $self, $cat, $pkg ) = @_;
	my $globspec = $self->vdb_dir()."/$cat/$pkg-[0-9]*/.";
	return !glob($globspec);
};
sub check_pats($@){
	my $self = shift;
	local $_ = shift;
	return 1 unless @_;
	for my $re ( @_ ) {
		#	confess "internal error" if ref $re ne 'Regexp';
		return 1 if /$re/;
	};
	return 0;
};
sub run($) {
	my $self=shift;
	my $idir = $self->vdb_dir();
	my $udir = $self->portdir();
	my @pats = @{$self->{pats}};

	my %cat;
	$cat{$_} = undef for(grep { /-/ } ls_dirs($udir,0));
	$cat{$_} = undef for(grep { /-/ } ls_dirs($idir,0));
	my $x=0;
	for my $cat ( sort keys %cat ) {
		my %pkg;
		$pkg{$_} |= 1 for(ls_pkgs("$udir/$cat",1));
		$pkg{$_} |= 2 for(ls_pkgs("$idir/$cat",1));

		if(!$self->installed()){
			for(keys %pkg) {
				delete $pkg{$_} if $pkg{$_} & 2;
			};
		};
		if(!$self->uninstalled()){
			for(keys %pkg) {
				delete $pkg{$_} unless $pkg{$_} & 2;
			};
		};

		for my $pkg ( sort keys %pkg ) {
			my $qua = $cat."/".$pkg;
			next unless $self->check_pats( $qua , @pats );
			if ( $self->versions() ) {
				my %ver;
				$ver{$_} |= 1 for $self->ls_uver($cat,$pkg);
				$ver{$_} |= 2 for $self->ls_iver($cat,$pkg);
#    				if(!$self->installed()){
#    					for(keys %ver) {
#    						delete $ver{$_} if $ver{$_} & 2;
#    					};
#    				};
				if(!$self->uninstalled()){
					for(keys %ver) {
						delete $ver{$_} unless $ver{$_} & 2;
					};
				};
				$self->accept($cat,$pkg,sort keys %ver);
			} else {
				$self->accept($cat,$pkg);
			}
		};
	}
};
sub gen_methods($) {
	my ($self) = @_;
	die 'ref \$self="',ref $self,'"' unless $self->isa("Gentoo::Probe");
	no strict 'refs';
	for my $key (keys %{$self}){
		*$key = sub{
			my $self = shift;
			my $slot = \$self->{$key};
			my $res = $$slot;
			$$slot = shift if @_;
			$res;
		} unless defined &$key;
	};
};
1;
