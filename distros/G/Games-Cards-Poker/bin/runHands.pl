#!/usr/bin/perl -w
# 4561PjW - runHands.pl created by Pip Stuart <Pip@CPAN.Org>
#   to create MySQL databases && tables for storing 
#   Games::Cards::Poker exhaustive odds data.
# After making sure database is setup, all possible hands are run through 
#   Games::Cards::Poker && wins, losses, && ties are stored.
# Params: `perl runHands.pl <InnerCountMax> <StartHoleIndex> <EndHoleIndex>`
# 2do:
#   reset db
#   fix data structs to handle contradictory results for straight flush vs.
#     straight for same hole vs. ehol matchups (separate win/loss/tie again?)
#   test if whole hole can fit in mem (as hash then try array if hash fails)
#   write && read completed hole && flop to progress.run
#   mk only two params of how many holes && flops to run
#   mk write straight to XML option
#
#   more thorough to use b64hand strings for everything (in way more space)
#
#   bleh... needs to be ported to C && dump straight to win/loss/tie xml
#
# Notz:
#   Useful stuff to calc:
#     # of ways to get each possible hole (combos) (see @holz)
#     For each possible hole:
#       Hands You Win         && %
#       Hands You Lose        && %
#       Hands You Tie         && %
#       Hands You Don't Lose  && % (Win + Tie)
#
# This code is distributed under the GNU General Public License (version 2).

use strict;
use warnings;
use DBI;
use Time::PT;
use Games::Cards::Poker qw(:all);
use Algorithm::ChooseSubsets;
use Data::Dumper;

my $rset = 0; # SET TO 1 TO RESET (DROP) ALL HOLE DATABASES (BE CAREFUL!)
my $nodb = 1; # flag for not using database during every run
my $nofl = 1; # flag for not storing flops in memory data
my $icmx = shift() || 9999999999; # limit of how many total inner loops can run
# 2,140,380 will do each turn, rivr, ehol for one flop (prolly ~11hours on Gen)
#   took 17446 seconds && ~13MB to do 1 flop on Kage so ~150days per hole
#   took 39155 seconds          to do 1 flop on Gen  so ~336days per hole
my $coun = shift() || 0;     # count of first ShortHand hole index to run
my $limt = shift() || $coun; # limit of last  ShortHand hole index to run
my $dbhn; my $stmt; my @rowa; my %dbez; my $daba; my $rows;     my $icou = 0;
my $ecou; my @deck; my $ptb4; my $ptaf; my $tdif; my $glim = 0; my $gcou = 0; 
my $cfgf = 'progress.run'; my $rtry = 127; my @data; my %data;
if(-e  $cfgf) { open(CFGF, "<$cfgf"); $glim = <CFGF>; close(CFGF); } #load prog
elsif(!$nodb) { $rset = 1; } # RESET DATABASE IF THERE'S NO PROGRESS YET!!!
my @rprg = RPrg(); #         rank lookup
my %rprv = RPrV(); # reverse Rank Progression Value lookup
my @holz = Holz(); #         hole lookup
my %zloh = Zloh(); # reverse hole lookup
my @flpz = Flpz(); #         flop lookup
my %zplf = Zplf(); # reverse flop lookup

if(!$nodb || $rset) {
  print "Testing for (&& creating any missing) databases...\n";
  #   CREATE ANY MISSING DATABASES:
  # connect to database known to exist ('mysql')
  $ecou = 0; $dbhn = undef;
  while($ecou++ < $rtry && !$dbhn) {
    $dbhn = DBI->connect('DBI:mysql:mysql', undef, undef);
    sleep(1) unless($dbhn);
  }
  # query engine for all other existent databases
  $stmt = $dbhn->prepare('show databases');
  $stmt->execute(); $rows = 0; # reset rows
  $rows = $stmt->rows(); # find the number of databases defined
  foreach(1..$rows) { # loop through defined
    @rowa = $stmt->fetchrow_array();        # loading each name
  #  printf("indx:%2d daba:$rowa[0]\n", $_); # print out index && name
    $dbez{$rowa[0]} = 1;                    # save name in hash for testing
  }
  $stmt->finish();
  foreach(0..$#holz) { # test if hole databases exist yet
    $daba = 'h' . $_; # build names as 'h0'..'h168'
    if( exists($dbez{$daba})) {
      $dbhn->do("drop   database $daba") if($rset); # RESET ALL DATABASES!!!
        delete($dbez{$daba})             if($rset); # RESET ALL DATABASES!!!
    }
    if(!exists($dbez{$daba})) {
      $dbhn->do("create database $daba"); # create databases that don't exist
    }
  }
  $dbhn->disconnect();
}
$ptb4 = Time::PT->new();
printf("PTb4:$ptb4 expand:%s\n", $ptb4->expand());
while($icou < $icmx && $coun <= $limt) { # limit not reached
  @deck = Deck();
  my $habv = $holz[$coun];
     $habv =~ /^(.)(.s?)$/;
  my @hole = ("$1s", $2); $hole[1] .= 'h' unless($hole[1] =~ /^.s$/);
#print "Deck b4:@deck\n";
  foreach(@hole) {
#print "removing card: $_...\n";
    RemoveCard($_, \@deck);
  }
#print "Deck af:@deck\n";
  my $chof = Algorithm::ChooseSubsets->new(\@deck, 3); my @pref; my $ndxf;
  while($icou < $icmx && ($ndxf = $chof->next())) { # choose flop subset
    @pref = @deck;
    my $shrf = ShortHand(@{$ndxf});
#print "ndxf:@{$ndxf} shrf:$shrf zplf:$zplf{$shrf}\n";
    foreach(@{$ndxf}) {
#print "removing card: $_...\n";
      RemoveCard($_, \@pref);
    }
    my $chot = Algorithm::ChooseSubsets->new(\@pref, 1); my @pret; my $ndxt;
    while($icou < $icmx && ($ndxt = $chot->next())) { # choose turn subset
      @pret = @pref;
      my $shrt = substr($ndxt->[0], 0, 1);
#print "  hole:$coun ($habv)
#ndxf:@{$ndxf} shrf:$shrf zplf:$zplf{$shrf}
#ndxt:@{$ndxt} shrt:$shrt rprv:$rprv{$shrt}\n";
      if(@{$ndxt}) {
        RemoveCard($ndxt->[0], \@pret);
      }
      my $chor = Algorithm::ChooseSubsets->new(\@pret, 1); my @prer; my $ndxr;
      my @bord;
      while($icou < $icmx && ($ndxr = $chor->next())) { # choose river subset
        @bord = (@{$ndxf}, @{$ndxt}, @{$ndxr});
        @prer = @pret;
        my $shrr = substr($ndxr->[0], 0, 1);
        if(@{$ndxr}) {
          RemoveCard($ndxr->[0], \@prer);
        }
        my $choe = Algorithm::ChooseSubsets->new(\@prer, 2); my $ndxe;
        while($icou < $icmx && ($ndxe = $choe->next())) { # choose enemy holes
          if(++$gcou > $glim) {
            my $shre = ShortHand(@{$ndxe}); my $bscm; my $bsce;
            if($coun <= $zloh{$shre}) { # don't revisit bottom half
              my $wlot = 0;
              $bscm = ScoreHand(BestHand(@hole,    @bord));
              $bsce = ScoreHand(BestHand(@{$ndxe}, @bord));
#print "
#ndxf:@{$ndxf} shrf:$shrf zplf:$zplf{$shrf}
#ndxt:@{$ndxt} shrt:$shrt rprv:$rprv{$shrt}
#ndxr:@{$ndxr} shrr:$shrr rprv:$rprv{$shrr}\n";
              if   ($bscm < $bsce) { $wlot = 1; } # wins
              elsif($bscm > $bsce) { $wlot = 3; } # loss
              else                 { $wlot = 2; } # ties
              UpdtData($wlot, $coun, $zplf{$shrf}, $rprv{$shrt},
                                     $rprv{$shrr}, $zloh{$shre});
              unless($nodb) {
                if(-e $cfgf) {
                  my $cfgb = $cfgf; $cfgb =~ s/\.run$/.bak/;
                  open(CFGF, "<$cfgf");
                  open(CFGB, ">$cfgb");
                  print CFGB <CFGF>;
                  close(CFGB);
                  close(CFGF);
                }
                open(CFGF, ">$cfgf");
                print CFGF $gcou;
                close(CFGF);
              }
              $icou++;
            }
          }
        }
      }
    }
    WritData($coun, $zplf{$shrf}) if($nodb && $nofl); # Write out all mem @data
    goto quit;
  }
  WritData($coun) if($nodb && !$nofl); # Write out all mem %data if !using db
  $coun++;
}
quit:
$ptaf = Time::PT->new();
printf("PTaf:$ptaf expand:%s\n", $ptaf->expand());
$tdif = ($ptaf - $ptb4); # Time::Frame
printf(" Dif:%s seconds:%s\n", $tdif->total_frames(), ($tdif->total_frames() / 60));

sub UpdtData { # Updates Data
  my $fiel = shift; my $ihol = shift; my $iflp = shift; my $daba = 'h' . $ihol;
  my $itrn = shift; my $irvr = shift; my $ieho = shift; my $taba = 'f' . $iflp;
  my $tflg = 0;
#print "ihol:$ihol ($holz[$ihol]) vs. ieho:$ieho ($holz[$ieho]) = $fiel\n";
  if($nodb) {
    if($nofl) { # don't store flop so start with turn in mem @data array
      if(@data &&
         defined($data[$itrn])               && @{$data[$itrn]} &&
         defined($data[$itrn][$irvr])        && @{$data[$itrn][$irvr]} && 
         defined($data[$itrn][$irvr][$ieho]) && @{$data[$itrn][$irvr][$ieho]}) { 
        if($fiel ne $data[$itrn][$irvr][$ieho][0]) {
          print "!*EROR*! New test yielded contradictory result for fiel:$fiel ihol:$ihol ieho:$ieho iflp:$iflp itrn:$itrn irvr:$irvr\n  hole:$holz[$ihol] ehol:$holz[$ieho] flop:$flpz[$iflp] turn:$rprg[$itrn] rivr:$rprg[$irvr]\n";
        }
      } else { 
        @{$data[$itrn][$irvr][$ieho]} = ($fiel, 0); 
      }
      $data[$itrn][$irvr][$ieho][1]++; 
    } else { # store flop in mem %data hash
      if(%data &&
         exists($data{$iflp})                      && %{$data{$iflp}}        &&
         exists($data{$iflp}{$itrn})               && %{$data{$iflp}{$itrn}} &&
         exists($data{$iflp}{$itrn}{$irvr})        && %{$data{$iflp}{$itrn}{$irvr}} && 
         exists($data{$iflp}{$itrn}{$irvr}{$ieho}) && %{$data{$iflp}{$itrn}{$irvr}{$ieho}}) { 
        if($fiel ne $data{$iflp}{$itrn}{$irvr}{$ieho}[0]) {
          print "!*EROR*! New test yielded contradictory result for fiel:$fiel ihol:$ihol ieho:$ieho iflp:$iflp itrn:$itrn irvr:$irvr\n  hole:$holz[$ihol] ehol:$holz[$ieho] flop:$flpz[$iflp] turn:$rprg[$itrn] rivr:$rprg[$irvr]\n";
        }
      } else { 
        @{$data{$iflp}{$itrn}{$irvr}{$ieho}} = ($fiel, 0); 
      }
      $data{$iflp}{$itrn}{$irvr}{$ieho}[1]++;
    }
  } else {
    $ecou = 0; $dbhn = undef;
    while($ecou++ < $rtry && !$dbhn) {
      $dbhn = DBI->connect("DBI:mysql:$daba", undef, undef);
      sleep(1) unless($dbhn);
    }
    my @tblz = $dbhn->tables();
    foreach(@tblz) {
      s/(^`|`$)//g;
      if($_ eq $taba) { $tflg = 1; last; } # check if table already exists
    }
    unless($tflg) { # if it doesn't...
      $dbhn->do("create table $taba(
        id   INT2 UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
        turn INT1 UNSIGNED NOT NULL,
        rivr INT1 UNSIGNED NOT NULL,
        hole INT1 UNSIGNED NOT NULL,
        wlot INT1 UNSIGNED,
        coun INT4 UNSIGNED )"
      ); # create tables to have Win, Lose, or Tie (1,3,2) && count times
    }
    $stmt = $dbhn->prepare("select wlot, coun from $taba where (turn='$itrn' && rivr='$irvr' && hole='$ieho')");
    $stmt->execute();
    $rows = 0; @rowa = (0, 0); # reset rows && wins, loss, ties counts
    $rows = $stmt->rows(); # find row if defined
    @rowa = $stmt->fetchrow_array() if($rows); # defined so get values to incr
    if($rowa[1]) {
      if($fiel ne $rowa[0]) {
        print "!*EROR*! New test yielded contradictory result for fiel:$fiel ihol:$ihol ieho:$ieho iflp:$iflp itrn:$itrn irvr:$irvr\n  hole:$holz[$ihol] ehol:$holz[$ieho] flop:$flpz[$iflp] turn:$rprg[$itrn] rivr:$rprg[$irvr]\n";
      }
    } else {
      $rowa[0] = $fiel;
    }
    $rowa[1]++;
    $stmt->finish();
    if($rows) { #     defined so update existing row
      $dbhn->do("update      $taba set                  coun='$rowa[1]'        where (turn='$itrn' && rivr='$irvr' && hole='$ieho')");
    } else    { # not defined so insert new      row
      $dbhn->do("insert into $taba set wlot='$rowa[0]', coun='$rowa[1]',              turn='$itrn',   rivr='$irvr',   hole='$ieho' ");
    }
    $dbhn->disconnect();
  }
}

sub ChekTabl { # checks if a database table exists && makes it if not
  return(0) unless($dbhn); my $taba = shift; my $tflg = 0;
  my @tblz = $dbhn->tables();
  foreach(@tblz) {
    s/(^`|`$)//g;
    if($_ eq $taba) { $tflg = 1; last; } # check if table already exists
  }
  unless($tflg) { # if it doesn't...
    $dbhn->do("create table $taba(
      id   INT2 UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
      turn INT1 UNSIGNED NOT NULL,
      rivr INT1 UNSIGNED NOT NULL,
      hole INT1 UNSIGNED NOT NULL,
      wlot INT1 UNSIGNED,
      coun INT4 UNSIGNED )"
    ); # create tables to have Win, Lose, or Tie (1,3,2) && count times
  }
}

sub WritData { # Saves mem data all to db at once at end of giant loop
  my $ihol = shift; my $daba = 'h' . $ihol; my $itrn; my $irvr; my $ieho;
  my $iflp = shift; my $taba = 'f' . $iflp; my $stmt; my $rows; my @rowa;
return;#print Dumper(@data);
  $ecou = 0; $dbhn = undef;
  while($ecou++ < $rtry && !$dbhn) {
    $dbhn = DBI->connect("DBI:mysql:$daba", undef, undef);
    sleep(1) unless($dbhn);
  }
  if($dbhn) {
    if($nofl) { # no flop so just use @data from turn on
      ChekTabl($taba);
      foreach $itrn (@data) {
        foreach $irvr (@{$data[$itrn]}) {
          foreach $ieho (@{$data[$itrn][$irvr]}) {
            $stmt = $dbhn->prepare("select wlot, coun from $taba where (turn='$itrn' && rivr='$irvr' && hole='$ieho')");
            $stmt->execute();
            $rows = 0; @rowa = (0, 0); # reset rows && wins, loss, ties counts
            $rows = $stmt->rows(); # find row if defined
            @rowa = $stmt->fetchrow_array() if($rows); # defined so get values to incr
            if($rowa[1]) {
              if($data[$itrn][$irvr][$ieho][0] ne $rowa[0]) {
                print "!*EROR*! New test yielded contradictory result for fiel:$data[$itrn][$irvr][$ieho][0] ihol:$ihol iflp:$iflp itrn:$itrn irvr:$irvr ieho:$ieho\n  hole:$holz[$ihol] flop:$flpz[$iflp] turn:$rprg[$itrn] rivr:$rprg[$irvr] ehol:$holz[$ieho]\n";
              }
            } else {
              $rowa[0] = $data[$itrn][$irvr][$ieho][0];
            }
            $rowa[1] = $data[$itrn][$irvr][$ieho][1];
            $stmt->finish();
            if($rows) { #     defined so update existing row
              $dbhn->do("update      $taba set                  coun='$rowa[1]'        where (turn='$itrn' && rivr='$irvr' && hole='$ieho')");
            } else    { # not defined so insert new      row
              $dbhn->do("insert into $taba set wlot='$rowa[0]', coun='$rowa[1]',              turn='$itrn',   rivr='$irvr',   hole='$ieho' ");
            }
          }
        }
      }
      @data = (); # empty @data at end
    } else {    # using flop so use %data
      foreach $iflp (keys(%data)) {
        $taba = 'f' . $iflp;
        ChekTabl($taba);
        foreach $itrn (keys(%{$data{$iflp}})) {
          foreach $irvr (keys(%{$data{$iflp}{$itrn}})) {
            foreach $ieho (keys(%{$data{$iflp}{$itrn}{$irvr}})) {
              $stmt = $dbhn->prepare("select wlot, coun from $taba where (turn='$itrn' && rivr='$irvr' && hole='$ieho')");
              $stmt->execute();
              $rows = 0; @rowa = (0, 0); # reset rows && wins, loss, ties counts
              $rows = $stmt->rows(); # find row if defined
              @rowa = $stmt->fetchrow_array() if($rows); # defined so get values to incr
              if($rowa[1]) {
                if($data{$iflp}{$itrn}{$irvr}{$ieho}[0] ne $rowa[0]) {
                  print "!*EROR*! New test yielded contradictory result for fiel:$data{$iflp}{$itrn}{$irvr}{$ieho}[0] ihol:$ihol iflp:$iflp itrn:$itrn irvr:$irvr ieho:$ieho\n  hole:$holz[$ihol] flop:$flpz[$iflp] turn:$rprg[$itrn] rivr:$rprg[$irvr] ehol:$holz[$ieho]\n";
                }
              } else {
                $rowa[0] = $data{$iflp}{$itrn}{$irvr}{$ieho}[0];
              }
              $rowa[1] = $data{$iflp}{$itrn}{$irvr}{$ieho}[1];
              $stmt->finish();
              if($rows) { #     defined so update existing row
                $dbhn->do("update      $taba set                  coun='$rowa[1]'        where (turn='$itrn' && rivr='$irvr' && hole='$ieho')");
              } else    { # not defined so insert new      row
                $dbhn->do("insert into $taba set wlot='$rowa[0]', coun='$rowa[1]',              turn='$itrn',   rivr='$irvr',   hole='$ieho' ");
              }
            }
          }
        }
      }
      %data = (); # empty %data at end
    }
    $dbhn->disconnect();
  }
}
