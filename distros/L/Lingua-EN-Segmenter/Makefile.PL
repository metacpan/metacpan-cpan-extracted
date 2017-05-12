# A template for Makefile.PL.
# - Set the $PACKAGE variable to the name of your module.
# - Fill in your dependencies under ExtUtils::AutoInstall

use lib './t/lib';
use ExtUtils::AutoInstall(
    -core => [
        'File::Slurp'=>0,
        'Math::VecStat'=>0.08, 
        'Class::Exporter'=>0,
        'Math::HashSum'=>0,
        'Math::Vector::SortIndexes'=>0,
        'Lingua::GL::Stemmer'=>0,
        'Lingua::Stem::Snowball::Da'=>0,
        'Lingua::PT::Stemmer'=>0,
        'Lingua::Stem::It'=>0,
        'Text::German'=>0,
        'Lingua::Stem::Snowball::No'=>0,
        'Lingua::Stem::Snowball::Se'=>0,
        'Lingua::Stem'=>0.60, 
        'Test::Harness'=>2.03,
        'Test::Simple'=>0.45
    ]
);

$PACKAGE = 'Lingua::EN::Segmenter';
($PACKAGE_FILE = $PACKAGE) =~ s|::|/|g;

WriteMakefile(
    NAME            => $PACKAGE,
    VERSION_FROM    => "lib/$PACKAGE_FILE.pm", # finds $VERSION
    'dist'          => { COMPRESS   => 'gzip -9',
                         SUFFIX     => '.gz',
                         DIST_DEFAULT   => 'all tardist',
                       },
);


