use ExtUtils::MakeMaker;
use Config;

my %defines;

my @includes=(
  # Add common include files to begin with
  "//--BEGIN $Config{osname}",
  '#include <fcntl.h>',
  '#include <sys/socket.h>',
  '#include <sys/un.h>',
  '#include <stdio.h>',
  '#include <unistd.h>',
  '#include <poll.h>',
  '#include <sys/time.h>',
  '#include <sys/stat.h>',
);

#Do some OS detection here
for($Config{osname}){
	if(/darwin/){
		$defines{IO_FD_OS_DARWIN}=1;
    push @includes, (
      '#include <sys/event.h>',
      '#include <sys/uio.h>',
      '#include <sys/types.h>',
      '#define SOCK_NONBLOCK 0x10000000',
      '#define SOCK_CLOEXEC  0x20000000',
    );
	}
	elsif(/bsd/){
		$defines{IO_FD_OS_BSD}=1;
    push @includes, (
      '#include <sys/event.h>',
      '#include <sys/uio.h>',
      '#include <sys/types.h>',
    );
	}
	elsif(/linux/){
		$defines{IO_FD_OS_LINUX}=1;

    push @includes,(
      '#include <sys/sendfile.h>',
    );
	}
	elsif(/win32/){
		die "WIN32 Unsupported at this time"
	}
	else{
		die "Unsupported platform: $_"
	}
}

push @includes, "//--END $Config{osname}";
{
  open my $platform, ">", "platform.h" or die "Could not generate header file";
  print $platform join "\n", @includes;
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	MIN_PERL_VERSION=> "v5.36",
    NAME              => 'IO::FD',
    VERSION_FROM      => 'lib/IO/FD.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/IO/FD.pod', # retrieve abstract from module
    AUTHOR            => 'Ruben Westerberg <drclaw@mac.com>',
    LICENSE           => 'mit',
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => (join " ", map {"-D$_"} keys %defines), # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
    META_ADD => {
		"meta-spec" => {
			version => 2
		},
		resources=> {
			repository =>{
				type => "git",
				url => "git://github.com/drclaw1394/perl-io-fd.git",
				web => "http://github.com/drclaw1394/perl-io-fd",
			}
		}
	}

);

if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw());
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'IO::FD',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
