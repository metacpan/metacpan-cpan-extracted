#!perl
# Kit: Test kit for Games::Dice::Tester
package MY::Kit;

use 5.006;
use strict;
use warnings;
#use Test::Exception ();
#use Test::Fatal ();
use Test::More ();
use List::AutoNumbered ();

use parent 'Exporter';
our @EXPORT = qw(num_is);

use Import::Into;

sub import {
    my $target = caller;
    my $class = shift;
    $class->export_to_level(1, $class, @_);

    $_->import::into($target) foreach
        qw(strict warnings Test::More List::AutoNumbered);
            # Test::Exception Test::Fatal

    { # Export the name of the package under test as the caller's $DUT
        no strict 'refs';
        *{ $target . '::DUT' } = eval qq(\\"List::AutoNumbered");
            # eval => constant
    }
} #import()

sub num_is {
    Test::More::cmp_ok($_[0], '==', $_[1], $_[2] || "$_[0] == $_[1]");
}

1;
