#!/usr/bin/perl
use strict;
use warnings;
use Test::Simple tests => 15;
BEGIN {unshift @INC, '../lib'}
use Lvalue ':all';

print "Lvalue $Lvalue::VERSION\n";

{no warnings 'redefine';
    my $ok = \&ok;
    *ok = sub ($;$) {push @_, shift; goto &$ok}
}

{package Integer;
	our $VERSION = '0.101';
	sub new {bless {value => $_[1] ? int $_[1] : 0}}
	sub value {
		my $self = shift;
		@_ ? $$self{value} = int shift
		   : $$self{value};
	}
}

my $int = Lvalue->wrap( Integer->new(3.14) );

ok 'constructor'
=> (ref $int) =~ /^Lvalue::Loader(?:::_\d)?$/;

ok 'getter'
=> $int->value == 3;

ok 'setter lvalue'
=> ($int->value = 234.5434) == 234
&& $int->value == 234;

ok 'can'
=> $int->can('value');

ok 'isa'
=> $int->isa('Integer');

ok 'DOES'
=> eval {$int->DOES('Integer')}
|| $@ =~ /^no method 'DOES' on 'Integer.+?lvalue.t/;

ok 'VERSION'
=> $int->VERSION eq '0.101';

$_ /= 6.23 for $int->value;

ok 'alias'
=> $int->value == 37;

ok 'setter method'
=> $int->value(2.71) == 2
&& $int->value == 2;

ok 'no method call'
=> !eval {$int->nomethod(3)}
&& $@ =~ /^no method 'nomethod' on 'Integer.+?lvalue.t/;

ok 'no method tied'
=> !eval {$int->nomethod = 3}
&& $@ =~ /^no method 'nomethod' on 'Integer.+?lvalue.t/;

$int = Lvalue->unwrap( $int );

ok 'unwrap'
=> ref $int eq 'Integer'
&& ! eval {$int->value = 5};

eval q{
	package Integer;
	use overload fallback => 1,
		'""'  => sub {"int($_[0]{value})"},
		'0+'  => sub {$_[0]{value}},
		'&{}' => sub {
			my $self = shift;
			sub {"code deref overload: $$self{value}"}
		};
};

my $norm = Integer->new(1.234);

ok 'pre Lvalue'
=> ! eval {$norm->value = 5}
&& "$norm" eq 'int(1)'
&& $norm == 1
&& eval {$norm->() eq 'code deref overload: 1'};

lvalue $norm;

ok 'post void wrap'
=> eval {$norm->value = 10; $norm->value == 10}
&& "$norm" eq 'int(10)'
&& $norm == 10
&& eval {$norm->() eq 'code deref overload: 10'};

unwrap $norm;

ok 'post void unwrap'
=> ! eval {$norm->value = 5}
&& $norm->value(6.4892) == 6
&& $norm == 6
&& "$norm" eq 'int(6)'
&& eval {$norm->() eq 'code deref overload: 6'};

{package NonSTD;
	sub new {bless {val => 0}}
	sub set_val {$_[0]{val} = $_[1]}
	sub get_val {$_[0]{val}}
}
