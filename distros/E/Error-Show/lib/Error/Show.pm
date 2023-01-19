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


our $VERSION = 'v0.1.0';
use constant DEBUG=>0;
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


our %exception_adaptors;
$exception_adaptors{"Exception::Base"}=sub {

};

$exception_adaptors{"Exception::Class::Base"}=sub {
  #take an error
  my $e=shift;
};


sub process_ref_errror{
  #
  # This can only be a (single) runtime error
  #
  my $error=pop;
  my %opts=@_;
  my $ref=ref $error;


  my %entry;

  # 
  # TODO: 
  # Lookup handler code to process this type of error
  # 

  \%entry;

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
      if(/at (.*?) line (\d+)/){
        #
        # Group by file names
        #
        my $entry=$entry{$1}//=[];
        #push @$entry, {file=>$1, line=>$2,message=>$_, sequence=>$i++};
        my $a=[];
        $a->[FILENAME]=$1;
        $a->[LINE]=$2;
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

sub text_output {
  my $info_ref=pop;
  my %opts=@_;
  my $total="";

  # Sort by sequence number 
  # Errors are stored by filename internally. Sort by sequence number.
  #
  my @sorted_info= 
    sort { $a->[SEQUENCE] <=> $b->[SEQUENCE] } 
    map { $_->@* } values %$info_ref;

  # Process each of the errors in sequence
  for my $info (@sorted_info){
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

    my $min=$info->[LINE]-$opts{pre_lines};
    my $max=$info->[LINE]+$opts{post_lines};

    my $target= $info->[LINE];

    $min=$min<0 ? 0: $min;
    my $count=$info->[CODE_LINES]->@*;
    $max=$max>=$count?$count:$max;

    #
    # format counter on the largest number to be expected
    #
    my $f_len=length("$max");

    my $out="$opts{indent}$info->[FILENAME]\n";
    
    my $indent=$opts{indent}//"";
    my $format="$indent%${f_len}d% 2s %s\n";
    my $mark="";

    #Change min and max to one based index
    $min++;
    #$max--;

    for my $l($min..$max){
      $mark="";

      #Perl line number is 1 based
      $mark="=>" if $l==$info->[LINE];

      #However our code lines are stored in a 0 based array
      $out.=sprintf $format, $l, $mark, $info->[CODE_LINES][$l-1];
    }
    $total.=$out;
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




	$opts{start_mark}//=qr|.*|;	#regex which matches the start of the code 
	$opts{pre_lines}//=5;		#Number of lines to show before target line
	$opts{post_lines}//=5;		#Number of lines to show after target line
	$opts{offset_start}//=0;	#Offset past start to consider as min line
	$opts{offset_end}//=0;		#Offset before end to consider as max line
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
# This only works with errors objects which captured a trace as a Devel::StackTrace object
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
    $opts{error}=[$opts{error}];
  }
  elsif($ref eq ""){
    # Not a reference - A string error 
  }
  elsif($ref eq "ARRAY" and ref($opts{error}[0]) eq "ARRAY"){
    # Array of  arrays of scalars
    
  }
  elsif($ref eq "ARRAY" and blessed($opts{error}[0]) eq $dstf){
    #Array of DSTF object
  }
  else {
    #warn "Expecting a string, caller() type array or a $dstf object, or arrays of these";
    $opts{error}="$opts{error}";
  }
  


  #Check for trace kv pair. If this is present. We ignore the error
  if(ref($opts{error}) eq "ARRAY" and ref $opts{error}[0]){
    # Iterate through the list
    my $_indent=$opts{indent}//="    ";
    my $current_indent="";

    my %_opts=%opts;
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
        $e->[MESSAGE]=$opts{message} if $opts{message};
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

sub wrap_eval{
  my $program=shift;
  "sub { $program }";
}
1;
__END__
