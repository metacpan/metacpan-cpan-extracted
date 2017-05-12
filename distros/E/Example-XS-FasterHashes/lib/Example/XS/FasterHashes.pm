package Example::XS::FasterHashes;

use strict;
use warnings;
require DynaLoader;

our @ISA = qw( DynaLoader );

our @HashKeys;

our $VERSION = '0.01';

{   #block to force lexical destruction, see makefile.pl
    my $hvkeysinit; #'/' not portable I think
    my $dir = substr($INC{'Example/XS/FasterHashes.pm'},0,
                     rindex($INC{'Example/XS/FasterHashes.pm'}, '/'));
    $dir .= '/FasterHashes/hvkeysinit.bin';
    open(my $hvkeysinitfh, '<', $dir)  or die "Could not open $dir: $!";
    binmode($hvkeysinitfh);
    sysread($hvkeysinitfh, $hvkeysinit, -s $dir);
    close($hvkeysinitfh);
    
    #when the XS Boot func takes parameters, you have to explictly add $VERSION
    #or XSPP's VERSION check will fail, dynaloader silently adds $VERSION as
    #the first parameter if there are zero parameters to bootstrap
    bootstrap Example::XS::FasterHashes($VERSION, $hvkeysinit);
}

#do not change this hash of hashes
sub new {
     my $href = {
          'layer1' => {
               'layer2' => {
                    'layer3' => {
                         'jiugsdh1' => 999,
                         'iusidfsd2' => 999,
                         'ihfsdgsfg3' => 999,
                         'sudfyf4' => 999,
                         'sfyuihldfss5' => 999,
                         'iuodafohsd6' => 999,
                         'kjsdjdfsj7' => 999
                    }
               }
          }
     };
     bless $href ;
     return $href ;
}

1;
__END__

=head1 NAME

Example::XS::FasterHashes - A tutorial with working examples for faster hashes in XS

=head1 SYNOPSIS

    use Example::XS::FasterHashes;
    use Time::HiRes qw( time );
    $o = new Example::XS::FasterHashes;
    
    $time = time;
    for(0..3000000){
         for (int(rand 6)+1) {$o->get($_);}
    }
    print "time was ".(time-$time)."\n";
    
    $time = time;
    for(0..3000000){
         for (int(rand 6)+1) {$o->getKC($_);}
    }
    print "time was ".(time-$time)."\n";

=head1 DESCRIPTION

This is a tutorial and a working example of precalculating key hash numbers
and interacting with Perl's shared string table from XS. It is not a library your
XS module can directly use. The intention is for you to copy paste the code or
concepts in this module into your XS module. The code in this XS lib
takes advantage of 2 parts of Perl's hash system. Perl compares the key's
char * to the char * in the HEK, if they match, it will not perform an
additional memcmp, see L<http://perl5.git.perl.org/perl.git/blob/7bef440cec6de046112398f991b1dd7d23689e23:/hv.c#l641>.
This module takes advantage of that, by passing to hv_fetch/etc the same char *
that will be found in the HEK struct. The 2nd optimization is precalculating
the hash number, which skips the hash calculating macro here,
L<http://perl5.git.perl.org/perl.git/blob/7bef440cec6de046112398f991b1dd7d23689e23:/hv.c#l614>.

There is a limitation though, ithreads. If a fork/clone/new thread happens,
the char * in the HEK in the new thread will be different from the char *
stored as a static in the DLL in the hv key cache, so the memcmp can not be
skipped. The shared string table is per interp, not per process. The hash number
being precalculated optimization is still done. A solution to the ithreads
problem is Perl's TLS system, see L<perlxs/Safely-Storing-Static-Data-in-XS>
but that isn't implemented in this example. I don't know the
performance impact of using Perl TLS since it adds 1 additional indirection
to obtaining the key's char * and hash number and probably negativly affects the
processor's prefetch ability. With the current non-ithreads design, in x86
the location of the char * is a machine code read only litteral
offset to the current instruction pointer since the key's char * is stored
in read/write static space in the DLL.

Read the source code for more the rest of the story. I suggest you delete this
module from your hard disk after you installed it and benchmarked it, or don't
even install it in the first place. It is not an API that you can directly use.

=head2 FUNCTIONS AND METHODS

=head3 new

    $obj = new Example::XS::FasterHashes;

Creates a new Example::XS::FasterHashes object.

=head3 get

    $obj->get(4);

The traditional way of going through hashes of hashes in XS. Returns nothing.
Takes 1 parameter, which is a random number from 1 through 7. This parameter
prevents attempts at CPU caching.

=head3 getKC

    $obj->getKC(2);

The fast way of going through hashes of hashes in XS. Returns nothing.
Takes 1 parameter, which is a random number from 1 through 7. This parameter
prevents attempts at CPU caching. Benchmark this against L</get>, it will be
faster. For me, using F<Example-XS-FasterHashes.t>, the block of code which
is using getKC is 15% faster than using L</get>(). I never have measured the
actual hv_fetches alone. The rand() might be 50% of the runtime,
I really don't know. KC stands for Key Cache.

=head1 SUPPORT

Bug fixes or performance ideas for this module should be submitted to the
CPAN RT queue. Read the comments in the source code. Understand throughly
whats being done before you integrate the code into your XS module.
Use a DEBUGGING perl build and a C debugger with symbols. If you supply
the wrong hash number, I don't know what will happen.

=head1 AUTHOR

Daniel Dragan aka bulk88 email = bulkdd _at_ cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Daniel Dragan

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, at your option, any later version of
Perl 5 you may have available.


=cut
