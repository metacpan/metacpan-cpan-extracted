#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;
use Test::Exception;

BEGIN {    
    use_ok('IOC');
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

my $c = IOC::Container->new();

lives_ok {
    $c->register($s)
} '... set container successfully';

foreach my $locale (qw/en fr_ca/) {
    my $obj = $s->instance(locale => $locale);
    isa_ok($obj, 'Localized::Object');
    is($obj->locale, $locale, '... got the right locale (' . $locale . ')');
}

foreach my $locale (qw/en fr_ca/) {
    my $obj = $c->get('localized_obj' => (locale => $locale));
    isa_ok($obj, 'Localized::Object');
    is($obj->locale, $locale, '... got the right locale (' . $locale . ')');
}



