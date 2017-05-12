###############
# MAKEFILE.PL #
###############

use Config;
use ExtUtils::MakeMaker;
use ExtUtils::Embed ();

my $embed = 'myldr/LibZipBin' . $Config{_exe} ;

WriteMakefile(
    'NAME'          => 'LibZip' ,
    'VERSION_FROM'  => 'lib/LibZip.pm' ,
    'EXE_FILES'     => [ qw(script/libzip) ],
    'PREREQ_PM'		=> {
    'Pod::Stripper'  => '0.22' ,
    'Compress::Zlib' => '1.33' ,
    'Archive::Zip'   => '1.05' ,
    } ,
    ($] >= 5.005 ?
      ( ABSTRACT_FROM => 'lib/LibZip.pod',
        AUTHOR        => 'Graciliano M. P. <gmpassos@cpan.org>'
       ) : ()
     ),
);

package MY;

sub postamble {
  my $arch = "blib/arch/auto/LibZip" ;
  return <<EOT;

all :: copy_embed

copy_embed : subdirs
	\$(MKPATH) "$arch"
	\$(CP) "$embed" "$arch"

EOT
}

1;

