#!perl
use Test::Most;

use strict;
use warnings;

use autodie;
use Test::DZil;
use Path::Tiny 0.004;

use Dist::Zilla::Plugin::ReadmeAnyFromPod;

my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
        add_files => {
            'source/dist.ini' => simple_ini(
                'GatherDir',
                # Only create README.mkdn in root, not in build
                [ 'ReadmeAnyFromPod', 'ReadmeMarkdownInRoot' ],
                # Create text README in both
                [ 'ReadmeAnyFromPod', 'ReadmeTextInRoot' ],
                [ 'ReadmeAnyFromPod', 'ReadmeTextInBuild' ],
            ),
        },
    }
);

# Artificially create README.mkdn and README in root. (Ordinarily this
# file would be created by a previous build.)
path($tzil->tempdir)->child('source/README.mkdn')->spew(<<EOF);
# Placeholder README content

This is the content of the README.mkdn file.
EOF

path($tzil->tempdir)->child('source/README')->spew(<<EOF);
Placeholder README content

This is the content of the README file.
EOF

lives_ok { $tzil->build; } "Built dist successfully";

sub file_has_content {
  my $path = shift;;
  my $content = $tzil->slurp_file($path);
  return $content =~ m/\S/;
}

sub file_nonexistent {
  my $path = shift;
  ! -e path($tzil->tempdir)->child($path);
}

ok(file_has_content("source/README.mkdn"),
   "Dist root contains non-empty README.mkdn");
ok(file_has_content("source/README"),
   "Dist root contains non-empty README");
ok(file_nonexistent("build/README.mkdn"),
   "README.mkdn didn't sneak into build");
ok(file_has_content("build/README"),
   "Dist build contains non-empty README");

done_testing();
