#!perl  -T

use Test::More tests => 146;
use Scalar::Util 'refaddr';
use strict;

{# Scope for the warnings so we can switch back to -w mode for tests below.
use warnings; no warnings 'utf8';


#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok 'JE::LValue' }


#--------------------------------------------------------------------#
# Tests 2-9: Method delegation

{
	no warnings 'once'; # since those warnings are wrong anyway
	local *__::prop      = sub { bless [], '___' };
	local *___::AUTOLOAD = sub { 5               };
	local *___::apply    = sub { $_[1]           };
	my $thing = bless [], '__';
	my $lv    = new JE::LValue $thing, 'anything can go here';
	isa_ok $lv, 'JE::LValue';
	cmp_ok $lv->my_method, '==', 5, 'method delegation';

	# Make sure that JE::LValue's own methods are not delegated
	isa_ok $lv->get, '___', 'result of get (in non-delegation test)';
	isa_ok $lv->set('doo'), '___', 'set is not delegated';
		# (returns retval of prop)
	is refaddr $thing, refaddr $lv->call,   'call is not delegated';
	is refaddr $thing, refaddr $lv->base,   'base is not delegated';
	is $lv->property, 'anything can go here',
		'property is not delegated';
	is $lv->can('set'), \&JE::LValue::set,
		'can is not delegated when it\'s not supposed to be';
}


#--------------------------------------------------------------------#
# Tests 10-120: Overloading

{
	package overtest;
	our($op, $thing);
	use overload
		'+'    => sub { $op = '+'      },
		'+='   => sub { $op = '+='     },
		'-'    => sub { $op = '-'      },
		'-='   => sub { $op = '-='     },
		'*'    => sub { $op = '*'      },
		'*='   => sub { $op = '*='     },
		'/'    => sub { $op = '/'      },
		'/='   => sub { $op = '/='     },
		'%'    => sub { $op = '%'      },
		'%='   => sub { $op = '%='     },
		'**'   => sub { $op = '**'     },
		'**='  => sub { $op = '**='    },
		'<<'   => sub { $op = '<<'     },
		'<<='  => sub { $op = '<<='    },
		'>>'   => sub { $op = '>>'     },
		'>>='  => sub { $op = '>>='    },
		 x     => sub { $op = 'x'      },
		'x='   => sub { $op = 'x='     },
		'.'    => sub { $op = '.'      },
		'.='   => sub { $op = '.='     },
		'<'    => sub { $op = '<';   1 },
		'<='   => sub { $op = '<=';  1 },
		'>'    => sub { $op = '>';   1 },
		'>='   => sub { $op = '>=';  1 },
		'=='   => sub { $op = '==';  1 },
		'!='   => sub { $op = '!=';  1 },
		'<=>'  => sub { $op = '<=>'; 1 },
		 lt    => sub { $op = 'lt';  1 },
		 le    => sub { $op = 'le';  1 },
		 gt    => sub { $op = 'gt';  1 },
		 ge    => sub { $op = 'ge';  1 },
		 eq    => sub { $op = 'eq';  1 },
		 ne    => sub { $op = 'ne';  1 },
		 cmp   => sub { $op = 'cmp'; 1 },
		'&'    => sub { $op = '&'      },
		'^'    => sub { $op = '^'      },
		'|'    => sub { $op = '|'      },
		 neg   => sub { $op = 'neg'    }, # unary negation
		'!'    => sub { $op = '!'      },
		'~'    => sub { $op = '~'      },
		'++'   => sub { $thing = '++'  },
		'--'   => sub { $thing = '--'  },
		 atan2 => sub { $op = 'atan2'  },
		 cos   => sub { $op = 'cos'    },
		 sin   => sub { $op = 'sin'    },
		 exp   => sub { $op = 'exp'    },
		 abs   => sub { $op = 'abs'    },
		 log   => sub { $op = 'log'    },
		 sqrt  => sub { $op = 'sqrt'   },
		 int   => sub { $op = 'int'    },
		 bool  => sub { $op = 'bool';0 },
		'""'   => sub { $op = '""'     },
		'0+'   => sub { $op = '00'     }, 
		'<>'   => sub { $op = '<>'     },
		'${}'  => sub { \"Hey!"        },
		'@{}'  => sub { ["Hey!"]       },
		'%{}'  => sub { {"Hey!" => 0 } },
		'&{}'  => sub { sub { "Hey!" } },
		'*{}'  => sub { \*STDOUT       };
}

{
	no warnings 'once';
	local *base_class::prop = sub { bless [], 'overtest' };
	my $lv = new JE::LValue bless([], 'base_class'), 'doodaa';
	my $tmp;

        is $lv + 1,             '+',      '+ overloading (1)';
        is $overtest::op,       '+',      '+ overloading (2)';
        is +($tmp = $lv) += 1,  '+=',     '+= overloading (1)';
        is $overtest::op,       '+=',     '+= overloading (2)';
        is $lv - 1,             '-',      '- overloading (1)';
        is $overtest::op,       '-',      '- overloading (2)';
        is +($tmp = $lv) -= 1,  '-=',     '-= overloading (1)';
        is $overtest::op,       '-=',     '-= overloading (2)';
        is $lv * 1,             '*',      '* overloading (1)';
        is $overtest::op,       '*',      '* overloading (2)';
        is +($tmp = $lv) *= 1,  '*=',     '*= overloading (1)';
        is $overtest::op,       '*=',     '*= overloading (2)';
        is $lv / 1,             '/',      '/ overloading (1)';
        is $overtest::op,       '/',      '/ overloading (2)';
        is +($tmp = $lv) /= 1,  '/=',     '/= overloading (1)';
        is $overtest::op,       '/=',     '/= overloading (2)';
        is $lv % 1,             '%',      '% overloading (1)';
        is $overtest::op,       '%',      '% overloading (2)';
        is +($tmp = $lv) %= 1,  '%=',     '%= overloading (1)';
        is $overtest::op,       '%=',     '%= overloading (2)';
        is $lv ** 1,            '**',     '** overloading (1)';
        is $overtest::op,       '**',     '** overloading (2)';
        is +($tmp = $lv) **= 1, '**=',    '**= overloading (1)';
        is $overtest::op,       '**=',    '**= overloading (2)';
        is $lv << 1,            '<<',     '<< overloading (1)';
        is $overtest::op,       '<<',     '<< overloading (2)';
        is +($tmp = $lv) <<= 1, '<<=',    '<<= overloading (1)';
        is $overtest::op,       '<<=',    '<<= overloading (2)';
        is $lv >> 1,            '>>',     '>> overloading (1)';
        is $overtest::op,       '>>',     '>> overloading (2)';
        is +($tmp = $lv) >>= 1, '>>=',    '>>= overloading (1)';
        is $overtest::op,       '>>=',    '>>= overloading (2)';
        is $lv x 1,             'x',      'x overloading (1)';
        is $overtest::op,       'x',      'x overloading (2)';
        is +($tmp = $lv) x= 1,  'x=',     'x= overloading (1)';
        is $overtest::op,       'x=',     'x= overloading (2)';
        is $lv . 1,             '.',      '. overloading (1)';
        is $overtest::op,       '.',      '. overloading (2)';
        is +($tmp = $lv) .= 1,  '.=',     '.= overloading (1)';
        is $overtest::op,       '.=',     '.= overloading (2)';
        is $lv < 1,              1,       '< overloading (1)';
        is $overtest::op,       '<',      '< overloading (2)';
        is $lv <= 1,             1,       '<= overloading (1)';
        is $overtest::op,       '<=',     '<= overloading (2)';
        is $lv > 1,              1,       '> overloading (1)';
        is $overtest::op,       '>',      '> overloading (2)';
        is $lv >= 1,             1,       '>= overloading (1)';
        is $overtest::op,       '>=',     '>= overloading (2)';
        is $lv == 1,             1,       '== overloading (1)';
        is $overtest::op,       '==',     '== overloading (2)';
        is $lv != 1,             1,       '!= overloading (1)';
        is $overtest::op,       '!=',     '!= overloading (2)';
        is $lv <=> 1,            1,       '<=> overloading (1)';
        is $overtest::op,       '<=>',    '<=> overloading (2)';
        is $lv lt 1,             1,       'lt overloading (1)';
        is $overtest::op,       'lt',     'lt overloading (2)';
        is $lv le 1,             1,       'le overloading (1)';
        is $overtest::op,       'le',     'le overloading (2)';
        is $lv gt 1,             1,       'gt overloading (1)';
        is $overtest::op,       'gt',     'gt overloading (2)';
        is $lv ge 1,             1,       'ge overloading (1)';
        is $overtest::op,       'ge',     'ge overloading (2)';
        is $lv eq 1,             1,       'eq overloading (1)';
        is $overtest::op,       'eq',     'eq overloading (2)';
        is $lv ne 1,             1,       'ne overloading (1)';
        is $overtest::op,       'ne',     'ne overloading (2)';
        is $lv cmp 1,            1,       'cmp overloading (1)';
        is $overtest::op,       'cmp',    'cmp overloading (2)';
        is $lv & 1,             '&',      '& overloading (1)';
        is $overtest::op,       '&',      '& overloading (2)';
        is $lv ^ 1,             '^',      '^ overloading (1)';
        is $overtest::op,       '^',      '^ overloading (2)';
        is $lv | 1,             '|',      '| overloading (1)';
        is $overtest::op,       '|',      '| overloading (2)';
        is -$lv,                'neg',    'neg overloading (1)';
        is $overtest::op,       'neg',    'neg overloading (2)';
        is !$lv,                '!',      '! overloading (1)';
        is $overtest::op,       '!',      '! overloading (2)';
        is ~$lv,                '~',      '~ overloading (1)';
        is $overtest::op,       '~',      '~ overloading (2)';
        ++$lv;
        is $overtest::thing,    '++',     '++ overloading';
        --$lv;
        is $overtest::thing,    '--',     '-- overloading';
        is atan2($lv,1),        'atan2',  'atan2 overloading (1)';
        is $overtest::op,       'atan2',  'atan2 overloading (2)';
        is cos $lv,             'cos',    'cos overloading (1)';
        is $overtest::op,       'cos',    'cos overloading (2)';
        is sin $lv,             'sin',    'sin overloading (1)';
        is $overtest::op,       'sin',    'sin overloading (2)';
        is exp $lv,             'exp',    'exp overloading (1)';
        is $overtest::op,       'exp',    'exp overloading (2)';
        is abs $lv,             'abs',    'abs overloading (1)';
        is $overtest::op,       'abs',    'abs overloading (2)';
        is log $lv,             'log',    'log overloading (1)';
        is $overtest::op,       'log',    'log overloading (2)';
        is sqrt $lv,            'sqrt',   'sqrt overloading (1)';
        is $overtest::op,       'sqrt',   'sqrt overloading (2)';
        is int $lv,             'int',    'int overloading (1)';
        is $overtest::op,       'int',    'int overloading (2)';
        is $lv ? 0 : 1,          1,       'bool overloading (1)';
        is $overtest::op,       'bool',   'bool overloading (2)';
        $lv =~ /^(.*)\z/s;
        is $1,                  '""',     'string overloading (1)';
        is $overtest::op,       '""',     'string overloading (2)';
        is ord chr $lv,          0,       'numeric overloading (1)';
        is $overtest::op,       '00',     'numeric overloading (2)';
        is <$lv>,               '<>',     '<> overloading (1)';
        is $overtest::op,       '<>',     '<> overloading (2)';
        is $$lv,                'Hey!',   'scalar dereference overloading';
        is_deeply \@$lv,       ['Hey!'],   'array dereference overloading';
        is_deeply \%$lv,     {'Hey!' => 0}, 'hash dereference overloading';
        is &$lv,           'Hey!',          'code dereference overloading';
        is \*$lv,          \*STDOUT,        'glob dereference overloading';

}


#--------------------------------------------------------------------#
# Tests 121-31: new, base, property

use_ok 'JE';

our $je = JE->new;
isa_ok $je, 'JE';

our $lv = new JE::LValue $je, 'undefined';
isa_ok $lv, 'JE::LValue', '(new JE::LValue $je, undefined)';

is refaddr +base $lv, refaddr $je;
is property $lv, 'undefined';

eval { new JE::LValue $je->undefined, 'oentoetntn' };
isa_ok $@, 'JE::Object::Error::TypeError',
	'$@ (after new JE::LValue undefined)';
eval { new JE::LValue $je->null, 'toetntn' };
isa_ok $@, 'JE::Object::Error::TypeError',
	'$@ (after new JE::LValue null)';

our $lv_no_base = new JE::LValue \$je, 'x';
isa_ok $lv_no_base, 'JE::LValue', 'lvalue without base';

is_deeply [base $lv_no_base], [],
	'(lvalue without base)->base in list context';
is_deeply scalar base $lv_no_base, undef,
	'(lvalue without base)->base in scalar context';
is property $lv_no_base, 'x', '(lvalue without base)->property';


#--------------------------------------------------------------------#
# Tests 132-3: get

isa_ok $lv->get, 'JE::Undefined', '$lv->get';
eval { $lv_no_base->get };
isa_ok $@, 'JE::Object::Error::ReferenceError',
	'$@ after $lv_no_base->get';


#--------------------------------------------------------------------#
# Tests 134-7: set

is $lv->set(7),            7, 'return value of "set"';
is $je->prop('undefined'), 7, 'result of $lv->set';
is $lv_no_base->set(2),    2, 'return value of "set" (again)';
is $je->prop('x'),         2, 'result of $lv_no_base->set';


#--------------------------------------------------------------------#
# call has already been tested in the 'Method delegation' section.


#--------------------------------------------------------------------#
# Tests 138-43: can

{
	no warnings 'once';
	local *base_class::prop = sub { bless [], 'prop_class' };
	local *prop_class::this = sub { ref(shift) . 'this' };
	local *prop_class::that = sub { ref(shift) . 'that' };
	local *prop_class::base = sub { }; # a method with the same name
	                                   # as a JE::LValue method

	my $lv = new JE::LValue bless([], 'base_class'), '';

	# Test prop_class's methods
	is $lv->can('this')->($lv), 'prop_classthis', 'can this';
	is $lv->can('that')->($lv), 'prop_classthat', 'can that';

	# JE::LValue's methods
	is $lv->can('base'), \&JE::LValue::base, 'can base';
	is $lv->can('get'),  \&JE::LValue::get,  'can get';
	ok !$lv->can('teemipyf.pyuh'), "can't teemipyf.pyuh";

	eval {
		$lv->can("\x{d800}")
	};
	is $@, '', '$lv->can("\x{d800}") doesn\'t die';
}


#--------------------------------------------------------------------#
# Test 144-6: warnings

{
 my $w;
 local $SIG{__WARN__} = sub { warn $_[0]; ++$w };
 no warnings 'uninitialized';
 () = $lv eq undef;
 is $w, undef, 'The overload handler respects the caller’s warnings';
}

} # end the warnings scope started near the top of the file

{
 local $^W;
 my $w;
 local $SIG{__WARN__} = sub { warn $_[0]; ++$w };
 () = our $lv eq undef;
 is $w, undef, 'The overload handler respects !$^W';
 
 $^W = 1;
 local $SIG{__WARN__} = sub {++$w };
 undef $w;
 () = $lv eq undef;
 is $w, 1, 'The overload handler respects $^W';
}
