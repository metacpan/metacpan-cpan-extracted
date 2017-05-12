use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $DEFAULTINSTSCRIPT = "/usr/local/bin";
my @scripts = qw(cucaracha fiesta salsaconfig);

print "Directory to install scripts \[$DEFAULTINSTSCRIPT\]: ";
my $INSTALLSCRIPT = <>;
chomp $INSTALLSCRIPT;

if($INSTALLSCRIPT) {
	if(-d $INSTALLSCRIPT) {
		$DEFAULTINSTSCRIPT = $INSTALLSCRIPT;
	} else { die("$!"); }
}
print "The scripts will be installed in \"$DEFAULTINSTSCRIPT\" directory...\n";

WriteMakefile(
    NAME              => 'Mail::Salsa',
    VERSION_FROM      => 'lib/Mail/Salsa.pm', # finds $VERSION
    PREREQ_PM         => {
		MIME::Base64  => 3.05,
		MIME::Explode => 0.38,
		Digest::MD5   => 2.33
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Mail/Salsa.pm', # retrieve abstract from module
       AUTHOR         => 'Henrique M. Riberiro Dias <henrique.ribeiro.dias@gmail.com>') : ()),
    EXE_FILES         => [ map { "bin/$_" } @scripts ],
    INSTALLSCRIPT     => $DEFAULTINSTSCRIPT
);
