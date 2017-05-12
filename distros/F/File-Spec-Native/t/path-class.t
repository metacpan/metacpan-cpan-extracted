use strict;
use warnings;
use Test::More;

eval q{ use Path::Class qw(file foreign_file); 1 }
  or plan skip_all => 'Path::Class required for these tests';

plan tests => 4;

{
  my $f = file(qw(foo bar));
  my $fs = $f->stringify;

  my $n = $f->as_foreign('Native');
  my $ns = $n->stringify;

  is($fs, $ns, 'Native == file()');
}

{
  my @path = qw( y a p c ); # can you tell i wish i was there?
  my $current = $File::Spec::ISA[0];

  my ($format, $exp) = ( $current eq 'Win32'
    ? (qw(Unix  y/a/p/c))
    : (qw(Win32 y\a\p\c))
  );
  my $fsclass = "File::Spec::$format";

  my $f = foreign_file($format => @path);
  is($f->stringify, $exp, "$format file path");
  is($f->stringify, $fsclass->catfile(@path), "same as $fsclass");
  is($f->as_foreign("Native")->stringify, File::Spec->catfile(@path), 'as_foreign("Native") same as File::Spec');
}
