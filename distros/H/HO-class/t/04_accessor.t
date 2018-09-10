use strict;
use warnings;

use Test::More tests => 21;
use Test::Exception;

require_ok('HO::accessor');

package T::one;
use HO::accessor [__t => '$'] , [], 0, 1; # accessors, methods, make_init, make_constructor

my $t1 = new T::one::;
Test::More::isa_ok($t1,'T::one');

Test::More::is(ref $t1->[0], '');

sub tm1 : lvalue { shift->[__t] }

package main;

ok($t1->tm1 = 'trf');
is($t1->tm1,'trf');

package T::one_without_constr;
use base 'T::one';

my $twc = new T::one_without_constr;

Test::More::isa_ok($twc,'T::one_without_constr');

my $tw2 = $twc->new;

Test::More::isa_ok($tw2,'T::one_without_constr');

; package T::entity
; BEGIN
    { Test::More::use_ok
        ( 'HO::class',
             _ro => name => '$',
             _ro => href => '$',
             _rw => version => sub () {'1.0'}
        )
    }

; package main

; my $e = new T::entity::
; $e->[$e->_name] = 'timestamp'
; $e->[$e->_href] = 'http://localhost:8091/time/'

; Test::More::is($e->name,'timestamp')
; Test::More::is($e->href,'http://localhost:8091/time/')
; Test::More::is($e->version,'1.0')

; throws_ok { T::entity->name }
      qr/Not a class method 'name'\./

; throws_ok { T::entity->version }
      qr/Not a class method 'version'\./

; package T::plus
; use HO::class
    _lvalue => val => '%',
    _rw => data => '%',
    init => 'hash'

; package main
; Test::More::is_deeply((T::plus->new->val={}),{})

; my $p = T::plus->new( data => {'key' => 'value'})
; is($p->data->{'key'},'value','rw hash read')
; is($p->data('key'),'value','rw hash read 2')
; is_deeply($p->data('key','polar'),$p,'rw hash change')
; is($p->data('key'),'polar','changed value')

; is_deeply($p->data({'new' => 'values'}),$p,'rw hash complete change')
; ok(!exists($p->data->{'key'}),'check 1')
; is($p->data->{'new'},'values','check 2')
