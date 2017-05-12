package Finance::Quant;

use strict;
use warnings;
no warnings 'redefine';
use Finance::Google::Sector::Mean;
use Finance::NASDAQ::Markets;
use Finance::Quant::Symbols;
use Cache::Memcached;
use Statistics::Basic qw(mean);
use List::Util qw(max min sum);
use vars qw/$VERSION @directories @DATA %files $current @symbols $textbuffer $textview $dir $sources/;
use LWP::UserAgent;
require Exporter;
our @ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
# This allows declaration	use Finance::Quant::Quotes ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(
new recommended Home updateSymbols
);
our $VERSION = '0.09';
use WWW::Mechanize;
use Carp;
use File::Copy;
use Data::Dumper;
use File::Spec::Functions;
use File::Path;
use Time::Local;
use File::Fetch;
use HTML::TreeBuilder;
use Text::Buffer;
use File::Find;
use Finance::Optical::StrongBuy;
use MIME::Base64;
use GD::Graph::lines;
use Finance::Quant;
use Statistics::Basic qw(mean);
use List::Util qw(max min sum);

our $DEBUG = 10;
our $DEBUG_TO_SYSLOG=1;
our $LOGGER_EXE="/usr/bin/logger";
our @directories = qw(download ibes-strong-buy ratings symbols charts backtest);
our %files;
our $current="Finance-Quant";
our $dir = File::Spec->tmpdir();
our ($recurse, $name, $case,$linenums,$quick_start, $use_regex,$seeking,$textbuffer,$textview,$cancel) =(1,1,1,1,1,1,1,undef,undef); ##< patch

our $memd = new Cache::Memcached {
'servers' => [ "127.0.0.1:11211"],
'debug' => 0,
'compress_threshold' => 10_000,
} or warn($@);


our $sources = {
      'TIME_SALES'           => "http://www.nasdaq.com/symbol/%s/time-sales",
      'RT_QUOTE'             => "http://www.nasdaq.com/symbol/%s/real-time",
      'NASDAQ_SYMBOLS'       => "ftp://ftp.nasdaqtrader.com/symboldirectory/nasdaqlisted.txt",
      'NASDAQ_COMMUNITY'     => "http://www.nasdaq.com/symbol/%s/real-time",
      'IBES_ICON'            => "http://content.nasdaq.com/ibes/%s_Smallcon.jpg",
      'GURU'                 => "http://www.nasdaq.com/symbol/%s/guru-analysis",
      #'IBES_RECOMMENDATIONS' => "http://www.nasdaq.com/symbol/%s/recommendations",
      #'IBES_ANALYST'         => "http://www.nasdaq.com/symbol/%s/analyst-research",
      'YAHOO_CHART'          => "http://chart.finance.yahoo.com/z?s=%s&t=3m&q=c&l=on&z=l&p=b,p,v,m20&a=m26-12-9&lang=en-US&region=US"
    };
sub recommended {
    my $class = shift;
    my $config = {};
    my $self = $class->new($config);
       $self->{config}->{'ibes'} = {SP500=>1,NYSE=>1,AMEX=>0,NASDAQ=>1,CUSTOM=>0},
       $self->{config}->{'swing-entry'} = {DAX=>1,TECHDAX=>1,MDAX=>1,SP500=>1};
       $self->{config}->{'sector-data'}         = 1;
       $self->{config}->{'markets'}             = 1;
       $self->{config}->{'yahoo-charts'}        = 1;
       $self->{config}->{'nasdaq-user-rating'}  = 1;
       $self->{config}->{'nasdaq-guru-rating'}  = 1;
       $self->{config}->{'sources'}  = $sources;
    $self->createDataDir();
    $self->_init();
    return $self;
}
sub updateSymbols {
    my $self = shift;
    $self->getNasdaqSymbols(File::Spec->tmpdir(),$self->{config}->{sources}->{NASDAQ_SYMBOLS});
}
sub _init{
    my $self = shift;
    $self->{config}->{sources} = $sources;
    my $syms = Finance::Quant::Symbols->new();
    my @DATA = @{$syms->{symbols}};
    
    foreach(@DATA){
      if(defined($self->{config}->{'ibes'}->{$_->[0]}) &&
         $self->{config}->{'ibes'}->{$_->[0]} == 1)  {
         $self->{config}->{'ibes'}->{$_->[0]} = $_->[1];
         if($_->[0] eq "NASDAQ"){
            $self->{config}->{'ibes'}->{NASDAQ}=$self->updateSymbols();
         }
      }
    }
    $self->{'sector-summary'} = {
        summary=>[Finance::Google::Sector::Mean::sectorsummary()],
        quotes=>[Finance::NASDAQ::Markets::sector()]
    } unless(!$self->{config}->{'sector-data'});
    $self->{'indices'} =  {
        quotes=>[Finance::NASDAQ::Markets::index()]
    }unless(!$self->{config}->{'markets'});
}



sub new {
    my $class = shift;
    my $symbol = shift;
    my $date = gmtime;
    my @e = split " ",$date;# =~ s/ /_/g;
  
    if(defined($e[2]) && (length $e[2]) == 1) {
      $e[2] = "0".$e[2];
    }
    my $downfolder  = "$e[4]-$e[1]-$e[2]"; 
    my $self = bless {
        config=>{'ibes'=>{CUSTOM=>$symbol},sources  => $sources},
        optical=>Finance::Optical::StrongBuy->new($dir),
        #testthread=>testthread->new($dir,10,$downfolder),
        downfolder=>$downfolder,
        dir=>$dir,
        date=>$date,
    }, $class;
#
#


    $self->{config}->{'nasdaq-guru-rating'}  = 1;
    $self->{textbuffer} = new Text::Buffer(-file=>'my.txt');
    
    $self->Dbg(2,"CREATED INSTANCE of $self");        
    
    return $self;
}


sub getDateDir {
  my $self = shift;

  my $date = gmtime;
  my @e = split " ",$date;# =~ s/ /_/g;
  
  if(defined($e[2]) && (length $e[2]) == 1) {
    $e[2] = "0".$e[2];
  }
  
  return "$e[4]-$e[1]-$e[2]";

  
}

sub Dbg {
  my $level=shift @_;
  my $msg = shift @_;
  # If the $DEBUG level exceeds the level at which we log this mess
      my @args=`echo '$0 $msg' | $LOGGER_EXE`;
      printf("\n",$msg);
}


sub getNasdaqSymbols {
  my $this = shift;
  my $dir  = shift;
  my $url = shift;
    if( defined $dir ) {
        my $ff = File::Fetch->new(uri => $url);
        my $where =  $ff->fetch(to =>$dir);
        return $this->symClean($where);
    }else{
        croak "need a working directory";
    }
}


sub get_source_image {
  my($this)= shift;
  my ($json_url) = @_;
  my $EXIT_CODE = 1;
  my $content = "";
  my $browser = WWW::Mechanize->new(
          stack_depth     => 0,
          timeout         => 3,
          autocheck       => 0,
  );
  $browser->get( $json_url );
  if ( $browser->success( ) ) {
    $EXIT_CODE=0;
  } else {
    $EXIT_CODE=1;
  }
  $content = $browser->content() unless($EXIT_CODE);
  return $content;
}
sub writeFile  {
  my $self=shift;
  my $raw = shift;
  my $filename = shift;
  my $dir = shift;
    open (PNG, sprintf(">%s/%s",$dir,$filename)) if(defined($dir));
    open (PNG, sprintf(">%s",$filename)) if(!defined($dir));
    print PNG $raw;
    close PNG;
  return 0;
}
sub Download{
  my $this = shift;
  my $symbols = shift;
  croak("end no symbols!!!")  if !defined($symbols);
  $this->Dbg(2,"end no symbols!!!");
  
  
  
  $this->{optical}->set_path(".");
    foreach my $symbol (split(" ",$symbols)) {
        $this->{optical}->callCheck($symbol);
    }
    return $this->{optical};
}
sub createDataDir {
  my $self = shift;
  my $config = $self->{config};
  my $dir = File::Spec->tmpdir();

  my $downfolder = $self->{downfolder};
   
  $self->{today}->{$dir}->{$downfolder} = [@directories];
  

    if( defined $dir ) {
        chdir($dir);
        File::Path::mkpath($current);
        chdir($current);
        File::Path::mkpath($self->{downfolder});
        chdir($downfolder);
        File::Path::mkpath(@directories, {
                 verbose => 1,
                 mode => 0711,
             } );
        chdir($downfolder);
        chdir("download");

  }
}


sub Home {

  my $self = shift;
  my $config = shift;
    $config = $self->{config} unless($config);
    $self->createDataDir();
  my $dir = File::Spec->tmpdir();
  my $date = gmtime;
  my @e = split " ",$date;# =~ s/ /_/g;
  
  if(defined($e[2]) && (length $e[2]) == 1) {
    $e[2] = "0".$e[2];
  }
  
  my $downfolder = "$e[4]-$e[1]-$e[2]";

  $self->{today}->{$dir}->{$downfolder} = [@directories];
  $self->{date} = $date;
    if( defined($dir)) {
        chdir($dir);
        chdir($current);
        File::Path::mkpath($downfolder);
        chdir($downfolder);
          #$self->{NYSE}->{timer}=time;
        my $all =  {};
        chdir($downfolder);
        chdir("download");
        
        $self->Dbg(2,"Starting download");
        
        foreach(keys %{$config->{ibes}}) {
            $self->Dbg(2,"downloading all for ".$_);
            $self->Download($config->{ibes}->{$_});
       }
       $self->Dbg(2,"Done download");
      chdir("..");
   }
   
    
   my @ok = keys %{$self->{optical}->{'result'}};

    $self->Dbg(2,"found strong buys ".join(" ",@ok));   

    my $ff = undef;
    $self->{'result'}->{symbols} = [@ok];
    
  
    $memd->set("master-run-SYMBOLS",\@ok);
    
    $self->Dbg(2,"stored to cache ");   


#   $self->{testthread}->push_in(@ok);
#   @symbols = @{} unless(!$data);


    File::Path::mkpath(("ratings/bottom","ratings/top","ratings/inbetween","ratings/csv"), {
             verbose => 1,
             mode => 0711,
         } );
    


# $self = retrieve('master-run-BACKUP');

#I have 1GB ASSIGNED CONTAINS ALSO THE CSV OF 1 YEAR DATA OF 8000 STOCKS FROM YAHOO
my $memd = new Cache::Memcached {
	'servers' => [ "127.0.0.1:11211"],
	'debug' => 0,
	'compress_threshold' => 10_000,
} or warn($@);

      
      
    $memd->set("master-run-SYMBOLS",\@ok);
    
    
    foreach my $sym (@ok) {
        $self->{'result'}->{$sym}->{'nasdaq-guru'}=[$self->getguruscreener($sym )];
        my @overall =();
      for my $i (reverse 0..$#{$self->{'result'}->{$sym}->{'nasdaq-guru'}}) {
        my $p=$self->{'result'}->{$sym}->{'nasdaq-guru'}[$i]{pct};
        $p =~ s/\%//g;
        push @overall,$p;
      }
       my $image =  $self->get_source_image(sprintf("http://content.nasdaq.com/ibes/%s_Smallcon.jpg",$sym));
                    $self->writeFile($image,sprintf("ibes-strong-buy/%s.jpg",$sym ));
       my ($stocksymbol, $startdate, $enddate, $interval, $agent,$ma, $diff) = ($sym,"1-15-2011",0,"d","Mozilla/4.0",20, 1);
      
       my $q = quotes::get($stocksymbol, $startdate, $enddate, $interval, $agent);
        $self->{'result'}->{$sym}->{'extended'} = chart::extended($stocksymbol, $q, $ma, $diff);
        $self->{'result'}->{$sym}->{'extended'}->{'guru-sum'}=sprintf("%d",mean(@overall));
        $ff = $self->get_source_image(sprintf($self->{config}->{sources}->{'NASDAQ_COMMUNITY'},$sym));
        if($ff =~ /<b>(.*)ratings<\/b>/){
    #      $self->writeFile($1,sprintf( "ratings/%s.html",$sym ));
           $self->{'result'}->{$sym}->{'extended'}->{'nasdaq-userrating'}=$1;
        }
      
                  
        my $out = chart::html($sym, $q, $ma, $diff, $self->{'result'}->{$sym}); 
        
        
        if($out!~/png;base64,["]/){
        
        my $check = chart::diffcheck($sym, $q, $ma, $diff);

        
        if($check==1){
        open OUT,">ratings/bottom/$sym.html";
        print OUT $out;
        close OUT;
        print "done: bottom-$sym.html generated.\n";
        }elsif($check==2){
        open OUT,">ratings/top/$sym.html";
        print OUT $out;
        close OUT;
        print "done: top-$sym.html generated.\n";
        
        }elsif($check==0){
        
        open OUT,">ratings/inbetween/$sym.html";
        print OUT $out;
        close OUT;
        print "done: inbetween-$sym.html generated.\n";
            
        }
        
        }
       
       
       if(0){
       
        
#        $ff = $self->get_source_image(sprintf($self->{config}->{sources}->{'IBES_ICON'},$sym ));
       
#        $ff = $self->get_source_image(sprintf($self->{config}->{sources}->{'YAHOO_CHART'},$sym ));
   #     $self->writeFile($ff,sprintf("charts/%s.png",$sym));
     #   $self->{$dir}->{$downfolder}->{'charts'}->{$sym}= sprintf("%s/%s/%s/charts/%s.png",$dir,$current,$downfolder,$sym);
     
     
           

     
        my $outfile = sprintf("%s/Finance-Quant/%s/backtest/longtrend_backtest_%s.data",$dir,$downfolder,$sym);
      
        my $cmd = sprintf("sh -c 'cat /usr/local/bin/longtrend-003.r | replace \"AAPL\" \"%s\"  | R --vanilla > %s'",$sym,$outfile);
        
        `$cmd`;
        
    #    my $data = `cat $outfile | egrep  "(Txn.*|Net.*|*.PL|2012*)"`;
     #   print "\nProcessing $sym";
        
        
      #  $self->{'result'}->{$sym}->{'extended'}->{backtest} = $data;
        
        
         #$cmd = sprintf("sh -c 'cat /usr/local/bin/longtrend-002.r | replace \"AAPL\" \"%s\" | R --vanilla'",$sym);
        
        #`$cmd`;
        
        
         # chdir("charts");
         # open OUT, ">$sym.html";
          
         #print OUT chart::html($sym, $q, $ma, $diff);   # expecting headers: Date,Open,High,Low,Close,Volume
        #  close OUT;
      }
    }
    chdir("..");

    $memd->set("master-run",$self);

    
#    $self->{testthread}->runner;
#    exit;  
}


sub getguruscreener {
 my $self = shift;
    my $symbol = shift;
    my $temp = undef;
    my $url = sprintf($self->{config}->{sources}->{GURU},$symbol);
    my @ids = qw/guru/;
    my $content =  $self->get_source_image($url);
    my %out = ();
    my %collection = ();
    return unless defined $content;
 my $tree = HTML::TreeBuilder->new;
    $tree->parse($content);
  my @ret = grep {
  if($_ =~ />(.*)</) {
      my $out =$1;
      if(defined($out) && length $out>40){
          $out=~ s/<\/tr>|<\/td>|<\/table>|<td*>|<tr*>|<tr>|<td>|<\/a>/\n/g;
          $out=~/<h2>(.*)<\/h2>(.*)<\/b/;
          my ($methode,$pct) = ($1,$2);
          if(defined($symbol) && defined($pct)){
            $pct =~ s/$symbol gets a <b>//g unless(!$symbol);
          }
          if(defined($methode) &&
            defined($pct) &&
            $methode =~ m/Investor/){
            my @set = split("Investor",$methode);
            $_={'methode'=>$set[0],'pct'=>$pct,"author"=>$set[1]};
          }
      }
  } } split("guru(.*)Detailed Analysis",$content);
  $tree = $tree->delete();
  my @overall =();
for my $i (reverse 0..$#ret) {
  my $p=$ret[$i]{pct};
  $p =~ s/\%//g;
	push @overall,$p;
}
  return @ret;
}
sub symClean {
  my $self = shift;
  my $list = shift;
  my $c = 0;
  open FILE,$list or croak $!;
  my @lines = <FILE>;
    foreach my $line(@lines){
        next if($line =~/File Creation Time|Symbol\|Security Name/);
        $line =~ /(.*?)\|/;
        if(defined($1)){
            push @symbols,$1;#sprintf(",(\"%s\")",$1);
            #print $1,($c % 100 ? "\n":" ");
        }
    }
    my $query = sprintf("%s", join(" ",@symbols));
    return $query;
    #return @symbols;
}
sub do_file_search
{
  my $self = shift;
  my $file = shift;
  if( ! defined $file ){return}
  my @lines = ();
    foreach my $aref( @{$files{$file}} )
    {
           push @lines, $$aref[0];
    }
  $self->{textbuffer}->insert('');
  open (FH,"< $file");
  while(<FH>){
     my $line = $.;
     if($linenums)
     {
       my $lineI = sprintf "%03d", $line;
       $self->{textbuffer}->insert_with_tags_by_name ($self->{textbuffer}->get_end_iter, $lineI, 'rmap');
       $self->{textbuffer}->insert ($self->{textbuffer}->get_end_iter, ' ');
     }
    if( grep {/^$line$/} @lines )
    {
           $self->{textbuffer}->insert_with_tags_by_name ($self->{textbuffer}->get_end_iter, $_, 'rmapZ');
    }
    else
    {
          $self->{textbuffer}->insert_with_tags_by_name ($self->{textbuffer}->get_end_iter, $_, 'bold');
    }
  }
 close FH;
#set up where to scroll to when opening file
 my $first;
 if ( $lines[0] > 0 ){ $first = $lines[0] }else{$first = 1}
#set frame label to file name
$self->{textbuffer}->insert($file);
$current = $file;
}
################################################################
sub do_dir_search
{
 my $self = shift;
my $search_str = shift;
$seeking = 1;
$cancel = 0;
%files = ();
$self->{textbuffer}->append('Search Results');
$self->{textbuffer}->append($search_str);
my $path = '.';
if( ! length $search_str){$seeking = 0; $cancel = 0; return}
my $regex;  #defaults to case insensitive
#if ($case){$regex =  qr/\Q$search_str\E/}
#      else{$regex =  qr/\Q$search_str\E/i} ##< before
if ($case)                                       ##<-------+
{                                                           #
   if ($use_regex)                                          #
   {                                                        #
     $regex =  qr/$search_str/;                             #
   }                                                        #
   else                                                     #
   {                                                        #
       $regex =  qr/\Q$search_str\E/                        #
   }                                                        # patch
}                                                           # (regex)
else                                                        #
{                                                           #
   if ($use_regex)                                          #
   {                                                        #
     $regex =  qr/$search_str/i;                            #
   }                                                        #
   else                                                     #
   {                                                        #
       $regex =  qr/\Q$search_str\E/i;                      #
   }                                                        #
}                                                ##<-------+
#$self->{textbuffer}->append($regex);
# use s modifier for multiline match
my $count = 0;
my $count1 = 0;
find (sub {
      if( $cancel ){ return $File::Find::prune = 1}
      $count1++;
      if( ! $recurse ){
      my $n = ($File::Find::name) =~ tr!/!!; #count slashes in file
      return $File::Find::prune = 1 if ($n > 1);
      }
     return if -d;
     return unless (-f);#and -T);
    if($name){
          if ($_ =~ /$regex/){
	     push @{$files{$File::Find::name}}, [-1,'']; #push into HoA
	  }
     }
    else
    {
         open (FH,"< $_");
            while(<FH>)
            {
               if ($_ =~ /$regex/)
               {
	           chomp $_;
                   push @{$files{$File::Find::name}}, [$., $_]; #push into HoA
     	       }
	     }
	 close FH;
     }
#------
        my $key = $File::Find::name;
        if( defined  $files{$key} )
        {
           $count++;
    	   my $aref = $files{$key};
	   my @larray = @$aref;
            $self->{textbuffer}->append("$key");
         foreach my $aref(@larray)
         {
	    if( $$aref[0] > 0 ) {
        my $lineI = sprintf"%03d", $$aref[0];
        $self->{textbuffer}->append("\n". $lineI);
	     }
	  }
       }
      # $self->{textbuffer}->append("");
 #-----
    }, $dir);
     $self->{textbuffer}->append("$count1 checked -- $count matches .. DONE");
     $seeking = 0;
     $cancel = 0;
    return [$self->{textbuffer}];
}
##############################################################################
sub insert_link
{
  my $self = shift;
  my ($buffer, $file ) = @_;
  #create tag here independently, so we can piggyback unique data
  my $tag = $buffer->create_tag (undef,
				 foreground => "blue",
				 underline => 'single',
				 size   => 20 * 1
				 );
# piggyback data onto each tag
  $tag->{file} = $file;
}
###########################################################################
# Looks at all tags covering the position of iter in the text view,
# and if one of them is a link, follow it by showing the page identified
# by the data attached to it.
#
sub follow_if_link
{
  my $self = shift;
  my ($text_view, $iter) = @_;
      my $tag = $iter->get_tags;
      my $file = $tag->{file};
     if($file)
     {
      $self->do_file_search($file);
      }
}



sub set_path {
    my $this = shift;
    my $arg  = shift;
    croak "need a working directory" if !defined($arg);
    $this->{dir} = $arg;
}



{package quotes;
	use LWP::UserAgent;
	
	sub get {
		my ($symbol, $startdate, $enddate, $agent) = @_;
		print "fetching data...\n";
		my $dat = _fetch($symbol, $startdate, $enddate, $agent);   # csv file, 1st row = header
		my @q = split /\n/, $dat;
		my @header = split /,/, shift @q;
		my %quotes = map { $_ => [] } @header;
		for my $q (@q) {
			my @val = split ',', $q;
			unshift @{$quotes{$header[$_]}}, $val[$_] for 0..$#val;   # unshift instead of push if data listed latest 1st & oldest last
		}
		open OUT, ">ratings/csv/$symbol.csv";
		print OUT $dat;
		close OUT;
		print "data written to ratings/csv/$symbol.csv.\n";
		return \%quotes;
	}
	sub _fetch {
		my ($symbol, $startdate, $enddate, $interval, $agent) = @_;
		my $url = "http://chart.yahoo.com/table.csv?";
		my $freq = "g=$interval";    # d: daily, w: weekly, m: monthly
		my $stock = "s=$symbol";
		my @start = split '-', $startdate;
		my @end = split '-', $enddate;
		$startdate = "a=" . ($start[0]-1) . "&b=$start[1]&c=$start[2]";
		$enddate = "d=" . ($end[0]-1) . "&e=$end[1]&f=$end[2]";
		$url .= "$startdate&$enddate&$stock&y=0&$freq&ignore=.csv";
		my $ua = new LWP::UserAgent(agent=>$agent);
		my $request = new HTTP::Request('GET',$url);
		my $response = $ua->request($request);
		if ($response->is_success) {
			return $response->content;
		} else {
			warn "Cannot fetch $url (status ", $response->code, " ", $response->message, ")\n";
		  	return 0;
		}
	}
}

{package chart;
	use GD::Graph::lines;
	use Statistics::Basic qw(mean);
  use MIME::Base64;
  use Data::Dumper;
	# my @headers = qw/ Date Open High Low Close Volume /; hardcoded in _tbl()
	# $q->{Close} assumed exists in plotlog() & plotdiff()
	sub html {
		my ($stock, $q, $ma, $diff,$extended) = @_;
		my $str = "";
		my $list = "";


    my @guru =  @{$extended->{'nasdaq-guru'}};
    my @ext = keys %{$extended->{extended}};
		my @values = values %{$extended->{extended}};
    my $xguru ="<h3>Factors</h3><ul>";
    if(defined($ext[0]))   {
						my $iu=0;
#						@ext =@ext[0];
						foreach my $egu (@ext){
								$xguru .= sprintf("<li>%s %s</li>",$egu,$extended->{extended}->{$egu});
								$iu++;
						}
    }
    $xguru .="</ul><h3>check:gurus nasdaq</h3><ul>";
		foreach my $gu (@guru){
		    $xguru .= sprintf("<li>raiting:[%s]\t\t%s</li>",$gu->{pct},$gu->{methode});
		}
		#	}
					$str = "<html><head><title>$stock</title></head>".
									"<body bgcolor=\"#00000\" text=\"ffffff\">".
									"<div style='float:left;padding:20;'>".$xguru."</div>".
									"<div style='float:right;'>\n";

		$str .= "<p><img src=\"data:image/png;base64," . plotlog($stock, $q, $ma) . "\">\n<br />";
		$str .= "<img src=\"data:image/png;base64," . plotdiff($stock, $q, $ma, $diff) . "\"></p>\n";
		#$str .=  _tbl($stock, $q);
		$str .= "</div></body></html>\n";


		$str .=  _tbl($stock, $q);
		$str .= "</center></body></html>\n";
		return $str;
	}
	
	sub plotlog {
		my ($stock, $q, $diff) = @_;
		my $img = $stock . "log.jpg";
		print "generating $img...\n";
		my ($s, $lines) = ([],[]);
		my $y_format = sub { sprintf " \$%.2f", exp $_[0] };
		
		$s = ts::logs($q->{Close});
		$lines->[0] = {	name => 'Log of Closing Price', color => 'marine', data => $s };
		$lines->[1] = {	name => "MA($diff) (Moving Avg)", color => 'cyan', data => ts::ma($lines->[0]->{data}, $diff) };
		
		return plotlines($img, $stock, $q->{Date}, $lines, $y_format);
		
	}

	sub plotdiff {
		my ($stock, $q, $lag, $diff) = @_;
		my $img = $stock . "diff.jpg";
		print "generating $img...\n";
		my ($s, $lines) = ([],[]);
		my $y_format = sub { sprintf "  %.2f", $_[0] };

		$s = ts::logs($q->{Close});
		$lines->[0] = {	name => "Diff($diff)", color => 'marine', data => ts::diff($s, $diff) };
		$lines->[1] = {	name => "MA($lag) (Moving Avg)", color => 'cyan', data => ts::ma($lines->[0]->{data}, $lag) };
		$s = ts::stdev($lines->[0]->{data}, $lag);
		$s = ts::nstdev_ma($s, $lines->[1]->{data}, 2);
		$lines->[2] = {	name => 'MA + 2 Std Dev', color => 'lred', data => $s->[0] };
		$lines->[3] = {	name => 'MA - 2 Std Dev', color => 'lred', data => $s->[1] };
		
		return plotlines($img, $stock, $q->{Date}, $lines, $y_format);

	}
	
	sub plotlines {
		my ($file, $stock, $x, $lines, $y_format) = @_;
		my @legend;
		my ($data, $colors) = ([], []);
		
		$data->[0] = $x;   # x-axis labels
	
		for (0..$#{$lines}) {
			$data->[(1+$_)] = $lines->[$_]->{data};
			$colors->[$_] = $lines->[$_]->{color};
			$legend[$_] = $lines->[$_]->{name};
		}
	
		my $graph = GD::Graph::lines->new(740,420);
		$graph->set (dclrs => $colors) or warn $graph->error;
		$graph->set_legend(@legend) or warn $graph->error;
		$graph->set (legend_placement => 'BC') or warn $graph->error;
		$graph->set(y_number_format => $y_format) if $y_format;
		$graph->set (
			title => "stock: $stock",
			boxclr => 'black',
			bgclr => 'dgray',
			axislabelclr => 'white',
			legendclr => 'white',
			textclr => 'white',
			r_margin => 20,
			tick_length => -4,
			y_long_ticks => 1,
			axis_space => 10,
			x_labels_vertical => 1,
			x_label_skip => int(0.2*scalar(@{$data->[0]}))
		) or warn $graph->error;	
		my $gd = $graph->plot($data) or warn $graph->error;

	  if(defined($gd)){
      my $png = $gd->png();	    
	    return  encode_base64($png);   
	     
	  }else{
	  
	    return  ""; 
	  
	  }
	  
	  
   

	}
	
	
				sub meanx {
		my ($stock, $q, $lag, $diff) = @_;
		my $img = $stock . "diff.jpg";
		my ($s, $lines) = ([],[]);
		my $y_format = sub { sprintf "  %.2f", $_[0] };
		$s = ts::logs($q->{Close});
		my $diffx = ts::diff($s, $diff);
		$lines->[0] = {	name => "Diff($diff)", color => 'marine', data => $diffx };
		$lines->[1] = {	name => "MA($lag) (Moving Avg)", color => 'cyan', data => ts::ma($lines->[0]->{data}, $lag) };
		$s = ts::stdev($lines->[0]->{data}, $lag);
		$s = ts::nstdev_ma($s, $lines->[1]->{data}, 2);
		$lines->[2] = {	name => 'MA + 2 Std Dev', color => 'lred', data => $s->[0] };
		$lines->[3] = {	name => 'MA - 2 Std Dev', color => 'lred', data => $s->[1] };
		my(@ty,@tx,@tu);
		@ty =  @{$lines->[0]->{data}};
		#my $mean   = sprintf("%3.3f",); # array refs are ok too
		return  [$#ty,mean(@ty)];
	}



	sub extended{
			my ($stocksymbol, $q, $lag, $diff) = @_;
my  @meanx = meanx($stocksymbol, $q, $lag, $diff);
my $check = diffcheck($stocksymbol, $q, $lag, $diff);
my @hl = checkHL($stocksymbol,$q);
my $output= {"position"=>($check==0?"middle":($check==1?"bottom":"top")),
				"days"=>$meanx[0][0],
				"momentum"=>sprintf("%3.8f",$meanx[0][1]),
				"avg-day-range-pct"=>$hl[0][0],
				"avg-vol"=>$hl[0][1]};
				return $output;
		}
		sub diffcheck {
		my ($stock, $q, $lag, $diff) = @_;
		my $img = $stock . "diff.jpg";
		my ($s, $lines) = ([],[]);
		my $y_format = sub { sprintf "  %.2f", $_[0] };
		$s = ts::logs($q->{Close});
		my $diffx = ts::diff($s, $diff);
		$lines->[0] = {	name => "Diff($diff)", color => 'marine', data => $diffx };
		$lines->[1] = {	name => "MA($lag) (Moving Avg)", color => 'cyan', data => ts::ma($lines->[0]->{data}, $lag) };
		$s = ts::stdev($lines->[0]->{data}, $lag);
		$s = ts::nstdev_ma($s, $lines->[1]->{data}, 2);
		$lines->[2] = {	name => 'MA + 2 Std Dev', color => 'lred', data => $s->[0] };
		$lines->[3] = {	name => 'MA - 2 Std Dev', color => 'lred', data => $s->[1] };
		my(@ty,@tx,@tu);
		@ty =  @{$lines->[0]->{data}};
		if($#ty<100)
		{ return -1; }
		@tx = @{$s->[1]};
		@tu = @{$s->[0]};
		my $mean   = mean(@ty); # array refs are ok too
		if($ty[$#ty] < $tx[$#tx]) {
						return 1;
		}
		if($ty[$#ty] >= $tu[$#tx]) {
								return 2;
		}
		return 0;
	}
	sub checkHL {
		my ($stock, $q) = @_;
		my $str = "";
		my @VOL=();
		my @HL=();
		my @headers = qw/ Date Open High Low Close Volume /;
		for my $i (reverse 0..$#{$q->{Date}}) {
				push @VOL, $q->{'Volume'}->[$i];
				push @HL, ($q->{'High'}->[$i]-$q->{'Low'}->[$i]) /($q->{'Close'}->[$i]/100) unless(!$q->{'High'}->[$i] or !$q->{'Low'}->[$i]);
		}
		return [sprintf("%s",mean(@HL)),sprintf("%d",mean(@VOL))];
	}
	
	sub _tbl {
		my ($stock, $q) = @_;
		my $str = "";
		my @headers = qw/ Date Open High Low Close Volume /;
		my $tr_start = "<tr align=\"center\">\n";
		$str .= "<table border=\"1\" cellpadding=\"3\" cellspacing=\"0\">\n";
		$str .= $tr_start . "<td colspan=\"" . scalar @headers . "\">";
		$str .= "<b>Stock: $stock</b></td></tr>\n";
		$str .= $tr_start;
		$str .= "<td><b>" . $headers[$_] . "</b></td>\n" for 0..$#headers;
		$str .= "</tr>\n";
		for my $i (reverse 0..$#{$q->{Date}}) {
			$str .= $tr_start;
			$str .= "<td>" . $q->{$headers[$_]}->[$i] . "</td>\n" for 0..$#headers;
			$str .= "</tr>\n";
		}
		$str .= "</table>\n";
		return $str;
	}	
}
{package ts;
	sub logs {
		my $s = shift;
		return [ map {log} @{$s}[0..$#{$s}] ];
	}
	
	sub diff {
		my ($series, $lag) = @_;
		my @diff = map {undef} 1..$lag;
		push @diff, $series->[$_] - $series->[$_-$lag] for ( $lag..$#{$series} );
		return \@diff;
	}
	
	sub ma {
		my ($series, $lag) = @_;
		my @ma = map {undef} 1..$lag;
		for(@{$series}){unless($_){push @ma,undef}else{last}}
		my $sum = 0;
		for my $i ($#ma..$#{$series}) {
			$sum += $series->[$i-$_] for (0..($lag-1));
			push @ma, $sum/($lag);
			$sum = 0;
		}
		return \@ma;
	}
	
	sub stdev {
		my ($series, $lag) = @_;
		my @stdev = map {undef} 1..$lag;
		for(@{$series}){unless($_){push @stdev,undef}else{last}}
		my ($sum, $sum2) = (0, 0);
		for my $i ($#stdev..$#{$series}) {
			for (0..($lag-1)) {
				$sum2 += ($series->[$i-$_])**2;
				$sum += $series->[$i-$_] ;
			}
			push @stdev, ($sum2/$lag - ($sum/$lag)**2)**0.5;
			($sum, $sum2) = (0, 0);
		}
		return \@stdev;
	}

	sub nstdev_ma{
		my ($sd, $ma, $n) = @_;
		my $ans=[[],[]]; 
		for (0..$#{$sd}) {
			my $yn = defined $sd->[$_] && defined $ma->[$_];
			$ans->[0][$_] = $yn ? $ma->[$_] + $n*($sd->[$_]) : undef;
			$ans->[1][$_] = $yn ? $ma->[$_] - $n*($sd->[$_]) : undef;			
		}
		return $ans;
	}
}





1;

=head1 NAME

  Finance::Quant - Generic envirorment for Qunatitative Analysis in finance

=head1 DESCRIPTION

  First:  We analysing for all symbols in Finance::Quant::Symbols and fresch NASDAQ symbolsname
          the recommendations released by Institutional Brokers Estimate System IBES
  Second: process the StrongBuy contracts with R long strategy
  Last:   Publishing the results into Cache and Disc
    
  
=head1 SYNOPSIS

  use strict;
  use warnings;
  use Data::Dumper;
  use Finance::Quant;
  use Time::HiRes qw(usleep);
    # GETS ONE
    my ($symbol,$self,$recommended,$home) = ('GOOG',undef,undef,undef,{});
    #single custom symbol
    $self = Finance::Quant->new($symbol);
    $home = $self->Home($self->{config});
    #search data
    my $textbuffer = $self->do_dir_search($symbol);
    print Dumper [$symbol,$self,$home,$textbuffer];

    # GETS ALL
    my $self = Finance::Quant->recommended;
    print Dumper [$self->{config}];
    my $home = $self->Home($self->{config});
    print Dumper [$self->{config}];
    print Dumper [$self,$home];
    
=head1 AUTHOR

Hagen Geissler <santex@cpan.org>


=head1 COPYRIGHT AND LICENCE

Copyright (C) 2012 by Hagen Geissler

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.

=head1 SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Finance::Quant

You can also look for information at:

    Documentation
        http://html5stockbot.com/data/documentation/ibes.html
        http://ibes-check.blogspot.com/
        http://html5stockbotdotcom.blogspot.com/view/flipcard

    Search CPAN
        http://search.cpan.org/dist/Finance::Quant/


=head1 SEE ALSO

  YOU NEED
  ~~~~~~~~
  
  PERL
  ----
  Finance::Quant;
  Finance::Google::Sector::Mean;
  Finance::NASDAQ::Markets;
  Finance::Quant::Symbols;
  GD                   
  Test::More        
  Carp
  Text::Reform    
  Data::Dumper			
  File::Spec::Functions		
  File::Path			
  Time::Local			
  File::Fetch			
  File::Copy			
  File::Find			
  Finance::Optical::StrongBuy	
  Finance::Google::Sector::Mean	
  Finance::NASDAQ::Markets	
  HTML::TreeBuilder		
  Text::Buffer			
  WWW::Mechanize
  GraphViz
  List::Util
  MIME::Base64
  GD::Graph::lines
  Statistics::Basic
  Thread::Queue
  Cache::Memcached
  LWP::UserAgent
  

  UNIX
  ----
  >GD
  >mysql
  >memcached  
   
  R
  - 
  >require(quantmod)
  >require(TTR)
  >require(blotter)
  >require(quantmod)
  >require(quantstrat)
  >require(PerformanceAnalytics)


__DATA__

