use Module::Build;

# check that nvcc is present and available
my $nvcc_version = `nvcc -V`;
$nvcc_version =~ /NVIDIA/ or die "You must have nvcc (from nVidia's CUDA Toolkit) installed\n";

# check that we have access cl.exe if we're on a Windows system. (I suppose I
# should also check for gcc on Linux machines, but I don't expect that to ever
# be lacking.)
use Config;
if ($Config{osname} =~ /MSWin/) {
	my $cl_version = `cl /help`;
	$cl_version =~ /Microsoft/
		or die ("You must have cl.exe (Microsoft's compiler) installed\n"
								. "in order to run ExtUtils::nvcc\n");
	
	# Warn if they have cl.exe but used gcc to compile perl
	warn "You used gcc to compile perl, but nvcc will use cl.exe; proceed with caution\n"
		if $Config{cc} eq 'gcc';
}

my $build = Module::Build->new
	(
		module_name => 'ExtUtils::nvcc',
		# Didn't think this next line was necessary...
#		dist_version_from => 'ExtUtils::nvcc',
		license  => 'perl',
	);

$build->create_build_script;
