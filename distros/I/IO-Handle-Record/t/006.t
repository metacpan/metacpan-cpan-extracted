use Test::More;
use Test::Deep;
use Data::Dumper;
$Data::Dumper::Deparse=1;
use IO::Handle::Record;
use IO::Socket::UNIX;
use IO::Select;
use Errno qw/EAGAIN/;
use Socket;

#########################

sub check_afunix {
  my ($r, $w);
  return unless eval {
    socketpair $r, $w, AF_UNIX, SOCK_STREAM, PF_UNSPEC and
      sockaddr_family( getsockname $r ) == AF_UNIX
  };
}

if( check_afunix ) {
  plan tests=>15;
} else {
  plan skip_all=>'need a working socketpair based on AF_UNIX sockets';
}

my @to_be_deleted;
sub t_create_file {
  my ($name, $content)=@_;
  my $f;
  if( open $f, '>', $name ) {
    push @to_be_deleted, $name;
    print $f $content or die "Cannot write to $name";
    close $f or die "Cannot write to $name";
  } else {
    die "Cannot open tmp file $name.";
  }
}
END {
  unlink @to_be_deleted;
}

sub t_cat {
  local $/;
  return scalar readline $_[0];
}

t_create_file 'f1', "content1";
t_create_file 'f2', "content2";

$SIG{__WARN__}=sub {
  print STDERR "$$: ".$_[0];
};

my ($p, $c)=IO::Socket::UNIX->socketpair( AF_UNIX,SOCK_STREAM,PF_UNSPEC );
my $pid;
while( !defined( $pid=fork ) ) {select undef, undef, undef, .1}

if( $pid ) {
  my $got;

  $p->write_record( 'f1', 'f2' );
  select undef, undef, undef, 0.5;  # pause to let the writer write both records

  ($got)=$p->read_record;

  cmp_deeply $got, [qw/f1 f2/], 'read_record';
  my @fds=@{$p->received_fds};
  cmp_deeply 0+@fds, 3, '3 fds received';
  cmp_deeply t_cat($fds[0]), 'content1', 'first fd';
  cmp_deeply t_cat($fds[1]), 'content2', 'second fd';
  cmp_deeply [(stat $fds[2])[0,1,6]], [(stat '/dev/null')[0,1,6]],
             'third fd is /dev/null';
  cmp_deeply !print( {$fds[2]} 'x'x1000000 ), !1, 'print 1000000 bytes to /dev/null';
  cmp_deeply [map ref, @fds], [qw/IO::File IO::File IO::Handle/],
             'handle types';
  @fds=();

  ($got)=$p->read_record;

  cmp_deeply $got, [qw/f2 f1/], 'read reverse';
  @fds=@{$p->received_fds};
  cmp_deeply 0+@fds, 3, '3 fds received';
  cmp_deeply [(stat $fds[0])[0,1,6]], [(stat $c)[0,1,6]],
             'first fd is $c';
  cmp_deeply $fds[0]->can('socktype'), \&IO::Socket::socktype,
             '$fds[0] can socktype()';
  cmp_deeply t_cat($fds[1]), 'content2', 'reverse: second fd';
  cmp_deeply t_cat($fds[2]), 'content1', 'reverse: third fd';
  cmp_deeply [map ref, @fds], [qw/IO::Socket::UNIX IO::File IO::File/],
             'handle types';
  @fds=();
  close $c; undef $c;
  undef $p->received_fds;	# closes received fds

 SKIP: {
    skip "Peer credentials are supported on Linux only", 1
      unless( $^O=~/linux/i );
    cmp_deeply [$p->peercred], [$$, $>, ($)=~/(\d+)/)[0]], 'peer credentials';
  }
} else {
  @to_be_deleted=();
  close $p; undef $p;

  my @l=$c->read_record;

  $c->fds_to_send=[map( {open my($fd), $_; $fd} @l ),
		   do{open my $fd, '>', '/dev/null'; $fd}];
  $c->write_record( \@l );

  $c->fds_to_send=[reverse( map( {open my($fd), $_; $fd} @l ), $c)];
  $c->write_record( [reverse @l] );

  exit 0;
}

# Local Variables: #
# mode: cperl #
# End: #
