#!/usr/bin/env perl

use strict;
use Test::More tests => 12;

AT_STARTUP_SCRIPT :
{
    BEGIN {
        use strict;
        use Method::Cached::Manager;

        Method::Cached::Manager->default_domain({
            class => 'Cache::FastMmap',
            args  => [],
        });
    }
}

IN_MODULE_OF_SOMETHING :
{
    package Dummy;

    use Method::Cached;
    use Method::Cached::KeyRule::Serialize qw/SELF_CODED/;

    sub new { bless {}, shift }
    sub id  { 1 < @_ ? $_[0]->{id} = $_[1] : $_[0]->{id} }

    sub self_shift : Cached(0, [SELF_SHIFT, LIST]) {
        time . ':' . rand
    }
    sub self_coded : Cached(0, [SELF_CODED, LIST]) {
        time . ':' . rand
    }
    sub per_object : Cached(0, [PER_OBJECT, LIST]) {
        time . ':' . rand
    }
}

IN_MAIN :
{
    # use Dummy;
    Dummy->import;

    sub make_value {
        my $method = shift;
        my $obj1 = Dummy->new;
        my $obj2 = Dummy->new;
        $obj1->id(100);
        $obj2->id(100);
        my @ret;
        push @ret, (
            $obj1->$method(1),
            $obj1->$method(1),
            $obj1->$method(3),
            $obj2->$method(1),
        );
        $obj1->id(300);
        push @ret, (
            $obj1->$method(1),
        );
        return @ret;
    }

    {
        my ($o1_base, $o1_clone, $o1_another, $o2_base, $o1_modified)
            = make_value('self_shift');

        is   $o1_base, $o1_clone,    ;
        isnt $o1_base, $o1_another,  ;
        is   $o1_base, $o2_base,     ;
        is   $o1_base, $o1_modified, ;
    }

    {
        my ($o1_base, $o1_clone, $o1_another, $o2_base, $o1_modified)
            = make_value('self_coded');

        is   $o1_base, $o1_clone,    ;
        isnt $o1_base, $o1_another,  ;
        is   $o1_base, $o2_base,     ;
        isnt $o1_base, $o1_modified, ;
    }

    {
        my ($o1_base, $o1_clone, $o1_another, $o2_base, $o1_modified)
            = make_value('per_object');

        is   $o1_base, $o1_clone,    ;
        isnt $o1_base, $o1_another,  ;
        isnt $o1_base, $o2_base,     ;
        is   $o1_base, $o1_modified, ;
    }
}
