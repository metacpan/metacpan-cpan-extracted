package Mail::Stats::Record;

use strict;

use vars qw($VERSION);

$VERSION = '0.1';

sub new {
  my $class = shift;
  my $this = {
	      MESSAGES => 0, # Number of messages
	      STATUS => {
			 R => 0,
			},  # Hash of statuses
	      PARSED => 0,   # Has this been parsed yet?
	     };
  
  return bless $this, $class;
}

sub num_read {
  my $this = shift;

  return $this->{STATUS}->{R};
}

sub num_unread {
  my $this = shift;
  
  return $this->{MESSAGES} - $this->{STATUS}->{R};
}

sub num_status {
  my ($this, $status) = @_;

  return $this->{STATUS}->{$status};
}

sub num_not_status {
  my ($this, $status) = @_;

  return $this->{MESSAGES} - $this->{STATUS}->{$status};
}

1;

__END__

=head1 NAME

Mail::Stats::Record - Perl module for holding stats about a mailbox

=head1 SYNOPSIS

  use Mail::Stats::Record;

=head1 DESCRIPTION



=head1 AUTHOR
 
  Sean Dague
  sean@dague.net
  http://dague.net/sean

=head1 SEE ALSO

perl(1), Mail::Stats

=cut
