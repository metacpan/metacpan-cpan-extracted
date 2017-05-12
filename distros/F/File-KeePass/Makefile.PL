use ExtUtils::MakeMaker;

###----------------------------------------------------------------###
#  Copyright 2010 - Paul Seamons                                     #
#  Distributed under the GNU General Public License without warranty #
###----------------------------------------------------------------###

WriteMakefile(
              NAME          => "File::KeePass",
              AUTHOR        => "Paul Seamons",
              ABSTRACT_FROM => "lib/File/KeePass.pm",
              VERSION_FROM  => "lib/File/KeePass.pm",
              INSTALLDIRS   => 'site',
              PREREQ_PM     => {
                  'Crypt::Rijndael' => '1.0',
                  'Digest::SHA'     => '1.0',
                  'MIME::Base64'    => '1.0',
                  #'Compress::Raw::Zlib' => '1.0', # not a requirement for v1 only infrastructure
                  #'XML::Parser'     => '1.0', # not a requirement for v1 only infrastructure
              },
              dist          => {
                DIST_DEFAULT => 'all tardist',
                COMPRESS     => 'gzip -vf',
                SUFFIX       => '.gz',
              },
              clean          => {
                FILES        => '*~',
              },
              realclean         => {
                FILES        => '*~',
              },
              );

package MY;

sub postamble {
  return qq^
    
pm_to_blib: README

README: \$(VERSION_FROM)
	pod2text \$(VERSION_FROM) > README
^;
}

1;
