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
        # [CSS::Compressor]
        [
          'CSS::Compressor' => {}
        ],
      )
    }
  }
);

$tzil->build;

my @css_files = sort grep /\.css$/, map { $_->name } @{ $tzil->files };

my @expected = qw( 
  public/css/all.css
  public/css/all.min.css
  public/css/comment.css
  public/css/comment.min.css
  public/css/screen.css
  public/css/screen.min.css
);

is_filelist \@css_files, \@expected, 'minified all CSS files';
is_smaller(qw( public/css/all.css     public/css/all.min.css ));
is_smaller(qw( public/css/comment.css public/css/comment.min.css ));
is_smaller(qw( public/css/screen.css  public/css/screen.min.css ));

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
