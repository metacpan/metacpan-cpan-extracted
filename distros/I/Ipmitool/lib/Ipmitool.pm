package Ipmitool;

use 5.010000;
use strict;
use warnings;
use Net::Ping;
use Data::Dumper;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Ipmitool ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.02';

our %FRU;
# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.
sub new
{
	my $class = shift;
	my $self = {};
	bless($self,$class);
	$self->_init(@_);
	return ($self);
}

sub remove_spaces
{
	my $string = shift;
	chomp($$string);
	$$string =~ s/^\s+//; #remove leading spaces
	$$string =~ s/\s+$//; #remove trailing spaces
	#print "String passed: $string\n";
}

sub fru
{
	my $self = shift;
	my $h = $self->{"ipaddress"};
	my $u = $self->{"username"};
	my $p = $self->{"password"};
	open PASSFILE, ">file" or die "Unable to create password file\n";
	print PASSFILE "$p";
	close(PASSFILE);
	system("ipmitool -H $h -U $u -f file fru > .fru.out");
	if ( $? == -1 )
	{
		print "command failed: $!\n";
	}else
	{
		printf "command exited with value %d\n", $? >> 8;
	}

	open FRU,".fru.out" or die "Unable to open .fru.out file\n";

	my @fru_line_numbers;
	while(<FRU>)
	{
		if(/FRU Device Description/)
		{	
			push(@fru_line_numbers,$.);	
			my @a1 = split(":");
			chomp($a1[1]);
			#print "element $a1[1]\n";
			my @a2 = split(/[()]/,$a1[1]);
			#print "name : $a2[1]\n";
			my $fruname = $a2[0];
			my $id = $a2[1];
			$id =~ s/ID//g;
			print "$. fruname : $fruname and ID is : $id\n";	
		}
	}
	close(FRU);
	
	for (my $j=0;$j<$#fru_line_numbers;$j=$j+1)
	{
		create_fru_hash(\$self,$fru_line_numbers[$j], $fru_line_numbers[$j+1]);
	}
	
	#print Dumper(\%FRU);
	return ( %FRU );
}

sub find_records
{
	my $start = shift;
	my $end = shift;
	my $array1 = shift;
	my $flag = 0;
#print "start : $start and end is : $end\n";
	open FRU1,".fru.out" or die "Unable to open .fru.out file\n";
	while(<FRU1>)
	{
		if (($. > $start) && ($. < $end))
		{
			if ( ! (/:/ | /^\s*$/) )
			{
				push(@$array1,$.);
				$flag = 1;
			}
		}
	}
	close(FRU1);
	return($flag);
}

sub create_fru_hash
{
	my $self = shift;
	my $start = shift;
	my $end = shift;
	my $temp_fru_name;
	
	print "start : $start and end : $end\n";
	
	my @rec_line_numbers;
	my $ret= find_records($start,$end,\@rec_line_numbers);
	foreach(@rec_line_numbers)
	{
		print "line numbers: $_\n";
	}	
	open FRU,".fru.out" or die "Unable to open .fru.out file\n";
	
	if ( $ret == 1 )
	{
		my $backup_end = $end;
		$end = $rec_line_numbers[0];
	}	
	while(<FRU>)
	{
		if ( ($. >= $start) && ($. < $end) )
		{
			if(! /^\s*$/)	
			{
				#print $_;
				if ( /FRU Device Description/ )
				{
					my @a1 = split(":");
            		chomp($a1[1]);
            		my @a2 = split(/[()]/,$a1[1]);
					$temp_fru_name = $a2[0];	
					remove_spaces(\$temp_fru_name);
            		my $id = $a2[1];
            		$id =~ s/ID//g;
					remove_spaces(\$id);
					$FRU{$temp_fru_name}{ID} = $id;
				}else
				{
					#print "inside else : $_\n";
					my @a1 = split(":");
					#print "$a1[0] : $a1[1]\n";
					remove_spaces(\$a1[0]);
					remove_spaces(\$a1[1]);
					$FRU{$temp_fru_name}{$a1[0]} = $a1[1];
				}
				
			}
		}
	}	
	if($ret == 1)
	{
	seek(FRU,0,0);
	for(my $i = 0; $i<$#rec_line_numbers; $i++)
	{
		print "inside for loop \n";
		add_sub_record($temp_fru_name,$rec_line_numbers[$i],$rec_line_numbers[$i+1]);
	}
	}
close(FRU);
}

sub add_sub_record
{
	my $fruname = shift;
	my $start = shift;
	my $end = shift;
	my $rec_name;	

	open F1, ".fru.out" or die "Unable to open .fru.out file\n";
	#print "inside add_sub_record func $fruname $start : $end\n";	
	while(<F1>)
	{
		if ( $. == $start )
		{
			$rec_name = $_;
			remove_spaces(\$rec_name);	
			#print "rec_name : $rec_name\n";
		}
		if ( ($. > $start ) && ( $. < $end ) )
		{
			#print "inside if block\n";
			my @a1 = split(":");
			remove_spaces(\$a1[0]);
			remove_spaces(\$a1[1]);
			#print "$fruname : $rec_name : $a1[0] : $a1[1]\n";
			$FRU{$fruname}{$rec_name}{$a1[0]} = $a1[1];
		}
	}
	close(F1);
}	

sub print
{
	my $self= shift;
	foreach (keys (%{$self}))
	{
		print "$_: $self->{$_}\n"
	}
	#print "IP Address : $self->{ipaddress}\n" if (defined($self->{ipaddress}));
	#print "Username : $self->{username}\n" if (defined($self->{username}));
	#print "Password : $self->{password}\n" if (defined($self->{password}));
	return 0;
}

sub bmc
{
	my $self = shift;
	my $cmd = shift;
	my @op = `ipmitool -H $self->{ipaddress} -U $self->{username} -f file bmc $cmd`;
	#print @op;
	foreach(@op)
	{
		print "$_";
	}
}

sub _init
{

my ($self,@args)=@_;
while (@args)
{
	my ($x);
	($x)=shift(@args);
	if ($x eq "-ipaddress")
	{
		$self->{"ipaddress"}=shift(@args);
		my $p = Net::Ping->new();
		if (!$p->ping($self->{"ipaddress"}))
		{
			#print " Machine is alive\n";
			die "$self->{ipaddress} : invalid ip address or machine is unreachable\n";
		}
		$p->close();
	} elsif ($x eq "-username")
	{
		$self->{"username"}=shift(@args);
	} elsif ($x eq "-password")
	{
		$self->{"password"}=shift(@args);
		open PASSFILE, ">file" or die "Unable to create password file\n";
        	print PASSFILE "$self->{password}";
	        close(PASSFILE);
	} else
	{
		die "Invalid argument : $x\n";
	} 
}

return(0);

}


# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Ipmitool - Perl interface to the ipmitool.

=head1 SYNOPSIS

  use Ipmitool;
  use Data::Dumper;
  $i = Ipmitool->new(-ipaddress => "10.8.151.179", -username => "root", -password => "changeme");
  $i->print();
  %FRU = $i->fru();
  print Dumper($i);
  $i->bmc("info");

=head1 DESCRIPTION

Ipmitool module lets you manage Intelligent Platform Management Interface (IPMI) functions of either the local system, via a kernel device driver, or a remote system, using IPMI V1.5 and IPMI v2.0. These functions include printing FRU information, LAN configuration, sensor readings, and remote chassis power control. 

=head1 METHODS

=head2 new()

This function will create object of ipmitool class, takes ipaddress, username, password as a input paramter

=head2 fru()

This function will access perticular machine's fru information and returns the FRU HASH.

=head2 bmc()

This function prints the bmc information of the machine.


=head1 SEE ALSO

http://ipmitool.sourceforge.net/manpage.html

=head1 AUTHOR

Manjunath Kumatagi, E<lt>manjunath.kumatagi@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Manjunath Kumatagi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
