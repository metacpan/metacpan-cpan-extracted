# -*- cperl -*-
#$Id: 99_pod.t,v 1.1.1.1 2003/09/10 18:29:36 cwest Exp $

=pod

Testing that the POD in all the Perl code is formatted correctly.

=cut

use Test::More;
use File::Spec;
use File::Find;
use strict;

eval "use Test::Pod 0.95";

if ($@) {
    plan skip_all => "Test::Pod v0.95 required for testing POD";
} else {
    Test::Pod->import;
    my @files;
    my $blib = File::Spec->catfile(qw(blib lib));
    find(
         sub {
             push @files, $File::Find::name if /\.(?:p(?:l|m|od)|t)$/;
         },
         $blib,
         ( -e 't' && -d _ ? 't' : () )
        );
    plan tests => scalar @files;
    foreach my $file (@files) {
        pod_file_ok($file);
    }
}
