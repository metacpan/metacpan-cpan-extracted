use strict;
use Test::More qw/no_plan/;
use Test::Exception;

BEGIN {
    use_ok 'IOC::Slinky::Container';
    use_ok 'YAML';
}

my $c;

dies_ok { $c = IOC::Slinky::Container->new( config => undef ); } 'invalid';
dies_ok { $c = IOC::Slinky::Container->new( config => '' ); } 'invalid';
dies_ok { $c = IOC::Slinky::Container->new( config => [ ] ); } 'invalid';
dies_ok { $c = IOC::Slinky::Container->new( config => { } ); } 'invalid';

lives_ok {
    $c = IOC::Slinky::Container->new( config => { container => { } } );
} 'empty';

ok 1;

__END__
