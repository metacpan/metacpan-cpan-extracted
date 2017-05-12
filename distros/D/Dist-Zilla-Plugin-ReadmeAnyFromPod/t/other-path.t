#!perl
use Test::Most;

use strict;
use warnings;

use autodie;
use Test::DZil;

use Dist::Zilla::Plugin::ReadmeAnyFromPod;

my @config = ('GatherDir',
	      [ 'ReadmeAnyFromPod',
		{
		 source_filename => "bin/sample",
		},
	      ]
	     );

my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
        add_files => {
            'source/dist.ini' => simple_ini(@config),
        },
    }
);

my $built = lives_ok { $tzil->build; } "Built dist successfully";

if ($built) {
  my $content = $tzil->slurp_file("build/README");
  print "$content\n";
  like($content, qr/\bscript\b/, "README contents are derived from 'bin/sample' instead of default.");
}
else {
  skip "Building dist failed", 1;
}

done_testing(2);
