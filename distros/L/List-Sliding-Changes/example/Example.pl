use strict;
use SlidingList::Changes qw(find_new_elements);
use Tie::File;

my $filename = 'log.txt';
tie my @log, 'Tie::File', $filename
  or die "Couldn't tie to $filename : $!\n";

# See what has happened
my @status = get_last_20_status_messages();

# Find out what we did not already communicate
my (@new) = find_new_elements(\@log,\@status);
print "New log messages : $_\n"
  for (@new);

# And update our log with what we have seen
push @log, @new;

sub get_last_20_status_messages {
  use POSIX;
  my ($timestamp) = strftime("%H%M",localtime());
  reverse map { "$timestamp:$_" } ("These are some new messages","Which you didn't see already","These are some old messages","Which you already saw")
};