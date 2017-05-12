use ExtUtils::MakeMaker;

#--- Original or revised phrtsd?
$OPT = $ARGV[0];
if ($OPT =~ /phrtsd_orig/i) {
   warn "*"x40, "\nUsing original phrtsd\n", "*"x40, "\n";
   $def = '-DPHRTSD_ORIG';
   copy('test1.pl', 'test.pl');
} else {
   $def = '';
   copy('test2.pl', 'test.pl');
}

WriteMakefile(
    'NAME'		=> 'Math::Random',
    'VERSION_FROM'	=> 'Random.pm',
    'OBJECT'		=> '$(O_FILES)',
    'LIBS'		=> ['-lm'],
    'DEFINE'		=> $def,
    'INC'		=> '',     # e.g., '-I/opt/pkg/perl5.002/dist' 
    'dist'		=> { COMPRESS=>"gzip -9", SUFFIX=>"gz" },
);

sub copy {
 my ($in, $out) = @_;
 open(I, $in) or die "Could not open $in: $!";
 open(O, ">$out") or die "Could not open $out: $!";
 while (<I>) { print O; }
 close I;
 close O;
}
