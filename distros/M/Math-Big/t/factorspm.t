# -*- mode: perl; -*-

use strict;
use Test;

BEGIN
  {
  $| = 1;
  # chdir 't' if -d 't';
  unshift @INC, '../lib'; # for running manually
  plan tests => 28;
  }

use Math::BigInt;
use Math::Big::Factors;

my (@args,$ref,$func,$argnum,$try,$x,$y,$z,$ans,@ans,$ans1);
$| = 1;
while (my $line = <DATA>)
  {
  next if $line =~ /^#/;
  chop $line;
  if ($line =~ s/^&//)
    {
    # format: '&subroutine:number_of_arguments
    ($func,$argnum) = split /:/,$line;
    $ref = 0; $ref = 1 if $func =~ s/_ref$//;
    }
  else
    {
    @args = split(/:/,$line,99);

    #print "try @args\n";
    $try = '@ans = (); ';
    if ((@args == 2) || ($ref != 0))
      {
      $try .= '$ans[0]';
      }
    else
      {
      $try .= '@ans';
      }
    $try .= " = Math::Big::Factors::$func (";
    for (my $i = 0; $i < $argnum; $i++)
      {
      $try .= "'$args[$i]',";
      }
    $try .= ");";
    eval $try;
    splice @args,0,$argnum;
    $ans1 = ""; foreach (@args) { $ans1 .= " $_" }
    $ans = "";
    foreach my $c (@ans)
      {
      # functions that return an array ref
      if (ref($c) eq 'ARRAY')
        {
        foreach my $h (@$c)
          {
          $ans .= " $h";
          }
        }
      else
        {
        $ans .= " $c";
        }
      }
    print "# Tried: '$try'\n" if !ok ($ans,$ans1);
    }
  } # endwhile data tests
close DATA;

# all done

__END__
&factors_wheel:2
1:1:1
2:1:2
3:1:3
0:1:0
9:1:3:3
18:1:2:3:3
1:2:1
2:2:2
3:2:3
0:2:0
9:2:3:3
18:2:2:3:3
1:3:1
2:3:2
3:3:3
0:3:0
9:3:3:3
18:3:2:3:3
1:4:1
2:4:2
3:4:3
0:4:0
9:4:3:3
18:4:2:3:3
&wheel_ref:1
1:2:1
2:2:3:1:5
3:2:3:5:1:7:11:13:17:19:23:29
4:2:3:5:7:1:11:13:17:19:23:29:31:37:41:43:47:53:59:61:67:71:73:79:83:89:97:101:103:107:109:113:121:127:131:137:139:143:149:151:157:163:167:169:173:179:181:187:191:193:197:199:209
