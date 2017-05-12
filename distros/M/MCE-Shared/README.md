## MCE::Shared for Perl

This document describes MCE::Shared version 1.826.

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

 MCE::Flow::init(
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

To install this module type the following:

    perl Makefile.PL

    make
    make test
    make install

This module requires Perl 5.10.1 or later to run.

MCE::Shared utilizes the following modules:

    bytes
    constant
    overload
    Carp
    IO::FDPass  1.2+ (optional, recommended on UNIX and Windows)
    MCE::Mutex  1.829+
    MCE::Util   1.829+
    MCE::Signal 1.829+
    Scalar::Util
    Sereal::Decoder 3.015+ (optional)
    Sereal::Encoder 3.015+ (optional)
    Socket
    Storable 2.04+ (default when Sereal 3.015+ isn't available)
    Symbol
    Test::More 0.45+ (for make test only)
    Time::HiRes

The IO::FDPass module applies to MCE::Shared::{ Condvar, Handle, and Queue }.

### Further Reading

The MCE::Shared module is described at https://metacpan.org/pod/MCE::Shared.

The MCE::Hobo module is described at https://metacpan.org/pod/MCE::Hobo.

See [MCE::Examples](https://metacpan.org/pod/MCE::Examples)
and [MCE Cookbook](https://github.com/marioroy/mce-cookbook) for recipes.

### Copyright and Licensing

Copyright (C) 2016-2017 by Mario E. Roy <marioeroy AT gmail DOT com>

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
http://www.gnu.org/copyleft/gpl.html.

