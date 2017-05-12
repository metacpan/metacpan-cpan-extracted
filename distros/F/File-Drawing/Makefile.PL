
####
# 
# The module ExtUtils::STDmaker generated this file from the contents of
#
# Docs::Site_SVD::File_Drawing 
#
# Don't edit this file, edit instead
#
# Docs::Site_SVD::File_Drawing
#
#	ANY CHANGES MADE HERE WILL BE LOST
#
#       the next time ExtUtils::STDmaker generates it.
#
#

use ExtUtils::MakeMaker;

my $tests = join ' ',unix2os('t/File/Drawing.t');


WriteMakefile(
    NAME => 'File::Drawing',
    DISTNAME => 'File-Drawing',
    VERSION  => '0.01',
    dist     => {COMPRESS => 'gzip',
                'gz' => 'gz'},
    test     => {TESTS => $tests},
    PREREQ_PM => {'File::Where' => '0.04',
                  'File::Revision' => '1.04',
                  'File::SmartNL' => '1.14',
                  'Data::Secs2' => '1.19',
                  'Data::SecsPack' => '0.04',
                  'Data::Startup' => '0.02',},
    

    ($] >= 5.005 ?     
        (AUTHOR    => 'SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>',
        ABSTRACT  => 'release, revise and retrieve contents to/from a drawing program module', ) : ()),
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

