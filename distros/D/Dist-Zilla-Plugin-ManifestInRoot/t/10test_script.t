use t::boilerplate;

use Test::More;
use Test::DZil;
use ExtUtils::Manifest;
use Sys::Hostname;

BEGIN {
   $ENV{AUTHOR_TESTING} or plan skip_all => 'Tests only for developers';
}

SKIP: {
   my $tzil = Builder->from_config
      (  { dist_root => 'lib' },
         { add_files => {
            q{source/file with spaces.txt}        => "foo\n",
            # q{source/file\\with some\\whacks.txt} => "bar\n",
            # q{source/'file-with-ticks.txt'}       => "baz\n",
            # q{source/file'with'quotes\\or\\backslash.txt} => "quux\n",
            'source/dist.ini' => simple_ini(
                                            'GatherDir',
                                            'ManifestInRoot',
                                            ),
            },
            },
         );

   $tzil->build;

   my $manihash = ExtUtils::Manifest::maniread
      ( $tzil->root->file( 'MANIFEST' ) );

   is_deeply(
             [ sort keys %$manihash ],
             [ sort(
                    q{file with spaces.txt},
                    'MANIFEST',
                    'dist.ini',
                    'Dist/Zilla/Plugin/ManifestInRoot.pm',
                    ) ],
             'Manifest in root'
             );

}

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
