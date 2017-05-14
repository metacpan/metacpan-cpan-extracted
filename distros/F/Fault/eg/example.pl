#!/usr/bin/perl -w

use lib ".";
use Fault::Logger;
use Fault::Msg;
use Fault::Delegate::Stdout;

 {   package Simple1;
      use vars qw{@ISA};
     @ISA = qw( UNIVERSAL );
     sub new     {my ($class) = @_; my $self = bless {}, $class; 
                  return $self;}
     sub log     {my ($self,$msg) = @_; my $str = $msg->msg;
		  print "\t\t     SIMPLE1: $str\n"; return 1;}
     1;
 }
 {   package Simple2;
     use vars qw{@ISA};
     @ISA = qw( UNIVERSAL );
     sub new        {my ($class) = @_; my $self = bless {}, $class; 
                     return $self;}
     sub log        {my ($self,$msg,$target,$myarg) = @_;
                    (defined $myarg) || ($myarg="");
		     my $str = $msg->msg;
 	             print "\t\t     SIMPLE2: $str $myarg\n"; return 1;}
     sub trans01    {my ($self,$msg,$target,@rest) = @_;}
     sub trans10    {my ($self,$msg,$target,@rest) = @_;}
     sub initfaults {my ($self) = @_; my @msglist   = (); return @msglist;}
     1;
 }

 sub fn {return shift;}
 my @mine = ("(Extra argghhs)","myarg2");
 my @rest = (undef,undef,undef,@mine);

 # Take your pick
 my $delegate1 = Simple1->new;
 my $delegate2 = Simple2->new;
 my $delegate3 = Fault::Delegate::Stdout->new;

 my $baz       = Fault::Logger->new  ($delegate1,$delegate2);
                 $baz->add_delegates ($delegate3);
    @delegates = Fault::Logger->delegates;
    @delegates = $baz->delegates;

 # Basic logging
 my $waslogged = Fault::Logger->log   ("Log this message or we shoot the dog",
                                       @rest);
    $waslogged = $baz->log            ("Bang!",@rest);

 # One shot logging
 my $first     = Fault::Logger->log_once    ("Useful once.",@rest);
    $first     = $baz->log_once             ("Useful once.",@rest);

 # Raise and lower fault
 my $okay      = Fault::Logger->fault_check ((!fn(0)),"TestGroup","Fn okay",
					     "NET",undef,undef,@mine);
    $okay      = $baz->fault_check          ((!fn(1)),"TestGroup","Fn okay",
					     "NET",undef,undef,@mine);

 # Report only when assertion is true
    $okay      = Fault::Logger->assertion_check ((!fn(0)),"[ASSERT]","Not OK",
						 "DATA",undef,undef, @mine);
    $okay      = $baz->assertion_check          ((!fn(1)),"[ASSERT]","Fn OK",
						 "DATA",undef,undef, @mine);

    $okay      = Fault::Logger->arg_check_isalnum ("A 1","val","BUG",
						   undef,undef,@rest);
    $okay      = $baz->arg_check_isalnum          ("A1","val","BUG",
						   undef,undef,@rest);
    $okay      = $baz->arg_check_isalnum          ("A;1","val");

 my $val       = "801234597566";
    $okay      = Fault::Logger->arg_check_isdigit ("A1","val","BUG",
						   undef,undef,@rest);
    $okay      = $baz->arg_check_isdigit          ("81","val","BUG",
						   undef,undef,@rest);
    $okay      = $baz->arg_check_isdigit          ("81.1","val");

    $okay      = Fault::Logger->arg_check_noref   (\$val,"val","BUG",
						   undef,undef,@rest);
    $okay      = $baz->arg_check_noref            ($val,"val","BUG",
						   undef,undef,@rest);
    $okay      = $baz->arg_check_noref            ($delegate1,"val");

    $val       = Fault::Msg->new;
    $okay      = Fault::Logger->arg_check_isa ($delegate1,'Fault::Msg',"val",
					       "BUG",undef,undef,@rest);
    $okay      = $baz->arg_check_isa          ("aaa",'Fault::Logger',"val",
					       "BUG",undef,undef,@rest);
    $okay      = $baz->arg_check_isa          ($val,'Fault::Msg',"val");

 # Access to latest logged message.
 my $msg       = Fault::Logger->message;
                 Fault::Logger->clr_message;

 # Raise and lower bug fault 
    undef $foo;
    $okay      = Fault::Logger->bug_check   ((!defined $foo),"Missing arg",
					     undef,@mine);
 my $foo       = 0;
    $okay      = $baz->bug_check            ((!defined $foo),"Missing arg",
					     undef,@mine);

 # Access to latest logged message.
    $msg       = $baz->message;
                 $baz->clr_message;

 # Only the first one will report
                 Fault::Logger->crash       ("AieeeEEE",@rest);
                 $baz->crash                ("Arrghhhhh",@rest);
