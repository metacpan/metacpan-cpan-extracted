
####
# 
# The module ExtUtils::STDmaker generated this file from the contents of
#
# Docs::Site_SVD::ExtUtils_SVDmaker 
#
# Don't edit this file, edit instead
#
# Docs::Site_SVD::ExtUtils_SVDmaker
#
#	ANY CHANGES MADE HERE WILL BE LOST
#
#       the next time ExtUtils::STDmaker generates it.
#
#

use ExtUtils::MakeMaker;

my $tests = join ' ',unix2os('t/ExtUtils/SVDmaker/Original.t','t/ExtUtils/SVDmaker/Revise.t');


WriteMakefile(
    NAME => 'ExtUtils::SVDmaker',
    DISTNAME => 'ExtUtils-SVDmaker',
    VERSION  => '0.10',
    dist     => {COMPRESS => 'gzip',
                'gz' => 'gz'},
    test     => {TESTS => $tests},
    PREREQ_PM => {'Archive::TarGzip' => '0.03',
                  'File::AnySpec' => '1.13',
                  'File::Maker' => '0.03',
                  'File::Package' => '1.16',
                  'File::SmartNL' => '1.14',
                  'File::Where' => '0',
                  'Text::Replace' => '0',
                  'Text::Column' => '0',
                  'Text::Scrub' => '1.17',
                  'Tie::Form' => '0.01',
                  'Tie::Layers' => '0.04',
                  'Tie::Gzip' => '1.15',},
    

    ($] >= 5.005 ?     
        (AUTHOR    => 'SoftwareDiamonds.com E<lt> support@SoftwareDiamonds.com E<gt>',
        ABSTRACT  => 'Generate Software Version Description (SVD) program modules and 
distribution files for CPAN.', ) : ()),
);



use File::Spec;
use File::Spec::Unix;
sub unix2os
{
   my @file = ();
   foreach my $file (@_) {
       my (undef, $dir, $file_unix) = File::Spec::Unix->splitpath( $file );
       my @dir = File::Spec::Unix->splitdir( $dir );
       push @file, File::Spec->catfile( @dir, $file_unix);
   }
   @file;
}

