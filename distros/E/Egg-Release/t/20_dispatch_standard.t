use Test::More tests => 143;
use lib qw( ../lib ./lib );
use Egg::Helper;

$ENV{VTEST_DISPATCH_CLASS}= 'Egg::Dispatch::Standard';

my $e= Egg::Helper->run('Vtest');

can_ok $e, 'refhash';
  ok my $rhash= $e->can('refhash'), q{my $rhash= $e->can('refhash')};
  ok my $rh= $rhash->(), q{my $rh= $rhash->()};
  isa_ok $rh, 'HASH';
  isa_ok tied(%$rh), 'Tie::RefHash';

can_ok $e, 'dispatch';
can_ok $e, 'dispatch_map';
{
	ok my $d= $e->dispatch, q{my $d= $e->dispatch};
	isa_ok $d, 'Egg::Dispatch::Standard::handler';
	my($begin, $default);
	ok $e->dispatch_map(
	  _default=> sub {},
	  _begin=> sub { $begin.= 1 },
	  test=> {
	    _begin=> sub { $begin.= 2 },
	    test=> {
	      _begin  => sub { $begin.= 3 },
	      _default=> sub { $default= 1 },
	      },
	    },
	  ), q{$e->dispatch_map( .......... };
	ok $e->dispatch_map, q{$e->dispatch_map};
can_ok $d, '_start';
	ok $d->_start, q{$d->_start};
	is $begin,   1, q{$begin, 1};
	$e->{Dispatch}= undef;
  };

{
	ok my $d= $e->dispatch, q{my $d= $e->dispatch};
can_ok $d, 'parts';
	ok $d->parts([qw/ test test /]), q{$d->parts([qw/ test test /])};
	my($begin, $default);
	ok $e->dispatch_map(
	  _default=> sub {},
	  _begin=> sub { $begin.= 1 },
	  test=> {
	    _begin=> sub { $begin.= 2 },
	    test=> {
	      _begin  => sub { $begin.= 3 },
	      _default=> sub { $default= 1 },
	      },
	    },
	  ), q{$e->dispatch_map( .......... };
	ok $d->_start, q{$d->_start};
	is $begin, '123', q{$begin, '123'};
can_ok $d, '_action';
	ok $d->_action, q{$d->_action};
	is $default, 1, q{$default, 1};
	$e->{Dispatch}= undef;
  };

{
	ok my $d= $e->dispatch, q{my $d= $e->dispatch};
	my $end;
	ok $e->dispatch_map(
	  _default=> sub {},
	  _end=> sub { $end.= 1 },
	  test=> {
	    _end=> sub { $end.= 2 },
	    test=> {
	      _end  => sub { $end.= 3 },
	      _default=> sub { $default= 1 },
	      },
	    },
	  ), q{$e->dispatch_map( .......... };
	ok $d->_start, q{$d->_start};
can_ok $d, '_finish';
	ok $d->_finish, q{$d->_finish};
	is $end, 1, q{$end, 1};
	$e->{Dispatch}= undef;
  };


{
	ok my $d= $e->dispatch, q{my $d= $e->dispatch};
	ok $d->parts([qw/ test test /]), q{$d->parts([qw/ test test /])};
	my $end;
	ok $e->dispatch_map(
	  _default=> sub {},
	  _end=> sub { $end.= 1 },
	  test=> {
	    _end=> sub { $end.= 2 },
	    test=> {
	      _end  => sub { $end.= 3 },
	      _default=> sub { $default= 1 },
	      },
	    },
	  ), q{$e->dispatch_map( .......... };
	ok $d->_start,  q{$d->_start};
	ok $d->_finish, q{$d->_finish};
	is $end, '321', q{$end, 321};
	$e->{Dispatch}= undef;
  };

{
	ok my $d= $e->dispatch, q{my $d= $e->dispatch};
	ok $d->parts([qw/ test test /]), q{$d->parts([qw/ test test /])};
	ok $e->dispatch_map(
	  _default=> sub {},
	  test=> {
	    test=> {
	      _default=> sub { $default= 1 },
	      },
	    },
	  ), q{$e->dispatch_map( .......... };
	ok $d->_start,  q{$d->_start};
	ok $d->_action, q{$d->_action};
	is join('/', @{$e->action}), 'test/test/index', q{join('/', @{$e->action}), 'test/test/index'};
	$e->{Dispatch}= undef;
  };

{
	ok my $d= $e->dispatch, q{my $d= $e->dispatch};
	ok $d->parts([qw/ test test /]), q{$d->parts([qw/ test test /])};
	ok $e->dispatch_map(
	  _default=> sub {},
	  test=> {
        _default=> sub { $default= 1 },
	    },
	  ), q{$e->dispatch_map( .......... };
	ok $d->_start,  q{$d->_start};
	ok $d->_action, q{$d->_action};
	is join('/', @{$e->action}), 'test/index', q{join('/', @{$e->action}), 'test/index'};
	$e->{Dispatch}= undef;
  };

{
	ok my $d= $e->dispatch, q{my $d= $e->dispatch};
	ok $d->parts([qw/ test test /]), q{$d->parts([qw/ test test /])};
	ok $e->dispatch_map(
        _default=> sub { $default= 1 },
	  ), q{$e->dispatch_map( .......... };
	ok $d->_start,  q{$d->_start};
	ok $d->_action, q{$d->_action};
	is join('/', @{$e->action}), 'index', q{join('/', @{$e->action}), 'index'};
	$e->{Dispatch}= undef;
  };

{
	ok my $d= $e->dispatch, q{my $d= $e->dispatch};
	ok $d->parts([qw/ test test /]), q{$d->parts([qw/ test test /])};
	ok $e->dispatch_map( $rhash->(
      [qw/ _default /]=> sub { $default= 1 },
	  ) ), q{$e->dispatch_map( .......... };
	ok $d->_start,  q{$d->_start};
	ok $d->_action, q{$d->_action};
	is join('/', @{$e->action}), 'index', q{join('/', @{$e->action}), 'index'};
	$e->{Dispatch}= undef;
  };

{
	ok my $d= $e->dispatch, q{my $d= $e->dispatch};
	ok $d->parts([qw/ test test /]), q{$d->parts([qw/ test test /])};
	ok $e->dispatch_map( $rhash->(
	  _default=> sub {},
      test=> $rhash->(
        [qw/ _default /]=> sub { $default= 1 },
        ),
	  ) ), q{$e->dispatch_map( .......... };
	ok $d->_start,  q{$d->_start};
	ok $d->_action, q{$d->_action};
	is join('/', @{$e->action}), 'test/index', q{join('/', @{$e->action}), 'test/index'};
	$e->{Dispatch}= undef;
  };

{
	ok my $d= $e->dispatch, q{my $d= $e->dispatch};
	ok $d->parts([qw/ test test /]), q{$d->parts([qw/ test test /])};
	ok $e->dispatch_map( $rhash->(
	  _default=> sub {},
      test=> $rhash->(
        test=> $rhash->(
          [qw/ _default /]=> sub { $default= 1 },
          ),
        ),
	  ) ), q{$e->dispatch_map( .......... };
	ok $d->_start,  q{$d->_start};
	ok $d->_action, q{$d->_action};
	is join('/', @{$e->action}), 'test/test/index', q{join('/', @{$e->action}), 'test/test/index'};
	$e->{Dispatch}= undef;
  };

{
	$ENV{REQUEST_METHOD}= 'GET';
	ok my $d= $e->dispatch, q{my $d= $e->dispatch};
	ok $d->parts([qw/ test test /]), q{$d->parts([qw/ test test /])};
	ok $e->dispatch_map( $rhash->(
	  _default=> sub {},
      test=> $rhash->(
        [qw/ _default 1 /]=> sub { $default= 1 },
        test=> $rhash->(
          [qw/ _default 1 /]=> sub { $default= 1 },
          ),
        ),
	  ) ), q{$e->dispatch_map( .......... };
	ok $d->_start,  q{$d->_start};
	ok $d->_action, q{$d->_action};
	is join('/', @{$e->action}), 'test/test/index', q{join('/', @{$e->action}), 'test/test/index'};
	$e->{Dispatch}= undef;
	$ENV{REQUEST_METHOD}= "";
  };

{
	$ENV{REQUEST_METHOD}= 'GET';
	ok my $d= $e->dispatch, q{my $d= $e->dispatch};
	ok $d->parts([qw/ test test /]), q{$d->parts([qw/ test test /])};
	ok $e->dispatch_map( $rhash->(
	  _default=> sub {},
      test=> $rhash->(
        [qw/ _default 1 /]=> sub { $default= 1 },
        test=> $rhash->(
          [qw/ _default 2 /]=> sub { $default= 1 },
          ),
        ),
	  ) ), q{$e->dispatch_map( .......... };
	ok ! $d->_start,  q{! $d->_start};
	ok $e->finished, q{$e->finished};
	is $e->response->status, 405, q{$e->response->status, 405};
	$e->{Dispatch}= undef;
	$ENV{REQUEST_METHOD}= "";
	$e->finished(0);
  };

{
	$ENV{REQUEST_METHOD}= 'POST';
	ok my $d= $e->dispatch, q{my $d= $e->dispatch};
	ok $d->parts([qw/ test test /]), q{$d->parts([qw/ test test /])};
	ok $e->dispatch_map( $rhash->(
	  _default=> sub {},
      test=> $rhash->(
        [qw/ _default 1 /]=> sub { $default= 1 },
        test=> $rhash->(
          [qw/ _default 1 /]=> sub { $default= 1 },
          ),
        ),
	  ) ), q{$e->dispatch_map( .......... };
	ok ! $d->_start, q{! $d->_start};
	ok $e->finished, q{$e->finished};
	is $e->response->status, 405, q{$e->response->status, 405};
	$e->{Dispatch}= undef;
	$ENV{REQUEST_METHOD}= "";
	$e->finished(0);
  };

{
	$ENV{REQUEST_METHOD}= 'POST';
	ok my $d= $e->dispatch, q{my $d= $e->dispatch};
	ok $d->parts([qw/ test test /]), q{$d->parts([qw/ test test /])};
	ok $e->dispatch_map( $rhash->(
	  _default=> sub {},
      test=> $rhash->(
        [qw/ _default 2 /]=> sub { $default= 1 },
        test=> $rhash->(
          [qw/ _default 2 /]=> sub { $default= 1 },
          ),
        ),
	  ) ), q{$e->dispatch_map( .......... };
	ok $d->_start,  q{$d->_start};
	ok $d->_action, q{$d->_action};
	is join('/', @{$e->action}), 'test/test/index', q{join('/', @{$e->action}), 'test/test/index'};
	$e->{Dispatch}= undef;
	$ENV{REQUEST_METHOD}= "";
	$e->finished(0);
  };

{
	$ENV{REQUEST_METHOD}= 'POST';
	ok my $d= $e->dispatch, q{my $d= $e->dispatch};
	ok $d->parts([qw/ test test /]), q{$d->parts([qw/ test test /])};
	ok $e->dispatch_map( $rhash->(
	  _default=> sub {},
      test=> $rhash->(
        [qw/ _default 1 /]=> sub { $default= 1 },
        test=> $rhash->(
          [qw/ _default 2 /]=> sub { $default= 1 },
          ),
        ),
	  ) ), q{$e->dispatch_map( .......... };
	ok ! $d->_start, q{! $d->_start};
	ok $e->finished, q{$e->finished};
	is $e->response->status, 405, q{$e->response->status, 405};
	$e->{Dispatch}= undef;
	$ENV{REQUEST_METHOD}= "";
	$e->finished(0);
  };

{
	ok my $d= $e->dispatch, q{my $d= $e->dispatch};
	ok $d->parts([qw/ test test /]), q{$d->parts([qw/ test test /])};
	ok $e->dispatch_map( $rhash->(
	  _default=> sub {},
      test=> $rhash->(
        [qw/ _default 0 /, 'TEST 1']=> sub { $default= 1 },
        test=> $rhash->(
          [qw/ _default 0 /, 'TEST 2']=> sub { $default= 1 },
          ),
        ),
	  ) ), q{$e->dispatch_map( .......... };
	ok $d->_start,  q{$d->_start};
	is join('/', @{$e->action}), 'test/test/index', q{join('/', @{$e->action}), 'test/test/index'};
	is $d->page_title, 'TEST 2', q{$d->page_title, 'TEST 2'};
	$e->{Dispatch}= undef;
  };

{
	ok my $d= $e->dispatch, q{my $d= $e->dispatch};
	ok $d->parts([qw/ test /]), q{$d->parts([qw/ test test /])};
	ok $e->dispatch_map( $rhash->(
	  _default=> sub {},
      test=> $rhash->(
        [qw/ _default 0 /, 'TEST 1']=> sub { $default= 1 },
        test=> $rhash->(
          [qw/ _default 0 /, 'TEST 2']=> sub { $default= 1 },
          ),
        ),
	  ) ), q{$e->dispatch_map( .......... };
	ok $d->_start,  q{$d->_start};
	is join('/', @{$e->action}), 'test/index', q{join('/', @{$e->action}), 'test/index'};
	is $d->page_title, 'TEST 1', q{$d->page_title, 'TEST 1'};
	$e->{Dispatch}= undef;
  };

{
	ok my $d= $e->dispatch, q{my $d= $e->dispatch};
	ok $d->parts([qw/ Test1234 Test5678 /]), q{$d->_actions([qw/ test test /])};
	my $match;
	ok $e->dispatch_map(
	  _default=> sub {},
      qr{^[A-Z][a-z]+([0-9]+)}=> {
        qr{^[A-Z]([a-z]+)([0-9]+)}=> sub {
          (my $egg, my $dipatch, $match)= @_;
          },
        },
	  ), q{$e->dispatch_map( .......... };
	ok $d->_start,  q{$d->_start};
	ok $d->_action, q{$d->_action};
	is join('/', @{$e->action}), 'Test1234/Test5678', q{join('/', @{$e->action}), 'Test1234/Test5678'};
	isa_ok $match, 'ARRAY';
	is @$match, 2, q{@$match, 2};
	is $match->[0], 'est',  q{$match->[0], 'est'};
	is $match->[1], '5678', q{$match->[1], '5678'};
	ok my $obj= tied($d->parts->[0]), q{my $obj= tied($d->parts->[0])};
	isa_ok $obj->[2], 'ARRAY';
	is @{$obj->[2]}, 1, q{@{$obj->[2]}, 1};
	is $obj->[2][0], '1234', q{$obj->[2][0], '1234'};
	is $d->page_title, 'Test5678', q{$d->page_title, 'TEST 1'};
	$e->{Dispatch}= undef;
  };

{
	ok my $d= $e->dispatch, q{my $d= $e->dispatch};
	ok $d->parts([qw/ Test1234 Test5678 /]), q{$d->_actions([qw/ test test /])};
	my $match;
	ok $e->dispatch_map( $rhash->(
	  _default=> sub {},
      [ qr{^[A-Z][a-z]+([0-9]+)} ]=> $rhash->(
        [ qr{^[A-Z]([a-z]+)([0-9]+)} ]=> sub {
          (my $egg, my $dipatch, $match)= @_;
          },
        ),
	  ) ), q{$e->dispatch_map( .......... };
	ok $d->_start,  q{$d->_start};
	ok $d->_action, q{$d->_action};
	is join('/', @{$e->action}), 'Test1234/Test5678', q{join('/', @{$e->action}), 'Test1234/Test5678'};
	isa_ok $match, 'ARRAY';
	is @$match, 2, q{@$match, 2};
	is $match->[0], 'est',  q{$match->[0], 'est'};
	is $match->[1], '5678', q{$match->[1], '5678'};
	ok my $obj= tied($d->parts->[0]), q{my $obj= tied($d->parts->[0])};
	isa_ok $obj->[2], 'ARRAY';
	is @{$obj->[2]}, 1, q{@{$obj->[2]}, 1};
	is $obj->[2][0], '1234', q{$obj->[2][0], '1234'};
	is $d->page_title, 'Test5678', q{$d->page_title, 'TEST 1'};
	$e->{Dispatch}= undef;
  };

