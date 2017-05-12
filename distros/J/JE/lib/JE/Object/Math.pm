package JE::Object::Math;

our $VERSION = '0.066';


use strict;
use warnings;

use constant inf => 9**9**9;
use constant nan => sin 9**9**9;

use POSIX qw'floor ceil';

our @ISA = 'JE::Object';

require JE::Number;
require JE::Object;
require JE::Object::Function;



=head1 NAME

JE::Object::Math - JavaScript Math object

=head1 SYNOPSIS

  use JE;
  use JE::Object::Math;

  $j = new JE;

  $math_obj = new JE::Object::Math $j;

=head1 DESCRIPTION

This class implements the JavaScript Math object.

=head1 METHODS

See L<JE::Types> for descriptions of most of the methods. Only what
is specific to JE::Object::Math is explained here.

=over

=item JE::Object::Math->new($global_obj)

Creates a new Math object.

=cut

sub new {
	my($class, $global) = @_;
	my $self = $class->SUPER::new($global);

	$self->prop({
		name  => 'E',
		value  => JE::Number->new($global, exp 1),
		dontenum => 1,
		dontdel   => 1,
		readonly  => 1,
	});	
	$self->prop({
		name  => 'LN10',
		value  => JE::Number->new($global, log 10),
		dontenum => 1,
		dontdel   => 1,
		readonly  => 1,
	});
	$self->prop({
		name  => 'LN2',
		value  => JE::Number->new($global, log 2),
		dontenum => 1,
		dontdel   => 1,
		readonly  => 1,
	});
	$self->prop({
		name  => 'LOG2E',
		value  => JE::Number->new($global, 1/log 2),
		dontenum => 1,
		dontdel   => 1,
		readonly  => 1,
	});
	$self->prop({
		name  => 'LOG10E',
		value  => JE::Number->new($global, 1/log 10),
		dontenum => 1,
		dontdel   => 1,
		readonly  => 1,
	});
	$self->prop({
		name  => 'PI',
		value  => JE::Number->new($global, 4 * atan2 1,1),
		dontenum => 1,
		dontdel   => 1,
		readonly  => 1,
	});
	$self->prop({
		name  => 'SQRT1_2',
		value  => JE::Number->new($global, .5**.5),
		dontenum => 1,
		dontdel   => 1,
		readonly  => 1,
	});
	$self->prop({
		name  => 'SQRT2',
		value  => JE::Number->new($global, 2**.5),
		dontenum => 1,
		dontdel   => 1,
		readonly  => 1,
	});

	$self->prop({
		name  => 'abs',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'abs',
			argnames => ['x'],
			no_proto => 1,
			function_args => ['args'],
			function => sub {	
				JE::Number->new($global,
					defined $_[0]
					? abs $_[0]->to_number->value
					: 'nan');
			},
		}),
		dontenum => 1,
	});
	$self->prop({
		name  => 'acos',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'acos',
			argnames => ['x'],
			no_proto => 1,
			function_args => ['args'],
			function => sub {
				my $num;
				if(defined $_[0]) {
					$num = $_[0]->to_number->value;
					$num = atan2+
						(1 - $num * $num)**.5,
						$num;
				}
				else {
					$num = 'nan';
				}	
				JE::Number->new($global, $num);
			},
		}),
		dontenum => 1,
	});
	$self->prop({
		name  => 'asin',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'asin',
			argnames => ['x'],
			no_proto => 1,
			function_args => ['args'],
			function => sub {
				my $num;
				if(defined $_[0]) {
					$num = $_[0]->to_number->value;
					$num = atan2+
						$num,
						(1 - $num * $num)**.5;
				}
				else {
					$num = 'nan';
				}	
				JE::Number->new($global, $num);
			},
		}),
		dontenum => 1,
	});
	$self->prop({
		name  => 'atan',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'atan',
			argnames => ['x'],
			no_proto => 1,
			function_args => ['args'],
			function => sub {
				JE::Number->new($global,
					defined $_[0]
					? atan2($_[0]->to_number->value, 1)
					: 'nan');
			},
		}),
		dontenum => 1,
	});
	$self->prop({
		name  => 'atan2',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'atan2',
			argnames => [qw/y x/],
			no_proto => 1,
			function_args => ['args'],
			function => sub {
				JE::Number->new($global,
					defined $_[0] && defined $_[1]
					? do {
					   my $a = $_[0]->to_number->value;
					   my $b = $_[1]->to_number->value;
					   # Windoze has trouble
					   # with two infs.
					   $a + 1 == $a && $b+1 == $b
					    ? ($b>0 ? 1 : 3) * atan2(1,1)
					       * ($a > 0 ? 1 : -1)
					    : atan2($a, $b)
					  }
					: 'nan');
			},
		}),
		dontenum => 1,
	});
	$self->prop({
		name  => 'ceil',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'ceil',
			argnames => [qw/x/],
			no_proto => 1,
			function_args => ['args'],
			function => sub {
				JE::Number->new($global,
					defined $_[0]
					? ceil($_[0]->to_number->value)
					: 'nan');
			},
		}),
		dontenum => 1,
	});
	$self->prop({
		name  => 'cos',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'cos',
			argnames => [qw/x/],
			no_proto => 1,
			function_args => ['args'],
			function => sub {
				JE::Number->new($global,
					defined $_[0]
					? cos($_[0]->to_number->value)
					: 'nan');
			},
		}),
		dontenum => 1,
	});
	$self->prop({
		name  => 'exp',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'exp',
			argnames => [qw/x/],
			no_proto => 1,
			function_args => ['args'],
			function => sub {
				JE::Number->new($global,
					defined $_[0]
					? $_[0] + 1 == $_[0] # inf
					   ? $_[0] < 0 ? 0 : 'inf'
					   : exp($_[0]->to_number->value)
					: 'nan');
			},
		}),
		dontenum => 1,
	});
	$self->prop({
		name  => 'floor',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'floor',
			argnames => [qw/x/],
			no_proto => 1,
			function_args => ['args'],
			function => sub {
				JE::Number->new($global,
					defined $_[0]
					? floor($_[0]->to_number->value)
					: 'nan');
			},
		}),
		dontenum => 1,
	});
	$self->prop({
		name  => 'log',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'log',
			argnames => [qw/x/],
			no_proto => 1,
			function_args => ['args'],
			function => sub {
				my $num;
				if (defined $_[0]) {
					$num = $_[0]->to_number->value;
					$num = $num < 0 ? 'nan' :
					       $num == 0 ? '-Infinity' :
					       log $num;
				}
				else { $num = 'nan' }
				JE::Number->new($global, $num);
			},
		}),
		dontenum => 1,
	});
	$self->prop({
		name  => 'max',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'max',
			length  => 2,
			no_proto => 1,
			function_args => ['args'],
			function => sub {
@_ or return JE::Number->new($global, '-inf');
my $result; my $num;
for (@_) {
	($num = $_->to_number->value) == $num or
		 return JE::Number->new($global, 'nan');;
	$result = $num if !defined $result or $result < $num;
}
JE::Number->new($global, $result);

			},
		}),
		dontenum => 1,
	});
	$self->prop({
		name  => 'min',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'min',
			length  => 2,
			no_proto => 1,
			function_args => ['args'],
			function => sub {
@_ or return JE::Number->new($global, 'inf');
my $result; my $num;
for (@_) {
	($num = $_->to_number->value) == $num or
		 return JE::Number->new($global, 'nan');;
	$result = $num if !defined $result or $result > $num;
}
JE::Number->new($global, $result);

			},
		}),
		dontenum => 1,
	});

	$self->prop({
		name  => 'pow',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'pow',
			argnames => [qw/x y/],
			no_proto => 1,
			function_args => ['args'],
			function => sub {
my $x = defined $_[0] ? $_[0]->to_number->value : nan;
my $y = defined $_[1] ? $_[1]->to_number->value : nan;

abs $x == 1 && abs $y == inf &&
	return JE::Object::Number->new($global, 'nan');

$y == 0 &&
	return JE::Number->new($global, 1);

$x == 0 && $y < 0 && return JE'Number->new($global, inf);

$x == -+inf && $y < 0 &&
	return JE'Number->new($global,
	                      int $y != $y || !($y % 2) ? 0 : -0.0);

$x == -+inf && $y > 0 && int $y != $y &&
	return JE'Number->new($global, inf);

return JE::Number->new($global, $x ** $y);

			},
		}),
		dontenum => 1,
	});
	$self->prop({
		name  => 'random',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'random',
			no_proto => 1,
			function_args => [],
			function => sub {
				JE::Number->new($global, rand);
			},
		}),
		dontenum => 1,
	});
	$self->prop({
		name  => 'round',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'round',
			argnames => ['x'],
			no_proto => 1,
			function_args => ['args'],
			function => sub {
				JE::Number->new($global,
					defined $_[0]
					? floor($_[0]->to_number->value+.5)
					: 'nan');
			},
		}),
		dontenum => 1,
	});
	$self->prop({
		name  => 'sin',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'sin',
			argnames => [qw/x/],
			no_proto => 1,
			function_args => ['args'],
			function => sub {
				JE::Number->new($global,
					defined $_[0]
					? sin($_[0]->to_number->value)
					: 'nan');
			},
		}),
		dontenum => 1,
	});
	$self->prop({
		name  => 'sqrt',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'sqrt',
			argnames => [qw/x/],
			no_proto => 1,
			function_args => ['args'],
			function => sub {
				JE::Number->new($global,
					defined $_[0]
					? do {
					   my $num
					    = $_[0]->to_number->value;
					   $num == -+inf
					    ? 'nan'
					    : $num ** .5
					  }
					: 'nan');
			},
		}),
		dontenum => 1,
	});
	$self->prop({
		name  => 'tan',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'tan',
			argnames => [qw/x/],
			no_proto => 1,
			function_args => ['args'],
			function => sub {
				my $num = shift;
				if(defined $num) {
					$num = $num->to_number->value;
					$num = sin($num) / cos $num;
				}
				else { $num = nan }
				JE::Number->new($global, $num);
			},
		}),
		dontenum => 1,
	});

	$self;
}



=item value

Not particularly useful. Returns a hash ref that is completely empty, 
unless you've added
your own properties to the object. This may change in a future release.

=item class

Returns the string 'Math'

=cut

sub class { 'Math' }




return "a true value";

=back

=head1 SEE ALSO

=over 4

=item JE

=item JE::Types

=item JE::Object

=item JE::Number

=back

=cut
