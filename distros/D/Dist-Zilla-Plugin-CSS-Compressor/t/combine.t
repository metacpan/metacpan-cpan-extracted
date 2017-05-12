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
        # [CSS::Compressor]
        [
          'CSS::Compressor' => {
            output => 'public/css/awesome.min.css',
          }
        ],
      )
    }
  }
);

$tzil->build;

my @css_files = sort grep /\.css$/, map { $_->name } @{ $tzil->files };

my @expected = qw( 
  public/css/all.css
  public/css/awesome.min.css
  public/css/comment.css
  public/css/screen.css
);

is_filelist \@css_files, \@expected, 'minified to public/css/awesome.min.css';

my $orig = join('', map { $tzil->slurp_file("source/public/css/$_.css") } qw( all comment screen ) );
my $min  = $tzil->slurp_file("build/public/css/awesome.min.css");

cmp_ok length($orig), '>', length($min), "original [" . length($orig) . "] is larger than min [" . length($min) ."]";
