package MegaDistro::Config;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(%args %Conf);
our @EXPORT_OK = qw(pre push_libs build_clean help $DEVNULL);
our %EXPORT_TAGS;
$EXPORT_TAGS{'default'} = \@EXPORT;

use File::Path;
use File::Spec::Functions qw(:ALL);


# Hash containing the various directories to be used by the system
our %Conf;

# Hash containing the various command-line arguements, passed to the program,
our %args;

sub init_config {
	my %overrides = @_;

	%Conf = %overrides;

	$Conf{'homedir'}    ||= $ENV{HOME};

	$Conf{'rootdir'}    ||= catdir($Conf{'homedir'}, '.megadistro');

	$Conf{'fetchdir'}   ||= catdir($Conf{'rootdir'}, 'Fetch');
	$Conf{'extractdir'} ||= catdir($Conf{'rootdir'}, 'Extract');
	$Conf{'builddir'}   ||= catdir($Conf{'rootdir'}, 'Build');

	# do not change!
	# (used to adjust path, when makemakerflags
	#    uses PREFIX instead of DESTDIR).
	$Conf{'prefixdir'}  ||= catdir($Conf{'builddir'}, 'usr');
	
	# Configurable Files used in building the package

	$Conf{'modlist'}    ||= catfile($Conf{'rootdir'}, "modules.list");

	# Make everything absolute in case we chdir.
	for my $key (grep !/^disttype$/, keys %Conf) {
	    $Conf{$key} = rel2abs($Conf{$key});
	}

	if ( $Conf{disttype} && $Conf{disttype} !~ /^(rpm|deb)/i ) {
	    die "Invalid package type! - Valid types are: rpm , deb" . "\n";
	}

	# HACK:  Let the other config modules see our changes.
	require MegaDistro::RpmMaker::Config;
	require MegaDistro::DebMaker::Config;
	MegaDistro::RpmMaker::Config::_init_globals();
	MegaDistro::DebMaker::Config::_init_globals();

	for my $key (keys %Conf) {
	    print "$key: $Conf{$key}\n" if $args{debug};
	}
}
init_config();


#
# Other random configurables
#
# /dev/null
our $DEVNULL = '/dev/null 2>&1';

#
# Preparation
#
sub pre {
	if ( $args{'trace'} ) {
		print 'MegaDistro::Config : Executing sub-routine: pre' . "\n";
	}
	
	if ( ! -d "$Conf{'fetchdir'}" ) {
		if ( $args{'debug'} ) {
			print "\t" . 'Fetch directory: ' . $Conf{'fetchdir'} . ' does not exist, creating it' . "\n";
		}
		mkpath $Conf{'fetchdir'};
	}
	if ( ! -d "$Conf{'extractdir'}" ) {
		if ( $args{'debug'} ) {
			print "\t" . 'Extract directory: ' . $Conf{'extractdir'} . ' does not exist, creating it' . "\n";
		}
		mkpath $Conf{'extractdir'};
	}
	if ( ! -d "$Conf{'builddir'}" ) {
		if ( $args{'debug'} ) {
			print "\t" . 'Build directory: ' . $Conf{'builddir'} . ' does not exist, creating it' . "\n";
		}
		mkpath $Conf{'builddir'};
	}
	
	&build_tree;
}

use Config;

sub prop_libs {
	my @add_libs;
	push @add_libs, catdir($Conf{'builddir'}, $Config{'installarchlib'});
	push @add_libs, catdir($Conf{'builddir'}, $Config{'installvendorarch'});
	push @add_libs, catdir($Conf{'builddir'}, $Config{'installvendorlib'});
	return @add_libs;
}

sub push_libs {
	my @add_libs = &prop_libs;
	for (@add_libs) {	#optional reverse.
		unshift @INC, $_;
	}
}

sub build_tree {
	my @build_libs = &prop_libs;
	for (@build_libs) {
		mkpath $_ if ! -d "$_";
	}
}

sub build_clean {

	rmtree "$Conf{'builddir'}/*";

}

sub help { #perhaps replace with <<
	print "\n";
	print "Usage: Configure [OPTION]... [--disttype=TYPE]" . "\n";
	print "  or:  Configure [-q] [-dxv] [-t TYPE]" . "\n";
	print "  or:  Configure [-h]" . "\n";
	print "Run the Configure system, and specify package type." . "\n";
	print "\n";
	print "The following arguements are all optional,"                                       . "\n";
	print "    however you should always specify the package type."                          . "\n";
	print "\n";
	print "  -h, --help                                displays this help information"       . "\n";
	print "  -t TYPE, --disttype=TYPE                  package type to build - "             . "\n";
	print "                                              valid types are 'deb' and 'rpm'"    . "\n";
	print "  -v, --verbose                             verbose output"                       . "\n";
	print "                                              (not recommended)"                  . "\n";
	print "  -d, --debug                               debbuging output"                     . "\n";
	print "                                              (for development only)"             . "\n";
	print "  -q, --quiet                               only display status information"      . "\n";
	print "                                              (obsolete)"                         . "\n";
	print "  -x, --trace                               trace the program execution"          . "\n";
	print "                                              (for development only)"             . "\n";
	print "      --clean                               completely removes everything"        . "\n";
	print "                                              from BUILDDIR"                      . "\n";
	print "      --force                               forces the install of all modules"    . "\n";
	print "                                              (use carefully!)"                   . "\n";
	print "      --build-only                          skips the packaging phase,"           . "\n";
	print "                                              builds snapshot of build-tree"      . "\n";
	print "      --modlist=FILE                        set the module list to use"           . "\n";
	print "      --fetchdir=DIR                        set directory to download modules"    . "\n";
	print "      --extractdir=DIR                      set directory to extract modules"     . "\n";
	print "      --builddir=DIR                        set directory for built modules"      . "\n";
	print "\n";
}

1;
