[Lazy::Bool](https://metacpan.org/release/Lazy-Bool) is my first module in [CPAN](http://www.cpan.org/) (The Comprehensive Perl Archive Network). It is a simple module (only 60 lines) and few methods/operators but can be useful in some situation. The source code can be found in my [github](https://github.com/peczenyj/Lazy-Bool).

##Example##

```perl
use Lazy::Bool;
use Test::More tests=> 3;
my $a = 6;
my $b = 4;
my $x  = Lazy::Bool->new(sub{ $a > $b });
my $false = Lazy::Bool::false;
 
my $result = ($x | $false) & ( ! ( $false & ! $false ) );
 
# now the expressions will be evaluate
ok($result,    "complex expression should be true");
ok(!! $x ,  "double negation of true value should be true");  
ok(!!! $false, "triple negation of false value should be true");
```

<!--more-->

Sometimes we have expensive operations in our code (like uses lots of CPU, Memory, etc). We can wait until the last second to evaluate this kind of expressions if we can. Imagine an imaginary video processing module and we need check many parameters to validate one file like: size, format, codec, extension, etc. It is easy to fetch the size of one file but read the file to fetch some informations can be expensive (we have I/O, etc). We can avoid one expensive process if the size of the file is not ok (like more than the limit, or less than 1 Kb). Of course we can write the validation subroutine thinking in this scenario or... we can use my Lazy::Bool!

##How it works##

In perl we can overload many operators using the pragma [overload](http://perldoc.perl.org/overload.html). One of this operators is the 'bool', used for type conversion. Perl has a small set of data types (scalar, array, hash, subroutine, etc) but one scalar can be used as a text, number or boolean (the context is important). If we use one scalar in boolean context, we can control like this.

```perl
package Lazy::Bool;

use overload 
	'bool' => \&_to_bool,

sub _to_bool {
	# return some boolean value
}
```

To create an instance of Lazy::Bool we need to use the [bless](http://perldoc.perl.org/functions/bless.html) keyword. I can bless any reference (normally we use a hashref to simulate the internal state of the object) and the semantic of the method calling is similar to Python: the first argument is the class or object.

For this module I'm blessing a reference to a subroutine. It is essential for be lazy as much as we can. For example:

```perl
package Lazy::Bool;

sub new {
	my $klass = shift;
	my $code  = shift;
		
	bless $code, $klass;
}
sub _to_bool {
	shift->()
}
...

my $false = Lazy::Bool->new( sub { 
	print "I am laaaaazy\n"; 
	0 
});

```

The shift keyword just return the first argument and remove it from the array. All subroutines in Perl receive just one array with all parameters. If I want to call a subroutine and pass more than one array I need to use references. Strange? Maybe, it is a simple way to work with multiple parameters and do this:

```perl
sub foo {
	# do something
}

sub wrap_foo {
	# before
	my $x = foo(@_);  # in some cases we can use goto (like recursion)
	# after
	
	return $x
}
```

In my module I have a blessed reference for a subroutine. I will evaluate the value only in boolean context. Sounds good! But If I want to build one complex expression using or, and, not?

I can't override the && and || BUT I can override the bit operators &, | and !, to build complex objects.

```perl
use overload 
	'&'    => \&_and;

sub _and {
	my $a = shift;
	my $b = shift;
	
	Lazy::Bool->new(sub {
		$a->_to_bool & $b
	})
}
...

my $x = Lazy::Bool->new( sub { 
	# my complex expression 1
} );
my $y = Lazy::Bool->new( sub { 
	# my complex expression 2
} );

# The variable $z is a Lazy::Bool too. 
my $z = $x & $y;  # CAUTION: will be evaluated if you use && 

print "ok" if $z; # now will evaluate the entire expression
```

And you can do the same with | and ! operators. 

There are two helper methods, true and false, to return lazy values of true and false (1 and 0).

##TODO##

Unfortunately this module is a beta version and it is not ready to production. I need to think in two details:

I need to implement: 

- a shortcut in and / or operations
- a cache to prevent evaluate the same expression twice

But I don't know what is the best way to do this. I'm using & and | operators similar to logical and/or but &/| does not have any shortcut. Maybe I can put a huge observation in the documentation about this.

The question about cache is interesting. In some cases I can't 'memoize' the result. I have two options:

- create another class like Lazy::Bool::Memoized to do this, or
- add an extra parameter in the contructor, like cached => 1

I'm very interesting in your opinion! Please give me some feedback :)

###UPDATE###

From version 0.03 there all boolean expression now supports shortcut and there is a new class, Lazy::Bool::Cached who memoize the value of the expression.

##Helpers##

There are two helpers to easily create new instances from an anonymous subroutine: lzb and lzbc 

```perl
use Test::More tests => 2;

use Lazy::Bool qw(lzb);
use Lazy::Bool::Cached qw(lzbc);

ok( lzb { 1 }, "lzb should be true" );
ok( lzbc { 1 }, "lzbc should be true" );
```

##How to install##
To install this module is simple:
	bash$ cpan Lazy::Bool

###Test Coverage##

Total 96.6 % 
```
---------------------------- ------ ------ ------ ------ ------ ------ ------
File                           stmt   bran   cond    sub    pod   time  total
---------------------------- ------ ------ ------ ------ ------ ------ ------
blib/lib/Lazy/Bool.pm         100.0  100.0   66.7  100.0   75.0   64.9   97.2
blib/lib/Lazy/Bool/Cached.pm  100.0  100.0   66.7  100.0   50.0   35.1   95.7
Total                         100.0  100.0   66.7  100.0   66.7  100.0   96.6
---------------------------- ------ ------ ------ ------ ------ ------ ------
```
	
##Final Considerations##

I try to do this module in Ruby and I realize it is not possible [see here](http://stackoverflow.com/questions/14444975/how-to-create-an-object-who-act-as-a-false-in-ruby/). In Ruby we have only two "false" values: nil and false. And it is HARD CODED in the code. I can't extend the FalseClass (in fact I can but if I do this I loose the 'new'). I have no options to do this transparent to the user.

The same thing in Java: I have the Boolean wrapper class but it is final. But I can emulate the same thing in Python using the `__nonzero__` special method like this:

```python
class MyBooleanClass:
	def __init__(self, value):
		self.value = value
		
	def __nonzero__(self):
		return self.value # Just to simplify the example
		
t = MyBooleanClass(True)
f = MyBooleanClass(False)

assert t, "should be true"
assert not f, "should be false"
```

Build a dynamic proxy to one real object can be very helpful in many situations. You can find this in Hibernate (the Java ORM solution) if you choose working with Lazy Initialization.

Perl, Python, Java, Ruby or PHP: each language has some advantages to do something. I can't choose one language just based on one aspect. We need to consider the community, the environment, tools, etc. Perl is a good choice for software development in general (web, desktop, backend services) but it is not the only language capable to do X. We need to think about many aspects to decide one (or more) for our next project and be happy.