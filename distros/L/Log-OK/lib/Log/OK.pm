package Log::OK;

use strict;
use warnings;
use version; our $VERSION=version->declare("v0.2.0");

use Carp qw<croak carp>;
use constant::more ();

use constant::more DEBUG_=>0;

use feature qw"say state";

my %systems=(
	"Log::Any"=>\&log_any,
	"Log::ger"=>\&log_ger,
	"Log::Log4perl"=>\&log_log4perl,
	"Log::Dispatch"=>\&log_dispatch
);


my $sub;
#use constant::more();
sub import {
	#arguments are lvl , opt, env, cat in hash ref
	my $p=shift;
	my $hr=shift;

	#return unless $hr;
	$hr={} unless $hr;

	my $caller=caller;
	
	if($hr->{sys}){
		#manual selection of logging system
		$sub=$systems{$hr->{sys}};
		croak "Unsupported logging system" unless $sub;
	}
	else{
		#attempt to auto detect the logging system
		$sub=auto_detect();
	}
	constant::more->import({
			logging=>{
				val=>$hr->{lvl},

        # Changed in v0.2.0
        # If the opt field is DOES NOT EXIST, we assume user wants to use
        # default of  "verbose" if opt field DOES EXIST, we use the user
        # supplied value. If if is undef, we do not process any command line
        # options.
				opt=>exists($hr->{opt})      
          ?$hr->{opt}
            ?$hr->{opt}.":s" 
            :undef 
          :"verbose:s",

				env=>$hr->{env},
				sys=>$hr->{sys},
				sub=>$sub,
			}
	});
};

sub auto_detect {
	#check for Log::Any first
	(%Log::Any:: )and return \&log_any;
	(%Log::ger::) and return \&log_ger;
	(%Log::Dispatch::) and return \&log_dispatch;
	(%Log::Log4perl::) and return \&log_log4perl;

	#otherwise fallback to log any
	#\&log_dispatch;
	\&no_logger;
}

sub log_any {
        DEBUG_ and say STDERR "setup for Log::Any";
        my ($opt, $value)=@_;
        state $lookup= {

        EMERGENCY => 0,
        ALERT     => 1,
        CRITICAL  => 2,
        ERROR     => 3,
	ERR	  => 3,
        WARNING   => 4,
        WARN      => 4,
        NOTICE    => 5,
        INFO      => 6,
        INFORM    => 6,
        DEBUG     => 7,
        TRACE     => 8,
	};
	state $level=0;	
	$value//="EMERGENCY"; #Default if undefined
	$value=1 if $value eq "" or $value eq 0;
	for(uc($value)){
		#test numeric. Should only be used for incremental 
		if(/\d/){
			#assume number
			$level+=$_;
			$level=0 if $level< 0;
			$level=8 if $level> 8;
		}
		else{
		
			$level=$lookup->{$_};	
			croak "Log::OK: unknown level \"$value\" for Log::Any. Valid options: ".join ', ', keys %$lookup unless defined $level;
		}
	}

        DEBUG_ and say STDERR "Level input $value";
        DEBUG_ and say STDERR "Level output $level";

        (
                #Contants to define
                "Log::OK::EMERGENCY"=>$level>=0,
                "Log::OK::ALERT"=>$level>=1,
                "Log::OK::CRITICAL"=>$level>=2,
                "Log::OK::ERROR"=>$level>=3,
                "Log::OK::ERR"=>$level>=3,
                "Log::OK::WARNING"=>$level>=4,
                "Log::OK::WARN"=>$level>=4,
                "Log::OK::NOTICE"=>$level>=5,
                "Log::OK::INFO"=>$level>=6,
                "Log::OK::INFORM"=>$level>=6,
                "Log::OK::DEBUG"=>$level>=7,
                "Log::OK::TRACE"=>$level>=8,

                "Log::OK::LEVEL"=>$value
        )
}

sub log_ger {
	
	DEBUG_ and say STDERR "setup for Log::ger";
	my ($opt, $value)=@_;
  state $unset=1;
	state $lookup={
		fatal   => 10,
		error   => 20,
		warn    => 30,
		info    => 40,
		debug   => 50,
		trace   => 60,
	};
	state $level=10;
	$value//="fatal"; #Default if undefined
	$value=1 if $value eq "" or $value eq 0;
	for(lc($value)){
		#test numeric
		if(/\d/){
			#assume number
			$level+=$_*10;
			$level=10 if $level < 10;
			$level=60 if $level > 60;
		}
		else{
			$level=$lookup->{$_};	
			croak "Log::OK: unknown level \"$value\" for Log::ger. Valid options: ".join ', ', keys %$lookup unless defined $level;
		}
	}

  #
  # Update the level in Log::ger only when the constant exists and for the first time only
  #
  if(*Log::OK::LEVEL{CODE} and $unset){
    $unset=undef;
    my $message= "Log::OK could not automatically sync log levels with your logger";
    carp $message unless eval "
    require Log::ger::Util;
    Log::ger::Util::set_level(Log::OK::LEVEL);
    1;
    ";
  }

	(
		#TODO: these values don't work well with 
		#incremental logging levels from the command line
		
		"Log::OK::FATAL"=>$level>=10,
		"Log::OK::ERROR"=>$level>=20,
		"Log::OK::WARN"=>$level>=30,
		"Log::OK::INFO"=>$level>=40,
		"Log::OK::DEBUG"=>$level>=50,
		"Log::OK::TRACE"=>$level>=60,

		"Log::OK::LEVEL"=>$level
	)

}

sub log_dispatch {
	DEBUG_ and say STDERR "setup for Log::Dispatch";
	my ($opt, $value)=@_;
	state $lookup={
		debug=>0,
		info=>1,
		notice=>2,
		warning=>3,
		error=>4,
		critical=>5,
		alert=>6,
		emergency=>7,

		#aliases
		warn=>3,
		err=>4,
		crit=>5,
		emerg=>7
	};
	state $level;
	$value//="emergency"; #Default if undefined
	$value=1 if $value eq "" or $value eq 0;
	for(lc($value)){
		#test numeric
		if(/\d/){
			#assume number
			$level-=$_;
			$level=0 if $level < 0;
			$level=7 if $level > 7;
		}
		else{
		
			$level=$lookup->{$_};	
			croak "Log::OK: unknown level \"$value\" for Log::Dispatch. Valid options: ".join ', ', keys %$lookup unless defined $level;
		}
	}




	(
		#TODO: these values don't work well with 
		#incremental logging levels from the command line

		"Log::OK::EMERGENCY"=>$level<=7,
		"Log::OK::EMERG"=>$level<=7,
		"Log::OK::ALERT"=>$level<=6,
		"Log::OK::CRITICAL"=>$level<=5,
		"Log::OK::CRIT"=>$level<=5,
		"Log::OK::ERROR"=>$level<=4,
		"Log::OK::ERR"=>$level<=4,
		"Log::OK::WARNING"=>$level<=3,
		"Log::OK::WARN"=>$level<=3,
		"Log::OK::NOTICE"=>$level<=2,
		"Log::OK::INFO"=>$level<=1,
		"Log::OK::DEBUG"=>$level<=0,

		"Log::OK::LEVEL"=>$level
	)


}

sub log_log4perl {
	DEBUG_ and say STDERR "setup for Log::Log4perl";

	my ($opt, $value)=@_;
	state $lookup={

		ALL   => 0,
		TRACE =>  5000,
		DEBUG => 10000,
		INFO  => 20000,
		WARN  => 30000,
		ERROR => 40000,
		FATAL => 50000,
		OFF   => (2 ** 31) - 1
	};

	state $levels=[ 0,5000,10000,20000,30000,40000,50000,(2**31)-1];

	DEBUG_ and say STDERR "";
	DEBUG_ and say STDERR "VALUE: $value";
	my $level;
	state $index=@$levels-1;

	$value//="FATAL"; #Default if undefined
	$value=1 if $value eq "" or $value eq 0;

	for(uc($value)){
		#test numeric
		if(/\d/){
			#assume number
			$index-=$_;
			$index=0 if $index< 0;
			$index=@$levels-1 if $index > @$levels-1;
			$level=$levels->[$index];
			croak "Log::OK: unknown level \"$value\" for Log::Log4perl" unless grep $level==$_, @$levels;

		}
		else{
			$level=$lookup->{$_};	

			croak "Log::OK: unknown level \"$value\" for Log::Log4perl. Valid options: ".join ', ', keys %$lookup unless defined $level;
			($index)=grep $levels->[$_]==$level, 0..@$levels-1;
		}
	}


	DEBUG_ and say STDERR "LEVEL: $level";

	(
		#TODO: these values don't work well with 
		#incremental logging levels from the command line

		"Log::OK::OFF"=>$level<=$lookup->{OFF},
		"Log::OK::FATAL"=>$level<=50000,
		"Log::OK::ERROR"=>$level<=40000,
		"Log::OK::WARN"=>$level<=30000,
		"Log::OK::INFO"=>$level<=20000,
		"Log::OK::DEBUG"=>$level<=10000,
		"Log::OK::TRACE"=>$level<=5000,
		"Log::OK::ALL"=>$level<=0,

		"Log::OK::LEVEL"=> $level
	)
}

#Define all supported constants as false.
sub no_logger {
	DEBUG_ and say STDERR "NO LOGGER DETECTED";
	(
		"Log::OK::OFF"=>0,
		"Log::OK::FATAL"=>0,
		"Log::OK::ERROR"=>0,
		"Log::OK::INFO"=>0,
		"Log::OK::DEBUG"=>0,
		"Log::OK::TRACE"=>0,
		"Log::OK::ALL"=>0,


		"Log::OK::EMERGENCY"=>0,
		"Log::OK::EMERG"=>0,
		"Log::OK::ALERT"=>0,
		"Log::OK::CRITICAL"=>0,
		"Log::OK::CRIT"=>0,
		"Log::OK::ERR"=>0,
		"Log::OK::WARNING"=>0,
		"Log::OK::NOTICE"=>0,

		"Log::OK::FATAL"=>0,

                "Log::OK::INFORM"=>0,

		"Log::OK::WARN"=>0,

		"Log::OK::LEVEL"=> 0
	)

}

1;
