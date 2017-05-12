use Test::More tests => 9;
use Test::Deep;
use Data::Dumper;
$Data::Dumper::Deparse=1;
BEGIN { use_ok('IO::Handle::Record') };
use IO::Pipe;
use IO::Select;
use Errno qw/EAGAIN/;

#########################

my ($p, $c)=(IO::Pipe->new, IO::Pipe->new);
my $pid;
while( !defined( $pid=fork ) ) {select undef, undef, undef, .2}

if( $pid ) {
  $p->reader; $c->writer;
  my $got;

  $c->write_record( 1 );
  ($got)=$p->read_record;
  cmp_deeply $got, [1], 'simple scalar';

  $c->write_record( 'string' );
  ($got)=$p->read_record;
  cmp_deeply $got, ['string'], 'simple string';

  $c->write_record( 1, 2, 3, 4 );
  ($got)=$p->read_record;
  cmp_deeply $got, [1, 2, 3, 4], 'scalar list';

  $c->write_record( [1,2], [3,4] );
  ($got)=$p->read_record;
  cmp_deeply $got, [[1, 2], [3, 4]], 'list list';

  $c->write_record( [1,2], +{a=>'b', c=>'d'} );
  ($got)=$p->read_record;
  cmp_deeply $got, [[1, 2], +{a=>'b', c=>'d'}], 'list+hash list';

  $c->record_opts={send_CODE=>1};
  $p->record_opts={receive_CODE=>sub {eval $_[0]}};
  $c->write_record( +{a=>'b', c=>'d'}, sub { $_[0]+$_[1] } );
  ($got)=$p->read_record;
  cmp_deeply $got, [+{a=>'b', c=>'d'},
                    code(sub {ref($_[0]) eq 'CODE' and $_[0]->(1, 2)==3})],
                      'hash+sub list';

  $c->record_opts={forgive_me=>1};
  $c->write_record( +{a=>'b', STDIN=>\*STDIN} );
  ($got)=$p->read_record;
  cmp_deeply $got, [+{a=>'b', STDIN=>re('^SCALAR\(')}],
             'GLOB passing';
  cmp_deeply ${$got->[0]->{STDIN}}, re('GLOB'),
             'GLOB passing2';

} else {
  $c->reader; $p->writer;
  $c->record_opts={receive_CODE=>sub {eval $_[0]}};
  $p->record_opts={send_CODE=>1};
  while( my @l=$c->read_record ) {
    $p->write_record( \@l  );
  }
  exit 0;
}

# Local Variables: #
# mode: cperl #
# End: #
