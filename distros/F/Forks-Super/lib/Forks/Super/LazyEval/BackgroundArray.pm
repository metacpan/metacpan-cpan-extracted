#
# Forks::Super::LazyEval::BackgroundArray - lazy evaluation of a perl
#    expression in list context
#

package Forks::Super::LazyEval::BackgroundArray;
use Forks::Super;
use Forks::Super::Wait 'WREAP_BG_OK';
use Carp;
use strict;
use warnings;

our $VERSION = '0.97';

# "protocols" for serializing data and the methods used
# to carry out the serialization

my %serialization_dispatch = (

    YAML => {
	require => sub { require YAML },
	encode => sub { return YAML::Dump( \@_ ) },
	decode => sub { return YAML::Load($_[0]) }
    },

    'Data::Dumper' => {
	require => sub { require Data::Dumper },
	encode => sub { return Data::Dumper::Dumper( \@_ ) },
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

# an array that is evaluated in a child process.
# the first time an element of the array is dereferenced,
# retrieve the output from the child,
# waiting for the child to finish if necessary

sub new {
    my ($class, $style, $command_or_code, %other_options) = @_;
    my $self = { value_set => 0, value => undef, style => $style };
    if ($style eq 'eval') {
	my $protocol = $other_options{'protocol'};
	$self->{code} = $command_or_code;
	$self->{job_id} = Forks::Super::fork {
	    (%other_options,
	     child_fh => 'out',
	     sub => sub {
		 my @result = $command_or_code->();
		 print STDOUT _encode($protocol, @result);
	     }, 
	     _is_bg => 2, 
	     _lazy_proto => $protocol )
	};

    } elsif ($style eq 'qx') {
	croak "Always use F::S::LazyEval::BackgroundScalar with bg_qx\n";
    }
    $self->{job} = Forks::Super::Job::get($self->{job_id});
    ($Forks::Super::LAST_JOB, $Forks::Super::LAST_JOB_ID)
	= ($self->{job}, $self->{job_id});
    $self->{value} = [];
    return bless $self, $class;
}

sub _encode {
    my ($protocol, @data) = @_;
    if (defined $serialization_dispatch{$protocol}) {
	$serialization_dispatch{$protocol}{'require'}->();
	return $serialization_dispatch{$protocol}{encode}->(@data);
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

sub _fetch {
    my $self = shift;

    if (!$self->{value_set}) {
	if (!$self->{job}->is_complete) {
	    my $pid = Forks::Super::waitpid $self->{job_id}, WREAP_BG_OK;
	    if ($pid != $self->{job}{real_pid} && $pid != $self->{job}{pid}) {

		carp 'Forks::Super::bg_eval: ',
			"failed to retrieve result from process!\n";
		$self->{value_set} = 1;
		$self->{error} = 
		    'waitpid failed, result not retrieved from process';
		return ();  # v0.53 on failure return empty string
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
		$self->{value} = [];
	    } elsif (ref $self->{value} ne 'ARRAY') {

		if (!length($self->{value})) {
		    $self->{value} = [];
		} else {
		    $self->{value} = [ $self->{value} ];
		}
	    }
	    $self->{value_set} = 1;
	} else {
	    croak "expect  style  to be 'eval' in ",
	    	"Forks::Super::LazyEval::BackgroundArray";
	}
    }
    my $value = $self->{value};
    return @$value;
}

1;

=head1 NAME

Forks::Super::LazyEval::BackgroundArray

=head1 VERSION

0.97

=head1 DESCRIPTION

An object type used to implement the L<Forks::Super::bg_qx|Forks::Super/bg_qx>
and L<Forks::Super::bg_eval|Forks::Super/bg_eval> lazy asynchronous
evaluation functions for list context.
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
