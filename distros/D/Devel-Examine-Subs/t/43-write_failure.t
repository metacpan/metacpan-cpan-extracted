#!perl 
use warnings;
use strict;

use Test::More;
use Data::Dumper;


if ($^O eq 'MSWin32'){
    plan skip_all => "Non-Windows tests, skipping"
}
else {

    plan tests => 2;

    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";

    my $file = 't/sample.data';

    my $des = Devel::Examine::Subs->new(file => $file, copy => '/root/no_write.data');

    eval {
        $des->search_replace(exec => sub {
            $_[0] =~ s/this/that/;
        });
    };

    like ($@, qr/_write_file/i, "croak if file can't be written to")
}

