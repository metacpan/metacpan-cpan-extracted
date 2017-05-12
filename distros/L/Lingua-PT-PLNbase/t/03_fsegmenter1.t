# -*- cperl -*-

use Test::More tests => 1 + 4;
use POSIX qw(locale_h);
setlocale(LC_CTYPE, "pt_PT");
use locale;
use File::Temp qw/:POSIX/;
use File::Slurp qw.slurp.;
BEGIN { use_ok( 'Lingua::PT::PLNbase' ); }


$a = 'Çáé';

SKIP: {
  skip "not a good locale", 4 unless $a =~ m!^\w{3}$!;

  my $outfile = tmpnam();
  fsentences({output=> $outfile},"t/ftext1");
  is(slurp($outfile), slurp('t/ftext1.out1'));
  unlink $outfile;

  $outfile = tmpnam();
  fsentences({s_tag => 'sentence',
	      t_tag => 'file',
	      p_tag => 'paragraph',
	      output=> $outfile,
             },"t/ftext1");
  is(slurp($outfile), slurp('t/ftext1.out2'));
  unlink $outfile;

  $outfile = tmpnam();
  fsentences({o_format => 'NATools',
	      output   => $outfile},
             "t/ftext1");
  is(slurp($outfile), slurp('t/ftext1.out3'));
  unlink $outfile;

  $outfile = tmpnam();
  fsentences({o_format => 'NATools',
	      tokenize => 1,
	      output=>$outfile},"t/ftext1");
  is(slurp($outfile), slurp('t/ftext1.out4'));
  unlink $outfile;

}
