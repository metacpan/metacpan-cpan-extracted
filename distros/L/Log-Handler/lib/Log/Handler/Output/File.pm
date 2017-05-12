=head1 NAME

Log::Handler::Output::File - Log messages to a file.

=head1 SYNOPSIS

    use Log::Handler::Output::File;

    my $log = Log::Handler::Output::File->new(
        filename    => "file.log",
        filelock    => 1,
        fileopen    => 1,
        reopen      => 1,
        mode        => "append",
        autoflush   => 1,
        permissions => "0664",
        utf8        => 0,
    );

    $log->log(message => $message);

=head1 DESCRIPTION

Log messages to a file.

=head1 METHODS

=head2 new()

Call C<new()> to create a new Log::Handler::Output::File object.

The following options are possible:

=over 4

=item B<filename>

With C<filename> you can set a file name as a string or as a array reference.
If you set a array reference then the parts will be concat with C<catfile> from
C<File::Spec>.

Set a file name:

    my $log = Log::Handler::Output::File->new( filename => "file.log"  );

Set a array reference:

    my $log = Log::Handler::Output::File->new(

        # foo/bar/baz.log
        filename => [ "foo", "bar", "baz.log" ],

        # /foo/bar/baz.log
        filename => [ "", "foo", "bar", "baz.log" ],

    );

=item B<filelock>

Maybe it's desirable to lock the log file by each write operation because a lot
of processes write at the same time to the log file. You can set the option
C<filelock> to 0 or 1.

    0 - no file lock
    1 - exclusive lock (LOCK_EX) and unlock (LOCK_UN) by each write operation (default)

=item B<fileopen>

Open a log file transient or permanent.

    0 - open and close the logfile by each write operation
    1 - open the logfile if C<new()> called and try to reopen the
        file if C<reopen> is set to 1 and the inode of the file has changed (default)

=item B<reopen>

This option works only if option C<fileopen> is set to 1.

    0 - deactivated
    1 - try to reopen the log file if the inode changed (default)

=item How to use B<fileopen> and B<reopen>

Please note that it's better to set C<reopen> and C<fileopen> to 0 on Windows
because Windows unfortunately haven't the faintest idea of inodes.

To write your code independent you should control it:

    my $os_is_win = $^O =~ /win/i ? 0 : 1;

    my $log = Log::Handler::Output::File->new(
       filename => "file.log",
       mode     => "append",
       fileopen => $os_is_win
    );

If you set C<fileopen> to 0 then it implies that C<reopen> has no importance.

=item B<mode>

There are three possible modes to open a log file.

    append - O_WRONLY | O_APPEND | O_CREAT (default)
    excl   - O_WRONLY | O_EXCL   | O_CREAT
    trunc  - O_WRONLY | O_TRUNC  | O_CREAT

C<append> would open the log file in any case and appends the messages at
the end of the log file.

C<excl> would fail by open the log file if the log file already exists.

C<trunc> would truncate the complete log file if it exists. Please take care
to use this option.

Take a look to the documentation of C<sysopen()> to get more information.

=item B<autoflush>

    0 - autoflush off
    1 - autoflush on (default)

=item B<permissions>

The option C<permissions> sets the permission of the file if it creates and
must be set as a octal value. The permission need to be in octal and are
modified by your process's current "umask".

That means that you have to use the unix style permissions such as C<chmod>.
C<0640> is the default permission for this option. That means that the owner
got read and write permissions and users in the same group got only read
permissions. All other users got no access.

Take a look to the documentation of C<sysopen()> to get more information.

=item B<utf8>, B<utf-8>

    utf8   =  binmode, $fh, ":utf8";
    utf-8  =  binmode, $fh, "encoding(utf-8)"; 

Yes, there is a difference.

L<http://perldoc.perl.org/perldiag.html#Malformed-UTF-8-character-(%25s)>

L<http://perldoc.perl.org/Encode.html#UTF-8-vs.-utf8-vs.-UTF8>

=item B<dateext>

It's possible to set a pattern in the filename that is replaced with a date.
If the date - and the filename - changed the file is closed and reopened with
the new filename. The filename is converted with C<POSIX::strftime>.

Example:

    my $log = Log::Handler::Output::File->new(
        filename  => "file-%Y-%m-%d.log",
        dateext => 1
    );

In this example the file C<file-2015-06-12.log> is created. At the next day the filename
changed, the log file C<file-2015-06-12.log> is closed and C<file-2015-06-13.log> is opened.

This feature is a small improvement for systems where no logrotate is available like Windows
systems. On this way you have the chance to delete old log files without to stop/start a
daemon.

=back

=head2 log()

Call C<log()> if you want to log messages to the log file.

Example:

    $log->log(message => "this message goes to the logfile");

=head2 flush()

Call C<flush()> if you want to re-open the log file.

This is useful if you don't want to use option S<"reopen">. As example
if a rotate mechanism moves the logfile and you want to re-open a new
one.

=head2 validate()

Validate a configuration.

=head2 reload()

Reload with a new configuration.

=head2 errstr()

Call C<errstr()> to get the last error message.

=head2 close()

Call C<close()> to close the log file yourself - normally you don't need
to use it, because the log file will be opened and closed automatically.

=head1 PREREQUISITES

    Carp
    Fcntl
    File::Spec
    Params::Validate

=head1 EXPORTS

No exports.

=head1 REPORT BUGS

Please report all bugs to <jschulz.cpan(at)bloonix.de>.

If you send me a mail then add Log::Handler into the subject.

=head1 AUTHOR

Jonny Schulz <jschulz.cpan(at)bloonix.de>.

=head1 COPYRIGHT

Copyright (C) 2007-2009 by Jonny Schulz. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

package Log::Handler::Output::File;

use strict;
use warnings;
use Carp;
use Fcntl qw( :flock O_WRONLY O_APPEND O_TRUNC O_EXCL O_CREAT );
use File::Spec;
use Params::Validate qw();
use POSIX;

our $VERSION = "0.08";
our $ERRSTR  = "";

sub new {
    my $class = shift;
    my $opts = $class->_validate(@_);
    my $self = bless $opts, $class;

    # open the log file permanent
    if ($self->{dateext}) {
        $self->_check_dateext
            or return undef;
    } elsif ($self->{fileopen}) {
        $self->_open
            or croak $self->errstr;
    }

    return $self;
}

sub log {
    my $self = shift;
    my $message = @_ > 1 ? {@_} : shift;

    if ($self->{dateext}) {
        $self->_check_dateext or return undef;
    }

    if (!$self->{fileopen}) {
        $self->_open or return undef;
    } elsif ($self->{reopen}) {
        $self->_checkino or return undef;
    }

    if ($self->{filelock}) {
        flock($self->{fh}, LOCK_EX)
            or return $self->_raise_error("unable to lock logfile $self->{filename}: $!");
    }

    print {$self->{fh}} $message->{message} or
        return $self->_raise_error("unable to print to logfile: $!");

    if ($self->{filelock}) {
        flock($self->{fh}, LOCK_UN)
            or return $self->_raise_error("unable to unlock logfile $self->{filename}: $!");
    }

    if (!$self->{fileopen}) {
        $self->close or return undef;
    }

    return 1;
}

sub flush {
    my $self = shift;

    if ($self->{fileopen}) {
        $self->close or return undef;
        $self->_open  or return undef;
    }

    return 1;
}

sub close {
    my $self = shift;

    if ($self->{fh}) {
        CORE::close($self->{fh})
            or return $self->_raise_error("unable to close logfile $self->{filename}: $!");
        delete $self->{fh};
    }

    return 1;
}

sub validate {
    my $self = shift;
    my $opts = ();

    eval { $opts = $self->_validate(@_) };

    if ($@) {
        return $self->_raise_error($@);
    }

    return $opts;
}

sub reload {
    my $self = shift;
    my $opts = $self->validate(@_);

    $self->close;

    foreach my $key (keys %$opts) {
        $self->{$key} = $opts->{$key};
    }

    if ($self->{fileopen}) {
        $self->_open
            or croak $self->errstr;
    }

    return 1;
}

sub errstr {
    return $ERRSTR;
}

sub DESTROY {
    my $self = shift;

    if ($self->{fh}) {
        CORE::close($self->{fh});
    }
}

#
# private stuff
#

sub _open {
    my $self = shift;

    sysopen(my $fh, $self->{filename}, $self->{mode}, $self->{permissions})
        or return $self->_raise_error("unable to open logfile $self->{filename}: $!");

    if ($self->{autoflush}) {
        my $oldfh = select $fh;
        $| = $self->{autoflush};
        select $oldfh;
    }

    if ($self->{utf8}) {
        binmode $fh, ":utf8";
    } elsif ($self->{"utf-8"}) {
        binmode $fh, "encoding(utf-8)";
    }

    if ($self->{reopen}) {
        $self->{inode} = (stat($self->{filename}))[1];
    }

    $self->{fh} = $fh;
    return 1;
}

sub _check_dateext {
    my $self = shift;

    my $filename = POSIX::strftime($self->{filename_pattern}, localtime);

    if ($self->{filename} ne $filename) {
        $self->{filename} = $filename;
        if ($self->{fileopen}) {
            $self->close or return undef;
            $self->_open or return undef;
        }
    }

    return 1;
}

sub _checkino {
    my $self = shift;

    if (!-e $self->{filename} || $self->{inode} != (stat($self->{filename}))[1]) {
        $self->close or return undef;
        $self->_open or return undef;
    }

    return 1;
}

sub _validate {
    my $class   = shift;
    my $bool_rx = qr/^[10]\z/;

    my %opts = Params::Validate::validate(@_, {
        filename => {
            type => Params::Validate::SCALAR | Params::Validate::ARRAYREF,
        },
        filelock => {
            type => Params::Validate::SCALAR,
            regex => $bool_rx,
            default => 1,
        },
        fileopen => {
            type => Params::Validate::SCALAR,
            regex => $bool_rx,
            default => 1,
        },
        reopen => {
            type  => Params::Validate::SCALAR,
            regex => $bool_rx,
            default => 1,
        },
        mode => {
            type => Params::Validate::SCALAR,
            regex => qr/^(append|excl|trunc)\z/,
            default => "append",
        },
        autoflush => {
            type => Params::Validate::SCALAR,
            regex => $bool_rx,
            default => 1,
        },
        permissions => {
            type => Params::Validate::SCALAR,
            regex => qr/^[0-7]{3,4}\z/,
            default => "0640",
        },
        utf8 => {
            type => Params::Validate::SCALAR,
            regex => $bool_rx,
            default => 0,
        },
        "utf-8" => {
            type => Params::Validate::SCALAR,
            regex => $bool_rx,
            default => 0,
        },
        dateext => {
            type => Params::Validate::SCALAR,
            optional => 1
        }
    });

    if (ref($opts{filename}) eq "ARRAY") {
        $opts{filename} = File::Spec->catfile(@{$opts{filename}});
    }

    if ($opts{mode} eq "append") {
        $opts{mode} = O_WRONLY | O_APPEND | O_CREAT;
    } elsif ($opts{mode} eq "excl") {
        $opts{mode} = O_WRONLY | O_EXCL | O_CREAT;
    } elsif ($opts{mode} eq "trunc") {
        $opts{mode} = O_WRONLY | O_TRUNC | O_CREAT;
    }

    $opts{permissions} = oct($opts{permissions});
    $opts{filename_pattern} = $opts{filename};

    return \%opts;
}

sub _raise_error {
    $ERRSTR = $_[1];
    return undef;
}

1;
