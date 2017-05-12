#!/usr/bin/perl -w

use strict;

if( !eval( "require Time::HiRes;" ) ) {
  print "Time::HiRes not installed; benchmarks cannot be done\n";
}

opendir( DIR, "./bench" );
my @files = readdir(DIR);
closedir( DIR );
foreach my $file ( @files ) {
  if( $file =~ m/(.+)\.tmpl/ ) {
    print "Processing $file\n";
    tmplfile( './bench/'.$file, $1 );
    print "\n";
  }
}

sub tmplfile {
  my $file = shift;
  my $name = shift;
open(TMPL,"$file");
$/ = undef;
my $tmpl = <TMPL>;
close(TMPL);

$tmpl =~ s/#([c+0-])/#-$1/g;

#print $tmpl;
my @parts = split('#-',$tmpl);

open(OUT,">./bench/one$name.pl");

my $div;
sub has_cc {
  my $div = (substr($ENV{'PATH'},0,1) eq '/') ? ':' : ';';
  my @path = split($div,$ENV{'PATH'});
  foreach my $dir ( @path ) {
    return 1 if( -e "$dir/cc" ||
                 -e "$dir/gcc" ||
                 -e "$dir/cc.exe" ||
                 -e "$dir/gcc.exe" ); }
  return 0;
}
if( $^O eq 'MSWin32' && !has_cc() ) { $div = '\\'; }
else { $div = '/'; }

print OUT <<START;
#!/usr/bin/perl
use strict;

my \$div = "\\$div";
my \$maxlen = 26;
my \$file = \$ARGV[1] || 'test.xml';
my ( \$root, \$s, \$s2, \$s3, \$usec, \$usec2, \$usec3, \$sa, \$sb, \$sc, \$base1, \$base2, \$base3 );

my \$onlyone = \$ARGV[2] ? 1 : 0;

tabit("-Module-",'load    ','parse   ','total') if( !\$onlyone );

exit if( !\$ARGV[0] );

use Time::HiRes qw(gettimeofday);

# For fairness; try to get the file to be read into memory cache
{
  open(FILE,'<', \$file) or die "Couldn't open \$!";
  local \$/ = undef; my \$cache = <FILE>;
  close(FILE);
}
START

#{
#  (\$s, \$usec) = gettimeofday();
#  if( eval( "require XML::Bare;" ) ) {
#    (\$s2, \$usec2) = gettimeofday();
#    my \$ob = new XML::Bare( file => \$file );
#    \$root = \$ob->parse();
#    (\$s3, \$usec3) = gettimeofday();
#    timeit('XML::Bare',1);
#  }
#}
#START
my $comment = '';
my $i = -1;
foreach my $part ( @parts ) {
  my @requires;
  $part = '#'.$part;
  my $type = '';
  my $module = '';
  if( $part =~ m/#([c\-0\+]) (.+)\n/ ) {
    $type = $1;
    my $name = $2;
    $module = $name if( $name =~ m/\w/ );
  }
  if( $part =~ m/#([c\-0\+]\+?)\n/ ) {
    $type = $1;
  }
  #print "[$type $module]\n";
  
  if( $type eq 'c' ) {
    $part =~ s/c\n//g;
    $part = "##".$part."##";
    $part =~ s/^##[#c \n]+//;
    $part =~ s/[ \n]+##$//;
    $comment = $part;
    next;
  }
  if( $type eq '0' ) {
    
    if( $module ) {
      $part =~ s/(#0)\W*.*/$1/;
    }
    
    while( $part =~ m/(require [A-Za-z\:]+;)/g ) {
      my $req = $1;
      if( !$module ) {
        my $fmod = $req;
        $fmod =~ s/require //; $fmod =~ s/;//;
        $module = $fmod;
      }
      push( @requires, $req );
    }
    $part =~ s/require [A-Za-z\:]+;\n//g;
    
    $part = "##".$part."##";
    $part =~ s/^##[#0 \n]+//;
    $part =~ s/[ \n]+##$//;
    
    print OUT "
    if( \$ARGV[0]*1 >= $i ) {
      (\$s, \$usec) = gettimeofday();
      if( eval( '@requires' ) ) {
        (\$s2, \$usec2) = gettimeofday();
        
$part

        (\$s3, \$usec3) = gettimeofday();
        unload('$module');
        timeit('$module',1);
      }
    }
    ";
  }
  if( $type eq '-' ) {
    
    if( $module ) {
      $part =~ s/(#[\-\0\+])\W*.*/$1/;
    }
    
    while( $part =~ m/(require [A-Za-z\:]+;)/g ) {
      my $req = $1;
      if( !$module ) {
        my $fmod = $req;
        $fmod =~ s/require //; $fmod =~ s/;//;
        $module = $fmod;
      }
      push( @requires, $req );
    }
    $part =~ s/require [A-Za-z\:]+;\n//g;
    
    $part = "##".$part."##";
    $part =~ s/^##[#\- \n]+//;
    $part =~ s/[ \n]+##$//;
    
    print OUT "
    if( \$ARGV[0] eq '$i' ) {
      (\$s, \$usec) = gettimeofday();
      if( eval( '@requires' ) ) {
        (\$s2, \$usec2) = gettimeofday();
        
$part

        (\$s3, \$usec3) = gettimeofday();
        unload('$module');
        timeit('$module');
      }
    }
    ";
  }
  if( $type eq '+' ) {
    $part = "##".$part."##";
    $part =~ s/^##[#\+ \n]+//;
    $part =~ s/[ \n]+##$//;
    print OUT "
    if( \$ARGV[0] eq '$i' ) {
    
$part
    
    }
    ";
  }
  if( $type eq '0+' ) {
    $part = "##".$part."##";
    $part =~ s/^##[0#\+ \n]+//;
    $part =~ s/[ \n]+##$//;
    print OUT "
    #if( \$ARGV[0] eq '$i' ) {
    
$part
    
    #}
    ";
  }
  $i++;
}

print OUT <<END;

sub unload {
  my \$module = shift;
  my \@parts = split(' ',\$module);
  \$module = \$parts[0];
  \$module =~ s/::/\\//g;
  \$module.='.pm';
  delete \$INC{\$module};
}

sub timeit {
  my \$name = shift;
  my \$base = shift;
  \$sa = \$s2-\$s + ((\$usec2-\$usec)/1000000); 
  \$sb = \$s3-\$s2 + ((\$usec3-\$usec2)/1000000); 
  \$sc = \$s3-\$s + ((\$usec3-\$usec)/1000000); 
  if( \$base ) {
    \$base1 = \$sa;
    \$base2 = \$sb;
    \$base3 = \$sc;
  }
  \$sa /= \$base1; \$sb /= \$base2; \$sc /= \$base3;
  \$sa = fixed( \$sa ); \$sb = fixed( \$sb ); \$sc = fixed( \$sc );
  if( !\$base || !\$onlyone ) {
    tabit( \$name,\$sa,\$sb,\$sc);
  }
}

sub tabit {
  my ( \$a, \$b, \$c, \$d ) = \@_;
  my \$len = length( \$a );
  print \$a;
  for( 0..(\$maxlen-\$len) ) { print ' '; }
  print "\$b \$c \$d\n";
}

sub fixed {
  my \$in = shift;
  \$in *= 10000;
  \$in = int( \$in );
  \$in /= 10000;
  my \$a = "\$in";
  my \$len = length( \$a );
  if( \$len > 8 ) { \$a = substr( \$a, 8 ); }
  if( \$len < 8 ) {
    while( \$len < 8 ) {
      \$a = "\${a} ";
      \$len = length( \$a );
    }
  }
  return \$a;
}
END

close(OUT);

open( SH, ">./bench/$name.pl" );

my $end = $i+1;
print SH "#!/usr/bin/perl
";
if( $comment ) {
  print SH "
print <<END;
$comment

END
  ";
}
print SH
"print `perl one$name.pl $end`;
my \$file = \$ARGV[0] || 'test.xml';
for my \$i ( 0..$i ) {
  print `perl one$name.pl \$i \$file 1`
}
";

#print SH "#!/bin/bash
#perl bench.pl $end
#for (( i=1;i<=$i;i++ )); do
#perl bench.pl \$i \$1 1
#done
#";

close( SH );
}
