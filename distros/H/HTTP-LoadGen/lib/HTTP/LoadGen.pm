package HTTP::LoadGen;

use 5.008008;
use strict;
no warnings qw/uninitialized/;

sub tlscache ();
sub conncache ();

use HTTP::LoadGen::Run;
BEGIN{ HTTP::LoadGen::Run::_dbg->import }

use Coro;
use Coro::Semaphore ();
use Coro::Specific ();
use Coro::Timer ();
use Coro::Handle;
use AnyEvent;
use AnyEvent::TLS;
use Exporter ();
use Scalar::Util ();

{our $VERSION = '0.07';}

BEGIN {
  our %EXPORT_TAGS=
    (
     common=>[qw!loadgen threadnr done userdata options rng rnd delay
		 register_iterator get_iterator follow_3XX!],
     const=>\@HTTP::LoadGen::Run::EXPORT,
    );
  my %seen;
  foreach my $v (values %EXPORT_TAGS) {
    undef @seen{@$v} if @$v;
  }
  our @EXPORT_OK=@{$EXPORT_TAGS{all}=[keys %seen]};
}

use constant {
  TD_USER=>0,
  TD_RNG=>1,
  TD_THREADNR=>2,
  TD_DONE=>3,
  TD_CONN_CACHE=>4,
  TD_TLS_CACHE=>5,
};

my $td;				# thread specific data
our $o;				# the global config hash

sub rnd;			# predeclaration
sub import {
  my $name=shift;
  local *export=\&Exporter::export;
  Exporter::export_to_level $name, 1, $name, map {
    my $what=$_; local $_;
    if($what eq '-rand') {
      *CORE::GLOBAL::rand=\&rnd;
      ();
    } elsif($what eq ':all') {
      our %EXPORT_TAGS;
      unless( exists $EXPORT_TAGS{sb} ) {
	require HTTP::LoadGen::ScoreBoard;
	require HTTP::LoadGen::Logger;
	HTTP::LoadGen::ScoreBoard->import
	    (@HTTP::LoadGen::ScoreBoard::EXPORT_OK);
	*get_logger=\&HTTP::LoadGen::Logger::get;
	$EXPORT_TAGS{sb}=\@HTTP::LoadGen::ScoreBoard::EXPORT_OK;
	$EXPORT_TAGS{log}=[qw!get_logger!];
	my %seen;
	foreach my $v (values %EXPORT_TAGS) {
	  undef @seen{@$v} if @$v;
	}
	our @EXPORT_OK=@{$EXPORT_TAGS{all}=[keys %seen]};
      }
      $what;
    } else {
      $what;
    }
  } @_;
}

sub create_proc {
  my ($how_many, $init, $handler, $exit)=@_;

  AnyEvent::detect;

  my @watcher;
  my %status;
  my $sem=Coro::Semaphore->new;

  pipe my($r, $w);
  pipe my($r2, $w2);

  for( my $i=0; $i<$how_many; $i++ ) {
    my $pid;
    select undef, undef, undef, 0.1 until defined ($pid=fork);
    unless($pid) {
      close $r;
      close $w2;
      $r2=unblock $r2;
      $init->($i) if $init;
      close $w;			# signal parent
      $r2->readable;		# wait for start signal
      undef $r2;
      my $rc=$handler->($i);

      exit $exit->($i, $rc) if $exit;
      exit $rc;
    }
    push @watcher, AE::child $pid, sub {
      $status{$_[0]}=[($_[1]>>8)&0xff, $_[1]&0x7f, $_[1]&0x80];
      $sem->up;
    };
    $sem->adjust(-1);
  }

  close $w;
  unblock($r)->readable;	# wait for children to finish ChildInit

  return [$w2, $sem, \@watcher, \%status];
}

sub start_proc {
  my ($arr)=@_;
  close $arr->[0];
  $arr->[1]->down;
  return $arr->[3];
}

sub _start_thr {
  my ($threadnr, $sem, $handler)=@_;
  $sem->adjust(-1);
  async {
    $handler->(@_);
    $sem->up;
  } $threadnr;
}

sub ramp_up {
  my ($procnr, $nproc, $start, $max, $duration, $handler)=@_;

  $duration=300 if $duration<=0;

  # begin with $start (system total) threads and start over a period
  # of $duration seconds up to $max threads.

  my $sem=Coro::Semaphore->new(1);
  my $initial_sleep=($nproc + $procnr - $start % $nproc) % $nproc + 1;

  my $i=$procnr;
  for(; $i<$start; $i+=$nproc ) {
    _start_thr $i, $sem, $handler;
  }

  return $sem if $i>=$max;

  my $interval=$duration/($max-$start);
  $initial_sleep*=$interval;
  $interval*=$nproc;

  my $cb=Coro::rouse_cb;

  my $tm;
  $tm=AE::timer $initial_sleep, $interval, sub {
    _start_thr $i, $sem, $handler;
    $i+=$nproc;
    unless ($i<$max) {
      undef $tm;
      $cb->();
    }
  };
  Coro::rouse_wait;

  return $sem;
}

sub tlscache () {$$td->[TD_TLS_CACHE]}
sub conncache () {$$td->[TD_CONN_CACHE]}
sub threadnr () {$$td->[TD_THREADNR]}
sub done () : lvalue {$$td->[TD_DONE]}
sub userdata () : lvalue {$$td->[TD_USER]}
sub options () {$o}
sub rng () : lvalue {$$td->[TD_RNG]}

sub rnd (;$) {
  my $rng=rng;
  (ref $rng eq 'CODE' ? $rng->($_[0]||1) :
   ref $rng ? $rng->rand($_[0]||1) :
   CORE::rand $_[0]);
}

sub delay {
  my ($prefix, $param)=@_;
  return if delete $param->{'skip'.$prefix.'delay'};
  return unless exists $param->{$prefix.'delay'};
  my $sec=$param->{$prefix.'delay'};
  if( exists $param->{$prefix.'jitter'} ) {
    my $jitter=$param->{$prefix.'jitter'};
    $sec+=-$jitter+rnd(2*$jitter);
  }
  #D warn "\u${prefix}Delay: $sec sec\n";
  Coro::Timer::sleep $sec if $sec>0;
}

my (%services, %known_iterators);

sub register_iterator {
  my $code=pop;
  if( Scalar::Util::reftype $code eq 'CODE' ) {
    @known_iterators{@_}=($code)x(+@_);
  } else {
    die "CODE reference expected";
  }
}

sub get_iterator {
  my ($name)=@_;
  exists $known_iterators{$name} and return $known_iterators{$name};
  return $known_iterators{''};
}

{
  my %keep=('user-agent'=>1, 'referer'=>1);
  sub follow_3XX {
    my ($rc, $el)=@_;

    # we are stricter here than most browsers because we do not follow
    # partial URLs.
    if( $rc->[RC_STATUS]=~/^3/ and
	exists $rc->[RC_HEADERS]->{location} and
	$rc->[RC_HEADERS]->{location}->[0]=~m!^(https?):// # scheme
					      ([^:/]+)	   # host
					      (:[0-9]+)?   # optional port
					      (.*)!ix ) {  # uri
      # follow location
      my $scheme=lc($1);
      my $host=$2;
      my $port=$3||$services{$scheme};
      my $uri=$4||'/';

      my @h;
      if( exists $el->[RQ_PARAM]->{headers} ) {
	my $hdr=$el->[RQ_PARAM]->{headers};
	for (my $i=0; $i<@$hdr; $i+=2) {
	  push @h, $hdr->[$i], $hdr->[$i+1] if exists $keep{lc $hdr->[$i]};
	}
      }

      return ['GET', $scheme, $host, $port, $uri,
	      {keepalive=>KEEPALIVE, followed=>1, headers=>\@h}];
    }
  }
}

BEGIN {
  %services=(http=>80, https=>443);

  register_iterator '', default=>sub {
    my $urls=options->{URLList};
    my $nurls=@$urls;
    my $i=0;
    return sub {
      return if $i>=$nurls;
      return $urls->[$i++];
    };
  };

  register_iterator random_start=>sub {
    my $urls=options->{URLList};
    my $nurls=@$urls;
    my ($i, $off)=(0, int rnd $nurls);
    return sub {
      return if $i>=$nurls;
      return $urls->[($off+$i++) % $nurls];
    };
  };

  register_iterator follow=>sub {
    my %save_delay;
    my $it=@_ ? $_[0] : get_iterator('')->();
    return sub {
      my ($rc, $el)=@_;

      my $next=follow_3XX $rc, $el;
      return $next if $next;

      delay 'post', \%save_delay;

      # get next request
      $next=$it->($rc, $el);
      return unless $next;;

      # save postdelay
      if( exists $next->[RQ_PARAM]->{postdelay} ) {
	$save_delay{postdelay}=$next->[RQ_PARAM]->{postdelay};
	$save_delay{postjitter}=$next->[RQ_PARAM]->{postjitter}
	  if exists $next->[RQ_PARAM]->{postjitter};
	$next->[RQ_PARAM]->{skippostdelay}=1;
      }

      return $next;
    };
  };

  register_iterator random_start_follow=>sub {
    @_=get_iterator('random_start')->();
    goto &{get_iterator 'follow'};
  };
}

sub loadgen {
  local $o=+{@_==1 ? %{$_[0]} : @_};

  my $nproc=($o->{NWorker}||=1);

  die "'URLList' or 'InitURLs' invalid"
    unless (exists $o->{InitURLs} &&
	        Scalar::Util::reftype $o->{InitURLs} eq 'CODE' or
	    exists $o->{URLList} && (!exists $o->{InitURLs} ||
				     exists $known_iterators{$o->{InitURLs}}));

  my $init=sub {
    my ($procnr)=@_;

    $td=Coro::Specific->new();	# thread specific data

    AnyEvent::TLS::init;

    HTTP::LoadGen::Run::dnscache=$o->{dnscache} if exists $o->{dnscache};
    $o->{ProcInit}->($procnr) if exists $o->{ProcInit};

    $o->{before}=sub {
      my ($el)=@_;
      delay 'pre', $el->[5];
      $o->{ReqStart}->($el) if exists $o->{ReqStart};
    };

    $o->{after}=sub {
      my ($rc, $el, $connh)=@_;
      $o->{ReqDone}->($rc, $el, $connh) if exists $o->{ReqDone};
      return 1 if done;
      delay 'post', $el->[5];
      return;
    };

    if( exists $o->{InitURLs} ) {
      $o->{InitURLs}=$known_iterators{$o->{InitURLs}} unless ref $o->{InitURLs};
    } else {
      $o->{InitURLs}=$known_iterators{''};
    }
  };
  my $exit;
  $exit=$o->{ProcExit} if exists $o->{ProcExit};

  $o->{ParentInit}->() if exists $o->{ParentInit};

  start_proc create_proc $nproc, $init, sub {
    my ($procnr)=@_;

    ramp_up($procnr, $nproc, $o->{RampUpStart}||$nproc,
	    $o->{RampUpMax}||$nproc, $o->{RampUpDuration}||300, sub {
	      my ($threadnr)=@_;

	      my $data=[];
	      $$td=$data;

	      $data->[TD_CONN_CACHE]={};
	      $data->[TD_TLS_CACHE]={};
	      $data->[TD_THREADNR]=$threadnr;
	      $data->[TD_USER]=$o->{ThreadInit}->() if exists $o->{ThreadInit};

	      HTTP::LoadGen::Run::run_urllist $o;

	      $o->{ThreadExit}->() if exists $o->{ThreadExit};
	    })->down;

    return 0;
  }, $exit;

  $o->{ParentExit}->() if exists $o->{ParentExit};
}

1;
