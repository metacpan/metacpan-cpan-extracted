
use Modern::Perl;
use Test::More qw(no_plan);
use AnyEvent;
use Data::Dumper;
$Data::Dumper::Sortkeys=1;
$Data::Dumper::Indent=1;
use FindBin qw($Bin);
use Scalar::Util qw( blessed looks_like_number);
require Method::Generate::DemolishAll;
use lib $Bin;
require TestMe;
#use Carp qw(confess);
#$SIG{__DIE__}=\&confess;
our $pkg='Devel::Agent';
use Sub::Defer qw(undefer_all);
require Plack::Middleware::Devel::Agent::Plack;
use Devel::Agent::Util;
use HTTP::Request::Common;
use Plack::Test;
use AnyEvent;
use File::Spec;
use File::Temp qw(tempdir);
undefer_all();

our $dir=tempdir;


# to enable unit tests
# PERL5OPT='-d:Agent'  perl -Ilib t/Charter-IT-Agent.t

our $SET;
our $TESTS=0;
SKIP: {
  skip 'PERL5OPT="-d:Agent" is not set',303 unless $^P==35;

  my $self=DB->new( 
    save_to_stack=>1,
    ignore_calling_class_re=>[qr/^Test2::/s,qr/^Test::/],);

  $SET='STACK_TO 3';
  stack_to(3);
  sub stack_to {
    ++$TESTS;
    $self->reset;
    for(1 .. $_[0]) {
      $self->depths->[$_]={depth=>$_,order_id=>$self->next_order_id,calls=>[]};
    }
  }
  sub close_to {
    my $id=shift;
    ++$TESTS;
    $self->close_to($id,{depth=>$id,order_id=>$self->next_order_id,calls=>[]});
    if($id==1) {
      #diag Dumper($self->depths);
      is_deeply($self->trace->[$#{$self->trace}],$self->depths->[$id],$SET.' ensure we were added to the stack');
      return;
    }
    my $owner=$id -1;
    #diag Dumper($self->depths->{$owner});
    cmp_ok($self->order_id,'>=',$self->depths->[$id]->{order_id},$SET.' validate the order id');
    my $cap=$self->depths->[$owner]->{calls}->$#*;
    is_deeply($self->depths->[$owner]->{calls}->[$cap],$self->depths->[$id],$SET.' '.$id.' ensure we are the proper child') or die Dumper($self);
  }

  $SET='CLOSE TO 3-1';
  close_to(3);
  close_to(2);
  close_to(1);
  $self->reset;
  $SET='CLOSE TO 1';
  close_to(1);
  #diag Dumper($self);
  close_to(1);
  #diag Dumper($self);
  diag "TOTAL_TESTS: $TESTS";

  {
    $SET='TEST BLOCK 1';
    diag "Starting $SET";
    $self->start_trace;
    run_test_1();
    $self->stop_trace;
    diag "Finished $SET";
  
    check_stack($self->trace,[
      {
        class_method=>'main::run_test_1',
        depth=>1,
        calls=>[
          {
            class_method=>'Test::More::diag',
            depth=>2,
            calls=>[],
          }
        ],
      }
    ]);
  }
  #diag Dumper $self->trace;
  {
    $SET='TEST BLOCK 2';

    $self->start_trace;

    run_test_1();
    run_test_1();

    $self->stop_trace;
  
    #diag Dumper $self->trace;
    {
    check_stack($self->trace,[
      {
        class_method=>'main::run_test_1',
        depth=>1,
        calls=>[
          {
            class_method=>'Test::More::diag',
            depth=>2,
            calls=>[],
          }
        ],
      },
      {
        class_method=>'main::run_test_1',
        depth=>1,
        calls=>[
          {
            class_method=>'Test::More::diag',
            depth=>2,
            calls=>[],
          }
        ],
      }
    ]);
    }
  }

  {
    $SET='TEST BLOCK 3 with evals';
    diag "Starting $SET";

    $self=DB->new(
      save_to_stack=>1,
      on_frame_end=>sub { 
        my ($self,$frame)=@_;
        #diag Dumper([$self->trace_id,$frame]) 
      }, 
      ignore_calling_class_re=>[qr/^Test2::/s,qr/^Test::/],
    );
    $self->start_trace;

    eval { 
      my $res=run_test_1();
      eval 'my $res=run_test_1();';
    };

    $self->stop_trace;
  
    #diag Dumper $self->trace;
    check_stack($self->trace,[
      {
        class_method=>'eval {...}',
        depth=>1,
        calls=>[
          {
            class_method=>'main::run_test_1',
            depth=>2,
            calls=>[
              {
                class_method=>'Test::More::diag',
                depth=>3,
                calls=>[],
              }
            ],
          },
          {
            class_method=>'eval {...}',
            depth=>2,
            calls=>[
              {
                class_method=>'main::run_test_1',
                depth=>3,
                calls=>[
                  {
                    depth=>4,
                    class_method=>'Test::More::diag',
                    calls=>[],
                  }
                ],
              }
            ],
          }
        ],
      },
    ]);
  }

  {
    $TESTS=0;
    $SET='TEST BLOCK 4 load Moo Objects';

    my $last_id=-1;
    $self=DB->new( 
      ignore_calling_class_re=>[qr/^Test2::/s,qr/^Test::/],
      ignore_begin_method=>1,
      save_to_stack=>1,
      ignore_methods=>{
        cmp_ok=>1,
        BEGIN=>1,
        Dumper=>1,
      },
      on_frame_end=>sub {
        my ($self,$frame,$depth)=@_;
        #diag Dumper($frame);
        cmp_ok($frame->{end_id},'>',$last_id,'ensure each frame is sequential') or die Dumper($frame);
        $last_id=$frame->{end_id};
      },
    );

    my $obj;
    
    undefer_all();
    undef $obj;
    $self->start_trace;

    sub {
      $obj=new TestMe;
      $obj->test_a(1,2,3);
    }->();

    $self->stop_trace;
    undef $obj;
    #diag Dumper($self->trace);
    check_stack($self->trace,[
      gm(qw( main::__ANON__ 1),
        gm(qw(TestMe::new  2)),
        gm(qw(TestMe::test_a 2),
          gm(qw(main::test_a 3), gm(qw(Test::More::diag 4)))
        )
      )
    ]);
  }
  {
    $TESTS=0;
    $SET='TEST BLOCK 5 Frame reconstruction';

    my $last_id=-1;
    my $frames={};
    $self=DB->new( 
      ignore_calling_class_re=>[qr/^Test2::/s,qr/^Test::/],
      ignore_begin_method=>1,
      save_to_stack=>0,
      ignore_methods=>{
        cmp_ok=>1,
        BEGIN=>1,
        Dumper=>1,
      },
      on_frame_end=>sub {
        my ($self,$frame,$depth)=@_;
        #diag Dumper($frame);
        cmp_ok($frame->{end_id},'>',$last_id,'ensure each frame is sequential') or die Dumper($frame);
        $last_id=$frame->{end_id};
        $frames->{$frame->{order_id}}=$frame;
      },
    );

    my $obj;
    $self->start_trace;

    sub {
      $obj=new TestMe;
      $obj->test_a(1,2,3);
    }->();

    $self->stop_trace;
    undef $obj;

    is_deeply($self->trace,[],'make sure $self->trace is empty');
    my $trace=rebuild_trace($frames);

    check_stack($trace,[
      gm(qw( main::__ANON__ 1),
        gm(qw(TestMe::new  2)),
        gm(qw(TestMe::test_a 2),
          gm(qw(main::test_a 3), gm(qw(Test::More::diag 4)))
        )
      )
    ]);
  }


  {
    my $scalar;
    my @list;
    $TESTS=0;
    $SET='RETURN TRACE';

    $self=DB->new( 
      ignore_calling_class_re=>[qr/^Test2::/s,qr/^Test::/],
      ignore_begin_method=>1,
      save_to_stack=>1,
    );
    $self->start_trace;
    $scalar=return_test();
    @list=return_test();
    $self->stop_trace;

    cmp_ok($scalar,'==',3,'ensure the scalar returned correctly');
    is_deeply(\@list,[1,2,3],'ensure the list returned is valid');
    

  }
  if(1){
    $TESTS=0;
    $SET='TEST BLOCK 7 require and SUPER';

    my $last_id=-1;
    my $frames={};
    $self=DB->new( 
      ignore_calling_class_re=>[qr/^Test2::/s,qr/^Test::/],
      ignore_begin_method=>1,
      save_to_stack=>0,
      ignore_methods=>{
        cmp_ok=>1,
        Dumper=>1,
      },
      on_frame_end=>sub {
        my ($self,$frame,$depth)=@_;
        #diag Dumper($frame);
        #$last_id=$frame->{end_id};
        #$frames->{$frame->{order_id}}=$frame;
      },
    );

    my $obj;
    $self->start_trace;
    require TestMe2;

    sub {
      $obj=new TestMe2;
      $obj->test_a(1,2,3);
    }->();

    $self->stop_trace;

    isa_ok($obj,'TestMe2');
    can_ok($obj,'test_a','test1');
    $obj->DESTROY;
    is_deeply($self->trace,[],'make sure $self->trace is empty');

  }
  {
    $TESTS=0;
    $SET='TEST BLOCK 8 Fatals';

    my $last_id=-1;
    my $frames={};
    $self=DB->new( 
      ignore_calling_class_re=>[qr/^Test2::/s,qr/^Test::/],
      ignore_begin_method=>1,
      save_to_stack=>1,
      ignore_methods=>{
        cmp_ok=>1,
        Dumper=>1,
      },
      on_frame_end=>sub {
        my ($self,$frame,$depth)=@_;
        ok(1,'this unit test should not end up in our trace');
        #diag Dumper($frame);
        #$last_id=$frame->{end_id};
        #$frames->{$frame->{order_id}}=$frame;
      },
    );

    my $obj;
    $self->start_trace;

    $obj=new TestMe2;
    eval {
      $obj->fatal;
    };

    $self->stop_trace;
    check_stack($self->trace,[
      {
        calls => [],
        class_method => 'TestMe2::new',
        depth => 1,
      },
      {
        caller_class => 'main',
        calls => [
          {
            calls => [],
            class_method => 'TestMe::fatal',
            depth => 2,
          }
        ],
        class_method => 'eval {...}',
        depth => 1,
      }
    ]);
  }
  {
    $TESTS=0;
    $SET='BLOCK 8 whole plate';
    diag "Starting $SET";
    $self->start_trace;
    require TestMe3;
    sub {
    my $obj=new TestMe3;

    }->();
    $self->stop_trace;
    #diag Dumper($self->trace);
    cmp_ok($self->trace->$#*,'==',2,$SET.' there should be 3 elements at the top level, 1. require, 2. Anonymous sub, 3. DESTROY');
  }
  {
    $TESTS=0;
    $SET='BLOCK 9 jumps';
    $self=DB->new(
      ignore_calling_class_re=>[qr/^Test2::/s,qr/^Test::/],
      ignore_begin_method=>1,
      save_to_stack=>1,
    );

    $self->start_trace;
    my $obj=new TestMe3;
    $obj->jump;
    $obj->jump_method;

    $self->stop_trace;

   cmp_ok($self->trace->$#*,'==',2,$SET.' Should have 3 elements');
  }
  {
    $TESTS=0;
    $SET='BLOCK 10 filter on args with depth testing';
    $self=DB->new(
      ignore_calling_class_re=>[qr/^Test2::/s,qr/^Test::/],
      ignore_begin_method=>1,
      save_to_stack=>1,
    );

    $self->start_trace;
    my $obj=new TestMe3;
    $obj->test_a([1,2,3]);


    $self->stop_trace;
    diag Dumper($self->trace);
    check_stack($self->trace,[
      gm('TestMe3::new',1),
      gm('TestMe3::test_a',1),
    ]);

  }

  if(1){
    $TESTS=0;
    $SET='BLOCK 11 AnyEvent testing';
    $self=DB->new(
      ignore_calling_class_re=>[qr/^Test2::/s,qr/^Test::/,],
      ignore_begin_method=>1,
      save_to_stack=>1,
      filter_on_args=>sub {
        my ($self,$frame,$args,$raw_caller)=@_;
        if($args->$#*!=-1 && defined($args->[0]) && blessed($args->[0])) {
          if(my $cb=$args->[0]->can('___db_stack_filter')) {
            return $args->[0]->$cb(@_);
          }
        }
        return 1;
      },
    );


    my $path=File::Spec->catfile($dir,'test');
    my $fh=IO::File->new($path,'>');

    my $str='';
    for(1 .. 3) {
      my $line="$_\n";
      $str .=$line;
      $fh->print($line);
    }


    $fh->close;

    $self->start_trace;

    my $cv=AnyEvent->condvar;

    my $check='';
    my $watcher;
    {
    $fh=IO::File->new($path,'<');
    $watcher=AnyEvent->io(
      fh=>$fh,
      poll=>'r',
      cb=>sub {
        my $line=$fh->getline;
        if(defined($line)) {
          $check .=$line;

        } else {
          $fh->close;
          undef $watcher;
          undef $fh;
          $cv->send('test');
        }
      }
    );
    $cv->recv;
    }

    $self->stop_trace;
    diag Dumper($self->trace);
    cmp_ok($str,'eq',$check,'make sure our calls to anyevent work');
  }
  {
    $SET='Pack Testing';
    $TESTS=0;
    my $check;
    sub test_app { \&test_responder }

    sub test_responder {
      my $responder = shift;
      my $writer = $responder->([ 200, [ 'Content-Type', 'text/plain' ]]);
      $check='';
      for(my $id=0;$id<2;++$id) {
        write_chunk($writer,$id);
        write_chunk($writer,$id);
      }
      $writer->close;
    }
    sub write_chunk {
      my ($writer,$id)=@_;
      my $line="Line: $id\n";
      $check .=$line;
      $writer->write($line);
    }
    my $test = Plack::Test->create(\&test_app);
    my $get=GET '/';
    my $res=$test->request($get);
    cmp_ok($res->code,'==',200,'establish a base line that our hello world streaming app is working');
    cmp_ok($res->content,'eq',$check,'ensure that our content is not corrupted');

    
    $DB::AGENT=undef;
    {
    no warnings;
    # force a trace every reqest
    $Plack::Middleware::Devel::Agent::Plack::TRACE_EVERY=1;
    $Plack::Middleware::Devel::Agent::Plack::AGENT_OPTIONS{save_to_stack}=0;
    $Plack::Middleware::Devel::Agent::Plack::AGENT_OPTIONS{on_frame_end}=sub {
      my ($agent,$frame)=@_;
      my $str='';
      my $fh;
      open($fh,'>',\$str);

      flush_row($agent,$frame,$fh);
      $fh->close;
      diag $str;
    };
    $Plack::Middleware::Devel::Agent::Plack::AGENT_OPTIONS{ignore_calling_class_re}=[qr/^Test2::/s,qr/^Test::/,];
    $Plack::Middleware::Devel::Agent::Plack::AGENT_OPTIONS{excludes}->{'Plack::Test::MockHTTP'}=1;
    
    $Plack::Middleware::Devel::Agent::Plack::AFTER_TRACE=sub {
      my ($db,$id,$res,$env)=@_;
      diag Dumper($res);
      $self=$db;
    };
    }

    my $org=$check;
    $test = Plack::Test->create(Plack::Middleware::Devel::Agent::Plack->wrap(\&test_app));
    $get=GET '/';
    $res=$test->request($get);
    $DB::AGENT->stop_trace if defined $DB::AGENT;
    cmp_ok($res->code,'==',200,'should get a code 200');#or die $res->status_line;
    diag $res->content;
    diag Dumper(\%Plack::Middleware::Devel::Agent::Plack::AGENT_OPTIONS);
    diag Dumper(\%Plack::Middleware::Devel::Agent::Plack::SELF_EXCLUDES);


  }
}
sub rebuild_trace {
  my ($frames)=@_;
  my @keys=sort { $a<=>$b } keys $frames->%*;
  my $trace=[];
  foreach my $key (@keys) {
    my $frame=$frames->{$key};

    # stick this in our root execution hook
    push @$trace,$frame if $frame->{depth}==1;
    my $owner_id=$frame->{owner_id};
    
    next unless exists $frames->{$owner_id};
    push $frames->{$owner_id}->{calls}->@*,$frame 
  }
  return $trace;
}

sub gm {
  my ($method,$depth,@calls)=@_;
  return {
    class_method=>$method,
    depth=>$depth,
    calls=>[@calls],
  },
}

sub run_test_1 {
    diag "sending output";
}
sub test_a {
  diag Dumper(@_);  
}


sub check_stack {
  my ($cmp,$check)=@_;
  ++$TESTS;
  cmp_ok($#{$cmp},'==',$#{$check},$SET.' both stacks should be the same size') or die Dumper($cmp,$check);
  while(my ($id,$check)=each @$check) {
    ++$TESTS;
    my $cmp=$cmp->[$id];
    check_methods($cmp,$check);
  }
}

sub check_methods {
  my ($cmp,$check)=@_;
  ++$TESTS;
  my $qm=quotemeta $check->{class_method};
  my $re=qr/^$qm/;
  like($cmp->{class_method},$re,$SET.' class methd check') or die Dumper($cmp,$check);
  foreach my $key (qw(duration depth line)) {
    ++$TESTS;
    ok(looks_like_number($cmp->{$key}),$SET." check $key") or die Dumper($cmp);
  }
  ++$TESTS;
  check_stack($cmp->{calls},$check->{calls});
}

sub return_test {
  return (1,2,3);
}
