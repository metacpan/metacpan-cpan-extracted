# -*- cperl -*-

use Test::More tests => 1 + 4;

use File::Temp qw/:POSIX/;
#use Perl6::Slurp;
use Path::Tiny 'path';
BEGIN { use_ok( 'Lingua::PT::PLNbase' ); }
use utf8;

  my $outfile = tmpnam();
  fsentences({output=> $outfile},"t/ftext1");
  is(path($outfile)->slurp_utf8 ,path('t/ftext1.out1')->slurp_utf8 );
  unlink $outfile;

  $outfile = tmpnam();
  fsentences({s_tag => 'sentence',
	      t_tag => 'file',
	      p_tag => 'paragraph',
	      output=> $outfile,
             },"t/ftext1");
  is(path($outfile)->slurp_utf8 , path('t/ftext1.out2')->slurp_utf8 );
  unlink $outfile;

  $outfile = tmpnam();
  fsentences({o_format => 'NATools',
	      output   => $outfile},
             "t/ftext1");
  is(path($outfile)->slurp_utf8 , path('t/ftext1.out3')->slurp_utf8 );
  unlink $outfile;

  $outfile = tmpnam();
  fsentences({o_format => 'NATools',
	      tokenize => 1,
	      output=>$outfile},"t/ftext1");
  is(path($outfile)->slurp_utf8 , path('t/ftext1.out4')->slurp_utf8 );
  unlink $outfile;

