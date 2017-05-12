use Test::More tests => 2;
use Test::Deep;
use Data::Dumper;
$Data::Dumper::Deparse=1;
use IO::Handle::Record;
use IO::Pipe;
use IO::Select;
use Errno qw/EAGAIN/;

#########################

my ($p, $c)=(IO::Pipe->new, IO::Pipe->new);
my $pid;
while( !defined( $pid=fork ) ) {select undef, undef, undef, .1}

if( $pid ) {
  $p->reader; $c->writer;
  my $got;
  my $msg=Storable::nfreeze( [1, 2] );
  $msg=pack( "N2", length($msg), 0 ).$msg;
  for( my $i=0; $i<length $msg; $i++ ) {
    $c->syswrite( $msg, 1, $i );
    select undef, undef, undef, 0.1;
  }
  my $again;
  ($got, $again)=$p->read_record;
  cmp_deeply $got, [1, 2], 'nonblocking read';

  cmp_deeply $again, code(sub{$_[0]>0 ? 1 : (0, "expected >0, got $_[0]")}),
             'again>0';
} else {
  $c->reader; $p->writer;
  $c->blocking(0);
  my $sel=IO::Select->new($c);

  my $again=0;
  while( $sel->can_read ) {
    $!=0;
    my @l=$c->read_record;
    if( @l ) {
      $p->write_record( \@l, $again );
    } elsif( $!==EAGAIN ) {
      $again++;
    } else {
      last;
    }
  }
  exit 0;
}

# Local Variables: #
# mode: cperl #
# End: #
