#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 84;
use Test::MockModule;
use Data::Dumper;

# module compilation
# Test 1
require_ok('Maypole');

# loaded modules 
# Tests 2 - 8
{
    ok($Maypole::VERSION, 'defines $VERSION');
    ok($INC{'Maypole/Config.pm'}, 'loads Maypole::Config');
    ok($INC{'UNIVERSAL/require.pm'}, 'loads UNIVERSAL::require');
    ok($INC{'Maypole/Constants.pm'}, 'loads Maypole::Constants');
    ok($INC{'Maypole/Headers.pm'}, 'loads Maypole::Headers');
    ok($INC{'Class/Accessor/Fast.pm'}, 'loads Class::Accessor::Fast');
    ok($INC{'Class/Data/Inheritable.pm'}, 'loads Class::Data::Inheritable');
}

my $OK       = Maypole::Constants::OK();
my $DECLINED = Maypole::Constants::DECLINED();
my $ERROR    = Maypole::Constants::ERROR();

# Maypole API
my @API = qw/ config init_done view_object params query param objects model_class
              template_args output path args action template error document_encoding
              content_type table headers_in headers_out 
              is_model_applicable setup setup_model init handler handler_guts
              call_authenticate call_exception additional_data
              authenticate exception parse_path make_path
              make_uri get_template_root get_request
              parse_location send_output
	      start_request_hook
	      get_session
          get_user
              /;

# Tests 9 to 13                
can_ok(Maypole => @API);
ok( UNIVERSAL::can(Maypole => 'is_applicable'), 'is_applicable() method' ); # added is_applicable back in
ok(Maypole->config->isa('Maypole::Config'), 'config is a Maypole::Config object');
ok(! Maypole->init_done, '... which is false by default');
is(Maypole->view_object, undef, '... which is undefined');

# simple test class that inherits from Maypole
{
    package MyDriver;
    @MyDriver::ISA = 'Maypole';
    @MyDriver::VERSION = 1;
    MyDriver->config->template_root('t/templates');
}

# back to package main;
my $driver_class = 'MyDriver';

# Test 14
# subclass inherits API
can_ok($driver_class => @API);

# Mock the model class
my (%required, @db_args, @adopted);
my $model_class = 'Maypole::Model::CDBI';
my $table_class = $driver_class . '::One';

my $mock_model = Test::MockModule->new($model_class);
$mock_model->mock(
    require        => sub {$required{+shift} = 1},
    setup_database => sub {
        push @db_args, \@_;
        $_[1]->{classes} = ["$model_class\::One", "$model_class\::Two"];
        $_[1]->{tables}  = [qw(one two)];
    },
    adopt          => sub {push @adopted, \@_},
);


# Tests 15 - 21
warn "Tests 15 to 21\n\n";
# setup
{
    # 2.11 - removed tests to check the installed handler was a different ref after setup().
    # The handler tests were testing Maypole's old (pre 2.11) method of importing handler() 
    # into the subclass - it works via standard inheritance now, by setting the 'method' 
    # attribute on Maypole::handler(). The reason the handlers were different 
    # was because setup() would create a new anonymous ref to Maypole::handler(), and install 
    # that - i.e. it installed the same code, but in a different ref, so they tested unequal
    # although they referred to the same code

    $driver_class->setup('dbi:foo'); 
    
    ok($required{$model_class}, '... requires model class');
    is($driver_class->config->model(),
        'Maypole::Model::CDBI', '... default model is CDBI');
    is(@db_args, 1, '... calls model->setup_database');
    like(join (' ', @{$db_args[0]}),
        qr/$model_class Maypole::Config=\S* $driver_class dbi:foo/,
        '... setup_database passed setup() args');
    is(@adopted, 2, '... calls model->adopt foreach class in the model');
    ok($adopted[0][0]->isa($model_class),
    '... sets up model subclasses to inherit from model');
    $driver_class->config->model('NonExistant::Model');
    eval {$driver_class->setup};
    like($@, qr/Couldn't load the model class/,
        '... dies if unable to load model class');
    
    # cleanup
    $@ = undef; 
    $driver_class->config->model($model_class);
}


# Tests 22 - 27
warn "Tests 22 to 27\n\n";
# Mock the view class
my $view_class = 'Maypole::View::TT';
my $mock_view = Test::MockModule->new($view_class);
$mock_view->mock(
    new     => sub {bless{}, shift},
    require => sub {$required{+shift} = 1},
);

# init()
{
    $driver_class->init();
    ok($required{$view_class}, '... requires the view class');
    is($driver_class->config->view, $view_class, '... the default view class is TT');
    is(join(' ', @{$driver_class->config->display_tables}), 'one two',
        '... config->display_tables defaults to all tables');
    ok($driver_class->view_object->isa($view_class),
        '... creates an instance of the view object');
    ok($driver_class->init_done, '... sets init_done');
    $driver_class->config->view('NonExistant::View');
    eval {$driver_class->init};
    like($@, qr/Couldn't load the view class/,
        '... dies if unable to load view class');
        
    # cleanup
    $@ = undef; 
    $driver_class->config->view($view_class);
}

my ($r, $req); # request objects

# Tests 28 - 38
warn "tests 28 to 38\n\n";
# handler()
{
    my $init = 0;
    my $status = 0;
    my %called;
    
    my $mock_driver = Test::MockModule->new($driver_class, no_auto => 1);
    $mock_driver->mock(
        init           => sub {$init++; shift->init_done(1)},
        get_request    => sub {($r, $req) = @_; $called{get_request}++},
        parse_location => sub {$called{parse_location}++},
        handler_guts   => sub { 
			        $called{handler_guts}++; $status
			      },
        send_output    => sub {$called{send_output}++},
    );

    my $rv = $driver_class->handler();
    
    ok($r && $r->isa($driver_class), '... created $r');
    ok($called{get_request}, '... calls get_request()');
    ok($called{parse_location}, '... calls parse_location');
    ok($called{handler_guts}, '... calls handler_guts()');
    ok($called{send_output}, '... call send_output');
    is($rv, 0, '... return status (should be ok?)');
    ok(!$init, "... doesn't call init() if init_done()");
    
    ok($r->headers_out && $r->headers_out->isa('Maypole::Headers'),
       '... populates headers_out() with a Maypole::Headers object');
       
    # call again, testing other branches
    $driver_class->init_done(0);
    $status = -1;
    $rv = $driver_class->handler();
    ok($called{handler_guts} == 2 && $called{send_output} == 1,
       '... returns early if handler_guts failed');
    is($rv, -1, '... returning the error code from handler_guts');
    
    $driver_class->handler();
    ok($init && $driver_class->init_done, "... init() called if !init_done()");
}


# Tests 39 - 48
warn "Tests 39 - 48\n\n";
# Testing handler_guts
{
    # handler_guts()
    {
        no strict 'refs';
        @{$table_class . "::ISA"} = $model_class;
    }

    my ($applicable, %called);
    
    my $mock_driver = new Test::MockModule($driver_class, no_auto => 1);
    my $mock_table  = new Test::MockModule($table_class, no_auto => 1);
    
    $mock_driver->mock(
        is_applicable   => sub {push @{$called{applicable}},\@_; $applicable},
        is_model_applicable   => 
            sub {push @{$called{applicable}},\@_; $applicable},
        get_request     => sub {($r, $req) = @_},
        additional_data => sub {$called{additional_data}++},
    );
    
    $mock_table->mock(
        table_process   => sub {push @{$called{process}},\@_},
    );
    
    $mock_model->mock(
        class_of        => sub {push @{$called{class_of}},\@_; $table_class},
        process         => sub {push @{$called{model_process}}, \@_},
    );
    
    $mock_view->mock(
        process         => sub {push @{$called{view_process}}, \@_; $OK}
    );
    
    # allow request
    $applicable = 1;
    
    $r->{path} = '/one/list';
    $r->parse_path;
  
    my $status = $r->handler_guts();
 
    # set model_class (would be done in handler_guts, but hard to mock earlier)
    $r->model_class( $r->config->model->class_of($r, $r->table) );
     
    warn "status : $status\n";

    is($r->model_class, $table_class, '... sets model_class from table()');
    ok($called{additional_data}, '... call additional_data()');
    is($status, $OK, '... return status = OK');

    TODO: {
        local $TODO = "test needs fixing";
        ok($called{model_process},
        '... if_applicable, call model_class->process');
    }

    # decline request
    %called = ();
    
    $applicable = 0;
    
    $r->{path} = '/one/list';
    $r->parse_path;
    
    $status = $r->handler_guts();
    # set model_class (would be done in handler_guts, but hard to mock earlier)
    $r->model_class( $r->config->model->class_of($r, $r->table) );
    
    is($r->template, $r->path,
       '... if ! is_applicable set template() to path()');
    
    TODO: {
        local $TODO = "test needs fixing";
    ok(!$called{model_process},
       '... !if_applicable, call model_class->process');
    }

    is_deeply($called{view_process}[0][1], $r,
              ' ... view_object->process called');
    is($status, $OK, '... return status = OK');

    # pre-load some output
    %called = ();
    
    $r->parse_path;
    $r->{output} = 'test';
    
    $status = $r->handler_guts();
    # set model_class (would be done in handler_guts, but hard to mock earlier)
    $r->model_class( $r->config->model->class_of($r, $r->table) );
    
    ok(!$called{view_process},
       '... unless output, call view_object->process to get output');

    # fail authentication
    $mock_driver->mock(call_authenticate => sub {$DECLINED});
    $status = $r->handler_guts();
    # set model_class (would be done in handler_guts, but hard to mock earlier)
    $r->model_class( $r->config->model->class_of($r, $r->table) );

    is($status, $DECLINED,
       '... return DECLINED unless call_authenticate == OK');

    # ... TODO authentication error handling
    # ... TODO model error handling
    # ... TODO view processing error handling
}

# Tests 49 - 53
warn "Tests 49 to 53\n\n";
# is_model_applicable()
{
TODO: {
    local $TODO = "test needs fixing";
    $r->config->ok_tables([qw(one two)]);
    $r->config->display_tables([qw(one two)]);
    $r->model_class($table_class);
    $r->table('one');
    $r->action('unittest');
    my $is_public;
    $mock_model->mock('is_public', sub {0});
    my $true_false = $r->is_model_applicable;
    is($true_false, 0,
       '... returns 0 unless model_class->is_public(action)');
    $mock_model->mock('is_public', sub {$is_public = \@_; 1});
    $true_false = $r->is_model_applicable;
    is($true_false, 1, '... returns 1 if table is in ok_tables');
    is_deeply($is_public, [$r->model_class, 'unittest'],
	      '... calls model_class->is_public with request action');
    is_deeply($r->config->ok_tables, {one => 1, two => 1},
	      '... config->ok_tables defaults to config->display_tables');
    delete $r->config->ok_tables->{one};
    $true_false = $r->is_model_applicable;
    is($true_false, 0, '... returns 0 unless $r->table is in ok_tables');
  }
}

# Tests 54 - 58
warn "Tests 54 to 58\n\n";
my $mock_driver = new Test::MockModule($driver_class, no_auto => 1);
my $mock_table  = new Test::MockModule($table_class, no_auto => 1);
# call_authenticate()
{
    my %auth_calls;
    $mock_table->mock(
        authenticate => sub {$auth_calls{model_auth} = \@_; $OK}
    );
    my $status = $r->call_authenticate;
    is_deeply($auth_calls{model_auth}, [$table_class, $r],
            '... calls model_class->authenticate if it exists'); # 54
    is($status, $OK, '... and returns its status (OK)'); # 55
    $mock_table->mock(authenticate => sub {$DECLINED});
    $status = $r->call_authenticate;
    is($status, $DECLINED, '... or DECLINED, as appropriate'); # 56
    
    $mock_table->unmock('authenticate');
    $mock_driver->mock(authenticate => sub {return $DECLINED});
    $status = $r->call_authenticate;
    is($status, $DECLINED, '... otherwise it calls authenticte()'); # 57
    $mock_driver->unmock('authenticate');
    $status = $r->call_authenticate;
    is($status, $OK, '... the default authenticate is OK'); # 58
}

# Tests 59 - 63
warn "Tests 59 to 63\n\n";
# call_exception()
{
TODO: {
       local $TODO = "test needs fixing";

    my %ex_calls;
    $mock_table->mock(
        exception => sub {$ex_calls{model_exception} = \@_; $OK}
    );
    $mock_driver->mock(
        exception => sub {$ex_calls{driver_exception} = \@_; 'X'}
    );
    my $status = $r->call_exception('ERR');
    is_deeply($ex_calls{model_exception}, [$table_class, $r, 'ERR'],
            '... calls model_class->exception if it exists');
    is($status, $OK, '... and returns its status (OK)');
    $mock_table->mock(exception => sub {$DECLINED});
    $status = $r->call_exception('ERR');
    is_deeply($ex_calls{driver_exception}, [$r, 'ERR'],
            '... or calls driver->exception if model returns !OK');
    is($status, 'X', '... and returns the drivers status');
    
    $mock_table->unmock('exception');
    $mock_driver->unmock('exception');
    $status = $r->call_exception('ERR');
    is($status, $ERROR, '... the default exception is ERROR');
    }
}

# Test 64
# authenticate()
{
    is(Maypole->authenticate(), $OK, '... returns OK');
}

# Test 65
# exception()
{
    is(Maypole->exception(), $ERROR, '... returns ERROR');
}

# Tests 66 to 71
warn "Tests 66 to 71\n\n";
# parse_path()
{
    $r->path(undef);
    
    $r->parse_path;
    is($r->path, 'frontpage', '... path() defaults to "frontpage"');
    
    $r->path('/table');
    $r->parse_path;
    is($r->table, 'table', '... parses "table" from the first part of path');
    ok(@{$r->args} == 0, '... "args" default to empty list');
    
    $r->path('/table/action');
    $r->parse_path;
    ok($r->table eq 'table' && $r->action eq 'action',
    '... action is parsed from second part of path');
    
    $r->path('/table/action/arg1/arg2');
    $r->parse_path;
    is_deeply($r->args, [qw(arg1 arg2)],
    '... "args" are populated from remaning components');
    
    # ... action defaults to index
    $r->path('/table');
    $r->parse_path;
    is($r->action, 'index', '... action defaults to index');
}

# make_uri() and make_path() - see pathtools.t

# Test 72
# get_template_root()
{
TODO: {
       local $TODO = "test needs fixing";
       is(Maypole->get_template_root(), '.', '... returns "."');
       }
}

# Test 73
# parse_location()
{
    eval {Maypole->parse_location()};
    like($@, qr/Do not use Maypole directly/, '... croaks - must be overriden');
}

# Test 74
# send_output()
{
    eval {Maypole->send_output};
    like($@, qr/Do not use Maypole directly/, '... croaks - must be overriden');
}

# Tests 75 - 84
warn "Tests 75 to 84\n\n";
# param()
{
	my $p = { foo => 'bar', 
		  quux => [ qw/one two three/ ],
		  buz => undef,
		  num => 3,
		  zero => 0,
	          };
		  
	$r->{params} = $p;
	
	is_deeply( [keys %$p], [$r->param] ); # 75
	
	cmp_ok( $r->param('foo'), eq => 'bar' ); # 76
	cmp_ok( $r->param('num'), '==' => 3 ); # 77
	cmp_ok( $r->param('zero'), '==' => 0 ); # 78
	
	ok( ! defined $r->param('buz') ); # 79
	
	# scalar context returns the 1st value, not a ref
	cmp_ok( scalar $r->param('quux'), eq => 'one' ); # 80
	is_deeply( [$r->param('quux')], [ qw/one two three/ ] ); # 81
	
	$r->param(foo => 'booze');
	cmp_ok( $r->param('foo'), 'eq', 'booze' ); # 82
	
	$r->param(foo => undef);
	ok( ! defined $r->param('foo') ); # 83
	
	# cannot introduce new keys
	$r->param(new => 'sox');
	ok( ! defined $r->param('new') ); # 84
}

