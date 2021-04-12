###########################################################################
#
# Rotate.pm
#
# Copyright (c) 2000 Raphael Manfredi.
# Copyright (c) 2002-2015 Mark Rogaski, mrogaski@cpan.org;
# all rights reserved.
#
# See the README file included with the
# distribution for license information.
#
###########################################################################

use strict;

###########################################################################
package Log::Agent::Rotate;

use Getargs::Long qw(ignorecase);

#
# File rotating policy
#

our $VERSION = "1.201";
$VERSION = eval $VERSION;

use constant {
    BACKLOG     => 0,
    UNZIPPED    => 1,
    MAX_SIZE    => 2,
    MAX_WRITE   => 3,
    MAX_TIME    => 4,
    IS_ALONE    => 5,
    SINGLE_HOST => 6,
    FILE_PERM   => 7,
};

#
# ->make
#
# Creation routine.
#
# Attributes:
#   backlog       amount of old files to keep (0 for none)
#   unzipped      amount of old files to NOT compress (defaults to 1)
#   max_size      maximum amount of bytes in file
#   max_write     maximum amount of bytes to write in file
#   max_time      maximum amount of time to keep open
#   is_alone      hint: only one instance is busy manipulating the logfiles
#   single_host   hint: access to logfiles always made via one host
#
sub make {
    my $self = bless [], shift;

    (
        $self->[BACKLOG],
        $self->[UNZIPPED],
        $self->[MAX_SIZE],
        $self->[MAX_WRITE],
        $self->[MAX_TIME],
        $self->[IS_ALONE],
        $self->[SINGLE_HOST],
        $self->[FILE_PERM]
    ) = xgetargs(@_,
        -backlog        => ['i', 7],
        -unzipped       => ['i', 1],
        -max_size       => ['i', 1_048_576],
        -max_write      => ['i', 0],
        -max_time       => ['s', "0"],
        -is_alone       => ['i', 0],
        -single_host    => ['i', 0],
        -file_perm      => ['i', 0666]
    );

    $self->[MAX_TIME] = seconds_in_period($self->[MAX_TIME])
            if $self->[MAX_TIME];

    return $self;
}

#
# seconds_in_period
#
# Converts a period into a number of seconds.
#
sub seconds_in_period {
    my ($p) = @_;

    $p =~ s|^(\d+)||;
    my $base = int($1); # Number of elementary periods
    my $u = "s";        # Default Unit
    $u = substr($1, 0, 1) if $p =~ /^\s*(\w+)$/;
    my $sec;

    if ($u eq 'm') {
        $sec = 60;              # One minute = 60 seconds
    } elsif ($u eq 'h') {
        $sec = 3600;            # One hour = 3600 seconds
    } elsif ($u eq 'd') {
        $sec = 86400;           # One day = 24 hours
    } elsif ($u eq 'w') {
        $sec = 604800;          # One week = 7 days
    } elsif ($u eq 'M') {
        $sec = 2592000;         # One month = 30 days
    } elsif ($u eq 'y') {
        $sec = 31536000;        # One year = 365 days
    } else {
        $sec = 1;               # Unrecognized: defaults to seconds
    }

    return $base * $sec;
}

#
# Attribute access
#

sub backlog     { $_[0]->[BACKLOG] }
sub unzipped    { $_[0]->[UNZIPPED] }
sub max_size    { $_[0]->[MAX_SIZE] }
sub max_write   { $_[0]->[MAX_WRITE] }
sub max_time    { $_[0]->[MAX_TIME] }
sub is_alone    { $_[0]->[IS_ALONE] }
sub single_host { $_[0]->[SINGLE_HOST] }
sub file_perm   { $_[0]->[FILE_PERM] }

#
# There's no set_xxx() routines: those objects are passed by reference and
# never "expanded", i.e. passed by copy.  Modifying any of the attributes
# would then lead to strange effects.
#

#
# ->is_same
#
# Compare settings of $self with that of $other
#
sub is_same {
    my $self = shift;
    my ($other) = @_;
    for (my $i = 0; $i < @$self; $i++) {
        return 0 if $self->[$i] != $other->[$i];
    }
    return 1;
}

1;        # for require
__END__

=head1 NAME

Log::Agent::Rotate - parameters for logfile rotation

=head1 SYNOPSIS

 require Log::Agent::Rotate;

 my $policy = Log::Agent::Rotate->make(
     -backlog     => 7,
     -unzipped    => 2,
     -is_alone    => 0,
     -max_size    => 100_000,
     -max_time    => "1w",
     -file_perm   => 0666
 );

=head1 DESCRIPTION

The C<Log::Agent::Rotate> class holds the parameters describing the logfile
rotation policy, and is meant to be supplied to instances of
C<Log::Agent::Driver::File> via arguments in the creation routine,
such as C<-rotate>, or by using array references as values in the
C<-channels> hashref: See complementary information in
L<Log::Agent::Driver::File>.

As rotation cycles are performed, the current logfile is renamed, and
possibly compressed, until the maximum backlog is reached, at which time
files are deleted.  Assuming a backlog of 5 and that the latest 2 files
are not compressed, the following files can be present on the filesystem:

    logfile           # the current logfile
    logfile.0         # most recently renamed logfile
    logfile.1
    logfile.2.gz
    logfile.3.gz
    logfile.4.gz      # oldest logfile, unlinked next cycle

The following I<switches> are available to the creation routine make(),
listed in alphabetical order, all taking a single integer value as argument:

=over 4

=item I<backlog>

The total amount of old logfiles to keep, besides the current logfile.

Defaults to 7.

=item I<file_perm>

The file permissions, given as an octal integer value, to supply to
sysopen() during file creation.  This value is modified during execution
by the umask of the process.  In most cases, it is good practice to leave
this set to the default and let the user process controll the file
permissions.

This option has no effect on Win32 systems.

Defaults to 0666.

=item I<is_alone>

The argument is a boolean stating whether the program writing to the logfile
will be the only one or not.  This is a hint that drives some optimizations,
but it is up to the program to B<guarantee> that noone else will be able to
write to or unlink the current logfile when set to I<true>.

Defaults to I<false>.

=item I<max_size>

The maximum logfile size.  This is a threshold, which will cause
a logfile rotation cycle to be performed, when crossed after a write to
the file.  If set to C<0>, this threshold is not checked.

Defaults to 1 megabyte.

=item I<max_time>

The maximum time in seconds between the moment we opened the file and
the next rotation cycle occurs.  This threshold is only checked after
a write to the file.

The value can also be given as a string, postfixed by one of the
following letters to specify the period unit (e.g. "3w"):

    Letter   Unit
    ------   -------
       m     minutes
       h     hours
       d     days
       d     days
       w     weeks
       M     months (30 days of 24 hours)
       y     years

Defaults to C<0>, meaning it is not checked.

=item I<max_write>

The maximum amount of data we can write to the logfile.  Like C<max_size>,
this is a threshold, which is only checked after a write to the logfile.
This is not the total logfile size: if several programs write to the same
logfile and C<max_size> is not used, then the logfiles may never be rotated
at all if none of the programs write at least C<max_write> bytes to the
logfile before exiting.

Defaults to C<0>, meaning it is not checked.

=item I<single_host>

The argument is a boolean stating whether the access to the logfiles
will be made from one single host or not.  This is a hint that drives some
optimizations, but it is up to the program to B<guarantee> that it is
accurately set.

Defaults to I<false>, which is always a safe value.

=item I<unzipped>

The amount of old logfiles, amongst the most recent ones, that should
not be compressed but be kept as plain files.

Defaults to 1.

=back

To test whether two configurations are strictly identical, use is_same(),
as in:

    print "identical\n" if $x->is_same($y);

where both $x and $y are C<Log::Agent::Rotate> objects.

All the aforementioned switches also have a corresponding querying
routine that can be issued on instances of the class to get their value.
It is not possible to modify those attributes.

For instance:

    my $x = Log::Agent::Rotate->make(...);
    my $mwrite = $x->max_write();

would get the configured I<max_write> threshold.

=head1 AUTHORS

Originally written by Raphael Manfredi (Raphael_Manfredi@pobox.com),
currently maintained by Mark Rogaski (mrogaski@cpan.org).

Thanks to Chris Meshkin for his suggestions on file permissions.

=head1 COPYRIGHT

Copyright (c) 2000, Raphael Manfredi.

Copyright (c) 2002-2015, Mark Rogaski; all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0, a copy of which can
be found with perl.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
Artistic License 2.0 for more details.

http://www.perlfoundation.org/artistic_license_2_0

=head1 SEE ALSO

Log::Agent(3), Log::Agent::Driver::File(3),
Log::Agent::Rotate::File(3).

=cut
