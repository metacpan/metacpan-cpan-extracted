package JobCenter::Client::Mojo;
use Mojo::Base 'Mojo::EventEmitter';

our $VERSION = '0.40'; # VERSION

#
# Mojo's default reactor uses EV, and EV does not play nice with signals
# without some handholding. We either can try to detect EV and do the
# handholding, or try to prevent Mojo using EV.
#
BEGIN {
	$ENV{'MOJO_REACTOR'} = 'Mojo::Reactor::Poll' unless $ENV{'MOJO_REACTOR'};
}

# more Mojolicious
use Mojo::IOLoop;
use Mojo::IOLoop::Stream;
use Mojo::Log;

# standard perl
use Carp qw(croak);
use Cwd qw(realpath);
use Data::Dumper;
use Encode qw(encode_utf8 decode_utf8);
use File::Basename;
use IO::Handle;
use POSIX ();
use Storable;
use Sys::Hostname;

# from cpan
use JSON::RPC2::TwoWay 0.02;
# JSON::RPC2::TwoWay depends on JSON::MaybeXS anyways, so it can be used here
# without adding another dependency
use JSON::MaybeXS qw(JSON decode_json encode_json);
use MojoX::NetstringStream 0.06; # for the enhanced close

has [qw(
	actions address auth clientid conn debug ioloop jobs json
	lastping log method ns ping_timeout port rpc timeout tls token who
)];

# keep in sync with the jobcenter
use constant {
	WORK_OK                => 0,  # exit codes for work method
	WORK_PING_TIMEOUT      => 92,
	WORK_CONNECTION_CLOSED => 91,
};

sub new {
	my ($class, %args) = @_;
	my $self = $class->SUPER::new();

	my $address = $args{address} // '127.0.0.1';
	my $debug = $args{debug} // 0; # or 1?
	$self->{ioloop} = $args{ioloop} // Mojo::IOLoop->singleton;
	my $json = $args{json} // 1;
	my $log = $args{log} // Mojo::Log->new(level => ($debug) ? 'debug' : 'info');
	my $method = $args{method} // 'password';
	my $port = $args{port} // 6522;
	my $timeout = $args{timeout} // 60;
	my $tls = $args{tls} // 0;
	my $tls_ca = $args{tls_ca};
	my $tls_cert = $args{tls_cert};
	my $tls_key = $args{tls_key};
	my $token = $args{token} or croak 'no token?';
	my $who = $args{who} or croak 'no who?';

	$self->{address} = $address;
	$self->{debug} = $args{debug} // 1;
	$self->{jobs} = {};
	$self->{json} = $json;
	$self->{ping_timeout} = $args{ping_timeout} // 300;
	$self->{log} = $log;
	$self->{method} = $method;
	$self->{port} = $port;
	$self->{timeout} = $timeout;
	$self->{tls} = $tls;
	$self->{tls_ca} = $tls_ca;
	$self->{tls_cert} = $tls_cert;
	$self->{tls_key} = $tls_key;
	$self->{token} = $token;
	$self->{who} = $who;
	$self->{autoconnect} = ($args{autoconnect} //= 1);

	return $self if !$args{autoconnect};

	$self->connect;

	return $self if $self->{auth};
	return;
}

sub connect {
	my $self = shift;

	delete $self->ioloop->{__exit__};
	delete $self->{auth};
	$self->{actions} = {};

	$self->on(disconnect => sub {
		my ($self, $code) = @_;
		#$self->{_exit} = $code;
		$self->ioloop->stop;
	});

	my $rpc = JSON::RPC2::TwoWay->new(debug => $self->{debug}) or croak 'no rpc?';
	$rpc->register('greetings', sub { $self->rpc_greetings(@_) }, notification => 1);
	$rpc->register('job_done', sub { $self->rpc_job_done(@_) }, notification => 1);
	$rpc->register('ping', sub { $self->rpc_ping(@_) });
	$rpc->register('task_ready', sub { $self->rpc_task_ready(@_) }, notification => 1);

	my $clarg = {
		address => $self->{address},
		port => $self->{port},
		tls => $self->{tls},
	};
	$clarg->{tls_ca} = $self->{tls_ca} if $self->{tls_ca};
	$clarg->{tls_cert} = $self->{tls_cert} if $self->{tls_cert};
	$clarg->{tls_key} = $self->{tls_key} if $self->{tls_key};

	my $clientid = $self->ioloop->client(
		$clarg => sub {
		my ($loop, $err, $stream) = @_;
		if ($err) {
			$err =~ s/\n$//s;
			$self->log->info('connection to API failed: ' . $err);
			$self->{auth} = 0;
			return;
		}
		my $ns = MojoX::NetstringStream->new(stream => $stream);
		$self->{ns} = $ns;
		my $conn = $rpc->newconnection(
			owner => $self,
			write => sub { $ns->write(@_) },
		);
		$self->{conn} = $conn;
		$ns->on(chunk => sub {
			my ($ns2, $chunk) = @_;
			#say 'got chunk: ', $chunk;
			my @err = $conn->handle($chunk);
			$self->log->debug('chunk handler: ' . join(' ', grep defined, @err)) if @err;
			$ns->close if $err[0];
		});
		$ns->on(close => sub {
			# this cb is called during global destruction, at
			# least on old perls where
			# Mojo::Util::_global_destruction() won't work
			return unless $conn;
			$conn->close;
			$self->log->info('connection to API closed');
			$self->emit(disconnect => WORK_CONNECTION_CLOSED); # todo doc
		});
	});

	$self->{rpc} = $rpc;
	$self->{clientid} = $clientid;

	# handle timeout?
	my $tmr = $self->ioloop->timer($self->{timeout} => sub {
		my $loop = shift;
		$self->log->error('timeout wating for greeting');
		$loop->remove($clientid);
		$self->{auth} = 0;
	});

	$self->log->debug('starting handshake');

	$self->_loop(sub { not defined $self->{auth} });

	$self->log->debug('done with handhake?');

	$self->ioloop->remove($tmr);
	$self->unsubscribe('disconnect');
	1;
}

sub is_connected {
	my $self = shift;
	return $self->{auth} && !$self->ioloop->{__exit__};
}

sub rpc_greetings {
	my ($self, $c, $i) = @_;
	$self->ioloop->delay(
		sub {
			my $d = shift;
			die "wrong api version $i->{version} (expected 1.1)" unless $i->{version} eq '1.1';
			$self->log->info('got greeting from ' . $i->{who});
			$c->call('hello', {who => $self->who, method => $self->method, token => $self->token}, $d->begin(0));
		},
		sub {
			my ($d, $e, $r) = @_;
			my $w;
			#say 'hello returned: ', Dumper(\@_);
			die "hello returned error $e->{message} ($e->{code})" if $e;
			die 'no results from hello?' unless $r;
			($r, $w) = @$r;
			if ($r) {
				$self->log->info("hello returned: $r, $w");
				$self->{auth} = 1;
			} else {
				$self->log->error('hello failed: ' . ($w // ''));
				$self->{auth} = 0; # defined but false
			}
		}
	)->catch(sub {
		my ($err) = @_;
		$self->log->error('something went wrong in handshake: ' . $err);
		$self->{auth} = '';
	});
}

sub rpc_job_done {
	my ($self, $conn, $i) = @_;
	my $job_id = $i->{job_id};
	my $outargs = $i->{outargs};
	my $outargsj = encode_json($outargs);
	$outargs = $outargsj if $self->{json};
	$outargsj = decode_utf8($outargsj); # for debug printing
	my $rescb = delete $self->{jobs}->{$job_id};
	if ($rescb) {
		$self->log->debug("got job_done: for job_id  $job_id result: $outargsj");
		local $@;
		eval {
			$rescb->($job_id, $outargs);
		};
		$self->log->info("got $@ calling result callback") if $@;
	} else {
		$self->log->debug("got job_done for unknown job $job_id result: $outargsj");
	}
}

sub call {
	my ($self, %args) = @_;
	my ($done, $job_id, $outargs);
	$args{cb1} = sub {
		($job_id, $outargs) = @_;
		$done++ unless $job_id;
	};
	$args{cb2} = sub {
		($job_id, $outargs) = @_;
		$done++;
	};
	$self->call_nb(%args);

	$self->_loop(sub { !$done });

	return $job_id, $outargs;
}

sub call_nb {
	my ($self, %args) = @_;
	my $wfname = $args{wfname} or die 'no workflowname?';
	my $vtag = $args{vtag};
	my $inargs = $args{inargs} // '{}';
	my $callcb = $args{cb1} // die 'no call callback?';
	my $rescb = $args{cb2} // die 'no result callback?';
	my $timeout = $args{timeout} // $self->timeout * 5; # a bit hackish..
	my $reqauth = $args{reqauth};
	my $clenv = $args{clenv};
	my $inargsj;

	if ($self->{json}) {
		$inargsj = $inargs;
		$inargs = decode_json($inargs);
		croak 'inargs is not a json object' unless ref $inargs eq 'HASH';
		if ($clenv) {
			$clenv = decode_json($clenv);
			croak 'clenv is not a json object' unless ref $clenv eq 'HASH';
		}
		if ($reqauth) {
			$reqauth = decode_json($reqauth);
			croak 'reqauth is not a json object' unless ref $reqauth eq 'HASH';
		}
	} else {
		croak 'inargs should be a hashref' unless ref $inargs eq 'HASH';
		# test encoding
		$inargsj = encode_json($inargs);
		if ($clenv) {
			croak 'clenv should be a hashref' unless ref $clenv eq 'HASH';
		}
		if ($reqauth) {
			croak 'reqauth should be a hashref' unless ref $reqauth eq 'HASH';
		}
	}

	$inargsj = decode_utf8($inargsj);
	$self->log->debug("calling $wfname with '" . $inargsj . "'" . (($vtag) ? " (vtag $vtag)" : ''));

	$self->ioloop->delay(
		sub {
			my $d = shift;
			$self->conn->call('create_job', {
				wfname => $wfname,
				vtag => $vtag,
				inargs => $inargs,
				timeout => $timeout,
				($clenv ? (clenv => $clenv) : ()),
				($reqauth ? (reqauth => $reqauth) : ()),
			}, $d->begin(0));
		},
		sub {
			my ($d, $e, $r) = @_;
			my ($job_id, $msg);
			if ($e) {
				$self->log->error("create_job returned error: $e->{message} ($e->{code}");
				$msg = "$e->{message} ($e->{code}"
			} else {
				($job_id, $msg) = @$r; # fixme: check for arrayref?
				if ($msg) {
					$self->log->error("create_job returned error: $msg");
				} elsif ($job_id) {
					$self->log->debug("create_job returned job_id: $job_id");
					$self->jobs->{$job_id} = $rescb;
				}
			}
			if ($msg) {
				$msg = {error => $msg} unless ref $msg;
				$msg = encode_json($msg) if $self->{json};
			}
			$callcb->($job_id, $msg);
		}
	)->catch(sub {
		my ($err) = @_;
		$self->log->error("Something went wrong in call_nb: $err");
		$err = { error => $err };
		$err = encode_json($err) if $self->{json};
		$callcb->(undef, $err);
	});
}

sub close {
	my ($self) = @_;

	$self->log->debug('closing connection');
	$self->conn->close();
	$self->ns->close();
	%$self = ();
}

sub find_jobs {
	my ($self, $filter) = @_;
	croak('no filter?') unless $filter;

	#print 'filter: ', Dumper($filter);
	$filter = encode_json($filter) if ref $filter eq 'HASH';

	my ($done, $err, $jobs);
	$self->ioloop->delay(
	sub {
		my $d = shift;
		# fixme: check results?
		$self->conn->call('find_jobs', { filter => $filter }, $d->begin(0));
	},
	sub {
		#say 'find_jobs call returned: ', Dumper(\@_);
		my ($d, $e, $r) = @_;
		if ($e) {
			$self->log->error("find_jobs got error $e->{message} ($e->{code})");
			$err = $e->{message};
			$done++;
			return;
		}
		$jobs = $r;
		$done++;
	})->catch(sub {
		my ($err) = @_;
		$self->log->error("something went wrong with get_job_status: $err");
		$done++;
	});

	$self->_loop(sub { !$done });

	return $err, @$jobs if ref $jobs eq 'ARRAY';
	return $err;
}

sub get_api_status {
	my ($self, $what) = @_;
	croak('no what?') unless $what;

	my $result;
	$self->ioloop->delay(
	sub {
		my $d = shift;
		$self->conn->call('get_api_status', { what => $what }, $d->begin(0));
	},
	sub {
		#say 'call returned: ', Dumper(\@_);
		my ($d, $e, $r) = @_;
		if ($e) {
			$self->log->error("get_api_status got error $e->{message} ($e->{code})");
			$result = $e->{message};
			return;
		}
		$result = $r;
	})->catch(sub {
		my ($err) = @_;
		$self->log->eror("something went wrong with get_api_status: $err");
	})->wait();

	return $result;
}

sub get_job_status {
	my ($self, $job_id) = @_;
	croak('no job_id?') unless $job_id;

	my ($done, $job_id2, $outargs);
	$self->get_job_status_nb(
		job_id => $job_id,
		statuscb => sub {
			($job_id2, $outargs) = @_;
			$done++;
			return;
		},
	);
	$self->_loop(sub { !$done });
	return $job_id2, $outargs;
}

sub get_job_status_nb {
	my ($self, %args) = @_;
	my $job_id = $args{job_id} or
		croak('no job_id?');

	my $statuscb = $args{statuscb};
	croak('statuscb should be a coderef')
		if ref $statuscb ne 'CODE';

	my $notifycb = $args{notifycb};
	croak('notifycb should be a coderef')
		if $notifycb and ref $notifycb ne 'CODE';

	#my ($done, $job_id2, $outargs);
	$self->ioloop->delay(
	sub {
		my $d = shift;
		# fixme: check results?
		$self->conn->call(
			'get_job_status', {
				job_id => $job_id,
				notify => ($notifycb ? JSON->true : JSON->false),
			}, $d->begin(0)
		);
	},
	sub {
		#say 'call returned: ', Dumper(\@_);
		my ($d, $e, $r) = @_;
		#$self->log->debug("get_job_satus_nb got job_id: $res msg: $msg");
		if ($e) {
			$self->log->error("get_job_status got error $e->{message} ($e->{code})");
			$statuscb->(undef, $e->{message});
			return;
		}
		my ($job_id2, $outargs) = @$r;
		if ($notifycb and !$job_id2 and !$outargs) {
			$self->jobs->{$job_id} = $notifycb;
		}
		$outargs = encode_json($outargs) if $self->{json} and ref $outargs;
		$statuscb->($job_id2, $outargs);
		return;
	})->catch(sub {
		my ($err) = @_;
		$self->log->error("Something went wrong in get_job_status_nb: $err");
		$err = { error => $err };
		$err = encode_json($err) if $self->{json};
		$statuscb->(undef, $err);
	});
}

sub ping {
	my ($self, $timeout) = @_;

	$timeout //= $self->timeout;
	my ($done, $ret);

	$self->ioloop->timer($timeout => sub {
		$done++;
	});

	$self->conn->call('ping', {}, sub {
		my ($e, $r) = @_;
		if (not $e and $r and $r =~ /pong/) {
			$ret = 1;
		} else {
			%$self = ();
		}
		$done++;
	});

	$self->_loop(sub { !$done });

	return $ret;
}

sub work {
	my ($self, $prepare) = @_;

	my $pt = $self->ping_timeout;
	my $tmr;
	$tmr = $self->ioloop->recurring($pt => sub {
		my $ioloop = shift;
		$self->log->debug('in ping_timeout timer: lastping: '
			 . ($self->lastping // 0) . ' limit: ' . (time - $pt) );
		return if ($self->lastping // 0) > time - $pt;
		$self->log->error('ping timeout');
		$ioloop->remove($self->clientid);
		$ioloop->remove($tmr);
		$ioloop->{__exit__} = WORK_PING_TIMEOUT; # todo: doc
		$ioloop->stop;
	}) if $pt > 0;
	$self->on(disconnect => sub {
		my ($self, $code) = @_;
		$self->ioloop->{__exit__} = $code;
		$self->ioloop->stop;
	});
	return 0 if $prepare;

	$self->ioloop->{__exit__} = WORK_OK;
	$self->log->debug('JobCenter::Client::Mojo starting work');
	$self->ioloop->start unless Mojo::IOLoop->is_running;
	$self->log->debug('JobCenter::Client::Mojo done?');
	$self->ioloop->remove($tmr) if $tmr;

	return $self->ioloop->{__exit__};
}

sub stop {
	my ($self, $exit) = @_;
	$self->ioloop->{__exit__} = $exit;
	$self->ioloop->stop;
}

sub create_slotgroup {
	my ($self, $name, $slots) = @_;
	croak('no slotgroup name?') unless $name;

	my $result;
	$self->ioloop->delay(
	sub {
		my $d = shift;
		$self->conn->call('create_slotgroup', { name => $name, slots => $slots }, $d->begin(0));
	},
	sub {
		#say 'call returned: ', Dumper(\@_);
		my ($d, $e, $r) = @_;
		if ($e) {
			$self->log->error("create_slotgroup got error $e->{message}");
			$result = $e->{message};
			return;
		}
		$result = $r;
	})->catch(sub {
		my ($err) = @_;
		$self->log->eror("something went wrong with create_slotgroup: $err");
	})->wait();

	return $result;
}

sub announce {
	my ($self, %args) = @_;
	my $actionname = $args{actionname} or croak 'no actionname?';
	my $cb = $args{cb} or croak 'no cb?';
	#my $async = $args{async} // 0;
	my $mode = $args{mode} // (($args{async}) ? 'async' : 'sync');
	croak "unknown callback mode $mode" unless $mode =~ /^(subproc|async|sync)$/;
	my $undocb = $args{undocb};
	my $host = hostname;
	my $workername = $args{workername} // "$self->{who} $host $0 $$";

	croak "already have action $actionname" if $self->actions->{$actionname};

	my $err;
	$self->ioloop->delay(
	sub {
		my $d = shift;
		# fixme: check results?
		$self->conn->call('announce', {
				 workername => $workername,
				 actionname => $actionname,
				 slotgroup => $args{slotgroup},
				 slots => $args{slots},
				 (($args{filter}) ? (filter => $args{filter}) : ()),
			}, $d->begin(0));
	},
	sub {
		#say 'call returned: ', Dumper(\@_);
		my ($d, $e, $r) = @_;
		if ($e) {
			$self->log->error("announce got error: $e->{message}");
			$err = $e->{message};
			return;
		}
		my ($res, $msg) = @$r;
		$self->log->debug("announce got res: $res msg: $msg");
		$self->actions->{$actionname} = {
			cb => $cb,
			mode => $mode,
			undocb => $undocb,
			addenv => $args{addenv} // 0,
		} if $res;
		$err = $msg unless $res;
	})->catch(sub {
		($err) = @_;
		$self->log->error("something went wrong with announce: $err");
	})->wait();

	return $err;
}

sub rpc_ping {
	my ($self, $c, $i, $rpccb) = @_;
	$self->lastping(time());
	return 'pong!';
}

sub rpc_task_ready {
	#say 'got task_ready: ', Dumper(\@_);
	my ($self, $c, $i) = @_;
	my $actionname = $i->{actionname};
	my $job_id = $i->{job_id};
	my $action = $self->actions->{$actionname};
	unless ($action) {
		$self->log->info("got task_ready for unknown action $actionname");
		return;
	}

	$self->log->debug("got task_ready for $actionname job_id $job_id calling get_task");
	$self->ioloop->delay(sub {
		my $d = shift;
		$c->call('get_task', {actionname => $actionname, job_id => $job_id}, $d->begin(0));
	},
	sub {
		my ($d, $e, $r) = @_;
		#say 'get_task returned: ', Dumper(\@_);
		if ($e) {
			$$self->log->debug("got $e->{message} ($e->{code}) calling get_task");
		}
		unless ($r) {
			$self->log->debug('no task for get_task');
			return;
		}
		my ($cookie, @args);
		($job_id, $cookie, @args) = @$r;
		unless ($cookie) {
			$self->log->debug('aaah? no cookie? (get_task)');
			return;
		}
		pop @args unless $action->{addenv}; # remove env
		local $@;
		if ($action->{mode} eq 'subproc') {
			eval {
				$self->_subproc($c, $action, $job_id, $cookie, @args);
			};
			$c->notify('task_done', { cookie => $cookie, outargs => { error => $@ } }) if $@;
		} elsif ($action->{mode} eq 'async') {
			eval {
				$action->{cb}->($job_id, @args, sub {
					$c->notify('task_done', { cookie => $cookie, outargs => $_[0] });
				});
			};
			$c->notify('task_done', { cookie => $cookie, outargs => { error => $@ } }) if $@;
		} elsif ($action->{mode} eq 'sync') {
			my $outargs = eval { $action->{cb}->($job_id, @args) };
			$outargs = { error => $@ } if $@;
			$c->notify('task_done', { cookie => $cookie, outargs => $outargs });
		} else {
			die "unkown mode $action->{mode}";
		}
	})->catch(sub {
		my ($err) = @_;
		$self->log->error("something went wrong with rpc_task_ready: $err");
	});
}

sub _subproc {
	my ($self, $c, $action, $job_id, $cookie, @args) = @_;

	# based on Mojo::IOLoop::Subprocess
	my $ioloop = $self->ioloop;

	# Pipe for subprocess communication
	pipe(my $reader, my $writer) or die "Can't create pipe: $!";

	die "Can't fork: $!" unless defined(my $pid = fork);
	unless ($pid) {# Child
		$self->log->debug("in child $$");;
		$ioloop->reset;
		CORE::close $reader; # or we won't get a sigpipe when daddy dies..
		my $undo = 0;
		my $outargs = eval { $action->{cb}->($job_id, @args) };
		if ($@) {
			$outargs = {'error' => $@};
			$undo++;
		} elsif (ref $outargs eq 'HASH' and $outargs->{'error'}) {
			$undo++;
		}
		if ($undo and $action->{undocb}) {
			$self->log->info("undoing for $job_id");;
			my $res = eval { $action->{undocb}->($job_id, @args); };
			$res = $@ if $@;
			# how should this look?
			$outargs = {'error' => {
				'msg' => 'undo failure',
				'undo' => $res,
				'olderr' => $outargs->{error},
			}};
			$undo = 0;
		}
		# stop ignoring sigpipe
		$SIG{PIPE} = sub { $undo++ };
		# if the parent is gone we get a sigpipe here:
		print $writer Storable::freeze($outargs);
		$writer->flush or $undo++;
		CORE::close $writer or $undo++;
		if ($undo and $action->{undocb}) {
			$self->log->info("undoing for $job_id");;
			eval { $action->{undocb}->($job_id, @args); };
			# ignore errors because we can't report them back..
		}
		# FIXME: normal exit?
		POSIX::_exit(0);
	}

	# Parent
	my $me = $$;
	CORE::close $writer;
	my $stream = Mojo::IOLoop::Stream->new($reader)->timeout(0);
	$ioloop->stream($stream);
	my $buffer = '';
	$stream->on(read => sub { $buffer .= pop });
	$stream->on(
		close => sub {
			#say "close handler!";
			return unless $$ == $me;
			waitpid $pid, 0;
			my $outargs = eval { Storable::thaw($buffer) };
			$outargs = { error => $@ } if $@;
			if ($outargs and ref $outargs eq 'HASH') {
				$self->log->debug('subprocess results: ' . Dumper($outargs));
				eval { $c->notify(
						'task_done',
						{ cookie => $cookie, outargs => $outargs }
				); }; # the connection might be gone?
			} # else?
		}
	);
}

# tick while Mojo::Reactor is still running and condition callback is true
sub _loop {
	warn __PACKAGE__." recursing into IO loop" if state $looping++;

	my $reactor = $_[0]->ioloop->singleton->reactor;
	my $err;

	if (ref $reactor eq 'Mojo::Reactor::EV') {

		my $active = 1;

		$active = $reactor->one_tick while $_[1]->() && $active;

	} elsif (ref $reactor eq 'Mojo::Reactor::Poll') {

		$reactor->{running}++;

		$reactor->one_tick while $_[1]->() && $reactor->is_running;

		$reactor->{running} &&= $reactor->{running} - 1;

	} else {

		$err = "unknown reactor: ".ref $reactor;
	}

	$looping--;
	die $err if $err;
}

#sub DESTROY {
#	my $self = shift;
#	say 'destroying ', $self;
#}

1;

=encoding utf8

=head1 NAME

JobCenter::Client::Mojo - JobCenter JSON-RPC 2.0 Api client using Mojo.

=head1 SYNOPSIS

  use JobCenter::Client::Mojo;

   my $client = JobCenter::Client::Mojo->new(
     address => ...
     port => ...
     who => ...
     token => ...
   );

   my ($job_id, $outargs) = $client->call(
     wfname => 'test',
     inargs => { test => 'test' },
   );

=head1 DESCRIPTION

L<JobCenter::Client::Mojo> is a class to build a client to connect to the
JSON-RPC 2.0 Api of the L<JobCenter> workflow engine.  The client can be
used to create and inspect jobs as well as for providing 'worker' services
to the JobCenter.

=head1 METHODS

=head2 new

$client = JobCenter::Client::Mojo->new(%arguments);

Class method that returns a new JobCenter::Client::Mojo object.

Valid arguments are:

=over 4

=item - address: address of the Api.

(default: 127.0.0.1)

=item - port: port of the Api

(default 6522)

=item - tls: connect using tls

(default false)

=item - tls_ca: verify server using ca

(default undef)

=item - tls_key: private client key

(default undef)

=item - tls_ca: public client certificate

(default undef)

=item - who: who to authenticate as.

(required)

=item - method: how to authenticate.

(default: password)

=item - token: token to authenticate with.

(required)

=item - debug: when true prints debugging using L<Mojo::Log>

(default: false)

=item - ioloop: L<Mojo::IOLoop> object to use

(per default the L<Mojo::IOLoop>->singleton object is used)

=item - json: flag wether input is json or perl.

when true expects the inargs to be valid json, when false a perl hashref is
expected and json encoded.  (default true)

=item - log: L<Mojo::Log> object to use

(per default a new L<Mojo::Log> object is created)

=item - timeout: how long to wait for Api calls to complete

(default 60 seconds)

=item - ping_timeout: after this long without a ping from the Api the
connection will be closed and the work() method will return

(default 5 minutes)

=back

=head2 call

($job_id, $result) = $client->call(%args);

Creates a new L<JobCenter> job and waits for the results.  Throws an error
if somethings goes wrong immediately.  Errors encountered during later
processing are returned as a L<JobCenter> error object.

Valid arguments are:

=over 4

=item - wfname: name of the workflow to call (required)

=item - inargs: input arguments for the workflow (if any)

=item - vtag: version tag of the workflow to use (optional)

=item - timeout: wait this many seconds for the job to finish
(optional, defaults to 5 times the Api-call timeout, so default 5 minutes)

=item - reqauth: authentication token to be passed on to the authentication
module of the API for per job/request authentication.

=item - clenv: client environment, made available as part of the job
environment and inherited to child jobs.

=back

=head2 call_nb

$job_id = $client->call_nb(%args);

Creates a new L<JobCenter> job and call the provided callback on completion
of the job.  Throws an error if somethings goes wrong immediately.  Errors
encountered during later processing are returned as a L<JobCenter> error
object to the callback.

Valid arguments are those for L<call> and:

=over 4

=item - cb1: coderef to the callback to call on job creation (requird)

( cb1 => sub { ($job_id, $err) = @_; ... } )

If job_id is undefined the job was not created, the error is then returned
as the second return value.

=item - cb2: coderef to the callback to call on job completion (requird)

( cb2 => sub { ($job_id, $outargs) = @_; ... } )

=back

=head2 get_job_status

($job_id, $result) = $client->get_job_status($job_id);

Retrieves the status for the given $job_id.  If the job_id does not exist
then the returned $job_id will be undefined and $result will be an error
message.  If the job has not finished executing then both $job_id and
$result will be undefined.  Otherwise the $result will contain the result of
the job.  (Which may be a JobCenter error object)

=head2 get_job_status_nb

$client->get_job_status_nb(%args);

Retrieves the status for the given $job_id.

Valid arguments are:

=over 4

=item - job_id

=item - statuscb: coderef to the callback for the current status

( statuscb => sub { ($job_id, $result) = @_; ... } )

If the job_id does not exist then the returned $job_id will be undefined
and $result will be an error message.  If the job has not finished executing
then both $job_id and $result will be undefined.  Otherwise the $result will
contain the result of the job.  (Which may be a JobCenter error object)

=item - notifycb: coderef to the callback for job completion

( statuscb => sub { ($job_id, $result) = @_; ... } )

If the job was still running when the get_job_status_nb call was made then
this callback will be called on completion of the job.

=back

=head2 find_jobs

($err, @jobs) = $client->find_jobs({'foo'=>'bar'});

Finds all currently running jobs with arguments matching the filter
expression.  The expression is evaluated in PostgreSQL using the @> for
jsonb objects, basically this means that you can only do equality tests for
one or more top-level keys.  If @jobs is empty $err might contain an error
message.

=head2 ping

$status = $client->ping($timeout);

Tries to ping the JobCenter API. On success return true. On failure returns
the undefined value, after that the client object should be undefined.

=head2 close

$client->close()

Closes the connection to the JobCenter API and tries to de-allocate
everything.  Trying to use the client afterwards will produce errors.

=head2 create_slotgroup

$client->create_slotgroup($name, $slots)

A 'slotgroup' is a way of telling the JobCenter API how many taskss the
worker can do at once.  The number of slots should be a positive integer.

=head2 announce

Announces the capability to do an action to the Api.  The provided callback
will be called when there is a task to be performed.  Returns an error when
there was a problem announcing the action.

  my $err = $client->announce(
    workername => 'me',
    actionname => 'do',
    slots => 1
    cb => sub { ... },
  );
  die "could not announce $actionname?: $err" if $err;

See L<jcworker> for an example.

Valid arguments are:

=over 4

=item - workername: name of the worker

(optional, defaults to client->who, processname and processid)

=item - actionname: name of the action

(required)

=item - cb: callback to be called for the action

(required)

=item - mode: callback mode

(optional, default 'sync')

Possible values:

=over 8

=item - 'sync': simple blocking mode, just return the results from the
callback.  Use only for callbacks taking less than (about) a second.

=item - 'subproc': the simple blocking callback is started in a seperate
process.  Useful for callbacks that take a long time.

=item - 'async': the callback gets passed another callback as the last
argument that is to be called on completion of the task.  For advanced use
cases where the worker is actually more like a proxy.  The (initial)
callback is expected to return soonish to the event loop, after setting up
some Mojo-callbacks.

=back

=item - async: backwards compatible way for specifying mode 'async'

(optional, default false)

=item - slotgroup: the slotgroup to use for accounting of parrallel tasks

(optional, conflicts with 'slots')

=item - slots: the amount of tasks the worker is able to process in parallel
for this action.

(optional, default 1, conflicts with 'slotgroup')

=item - undocb: a callback that gets called when the original callback
returns an error object or throws an error.

Called with the same arguments as the original callback.

(optional, only valid for mode 'subproc')

=item - filter: only process a subset of the action

The filter expression allows a worker to specify that it can only do the
actionname for a certain subset of arguments.  For example, for a "mkdir"
action the filter expression {'host' => 'example.com'} would mean that this
worker can only do mkdir on host example.com. Filter expressions are limited
to simple equality tests on one or more keys, and only those keys that are
allowed in the action definition. Filtering can be allowed, be mandatory or
be forbidden per action.

=item - addenv: pass on action enviroment to the callback

If the addenv flag is true the action callback will be given one extra
argument containing the action environment as a hashref.  In the async
callback mode the environment will be inserted before the result callback.

=back

=head2 work

Starts the L<Mojo::IOLoop>.  Returns a non-zero value when the IOLoop was
stopped due to some error condition (like a lost connection or a ping
timeout).

=head3 Possible work() exit codes

The JobCenter::Client::Mojo library currently defines the following exit codes:

	WORK_OK
	WORK_PING_TIMEOUT
	WORK_CONNECTION_CLOSED

=head2 stop

  $client->stop($exit);

Makes the work() function exit with the provided exit code.

=head1 SEE ALSO

=over 4

=item *

L<Mojo::IOLoop>, L<Mojo::IOLoop::Stream>, L<http://mojolicious.org>: the L<Mojolicious> Web framework

=item *

L<jcclient|https://github.com/a6502/JobCenter-Client-Mojo/blob/master/examples/jcclient>, L<jcworker|https://github.com/a6502/JobCenter-Client-Mojo/blob/master/examples/jcworker>

=back

L<https://github.com/a6502/JobCenter>: JobCenter Orchestration Engine

=head1 ACKNOWLEDGEMENT

This software has been developed with support from L<STRATO|https://www.strato.com/>.
In German: Diese Software wurde mit Unterstützung von L<STRATO|https://www.strato.de/> entwickelt.

=head1 THANKS

Thanks to Eitan Schuler for reporting a bug and providing a pull request.

=head1 AUTHORS

=over 4

=item *

Wieger Opmeer <wiegerop@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Wieger Opmeer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
