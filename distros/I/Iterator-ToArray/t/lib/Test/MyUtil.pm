package Test::MyUtil;

use strict;
use warnings;
use base qw(Exporter);

our @EXPORT = qw(mk_iterator);

sub mk_iterator {
    my $max = shift || 10;
    Test::MyIter->new($max);
}

package Test::MyIter;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $max   = shift;
    my $i     = 0;
    bless sub {
        return if $i > $max;
        $i++;
    }, $class;
}

sub next { shift->() }
1;
