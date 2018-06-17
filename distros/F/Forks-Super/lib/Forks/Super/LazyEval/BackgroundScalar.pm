#
# Forks::Super::LazyEval::BackgroundScalar - lazy evaluation of a perl
#    expression in scalar context or external command
#
# formerly Forks::Super::Tie::BackgroundScalar, but this has not been
# used with 'tie' since v0.43

package Forks::Super::LazyEval::BackgroundScalar;
use Forks::Super;
use Forks::Super::Debug qw(:all);
use Forks::Super::Wait 'WREAP_BG_OK';
use Scalar::Util 'reftype';
use Carp;
use strict;
use warnings;
use overload
    '""' => sub { "" . $_[0]->_fetch },
    '+' => sub { $_[0]->_fetch + $_[1] },
    '*' => sub { $_[0]->_fetch * $_[1] },
    '&' => sub { $_[0]->_fetch & $_[1] },
    '|' => sub { $_[0]->_fetch | $_[1] },
    '^' => sub { $_[0]->_fetch ^ $_[1] },
    '~' => sub { ~$_[0]->_fetch },
    '<=>' => sub { $_[2] ? $_[1]||0 <=> $_[0]->_fetch 
		       : $_[0]->_fetch <=> $_[1]||0 },
    'cmp' => sub {
	$_[2] ? $_[1] cmp $_[0]->_fetch : $_[0]->_fetch cmp $_[1]
    },
    '-' => sub { $_[2] ? $_[1] - $_[0]->_fetch : $_[0]->_fetch - $_[1] },
    '/' => sub { $_[2] ? $_[1] / $_[0]->_fetch : $_[0]->_fetch / $_[1] },
    '%' => sub { $_[2] ? $_[1] % $_[0]->_fetch : $_[0]->_fetch % $_[1] },
    '**' => sub { $_[2] ? $_[1] ** $_[0]->_fetch : $_[0]->_fetch ** $_[1] },
    '<<' => sub { $_[2] ? $_[1] << $_[0]->_fetch : $_[0]->_fetch << $_[1] },
    '>>' => sub { $_[2] ? $_[1] >> $_[0]->_fetch : $_[0]->_fetch >> $_[1] },
    'x' => sub { $_[2] ? $_[1] x $_[0]->_fetch : $_[0]->_fetch x $_[1] },

# derefencing operators: should return a reference of the correct type.

    '${}' => sub { $_[0]->_fetch },
    '@{}' => sub { $_[0]->_fetch },
    '&{}' => sub { $_[0]->_fetch },
    '*{}' => sub { $_[0]->_fetch },

# A BackgroundScalar object is a HASH-type reference. Inside
# _fetch we must disable overloading of '%{}'
    '%{}' => sub { $_[0]->_fetch },

    'cos' => sub { cos $_[0]->_fetch },
    'sin' => sub { sin $_[0]->_fetch },
    'exp' => sub { exp $_[0]->_fetch },
    'log' => sub { log $_[0]->_fetch },
    'sqrt' => sub { sqrt $_[0]->_fetch },
    'int' => sub { int $_[0]->_fetch },
    'abs' => sub { abs $_[0]->_fetch },
    'atan2' => sub { $_[2] ? atan2($_[1], $_[0]->_fetch) 
		         : atan2($_[0]->_fetch, $_[1]) }
;

our $VERSION = '0.94';

# "protocols" for serializing data and the methods used
# to carry out the serialization

my %serialization_dispatch = (

    YAML => {
	require => sub { require YAML },
	encode => sub { return YAML::Dump($_[0]) },
	decode => sub { return YAML::Load($_[0]) }
    },

    'Data::Dumper' => {
	require => sub { require Data::Dumper },
	encode => sub { return Data::Dumper::Dumper($_[0]) },
	decode => sub {
	    my ($data,$job,$VAR1) = @_;
            if ($job->{untaint}) {
                ($data) = $data =~ /(.*)/s;
            } elsif (${^TAINT}) {
                carp 'Forks::Super::bg_eval/bg_qx(): ',
                        'Using Data::Dumper for serialization, which cannot ',
                        "operate on 'tainted' data. Use bg_eval {...} ",
                        '{untaint => 1} or bg_qx COMMAND, ',
                        "{untaint => 1} to retrieve the result.\n";
                return;
            }
	    my $decoded = eval "$data";    ## no critic (StringyEval)
	    return $decoded;
	}
    },

    );

# a scalar reference that is evaluated in a child process.
# when the value is dereferenced, retrieve the output from
# the child, waiting for the child to finish if necessary

sub new {
    my ($class, $style, $command_or_code, %other_options) = @_;
    my $self = { value_set => 0, style => $style };
    if ($style eq 'eval') {
	my $protocol = $other_options{'protocol'};
	$self->{code} = $command_or_code;
	$self->{job_id} = Forks::Super::fork { 
	    (%other_options,
	     child_fh => 'out',
	     sub => sub {
		 my $Result = $command_or_code->();
		 print STDOUT _encode($protocol, $Result);
	     }, 
	     _is_bg => 1,
	     _lazy_proto => $protocol )
	};

    } elsif ($style eq 'qx') {
	$self->{command} = $command_or_code;
	$self->{stdout} = '';
	$self->{job_id} = Forks::Super::fork { 
	    (%other_options, 
	     child_fh => 'out',
	     cmd => $command_or_code,
	     stdout => \$self->{stdout},
	     _is_bg => 1)
	};
        
    }
    $self->{job} = Forks::Super::Job::get($self->{job_id});
    ($Forks::Super::LAST_JOB, $Forks::Super::LAST_JOB_ID)
	= ($self->{job}, $self->{job_id});
    $self->{value} = undef;
    return bless $self, $class;
}

sub _encode {
    my ($protocol, $data) = @_;
    if (defined $serialization_dispatch{$protocol}) {
	$serialization_dispatch{$protocol}{'require'}->();
	return $serialization_dispatch{$protocol}{encode}->($data);
    } else {
	croak 'Forks::Super::LazyEval::BackgroundScalar: ',
	    'YAML or Data::Dumper required to use bg_eval';
    }
}

sub _decode {
    my ($protocol, $data, $job) = @_;
    if (defined $serialization_dispatch{$protocol}) {
	$serialization_dispatch{$protocol}{require}->();
	return $serialization_dispatch{$protocol}{decode}->($data,$job);
    } else {
	croak 'Forks::Super::LazyEval::BackgroundScalar: ',
	    'YAML or Data::Dumper required to use bg_eval';
    }
}


# retrieves the result of the background task. If necessary, wait for the
# background task to finish.
sub _fetch {
    my $self = shift;

    # temporarily turn off overloaded hash dereferencing.
    # it will be turned back on later
    #
    # I would love to just say 'no overloading %{}' here, but that
    # is not supported for perl <5.10.1
    my $class = ref $self;
    bless $self, '!@#$%';
    
    if (!$self->{value_set}) {
	if (!$self->{job}->is_complete) {
            return if &Forks::Super::Job::_INSIDE_END_QUEUE;
	    my $pid = Forks::Super::waitpid $self->{job_id}, WREAP_BG_OK;
            no warnings 'numeric';
	    if ($pid != $self->{job}{real_pid} && $pid != $self->{job}{pid}) {
		carp 'Forks::Super::bg_eval: ',
			"failed to retrieve result from process!\n";
		$self->{value_set} = 1;
		$self->{error} =
		    'waitpid failed, result not retrieved from process';
		bless $self, $class;
		return '';  # v0.53 on failure return empty string
	    }
	    if ($self->{job}{status} != 0) {
		$self->{error} = 'job status: ' . $self->{job}{status};
	    }
	    # XXX - what other error conditions are there to set ?
        }

	if ($self->{style} eq 'eval') {
	    my $stdout = join'', Forks::Super::read_stdout($self->{job_id});
	    if (!eval {
		$self->{value} = _decode($self->{job}{_lazy_proto}, 
					 $stdout, $self->{job});
		1
		}) {
		$self->{error} ||= $@;
		$self->{value} = undef;
	    }
	    $self->{value_set} = 1;
	} elsif ($self->{style} eq 'qx') {
	    $self->{value_set} = 1;
	    if (defined $self->{stdout}) {
		$self->{value} = $self->{stdout};
	    } else {
		$self->{value} = '';
	    }
	}
    }
    my $value = $self->{value};
    bless $self, $class;
    return $value;
}

sub _job {
    my $self = shift;
    my $class = ref $self;
    bless $self, '!@#$%';
    my $job = $self->{job};
    bless $self, $class;
    return $job;
}

sub Forks::Super::LazyEval::BackgroundScalar::AUTOLOAD {
    my $obj = shift->_fetch;
    my $ref = ref($obj);
    my $method = $Forks::Super::LazyEval::BackgroundScalar::AUTOLOAD;
    return if $method =~ /::DESTROY$/;
    if (!$ref || $ref eq 'ARRAY' || $ref eq 'SCALAR' || $ref eq 'HASH') {
        die "bg_eval: Can't call method '$method' on unblessed reference";
    }
    $method =~ s/.*:://;
    no strict 'refs';
    return $obj->$method(@_);
}

1;

=head1 NAME

Forks::Super::LazyEval::BackgroundScalar

=head1 VERSION

0.94

=head1 DESCRIPTION

An object type used to implement the L<Forks::Super::bg_qx|Forks::Super/bg_qx>
and L<Forks::Super::bg_eval|Forks::Super/bg_eval> lazy asynchronous
evaluation functions for scalar context.
See L<Forks::Super|Forks::Super> and
L<Forks::Super::LazyEval|Forks::Super::LazyEval> for details.

=head1 AUTHOR

Marty O'Brien, E<lt>mob@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010-2018, Marty O'Brien.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See http://dev.perl.org/licenses/ for more information.

=cut
