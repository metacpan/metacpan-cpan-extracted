# Mail::AddressSort
# Sorts an array of  email addresses 
# for the purpose of expediting delivery of multiple recipients

#
# Package Definition
#

package Mail::AddressSort;

#
# Compiler Directives
#

use strict;

#
# Global Variables
#

use vars qw/$VERSION/;

$VERSION=1.0;

#
# Subroutines
#

# Constructor method
sub new
{
my ($class)=shift;
my ($object);
$object={};
bless ($object);
return($object);
}

# Add addresses to the list
sub input
{
my ($self)=shift;
my ($addr,$parsed);
while (@_)
{
	($addr)=shift;
	$parsed=_sortFmt($addr);
	$self->{list}->{$parsed}=$addr;
}
return();
}

# Return all addresses in one sorted array
sub sorted
{
my ($self)=shift;
my ($key,@array);
foreach $key (sort(keys(%{$self->{list}})))
{
	push(@array,$self->{list}->{$key});
}
return(@array);
}

# Return a count of the number of addresses in the list
sub count
{
my ($self)=shift;
return scalar(keys(%{$self->{list}}));
}

# Return all addresses in an array of arrays limited by a
# maximun number of addresses per array and also by domain if necessary

sub batches
{
my ($self)=shift;
my ($arg,$max,$hostSplit,$count,$batchNum,$host,$lastHost,$address
	,$out,@list,$batches);
while (@_)
{
	($arg)=shift;
	if ($arg eq "-maxRecipients")
	{
		$max=shift;
		print("MaxRecp passed as $max\n");
	} elsif ($arg eq "-byHost")
	{
		$hostSplit=1;
	}
}
if ($max <=0)
{
	my ($num)=$self->count();
	if ($num < 100)
	{
		$max=int($num/5);
		$max++ if ($max ==0);
	} else {
		$max=100;
	}
}
print("MaxRecp set to $max\n");
$max++;
$batches=[];
$count=1;
$batchNum=1;
foreach $address (sort(keys(%{$self->{list}})))
{
	$out=$self->{list}->{$address};
	($host)=split(/\@/,$address);
	$lastHost=$host unless ($lastHost);
	if ($count == $max || ($host ne $lastHost && $hostSplit))
	{
		push(@{$batches},[ @list ]);
		(@list)=();
		$batchNum++;
		$count=1;
	}
	push(@list,$out);
	$count++;
	$lastHost=$host;
}
if (@list)
{
	push(@{$batches},[ @list ]);
}
return($batches);
}

sub printBatches
{
my ($self,$batch,$number)=@_;
my ($sub,$count,$size,$addr);
if ($number)
{
	_printBatch($batch,$number);
} else {
	$count=scalar(@{$batch});
	for ($sub=1;$sub<=$count;$sub++)
	{
		_printBatch($batch,$sub);
	}
}
return;
}

sub printHostCount
{
my ($self)=shift;
my (%report,$host,$domain);
(%report)=$self->_hostCount();
foreach $host (sort(keys(%report)))
{
	$domain=join(".",reverse(split(/\./,$host)));
	printf("%5d %-40s\n",$report{$host},$domain);
}
return;
}

#
# Hidden Subroutines
#

sub _sortFmt
{
my ($addr)=shift;
my ($parsed,$user,$domain,@dp,@rdp);
($user,$domain)=split(/\@/,$addr);
($domain)=lc($domain);
(@dp)=split(/\./,$domain);
$parsed=join(".",reverse(@dp))."\@".$user;
return($parsed);
}

sub _printBatch
{
my ($batch,$number)=@_;
my ($count,$size,$address);
$count=$#$batch;
return undef if ($number < 1 || $ number > $count);
$size=scalar(@{$batch->[$number-1]});
print("Batch $number of $count ($size entries)\n");
foreach $address (@{$batch->[$number-1]})
{
	print("\t$address\n");
}
return;
}

sub _hostCount
{
my ($self)=shift;
my ($entry,$domain,%count);
foreach $entry (keys(%{$self->{list}}))
{
	($domain)=split(/\@/,$entry);
	$count{$domain}++;
}
return(%count);
}

#
# Exit Area
#
1;

__END__

#
# POD Documentation
#

=head1 NAME

Mail::AddressSort   Sort an array of email addresses

=head1 SYNOPSIS

$list=Mail::AddressSort->new();

$list->input(@addresses);

(@addresses)=$list->sorted();

$batch=$list->batches(-maxRecipients => [int] , -byHost);

=head1 DESCRIPTION

Mail::AddressSort is useful for sorting large lists of email addresses.  A
Mail::AddressSort object is capable of taking an array of email addresses and 
returning it in either a single sorted list, or an array reference to array 
references that contain of the same list broken down into smaller batches.

The email addresses are sorted by taking a reverse of the fully qualified 
domain name instead of just using the literal string.  This can be helpful in 
sorting the list by mailhosts.

For example, the following email addresses:

cpj1@visi.com, 
chrisj@MR.Net

are reversed for the purposes of sorting to:

com.visi@cpj1, 
net.mr@chrisj

=head1 METHODS

=over 4

=item $list=Mail::AddressSort->new();

Creates a new AddressSort object.

=item $list->input([addresses]);

Adds addresses to the internal table.

=item (@array)=$list->sorted();

Returns a single list of addresses sorted out.

=item $size=$list->count();

Returns the number of addresses in the list.

=item $batch=$list->batches(-maxRecipients -> [int], -byHost);

Returns a pointer to an array.  Each element in the array is an annonymous 
array containing sorted email addresses from the list.  Each list will be 
no larger than the value passed in the -maxRecipients arguement.

The -maxRecipients option will automatically be set if it isn't specified.  If 
the number of addresses in the list is less than 100, it will be set to 1/5th of 
that number.  If the number of addresses is over 100, it will be set to 100.

If -byHost is specified, each list in the array will only contain email 
addresses with a matching FQDN.

=item $list->printBatches($batch,$index);

Prints out a report of the contents of batch array (created from the 
$list->batches method).  If $index is specified, it will only print 
a list of addresses associated with that particular batch.

=item $list->printHostCount();

Prints a list of all hosts with the number of addresses associated with 
that host.

=back

=head1 AUTHOR

Chris Josephes (chrisj@mr.net)

=head1 VERSION

Version 1.0
