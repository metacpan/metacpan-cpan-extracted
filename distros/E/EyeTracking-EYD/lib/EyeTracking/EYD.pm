use strict;
use warnings;
package EyeTracking::EYD;
use Data::Dumper;
use Number::Range;
use List::MoreUtils qw{indexes}; # find record name as index

sub new {
 my $class = shift;
 my $self = {
     file => shift,
     id => shift,
     errorfile=>shift,
 };
 $self->{verbose}=0;
 #$self->{_startbyte} = 0;
 #$self->{_endbyte}   = 0;
 #$self->{_recfmt}    = 0;
 #$self->{_records}   = ();
 #$self->{data}       = ();
 bless $self, $class;
 
 return $self;
}
# need to remove the filehandle after we're done
sub DESTROY{
 my $self=shift;
 $self->{errorhandle}->close() if $self->{errorhandle};
 undef $self;
 #undef @ideal, @b, @m;
 #undef @retrived, @a, @n;
}


sub read {
 my $self=shift;
 open my $eydfile, $self->{file};

 # status code has 3 Booleen values, decode them with a hash instead of math
 my %TFkey = (  
             '0'  => [('FALSE')x3], 
             '16' => [qw/FALSE TRUE FALSE/],
             '32' => [qw/TRUE FALSE FALSE/],
             '48' => [qw/TRUE TRUE FALSE/ ]  );
 
 
 # what they say the data type is =>  what perl knows it as
 my %Dtype = ('Byte' => 'C', 'VT_UI1'=>'C', 'UInt16' => 'S', 'Int16' => 'S', 'VT_UI2' => 'S', 'VT_I2'=>'S');
 # anti eyd scans have these: s/VT_UI2/UInt16/;s/VT_I2/Int16/;
 
 my $endbyte    = 1;   # will be something much greater
 my $totalbytes = 0;   # not used? -- should use to check
 my @record;           # structure of data
 my @data;             # actual data
 #my @orgXdat;          # xdat before bitmask


 #####
 # populate data with each frame of eyd binary info
 #####
 $_ = <$eydfile>;
 if(!m/^\[File/){
    die "++ eyd file is not an eyd file!" ;
  }
  

 while(<$eydfile>){

  # keep going until we are about to hit binary data
  last if m/^\[Segment_Data\]/;

  # set endbyte location, skip if we already know it
  $endbyte        = $1  if /Segment_Directory_Start_Address: (\d\d+)/;

  # set total bytes
  $totalbytes     = $1   if !$totalbytes && /Total_Bytes_Per_Record: (\d+)/;
  
  #
  # only want the table with bytes in the byte column.
  #
  my @readData = split/\s+/;

  # between 3 and 4, and 4th is a digit
  next if $#readData > 4 || $#readData < 3  || $readData[3] !~ /^\d+$/;  


  # add what we have to the table
  push @record, [@readData];

 }


 print Dumper(@record),"\n" if $self->{verbose}>3;

 # end of text is start of binary
 my $start = tell($eydfile);

 # find where XDAT is, probably always 4
 my $xdatPos=0;
 $xdatPos++ while $record[$xdatPos][0] !~ /XDAT/ && $xdatPos <= $#record;
 

 # HEADER
 print join("\t", map {$_->[0] } @record),"\n" if $self->{verbose} > 2;

 # gaze data should be divided by 10
 # so find which index in data that is
 my @gazeIdx= indexes {/gaze/} map {$_->[0]} @record;


 # number of bytes to read
 # byte position of last record + it's size
 # -1 b/c we start at 0 not 1 ??
 # also as $totalbytes from header info, could check these numbers
 my $recSize = $record[-1]->[1] + $record[-1]->[3] -1;

 # format of line for upack # e.g.  CSSCSSSSSSS
 # join all data types mapped to either C (byte) or S (U/Int16) via hash
 my $recFmt  = join("",map { $Dtype{$_->[2]} } @record);
 for(@record) {
    print STDERR "unknown: ", $_->[2], "\n" if ! exists ($Dtype{$_->[2]});
 }
 #

 # need to know previous occurances for correction calculations
 my $prvXDAT    = 0;
 my $prvXDATidx = 0;


 print "@", tell($eydfile), "end is $endbyte\n" if $self->{verbose};
 while(tell($eydfile) < $endbyte || ( $endbyte==1 && !eof($eydfile) ) ) {
  my $info;

  # read in whole record and add to data
  read($eydfile,$info,$recSize);

  # get record as an array from binary
  my @unpacked = unpack($recFmt, $info);

  # scale the gazes
  $unpacked[$_] /= 10 for @gazeIdx;

  # and to master array
  push @data, [ @unpacked ];

  print join("\t",@{$data[-1]}),"\n" if  $self->{verbose} > 3;


  # xdat is masked -- according to ASLconvert in the ilab matlab package
  # deal with this when printing out
  #push @orgXdat, $data[-1][$xdatPos];                        # save origianl for print back
  ## see /mnt/B/bea_res/Data/Tasks/RingRewardsAnti/Basic/10297/20070523/Raw/EyeData/2623_ringreward_anti_run1.eyd 
  ## for when this is necessary
  $data[-1][$xdatPos] = ($data[-1][$xdatPos] + 65536) & 255; # add 2^16 mask out 2^8 ?? 
 }
 
 close $eydfile;


 # give the self some more vars
 $self->{_startbyte} = $start;
 $self->{_endbyte}   = $endbyte;
 $self->{_recfmt}    = $recFmt;
 $self->{_records}   = \@record;
 $self->{fields}     = [ map {$_->[0]} @{$self->{_records}} ];
 $self->{data}       = \@data;
 
 #return ($file,$start,$endbyte, $recFmt,\@data);
 #my %data;
 #for my $i (0..$#record){
 #  $data{"$record[$i]"} = map {$_->[$i]} @data;
 #}
 #return %data

}


sub printEyeData {
 my $self = shift;

 # write to
 my $filename = shift;
 open(my $fh, ">".($filename || '-')) or die "cannot open output in printCodes ($filename)\n";

 # the first element of each list in the _records list is the title
 my @items = map {$_->[0]} @{$self->{_records}};

 # we only want a few of them
 my @HdrIdx = indexes {/XDAT|pupil_diam|gaze/} @items;

 print $fh join("\t",@items[@HdrIdx]),"\n";
 # get each instances desired fields as a tab delim. string, then separate those by newlines 
 print $fh join("\n", map {join("\t",@{$_}[@HdrIdx])} @{$self->{data}} );

 close($fh);

}




sub printallEyeData {
 my $self = shift;
 print join("\t", @{$self->{fields}}),"\n";
 print join("\n", map {join("\t",@{$_})} @{$self->{data}} );
}


#  "code:" array of hashes
#[
#{
#      'target' => { 'xdat' => 149, 'pos' => 25571 },
#      'stop'   => { 'xdat' => 250, 'pos' => 25668 },
#      'start'  => { 'xdat' => 100, 'pos' => 25389 }
#      'first'  => 25389,
#      'last'   => 28322,
#      'startcode'  => 100
#      'targetcode' => 149
#},




sub trialPositions {
 my $self = shift;
 my ($startCodes,$targetCodes,$stopCodes) = @_;


 #### find all trials

 my ($oldstate,$newstate)=(-1,-1); # none=-1,start=0,target=1,stop=2
 my %statelook=(0=>'start',1=>'target',2=>'stop');
 #$self->{codes}; # stores hash array
 my $curCode=-1;
 my @ranges=($startCodes, $targetCodes, $stopCodes);
 my %init=(xdat=>-1, pos=>-1);
 my %trial=(start=>{%init}, stop=>{%init}, target=>{%init}, first=>-1,last=>-1,startcode=>-1,targetcode=>-1);
 #my %trial=(start=>{%init}, stop=>{%init}, target=>{%init}, first=>-1,last=>-1);

 my @xdatidx = indexes {/XDAT/i} @{$self->{fields}};
 #TODO warn if $#xdatidx>0
 #
 my @codes=map {$_->[$xdatidx[0]]} @{$self->{data}};
 # iterate through all xdats read by ASL eye tracker
 while (my ($idx, $xdat) = each(@codes) ){
  #$xdat=50 if $xdat==48;
  next if $xdat == $curCode;
  # update current code
  $curCode=$xdat;
  # check what range the xdat is in, update state
  my $inrange=0;
  while( my ($state,$range) = each @ranges ) {
    if( $range->inrange($xdat) ) {
     $oldstate=$newstate;
     $newstate=$state;
     $inrange=1;
    }
  }
  
  # warn and skip if xdat is off
  # we dont have to warn about the last xdat, 65278
  if( !$inrange  ) { $self->writeerror("xdat $xdat at pos $idx is not in a known range!") if $xdat != 65278; next}
  
  # when the next state comes before the old state and we've recovered at least one code
  # push what's in this trial to codes, clear row, need to push after finish too -- capture last
  my $numRecov = scalar(grep {$_->{xdat}!=-1} @trial{qw/start target stop/});
  if($newstate<=$oldstate && $numRecov>0) {
    $trial{last}=$idx-1;
    $trial{startcode}=$trial{start}->{xdat};
    $trial{targetcode}=$trial{target}->{xdat};
    $trial{ITI}=$trial{last} - $trial{start}->{pos};
    push @{$self->{codes}}, {%trial};
    %trial=(start=>{%init}, stop=>{%init}, target=>{%init}, first=>-1,last=>-1,startcode=>-1,targetcode=>-1);
    #%trial=(start=>{%init}, stop=>{%init}, target=>{%init}, first=>-1,last=>-1);
  }


  # build trial up
  $trial{ $statelook{$newstate} } = { xdat=>$xdat, pos=>$idx };
  $trial{first}=$idx if $trial{first}==-1;


 }
 # get last trial
 if (scalar(grep {$_->{xdat}!=-1} @trial{qw/start target stop/}) > 0 ) {
    $trial{last}=$#{$self->{data}};
    $trial{startcode}=$trial{start}->{xdat};
    $trial{targetcode}=$trial{target}->{xdat};
    $trial{ITI}=$trial{last} - $trial{start}->{pos};
    push @{$self->{codes}},{%trial};
 }

}



sub barsEprimeLog {
   my $self = shift;
   my %xDATlookup = (
                  'FIVEpunish007' => 147, 'FIVEpunish108' => 148,  
                  'FIVEpunish532' => 149, 'FIVEpunish633' => 150,
                  'FIVEreward007' => 127, 'FIVEreward108' => 128,
                  'FIVEreward532' => 129, 'FIVEreward633' => 130,
                  'neutral007'    => 201, 'neutral108'    => 202,
                  'neutral532'    => 203, 'neutral633'    => 204);


   my ($file) = @_;
   open my $txtfile, $file or die "error opening eprime log file $file: $!";
   ## prepare vars
   my @frames;
   # want these fields from txt file
   my @flds=qw/masterlist location Procedure Running Latency Score Correct fixation/;
   print join(",",@flds),"\n" if $self->{verbose};

   # Skip the header
   $_=<$txtfile>;
   $_=<$txtfile> while( ! m/ Header End /);
   my @data;
   my %col;
   my %prevScored;
   my $fixation="";
   
   # run through LogFrame Start/End blocks
   # collecting all the blocks between procuedures that have location frames (a scorable event)

   while(<$txtfile>) {
     @col{@flds}=("NA")x($#flds+1) if/ LogFrame Start /;     # initilize to all 0s
     s/\r//g;                                                # strip windows characters
     $col{"$1"}="$2"  if m/\s+(.*): (.*)$/;                  # get all pairs
     if( / LogFrame End /) {
        print join(",",@col{@flds}),"\n" if $self->{verbose} > 1;

        # there is a location, we've seen fixations
        # time to publish what we have
        # if location and fixation are empty, this is the first, and we should continue
        # so we can collect the ITI
        if( $col{location} ne '' and $fixation ne '') {
           # sum ITI time (including fixations)
           $prevScored{fixationTxt}=$fixation;
           $fixation=~s/LongFix/363/g;
           $fixation=~s/[a-z]*Catch2/182/g;
           $fixation=~s/[a-z]*Catch1|fix/91/g;
           $prevScored{duration}=eval("0$fixation"); # 0+363+$col{Procedure}

           my $Proc=$prevScored{'Procedure'};
           my $startcode=50; if ($Proc =~ m/punish/) { $startcode=100} elsif($Proc=~ m/neutral/){$startcode=200};
           my %finalhash;
           @finalhash{(@flds,'fixationTxt')}=@prevScored{(@flds,'fixationTxt')};
           #$finalhash{'Procedure'} = $Proc; # this is already ahead, need to pull it back before commiting
           push @data, {%finalhash, 'startcode'=>$startcode, 'targetcode' =>$xDATlookup{$Proc} };
           $fixation="";

           #there are only 42 runs
           last if $#data>=41
         }

        # we have Catch trials and fixations to account for
        $fixation.="+$col{Procedure}" if $col{Procedure} =~ m/Fix|Catch/i;
        $fixation="" if $col{Procedure} eq 'NA';

        # continue if we lack data, especially location (dot never appears, not scorable)
        next if $col{location} eq '' || $col{Procedure} eq 'NA' || $col{Running} ne 'masterlist';

        %prevScored=%col;
      }
   }

   close $txtfile;
   $self->{_idealOrderHash}=\@data;
}

#
# use a parsed eprime file (long form of masterlists)
sub barsEprimeTrialOrder {
   my $self = shift;
   my @data=();
   my %xDATlookup = (
                  'FIVEpunish007' => 147, 'FIVEpunish108' => 148,  
                  'FIVEpunish532' => 149, 'FIVEpunish633' => 150,
                  'FIVEreward007' => 127, 'FIVEreward108' => 128,
                  'FIVEreward532' => 129, 'FIVEreward633' => 130,
                  'neutral007'    => 201, 'neutral108'    => 202,
                  'neutral532'    => 203, 'neutral633'    => 204);


   my ($file) = @_;

   #want to mirror relevant bits of actually going through the log file
   #$VAR42 = {
   #   'startcode' => 100,
   #   'targetcode' => 149,
   #   'location' => '532',
   #   'fixationTxt' => '+LongFix',
   #   'fixation' => 363,
   #   'Procedure' => 'FIVEpunish532',
   #};
   open my $txtfile, $file or die "err opening eprime trial order file $file: $!";
   # file like "~/remotes/B/bea_res/MR_Scanner_Experiments/Scanner Tasks/MRRC tasks/Rewards Scanner Bars/OrderOfEvents-v1.txt"
   # 1 neutral007
   # 1 LongFix
   # 2 FIVEpunish532
   # 2 LongFix
   # 3 FIVEreward532
   # 3 LongFix
   # 3 fix
   # 3 fix
   # 3 punCatch1
   # 3 fix
   # 4 neutral532
   while(<$txtfile>) {
     # format checks
     die "eprime run order file has unexpected format ($. = $_)"  if length(split(/\s+/)) > 1;
     next if /^ .*fix$/; # start with fix, no trial number -- i.e. run 3

     # read
     my ($trialnum,$event) = split/\s+/;
     print "$trialnum,$event\n" if $self->{verbose};

     # add fixations
     if($event =~ /Fix|catch/i){
      ${$data[$trialnum-1]}{fixationTxt}='' if !exists(${$data[$trialnum-1]}{fixationTxt});
      ${$data[$trialnum-1]}{fixationTxt}.= "+$event";
     }

     # add event
     else {
      ${$data[$trialnum-1]}{Procedure} = $event;
      #print "\ttarget and start code setting!\n";
      ${$data[$trialnum-1]}{targetcode}= $xDATlookup{$event};
      # startcode   reward: 50   punish:100    neut: 200
      $_=$event;
      ${$data[$trialnum-1]}{startcode}= /reward/? 50 : (/punish/? 100 : 200);
      ${$data[$trialnum-1]}{location} = $1 if /(\d{3})$/;
     }
   }

   close $txtfile;
   for (0..$#data){
     my $fixation=${$data[$_]}{fixationTxt};
     # longfix is known to only happen once and immediatly after a prep+cue+sac
     # prep+cue+sac+fix = 91*4
     $fixation=~s/LongFix/363/g;
     $fixation=~s/[a-z]*Catch2/182/g;
     $fixation=~s/[a-z]*Catch1|fix/91/g;
     ${$data[$_]}{duration}=eval("0$fixation"); # 0+363+....
   }
   $self->{_idealOrderHash}=\@data;
}



#
# use a parsed eprime file (long form of masterlists)
sub ringsEprimeTrialOrder {
   my $self = shift;
   my @data=();
   my %xDATlookup = (
                  'neutralcatch1' => 121, 'neutralcatch2' => 131,
                  'rewardcatch1'  => 141, 'rewardcatch2'  => 151,

                  'neutral007'    => 161, 'neutral108'    => 162,  
                  'neutral214'    => 163, 'neutral426'    => 164,
                  'neutral532'    => 165, 'neutral633'    => 166,

                  'reward007'     => 181, 'reward108'     => 182,
                  'reward214'     => 183, 'reward426'     => 184,
                  'reward532'     => 185, 'reward633'     => 186
   );
   our %startCodesHash = (
   	'neutralcatch1'=> 20,
   	'neutralcatch2'=> 30,
   	'rewardcatch1' => 40,
   	'rewardcatch2' => 50,
   	'neutral'      => 60,
   	'reward'       => 80
   );



   my ($file) = @_;

   #want to mirror relevant bits of actually going through the log file
   #$VAR42 = {
   #   'startcode' => 80,
   #   'targetcode' => 185,
   #   'location' => '532',
   #   'fixationTxt' => '+Fix',
   #   'fixation' => 91,
   #   'Procedure' => 'reward532',
   #};
   open my $txtfile, $file or die "err opening eprime trial order file $file: $!";
   # file like "~/remotes/B/bea_res/MR_Scanner_Experiments/Scanner Tasks/MRRC tasks/Rewards Scanner Bars/OrderOfEvents-v1.txt"
   # 1 neutral007
   # 1 Fix
   # 2 reward532
   # 2 Fix
   # 3 reward532
   while(<$txtfile>) {
     # format checks
     die "eprime run order file has unexpected format ($. = $_)"  if length(split(/\s+/)) > 1;
     next if /^0? .*fix$/; # start with fix, no trial number -- i.e. run 3

     # read
     my ($trialnum,$event) = split/\s+/;
     print "$trialnum,$event\n" if $self->{verbose} > 1;

     # add fixations
     if($event =~ /Fix/i){
      # fixes do not send an xdat
      # catch2's do not leave enough space between sending start,target, and stop for anything but the stop xdat to be seen
      ${$data[$trialnum-1]}{fixationTxt}='' if !exists(${$data[$trialnum-1]}{fixationTxt});
      ${$data[$trialnum-1]}{fixationTxt}.= "+$event";
     }

     # add event
     else {
      ${$data[$trialnum-1]}{Procedure} = $event;
      $event=lc($event);
      print "Warning: $event is unknown!\n" if ! exists($xDATlookup{$event});
      #print "\ttarget and start code setting!\n";
      ${$data[$trialnum-1]}{targetcode}= $xDATlookup{$event};
      $_=$event;
      /(neutral|reward)(catch\d)?/i;
      ${$data[$trialnum-1]}{fixationTxt}.= "+$&";
      ${$data[$trialnum-1]}{startcode}= $startCodesHash{lc($&)};
      ${$data[$trialnum-1]}{location} = $1 if /(\d{3})$/;
     }
   }

   close $txtfile;
   my $i=0;
   while($i<=$#data){
     # we take in catch2, but the xdat never has time to send, so it not actually seen
     # compensate by removing from data list, but appending to fixation of the next guy
     # we run into problems if catch is the last thing
     if($i<$#data && ${$data[$i+1]}{Procedure} =~ /catch2/i ) {
      ${$data[$i]}{fixationTxt} .=  ${$data[$i+1]}{fixationTxt};
      splice(@data,$i+1,1);
     }

     my $fixation=${$data[$i]}{fixationTxt};
     $fixation=~s/fix/90/ig;
     $fixation=~s/\+(neutral|reward)catch1/+180/ig; # ~3*60
     $fixation=~s/\+(neutral|reward)catch2/+90/ig;  # ~1.5*60
     $fixation=~s/\+(reward|neutral)/+4.5*60/ig; # ~ 4.5*60
     ${$data[$i]}{duration}=eval("0$fixation"); # 0+363+....

     print "$i: $fixation=>",${$data[$i]}{duration}, " ", ${$data[$i]}{fixationTxt}, "\n" if $self->{verbose} > 2;

     $i++;
   }
   $self->{_idealOrderHash}=\@data;
}



# companion function to write errors
# done this way so error writing can be abstracted and
# so we dont open a file when we dont have an error to write
sub writeerror {
  my $self = shift;
  my $msg  = shift;

  if(!$self->{errorhandle}) { 
     open($self->{errorhandle} ,">&", \*STDERR ) or die "cannot open STDERR, something's really wrong!\n"; 
     if($self->{errorfile}) {
      close( $self->{errorhandle} );
      open($self->{errorhandle} , ">", $self->{errorfile}) or die "cannot open error file for checkAlignment ( $self->{errorfile})\n";
    }
  }

  print { $self->{errorhandle} }  "$self->{id} $msg\n";
  print "\t$msg\n" if $self->{printerrors};
  
}


sub checkAlignment {
   use Algorithm::NeedlemanWunsch;
   my $self = shift;

   #
   # score
   #  fit trial xdats to those recorded by eprime
   #  with dynamic programing matching algorithm (needlemanWunsch)
   #
   #
   # make copies of the two hashes
   our @ideal= @{$self->{_idealOrderHash}};
   our @retrived= @{$self->{codes}};
  
   our ($a, $b)=("","");
   sub score_sub {
      return -2 if !@_;                 # gap penalty
      my $a=$_[0]->{startcode};
      my $b=$_[1]->{startcode};
      my $a2=$_[0]->{targetcode};
      my $b2=$_[1]->{targetcode};
      #return ($_[0] eq $_[1]) ? 1 : -5; # match, mismatch
      # if start codes are the same +2, if not but they're in the same block -1, otherwise -2
      my $score=($a eq $b) ? 2 : (abs($a-$b)<100)? -1: -2;
      # targets match +2, same for targets
      $score+=($a2 eq $b2) ? 2 : (abs($a-$b)<100)? -1 : -2;

      print "$a/$b\t$a2/$b2: $score\n" if $self->{verbose} > 1;
      return $score;
      #### previous scoring 
      #### donno what was goign on
      return ($a eq $b && $a2 eq $b2) ? 4: -5 if ($a*$b<0); # misalign-- taget and stop align=4, dont -5
      return ($a2 eq $b2) ? 3: -5 if ($a*$b<0);             # never seen
      return ($a eq $b) ? 1 : -5;                           # mismatch = -5
   }
  
   # Magic alignment (make string, pop as matched/gapped, reverse)
   # n and m collect indexes (-1 is used if somethign is skipped)
   # a and b are string representations of the alingment
   #
   # alignment only made on start codes
   # TODO: include target codes!
   #
   our ($n,$m)=($#ideal,$#retrived);
   our (@n,@m)=();
   sub shifta_sub {$b="___:___;$b"; $a=sprintf("%03d:%03d;$a",@{pop(@ideal)}{qw/startcode targetcode/});     push @m,-1;push @n,$n--;}
   sub shiftb_sub {$a="___:___;$a"; $b=sprintf("%03d:%03d;$b",@{pop(@retrived)}{qw/startcode targetcode/});  push @n,-1;push @m,$m--;}
   #sub onalign    {$a=sprintf('%03d',pop(@ideal)->{startcode}).";$a"; $b=sprintf('%03d',pop(@retrived)->{startcode}).";$b";  push @m,$m--; push @n,$n--;}
   sub onalign {
            $a=sprintf("%03d:%03d;$a",@{pop(@ideal)}{qw/startcode targetcode/}); 
            $b=sprintf("%03d:%03d;$b",@{pop(@retrived)}{qw/startcode targetcode/});
            push @m,$m--; push @n,$n--;
   }
  
   my $matcher = Algorithm::NeedlemanWunsch->new(\&score_sub);
   my $score=$matcher->align(\@ideal,\@retrived, { shift_b=>\&shiftb_sub, shift_a=>\&shifta_sub, align=>\&onalign});
   
   $self->{alignment_eprime} = $a;
   $self->{alignment_eyd}    = $b;
   print "$score:\nep:$a\ney:$b\n" if $self->{verbose};

   #looks like:
   #40:
   #___;200;100;050;200;200;050;200;100;100;200;050;050;050;100;050;200;100;050;200;100;200;050;200;200;100;100...
   #-01;200;100;050;200;200;050;200;100;100;200;050;050;050;100;050;200;100;050;200;100;200;050;200;200;100;100...



   # indexes are end to start, not useful for printing
   @n=reverse @n;
   @m=reverse @m;
   # say "@n\n@m";
  
   
  
   # eyd codes: start targ stop
   # eyd time index: start targ stop laststop
   # eprime run order expected codes: start targ stop
   my @codeTable=([qw/strt trg stp ITIo ITIe | strtp trgp stpp lastp proc strtep trgep stpep/]);
   for my $i (0..$#n) {
    # negative index ($i) means bad alignment 
    if($n[$i] <0 ||  $m[$i] < 0) { 
      # n is expected, m is observed
      # if n is negative, expected is behind
      my $whosbehind=($n[$i] < 0)?"expected":"observed";
      $self->writeerror("bad alignment: missed trial! (@ trial $i: $whosbehind code is behind )") if $i > 0; 
      next
    }
    my $epIdx=$n[$i]; # from eprime inde$m[$i] x
    my $eyIdx=$m[$i]; # from eyd index
    my @t=();
    push @t, map {$_->{xdat} } @{$self->{codes}->[$eyIdx]}{qw/start target stop/};
    #push @t, @{$self->{_idealOrderHash}->[$epIdx]}{qw/startcode targetcode/}, 250;
    my $ITIobs = @{$self->{codes}}[$eyIdx]->{last} - @{$self->{codes}}[$eyIdx]->{start}->{pos};
    my $ITIhyp = @{$self->{_idealOrderHash}->[$epIdx]}{duration};
    push @t, $ITIobs, $ITIhyp; 
    push @t, "|";
    push @t, map {$_->{pos}  } @{$self->{codes}->[$eyIdx]}{qw/start target stop/};
    push @t, $self->{codes}->[$eyIdx]->{last};
    push @t, @{$self->{_idealOrderHash}->[$epIdx]}{fixationTxt};
    push @t, @{$self->{_idealOrderHash}->[$epIdx]}{qw/startcode targetcode/}, 250;
    push @codeTable, [@t];

    #@t=();
    #push @t, $IT 

    # if the estimate is off by more than a sample between the trials
    # 2 and 41, complain
    if(abs($ITIhyp - $ITIobs) > 1 and $i>1 and $i<42 ) { 
       $self->writeerror("ITI error\@trial $i, obs $ITIobs != hyp $ITIhyp");
    }

    # output useful for graphviz visualization of corrupt codes
    # but should be the same info as what is printed by score,a,b above
    for my $type (qw/startcode targetcode/){ 
       my $hypCode = $self->{_idealOrderHash}->[$epIdx]->{$type};
       my $obsCode = $self->{codes}->[$eyIdx]->{$type};
        $self->writeerror("$hypCode -> $obsCode #expectted -> obs (\@trial $i)") if $hypCode != $obsCode;
    }
  }
   
  # Print codetable if we ask for it
  # either by specifiying codeTableFN
  # or by setting verbose to 1

  #strt trg   stp   ITIo  ITIe  strtp trgp  stpp  lastp proc
  print join("\n", map {join("\t",@{$_}[0..10])} @codeTable) if $self->{verbose};

  if($self->{codeTableFN} and open(my $codeTableFH, '>',$self->{codeTableFN}) ){
     print $codeTableFH join("\n", map {join("\t",@{$_}[0..10])} @codeTable) ;
     close $codeTableFH;
  }

  $self->{checked}    = [ @codeTable[1..$#codeTable] ];
  # checkedHdr is a hash with header names pointing to an index
  while( my ($idx,$key) = each @{$codeTable[0]} ) { $self->{checkedHdr}->{$key}=$idx }

  return $score;
}

sub printCodes {
  my $self = shift; 

  # write to
  my $filename = shift;
  open(my $fh, ">".($filename || '-')) or die "cannot open output in printCodes ($filename)\n";

  for my $i (0..$#{$self->{codes}}) {
     next if $self->{codes}->[$i]->{start}->{xdat} == -1;
     my @a;
     push @a, map {$_->{xdat}} @{$self->{codes}->[$i]}{qw/start target stop/};
     push @a, map {$_->{pos}  } @{$self->{codes}->[$i]}{qw/start target stop/};
     print $fh join("\t",@a), "\n";
   }

   close($fh);
}


1;

__END__

=pod

=head1 NAME

EyeTracking::EYD

=head1 VERSION

version 0.1.2

=head1 SYNOPSIS

   # the binary EYD file
   my $file='/home/foranw/remotes/B/bea_res/Data/Tasks/BarsScan/Basic/10128/20080925/Raw/EyeData/10128_run1.eyd';
   my $id="10128.20090925.1";
   my $errorfile="$id.err";
   # an expected order-of-events long file

   my $order='/home/foranw/remotes/B/bea_res/MR_Scanner_Experiments/Scanner Tasks/MRRC tasks/Rewards Scanner Bars/OrderOfEvents-v1.txt';
   ##trial.num event
   #1 neutral007
   #1 LongFix
   #2 FIVEpunish532
   #2 LongFix
   #3 FIVEreward532
   ### used by barsEprimeTrialOrder
   ### hardcoded xdat codes (start,target,stop) as hash from e.g. neutral007
   ###           time delays as a result of eg LongFix


   my $eyd = EyeTracking::EYD->new($file,$id,$errorfile);
   # $eyd->{verbose}=1;     # print lots of fun things
   # $eyd->{printerrors}=1; # errors also go to stdout
   $eyd->read();
   # print Dumper($eyd->{data}),"\n";
   $eyd->printEyeData(); # just: xdat, dil, gaze
   $eyd->printallEyeData(); # print everying


   use Number::Range;
   my $startCodes  = Number::Range->new("50,100,200");
   my $targetCodes = Number::Range->new("110..160,201..210");
   my $stopCodes   = Number::Range->new("250");
   $eyd->trialPositions($startCodes,$targetCodes,$stopCodes );
   # print Dumper($eyd->{codes}),"\n";

   # print codes and index in triplet pairs
   # eg. 100  147  250  15387 15568 15666
   $eyd->printCodes();

   # use order of exerpiment to set timing
   $eyd->barsEprimeTrialOrder($order);
   #print Dumper($self->{_idealOrderHash})
   $eyd->checkAlignment();
   # with verbose, prints a nice list like:
   #strt trg   stp   ITIo  ITIe  strtp trgp  stpp  lastp proc
   #200  201   250   357   363   |  480   656   753   837   +LongFix
   #

   #$eyd->{checked}
   # we have a 'legacy' format to persever
   # print in that format
   my @fields=@{$eyd->{checkedHdr}}{qw/strt trg stp strtp trgp stpp lastp strtep trgep stpep/};
   print ( map {join("\t",@$_[@fields ]),"\n"} @{$eyd->{checked}}  ), "\n";

=head1 DESCRIPTION

This provides functions to deal with ASL EYD binary files
specifically in the context of EPrime run experments.

In addition to pupil dilation and gaze location,
we are particularly interested in using the eyd timing as a way to 
confirm task progress (via xdat codes)
and adjust expected timing from eprime (via sample number)

Parsing the binary file was largely copied from
L<http://tech.groups.yahoo.com/group/ilab/>

=head1 NAME

EyeTracking::EYD - extract EYD binary files in a start,target,stop paradigm

=head1 METHODS

=head2 new

C<< $eyd = EyeTracking::EYD->new($file,$id,$errorfile) >>
requries an eyd file be passed as the sole argument
set C<< $self->{verbose} >>  to true for more printing 

=head2 read

C<< $eyd->read() >>
reads the eyd file provided when new() is called

creates C<< $eyd->{qw/_startbyte _endbyte _recfmt _records fields data} >>

=over

=item data and fields

data is a 2D array of where each row 
has a sample of of @fields
=item @_records

@_records stores the type and name of each field

=item other

_recfmt, start, and endbyte together describe
the start and end of the binary blob and what the order
of encoding is

"Corrects" gaze by origvalue/10

this code is taken mostly from ilab
=back

=back

=head2 printEyeData

C<< $eyd->printEyeData(filename=<stdout>) >>
prints XDAT, pupil_diam and gaze to stdout unless af filename is given
one sample per line

=head2 printallEyeData

C<< $eyd->printallEyeData() >>
prints everything collected
one sample per line

=head2 trialPositions

C<< $eyd->trialPositions($start,$target,$stop) >>
where start,target,stop are all number::range ojbects
will make a wide fromate table of
start | target | stop in the form of a hash as C<{codes}>

   my $startCodes  = Number::Range->new("50,100,200");
   my $targetCodes = Number::Range->new("110..160,201..210");
   my $stopCodes   = Number::Range->new("250");
   $eyd->trialPositions($startCodes,$targetCodes,$stopCodes) 
   print Dumper($eyd->{codes})

=head2 barsEprimeLog and barsEprimeTrialOrder

C<< $eyd->barsEprimeLog($logfile) >> or C<< $eyd->barsEprimeTrialOrder($orderfile) >>
results in C<< $eyd->{_idealOrderHash} >>

where logfile is an eprime experement's log file and 
orderfile is a space deliminted file with 'trial# displayevent' on each line

logfiles are specific to one subject on a particular run
orderfiles are generic for all subjects for a particular run

the output is an array of hashes like

   $VAR42 = {
      'startcode' => 100,
      'Latency' => '451',              #*
      'masterlist' => '142',           #*
      'location' => '532',
      'fixationTxt' => '+LongFix',
      'fixation' => 363,
      'targetcode' => 149,
      'Score' => '60',                 #*
      'Procedure' => 'FIVEpunish532',
      'Correct' => '1',                #*
      'Running' => 'masterlist'        #*
   };

* denotes hash elements only created by barsEprimeLog not in barsEprimeTrialOrder

fixationTxt is a + delim. list of fixation events 
duration is the number of samples (assumed 60Hz) as estimated by parsing and evaluating fixationTxt

=over

=item example orderfile

   1 neutral007
   1 LongFix
   2 FIVEpunish532
   2 LongFix
   3 FIVEreward532
   3 LongFix
   3 fix
   3 fix
   3 punCatch1
   3 fix
   4 neutral532
   ...

=item example logfile

=item study details

|    bars            |      cross     |   dot        |     cross
cue                 prep             sac             |  fixations
|                    |                |              |
start                               target          stop=250
|    1.5                   1.5             1.5       |          1.5s*N  LongFix==2*1.5s
|    {,ONE..FIVE}{punish,neutral,reward}{[position]} |  LongFix + { fix,Catch{1,2} }*

=back

=head2 Ring Rewards

We can also parse ring rewards eprime order files
parsed trial information is stored in C<< $eyd->{_idealOrderHash} >>

=head2 checkAlignment

C<< $eyd->checkAlignment(filename=<STDERR>)  >> returns the alignment score between observed and experiement setup (eprime)
and prints alignment errors to stderr or specified file
extensivle checks value of C<< $self->{verbose} >> when printing 

uses {_idealOrderHash}  and {codes} (both arrays of hashes with startcode and targetcode)
to find the optimal (NeedlemanWunsch with gap/mismatch=-5) alignment of start and target codes

setting C<< $self->{codeTableFN} >> to a file will 
write the ITIobserved against ITIexpected table to that file

=head2 printCodes

C<< $eyd->printCodes()  >> prints codes to a given file name (or stdout if no arguments)
is a nice way of exporting C<< $self->{codes} >>

=head1 AUTHOR

Will Foran <willforan+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Will Foran <willforan+cpan@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
