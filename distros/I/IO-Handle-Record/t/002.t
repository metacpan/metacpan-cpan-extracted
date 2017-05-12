use Test::More;
use Test::Deep;
use Data::Dumper;
$Data::Dumper::Deparse=1;
use IO::Handle::Record;
use IO::Socket::UNIX;
use IO::Select;
use Errno qw/EAGAIN/;

#########################

sub check_afunix {
  my ($r, $w);
  return unless eval {
    socketpair $r, $w, AF_UNIX, SOCK_STREAM, PF_UNSPEC and
      sockaddr_family( getsockname $r ) == AF_UNIX
  };
}

if( check_afunix ) {
  plan tests=>5;
} else {
  plan skip_all=>'need a working socketpair based on AF_UNIX sockets';
}

my ($p, $c)=IO::Socket::UNIX->socketpair( AF_UNIX,SOCK_STREAM,PF_UNSPEC );
my $pid;
while( !defined( $pid=fork ) ) {select undef, undef, undef, .1}

if( $pid ) {
  close $c; undef $c;
  my $got;

  $p->write_record( 1 );
  ($got)=$p->read_record;
  cmp_deeply $got, [1], 'simple scalar';

  $p->write_record( 1, 2, 3, 4 );
  ($got)=$p->read_record;
  cmp_deeply $got, [1, 2, 3, 4], 'scalar list';

  $p->write_record( [1,2], [3,4] );
  ($got)=$p->read_record;
  cmp_deeply $got, [[1, 2], [3, 4]], 'list list';

  $p->write_record( [1,2], +{a=>'b', c=>'d'} );
  ($got)=$p->read_record;
  cmp_deeply $got, [[1, 2], +{a=>'b', c=>'d'}], 'list+hash list';

  $p->record_opts={receive_CODE=>sub {eval $_[0]}, send_CODE=>1};
  $p->write_record( +{a=>'b', c=>'d'}, sub { $_[0]+$_[1] } );
  ($got)=$p->read_record;
  cmp_deeply $got, [+{a=>'b', c=>'d'},
                    code(sub {ref($_[0]) eq 'CODE' and $_[0]->(1, 2)==3})],
                      'hash+sub list';
} else {
  close $p; undef $p;
  $c->record_opts={receive_CODE=>sub {eval $_[0]}, send_CODE=>1};
  while( my @l=$c->read_record ) {
    $c->write_record( \@l );
  }
  exit 0;
}

# Local Variables: #
# mode: cperl #
# End: #
