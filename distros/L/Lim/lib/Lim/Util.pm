package Lim::Util;

use common::sense;
use Carp;

use Log::Log4perl ();
use File::Temp ();
use Fcntl qw(:seek);
use IO::File ();
use Digest::SHA ();
use Scalar::Util qw(blessed);
eval 'use URI::Escape::XS qw(uri_unescape);';
if ($@) {
    eval 'use URI::Escape qw(uri_unescape);';
    die $@ if $@;
}
use AnyEvent ();
use AnyEvent::Util ();
use AnyEvent::Socket ();

use Lim ();

=encoding utf8

=head1 NAME

Lim::Util - Utilities for plugins

=head1 VERSION

See L<Lim> for version.

=cut

our $VERSION = $Lim::VERSION;
our %CALL_METHOD = (
    Create => 'POST',
    Read => 'GET',
    Update => 'PUT',
    Delete => 'DELETE'
);

=head1 SYNOPSIS

=over 4

use Lim::Util;

=back

=head1 METHODS

=over 4

=item $full_path = Lim::Util::FileExists($file)

Check if C<$file> exists by prefixing L<Lim::Config>->{prefix} and returns the
full path to the file or undef if it does not exist.

=cut

sub FileExists {
    my ($file) = @_;

    if (defined $file) {
        $file =~ s/^\///o;
        foreach (@{Lim::Config->{prefix}}) {
            my $real_file = $_.'/'.$file;

            if (-f $real_file) {
                return $real_file;
            }
        }
    }
    return;
}

=item $full_path = Lim::Util::FileReadable($file)

Check if C<$file> exists by prefixing L<Lim::Config>->{prefix} and if it is
readable. Returns the full path to the file or undef if it does not exist.

=cut

sub FileReadable {
    my ($file) = @_;

    if (defined $file) {
        $file =~ s/^\///o;
        foreach (@{Lim::Config->{prefix}}) {
            my $real_file = $_.'/'.$file;

            if (-f $real_file and -r $real_file) {
                return $real_file;
            }
        }
    }
    return;
}

=item $full_path = Lim::Util::FileWritable($file)

Check if C<$file> exists by prefixing L<Lim::Config>->{prefix} and if it is
writable. Returns the full path to the file or undef if it does not exist.

=cut

sub FileWritable {
    my ($file) = @_;

    if (defined $file) {
        $file =~ s/^\///o;
        foreach (@{Lim::Config->{prefix}}) {
            my $real_file = $_.'/'.$file;

            if (-f $real_file and -w $real_file) {
                return $real_file;
            }
        }
    }
    return;
}

=item $content = Lim::Util::FileReadContent($file)

Read the file and return the content or undef if there was an error.

=cut

sub FileReadContent {
    my ($file) = @_;

    if (-r $file and defined (my $fh = IO::File->new($file))) {
        my ($tell, $content);
        $fh->seek(0, SEEK_END);
        $tell = $fh->tell;
        $fh->seek(0, SEEK_SET);
        if ($fh->read($content, $tell) == $tell) {
            return $content;
        }
    }
    return;
}

=item [$temp_file] = Lim::Util::FileWriteContent([$file | $object,] $content)

Write the content to a file or a new temporary file, content in file will be
reread and checked with a SHA checksum.

If the C<$file> is specified, write the content to the filename and return 1 or
undef on error. Will overwrite the file if it exists.

If the C<$object> is a L<Temp::File> object, write the content to that file and
return 1 or undef on error.

If no C<$file> or C<$object> is specified, write the content to a new temporary
file and return the L<File::Temp> object or undef on error.

=cut

sub FileWriteContent {
    my ($file, $content) = @_;
    my $filename;

    if (defined $file and !defined $content) {
        $content = $file;
        undef($file);
    }
    if (blessed $file) {
        unless ($file->isa('File::Temp')) {
            return;
        }
        $filename = $file->filename;
    }
    elsif (defined $file) {
        my $fh = IO::File->new;
        unless ($fh->open($file, '>')) {
            return;
        }
        $filename = $file;
        $file = $fh;
    }
    unless (defined $content) {
        return;
    }
    unless (defined $file) {
        eval {
            $file = File::Temp->new;
        };
        if ($@) {
            # TODO log error
            return;
        }
        $filename = $file->filename;
    }

    print $file $content;
    $file->flush;
    $file->close;

    my $fh = IO::File->new;
    if ($fh->open($filename)) {
        my ($tell, $read);
        $fh->seek(0, SEEK_END);
        $tell = $fh->tell;
        $fh->seek(0, SEEK_SET);
        unless ($fh->read($read, $tell) == $tell) {
            $fh->close;
            unless ($file->isa('File::Temp')) {
                unlink($filename);
            }
            return;
        }
        unless (Digest::SHA::sha1_base64($content) eq Digest::SHA::sha1_base64($read)) {
            $fh->close;
            unless ($file->isa('File::Temp')) {
                unlink($filename);
            }
            return;
        }
    }
    return $file->isa('File::Temp') ? $file : 1;
}

=item $temp_file = Lim::Util::TempFile

Creates a temporary file. Returns a L<File::Temp> object or undef if there where
problems creating the temporary file.

=cut

sub TempFile {
    my $tmp;

    eval {
        $tmp = File::Temp->new;
    };

    unless ($@) {
        # TODO log error
        return $tmp;
    }
    return;
}

=item $temp_file = Lim::Util::TempFileLikeThis($file)

Creates a temporary file that will have the same owner and mode as the specified
C<$file>. Returns a L<File::Temp> object or undef if the specified file did not
exist or if there where problems creating the temporary file.

=cut

sub TempFileLikeThis {
    my ($file) = @_;

    if (defined $file and -f $file) {
        my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
            $atime,$mtime,$ctime,$blksize,$blocks)
            = stat($file);
        my $tmp;

        eval {
            $tmp = File::Temp->new;
        };

        # TODO log error

        unless ($@) {
            if (chmod($mode, $tmp->filename) and chown($uid, $gid, $tmp->filename)) {
                return $tmp;
            }
        }
    }
    return;
}

=item ($method, $uri) = Lim::Util::URIize($call)

Returns an URI based on the C<$call> given and the corresponding HTTP method to
be used.

Example:

=over 4

use Lim::Util;
($method, $uri) = Lim::Util::URIize('ReadVersion');
print "$method $ur\n";
($method, $uri) = Lim::Util::URIize('CreateOtherCall');
print "$method $ur\n";

=back

Produces:

=over 4

GET /version
PUT /other_call

=back

=cut

sub URIize {
    my @parts = split(/([A-Z][^A-Z]*)/o, $_[0]);
    my ($part, $method, $uri);

    while (scalar @parts) {
        $part = shift(@parts);
        if ($part ne '') {
            last;
        }
    }

    unless (exists $CALL_METHOD{$part}) {
        confess __PACKAGE__, ': No conversion found for ', $part, ' (', $_[0], ')';
    }

    $method = $CALL_METHOD{$part};

    @parts = grep !/^$/o, @parts;
    unless (scalar @parts) {
        confess __PACKAGE__, ': Could not build URI (', $_[0], ')';
    }
    $uri = lc(join('_', @parts));

    return ($method, '/'.$uri);
}

=item $hash_ref = Lim::Util::QueryDecode($query_string)

Returns an HASH reference of the decode query string.

=cut

sub QueryDecode {
    my ($href, $href_final) = ({}, {});

    foreach my $part (split(/&/o, $_[0])) {
        my ($key, $value) = split(/=/o, $part, 2);

        $key = uri_unescape($key);
        $value = uri_unescape($value);

        unless ($key) {
            return;
        }

        # check if last element is array and remove it from $key
        my $array = $key =~ s/\[\]$//o ? 1 : 0;
        # verify $key
        unless ($key =~ /^[^\]]+(?:\[[^\]]+\])*$/o) {
            return;
        }
        # remove last ] so we don't split or get it in $k
        $key =~ s/\]$//o;

        my @keys = split(/(?:\]\[|\[)/o, $key);
        my $this = $href;
        while (defined (my $k = shift(@keys))) {
            unless (scalar @keys) {
                if ($array and exists $this->{$k}) {
                    unless (ref($this->{$k}) eq 'ARRAY') {
                        return;
                    }
                    push(@{$this->{$k}}, $value);
                    last;
                }
                $this->{$k} = $array ? [ $value ] : $value;
                last;
            }

            if (exists $this->{$k}) {
                $this = $this->{$k};
                next;
            }

            $this = $this->{$k} = {};
        }
    }

    # restruct hashes with all numeric keys to arrays
    my @process = ([$href, $href_final, undef, undef]);
    while (defined (my $this = shift(@process))) {
        my ($old, $new, $parent, $key) = @$this;

        my $numeric = 1;
        foreach (keys %$old) {
            unless (/^\d+$/o) {
                $numeric = 0;
                last;
            }
        }

        if ($numeric) {
            my @array;
            foreach (sort (keys %$old)) {
                if (ref($old->{$_}) eq 'HASH') {
                    my $entry = {};
                    push(@array, $entry);
                    push(@process, [$old->{$_}, $entry, \@array, scalar @array - 1]);
                    next;
                }
                push(@array, $old->{$_});
            }

            if (ref($parent) eq 'HASH') {
                $parent->{$key} = \@array;
            }
            elsif (ref($parent) eq 'ARRAY') {
                $parent->[$key] = \@array;
            }
            else {
                return;
            }
        }
        else {
            foreach (keys %$old) {
                if (ref($old->{$_}) eq 'HASH') {
                    $new->{$_} = {};
                    push(@process, [$old->{$_}, $new->{$_}, $new, $_]);
                    next;
                }
                $new->{$_} = $old->{$_};
            }
        }
    }

    return $href_final;
}

=item $camelized = Lim::Util::Camelize($underscore)

Convert underscored text to camelized, used for translating URI to calls.

Example:

=over 4

use Lim::Util;
print Lim::Util::Camelize('long_u_r_i_call_name'), "\n";

=back

Produces:

=over 4

LongURICallName

=back

=cut

sub Camelize {
    my ($underscore) = @_;
    my $camelized;

    foreach (split(/_/o, $underscore)) {
        $camelized .= ucfirst($_);
    }

    return $camelized;
}

=item [$cv =] Lim::Util::run_cmd $cmd, key => value...

This function extends L<AnyEvent::Util::run_cmd> with a timeout and will also
set C<close_all> option.

=over 4

=item timeout => $seconds

Creates a timeout for the running command and will try and kill it after the
specified C<$seconds>, see below how you can change the kill functionallity.

Using C<timeout> will set C<$$> option to L<AnyEvent::Util::run_cmd> so you
won't be able to use that option.

=item cb => $callback->($cv)

This is required if you'r using C<timeout>.

Call the given C<$callback> when the command finish or have timed out with the
condition variable returned by L<AnyEvent::Util::run_cmd>. If the command timed
out the condition variable will be set as if the command failed.

=item kill_sig => 15

Signal to use when trying to kill the command.

=item kill_try => 3

Number of times to try and kill the command with C<kill_sig>.

=item interval => 1

Number of seconds to wait between each attempt to kill the command.

=item kill_kill => 1

If true (default) kill the command with signal KILL after trying to kill it with
C<kill_sig> for the specified number of C<kill_try> attempts.

=back

=cut

sub run_cmd {
    my $cmd = shift;
    my %args = (
        kill_try => 3,
        kill_kill => 1,
        kill_sig => 15,
        interval => 1,
        @_
    );
    my ($pid, $timeout) = (0, undef);

    my %pass_args = %args;
    foreach (qw(kill_try kill_kill timeout interval cb)) {
        delete $pass_args{$_};
    }
    $pass_args{close_all} = 1;

    if (exists $args{timeout}) {
        $pass_args{'$$'} = \$pid;

        unless (exists $args{cb} and ref($args{cb}) eq 'CODE') {
            confess __PACKAGE__, ': must have cb with timeout or invalid';
        }

        unless ($args{timeout} > 0) {
            confess __PACKAGE__, ': timeout invalid';
        }

        unless ($args{interval} > 0) {
            confess __PACKAGE__, ': interval invalid';
        }

        unless ($args{kill_try} >= 0) {
            confess __PACKAGE__, ': kill_try invalid';
        }

        $timeout = AnyEvent->timer(
            after => $args{timeout},
            interval => $args{interval},
            cb => sub {
                unless ($pid) {
                    undef($timeout);
                    return;
                }

                if ($args{kill_try}--) {
                    Lim::DEBUG and Log::Log4perl->get_logger->debug('trying to kill cmd ', (ref($cmd) eq 'ARRAY' ? join(' ', @$cmd) : $cmd));
                    kill($args{kill_sig}, $pid);
                }
                else {
                    if ($args{kill_kill}) {
                        Lim::DEBUG and Log::Log4perl->get_logger->debug('killing cmd ', (ref($cmd) eq 'ARRAY' ? join(' ', @$cmd) : $cmd));
                        kill(9, $pid);
                    }
                    undef($timeout);
                }
            });

        Lim::DEBUG and Log::Log4perl->get_logger->debug('run_cmd [timeout ', $args{timeout},'] ', (ref($cmd) eq 'ARRAY' ? join(' ', @$cmd) : $cmd));

        my $cv = AnyEvent::Util::run_cmd
            $cmd,
            %pass_args;
        $cv->cb(sub {
            Lim::DEBUG and Log::Log4perl->get_logger->debug('cmd end ', (ref($cmd) eq 'ARRAY' ? join(' ', @$cmd) : $cmd));
            undef($timeout);
            $args{cb}->(@_);
        });
        return;
    }

    Lim::DEBUG and Log::Log4perl->get_logger->debug('run_cmd ', (ref($cmd) eq 'ARRAY' ? join(' ', @$cmd) : $cmd));

    return AnyEvent::Util::run_cmd
        $cmd,
        %pass_args;
}

=item Lim::Util::resolve_host $host, $port, $cb->($ipAddress, $port);

=cut

sub resolve_host {
    my ($host, $port, $cb) = @_;

    unless (defined $host) {
        confess __PACKAGE__, ': Missing host';
    }
    unless (ref($cb) eq 'CODE') {
        confess __PACKAGE__, ': Missing cb or is not CODE';
    }

    if (AnyEvent::Socket::parse_address($host)) {
        $cb->($host, $port);
        return;
    }

    if (Lim::Config->{rpc}->{skip_dns}) {
        $cb->(Lim::Util::resolve_hosts($host), $port);
        return;
    }

    AnyEvent::Socket::resolve_sockaddr $host, $port, 0, undef, undef, sub {
        unless (scalar @_) {
            if (AnyEvent::Socket->VERSION < 6.01) {
                $cb->(Lim::Util::resolve_hosts($host), $port);
            }
            else {
                $cb->();
            }
            return;
        }

        unless (ref($_[0]) eq 'ARRAY') {
            # TODO: warn?
            $cb->();
            return;
        }

        my ($service, $ipn) = AnyEvent::Socket::unpack_sockaddr($_[0]->[3]);
        $cb->(AnyEvent::Socket::format_address($ipn), $service);
    };
}

=item $ipAddress = Lim::Util::resolve_hosts $host

=cut

sub resolve_hosts {
    my ($host, $cb) = @_;

    unless (defined $host) {
        confess __PACKAGE__, ': Missing host';
    }

    if (open(HOSTS, $^O eq 'MSWin32' ? $ENV{SystemRoot}.'/system32/drivers/etc/hosts' : '/etc/hosts')) {
        while(<HOSTS>) {
            s/[\r\n]+$//o;
            s/#.*//o;
            s/^\s+//o;
            s/\s+$//o;

            my ($addr, @aliases) = split(/\s+/o);
            if (grep(/^$host$/, @aliases)) {
                close(HOSTS);
                return $addr;
            }
        }
        close(HOSTS);
    }

    return;
}

=back

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lim::Util

You can also look for information at:

=over 4

=item * Lim issue tracker (report bugs here)

L<https://github.com/jelu/lim/issues>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Jerry Lundström.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lim::Util
