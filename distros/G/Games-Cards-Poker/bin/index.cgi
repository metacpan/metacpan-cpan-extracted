#!/usr/bin/perl
# index.cgi created by Pip Stuart <Pip@CPAN.Org> to provide a CGI
#   interface to generated Poker data.  Please e-mail me if you
#   need the scripts to generate the card images.
# This code is distributed under the GNU General Public License (version 2).

use CGI ":standard";
use LWP::UserAgent;
my $this = 'http://Your.URL.Org/cgi-bin/pokr/index.cgi';
my $imgp = 'http://Your.URL.Org/img/';
my $oddp = '/home/your_path/public_html/pokr/OddsTabl.htm';
my $meth = $ENV{'REQUEST_METHOD'};
my $quer = $ENV{'QUERY_STRING'};
my $nqur = $quer;
my $tqur;
my $uage = new LWP::UserAgent;
   $uage->agent("AgentName/0.1 " . $uage->agent);
my $oppo = param('oppo') || 9;
my $hol0 = param('hol0') || '';
my $hol1 = param('hol1') || '';
my $shrt = '';
my @rnkz = qw( A K Q J T 9 8 7 6 5 4 3 2 );
my @sutz = qw( s h d c );
my $runs = '';
my $wins = '';

# prep tests && params
$nqur = "oppo=$oppo" unless($nqur =~ /^oppo=/);
if($hol0) {
  if($hol1) {
    $shrt  =        substr($hol0, 0, 1) .  substr($hol1, 0, 1);
    my $ndx0 = 0; my $ndx1 = 0;
    for(my $indx = 0; $indx < @rnkz; $indx++) {
      $ndx0 = $indx if(substr($hol0, 0, 1) eq $rnkz[$indx]);
      $ndx1 = $indx if(substr($hol1, 0, 1) eq $rnkz[$indx]);
    }
    $shrt = reverse($shrt) if($ndx0 > $ndx1);
    $shrt .= 's' if(substr($hol0, 1, 1) eq substr($hol1, 1, 1));
    open(ODDP, "<$oddp");
    while(<ODDP>) {
      if(s/^<tr><th bgcolor="#032B17">$shrt<\/th>//) {
        my $topp = $oppo;
        s/^<td bgcolor="#3B3B17">(\d+)<\/td><td>(\d+\.\d+)%<\/td>// while($topp-- > 1);
#<tr><th bgcolor="#032B17">AA</th><td bgcolor="#3B3B17">713</td><td>85.83%</td><td bgcolor="#3B3B17">2559</td><td>77.06%</td><td bgcolor="#3B3B17">5757</td><td>69.55%</td><td bgcolor="#3B3B17">8571</td><td>63.21%</td><td bgcolor="#3B3B17">8819</td><td>58.28%</td><td bgcolor="#3B3B17">6342</td><td>53.74%</td><td bgcolor="#3B3B17">3444</td><td>47.50%</td><td bgcolor="#3B3B17">1883</td><td>38.50%</td><td bgcolor="#3B3B17">1525</td><td>31.34%</td></tr>
        if(/^<td bgcolor="#3B3B17">(\d+)<\/td><td>(\d+\.\d+)%<\/td>/) {
          $runs = $1;
          $wins = $2;
        }
      }
    }
    close(ODDP);
    $nqur = "oppo=$oppo"; # RESET
  } else {
    $nqur .= '&hol1=';
  }
} else {
  $nqur .= '&hol0=';
}

print "Content-type: text/html\n\n";

$tqur = $quer; $tqur =~ s/((oppo=)\d+)?/oppo=1/;
print qq|
<html><head><title>Pick Your HoldEm Hole Odds</title></head>
<body bgcolor="#03071B" text="#A8F8F0">
<table width="100%">
  <tr>
    <td colspan="2">
      <table cellpadding="0" cellspacing="0" width="100%">
        <tr>
          <td><a href="$this?$tqur"><img width="100%" height="100%" src="${imgp}o1.png"/></a></td>
          <td/>
          <td/>
          <td/>
          <td/>
|;
for(my $indx = 9; $indx >= 2; $indx--) {
  $tqur = $quer; $tqur =~ s/((oppo=)\d+)?/oppo=$indx/;
  print qq|          <td><a href="$this?$tqur"><img width="100%" height="100%" src="${imgp}o$indx.png"/></a></td>\n|;
}
print qq|        </tr>\n|;
foreach my $suit (@sutz) {
  print qq|        <tr>\n|;
  foreach my $rank (@rnkz) {
    print qq|          <td>|;
    if((!$hol0 || $hol0 ne "$rank$suit") && 
       (!$hol1 || $hol1 ne "$rank$suit")) {
      if($hol0 && $hol1) {
        print qq|<a href="$this?$nqur"><img width="100%" height="100%" src="$imgp$rank$suit.png"/></a>|;
      } else {
        print qq|<a href="$this?$nqur$rank$suit"><img width="100%" height="100%" src="$imgp$rank$suit.png"/></a>|;
      }
    }
    print qq|</td>\n|;
  }
  print qq|        </tr>\n|;
}
print qq|
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table cellpadding="0" cellspacing="0" width="100%">
        <tr>
          <td>Hole</td>
          <td colspan="2">
            <table cellpadding="0" cellspacing="0" width="100%">
              <tr>\n|;
if($hol0) {
  $tqur = "oppo=$oppo";
  print qq|                <td><a href="$this?$tqur"><img width="100%" height="100%" src="${imgp}$hol0.png"/></a></td>\n|;
} else {
  print qq|                <td/>\n|;
#  print qq|                <td><img width="100%" height="100%" src="${imgp}back.png"/></td>\n|;
}
if($hol1) {
  $tqur = $quer; $tqur =~ s/&hol1=..$//;
  print qq|                <td><a href="$this?$tqur"><img width="100%" height="100%" src="${imgp}$hol1.png"/></a></td>\n|;
} else {
  print qq|                <td/>\n|;
#  print qq|                <td><img width="100%" height="100%" src="${imgp}back.png"/></td>\n|;
}
print qq|
              </tr>
            </table>
          </td>
        </tr>
<!--
        <tr>
          <td>Flop</td>
          <td><img width="100%" height="100%" src="${imgp}4h.png"/></td>
          <td><img width="100%" height="100%" src="${imgp}Ah.png"/></td>
          <td><img width="100%" height="100%" src="${imgp}Td.png"/></td>
        </tr>
        <tr>
          <td>Turn<br/>River</td>
          <td colspan="2">
            <table cellpadding="0" cellspacing="0" width="100%">
              <tr>
                <td><img width="100%" height="100%" src="${imgp}9c.png"/></td>
                <td><img width="100%" height="100%" src="${imgp}7c.png"/></td>
              </tr>
            </table>
          </td>
        </tr>
  -->
      </table>
    </td>
    <td colspan="2" align="center">
      <table>
        <tr>
          <td>Opponents:</td>
          <td><b><font size="+2">$oppo</font></b></td>
          <td>&nbsp;&nbsp;&nbsp;&nbsp;Runs:</td>
          <td><b><font size="+2">$runs</font></b></td>
        </tr>
        <tr>
          <td>Hole:</td>
          <td><b><font size="+2">$shrt</font></b></td>
          <td><b>&nbsp;&nbsp;&nbsp;&nbsp;Wins:</b></td>
          <td align="right"><b><font size="+3" color="#F8F8B0">$wins%</font></b></td>
        </tr>
<!--
        <tr>
          <td>Flop:</td>
          <td><b><font size="+2">AT4</font></b></td>
          <td><b>&nbsp;&nbsp;&nbsp;&nbsp;Ties:</b></td>
          <td align="right"><b><font size="+3" color="#F8F8B0">1.27%</font></b></td>
        </tr>
  -->
      </table>
    </td>
  </tr>
</table>\n|;
open(ODDP, "<$oddp");
while(<ODDP>) {
  print $_ if(/Total Runs:/);
}
close(ODDP);
print qq|
</body></html>|;
