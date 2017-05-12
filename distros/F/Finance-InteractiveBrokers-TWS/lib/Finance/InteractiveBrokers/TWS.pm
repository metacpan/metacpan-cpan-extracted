#!/usr/bin/perl

package Finance::InteractiveBrokers::TWS;

use version; $VERSION = qv('0.1.1');

use warnings;
use strict;
use File::Spec;
use Data::Dumper;

use Class::InsideOut qw(:std);

#	Define class attributes
#
readonly api_path   => my %api_path;
readonly IB_classes => my %IB_classes;
readonly api_spec   => my %api_spec;
readonly java_src   => my %java_src;
readonly jcode      => my %jcode;
readonly eclient    => my %eclient;

sub new { 

	my $self     = register( shift );
	my $callback = shift;

	$callback || die 
	   "\n*** You MUST supply a callback to create a TWS object\n\n";

	$api_path   {id $self} = $self->get_tws_api_install_path();
	$IB_classes {id $self} = $self->get_list_ref_of_classes();
	$api_spec   {id $self} = $self->learn_EWrapper_spec();
	$java_src   {id $self} = $self->build_java_src();

	$self->compile_java_src();
	$self->create_subroutines();

	my $jcode = Finance::InteractiveBrokers::TWS::Inline_Java->new($callback);
	$jcode{id $self} = $jcode;

	my $eclient = $self->EClientSocket->new($jcode);
	$eclient{id $self} = $eclient;

	$jcode->OpenCallbackStream();

	return $self;
}

=begin build_java_src 

I need to build a Java class that looks like the following with a whole
bunch of duplicate methods, one for each event the TWS emits.  Rather
than hard code the Java class, I build it on the fly by reading the
EWrapper as compiled by INLINE.  Then I return the source which
looks like:

	import org.perl.inline.java.*;
	import com.ib.client.*;

	class Inline_Java extends InlineJavaPerlCaller implements EWrapper {

	InlineJavaPerlObject perlobj;

    	public Inline_Java(InlineJavaPerlObject PerlObj)
    	throws InlineJavaException {
       	perlobj = PerlObj;
    	}

    	public void tickPrice(int tickerId, int field, double price,
                          int canAutoExecute)

    	{
       	try {
            		perlobj.InvokeMethod("tickPrice", new Object [] {
			tickerId, field, price, canAutoExecute }); 
		}
        	catch (InlineJavaPerlException pe){ }
        	catch (InlineJavaException pe) { pe.printStackTrace() ;}
	}
  ...
  ...
  ...
  }

=end build_java_src

=cut
sub build_java_src {

	my $self = shift;

	my $src = <<"	END";
	import org.perl.inline.java.*;
        import com.ib.client.*;

	class Inline_Java extends InlineJavaPerlCaller implements EWrapper {

	InlineJavaPerlObject perlobj;

	public Inline_Java(InlineJavaPerlObject PerlObj)
	throws InlineJavaException { perlobj = PerlObj; }

	END

	foreach my $method_def_ref (@{$self->api_spec()}) {

		my ($method_name, $parm_list_ref) = @$method_def_ref;
 		
		# I need to remove the 'java.lang' from 'java.lang.String'
		# and the 'com.ib.client' from 'com.ib.client.Contract'
		# etc.. that gets stuck on some of the attributes
		my @clean = map { (split/\./)[-1] } @{$parm_list_ref};

		my $str0 = join ',', map {$clean[$_]." var".$_} 0..$#clean;
		my $str1 = join ',', map {"var".$_} 0..$#clean;
	
		$src .= sprintf("\tpublic void %s(%s) {
            try {
                perlobj.InvokeMethod(\"%s\", new Object [] {
                        %s
                });
            }
            catch (InlineJavaPerlException pe){ }
            catch (InlineJavaException pe) { pe.printStackTrace() ;}\n\n\t}",
		 $method_name, $str0, $method_name, $str1);
	}

	$src .= '}';

	return $src;
}


=for compile_java_src 
Take the Java source created in this module and compile it, also study
all the IB supplied classes, so we can use them.

=cut
sub compile_java_src {

	my $self = shift;

	# Prepend 'com.ib.client' to each class, for proper pathing in STUDY
	my @class_list = map {'com.ib.client.'.$_} @{$self->IB_classes()};

	Inline->bind(
		Java => $self->java_src(),
      AUTOSTUDY => 1,
      STUDY => \@class_list,
      );
	
	return 0;
}

=begin create_subroutines

	I (at time of writing) create the following subroutines DYNAMICALLY:

	   EClientErrors
	   AnyWrapper
	   Execution
	   EWrapperMsgGenerator
	   ExecutionFilter
	   EWrapper
	   EClientSocket
	   TickType
	   OrderState
	   EReader
	   ScannerSubscription
	   AnyWrapperMsgGenerator
	   ContractDetails
	   Order
	   ComboLeg
	   Util
	   EClientErrors$CodeMsgPair
	   Contract

	These are simple, convenience subs that call the IB supplied class.  So that
	the user (or me) can do:

		my $contract = $object->Contract(...);

	 to create an IB contract instead of having to do
	
	   my $contract = 
	     Finance::InteractiveBrokers::TWS::com::ib::client::Contract->new(...);


	The subroutines I create look like:

	   sub Contract {
	      return __PACKAGE__.'::com::ib::client::Contract';
	   }

=end create_subroutines

=cut

sub create_subroutines {

	my $self = shift;

	{  # localize "no strict 'refs'" to this block
		no strict 'refs';
		
		foreach my $class_name (@{$self->IB_classes()}) {

			*{ $class_name } = 
			   sub { return __PACKAGE__.'::com::ib::client::'.$class_name };

		}
	}
}

=for get_list_ref_of_classes
	I read the list of files in the API directory whose name ends in 
	*.class, remove the .class from the name and return a list of class names

=cut
sub get_list_ref_of_classes {

	my $self = shift;
	
	opendir(DIR, $self->api_path() ) || die 
		"can not opendir \'".$self->api_path(),"\': $!";

	# CAREFUL this grep uses a search and replace to remove ".class"
	# from the filename in addition to the match
	my @classes = grep { s/\.class// } readdir(DIR);

	closedir DIR;

	return \@classes;
}

=for get_tws_api_install_path 
	get_tws_api_install_path, simply looks through the CLASSPATH environmental
	variable and finds the path for the likely TWS installation, the way I do
	it is probably not bullet proof, that is looking for a path with IBJts 
	or jts, but it works for me.

=cut
sub get_tws_api_install_path {

	my $self = shift;

	defined $ENV{'CLASSPATH'} || die "\nCLASSPATH not set\n\n";
	my ($API_base) = grep {/(IBJts)|(jts)/} split(/[:;]/, $ENV{CLASSPATH});

	my @path = File::Spec->splitdir($API_base);
	push @path, qw[com ib client];
	my $path = File::Spec->catfile(@path);

	return $path;
}

=for learn_EWrapper_spec 
	I complile the IB supplied EWrapper with Inline::Java, and then plumb
	the debths of the structure created to learn the methods within the EWrapper
	and number and type of parameters to each method, so that I may later
	use that info, to dynamically build my own Wrapper

=cut
sub learn_EWrapper_spec {

	my $self = shift;

	use Inline (
		Java => 'STUDY',
		AUTOSTUDY => 1,
		STUDY => ['com.ib.client.EWrapper'],
	);

	my $package_name = __PACKAGE__.'::com::ib::client::EWrapper';
	my $inlines = (Inline::Java::__get_INLINES)[0]->[0]{ILSM}{data}[1];

	my $ewrapper_methods_ref = $inlines->{classes}{$package_name}{methods};

	my @spec = ();

	# Build a [[method_name, @parms], [method_name, @parms]]
	while (my ($method_name, $value) = each %{$ewrapper_methods_ref}) {

		while (my ($key, $ivalue) = each %{$value}) {
	
			push @spec, [$method_name, $ivalue->{SIGNATURE}] 
				if $ivalue->{SIGNATURE};
		}
	}

	return \@spec;
}

=for read_messages_for_x_sec 
Call our implementation of EWrapper to process the messages emitted from
the TWS.  When the messages are read it will trigger the code in the callback
supplied by the user.

=cut
sub read_messages_for_x_sec {

   my ($self, $wait) = @_;

   $wait ||= .05;
   my $jcode = $self->jcode(); 

   my $num_callbacks_processed = 0;
   while ($jcode->WaitForCallback($wait)) {
       $jcode->ProcessNextCallback();
       $num_callbacks_processed++;
   }

   return $num_callbacks_processed;
}

1;

__END__

=pod

=head1 NAME

Finance::InteractiveBrokers::TWS - Lets you talk to Interactivebrokers Trader's Workstation using Perl.

This module is a lightweight wrapper around InteractiveBroker's Trader's Workstation (TWS) Java interface, that lets one interact with the TWS using Perl, via the vendor supplied API.  This means that all the functionality available to Java programmers is also available to you.

To successfully use this module you will need to familiarize yourself with the IB java code supplied in the API.

=head1 VERSION

0.1.0 - Still alpha code.  But its been redesigned to be more compatible with changes to the IB API.  It works well with my limited tests.

** WARNING ** This version is incompatible with previous versions of this module. 

=head1 SYNOPSIS

	my $callback = My::Custom_Callback_Code->new();
	my $tws      = Finance::InteractiveBrokers::TWS->new($callback);

	#                           Host         Port    Client_ID
	#                           ----         ----    ---------
	my @tws_GUI_location = qw/  127.0.0.1    7496       15     /;

	$tws->eclient->eConnect(@tws_GUI_location);
	do {$tws->read_messages_for_x_sec()} until $tws->eclient-isConnected();

	#  Create a contract
	#
	my $contract    = $tws->Contract->new();

	#	Set the values
	$contract->{m_conId}    = 50;
	$contract->{m_symbol}   = 'AAPL';
	$contract->{m_secType}  = 'STK';
	$contract->{m_exchange} = 'SMART';

	my $contract_id = 50;     # this can be any number you want
	$tws->eclient->reqMktData($contract_id, $contract,"","");

	while(1) {
		$tws->read_messages_for_x_sec();
	}

=head1 DESCRIPTION

Finance::InteractiveBrokers::TWS - Is a wrapper around InteractiveBrokers Traders Workstation (TWS) Java interface, that lets one interact with the TWS using Perl, via the vendor supplied API.

It uses Inline::Java to wrap InteractiveBrokers' Java API that IB supplies to communicate with the TWS.  As such, the method names don't conform to Perl standards and in most cases follow Java standards.

After numerous attempts at writing a pure perl module I opted for this solution because:

=over 

=item * 

Using Inline::Java resulted in a much simpler and smaller module

=item * 

The interaction and call syntax is identical to the Java API (because it is the Java API) and as such, you can ask questions on the IB bulletin board and yahoo, and be using the same method names and call syntax as they are.  In other words, people will know what you're talking about.

=item * 

IB changes their interface with some frequency, which required re-writing my interface every time 

=item * 

IB changes there message stream, which required me to modify my parser

=item * 

Whenever IB changes something I'd have to diff the old API versus the new API and try to figure out what changed and how that affected my code 

=back

=head1 USAGE

=head2 Class Methods

The following methods are provided by the Finance::InteractiveBrokers::TWS class

=head3 new

Sorta obvious, this instantiates an object of class Finance::InteractiveBrokers::TWS.  It requires a single parameter: a callback object.  That is, you (the user) has to write a class that can handle the messages that the TWS will emit.

 my $tws = Finance::InteractiveBrokers::TWS->new($callback);

=head3 read_messages_for_x_sec

Processes the messages the TWS has emitted.  It accepts a single optional parameter of how many seconds to listen for messages to process.  It returns the number of callbacks processed.  If no messages are found within the wait period, control is returned to the caller.

 my $seconds_to_wait = 2;
 my $quantity = $tws->read_messages_for_x_sec($seconds_to_wait);

=head2 IB Methods

Once you've instantiated a Finance::InteractiveBrokers::TWS object you make the same calls that some one working directly in Java would make to the API.  You do this via the "eclient" method of $tws.

For example when you want to connect to the TWS you issue:

 $tws->eclient->eConnect(@tws_GUI_location);

Or if you want to request some market data you issue:

 $tws->eclient->reqMktData($contract_id, $contract,"","");

Or to find out if you're connected to TWS:

 my $connection_status = $tws->eclient->isConnected();

You get the idea!

=head2 IB Objects

To interact with the TWS via the API one needs to create various objects supplied by IB, such as Contracts, Orders, ComboLegs... All the objects supplied by IB are available to this module.  To instantiate any IB class, use the $tws you've created

=head3 Instantiation

When instantiating these objects you can pass all the parameters in positionally according to how IB has documented them.  Or you can just create them blank and set the attributes later.  Some examples are:

	my $order = $tws->Order->new(@parms);

=head3 Attribute Setting / Getting

When Inline::Java creates these objects it hands back a Perl reference to hash.  Thus working with these objects is simple.  To set a attribute of an object you do it like:

	$contract->{m_symbol}   = 'YHOO';

To get an attribute of an object you do it like:

	my $symbol = $contract->{m_symbol};

=head1 CALLBACK

The callback is the custom code you write to handle the messages the TWS emits and that are picked up by the API.  The API dispatches (call) your callback to handle processing of the message.

The methods that are called are described (poorly) by IB at:

http://www.interactivebrokers.com/php/webhelp/Interoperability/Socket_Client_Java/java_ewrapper.htm

But in general, you will have methods in your callback like:


 sub tickPrice {
	my ($self, @args) = @_;
	
	# do something when you get a change in price
 }

 sub error {
	my ($self, @args) = @_;

	# handle the error
 }

Again, these methods are described by IB on their website.

=head1 EXAMPLE

 package Local::Callback;
 use strict;
 
 sub new {
	 bless {}, shift;
 }
 
 sub nextValidId {
	 my $self = shift;
	 $self->{nextValidId} = $_[0];
	 print "nextValidId called with: ", join(" ", @_), "\n";
 }
 
 sub error {
	 my ($self, $return_code, $error_num, $error_text) = @_;
 
	 print "error called with: ", join('|', $return_code,
	     $error_num, $error_text), "\n";
 
	 # sleep for some predetermined time if I get a 502
	 # Couldn't connect to TWS.  Confirm that "Enable ActiveX and
	 # Socket Clients" is enabled on the TWS "Configure->API" menu.
	if ($error_num == 502) {
	    sleep 60;
	 }
 }
 
 sub AUTOLOAD {
	 my ($self, @args) = @_;
	 our $AUTOLOAD;
	 print "$AUTOLOAD called with: ", join '^', @args, "\n";
	 return;
 }
 
 package main;
 
 use Finance::InteractiveBrokers::TWS;
 
 my $tws;
 
 while (1) {
 
	 if (defined $tws and $tws->isConnected) {
	     $tws->read_messages_for_x_sec(1);
	 }
	 else {
	     connect_to_tws();
	 }
 }
 
 $tws->eDisconnect;
 
 #   connect_to_tws, connects to the tws and sets up a few
 #   objects that we want clean at every new connection
 sub connect_to_tws {
 
	 my $callback = Local::Callback->new();
	 $tws = Finance::InteractiveBrokers::TWS->new($callback);
 
	 ####                        Host         Port    Client_ID
	 ####                        ----         ----    ---------
	 my @tws_GUI_location = qw/  127.0.0.1    7496       15     /;
 
	 $tws->eConnect(@tws_GUI_location);
 
	 my $contract_id = 50;      # this can be any number you want
	 my $contract    = $tws->Contract->new();
 
	 $contract->{m_symbol}   = 'YHOO';
	 $contract->{m_secType}  = 'STK';
	 $contract->{m_exchange} = 'SMART';
 
	 $tws->reqMktData($contract_id, $contract);
 
	 $tws->read_messages_for_x_sec(3);
 
	 return;
 }
 

=head1 HELP

You are welcome to email me if you are having problems with this module.  You should also look at the IB forums (http://www.interactivebrokers.com/cgi-bin/discus/discus.pl) if you have questions about interacting with the TWS (i.e. how to get TWS to do something for you, what the proper call syntax is...)

There is also another forum on: http://finance.groups.yahoo.com/group/TWSAPI . I'm not exactly sure of what the difference is.

There is a Wiki for TWS at: http://chuckcaplan.com/twsapi/

=head1 DIAGNOSTICS

If you receive an error something like:

=head2 Inline_Bridge is not abstract and does not override abstract method...

 The error message was:
 TWS_581d.java:6: Inline_Bridge is not abstract and does not override abstract method tickOptionComputation(int,int,double,double) in com.ib.client.EWrapper
 class Inline_Bridge extends InlineJavaPerlCaller implements EWrapper {
^
 1 error

It means that this module (Finance::InteractiveBrokers::TWS) is not up to date with the current IB API version you have installed.  Specifically, this module is missing a new method implemented by the API.

The easiest fix is to look at the specification of the method (in this case tickOptionComputation), in the EWrapper.java file in the IBJts/java/com/ib/client directory where you installed the IB API, and implement it in the __Java__ section of this module.  Additionally, add the appropriate entry into the tws.conf file (Its really simple code, I promise you can figure it out, just copy and paste a different section).  Then do a "make realclean && perl Makefile.PL && make && make test" and see if that fixes the compile error.

=head2  Finance::InteractiveBrokers::TWS::java::lang::NullPointerException=HASH(0x8b671cc)
 
This means you did not supply a callback object when you instantiated a Finance::IB:TWS object.

 The error message was:
 TWS_661f.java:21: incompatible types
 found   : int
 required: java.lang.Object
	                 tickerId, field, price, canAutoExecute
	                 ^

The above error is sort of a bug, sort of an inconsistancy.  But basically if you are running Java <= 1.4 then you need to alter the TWS.pm source and change the lines that look like:

 perlobj.InvokeMethod("tickPrice", new Object [] {
	                   tickerId, field, price, canAutoExecute
	                  });

and manually cast the variables into their types directly, like this:

 perlobj.InvokeMethod("tickPrice", new Object [] {
	new Integer (tickerId), new Integer (field), new Double (price), 
	new Integer (canAutoExecute)});

I don't feel like going through all the code to do this, especially since most
people will be using Java 1.5 and above shortly

=head2 Other errors during first time use

Please delete the installation and start over making sure you install as "root".  YOU MUST RUN THE tests.  The tests create a directory where the Inline::Java places some necessary files.

=head1 CONFIGURATION AND ENVIRONMENT

You need to compile the *.java API source files into java class files prior to using this module.  Do it like:

 $ cd ~/IBJts/java/com/ib/client/
 $ javac *.java

Furthermore Finance::InteractiveBrokers::TWS does require that you set your CLASSPATH environmental variable to the location of the IBJts/java directory where you installed the IB API.  Such as:

 $ export CLASSPATH=~/IBJts/java

=head1 DEPENDENCIES

=over

=item * 

Java JDK/JRE version >= 1.5 - If you have a lower version there is a workaround see DIAGNOSTICS

=item *

InteractiveBrokers TWS GUI application

=item *

Inline

=item * 

Inline::Java v.50_92 or greater

=item *

Class::InsideOut

=back

=head1 INCOMPATIBILITIES

See above DIAGNOSTICS

=head1 BUGS AND LIMITATIONS

See above DIAGNOSTICS

Please report any bugs or feature requests to
C<bug-finance-ib-tws@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 VERY SPECIAL THANKS

Patrick LeBoutillier - Author of Inline::Java, and for all his help while I learned how to use Inline::Java

=head1 ACKNOWLEDGEMENTS

Carl Erickson wrote the first Perl interface. Based on his README, it was sort of a proof of concept, and doesn't implement all of TWS's functionality. Carl is pretty active on the TWS mailing list(s). He doesn't actively "support" the perl code, but he's very helpful if you want to try it and need some help. This code is meant to be synchronous and blocking; in that you request market data, and your program blocks until you get the data back. Every time you want new data, you request it.

You can find the code on the Yahoo TWSAPI group, I think the following link will work: http://finance.groups.yahoo.com/group/TWSAPI/files/Perl%20Code/

=head1 AUTHOR

Jay Strauss  C<< <tws_at_heyjay.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Jay Strauss C<< <tws_at_heyjay.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
/usr/bin/perl
