package Linux::DVB::DVBT::Apps::QuartzPVR::Mail ;

=head1 NAME

Linux::DVB::DVBT::Apps::QuartzPVR::Mail - Mail utils

=head1 SYNOPSIS

use Linux::DVB::DVBT::Apps::QuartzPVR::Mail ;


=head1 DESCRIPTION


=head1 DIAGNOSTICS

Setting the debug flag to level 1 prints out (to STDOUT) some debug messages, setting it to level 2 prints out more verbose messages.

=head1 AUTHOR

Steve Price 

=head1 BUGS

None that I know of!

=head1 INTERFACE

=over 4

=cut

use strict ;
use Carp ;

our $VERSION = "1.000" ;

#============================================================================================
# USES
#============================================================================================
use Data::Dumper ;

use Linux::DVB::DVBT::Apps::QuartzPVR::Report ;


#============================================================================================
# GLOBALS
#============================================================================================

our $debug = 0 ;

our $opts_href ;


#============================================================================================
# OBJECT METHODS 
#============================================================================================

BEGIN {
	
	$opts_href = {
		'to'		=> 'quartz@quartz-net.co.uk',
		'tvreport'	=> undef,
	} ;
	
}

#---------------------------------------------------------------------
# Set options 
sub set
{
	my (%options) = @_ ;

#print "Crontab::set()\n" ;
	foreach my $opt (keys %options)
	{
		$opts_href->{$opt} = $options{$opt} ;

#print " $opt = $options{$opt}\n" ;
	}
	
	$debug = $options{'debug'} if exists($options{'debug'}) ;
}


#---------------------------------------------------------------------
sub mail_error
{
	my ($subject, $error) = @_ ;
	
	my $data = "echo '$error'" ;
	my $tmpfile ;
	if ($opts_href->{'tvreport'})
	{
		my $tvreport = $opts_href->{'tvreport'} ;
		my $report = $tvreport->create_report() ;
		$tmpfile = "/tmp/report.$$" ;
		if (open my $fh, ">$tmpfile")
		{
			print $fh "$error\n\n" ;

			print $fh $report ;
			close $fh ;
			$data = "cat $tmpfile" ;	
		}
		else
		{
			$tmpfile = undef ;
		}
	}

	# send mail
	`$data | mail -s '$subject' $opts_href->{'to'}` ;
	
	# clean up
	unlink $tmpfile if $tmpfile ;
}



# ============================================================================================
# END OF PACKAGE

=back

=cut

1;

__END__


