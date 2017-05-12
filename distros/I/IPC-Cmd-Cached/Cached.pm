###########################################
package IPC::Cmd::Cached;
###########################################
# 2007, Mike Schilli <cpan@perlmeister.com>
###########################################

use strict;
use warnings;
use Cache::FileCache;
use IPC::Cmd;
use Storable qw(freeze thaw);
use Log::Log4perl qw(:easy);

our $VERSION = "0.01";

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        cache => undef,
        %options,
    };

    if(! defined $self->{cache}) {
        $self->{cache} = Cache::FileCache->new({
            auto_purge_on_get  => 1,
            default_expires_in => 24*3600,
            namespace          => "IPC-Cmd-Cached",
        });
    }

    bless $self, $class;
}

###########################################
sub run {
###########################################
    my($self, @opts) = @_;

    DEBUG "Running @opts";

    my @result = IPC::Cmd::run(@opts);

    if(! defined $result[0]) {
        ERROR $result[4]->[0];
        return undef;
    }

    DEBUG "Return: $result[0]\n";

    if($result[0]) {
        DEBUG "Stdout: ", join('', @{$result[3]});
    }

    my $data = freeze({
        result => \@result,
        opts   => \@opts,
        time   => time,
    });

    my $key = normalize(@opts);

    $self->{cache}->set($key, $data);

    return @result;
}

###########################################
sub run_cached {
###########################################
    my($self, @opts) = @_;

    my $key = normalize(@opts);

    my $stored = $self->{cache}->get($key);

    if(defined $stored) {
        DEBUG "Found result for @opts in cache";
        my $data = thaw($stored);
        return @{ $data->{result} };
    }

    DEBUG "Didn't find result for @opts in cache";
    return undef;
}

###########################################
sub normalize {
###########################################
    my(@args) = @_;

    return join(" ", @args);
}

###########################################
sub run_all {
###########################################
    my($self) = @_;

    for my $key ($self->{cache}->get_keys()) {
        my $stored = $self->{cache}->get( $key );

        if(defined $stored) {
            my $data = thaw($stored);
            $self->run( @{ $data->{opts} } );
        }
    }
}

1;

__END__

=head1 NAME

IPC::Cmd::Cached - Run expensive commands and cache their output

=head1 SYNOPSIS

    use IPC::Cmd::Cached;

    my $runner = IPC::Cmd::Cached->new();

      # takes a fair mount to run, but result gets cached
    my($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) =
      $runner->run(command => "find /etc -type f -print");

      # Returns the same result much faster, because it's cached
    my($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) =
      $runner->run_cached("find /etc -type f -print");

      # To make sure the cached entries don't expire, run this 
      # twice a day via a cronjob:
    $runner->run_all();

=head1 DESCRIPTION

C<IPC::Cmd::Cached> uses C<IPC::Cmd> to run arbitrary shell commands,
but caches their results and finds them later. 

It uses a C<Cache::FileCache> object to store the output of commands it
has successfully executed persistently on disk. 
Results are store under a key equal to the
command line given to run the commands.

If a command's output doesn't change much over time and cached results
are acceptable, C<IPC::Cmd::Cached> saves time by reusing canned results
instead of recalculating the same results over and over again.

C<IPC::Cmd::Cached> works like the C<Memoize> module, but instead of
caching the output of functions, it caches the output of external scripts.

=head1 CAVEATS

A command's results are cached based on its full command line. This
might not be desirable if the same command produces varying 
output over time:

    $ eg/run-cached date
    Mon Dec 17 00:01:00 PST 2007
    $ eg/run-cached -c date
    Mon Dec 17 00:01:00 PST 2007

=head1 Advanced use cases

The constructor accepts arguments to change the runner's internal behavior:

=over 4

=item cache

By default, this is set to a Cache::FileCache object in the default
namespace with 24 hours of expiration time:

    my $runner = IPC::Cmd::Cached->new( 
      cache => Cache::FileCache->new({
        auto_purge_on_get  => 1,
        default_expires_in => 24*3600,
        namespace          => "IPC-Cmd-Cached",
      }),
    );

If you need different characteristics, define your own cache object and
hand it over to C<new> as shown above. Take a look at the Cache::Cache
documentation for details.

=back

=head1 EXAMPLES

The distribution comes with two utility scripts, C<run-cached> and 
C<run-cached-all>.

C<run-cached> runs a command specified on its command line. With the -c
option, it will fetch the cached entry instead.

C<run-cached-all> runs all scripts in the cache to refresh their content.

Check the documentation that comes with these scripts for more details.

=head1 LEGALESE

Copyright 2007 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2007, Mike Schilli <cpan@perlmeister.com>
