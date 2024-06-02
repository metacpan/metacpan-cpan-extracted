use strict;
use warnings;
package Dist::Zilla::Plugin::Run::Role::Runner;
# vim: set ts=8 sts=2 sw=2 tw=115 et :

our $VERSION = '0.050';

use Moose::Role;
use namespace::autoclean;
use File::Spec (); # core
use Config     (); # core
use Moose::Util 'find_meta';

has perlpath => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => 'current_perl_path',
);

has censor_commands => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
);

has [ qw(run run_if_trial run_no_trial run_if_release run_no_release) ] => (
    is => 'ro',
    isa  => 'ArrayRef[Str]',
    default => sub { [] },
);

has eval => (
    is => 'ro',
    isa  => 'ArrayRef[Str]',
    default => sub { [] },
);

has fatal_errors => (
    is => 'ro',
    isa => 'Bool',
    default => 1,
);

has quiet => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
);

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        version => $VERSION,
        (map +($_ => $self->$_ ? 1 : 0), qw(fatal_errors quiet)),
        map
            @{ $self->$_ }
                # look for user:password URIs
                ? ( $_ => [ map $self->censor_commands || /\b\w+:[^@]+@\b/ ? 'REDACTED' : $_, @{ $self->$_ } ] )
                : (),
            qw(run run_if_trial run_no_trial run_if_release run_no_release eval),
    };

    return $config;
};

around BUILDARGS => sub {
    my ( $orig, $class, @args ) = @_;
    my $built = $class->$orig(@args);

    foreach my $dep (qw( notexist_fatal )) {
        if ( exists $built->{$dep} ) {
            warn(" !\n ! $class attribute '$dep' is deprecated and has no effect.\n !\n");
            delete $built->{$dep};
        }
    }
    return $built;
};

sub _is_trial {
    my $self = shift;

    # we want to avoid provoking other plugins prematurely, but also be as
    # accurate as we can with this status

    my $release_status_attr = find_meta($self->zilla)->find_attribute_by_name('release_status');

    return ( $self->zilla->is_trial ? 1 : 0 ) if
        not $release_status_attr     # legacy (before Dist::Zilla 5.035)
        or $release_status_attr->has_value($self->zilla);

    # otherwise, only use the logic that does not require zilla->version
    # before Dist::Zilla 5.035, this is what $zilla->is_trial returned
    return eval { $self->zilla->_release_status_from_env =~ /\A(?:testing|unstable)\z/ } ? 1 : 0;
}

sub _call_script {
    my ( $self, $params ) = @_;

    foreach my $run_cmd (@{$self->run}) {
        $self->_run_cmd($run_cmd, $params);
    }

    foreach my $run_cmd (@{$self->run_if_trial}) {
        if ($self->_is_trial) {
            $self->_run_cmd($run_cmd, $params);
        } else {
            $self->log_debug([ 'not executing, because no trial: %s', $run_cmd ]);
        }
    }

    foreach my $run_cmd (@{$self->run_no_trial}) {
        if ($self->_is_trial) {
            $self->log_debug([ 'not executing, because trial: %s', $run_cmd ]);
        } else {
            $self->_run_cmd($run_cmd, $params);
        }
    }

    my $is_release = defined $ENV{'DZIL_RELEASING'} && $ENV{'DZIL_RELEASING'} == 1 ? 1 : 0;

    foreach my $run_cmd (@{$self->run_if_release}) {
        if ($is_release) {
            $self->_run_cmd($run_cmd, $params);
        } else {
            $self->log_debug([ 'not executing, because no release: %s', $run_cmd ]);
        }
    }

    foreach my $run_cmd (@{$self->run_no_release}) {
        if ($is_release) {
            $self->log_debug([ 'not executing, because release: %s', $run_cmd ]);
        } else {
            $self->_run_cmd($run_cmd, $params);
        }
    }

    if (my @code = @{ $self->eval }) {
        my $code = join "\n", @code;

        $self->_eval_cmd($code, $params);
    }
}

sub _run_cmd {
    my ( $self, $run_cmd, $params, $dry_run ) = @_;

    if ($dry_run) {
        $self->log_debug([ 'dry run, would run: %s', $run_cmd ]);
        return;
    }

    return if not $run_cmd;

    require IPC::Open3;  # core

    my $command = $self->build_formatter($params)->format($run_cmd);
    $self->${ $self->quiet ? \'log_debug' : \'log' }([ 'executing: %s', $command ]);

    # autoflush STDOUT so we can see command output right away
    local $| = 1;
    # allow stderr to remain, for visibility into errors
    my $pid = IPC::Open3::open3(my ($in, $out), '>&STDERR', $command);
    binmode $out, ':crlf' if $^O eq 'MSWin32';
    while(defined(my $line = <$out>)){
        chomp($line); # logger appends its own newline
        $self->${ $self->quiet ? \'log_debug' : \'log' }($line);
    }

    # zombie repellent
    waitpid($pid, 0);

    if (my $status = ($? >> 8)) {
        $self->${ $self->fatal_errors ? \'log_fatal' : $self->quiet ? \'log_debug' : \'log'}
            ([ 'command exited with status %s (%s)', $status, $? ]);
    }
    else {
        $self->log_debug('command executed successfully');
    }
}

sub _eval_cmd {
    my ( $self, $code, $params, $dry_run ) = @_;

    if ($dry_run) {
        $self->log_debug([ 'dry run, would evaluate: %s', $code ]);
        return;
    }

    $code = $self->build_formatter($params)->format($code);
    $self->${ $self->quiet ? \'log_debug' : \'log' }([ 'evaluating: %s', $code ]);

    my $sub = __eval_wrapper($code);
    $sub->($self);
    my $error = $@;

    if (defined $error and $error ne '') {
        if ($self->fatal_errors and $self->quiet and not $self->zilla->logger->get_debug) {
            $self->log([ 'evaluated: %s', $code]);
        }

        $self->${ $self->fatal_errors ? \'log_fatal' : $self->quiet ? \'log_debug' : \'log'}
            ([ 'evaluation died: %s', $error ]);
    }
}

sub __eval_wrapper {
    my $code = shift;
    sub { eval $code };
}

around mvp_multivalue_args => sub {
    my ($original, $self) = @_;

    my @res = $self->$original();

    push @res, qw( run run_no_trial run_if_trial run_if_release run_no_release eval );

    @res;
};

my $path_separator = (File::Spec->catfile(qw(a b)) =~ m/^a(.+?)b$/)[0];

sub build_formatter {
    my ( $self, $params ) = @_;

    require String::Formatter;
    String::Formatter->VERSION(0.102082);

    my $codes = {
        # not always available
        # explicitly pass a string (not an object) [rt-72008]
        a => sub {
            return "$params->{archive}" if defined $params->{archive};
            $self->log('attempting to use %a in a non-Release plugin');
            '';
        },

        # source dir
        o => sub {
            my $dir = $params->{source_dir} || $self->zilla->root;
            return $dir ? "$dir" : '';
        },

        # build dir or mint dir
        d => sub {
            require Path::Tiny;
            # stringify build directory
            my $dir = $params->{dir} || $self->zilla->built_in;
            return Path::Tiny::path($dir)->canonpath if $dir;
            $self->log('attempting to use %d in before_build');
            '';
        },

        # distribution name
        n => sub { $self->zilla->name },

        # backward compatibility (don't error)
        s => '',

        # portability
        p => $path_separator,
        x => sub { $self->perlpath },
    };

    # available during build, not mint
    unless( $params->{minting} ){
        $codes->{v} = sub { $self->zilla->version };
        $codes->{t} = sub { $self->_is_trial ? '-TRIAL' : '' };
    }

    # positional replacement of %s (backward compatible)
    if( my @pos = @{ $params->{pos} || [] } ){
        # where are you defined-or // operator?
        $codes->{s} = sub {
            my $s = shift(@pos);
            $s = $s->() if ref $s eq 'CODE';
            defined($s) ? $s : '';
        };
    }

    return String::Formatter->new({ codes => $codes });
}

sub current_perl_path { $^X }

1;
