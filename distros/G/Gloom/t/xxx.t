use Test::More;
use strict;

eval "use XXX 0.17 (); 1"
    or plan skip_all => 'needs XXX >= 0.17';

plan tests => 2;

package A;
use Gloom -base;

package B;
use Gloom -base;

sub doom {
    XXX my $self = shift;
}

package main;
use Gloom;

ok not(defined &XXX), 'XXX is not exported unless -base';
$Gloom::DumpModule = 'Data::Dumper';

eval {
    B->new->doom;
};

ok $@ =~ /^\$VAR1/, 'XXX works';
