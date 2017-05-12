
####
# 
# The module ExtUtils::STDmaker generated this file from the contents of
#
# Docs::Site_SVD::File_Where 
#
# Don't edit this file, edit instead
#
# Docs::Site_SVD::File_Where
#
#	ANY CHANGES MADE HERE WILL BE LOST
#
#       the next time ExtUtils::STDmaker generates it.
#
#

use ExtUtils::MakeMaker;

my $tests = join ' ',unix2os('t/File/Where.t');


WriteMakefile(
    NAME => 'File::Where',
    DISTNAME => 'File-Where',
    VERSION  => '0.05',
    dist     => {COMPRESS => 'gzip',
                'gz' => 'gz'},
    test     => {TESTS => $tests},
    
    

    ($] >= 5.005 ?     
        (AUTHOR    => 'SoftwareDiamonds.com E<lt> support@SoftwareDiamonds.com E<gt>',
        ABSTRACT  => 'The subroutines in C<File::Where> program module finds the absolute file or dir for a
program module, program module repository, relative file, or relative directory
by searching the directories in the @INC array of directories or an
override array of directories. The C<File::Where> program module also contains
subroutines to find all the program modules in a repository or directory.
The File::Where supercedes the C<File::PM2File>
program module and the C,File::SubPM program module>.', ) : ()),
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

