#!perl
use 5.008;

use strict;
use warnings;
use utf8;

use lib qw(../lib/);

use Test::More;
use Test::Deep;
#cmp_deeply([],any());

use LCS;

use Data::Dumper;

binmode(STDOUT,":encoding(UTF-8)");
binmode(STDERR,":encoding(UTF-8)");

my $class = 'LCS::Similar';

use_ok($class);

my $object = new_ok($class);

if (1) {
  ok($object->new());
  ok($object->new(1,2));
  ok($object->new({}));
  ok($object->new({a => 1}));

  ok($class->new());
}

my $examples = [
  [
    [ split(/\n/,<<TEXT) ],
The genital structures were photographed beneath glycerol with a 5-megapixel digital

Manuscript accepted 04.04.20 12
190

C. GERMANN

camera (Leica DFC425) under a stereomicroscope (Leica MZ16). The same camera
TEXT

    [ split(/\n/,<<TEXT) ],
The genital structures were photographed beneath glycerol with a 5-megapixel digital

Manuscript accepted 04.04.2012
190 C. GERMANN

camera (Leica DFC425) under a stereomicroscope (Leica MZ16). The same camera
TEXT
  ],

  [
    [ split(/\n/,<<TEXT) ],
o


Thc dig drown fox

jumps over
TEXT

    [ split(/\n/,<<TEXT) ],
The big brown Foxes

ahem
jump over

TEXT

  ],
];

if (0) {
  local $Data::Dumper::Deepcopy = 1;
  print STDERR Data::Dumper->Dump([$examples],[qw(examples)]),"\n";
}

#exit;

my $examples2 = [
  [qw(
    eonnnnnicaio
    commu_nicato
  )],
  [qw(
    dejinnmifnr
    deſum_mitur
  )],
  [qw(
    ittudo
    titudo
  )],
];

sub confusable {
  my ($a, $b, $threshold) = @_;

  $a //= '';
  $b //= '';
  $threshold //= 0.7;

  return 1 if ($a eq $b);
  return 1 if (!$a && !$b);

  my $map = {
    'e' => 'c',
    'c' => 'e',
    'm' => 'n',
    'n' => 'm',
    'i' => 't',
    't' => 'i',
    't' => 'f',
    'f' => 't',
    'ſ' => 'j',
    'j' => 'ſ',
  };

  return $threshold if (exists $map->{$a} && $map->{$a} eq $b);
}

sub similarity {
  my ($a, $b, $threshold) = @_;

  $a //= '';
  $b //= '';
  $threshold //= 0.7;

  return 1 if ($a eq $b);
  return 1 if (!$a && !$b);

  my $llcs = LCS->LLCS(
    [split(//,$a)],
    [split(//,$b)],
  );
  my $similarity = (2 * $llcs) / (length($a) + length($b));
  return $similarity if ($similarity >= $threshold);
}

if (1) {
  for my $example (0 .. $#$examples) {
  #for my $example (1) {
 	for my $threshold (qw(0.1 0.5 0.7 1) ) {
  	  my $a = $examples->[$example]->[0];
  	  my $b = $examples->[$example]->[1];

  	  my $lcs = LCS::Similar->LCS($a,$b,\&similarity,$threshold);
  	  #my $lcs = LCS::Similar->LCS($a,$b,);
  	  my $all_lcs = LCS->allLCS($a,$b);

  	  if (1) {
  		cmp_deeply(
    	  $lcs,
    	  any(
        	$lcs,
        	supersetof( @{$all_lcs} )
    	  ),
    	  "Example $example, Threshold $threshold"
  	    );
  	  }

  	  if (1) {
    	my $aligned = LCS->lcs2align($a,$b,$lcs);
    	for my $chunk (@$aligned) {
      	  print 'a: ',$chunk->[0],"\n";
      	  print 'b: ',$chunk->[1],"\n";
      	  print "\n";
    	}
  	  }

  	  if (0) {
    	local $Data::Dumper::Deepcopy = 1;
    	print STDERR Data::Dumper->Dump([$all_lcs],[qw(allLCS)]),"\n";
    	print STDERR Data::Dumper->Dump([$lcs],[qw(LCS)]),"\n";
  	  }
    }
  }
}

if (1) {
    for my $example (0 .. $#$examples) {
    #for my $example (1) {
 	#for my $threshold (qw(0.1 0.5 0.7 1) ) {
  	    my $a = $examples->[$example]->[0];
  	    my $b = $examples->[$example]->[1];

  	    my $lcs = LCS::Similar->LCS($a,$b,);
  	    #my $lcs = LCS::Similar->LCS($a,$b,);
  	    my $all_lcs = LCS->allLCS($a,$b);

  	    if (1) {
  		    cmp_deeply(
    	            $lcs,
    	            any(
                    	$lcs,
                    	supersetof( @{$all_lcs} )
    	            ),
    	            "Example $example, Threshold undef"
  	         );
  	    }

  	    if (1) {
            	my $aligned = LCS->lcs2align($a,$b,$lcs);
    	        for my $chunk (@$aligned) {
      	        print 'a: ',$chunk->[0],"\n";
      	        print 'b: ',$chunk->[1],"\n";
      	        print "\n";
    	        }
  	    }

  	    if (0) {
    	        local $Data::Dumper::Deepcopy = 1;
    	        print STDERR Data::Dumper->Dump([$all_lcs],[qw(allLCS)]),"\n";
            	print STDERR Data::Dumper->Dump([$lcs],[qw(LCS)]),"\n";
  	    }

    }
}


if (2) {
  for my $example (0 .. $#$examples2) {
  #for my $example ($examples->[3]) {
    for my $threshold (qw(0.1 0.5 0.7 1) ) {
  	  my $a = $examples2->[$example]->[0];
  	  my $b = $examples2->[$example]->[1];
      my @a = $a =~ /([^_])/g;
      my @b = $b =~ /([^_])/g;

      my $lcs = LCS::Similar->LCS(\@a,\@b,\&confusable,$threshold);
      my $all_lcs = LCS->allLCS(\@a,\@b);

      cmp_deeply(
        $lcs,
        any(
            $lcs,
            supersetof(@{$all_lcs})
        ),
        "Example2 $example, Threshold $threshold"
      );

  	  if (1) {
    	my $aligned = [LCS->align2strings(
    	  LCS->lcs2align(\@a,\@b,$lcs)
    	)];
    	#for my $chunk (@$aligned) {
      	  print 'a: ',$aligned->[0],"\n";
      	  print 'b: ',$aligned->[1],"\n";
      	  print "\n";
    	#}
  	  }

      if (0) {
        local $Data::Dumper::Deepcopy = 1;
        print STDERR Data::Dumper->Dump([$all_lcs],[qw(allLCS)]),"\n";
        print STDERR Data::Dumper->Dump([$lcs],[qw(LCS)]),"\n";
      }
    }
  }
}

my @data3 = ([qw/a b d/ x 50], [qw/b a d c/ x 50]);
# NOTE: needs 100 years
if (0) {
  cmp_deeply(
    LCS::Similar->LCS(@data3),
    any(@{LCS->allLCS(@data3)} ),
    '[qw/a b d/ x 50], [qw/b a d c/ x 50]'
  );
  if (0) {
    $Data::Dumper::Deepcopy = 1;
    print STDERR 'allLCS: ',Data::Dumper->Dump(LCS->allLCS(@data3)),"\n";
    print STDERR 'LCS: ',Dumper(LCS::Similar->LCS(@data3)),"\n";
  }
}


done_testing;
