package Mail::Stats;

use strict;
use vars qw($VERSION);

use Carp;
use Mail::Stats::Record;
use Mail::Stats::Parser;
use Mail::Stats::Config;

$VERSION = '0.02';

sub newmail {
  my $cfg = shift;
  my $c = new Mail::Stats::Config($cfg);
  
  if(!defined($c->{sort}) or scalar(@{$c->{mboxen}}) < 1) {
    return undef;
  }

  my $hash;
  
  for my $mbox (@{$c->{mboxen}}) {
    open(IN,$mbox) or croak("$0: could not open file $mbox - $!\n");
    $hash->{$mbox} = Mail::Stats::Parser::parse(\*IN);
    close(IN);
  }
  
  for my $mbox (sort {&{$c->{sort}}($hash)} keys %$hash) {
    my $short = $mbox;
    my $count = $hash->{$mbox}->num_unread();
    if($c->{showall} or $count) {
      $short =~ s/.*\///;
      my $message = $c->{message};
      $message =~ s/%% mbox %%/$short/;
      $message =~ s/%% count %%/$count/;
      print $message;
    }
  }

  return 1;
  # print STDERR Dumper($hash);
}

1;
__END__

=head1 NAME

Mail::Stats - Perl module for getting quick statistics on procmail generated
mailbox files.

=head1 SYNOPSIS

  use Mail::Stats;

=head1 DESCRIPTION

This is the beginning of a quick and dirty mbox statistics program.  It
will be very reworked over the next many moons.  Hopefully it is mildly
useful in its current format.

More documentation would be here, but I am getting on a plane to another
country, and would like to get something out in an alpha state before I
leave.

=head1 AUTHOR
 
  Sean Dague
  sean@dague.net
  http://dague.net/sean

=head1 SEE ALSO

perl(1).

=cut
