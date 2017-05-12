use strict;
use warnings;
use Test::More 0.88;
use Test::DZil;

plan tests => 2;

my $tzil = Builder->from_config(
  { dist_root => 'corpus/DZT' },
  {
    add_files => {
      'source/dist.ini' => simple_ini(
        {},
        # [GatherDir]
        'GatherDir',
        # [JavaScript::Minifier]
        [
          'JavaScript::Minifier' => {
            output => 'public/js/awesome.min.js',
          }
        ],
      )
    }
  }
);

$tzil->build;

my @js_files = sort grep /\.js$/, map { $_->name } @{ $tzil->files };

my @expected = qw( 
  public/js/all.js
  public/js/awesome.min.js
  public/js/comment.js
  public/js/screen.js
);

is_filelist \@js_files, \@expected, 'minified to public/js/awesome.min.js';

my $orig = join('', map { $tzil->slurp_file("source/public/js/$_.js") } qw( all comment screen ) );
my $min  = $tzil->slurp_file("build/public/js/awesome.min.js");

cmp_ok length($orig), '>', length($min), "original [" . length($orig) . "] is larger than min [" . length($min) ."]";
