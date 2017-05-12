#!perl -T
#########################

use Test::More tests => 19;
use JavaScript::Minifier qw(minify);

### This is mainly to align the tests to 's' scripts, because s1 is
### somehow missing
can_ok('JavaScript::Minifier', 'minify');

#########################

sub filesMatch {
  my $file1 = shift;
  my $file2 = shift;
  my $a;
  my $b;

  while (1) {
    $a = getc($file1);
    $b = getc($file2);

    if (!defined($a) && !defined($b)) { # both files end at same place
      return 1;
    }
    elsif (!defined($b) || # file2 ends first
           !defined($a) || # file1 ends first
           $a ne $b) {     # a and b not the same
      return 0;
    }
  }
}

sub minTest {
  my $filename = shift;

  open(INFILE, 't/scripts/' . $filename . '.js') or die("couldn't open file");
  open(GOTFILE, '>t/scripts/' . $filename . '-got.js') or die("couldn't open file");
    minify(input => *INFILE, outfile => *GOTFILE);
  close(INFILE);
  close(GOTFILE);

  open(EXPECTEDFILE, 't/scripts/' . $filename . '-expected.js') or die("couldn't open file");
  open(GOTFILE, 't/scripts/' . $filename . '-got.js') or die("couldn't open file");
    ok(filesMatch(GOTFILE, EXPECTEDFILE), 'testing ' . $filename);
  close(EXPECTEDFILE);
  close(GOTFILE);
}

minTest('s2');    # missing semi-colons
minTest('s3');    # //@
minTest('s4');    # /*@*/
minTest('s5');    # //
minTest('s6');    # /**/
minTest('s7');    # blocks of comments
minTest('s8');    # + + - -
minTest('s9');    # alphanum
minTest('s10');  # }])
minTest('s11');  # string and regexp literals
minTest('s12');  # other characters
minTest('s13');  # comment at start
minTest('s14');  # slash following square bracket
                 # ... is division not RegExp
minTest('s15');  # newline-at-end-of-file
                 # -> not there so don't add
minTest('s16');  # newline-at-end-of-file
                 # -> it's there so leave it alone

is(minify(input => 'var x = 2;'), 'var x=2;', 'string literal input and ouput');
is(minify(input => "var x = 2;\n;;;alert('hi');\nvar x = 2;", stripDebug => 1), 'var x=2;var x=2;', 'scriptDebug option');
is(minify(input => 'var x = 2;', copyright => "BSD"), '/* BSD */var x=2;', 'copyright option');
