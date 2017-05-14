package HTCondor::Queue::Parser;

use strict;
use warnings;
use XML::Simple;
use JSON::XS;

# ABSTRACT: parses multible schedds condor_q output, so you don't have to. Serves output in many formats. 

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	return $self;
}

my %schedds_map;
my $schedd;
my @submitter_xml;

sub load_schedds_xml {
	my $self = shift;
	my $condor_q = shift;
	my @text = @{$condor_q};
	my %schedds_map;
	my $schedd;
	
	
	die("Got no input. Check condor_q -xml output") if (scalar(@text) < 1);

	foreach my $line (@text) {
	
		if ($line =~ m/^--.*Schedd\:(.*)\s\:(.*)/) {
			# $2 is useful but not used -- IP
			$schedd = $1;
		}
		if ($line =~ m/\<classads\>/) {
			# New scheed, record previous in the map and reset everything
			$schedds_map{$schedd}{'xml'} = \@submitter_xml;
			@submitter_xml = ();
		}
		push(@submitter_xml, $line);
	}	
	return %schedds_map;
}
sub convert_to_compatible_xml {
	my $self = shift;
	my $schedds_map_href = shift;
	my %schedds_map = %{$schedds_map_href};

	foreach my $schedd (keys %schedds_map) {
		
		die("There's no XML in the provided schedds_map , verify") if not $schedds_map{$schedd}{'xml'};
		my @real_xml=();

		 foreach my $line  (@{$schedds_map{$schedd}{'xml'}}) {
			 chomp $line;	
			 
			 #</x509userproxy>    <a n="GridMonitorJob"><b v="t"/></a> <GratiaJobOrigin>
			 # <a n="TargetType"><s>Machine</s></a>
			 if ( $line =~ m/\<a.*n\=\"(.*)\"\>\<.*\>(.*)\<.*\>\<\/a\>/ ) {
				 push(@real_xml, "<$1> $2 </$1>" );
			 }
			 elsif ($line =~ m/\<a.*n\=\"(.*)\"\>\<b v\=\"(.)\"\/\>\<\/a\>/) {
				 push(@real_xml, "<$1> $2 </$1>" );
			 }
			 else {
				push (@real_xml, $line);
			 }
		 }

		$schedds_map{$schedd}{'xml'} = \@real_xml;
		# Check if there's any big difference on using the 
		# Below or not, and how compatible it is with the API
		# my $job_data = XMLin($xml);
		# $self->{'schedds_map'}{$schedd}{'href'} = $job_data;	
	}
	return %schedds_map;
}

sub xml_to_hrefs{
	my $self = shift;
	my $schedds_map_href = shift;
	my %schedds_map = %{$schedds_map_href};
	
	foreach my $schedd (keys %schedds_map) {
		die ('Provide an xml in %schedds_map{$schedd}{xml} ') if not defined $schedds_map{$schedd}{'xml'} ;
		my $xml = "@{$schedds_map{$schedd}{'xml'}}";
		my $job_data = XMLin($xml);
		$schedds_map{$schedd}{'href'} = $job_data;	
	}
	return %schedds_map;
}

sub schedd_json {
	my $self = shift;
	my $schedds_map_href = shift;
	my $schedd = shift;
	my %schedds_map = %{$schedds_map_href};
	
	die("Which schedd?") if not $schedd;
	die('Come on, ask me something that exists, populate $schedds_map{$schedd}') if not $schedds_map{$schedd}{'href'};
	my $coder = JSON::XS->new->ascii->pretty->allow_nonref;
	my $json = $coder->encode($schedds_map{$schedd}{'href'});
	return $json;
}


1;


__END__

=pod

=head1 NAME

HTCondor::Queue::Parser 

=head1 SYNOPSIS

  my $cparser = HTCondor::Queue::Parser->new();
  
  my @condor_q =  read_file( 't/input.txt' ) ; # Text file with condor_q -global or condor_q output
  
  my %schedds_map = $cparser->load_schedds_xml(\@condor_q);
  
  foreach my $schedd (keys %schedds_map) {
        # This allows you to have simplified XMLs per schedd, that won't break XML parsers.
        # Default condor_q -global -l -xml does not outputs an 
        my $simple_xml = $schedds_map{$schedd}{'xml'};
        
  }

=head1 INITIAL RELEASE WARNING

This is the first 'working' version that was decent enough to upload to CPAN. You might find problems as 
it was not fully reviewed or tested by other people. Reviews and bug reports are welcome at :

	https://github.com/samircury/HTCondor--Queue--Parser/issues 
 
=head1 DESCRIPTION

Outputs condor queue's jobs different ways : Simpler XML per schedds, JSON

HTCondor's default output looks like :

  <c>
     <a n="MyType"><s>Job</s></a>
     <a n="TargetType"><s>Machine</s></a>
     <a n="PeriodicRemove"><b v="f"/></a>
     <a n="CommittedSlotTime"><i>0</i></a>
     <a n="Out"><s>_condor_stdout</s></a>
  </c> # Fake line -- truncated for the example
   
Converted, simpler XML from this module looks like more :

  <?xml version="1.0"?>
  <classads>
    <c>
      <MyType> Job </MyType>
      <TargetType> Machine </TargetType>
      <ClusterId> 790960 </ClusterId>
      <QDate> 1312487190 </QDate>
      <CompletionDate> 0 </CompletionDate>
      <Owner> uscmsPool1639 </Owner>
      <LocalUserCpu> 0.000000000000000E+00 </LocalUserCpu>
      <LocalSysCpu> 0.000000000000000E+00 </LocalSysCpu>
      <ExitStatus> 0 </ExitStatus>
      <NumCkpts_RAW> 0 </NumCkpts_RAW>
      <NumCkpts> 0 </NumCkpts>
      <NumRestarts> 0 </NumRestarts>
      <NumSystemHolds> 0 </NumSystemHolds>
      <CommittedTime> 0 </CommittedTime>
    </c> # Fake line -- truncated for the example
  </classads> # Fake line -- truncated for example


=head1 METHODS

=head2 new
	
	# This will only create the object then you can play with it later (see other methods)
	my $cparser = Condor::QueueParser->new();
	

=head2 load_schedds_xml

	# Here one should load the RAW output from $(condor_q -global -l -xml) it will spit a non-XML format and be converted later.
	$cparser->load_schedds_xml(\@condor_q);
	# What it does under the hood, is to get REAL XML for each schedd that the condor_q will present.
	# $cparser->{'schedds_map'}  will be then loaded with a key per schedd, which contains the {'xml'} already

=head2 convert_to_compatible_xml

Before this method runs, {xml} will contain the standard condor XML :

	<classads><c>   <a n="MyType"><s>Job</s></a>  

Afterwards, it will contain what I call "more compatible" XML :

	<classads>  <c> <MyType> Job </MyType> <TargetType> Machine </TargetType> 

=head2 xml_to_hrefs

This one should get the content of $self->{'schedds_map'}{$schedd}{'xml'} and populate $self->{'schedds_map'}{$schedd}{'href'} 
with a Perl equivalent multilevel hash, which will be the native format to Perl information, and you can use it in your application

=head2 schedd_json

Maybe the most useful way to use it is :

	foreach my $schedd (keys %{$cparser->{'schedds_map'}}) {
		my $json = $cparser->schedd_json($schedd);
		# do something with $json;
	}

=head1 SUPPORT

You will have more luck at https://github.com/samircury/HTCondor--Queue--Parser/issues 

The CPAN's tracking system is also an option.

=head1 AUTHOR

Copyright 2014 Samir Cury.

=cut
