use strict;
use warnings;
use Test::More 0.88;
use Test::DZil;

plan tests => 4;

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
          'JavaScript::Minifier' => {}
        ],
      )
    }
  }
);

$tzil->build;

my @js_files = sort grep /\.js$/, map { $_->name } @{ $tzil->files };

my @expected = qw( 
  public/js/all.js
  public/js/all.min.js
  public/js/comment.js
  public/js/comment.min.js
  public/js/screen.js
  public/js/screen.min.js
);

is_filelist \@js_files, \@expected, 'minified all JavaScript files';
is_smaller(qw( public/js/all.js     public/js/all.min.js ));
is_smaller(qw( public/js/comment.js public/js/comment.min.js ));
is_smaller(qw( public/js/screen.js  public/js/screen.min.js ));

sub is_smaller
{
  my($orig_fn, $min_fn) = @_;
  #diag "read $orig_fn";
  my $orig = $tzil->slurp_file("source/$orig_fn");
  #diag "read $min_fn";
  my $min  = $tzil->slurp_file("build/$min_fn");
  
  cmp_ok length($orig), '>', length($min), 
    "$orig_fn [" . length($orig) . "] is larger than $min_fn [" . length($min) . "]";
}
