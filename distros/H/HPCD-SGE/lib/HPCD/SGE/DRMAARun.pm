package HPCD::SGE::DRMAARun;

### INCLUDES ##################################################################

# safe Perl
use warnings;
use strict;
use Carp;
use Data::Dumper;
use DateTime;
use Schedule::DRMAAc qw( :all );

use Moose::Role;

with 'HPCD::SGE::DRMAAWrapper';

has '_drmaa_jobid' => (
	is       => 'rw',
	init_arg => undef
);

has '_drmaa_stat' => (
	is       => 'rw',
	init_arg => undef
);

has '_drmaa_rusage' => (
	is       => 'rw',
	init_arg => undef
);

has '_qalter_command' => (
	is        => 'rw',
	init_arg  => undef,
	predicate => '_has_qalter_command',
	lazy      => 1,
	default   => ""
);

my @_qa = (
	# [ key       arg-parser    arg-setter drmaa-attr              arg-displayer stage-attr ]
	[ '-N',      'str1_parse', 'set_attr', $DRMAA_JOB_NAME,       'str_disp',   'name' ],               # Name
	[ '-l',      'str1_parse', 'set_qalt', undef,                 'res_disp',   'resources_required' ], # resources
	[ '-o',      'str1_parse', 'set_netp', $DRMAA_OUTPUT_PATH,    'str_disp',   ' ' ],                  # stdout
	[ '-e',      'str1_parse', 'set_netp', $DRMAA_ERROR_PATH,     'str_disp',   ' ' ],                  # stderr
	[ '-cwd',    'no_parse',   'set_attr', $DRMAA_WD,             'str_disp',   ' ' ],                  # cwd
	[ 'SCRIPT',  'str1_parse', 'set_attr', $DRMAA_REMOTE_COMMAND, 'str_disp',   ' ' ],                  # script
	[ '-@',      'str1_parse', 'set_qalt', undef,                 'str_disp',   undef ],                # optionfile
	[ '-a',      'str1_parse', 'set_qalt', undef,                 'str_disp',   undef ],                # datetime
	[ '-ac',     'str1_parse', 'set_qalt', undef,                 'str_disp',   undef ],                # add context
	[ '-ar',     'str1_parse', 'set_qalt', undef,                 'str_disp',   undef ],                # advance reservation
	[ '-A',      'str1_parse', 'set_qalt', undef,                 'str_disp',   undef ],                # account
	[ '-binding','bind_parse', 'set_qalt', undef,                 'str_disp',   undef ],                # binding
	[ '-c',      'str1_parse', 'set_qalt', undef,                 'str_disp',   undef ],                # checkpoint freq
	[ '-ckpt',   'str1_parse', 'set_qalt', undef,                 'str_disp',   undef ],                # checkpoint name
	[ '-dc',     'str1_parse', 'set_qalt', undef,                 'str_disp',   undef ],                # delete context
	[ '-display','str1_parse', 'set_qalt', undef,                 'str_disp',   undef ],                # host:disp xterm
	[ '-dl',     'str1_parse', 'set_qalt', undef,                 'str_disp',   undef ],                # deadline time
	[ '-h',      'no_parse',   'set_qalt', undef,                 'str_disp',   undef ],                # hold
	[ '-hold_jid','str1_parse','set_qalt', undef,                 'str_disp',   undef ],                # hold jobid[s]
	[ '-hold_jid_ad','str1_parse','set_qalt',undef,               'str_disp',   undef ],                # hold array dependency jobid[s]
	[ '-j',      'str1_parse', 'set_qalt', undef,                 'str_disp',   undef ],                # join stdout/stderr
	[ '-js',     'str1_parse', 'set_qalt', undef,                 'str_disp',   undef ],                # job share integer
	[ '-M',      'str1_parse', 'set_qalt', undef,                 'str_disp',   undef ],                # maildest
	[ '-m',      'str1_parse', 'set_qalt', undef,                 'str_disp',   undef ],                # mail
	[ '-masterq','str1_parse', 'set_qalt', undef,                 'str_disp',   undef ],                # master queue
	[ '-notify', 'no_parse',   'set_qalt', undef,                 'str_disp',   undef ],                # sig usr1/usr2 before stop/kill
	[ '-now',    'str1_parse', 'set_qalt', undef,                 'str_disp',   undef ],                # no wait, now or never
	[ '-ot',     'str1_parse', 'set_qalt', undef,                 'str_disp',   undef ],                # override tickets
	[ '-P',      'str1_parse', 'set_qalt', undef,                 'str_disp',   undef ],                # project name
	[ '-p',      'str1_parse', 'set_qalt', undef,                 'str_disp',   undef ],                # priority
	[ '-pe',     'pe_parse',   'set_qalt', undef,                 'str_disp',   undef ],                # parallel environment
	[ '-pty',    'str1_parse', 'set_qalt', undef,                 'str_disp',   undef ],                # pseudo tty
	[ '-q',      'str1_parse', 'set_queue',undef,                 'str_disp',   undef ],                # queue
	[ '-R',      'str1_parse', 'set_qalt', undef,                 'str_disp',   undef ],                # reservation used
	[ '-r',      'str1_parse', 'set_qalt', undef,                 'str_disp',   undef ],                # rerun possible
	[ '-sc',     'str1_parse', 'set_qalt', undef,                 'str_disp',   undef ],                # set context
	[ '-v',      'str1_parse', 'set_qalt', undef,                 'str_disp',   undef ],                # env variables
);

my %_qaparse;      # method to parse this arg
my %_qaset;        # method to set this arg in the job template
my %_qasetattr;    # method to set this arg in the job template
my %_qadisp;       # method to display this arg for info
my %_qaattr;       # if provided, attr of stage that internally provides this args value

# my $extra_queue_arg = undef;

has '_extra_queue_arg' => (
	is       => 'rw',
	default  => undef,
	init_arg => undef
);

has '_cpu_multiplier' => (
	is       => 'rw',
	default  => 1,
	init_arg => undef
);

for my $l (@_qa) {
	my ( $k, $p, $s, $sa, $d, $a ) = @$l;
	$_qaparse{$k}   = $p;
	$_qaset{$k}     = $s;
	$_qasetattr{$k} = $sa;
	$_qadisp{$k}    = $d;
	$_qaattr{$k}    = $a if $a;
}

has '_drmaa_job_template' => (
	is       => 'ro',
	lazy     => 1,
	init_arg => undef,
	builder  => '_init_drmaa_job_template',
);

sub _init_drmaa_job_template {
	my $self    = shift;
	my $jt      = $self->Odrmaa_allocate_job_template;
	my $args    = $self->_qsub_args;
	my $skipped = $self->_qsub_args_skipped;
	my $stage   = $self->stage;
	my $extra   = $stage->extra_sge_args_string;
	$extra =~ s/^\s*//;
	while ($extra) {
		$extra =~ s/^(-\w+)\s*\b//
			or croak "No known qsub option ($extra)";
		my $key = $1;
		my $p = $_qaparse{$key}
			or croak "No known qsub option ($key $extra)";
		my $val  = $self->$p( $key, \$extra );
		if (exists $_qaattr{$key}) {
			my $attr = $_qaattr{$key};
			if ($attr =~ /^\s*$/) {
				$attr = '';
			}
			else {
				$attr = " from stage attr ($attr)";
			}
			$stage->warn( "ignoring ($key $val) from extra_sge_args_string, it is determined internally$attr" );
			push @$skipped, $key;
			push @$skipped, $val if defined $val;
		}
		else {
			$self->set( $jt, $key, $val );
			my $disp = $_qadisp{$key};
			$disp = $self->$disp($val);
			push @$args, $key;
			push @$args, $disp if defined $disp;
		}
	}
	for my $pair (
		(   [ '-N', $self->unique_id ],
			[ '-l', $stage->_use_resources_required ],
			[ '-o', $self->_stdout ],
			[ '-e', $self->_stderr ],
			[ '-cwd', get_cwd() ],
			[ 'SCRIPT', $stage->script_file ]
		) ) {
		my ($key, $val) = @$pair;
		$self->set( $jt, $key, $val );
		push @$args, $key unless $key eq 'SCRIPT';
		if (defined $val) {
			my $disp = $_qadisp{$key};
			$disp = $self->$disp($val);
			push @$args, $disp;
		}
	}
	return $jt;
}

sub str1_parse {
	my $self      = shift;
	my $key       = shift;
	my $ref_extra = shift;
	$$ref_extra =~ s/^\s*(\S+)\b\s*//
		or croak "no string arg found for extra qsub option ($key)";
	return $1;
}

sub no_parse {
	my $self      = shift;
	my $key       = shift;
	my $ref_extra = shift;
	return undef;
}

sub yn_parse {
	my $self      = shift;
	my $key       = shift;
	my $ref_extra = shift;
	$$ref_extra =~ s/^\s*(y)(es)?\b\s*// or $$ref_extra =~ s/\s*(n)(o)?\b\s*//
		or croak "no yes/no arg found for extra qsub option ($key) in: $$ref_extra";
	return $1;
}

my %bind_prefix = map { ($_ => 1) } qw(env pe set);

sub bind_parse {
	my $self      = shift;
	my $key       = shift;
	my $ref_extra = shift;
	my $res       = $self->str1_parse( $key, $ref_extra );
	return $bind_prefix{$res}
		? "$res " . $self->str1_parse( "$key $res", $ref_extra )
		: $res;
}

sub pe_parse {
	my $self      = shift;
	my $key       = shift;
	my $ref_extra = shift;
	my $pe = $self->str1_parse( $key, $ref_extra );
	my $range = $self->str1_parse( "$key $pe", $ref_extra );
	$range =~ /(^(\d+)-?\d*$)|(^-\d*$)/
		or croak "invalid range arg ($range) found for extra qsub option ($key name($pe))";
	$self->_cpu_multiplier( $2 ) if defined $2;
	return "$pe $range";
}

sub str_disp {
	my ($self, $val) = @_;
	return $val;
}

sub ml_disp {
	my ($self, $val) = @_;
	return $val ? 'n' : 'e';
}

sub res_disp {
	my $self = shift;
	my $val = $self->_get_mapped_resource_string( @_ );
	my $extra_queue_arg = $self->_extra_queue_arg;
	return ($val && $extra_queue_arg)
		? "$val,$extra_queue_arg"
		: ($extra_queue_arg || $val);
}

sub vec_disp {
	my ($self, $val) = @_;
	return join ',', @$val;
}

sub set {
	my ($self, $jt, $key, $val) = @_;
	my $s = $_qaset{$key};
	$self->$s( $jt, $key, $val );
}

sub set_attr {
	my ($self, $jt, $key, $val) = @_;
	$self->Odrmaa_set_attribute( $jt, $_qasetattr{$key}, $val );
}

sub set_netp {
	my ($self, $jt, $key, $val) = @_;
	$self->Odrmaa_set_attribute( $jt, $_qasetattr{$key}, ":$val" );
}

sub set_vec {
	my ($self, $jt, $key, $val) = @_;
	$self->Odrmaa_set_vector_attribute( $jt, $_qasetattr{$key}, $val );
}

sub set_queue {
	my ($self, $jt, $key, $val) = @_;
	$self->_extra_queue_arg( "qname=$val" );
	set_qalt( @_ );
}

sub set_qalt {
	my ($self, $jt, $key, $val) = @_;
	$self->append_qalter($key);
	if (defined $val) {
		my $disp = $_qadisp{$key};
		$self->append_qalter( $self->$disp($val) );
	}
}

sub append_qalter {
	my ($self, $val) = @_;
	my $qa = $self->_qalter_command;
	my $newval = join( ' ',
		($qa ? ($qa) : ()),
		$val );
	$self->_qalter_command( $newval );
}

sub get_cwd {
	my $cwd = `/bin/pwd`;
	chomp $cwd;
	return $cwd;
}

has '_qsub_args' => (
	is       => 'rw',
	lazy     => 1,
	init_arg => undef,
	default  => sub { [ ] }
);

has '_qsub_args_skipped' => (
	is       => 'rw',
	lazy     => 1,
	init_arg => undef,
	default  => sub { [ ] }
);

my $unchanged = sub { return $_[0] };

my $to_localtime = sub { return DateTime->from_epoch( epoch => $_[0] )->datetime };

my $to_int = sub { my $v = shift; $v =~ s/\.0+$//; return $v };

my $to_KMGT = sub {
	my $v     = $to_int->( shift );
	my $units = '';
	my @conv  = ( [ 1024**4, 'T' ], [ 1024**3, 'G' ], [ 1024**2, 'M' ], [ 1024**1, 'K' ] );

	for my $pair (@conv) {
		my ( $div, $name ) = @$pair;
		if ($v >= $div) {
			$v = sprintf "%7.3f", $v/$div;
			$v =~ s/ //g;
			$units = $name;
			last;
		}
	}
	return "$v$units";
};

my %fixer = (
	maxvmem         => $to_KMGT,
	acct_maxvmem    => $to_KMGT,
	submission_time => $to_localtime,
	start_time      => $to_localtime,
	end_time        => $to_localtime
);

around '_register_status' => sub {
	my $orig   = shift;
	my $self   = shift;
	my $status = shift;
	my $stage  = $self->stage;

	if (my $abort = $self->Odrmaa_wifaborted( $status )) {
		$stage->info( "Abort code ($abort) returned for drmaa status ($status)" );
		$self->abort( $status );
	}
	elsif (my $signal = $self->Odrmaa_wifsignaled( $status )) {
		$self->kill( $signal );
		$self->killsignal( $self->Odrmaa_wtermsig( $status ) || 'not provided by drmaa');
	}
	else {
		my $estat = $self->Odrmaa_wexitstatus( $status );
		$stage->info("Exit status ($estat) returned for drmaa status ($status)");
		$self->status( $self->Odrmaa_wexitstatus( $status ) );
	}
};

around '_collect_qacct_info' => sub {
	my $orig  = shift;          # we ignore this: totally replace the parent (qacct) version
								# unless drmaa failed to get any status attributes
	my $self  = shift;
	my $stage = $self->stage;

	my %info;
	my $exit_status;

	while (my ( $continue, $value ) = $self->Odrmaa_get_next_attr_value($self->_drmaa_rusage)) {
		last unless $continue;
		if (my ( $k, $v ) = $value =~ /(\w+)=(.*)/) {
			$info{$k} = ($fixer{ $k } // $to_int )->($v);
			$exit_status = $info{$k} if $k eq 'exit_status';
		}
	}
	$orig->($self) unless defined $exit_status && $exit_status ne 'unknown'; 
	return \%info;
};

around '_delete_job' => sub {
	my $orig = shift;           # we ignore this: totally replace the parent (qdel) version
	my $self = shift;

	$self->Odrmaa_control($self->_drmaa_jobid, $DRMAA_CONTROL_TERMINATE);
};

around 'hard_timeout' => sub {
	my $orig = shift;           # we ignore this: totally replace the parent method,
								# there is no sub-process to kill
	my $self = shift;
	$self->_delete_job;
};

around '_get_submit_command' => sub {
	my $orig = shift;    # over-ride original method completely
	my $self = shift;

	my $stage        = $self->stage;
	my $shell_script = $stage->script_file;
	my $output_file  = $self->_stdout;
	my $error_file   = $self->_stderr;

	my $jt           = $self->_drmaa_job_template;       # ensure the template has been createwd
	my @skipped_args = @{ $self->_qsub_args_skipped };
	if (@skipped_args) {
		unshift @skipped_args, '(unsupported qsub args:';
		push @skipped_args, ')';
	}
	my $qsub_equivalent_command = join( ' ',
		'internal equivalent to:',
		'qsub', @{ $self->_qsub_args },
		@skipped_args
	);
	return $qsub_equivalent_command;
};

around '_submit_command' => sub {
	my $orig = shift;    # over-ride original method completely
	my $self = shift;
	my $jt   = $self->_drmaa_job_template;
	if ($self->_has_qalter_command) {
		my $qac = $self->_qalter_command;
		$self->Odrmaa_set_attribute( $jt, $DRMAA_NATIVE_SPECIFICATION, $qac );
	}
	my $jobid = $self->Odrmaa_run_job( $jt );
	$self->_drmaa_jobid( $jobid );
	$self->stage->info( "Job submitted with job id: $jobid" );
	return $jobid;
};

1;
