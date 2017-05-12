use ExtUtils::MakeMaker;
use Config qw(%Config);

#we need to generate a file that contains the hash keys in a easy to digest
#format in C, if the key names are included as const static data in the DLL
#it is a complete waste of trying to do this, since that data in the const
#static DLL section will be used only once in the process's lifetime yet kept
#for the rest of the process's lifetime in RAM
#by putting the key names in a separate file, it is guarenteed they will be
#freed by perl and the OS

#The description of the file format should be better documented here
open(my $hvkeysfh, '<', 'hvkeys.h')  or die "Could not open hvkeys.h: $!";
binmode($hvkeysfh);
sysread($hvkeysfh, $hvKeysFile, -s 'hvkeys.h');
close($hvkeysfh);

my @keys = $hvKeysFile =~ /XMM\((.+?)\)/gs;
die "hvkeys.h is corrupt " if ! @keys;
my $stringsStart = length(pack('J', 0)) * @keys * 2 + length(pack('J', 0));
my $hvkeystruct = pack('J', length(join('',@keys)) + @keys + $stringsStart);
#+ @keys is null chars
$strCat = '';
foreach (@keys) {
    $hvkeystruct .= pack('J', $stringsStart+length($strCat));
    $hvkeystruct .= pack('J', length($_));
    $strCat .= $_."\0";
}
die "assert 0" if length($hvkeystruct) !=  $stringsStart;
$hvkeystruct .= $strCat;

open(my $hvkeysinit, '>', './lib/Example/XS/FasterHashes/hvkeysinit.bin')
or die "Could not open ./lib/Example/XS/FasterHashes/hvkeysinit.bin: $!";
binmode($hvkeysinit);
syswrite($hvkeysinit, $hvkeystruct);
close($hvkeysinit);

WriteMakefile(
    NAME              => 'Example::XS::FasterHashes',
    VERSION_FROM      => 'lib/Example/XS/FasterHashes.pm', # finds $VERSION
    PREREQ_PM         => {'Time::HiRes' => 0},
    BUILD_REQUIRES    => {'Time::HiRes' => 0}, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Example/XS/FasterHashes.pm', # retrieve abstract from module
       AUTHOR         => 'Daniel Dragan bulkdd cpan.org') : ()),
    LIBS              => [''],
    DEFINE            => '',
    INC               => '-I.',
    XSOPT             => ' -nolinenumbers ',
    clean             => {FILES => './lib/Example/XS/FasterHashes/hvkeysinit.bin'},
);