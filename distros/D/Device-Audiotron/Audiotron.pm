package Device::Audiotron;

require 5.6.0;
require Exporter;
our @ISA = qw(Exporter);

$VERSION = '1.02';

use strict;
use Carp;
use vars qw($VERSION @ISA);
use LWP 5.64 qw(UserAgent);


#Copyright (c) 2002 Dave Crawford. All rights reserved.
#This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

sub new
	{
	my $class = shift;
	my $self = {};
	($self->{ip},$self->{user},$self->{pass}) = @_;
	bless $self,$class;
	return($self);
	}

sub GetInfo
	{
        my ($self,$type, $count, $criteria) = @_;
        my ($url, $fetched, @array);
        
        $url = "http://$self->{ip}/apigetinfo.asp?type=$type";
        if($count){$url .= "&count=$count";}
        if($criteria){$url .= "&this=" . $criteria;}

	$fetched = $self->_FetchURL($url);
	return($fetched);
        }
        
sub Qfile
	{
        my ($self, $type, $criteria) = @_;
        my ($url, $fetched);
        
        $url = "http://$self->{ip}/apiqfile.asp?type=$type&file=$criteria";
        
	$fetched = $self->_FetchURL($url);
	return($fetched);
	}
	
sub AddFile
	{
	my ($self, $file) = @_;
        my ($url, $fetched);

	$url = "http://$self->{ip}/apiaddfile.asp?type=file&file=$file";
	
	$fetched = $self->_FetchURL($url);
	return($fetched);
	}

sub Cmd
	{
	my ($self, $cmd, $arg) = @_;
        my ($url, $fetched);
	
	$url = "http://$self->{ip}/apicmd.asp?cmd=$cmd";
	if($arg){$url .= "&arg=$arg";}
	
	$fetched = $self->_FetchURL($url);
	return($fetched);
	}

sub GetStatus
        {
        my $self = shift;
        my ($url, $fetched, $h_name, $h_value, %status);
        
        $url = "http://$self->{ip}/apigetstatus.asp";

	$fetched = $self->_FetchURL($url);
	my @array = split /\n/,$fetched;
	foreach(@array)
		{
		if((/^\[(End )?Status\]/) || !(/=/)){next;}
		chomp();
		($h_name, $h_value) = split(/\s*=\s*/,$_,2);
		$status{$h_name} = $h_value;
		}
	return(%status);
        }
        
sub GlobalInfo
        {
        my $self = shift;
        my ($url, $fetched, $h_name, $h_value, %tmp_hst, %status, @shares, @hosts);
        my ($hst_cnt, $shr_flag, $hst_flag) = 0;
        
        $url = "http://$self->{ip}/apigetinfo.asp?type=global";

	$fetched = $self->_FetchURL($url);
	
	my @array = split /\n/,$fetched;
	foreach(@array)
		{
		if(/^\[(End )?Global\]/){next;}
		if(/^\[Share List\]/){$shr_flag=1;next;}
		if(/^\[End Share List\]/){$shr_flag=0;next;}
		if(/^\[Host List\]/){$hst_flag=1;next;}
		if(/^\[End Host List\]/){$hst_flag=0;next;}
		if(/^\[End Host\]/){push(@hosts,{%tmp_hst});next;}
		if(!(/=/)){next;}
		
		chomp();
		
		($h_name, $h_value) = split(/\s*=\s*/,$_,2);
		
		if($shr_flag)
			{
			push(@shares, $h_value);
			}
		elsif($hst_flag)
			{
			$tmp_hst{$h_name} = $h_value;
			}
		else
			{
			$status{$h_name} = $h_value;
			}
		}
	return(\%status, \@shares, \@hosts);
        }

sub Msg
	{
	my ($self, $line1, $line2, $tmout) = @_;
        my ($url, $fetched);
	
	$url = "http://$self->{ip}/apimsg.asp?line1=$line1&line2=$line2";
	if($tmout){$url .= "&timeout=$tmout";}

	
	$fetched = $self->_FetchURL($url);
	return($fetched);
	}

sub DumpToc
	{
	my ($self, $share) = @_;
        my ($url, $fetched);
	
	$url = "http://$self->{ip}/apidumptoc.asp?share=$share";
	
	$fetched = $self->_FetchURL($url);
	return($fetched);
	}



## internal "helper" routines ##

sub _FetchURL
	{
	my ($self, $url) = @_;
	my ($ua, $request, $response);
	
        $ua = LWP::UserAgent->new();
        $ua->agent("Device::Audiotron 1.01");
        $request = HTTP::Request->new('GET', $url);
        $request->authorization_basic($self->{user}, $self->{pass});
	
        $response = $ua->request($request);

        if($response->is_success)
                {
		return($response->content());
		}
        else
                {
                croak("[HTTP " .  $response->code() . " Error] ");
                }
	}

1;

__END__

=pod
=head1 NAME
Device::Audiotron - Perl module to interface with the Audiotron API.

=head1 SYNOPSIS

use Device::Audiotron;
$at = new Device::Audiotron("Audiotron IP address","username","password");
if(!$at){die "Audiotron object failed to initialize.";}

my ($ref_status, $ref_shares, $ref_hosts) = $at->GlobalInfo();
my $firmware_version = $ref_status->{"Version"};

=head1 DESCRIPTION

Device::Audiotron provides a tie-in into the API included in the latest firmware for Voyetra Turtle Beach's Audiotron.

I highly suggest reading through the API documentation located at http://www.turtlebeach.com/site/products/audiotron/api/dl_api.asp before attempting to implement this module. 

The available methods for the Audiotron object and an example of usage for each are listed below. The native API call is listed in brackets below each method for informational purposes and for ease in referencing Voyetra's API documentation.
   
   
   GetInfo(Type,[Count],[Criteria])
   [Apigetinfo.asp]
   
	Returns a string containing the results from the command request.   
	
	$type = "Global";
	$info = $at->GetInfo($type);
	
	OR
	
	$type = "artist";
	$count = 4;
	$criteria = "Staind";
	$info = $at->GetInfo($type,$count,$criteria);
	

   Qfile(Type,Criteria)
   [Apiqfile.asp]

	Returns a string containing the results from the command request.   

	$type = "File";
	$file = q|\\\\LITHIUM\MP3\Bush\deconstructed\Comedown.mp3|;
	$cmd_result = $at->Qfile($type, $file);


   AddFile(Full_File_Name)
   [Apiaddfile.asp]
   
	Returns a string containing the results from the command request.

	$file = q|\\\\COBALT\MP3\new_song.mp3|;
	$cmd_result = $at->AddFile($file);


   Cmd(Command,[Arg])
   [Apicmd.asp]
   
	Returns a string containing the results from the command request.
	
	$cmd_name = "play";
	$cmd_result = $at->Cmd($cmd_name);
	
	OR
	
	$cmd_name = "goto";
	$cmd_arg = "18";
	$cmd_result = $at->Cmd($cmd_name, $cmd_arg);


   GetStatus()
   [Apigetstatus.asp]
   
   	Returns a hash containing element names equivalent to the 'field' names returned by the Audiotron.

   	%status = $at->GetStatus();
   	print $status{'State'};


   GlobalInfo()
   [See GetInfo]
   
   	Returns references to a hash, an array, and an array of hashes.
   	
	This is simply a call to GetInfo with "Global" passed as the type but has been customized to pre-parse the results.
	
	  ($ref_status, $ref_shares, $ref_hosts) = $at->GlobalInfo();
	
   	In the above example '$ref_status' is a reference to a hash containing element names equivalent to the 'field' names returned from the "status" portion of the results. So for example, to get the version number of the firmware:
   	
   	  $firmware_version = $ref_status->{"Version"};
   	
   	Next, $ref_shares is a reference to an array where each element contains the UNC name for the share as listed in the Audiotron.
   	
   	Lastly, $ref_hosts is a reference to an array of hashes, one hash per host known by the Audiotron. Each hash in the array contains three elements named 'Host','IP', and 'State'. So for example, to get the IP address of the first host in the array:
   	
   	  $ip_add = $ref_hosts->[0]->{"IP"};


   Msg(Text_line1,[Text_line2],[Timeout])
   [Apimsg.api]
   
   	Returns a string containing the results from the command request.
   	
   	$line1 = "This is a test.";
	$line2 = "Just Another Perl Hacker";
	$time_out = "5";
	$cmd_result = $at->Msg($line1, $line2, $time_out);
	

   DumpToc(Share_name)
   [Apidumptoc.asp]
   
   	Returns a (sometimes huge!) string containing the results from the command request.
   
	$share = q|\\\\LITHIUM\MP3|;
	$toc = $at->DumpToc($share);
	
	NOTE:
	This is here just as a 'placeholder', newer versions will allow the output to be written to a file instead of be handed back as a string. Very inefficient in it's current form.
   
   

   Copyright (c) 2002 Dave Crawford. All rights reserved.
   This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

=head1 EXPORT

None by default.

=head1 AUTHOR

Dave Crawford, crawford@dcrawford.com
=cut
