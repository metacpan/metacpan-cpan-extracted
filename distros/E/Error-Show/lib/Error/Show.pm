package Error::Show;

use 5.024000;
use strict;
use warnings;
use feature "say";
use Carp;
use POSIX;  #For _exit;
use IPC::Open3;
use Symbol 'gensym'; # vivify a separate handle for STDERR
use Scalar::Util qw<blessed>;

#use Exporter qw<import>;
use base "Exporter";


our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} });

our @EXPORT = qw();


our $VERSION = 'v0.2.1';
use constant DEBUG=>undef;
use enum ("PACKAGE=0",qw<FILENAME LINE SUBROUTINE 
  HASARGS WANTARRAY EVALTEXT IS_REQUIRE HINTS BITMASK 
  HINT_HASH MESSAGE SEQUENCE CODE_LINES>);


################################
# my $buffer="";               #
# open THITHER  ,">",\$buffer; #
################################

#
# A list of top level file paths or scalar refs to check for syntax errors
#
my @IINC;
sub context;

 
sub import {
  my $package=shift;
  my @caller=caller;
  my @options=@_;


  # We don't export anything. Return when we are used withing code
  # Continue if caller has no line number, meaning from the CLI
  #
  return if($caller[LINE]);

  # 
  # CLI Options include 
  #
  my %options;

  my $clean=grep /clean/i, @options;
  my $splain=grep /splain/i, @options;
  my $do_warn=grep /warn/i, @options;

  my @warn=$do_warn?():"-MError::Show::Internal";


  #
  # 1. Command line argument activation ie -MError::Show
  #
  # Find out any extra lib paths used. To do this we:
  #
  # a. fork/exec a new perl process using the value of $^X. 
  # b. The new process dumps the @INC array to STDOUT
  # c. This process reads the output and stores in @IINC
  #
  # Only run it the first time its used
  # Is this the best way? Not sure. At least this way there is no argument
  # processing, perl process does it for us.
  #
  
  @IINC=map {chomp; $_} do {
    open my $fh, "-|", $^X . q| -E 'map print("$_\n"), @INC'| or die "$!";
    <$fh>;
  } unless @IINC;

  #
  # 2. Extract the extra include paths
  #
  # Built up the 'extra' array of any include paths not already listed 
  # from the STDOUT dumping above
  #
  my @extra=map  {("-I", $_)} grep {my $i=$_; !grep { $i eq $_} @IINC} @INC;



  # 
  # 3. Syntax checking the program
  #
  # Now we have the include paths sorted,
  # a. fork/exec again, this time with the -c switch for perl to check syntax
  # b. slurp STDERR from child process
  # c. execute the context routine to parse and show more source code context
  # d. print!
  # The proc

  local $/=undef;
  my $file=$0;

  #push @file, @ARGV;

  #my $runnable=not $^C;#$options{check};
  #for my $file(@file){
  die "Error::Show cannot process STDIN, -e and -E programs" if $file eq "-e" or $file eq "-E" or $file eq "-";
  die "Error::Show cannot access \"$file\"" unless -f $file;
  my @cmd= ($^X ,@warn, @extra, "-c",  $file);

    my $pid;
    my $result;
    eval {
      $pid=open3(my $chld_in, my $chld_out, my $chld_err = gensym, @cmd);
      $result=<$chld_err>;
      close $chld_in;
      close $chld_out;
      close $chld_err;
      wait;
    };
    if(!$pid and $@){
      die "Error::Show failed to syntax check";
    }


  # 
  # 4. Status code from child indicates success
  # When 0 this means syntax was ok. Otherwise error
  # Attempt to propogate code to exit status
  #
  my $code=$?>255? (0xFF & ~$?): $?;

  my $runnable=$?==0;
  #say "SYNTAX RUNNABLE: $runnable";

  my $status=context(splain=>$splain, clean=>$clean, error=>$result )."\n";

  if($^C){
    if($runnable){
      #only print status if we want warnings
      print STDERR $do_warn?$status: "$file syntax OK\n";

    }
    else{
      #Not runnable, thus  syntax error. Always print
      print STDERR $status;

    }
    POSIX::_exit $code;

  }
  else{
    #not checking, we want to run
    if($runnable){
      # don't bother with warnings

    }
    else{
      #Not runnable, thus  syntax error. Always print
      print STDERR $status;
      POSIX::_exit $code;
    }
  }
}


sub process_string_error{
  my $error=pop;
  my %opts=@_;

	my @error_lines;
  my @errors; 
  #my @entry;
  my %entry;
	if(defined $error){
    #local $_=$error;
		#Substitue with a line number relative to the start marker
		#Reported line numbers are 1 based, stored lines are 0 based
    #my $translation=$opts{translation};
    #my $start=$opts{start};
  
    my $i=0;
		for(split "\n", $error){
      DEBUG and say STDERR "ERROR LINE: ".$_;
      if(/at (.*?) line (\d+)/
        or /Missing right curly or square bracket at (.*?) (\d+) at end of line/){
        #
        # Group by file names
        #
        DEBUG and say STDERR "PROCESSING: ".$_;
        DEBUG and say STDERR "file: $1 and line $2";
        my $entry=$entry{$1}//=[];
        #push @$entry, {file=>$1, line=>$2,message=>$_, sequence=>$i++};
        my $a=[];
        $a->[FILENAME]=$1;
        $a->[LINE]=$2-1;
        $a->[MESSAGE]=$_;
        $a->[MESSAGE]=$opts{message} if $opts{message};
        $a->[SEQUENCE]=$i++;
        $a->[EVALTEXT]=$opts{program} if $opts{program};
        push @$entry, $a;
      }
    }

    
	}
	else {
		#Assume a target line
    #push @error_lines, $opts{line}-1;
	}

  #Key is file name
  # value is a hash of filename,line number, perl error string and the sequence number

  \%entry;

}

# Takes a hash ref error sources

sub text_output {
  my $info_ref=pop;
  my %opts=@_;
  my $total="";

  DEBUG and say STDERR "Reverse flag in text output set to: $opts{reverse}";

  # Sort by sequence number 
  # Errors are stored by filename internally. Sort by sequence number.
  #

  my @sorted_info= 
    sort {$a->[SEQUENCE] <=> $b->[SEQUENCE] } 
    map {  $_->@* } values %$info_ref;

  # Reverse the order if we want the first error listed last
  #
  @sorted_info=reverse (@sorted_info) if $opts{reverse};

  # Process each of the errors in sequence
  my $counter=0;
  my $limit=$opts{limit}//100;
  for my $info (@sorted_info){
    last if $counter>=$limit and $limit >0;
    $counter++;
    unless(exists $info->[CODE_LINES]){
      my @code;
      
      if($info->[EVALTEXT]){
        @code=split "\n", $info->[EVALTEXT];
      }
      else {
        @code=split "\n", do {
          open my $fh, "<", $info->[FILENAME] or warn "Could not open file for reading: $info->[FILENAME]";
          local $/=undef;
          <$fh>;
        };
      }
      $info->[CODE_LINES]=\@code;
    }

    # At this point we have lines of code in an array
    #
    
    #Find start mark and end mark
    #
    my $start_line=0;
    if($opts{start_mark}){
      my $counter=0;
      my $start_mark=$opts{start_mark};
        for($info->[CODE_LINES]->@*){
          if(/$start_mark/){
            $start_line+=$counter+1;
            last;
          }
          $counter++;
        }
        # Don't include the start marker in the results
    }

    my $end_line=$info->[CODE_LINES]->@*-1;

    if($opts{end_mark}){
        my $counter=0;
        my $end_mark=$opts{end_mark};
        for (reverse($info->[CODE_LINES]->@*)){
          if(/$end_mark/){
            $end_line-=$counter;
            last;
          }
          $counter++;
        }
    }

    $start_line+=$opts{start_offset} if $opts{start_offset};
    $end_line-=$opts{end_offset } if $opts{end_offset};

    # preclamp the error line to within this range so that 'Unmatched ' errors
    # at least show ssomething.
    #
    $info->[LINE]=$end_line if $info->[LINE]>$end_line;

    DEBUG and say "START LINE after offset: $start_line";
    DEBUG and say "END LINE after offset: $end_line";
    # At this point the file min and max lines we should consider are
    # start_line and end line  inclusive. The $start_line is also used as an
    # offset to shift error sources
    #

    my $min=$info->[LINE]-$opts{pre_lines};
    my $max=$info->[LINE]+$opts{post_lines};

    my $target= $info->[LINE];#-$start_line;
    DEBUG and say "TARGET: $target";

    $min=$min<$start_line ? $start_line: $min;

    $max=$max>$end_line?$end_line:$max;

    #
    # format counter on the largest number to be expected
    #
    my $f_len=length("$max");

    my $out="$opts{indent}$info->[FILENAME]\n";
    
    my $indent=$opts{indent}//"";
    my $format="$indent%${f_len}d% 2s %s\n";
    my $mark="";

    #Change min and max to one based index
    #$min++;
    #$max--;
    DEBUG and say STDERR "min before print $min";
    DEBUG and say STDERR "max before print $max";
    for my $l($min..$max){
      $mark="";

      my $a=$l-$start_line+1;

      #Perl line number is 1 based
      $mark="=>" if $l==$target;


      # Print lines as per the index in file array
      $out.=sprintf $format, $a, $mark, $info->[CODE_LINES][$l];
    }

    $total.=$out;
    
    # Modifiy the message now with updated line numbers
    # TODO: Tidy this up
    $info->[MESSAGE]=~s/line (\d+)(?:\.|,)/(($1-1)>$max?$max:$1-1)-$start_line+1/e;

    $total.=$info->[MESSAGE]."\n" unless $opts{clean};

  }
  if($opts{splain}){
    $total=splain($total);
  }
  $total;
}


#Take an error string and attempt to contextualize it
#	context options_pairs, error string	
sub _context{
	#use feature ":all";
	DEBUG and say STDERR "IN context call";
  #my ($package, $file, $caller_line)=caller;
	# 
  # Error is set by single argument, key/value pair, or if no
  # argument $@ is used
  #
	my %opts=@_;

  my $error= $opts{error};




  #$opts{start_mark};#//=qr|.*|;	#regex which matches the start of the code 
	$opts{pre_lines}//=5;		  #Number of lines to show before target line
	$opts{post_lines}//=5;		#Number of lines to show after target line
	$opts{start_offset}//=0;	#Offset past start mark to consider as min line
	$opts{end_offset}//=0;		#Offset before end to consider as max line
	$opts{translation}//=0;		#A static value added to the line numbering
	$opts{indent}//="";
	$opts{file}//="";

  # Get the all the info we need to process
  my $info_ref;
  if(defined($error) and ref($error) eq ""){
    #A string error. A normal string die/warn or compile time errors/warnings
    $info_ref=process_string_error %opts, $error;
    #say "infor ref ".join ", ", $info_ref;
  }
  else{
    #Some kind of object, converted into line and file hash
    $info_ref= {$error->[FILENAME]=>[$error]};#  {$error->{file}=>[$error]};
    $error->[MESSAGE]=$opts{message}//""; #Store the message
    $error->[EVALTEXT]=$opts{program} if $opts{program};
  }
  
  # Override text/file to search
  my $output;
  $output=text_output %opts, $info_ref;
  
  #TODO:
  #
	$output;
  
}


#
# Front end to the main processing sub. Configures and checks the inputs
#
my $msg= "Trace must be a ref to array of  {file=>.., line=>..} pairs";
sub context{
  my %opts;
  my $out;
  if(@_==0){
    $opts{error}=$@;
  }
  elsif(@_==1){
    $opts{error}=shift;
  }
  else {
    %opts=@_;
  }

  if($opts{frames}){
    $opts{error}=delete $opts{frames};
  }
  
  # Convert from supported exceptions classes to internal format

  my $ref=ref $opts{error};
  my $dstf="Devel::StackTrace::Frame";

  if((blessed($opts{error})//"") eq $dstf){
    # Single DSTF stack frame. Convert to an array
    $opts{error}=[$opts{error}];
  }
  elsif($ref eq "ARRAY" and ref($opts{error}[0]) eq ""){
    # Array of scalars  - a normal stack frame - wrap it
    $opts{error}=[[$opts{error}->@*]];
  }
  elsif($ref eq ""){
    # Not a reference - A string error 
  }
  elsif($ref eq "ARRAY" and ref($opts{error}[0]) eq "ARRAY"){
    # Array of  arrays of scalars
    $opts{error}=[map { [$_->@*] } $opts{error}->@* ];
    
  }
  elsif($ref eq "ARRAY" and blessed($opts{error}[0]) eq $dstf){
    #Array of DSTF object
  }
  else {
    # Force stringification of error as a last ditch attempt
    $opts{error}="$opts{error}";
  }
  
  DEBUG and say STDERR "Reverse flag set to: $opts{reverse}";

  # Reverse the ordering of errors here if requested
  #
  $opts{error}->@*=reverse $opts{error}->@* if $opts{reverse};
  # Check for trace kv pair. If this is present. We ignore the error
  #
  if(ref($opts{error}) eq "ARRAY" and ref $opts{error}[0]){
    # Iterate through the list
    my $_indent=$opts{indent}//="    ";
    my $current_indent="";

    my %_opts=%opts;
    my $i=0;  #Sequence number
    for my $e ($opts{error}->@*) {

      if((blessed($e)//"") eq "Devel::StackTrace::Frame"){
        #Convert to an array
        my @a;
        $a[PACKAGE]=$e->package;
        $a[FILENAME]=$e->filename;
        $a[LINE]=$e->line;
        $a[SUBROUTINE]=$e->subroutine;
        $a[HASARGS]=$e->hasargs;
        $a[WANTARRAY]=$e->wantarray;
        $a[EVALTEXT]=$e->evaltext;
        $a[IS_REQUIRE]=$e->is_require;
        $a[HINTS]=$e->hints;
        $a[BITMASK]=$e->bitmask;
        $a[HINT_HASH]=$e->hints;
        $e=\@a;
      }


      if($e->[FILENAME] and $e->[LINE]){
        $e->[MESSAGE]//="";

        #Force a message if one is provided
        $e->[LINE]--; #Make the error 0 based
        $e->[MESSAGE]=$opts{message} if $opts{message};
        $e->[SEQUENCE]=$i++;
        
        # Generate the context here
        #
        $_opts{indent}=$current_indent;
        $_opts{error}=$e;
        $out.=_context %_opts;
        $current_indent.=$_indent;
      }
      else{
        die $msg;
      }
    }

  }
  else {
    #say "NOT AN ARRAY: ". join ", ", %opts;

    $out=_context %opts;
  }
  $out;
}

my ($chld_in, $chld_out, $chld_err);
my @cmd="splain";
my $pid;
sub splain {
  my $out;
  #Attempt to open splain process if it isn't already
  unless($pid){
    eval{
      $pid= open3($chld_in, $chld_out, $chld_err = gensym, @cmd);
      #$chld_in->autoflush(1);

    };
    if(!$pid and $@){
      warn "Error::Show Could not splain the results";
    }
  };

  #Attempt to write to the process and read from it
  eval {
    print $chld_in $_[0], "\n";;
    close $chld_in;
    $out=<$chld_out>;
    close $chld_out;
    close $chld_err;
  };

  if($@){
    $pid=undef;
    close $chld_in;
    close $chld_out;
    close $chld_err;
    warn "Error::Show Could not splain the results";
  }
  $out;
}

#sub wrap_eval{
#  my $program=shift;
#  "sub { $program }";
#}

1;
__END__
