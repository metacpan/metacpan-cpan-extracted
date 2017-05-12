use ExtUtils::MakeMaker;
use Config qw(%Config);

#### Build information
my $statvfs_header = "sys/statvfs.h";
my $statvfs_symbol = "d_statvfs";
my $statvfs_header_def = "i_sysstatvfs";
my $define = "";


print "OS = $Config{osname}\n";

#### Windows
if($Config{osname} =~ /^MSWin/i) {
	print "This module does not support Windows.\n";
	die "You might try Filesys::DfPortable instead.\n";
}

#### Check for the existance of statvfs
if(check_statvfs()) {
	print "Building with statvfs ....\n";
}

else {
	print "Config module or include search could not find statvfs.";
	die "We could not find statvfs on this system.\n";
}


sub check_statvfs {
	print "Checking for statvfs .....\n";
	if(exists $Config{$statvfs_symbol} && defined $Config{$statvfs_symbol}) { 
		print "$statvfs_symbol is defined.\n";
		if(exists $Config{$statvfs_header_def} && defined $Config{$statvfs_header_def}) {
			print "$statvfs_header_def is defined.\n";
			return(1);
		}

		else {
			print "Weird, $statvfs_header_def is not defined.\n";
			#### Have never seen a system with statvfs and no sys/statvfs.h header
			#### Lets see if we can find one
			if(look_for_header($statvfs_header)) {
				return(1);
			}

			else {
				#### no idea what header would be
				print "Cannot find a $statvfs_header file\n";
				print "We will not try to build with statvfs\n";
				return(0);
			}
		}
	}

	else {
		print "$statvfs_symbol is not defined\n";

		if(look_for_header($statvfs_header)) {
			return(1);
		}

		else {
			#### don't use statvfs
			print "Cannot find a $statvfs_header file\n";
			print "We will not try to build with statvfs\n";
			return(0);
		}
	}

	return(0);
}


sub look_for_header {
my $header = shift;

  	my @header_inc = split(/\s+/, join(" ", $Config{usrinc}, $Config{locincpth}));
  	#my @header_inc = split(/\s+/, join(" ", $Config{usrinc}));
	foreach $header_path (@header_inc) {
		if(-f $header_path . '/' . $header) {
			print "Header found:" , $header_path . '/' . $header, "\n";
			return(1);
		}
	}

	return(0);
}


WriteMakefile(
    'NAME'	=> 'Filesys::Statvfs',
    'VERSION_FROM' => 'Statvfs.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> $define,     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    'XSPROTOARG' => '-prototypes' 
);
