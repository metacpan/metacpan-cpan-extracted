## MCE::Shared for Perl

This document describes MCE::Shared version 1.892.

### Description

This module provides data sharing capabilities for
[MCE](https://github.com/marioroy/mce-perl) supporting threads and processes.

MCE::Hobo, included with the distribution, provides threads-like parallelization
for running code asynchronously. Unlike threads, Hobo workers are spawned as
processes having unique PIDs.

### Synopsis

```perl
 use MCE::Hobo;
 use MCE::Shared;

 my $N   = shift || 4_000_000;
 my $pi  = MCE::Shared->scalar( 0.0 );

 my $seq = MCE::Shared->sequence(
    { chunk_size => 200_000, bounds_only => 1 },
    0, $N - 1
 );

 sub compute_pi {
    my ( $wid ) = @_;

    while ( my ( $beg, $end ) = $seq->next ) {
       my ( $_pi, $t ) = ( 0.0 );
       for my $i ( $beg .. $end ) {
          $t = ( $i + 0.5 ) / $N;
          $_pi += 4.0 / ( 1.0 + $t * $t );
       }
       $pi->incrby( $_pi );
    }

    return;
 }

 MCE::Hobo->create( \&compute_pi, $_ ) for ( 1 .. 8 );

 # ... do other stuff ...

 $_->join() for MCE::Hobo->list();

 printf "pi = %0.13f\n", $pi->get / $N;  # 3.1415926535898
```

The next demonstration does the same thing using a MCE Model.

```perl
 use MCE::Flow;
 use MCE::Shared;

 my $N  = shift || 4_000_000;
 my $pi = MCE::Shared->scalar( 0.0 );

 sub compute_pi {
    my ( $wid, $beg_seq, $end_seq ) = @_;
    my ( $_pi, $t ) = ( 0.0 );

    foreach my $i ( $beg_seq .. $end_seq ) {
       $t = ( $i + 0.5 ) / $N;
       $_pi += 4.0 / ( 1.0 + $t * $t );
    }

    $pi->incrby( $_pi );
 }

 # Compute bounds only, workers receive [ begin, end ] values

 MCE::Flow->init(
    chunk_size  => 200_000,
    max_workers => 8,
    bounds_only => 1
 );

 mce_flow_s sub {
    compute_pi( MCE->wid, $_->[0], $_->[1] );
 }, 0, $N - 1;

 printf "pi = %0.13f\n", $pi->get / $N;  # 3.1415926535898
```

### Installation and Dependencies

MCE::Shared enables extra functionality on systems with IO::FDPass installed.
Without it, MCE::Shared is unable to send file descriptors to the shared-manager
process. The use applies to Condvar, Queue, and Handle (mce_open). IO::FDpass
isn't used for anything else.

To install this module type the following:

    # Appends IO::FDPass to PREREQ_PM if a C compiler is available.
    perl Makefile.PL

    # Or exclude the IO::FDPass check and not append to PREREQ_PM.
    MCE_PREREQ_EXCLUDE_IO_FDPASS=1 perl Makefile.PL

    make
    make test
    make install

This module requires Perl 5.10.1 or later to run.

MCE::Shared utilizes the following modules:

    bytes
    constant
    overload
    Carp
    Errno
    IO::FDPass  1.2+ (optional, recommended on UNIX and Windows)
    IO::Handle
    MCE::Mutex  1.889+
    MCE::Util   1.889+
    MCE::Signal 1.889+
    POSIX
    Scalar::Util 1.22+
    Sereal::Decoder 3.015+ (optional)
    Sereal::Encoder 3.015+ (optional)
    Socket
    Storable    2.04+ (default when Sereal isn't available)
    Test::More  0.45+ (for make test only)
    Time::HiRes

The IO::FDPass module applies to MCE::Shared::{ Condvar, Handle, and Queue }.

### Further Reading

The MCE::Shared module is described at https://metacpan.org/pod/MCE::Shared.

The MCE::Hobo module is described at https://metacpan.org/pod/MCE::Hobo.

See also, [MCE::Examples](https://metacpan.org/pod/MCE::Examples).

### Copyright and Licensing

Copyright (C) 2016-2024 by Mario E. Roy <marioeroy AT gmail DOT com>

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself:

        a) the GNU General Public License as published by the Free
        Software Foundation; either version 1, or (at your option) any
        later version, or

        b) the "Artistic License" which comes with this Kit.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the Artistic License with this
Kit, in the file named "LICENSE".  If not, I'll be glad to provide one.

You should also have received a copy of the GNU General Public License
along with this program in the file named "Copying". If not, write to the
Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
Boston, MA 02110-1301, USA or visit their web page on the internet at
https://www.gnu.org/copyleft/gpl.html.

