package Eidolon::Driver::Log::Basic;
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   Eidolon/Driver/Log/Basic.pm - basic log driver
#   
# ==============================================================================

use base qw/Eidolon::Driver::Log/;
use POSIX "strftime";
use Fcntl ":flock";
use warnings;
use strict;

our $VERSION = "0.01"; # 2008-09-26 23:21:32

# ------------------------------------------------------------------------------
# \% new($logs_dir, $file)
# constructor
# ------------------------------------------------------------------------------
sub new
{
    my ($class, $dir, $file, $self);

    ($class, $dir, $file) = @_;

    $self = $class->SUPER::new;

    # class attributes
    $self->{"dir"}    = $dir;
    $self->{"file"}   = $file || "system.log";
    $self->{"handle"} = undef;

    # check if log directory exists
    throw DriverError::Log::Directory($self->{"dir"}) if (!-d $self->{"dir"});

    return $self;
}

# ------------------------------------------------------------------------------
# open()
# open log
# ------------------------------------------------------------------------------
sub open
{
    my $self = shift;

    $self->close if ($self->{"handle"}); 

    open $self->{"handle"}, ">>$self->{'dir'}$self->{'file'}" or 
        throw DriverError::Log::Open($self->{"dir"}.$self->{"file"});

    flock $self->{"handle"}, LOCK_EX;
}

# ------------------------------------------------------------------------------
# close()
# close log
# ------------------------------------------------------------------------------
sub close
{
    my $self = shift;

    if ($self->{"handle"}) 
    {
        flock $self->{"handle"}, LOCK_UN;
        close $self->{"handle"};
    }
}

# ------------------------------------------------------------------------------
# _write($level, $msg)
# write log
# ------------------------------------------------------------------------------
sub _write
{
    my ($self, $level, $msg, $r, $fh);

    ($self, $level, $msg) = @_;
    $r = Eidolon::Core::Registry->get_instance;

    $self->open;
    $fh = $self->{"handle"};

    printf $fh
    (
        "[ %s ]\t%s\t%s\t%s\n", 
        strftime("%Y-%m-%d %H:%M:%S", localtime), 
        $r->cgi->get_query || "/", 
        $level,
        $msg ? $msg : "-"
    );

    $self->close;
}

# ------------------------------------------------------------------------------
# notice($msg)
# notice
# ------------------------------------------------------------------------------
sub notice
{
    my ($self, $msg) = @_;

    $self->_write("notice", $msg);
}

# ------------------------------------------------------------------------------
# warning($msg)
# warning
# ------------------------------------------------------------------------------
sub warning
{
    my ($self, $msg) = @_;

    $self->_write("warning", $msg);
}

# ------------------------------------------------------------------------------
# error($msg)
# error
# ------------------------------------------------------------------------------
sub error
{
    my ($self, $msg) = @_;

    $self->_write("error", $msg);
}

1;

__END__

=head1 NAME

Eidolon::Driver::Log::Basic - basic log driver for Eidolon.

=head1 SYNOPSIS

Somewhere in application controller:

    my ($r, $log);

    $r   = Eidolon::Core::Registry->get_instance;
    $log = $r->loader->get_object("Eidolon::Driver::Log::Basic");

    $log->notice("Something happened");
    $log->warning("Something not so good happened");
    $log->error("Something bad happened");

=head1 DESCRIPTION

The I<Eidolon::Driver::Log::Basic> is a simple log driver for I<Eidolon>.
It provides simple file logging, storing time (in I<Y-m-d H:M:S> format), user
request string, log level (I<notice>, I<warning> or I<error>) and log message 
for each entry.

=head1 METHODS

=head2 new($logs_dir, $file)

Class constructor. C<$logs_dir> - a directory, where log file C<$file> will be
saved. 

=head2 open()

Implementation of abstract method from 
L<Eidolon::Driver::Log/open()>.

=head2 close()

Inherited from
L<Eidolon::Driver::Log/close()>.

=head2 notice($msg)

Implementation of abstract method from
L<Eidolon::Driver::Log/notice($msg)>.

=head2 warning($msg)

Implementation of abstract method from
L<Eidolon::Driver::Log/warning($msg)>.

=head2 error($msg)

Implementation of abstract method from
L<Eidolon::Driver::Log/error($msg)>.

=head1 SEE ALSO

L<Eidolon>, L<Eidolon::Driver::Log>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Anton Belousov, E<lt>abel@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2009, Atma 7, L<http://www.atma7.com>

=cut
