##################################################
package Log::Log4perl::Layout::XMLLayout;
##################################################

use 5.006;
use strict;
use warnings;
use Carp;
use Log::Log4perl::Level;
use Log::Log4perl::DateFormat;
use Log::Log4perl::NDC;
use Log::Log4perl::MDC;
use File::Spec;

our $TIME_HIRES_AVAILABLE;
our $TIME_HIRES_AVAILABLE_WARNED = 0;

our $VERSION = do { my @r = (q$Revision: 0.03 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };



BEGIN {
    # Check if we've got Time::HiRes. If not, don't make a big fuss,
    # just set a flag so we know later on that we can't have fine-grained
    # time stamps
    $TIME_HIRES_AVAILABLE = 0;
    eval { require Time::HiRes; };
    if(!$@) {
        $TIME_HIRES_AVAILABLE = 1;
    }
}

##################################################
sub current_time {
##################################################
    # Return msecs 
    if($TIME_HIRES_AVAILABLE) {
    	my($millis)=0;
    	my($secs, $micros)=Time::HiRes::gettimeofday();
    	{ use integer;
    	  $millis=$micros/1000;
    	}
        # we do not want to use BigInt:
        # determine millisecs since 1970 based on string operations
        return (sprintf("%s%0.3d", $secs, $millis));
    } else {
        return (time().'000');
    }
}

use base qw(Log::Log4perl::Layout);

no strict qw(refs);

##################################################
sub new {
##################################################
    my $class = shift;
    $class = ref ($class) || $class;

    my ($data) = @_;

    my ($location_info)=1;
    my ($encoding)=undef;
    
    if ((defined $data) && (ref $data)) {
       if (exists $data->{LocationInfo}{value} ) {
          $location_info = (uc($data->{'LocationInfo'}{value}) eq 'TRUE'?1:0);
        }
       if (exists $data->{'Encoding'}{value} ) {
          $encoding = $data->{'Encoding'}{value};
       }
    }
    my $self = {
        format      => undef,
        info_needed => {},
        stack       => []
    };

    bless $self, $class;
    $self->{'location_info'}=$location_info;
    $self->{'encoding'}=$encoding;
    $self->{'enc_set'}=0;
    
    return $self;
}


##################################################
sub render {
##################################################
    my($self, $message, $category, $priority, $caller_level) = @_;

    $caller_level = 0 unless defined  $caller_level;

    my %info    = ();

    $info{m}    = $message;
        # See 'define'
    chomp $info{m} if $self->{message_chompable};

    my @results = ();

    if($self->{'location_info'}) {
        my ($package, $filename, $line, 
            $subroutine, $hasargs,
            $wantarray, $evaltext, $is_require, 
            $hints, $bitmask) = caller($caller_level);

        # If caller() choked because of a whacko caller level,
        # correct undefined values to 'undef' in order to prevent 
        # warning messages when interpolating later
        unless(defined $bitmask) {
            for($package, 
                $filename, $line,
                $subroutine, $hasargs,
                $wantarray, $evaltext, $is_require,
                $hints, $bitmask) {
                $_ = 'undef' unless defined $_;
            }
        }

        $info{L} = $line;
        $info{F} = $filename;
        $info{C} = $package;
        $info{C} =~ s/::/./g;

        # For the name of the subroutine the logger was triggered,
        # we need to go one more level up
        $subroutine = (caller($caller_level+1))[3];
        $subroutine = "main" unless $subroutine;
        my(@namespace)=split(/::/, $subroutine);
        $info{M} = pop(@namespace);
    }

    $info{x} = Log::Log4perl::NDC->get();
    $info{x} =~ s/[\[\]]//g;
    $info{x} =~ s/::/./g;
    $info{c} = $category;
    $info{d} = current_time;
    $info{p} = $priority;

    # create XML-Code 

    my($xml_code)= qq(<log4j:event logger="$info{c}"
	timestamp="$info{d}"
	level="$info{p}"
	thread="$$">
	<log4j:message><![CDATA[$info{'m'}]]></log4j:message>
	<log4j:NDC><![CDATA[$info{x}]]></log4j:NDC>);
    if($self->{'location_info'}) {
    	$xml_code.= qq(
	<log4j:locationInfo class="$info{C}"
		method="$info{M}"
		file="$info{F}"
		line="$info{L}">
	</log4j:locationInfo>);
   }
   $xml_code.= qq(\n</log4j:event>\n);
   
   if(!($self->{'enc_set'})) {
      $xml_code=join("\n", qq(<?xml version = "1.0" encoding = "$self->{'encoding'}"?>)
                , $xml_code) if (defined $self->{'encoding'});
      $self->{'enc_set'}=1;	
   }
   return ($xml_code);
}


1;

__END__

=head1 NAME

Log::Log4perl::Layout::XMLLayout - XML Layout

=head1 SYNOPSIS

  use Log::Log4perl::Layout::XMLLayout;

  my $app = Log::Log4perl::Appender->new("Log::Log4perl::Appender::File");

  my $logger = Log::Log4perl->get_logger("abc.def.ghi");
  $logger->add_appender($app);

  # Log with LocationInfo
  my $layout = Log::Log4perl::Layout::XMLLayout->new(
    { LocationInfo => { value => 'TRUE' },
      Encoding     => { value => 'iso8859-1'}});
      
  $app->layout($layout);
  $logger->debug("That's the message");

  ########################### Log4perl Config File entries for XMLLayout
  log4perl.appender.A1.layout			= Log::Log4perl::Layout::XMLLayout
  log4perl.appender.A1.layout.LocationInfo	= TRUE
  log4perl.appender.A1.layout.Encoding		=iso8859-1
  ###########################

=head1 DESCRIPTION

Creates a XML layout according to
http://jakarta.apache.org/log4j/docs/api/org/apache/log4j/xml/XMLLayout.html

Logfiles generated based on XMLLayout can be viewed and filtered 
within the log4j chainsaw graphical user interface (see example section below).
chainsaw is part of the JAVA based log4j package and can be downloaded from
http://jakarta.apache.org/

The output of the XMLLayout consists of a series of log4j:event elements as defined in the log4j.dtd. It does not output a complete well-formed XML file. 
The output is designed to be included as an external entity in a separate file to form a correct XML file. 

For example, if abc is the name of the file where the XMLLayout ouput goes, then a well-formed XML file would be: 


<?xml version="1.0" ?>

<!DOCTYPE log4j:eventSet SYSTEM "log4j.dtd" [<!ENTITY data SYSTEM "abc">]>

<log4j:eventSet version="1.2" xmlns:log4j="http://jakarta.apache.org/log4j/">
  &data;
</log4j:eventSet>


This approach enforces the independence of the XMLLayout and the appender where it is embedded. 

The version attribute helps components to correctly intrepret output generated by XMLLayout. The value of this attribute should be "1.1" for output generated by log4j versions prior to log4j 1.2 (final release) and "1.2" for relase 1.2 and later. 

=head2 Methods

=over 4

=item new()

The C<new()> method creates a XMLLayout object, specifying its log
contents. 
NDC is explained in L<Log::Log4perl/"Nested Diagnostic Context (NDC)">.

=back

=head2 Attributes

=over 4

=item LocationInfo

If LocationInfo is set to TRUE, source code location info is added to each 
logging event.

=item Encoding

adds XML version and character encoding attributes to the log.
Following line is generated only when the first logger call is done:

E<lt>?xml version = "1.0" encoding = "iso8859-1"?E<gt>

This line will not be generated if the Encoding attribute is undefined. This is required when using chainsaw to view
XMLLayouted logfiles.

=back

=head2 Example

To view an filter XMLLayouted files in Chainsaw, create a chainsaw configuration file like 

  <log4j:configuration debug="true">
  
    <plugin name="XMLSocketReceiver" class="org.apache.log4j.net.XMLSocketReceiver">
            
      <param name="decoder" value="org.apache.log4j.xml.XMLDecoder"/> 
      
      <param name="Port" value="4445"/> 
      
    </plugin>
    
    <root> <level value="debug"/> </root> 
    
  </log4j:configuration>
  
  and name it e.g. config.xml. Then start Chainsaw like

  java -Dlog4j.debug=true -Dlog4j.configuration=config.xml \
  
    -classpath ".:log4j-1.3alpha.jar:log4j-chainsaw-1.3alpha.jar" \
    
    org.apache.log4j.chainsaw.LogUIand watch the GUI coming up.
    

Configure Log::Log4perl to use a socket appender with an XMLLayout, pointing to the host/port where Chainsaw (as configured above) is waiting with its XMLSocketReceiver: 

  use Log::Log4perl qw(get_logger);
  
  use Log::Log4perl::Layout::XMLLayout;  my $conf = q(
  
    log4perl.category.Bar.Twix          = WARN, Appender
    
    log4perl.appender.Appender          = Log::Log4perl::Appender::socket
    
    log4perl.appender.Appender.PeerAddr = localhost
    
    log4perl.appender.Appender.PeerPort = 4445
    
    log4perl.appender.Appender.layout   = Log::Log4perl::Layout::XMLLayout
    
  );  
  
  Log::Log4perl::init(\$conf);
  

=head2 XML Document Type Definition 

E<lt>!ELEMENT log4j:eventSet (log4j:event*)E<gt>

E<lt>!ATTLIST log4j:eventSet

  includesLocationInfo   (true|false) "true"

E<gt>

E<lt>!ELEMENT log4j:event (log4j:message, log4j:NDC?, log4j:throwable?, log4j:locationInfo?) E<gt>

E<lt>!-- The timestamp format is application dependent. --E<gt>

E<lt>!ATTLIST log4j:event
    logger     CDATA #REQUIRED
    priority   CDATA #REQUIRED
    thread     CDATA #REQUIRED
    timestamp  CDATA #REQUIRED
E<gt>

E<lt>!ELEMENT log4j:message (#PCDATA)E<gt>

E<lt>!ELEMENT log4j:NDC (#PCDATA)E<gt>

E<lt>!ELEMENT log4j:throwable (#PCDATA)E<gt>

E<lt>!ELEMENT log4j:locationInfo EMPTYE<gt>

E<lt>!ATTLIST log4j:locationInfo

  class  CDATA	#REQUIRED
  
  method CDATA	#REQUIRED
  
  file   CDATA	#REQUIRED
  
  line   CDATA	#REQUIRED

E<gt>

=head1 INSTALLATION

To install this module type the following:

   perl Makefile.PL
   
   make
   
   make test
   
   make install

=head1 KNOWN BUGS

Some older versions of chainsaw use a different DTD. Consequently, these versions do not display
log events generated via XMLLayout.

=head1 AUTHOR


        Guido Carls <gcarls@cpan.org>

=head1 COPYRIGHT AND LICENCE


Copyright (C) 2003 G. Carls

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Log::Log4perl>


