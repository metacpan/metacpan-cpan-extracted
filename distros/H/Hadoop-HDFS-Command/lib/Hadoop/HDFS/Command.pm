package Hadoop::HDFS::Command;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.001';

use Capture::Tiny   ();
use Carp            ();
use Data::Dumper;
use DateTime::Format::Strptime;
use DateTime;
use Getopt::Long    ();
use IPC::Cmd        ();
use Ref::Util       ();
use Time::HiRes   qw( time );
use Types::Standard qw(Bool);

{ use Moo; }

has cmd_hdfs => (
    is  => 'rw',
    isa => sub {
        my $val = shift;
        return if $val && -e $val && -x _;
        Carp::confess sprintf "The command `%s` either does not exist or not an executable!",
                        $val,
        ;
    },
    default => sub { '/usr/bin/hdfs' },
    lazy    => 1,
);

has enable_log => (
    is      => 'rw',
    isa     => Bool,
    default => sub { 0 },
    lazy    => 1,
);

sub dfs {
    my $self = shift;
    my $options = Ref::Util::is_hashref $_[0] ? shift( @_ ) : {};
    (my $cmd    = shift || die "No dfs command specified") =~ s{ \A [-]+ }{}xms;
    my $method  = '_dfs_' . $cmd;
    Carp::croak "'$cmd' is not implemented!" if ! $self->can( $method );
    $self->$method( $options, @_ );
}

sub _dfs_ls {
    my $self = shift;
    state $strp;

    my $options = shift;
    my @params  = @_;
    my @flags   = qw( d h R );
    my($arg, $paths) = $self->_parse_options(
                            \@params,
                            \@flags,
                            undef,
                            {
                                require_params => 1,
                            },
                        );

    my $want_epoch = $options->{want_epoch};
    my $cb = delete $options->{callback};

    if ( $cb ) {
        die "callback needs to be a CODE" if ! Ref::Util::is_coderef $cb;
        if ( defined wantarray ) {
            Carp::croak "You need to call this function in void context when callback is specified";
        }
    }

    my @response = $self->_capture(
        $options,
        $self->cmd_hdfs,
        qw( dfs -ls ),
        ( map { '-' . $_ } grep { $arg->{ $_ } } @flags ),
        @{ $paths },
    );

    # directory is empty
    #
    return if ! @response;

    if ( $response[0] && $response[0] =~ m{ \A Found \s+ [0-9] }xms ) {
        shift @response; # junk
    }

    my $space = q{ };

    my @rv;
    for my $line ( @response ) {
        my($mode, $replication, $user, $group, @unknown) = split m{ \s+ }xms, $line, 5;
        my @rest = map { split $space, $_ } @unknown;
        my $size;
        if ( $arg->{h}) {
            if ( $rest[0] eq '0' || $rest[1] !~ m{ [a-zA-Z_] }xms ) {
                $size = shift @rest;
            }
            else {
                $size = join $space, shift @rest, shift @rest;
            }
        }
        else {
            $size = shift @rest;
        }
        my $date   = join ' ', shift @rest, shift @rest;
        my $path   = shift( @rest ) || die "Unable to parse $line to gather the path";
        my $is_dir = $mode =~ m{ \A [d] }xms ? 1 : 0;

        my %record = (
            mode        => $mode,
            replication => $replication,
            user        => $user,
            group       => $group,
            size        => $size,
            date        => $date,
            path        => $path,
            type        => $is_dir ? 'dir' : 'file',
        );

        if ( $want_epoch ) {
            $strp ||= DateTime::Format::Strptime->new(
                            pattern   => '%Y-%m-%d %H:%M',
                            time_zone => 'CET',
                            on_error  => 'croak',
                        );
            eval {
                $record{epoch} = $strp->parse_datetime( $date )->epoch;
                1;
            } or do {
                my $eval_error = $@ || 'Zombie error';
                $self->_log( debug => 'Failed to convert %s into an epoch: %s',
                                $date,
                                $eval_error,
                );
            };
        }

        if ( @rest ) {
            # interpret as the rest of the path as spaces in paths are ok
            # possibly this will need to be revisited in the future.
            #
            $record{path} = join $space, $record{path}, @rest;
        }

        if ( $cb ) {
            # control the flow from the callback
            # So, the return value matters.
            #
            if ( ! $cb->( \%record ) ) {
                $self->_log( info => 'Terminating the ls processing as the user callback did not return a true value.');
                last;
            }
            next;
        }

        push @rv, { %record };
    }

    return if $cb;
    return @rv;
}

sub _dfs_du {
    my $self = shift;
    my $options = shift;
    my @params  = @_;
    my @flags   = qw( h s );
    my($arg, $paths) = $self->_parse_options(
                            \@params,
                            \@flags,
                            undef,
                            {
                                require_params => 1,
                            },
                        );

    my @rv = $self->_capture(
        $options,
        $self->cmd_hdfs,
        qw( dfs -du ),
        ( map { '-' . $_ } grep { $arg->{ $_ } } @flags ),
        @{ $paths },
    ) or die "No output collected from -du command";

    return map {
        my @val = split m{ \s{2,} }xms, $_;
        {
            size                => shift( @val ),
            name                => pop(   @val ),
            ( @val ? (
            disk_space_consumed => shift( @val ),
            ) : () ),
        }
    } @rv;
}

sub _dfs_mv {
    my $self = shift;
    my $options = shift;
    my @params  = @_;
    my($arg, $paths) = $self->_parse_options(
                            \@params,
                            [],
                            undef,
                            {
                                require_params => 1,
                            },
                        );
    my $source = shift @{ $paths } || die "Source path not specified";
    my $target = shift @{ $paths } || die "Target path not specified";

    # will die on error
    $self->_capture(
        $options,
        $self->cmd_hdfs,
        qw( dfs -mv ),
        $source => $target,
    );

    return;
}

sub _dfs_rm {
    my $self = shift;
    my $options = shift;
    my @params  = @_;
    my @flags   = qw( f r skipTrash );
    my($arg, $paths) = $self->_parse_options(
                            \@params,
                            \@flags,
                            undef,
                            {
                                require_params => 1,
                            },
                        );

    my @response = $self->_capture(
        $options,
        $self->cmd_hdfs,
        qw( dfs -rm ),
        ( map { '-' . $_ } grep { $arg->{ $_ } } @flags ),
        @{ $paths },
    );

    # just a confirmation message
    return @response;
}

sub _dfs_put {
    my $self = shift;
    my $options = shift;
    my @params  = @_;
    my @flags   = qw( f p l - );
    my($arg, $paths) = $self->_parse_options(
                            \@params,
                            \@flags,
                            undef,
                            {
                                require_params => 1,
                            },
                        );

    if ( $paths->[0] && $paths->[0] eq '\-' ) {
        shift @{ $paths };
        $options->{stdin} = pop( @{ $paths } ) || die "stdin content not specified!";
    }

    if ( @{ $paths } < ( $options->{stdin} ? 1 : 2 ) ) {
        die "Missing arguments!";
    }

    my @response = $self->_capture_with_stdin(
        $options,
        $self->cmd_hdfs,
        qw( dfs -put ),
        ( map { $_ eq '-' ? $_ : '-' . $_ } grep { $arg->{ $_ } } @flags ),
        ( $options->{stdin} ? '-' : () ),
        @{ $paths },
    );

    # just a confirmation message
    return @response;
}

sub _parse_options {
    my $self = shift;
    # TODO: collect dfs generic options
    #
    # Generic options supported are
    # -conf <configuration file>     specify an application configuration file
    # -D <property=value>            use value for given property
    # -fs <local|namenode:port>      specify a namenode
    # -jt <local|resourcemanager:port>    specify a ResourceManager
    # -files <comma separated list of files>    specify comma separated files to be copied to the map reduce cluster
    # -libjars <comma separated list of jars>    specify comma separated jar files to include in the classpath.
    # -archives <comma separated list of archives>    specify comma separated archives to be unarchived on the compute machines.

    my($params, $flags, $opt, $conf) = @_;
    $conf ||= {};
    my @params = map { $_ eq '-' ? '\-' : $_ } @{ $params };

    Getopt::Long::GetOptionsFromArray(
        \@params,
        \my %arg,
        (
            map { Ref::Util::is_arrayref $_ ? @{ $_ } : () }
                $flags,
                $opt,
        ),
    ) || die qq{Unable to parse parameters: '@{$params}'};

    if ( $conf->{require_params} && ! @params ) {
        die "No parameters were specified!";
    }

    return \%arg, [ @params ];
}

sub _capture {
    my $self = shift;
    my $options = shift;
    my @cmd     = @_;

    $self->_log( debug => 'Executing command: %s', join(' ', @cmd) );

    my $start = time;

    my($stdout, $stderr, $fail) = Capture::Tiny::capture {
        system( @cmd );
    };

    $self->_log( debug => 'Execution took %.3f seconds', time - $start );

    if ( $fail ) {
        my $code = $fail >> 8;
        $stderr ||= '[no error]';
        my $msg = "External command (@cmd) failed with status=$code: $stderr";
        if ( $options->{ignore_fail} ) {
            if ( ! $options->{silent} ) {
                warn "[Fatal error downgraded to a warning] $msg";
            }
            return $self->_split_on_newlines( $stdout || '' );
        }
        die $msg;
    }

    if ( $stderr ) {
        warn "Warning from external command: $stderr";
    }

    return $self->_split_on_newlines( $stdout );
}

sub _capture_with_stdin {
    my $self = shift;
    # TODO: use a single capture method.
    my $options = shift;
    my @cmd     = @_;

    my $stdin = delete $options->{stdin};

    $self->_log( debug => 'Executing command(IPC): %s', join(' ', @cmd) );

    my $start = time;

    my $res = IPC::Cmd::run_forked(
                    \@cmd,
                    {
                        ( $stdin ? (
                        child_stdin                      => $stdin,
                        ) : () ),
                        #timeout                          => $timeout,
                        terminate_on_parent_sudden_death => 1,
                    }
                );

    $self->_log( debug => 'Execution took %.3f seconds', time - $start );

    my($stdout, $stderr, $fail);

    my $success = defined  $res->{exit_code}
                        && $res->{exit_code} == 0
                        && ! $res->{timeout};

    $fail   = $success ? 0 : $res->{exit_code};
    $stderr = $res->{stderr};
    $stdout = $res->{stdout};

    if ( $fail ) {
        my $code = $fail >> 8;
        $stderr ||= $res->{err_msg} || '[no error]';
        my $msg = "External command (@cmd) failed with status=$code: $stderr";
        if ( $options->{ignore_fail} ) {
            if ( ! $options->{silent} ) {
                warn "[Fatal error downgraded to a warning] $msg";
            }
            return $self->_split_on_newlines( $stdout || '' );
        }
        die $msg;
    }

    if ( $stderr ) {
        warn "Warning from external command: $stderr";
    }

    return $self->_split_on_newlines( $stdout );
}

sub _split_on_newlines {
    my $self = shift;
    my $rv = shift;

    $rv =~ s{ \A \s+    }{}xms;
    $rv =~ s{    \s+ \z }{}xms;

    return split m{ \n+ }xms, $rv;
}

sub _log {
    my $self = shift;
    return if ! $self->enable_log;
    my($level, $tmpl, @param) = @_;
    my $msg = sprintf "[%s] %s\n", uc $level, $tmpl;
    printf STDERR $msg, @param;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Hadoop::HDFS::Command

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use Hadoop::HDFS::Command;
    my $hdfs = Hadoop::HDFS::Command->new;
    my @rv = $hdfs->$command( @command_args );

=head1 DESCRIPTION

This is a simple wrapper around the hdfs commandline to make them easier to
call from Perl and parse their output.

The interface is partially done at the moment (see the implemented wrappers
down below).

You can always use the WebHDFS to do similar operations instead of failling
back to the commandline. However there are several benefits of using the
cli; i) you'll end up with a single C<JVM> invocation, so the response
might be faster ii) Some functionality / endpoints might be buggy for WebHDFS
but might work with the cli (for example escaping certain values is broken
in some versions, but works with the cli).

=head1 NAME

Hadoop::HDFS::Command - Wrappers for various hadoop hdfs cli commands

=head1 METHODS

=head2 new

The constructor. Available attributes are listed below.

=head3 cmd_hdfs

Default value is C</usr/bin/hdfs>. This option needs to be altered if you have
the C<`hdfs`> command in some other place.

=head3 enable_log :Bool

Can be used to enable the internal logging feature. Disabled by default.

=head2 dfs

One of the top level commands, including an interface to the sub-commands
listed below. The calling convention of the sub commands is as simple as:

    my @rv = $hdfs->dfs( \%options, $sub_command => @subcommand_args );
    # options hash is optional
    my @rv = $hdfs->dfs( $sub_command => @subcommand_args );

Available options are listed below:

=over 4

=item ignore_fail :Bool

Global.

=item silent :Bool

Global.

=item want_epoch :Bool

Only used for C<ls>. Converts timestamps to epoch.

=item callback :CODE

Only used for C<ls>. The callback always needs to return true to continue
processing, returning false from it will short-circuit the processor.

=back

=head3 du

The C<@subcommand_args> can have these defined: C<-s>, C<-h>.

    my @rv = $hdfs->dfs( du => @subcommand_args => $hdfs_path );
    my @rv = $hdfs->dfs( du => qw( -h -s ) => "/tmp" );
    my @rv = $hdfs->dfs(
                {   
                    ignore_fail => 1,
                    silent      => 1,
                },  
                du => -s => @hdfs_paths,
            );

=head3 ls

The C<@subcommand_args> can have these defined: C<-d>, C<-h>, C<R>.

    my @rv = $hdfs->dfs( ls => @subcommand_args => $hdfs_path );

The callback can be used to prevent buffering and process the result set yourself.
The callback always needs to return true to continue processing. If you want to
skip some entries but continue processing then a true value needs to be returned.
A bare return (which is false) will short circuit the iterator and discard any
remaining records.

    my %options = (
        callback => sub {
            # This callback will receive a hash meta-data about the file.
            my $file = shift;
            if ( $file->{type} eq 'dir' ) {
                # do something
            }
            
            # skip this one, but continue processing
            return 1 if $file->{type} ne 'file';
            
            # do something
            
            return if $something_really_bad_so_end_this_processor;
            
            # continue processing
            return 1;
        },
        # The meta-data passed to the callback will have an "epoch"
        # key set when this is true.
        want_epoch => 1,
    );
    # execute the command recursively on the path
    $hdfs->dfs( \%options, ls => -R => $hdfs_path );

=head3 mv

    my @rv = $hdfs->dfs( mv => $hdfs_source_path, $hdfs_dest_path );

=head3 put

The C<@subcommand_args> can have these defined: C<-f>, C<-p>, C<-l>

    $hdfs->dfs( put => @subcommand_args, $local_path, $hdfs_path );
    # notice the additional "-"
    $hdfs->dfs( put => '-f', '-', $hdfs_path, $in_memory_data );

=head3 rm

The C<@subcommand_args> can have these defined: C<-f>, C<-r>, C<-skipTrash>

    $hdfs->dfs( rm => @subcommand_args, $hdfs_path );

=head1 SEE ALSO

C<`hdfs dfs -help`>.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
