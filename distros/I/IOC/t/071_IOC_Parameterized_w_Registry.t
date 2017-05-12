#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;
use Test::Exception;

BEGIN {    
    use_ok('IOC');    
    use_ok('IOC::Registry');  
    use_ok('IOC::Service::Parameterized');   
}

{
    package Localized::Object;
    
    use strict;
    use warnings;
    
    sub new {
        my ($class, $locale) = @_;
        bless \$locale => $class;
    }
    
    sub locale { ${$_[0]} }
}

my $s = IOC::Service::Parameterized->new('localized_obj' => sub {
    my ($c, %params) = @_;
    Localized::Object->new($params{locale});
});

my $c1 = IOC::Container->new('foo');
my $c2 = IOC::Container->new('bar');
my $c3 = IOC::Container->new('baz');

$c1->addSubContainer($c2);
$c2->addSubContainer($c3);

lives_ok {
    $c3->register($s)
} '... set container successfully';

my $reg = IOC::Registry->new;
$reg->registerContainer($c1);

foreach my $locale (qw/en fr_ca/) {
    my $obj = $reg->locateService('foo/bar/baz/localized_obj' => (locale => $locale));
    isa_ok($obj, 'Localized::Object');
    is($obj->locale, $locale, '... got the right locale (' . $locale . ')');
}




