package Linux::Taskstats::Read;

use 5.008001;
use strict;
use warnings;
use Fcntl qw(O_RDONLY);

our $VERSION = '6.01';

## these are object members (and need to be cleaned up in DESTROY())
my %Fh  = ();
my %Ver = ();

my %Size   = ( 3 => 268,
               4 => 276,
               6 => 316, );

my %Tmpl   = ();
$Tmpl{3} = 'S xx L C C xxxxxx QQQQQQQQ a32 C C xx xxxx LLLLL xxxx QQQQQQQQQQQQQQQQ';
$Tmpl{4} = $Tmpl{3};
$Tmpl{6} = $Tmpl{3} . 'QQQQQ';

my %Fields = ();

$Fields{3} = [ qw(version     ac_exitcode
                  ac_flag     ac_nice

                  cpu_count            cpu_delay_total
                  blkio_count          blkio_delay_total
                  swapin_count         swapin_delay_total
                  cpu_run_real_total   cpu_run_virtual_total

                  ac_comm

                  ac_sched
                  ac_pad

                  ac_uid       ac_gid
                  ac_pid       ac_ppid
                  ac_btime

                  ac_etime      ac_utime     ac_stime
                  ac_minflt     ac_majflt

                  coremem       virtmem      hiwater_rss     hiwater_vm
                  read_char     write_char   read_syscalls   write_syscalls
                  read_bytes    write_bytes  cancelled_write_bytes) ];
$Fields{4} = $Fields{3};
@{$Fields{6}} = (@{$Fields{3}}, qw(nvcsw nivcsw
                                   ac_utimescaled ac_stimescaled
                                   cpu_scaled_run_real_total));

sub new {
    my $class = shift;
    my %args = @_;
    my $self = bless \(my $fake), $class;  ## an inside-out module

    $Ver{$self} = ($args{'-ver'} || $args{'-version'})
      or die "'-version' parameter required\n";

    $self->open($args{'-file'}) if $args{'-file'};

    return $self;
}

sub open {
    my $self = shift;
    my $file = shift;

    unless( -f $file && -r _ ) {
        die "File '$file' is not a file or is not readable.\n";
    }

    sysopen($Fh{$self}, $file, O_RDONLY)
      or die "Could not open file '$file': $!\n";

    return 1;
}

sub read {
    my $self = shift;

    sysread($Fh{$self}, my $rec, $Size{$Ver{$self}}, 0)
      or return;

    my %rec = ();
    @rec{@{$Fields{$Ver{$self}}}} = unpack($Tmpl{$Ver{$self}}, $rec);

    ## some cleaning
    $rec{ac_comm} =~ s/\0//g;

    return \%rec;
}

sub read_raw {
    my $self = shift;

    sysread($Fh{$self}, my $rec, $Size{$Ver{$self}}, 0)
      or return;

    return $rec;
}

sub close {
    CORE::close($Fh{$_[0]}) if $Fh{$_[0]};
    delete $Fh{$_[0]};
}

sub version {
    return $Ver{$_[0]};
}

sub size {
    return $Size{$Ver{$_[0]}};
}

sub fields {
    return @{ $Fields{$Ver{$_[0]}} };
}

sub template {
    return $Tmpl{$Ver{$_[0]}};
}

sub DESTROY {
    my $self = $_[0];

    ## delete any members here
    delete $Fh{$self};
    delete $Ver{$self};

    my $super = $self->can("SUPER::DESTROY");
    goto &$super if $super;
}

1;
__END__

=head1 NAME

Linux::Taskstats::Read - Read Linux taskstats structures

=head1 SYNOPSIS

  use Linux::Taskstats::Read;

  my $ts = new Linux::Taskstats::Read( -file => '/some/taskstats.log' -ver => 3 );
  while( my $rec = $ts->read ) {
    printf("Comm: %s (uid: %d)\n", $rec->{ac_comm}, $rec->{ac_uid});
  }
  $ts->close;

=head1 DESCRIPTION

The Linux 2.6.19 kernel introduced real-time task and process
statistical accounting routines. These stats are requested and
gathered via a netlink interface. This module does not interface with
netlink, but it can read a raw binary dump of a taskstats struct
(either from memory or from disk).

=head2 new()

Creates a new taskstats record reader object. Parameters:

=over 4

=item B<-file>

Specifies a file to open. This file should be a binary dump of
taskstats objects (e.g. such as produced by F<getdelays>).

=item B<-ver>

Specifies the taskstats struct version. This is a required
parameter. Try '3' if you don't know what version to use. Otherwise,
look near the top of F<linux/taskstats.h> to see your kernel's current
version.

=back

=head2 read()

Reads a taskstats record from the file specified in either the
constructor (B<new()>) or B<open()>.

  my $rec = $ts->read;

=head2 read_raw()

Returns a raw (packed) taststats structure.

=head2 close()

When you're done reading what you need from the taststats dump, kindly
close the file.

Example:

  $ts->close();

=head2 open()

If you don't know the filename at the time of object construction, or
you've closed the object's filehandle (via B<close()>), you can
(re-)open a new file with this method.

Example:

  $ts->open('/path/to/some/file.log');

=head2 fields()

Returns a list containing all of the fields of the taskstats structure
in the order they appear in F<taskstats.h>.

Example:

  my @fields = $ts->fields;

=head2 size()

Returns the record size in bytes for the current taskstats version.

Example:

  my $size = $ts->size;

=head2 template()

Returns the template for unpack() for this taskstats version.

Example:

  my $rec = $ts->read_raw;
  @data = unpack($ts->template, $rec);

=head2 version()

Returns the taskstats version this object is currently set to parse.

Example:

  print $ts->version . "\n";

=head1 TASKSTATS STRUCT

A taskstats struct, as returned by B<read()> has the following fields
you can examine (this is the version 3 format):

  version
  ac_exitcode
  ac_flag
  ac_nice
  cpu_count
  cpu_delay_total
  blkio_count
  blkio_delay_total
  swapin_count
  swapin_delay_total
  cpu_run_real_total
  cpu_run_virtual_total
  ac_comm
  ac_sched
  ac_pad
  ac_uid
  ac_gid
  ac_pid
  ac_ppid
  ac_btime
  ac_etime
  ac_utime
  ac_stime
  ac_minflt
  ac_majflt
  coremem
  virtmem
  hiwater_rss
  hiwater_vm
  read_char
  write_char
  read_syscalls
  write_syscalls
  read_bytes
  write_bytes
  cancelled_write_bytes

More information on what is stored in these fields may be found in the
documentation supplied by your kernel. These fields are subject to
change depending on the taskstats version used. They are supplied here
only as a courtesy and reference. Future versions may or may not be
included in subsequent releases of this module.

=head1 TROUBLESHOOTING

Q. I have no idea what this modules is for! What is it for?

A. B<Linux::Taskstats::Read> can read taskstats dumps. If you don't
know what taskstats is, you probably don't need this module (but you
can find out more by reading the 'SEE ALSO' references below).

Q. I get "Invalid type 'Q' in unpack at .../Linnux/Taskstats/Read.pm"
errors.

A. You're not on a 64-bit box (or your kernel has not been built with
64-bit support). This module has to be used on a box that can build
and run taskstats (but may not necessarily be running it at the
moment).

Q. How can I make taskstats dumps that this module can read?

A. See the F<getdelays> program in the 'SEE ALSO' section below for an
example program.

Q. I can't get F<getdelays> to run on my system.

A. Try a 2.6.2x kernel or higher (apparently there were some problems
in the 19 kernel). Beyond that, check with your kernel vendor for
additional support.

=head1 NOTES

The major version of this module will match the latest version of the
taskstats struct it supports natively (e.g., 3.xx for taskstats
version 3, etc.).

=head1 SEE ALSO

The following documents in the 2.6.19 or higher Linux kernel sources
(under the F<Documentation/accounting> directory):

=over 4

=item F<taskstats.txt>

=item F<delay-accounting.txt>

=item F<taskstats-struct.txt>

=item F<taskstats.h>

=item F<getdelays.c>

=back

=head1 AUTHOR

Scott Wiersdorf, E<lt>scott@perlcode.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Bluehost, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
