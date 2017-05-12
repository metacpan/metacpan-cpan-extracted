# -*- mode: cperl; cperl-indent-level: 2 -*-
#
# This module is copyright 1998 Mark-Jason Dominus.
# (mjd-perl-interpolation@plover.com)
# and 2002-2009 Jenda Krynicky

package Interpolation;
use vars '$VERSION';
$VERSION = '0.74';
use strict 'vars';
use warnings;
no warnings 'uninitialized'; # I don't want to be forced to use "if (defined $foo and $foo)

use Carp;

%Interpolation::builtin = (
        null => sub { $_[0] },
	    'eval' => sub { $_[0] },
	    identity => sub { $_[0] },
	    ucwords =>
	    sub {
	      my $s = lc shift;
	      $s =~ s/\b(\w)/\u$1/g;
	      $s
	    },
	    commify =>
	    sub {
	      local $_ = sprintf("%.2f", shift());
	      1 while s/^(-?\d+)(\d{3})/$1,$2/;
	      $_;
	    },
	    'reverse' =>
	    sub { reverse $_[0] },

	    # Idea for funky sprintf trick thanks to Ken Fox
	    'sprintf' =>
	    sub {
	      my %fakehash;
	      my $format = shift;
	      tie %fakehash, Interpolation,
	      sub { sprintf($format, split /$;/o,$_[0])};
	      \%fakehash;
	    },
	    'sprintf1' =>
	    sub {
	      my ($fmt, @args) = split(/$;/o, shift());
	      sprintf($fmt, @args);
	    },
		'sprintfx' => sub {sprintf shift(), @_},
	    'sqlescape' => sub {$_ = $_[0]; s/'/''/g; "'".$_},
		'htmlescape' => sub {HTML::Entities::encode($_[0], '^\r\n\t !\#\$%\"\'-;=?-~')},
		'tagescape' => sub {HTML::Entities::encode($_[0], '^\r\n\t !\#\$%\(-;=?-~')},
		'jsescape' => sub {my $s = $_[0];$s =~ s/(['"])/\\$1/g;HTML::Entities::encode($s, '^\r\n\t !\#\$%\(-;=?-~')},
		'round' => sub {
			my ($number, $scale);
			if (defined $_[1]) {
				($number, $scale) = @_;
			} else {
				($number, $scale) = split /$;/o, $_[0];
			}
			$scale = 1 unless $scale;
			return POSIX::floor(($number / $scale) + 0.5) * $scale;
		}
	   );

%Interpolation::needmodules = (
	'htmlescape' => 'use HTML::Entities;',
	'tagescape' => 'use HTML::Entities;',
	'jsescape' => 'use HTML::Entities;',
	'round' => 'use POSIX;',
);

my %is_scalar;

sub import {
  my $caller_pack = caller;
  shift; # the "Interpolation"
#  print STDERR "exporter args: (@_); caller pack: $caller_pack\n";
  if (@_ % 2) {
    croak "Argument list in `use Interpolation' must be list of pairs; aborting";
  }
  while (@_) {
    my $hashname = shift;
    my $function = shift;
    my $type;

	$function = $hashname unless $function;

    if ($hashname =~ /^(.+):([\$\@\*\\]*->[\$\@])$/) {
        # there is a type specification !
        $type = $2;
        $hashname = $1;
		if ($type eq '->$') {
			$is_scalar{$caller_pack . '::' . $hashname} = undef;
			my $fakescalar;
			tie $fakescalar, 'Interpolation::Scalar', $function;
			*{$caller_pack . '::' . $hashname} = \$fakescalar;
			next;
		}
	} else {
		$type = '$->$';
	}

    my %fakehash;
    tie %fakehash, 'Interpolation', $type, $function;
    *{$caller_pack . '::' . $hashname} = \%fakehash;
  }
  return 1
}

sub TIEHASH {
	shift;
	my $function = pop();
	my $type = shift();
	my $my_pack;

	if ($type eq '' or $type eq '$->$') {
		$my_pack = 'Interpolation::base'
	} elsif ($type eq '$->@') {
		$my_pack = 'Interpolation::S2A';
	} elsif ($type eq '@->$') {
		$my_pack = 'Interpolation::A2S';
	} elsif ($type eq '@->@') {
		$my_pack = 'Interpolation::A2A';
	} else {
		$my_pack = 'Interpolation::general';
	}

	if (ref $function) {
		croak "'use Interpolation' needs a reference to a subroutine or a builtin name!" unless ref $function eq 'CODE';
	} else {
		my $lc_function = lc $function;
		my $lc_hashname;
		if (exists $Interpolation::builtin{$lc_function}) {
			if (exists $Interpolation::needmodules{$lc_function}) {
				eval $Interpolation::needmodules{$lc_function};
				croak $@ if $@;
				delete $Interpolation::needmodules{$lc_function}
			}
			$function = $Interpolation::builtin{$lc_function};
		} else {
			croak "Unknown builtin $function!\n";
		}
	}

	$my_pack->TIEHASH($function, $type);
}

sub unimport {
	no warnings 'untie';
	my $caller_pack = caller;
	my $my_pack = shift;
	while (@_) {
		my $varname = shift;
		if (!exists $is_scalar{$caller_pack . '::' . $varname}) {
			my $oldvar = *{$caller_pack . '::' . $varname}{HASH};
			my %fakehash;
			*{$caller_pack . '::' . $varname} = \%fakehash;
			untie %$oldvar;
		} else {
			my $oldvar = *{$caller_pack . '::' . $varname}{SCALAR};
			my $fakescalar;
			*{$caller_pack . '::' . $varname} = \$fakescalar;
			untie $$oldvar;
			delete $is_scalar{$caller_pack . '::' . $varname};
		}
	}
}

package Interpolation::base;
use Carp;

sub TIEHASH {
	my $pack = shift;
	my $cref = shift;
	unless (ref $cref) {		# Convert symbolic name to function ref
		croak "Unknown builtin function `$cref'; aborting"
			unless exists $Interpolation::builtin{lc $cref};

		eval $Interpolation::needmodules{lc $cref}
			if (exists $Interpolation::needmodules{lc $cref});
		croak $@ if $@;

		$cref = $Interpolation::builtin{lc $cref};
	}
	bless $cref => $pack;		# That's it?  Yup!
}

# This is where the magic is.
sub FETCH {
  &{$_[0]}($_[1]);		# For pre-5.004_04 compatibility
  #$_[0]->($_[1]);		# Line of the day?
}

sub cut_it_out {
  my $object = shift;
  my $caller = (caller(1))[3];
  croak "Not allowed to use $caller on an Interpolation variable; aborting";
}

sub STORE {
  &{$_[0]}($_[1], $_[2]);		# For pre-5.004_04 compatibility
  #$_[0]->($_[1]);		# Line of the day?
}

*DELETE = \&cut_it_out;
*CLEAR = \&cut_it_out;
*EXISTS = \&cut_it_out;
*FIRSTKEY = \&cut_it_out;
*NEXTKEY = \&cut_it_out;

sub UNTIE {};

package Interpolation::S2A;

@Interpolation::S2A::ISA = ('Interpolation::base');
sub FETCH {
  join $", &{$_[0]}($_[1]);
}

sub STORE {
	if (defined wantarray) {
		join $", &{$_[0]}($_[1], $_[2]);
	} else {
		&{$_[0]}($_[1], $_[2]);
	}
}

package Interpolation::A2A;

@Interpolation::A2A::ISA = ('Interpolation::base');
sub FETCH {
  join $", &{$_[0]}(split /$;/o,$_[1]);
}

package Interpolation::A2S;

@Interpolation::A2S::ISA = ('Interpolation::base');
sub FETCH {
  &{$_[0]}(split /$;/o,$_[1]);
}

package Interpolation::general;
use Carp;

@Interpolation::general::ISA = ('Interpolation::base');

sub TIEHASH {
  my $pack = shift;
  my $cref = shift;
  my $type = shift;
  my $self = [];
  unless (ref $cref) {
    croak "Unknown builtin function `$cref'; aborting"
      unless exists $Interpolation::builtin{$cref};
    $cref = $Interpolation::builtin{$cref};
  }
  $self->[0] = reverse $type;
  $self->[1] = $cref;
  bless $self => $pack;		# That's it?  Yup!
}

sub FETCH {
    my $self = shift;
    my $type = $self->[0];
    my $par1type = chop ($type);
    my (@param,$par1subtype);
    if (($par1type eq '\\') and (($par1subtype = chop($type)) eq '@')) {
        $param[0] = [split /$;/o, $_[0]]
    } elsif ($par1type eq '@') {
        @param = split /$;/o, $_[0]
    } else {
        $param[0] = $_[0]
    }
    if ($type =~ /^(.)>-$/ or ($type =~ /\*$/ and $_[0] eq $; and (undef @param or 1))) {
        my $code = $self->[1];
        if ($1 eq '$') {
            &{$code}(@param);
        } else {
            join $", &{$code}(@param);
        }
    } else {
        if ($type =~ /\*$/) {$type .= $par1subtype.$par1type};  ##<???>
        my %fakehash;
        tie %fakehash, Interpolation::internal, [$type, $self->[1], @param];
        bless \%fakehash, Interpolation::internal;
    }
}

package Interpolation::internal;

@Interpolation::internal::ISA = ('Interpolation::base');

sub TIEHASH {
  my ($pack, $self) = @_;
  bless $self => $pack;		# That's it?  Yup!
}

sub FETCH {
    my $self = $_[0];
    my $par1type = chop ($self->[0]);
    my (@param,$par1subtype);
    if ($par1type eq '\\' and (($par1subtype = chop($self->[0])) eq '@')) {
        $param[0] = [split /$;/o, $_[1]]
    } elsif ($par1type eq '@' and $self->[0] !~ /\*$/) {
        @param = split /$;/o, $_[1]
    } else {
        $param[0] = $_[1]
    }
    push @$self, @param;
    if ($self->[0] =~ /^(.)>-$/ or ($self->[0] =~ /\*$/ and $_[1] eq $; and pop @$self)) {
        shift @$self;
        my $code = shift @$self;
        if ($1 eq '$') {
            &{$code}(@$self);
        } else {
            join $", &{$code}(@$self);
        }
    } else {
        my %fakehash;
        if ($self->[0] =~ /\*$/) {$self->[0] .= $par1subtype.$par1type};  ##<???>
        tie %fakehash, Interpolation::internal, $self;
        bless \%fakehash, Interpolation::internal;
    }
}

use overload '""'   => sub {
	my $self = tied(%{$_[0]});
	my ($type, $code, @param) = @$self;
	if ($type =~ /^\$/) {
		&{$code}(@param);
	} else {
		join $", &{$code}(@param);
	}
};

package Interpolation::Scalar;

use Tie::Scalar;
use Carp;
our @ISA=(Tie::Scalar);

sub TIESCALAR {
  my $pack = shift;
  my $cref = shift;
  unless (ref $cref) {		# symbolic names not supported
    croak "Builtins not supported for type (void)->\$";
  }
  bless $cref => $pack;		# That's it?  Yup!
}

sub FETCH {
  &{$_[0]}();		# For pre-5.004_04 compatibility
  #$_[0]->($_[1]);		# Line of the day?
}

sub STORE {
  &{$_[0]}($_[1]);		# For pre-5.004_04 compatibility
  #$_[0]->($_[1]);		# Line of the day?
}


1;

=head1 NAME

Interpolation - Arbitrary string interpolation semantics (using tie())

Version 0.74

Originaly by Mark-Jason Dominus (mjd-perl-interpolation@plover.com)
Since version 0.66 maintained by Jenda@Krynicky.cz

=head1 SYNOPSIS

  use Interpolation name => \&function, ...;
  print "la la la la $name{blah blah blah}";

  # This is like doing:
  $VAR = &function(blah blah blah);
  print "la la la la $VAR";

=head1 DESCRIPTION

Beginners always want to write this:

  print "The sum of three and four is: 3+4";

And they want the C<3+4> part to be evaluated, so that it prints
this:

  The sum of three and four is: 7

Of course, it's a double-quoted string, so it's not evaluated.  The
only things that are evaluated in double-quoted strings are variable
references.

There are solutions to this, but most of them are ugly.  This module
is less ugly. Well .... this module IS ugly, but only inside. Your code may end up being nice.

The module also lets you define arbitrary interpolation semantics.

For example, you can say

   use Interpolation money => \&commify_with_dollar_sign,
                     E     => 'eval',
                     placename => 'ucwords',
       ;

And then you can write these:

   print "3 + 4 = $E{3+4}";
   # Prints  ``3 + 4 = 7''

   $SALARY = 57500;
   print "The salary is $money{$SALARY}";
   # Prints  ``The salary is $57,500.00''

   $PLACE1 = 'SAN BERNADINO HIGH SCHOOL';
   $PLACE2 = 'n.y. state';
   print "$placename{$PLACE1} is not near $placename{$PLACE2}";
   # Prints  ``San Bernadino High School is not near N.Y. State";

=head1 DETAILS

The arguments to the C<use> call should be name-function pairs.  If
the pair is C<($n, $f)>, then C<$n> will be the name for the semantics
provided by C<$f>.  C<$f> must either be a reference to a function
that you supply, or it can be the name of one of the built-in
formatting functions provided by this package.  C<Interpolation> will
take over the C<%n> hash or C<$n> scalar in your package, and tie it so that acessing
C<$n{X}> calls C<f(X)> and yields its return value.

If for some reason you want to, you can add new semantics at run time
by using

  import Interpolation name => function, ...

You can remove them again with

  unimport Interpolation 'name', ...

Interpolators created by the import() or use statements are always PACKAGE variables, not lexicals!
If you want a lexical interpolator you can create it like this:

	my %name;
	tie %name, 'Interpolation', sub { ...
  or
	my %name;
	tie %name, 'Interpolation', '$$->$', sub { ...


=head2 Built-ins

C<Interpolation> provides a few useful built-in formatting functions;
you can refer to these by name in the C<use> or C<import> line.  They are:

	eval			- Evaluate the argument
	null			- Same as eval
	identity		- Also the same as eval

	ucwords		- Capitalize Input String Like This

	commify		- 1428571 => 1,428,571.00

	reverse		- reverse string

	sprintf			- makes "$S{'%.2f %03d'}{37.5,42}" turn into "37.50 042"
		use Interpolation S => 'sprintf';
		print "$S{'%.2f %03d'}{37.5, 42}\n";

	sprintf1		- makes "$S{'%.2f %03d', 37.5,42}" turn into "37.50 042".
		use Interpolation S => 'sprintf1';
		print "$S{'%.2f %03d', 37.5, 42}\n";

	sprintfX		- makes "$S{'%.2f %03d'}{37.5}{42}" turn into "37.50 042".
		use Interpolation 'S:$$*->$' => 'sprintfX';
		print "$S{'%.2f %03d'}{37.5}{42}\n";

	sqlescape		- escapes single quotes for use in SQL queries

	round			- rounds the number
		use Interpolation round => 'round'; print "The sum is: $round{$sum, 0.01}\n";
		use Interpolation 'round:$$->$' => 'round'; print "The sum is: $round{$sum}{0.01}\n";

	htmlescape	- escapes characters special to HTML
			"<b>$htmlescape{$text}</b>
	tagescape	- escapes characters special to HTML plus double and single quotes
			qq{<input type=text name=foo value="$tagescape{$value}">}
	jsescape		- escapes the text to be used in JavaScript
			qq{<a href="JavaScript:foo( '$jsescape{$value}' )">}
		(the last three require module HTML::Entities)

=head1 ADVANCED

It is posible to pass multiple (or no) arguments to your function.
There are two alternate syntaxes:

    $interpolator{param1,param2}
    $interpolator{param1}{param2}

The first syntax will pass both arguments in $_[0] joined by $;, so you have to split them:

    use Interpolation add => sub{@_ = split /$;/o, $_[0]; $_[0] + $_[1]};
    print "3 + 4 = $add{3,4}\n";

The other syntax (used for example by builtin 'sprintf') requires quite some magic,
so you probably wouldn't want to be forced to write it yourself.
(See the source of this module if you want to know how strange is the code. )

The other problem is, that your interpolator might want to return an array.
In that case you would anticipate to get all the items joined by $",
but instead you would get only the last item. You have to join the list yourself:

    use Interpolation foo => sub {join $", &bar($_[0])};

To make your life easier this module provides a way to specify the "type" of the interpolator
and then does the necessary splits, joins or magic itself.

The syntax is:

    use Interpolation 'name:input->output' => sub { ...

where the input is a list of '$'s, '@'s and '\@'s and the output is either '$' or '@'.
The '$' means that the parameter/output should be left intact, while '@'
forces a split/join on the parameter/output. Each character in the input list
specifies the type of one brace in the call.

In addition you may add an asterisk
to the end of the input type specification. This will allow for an arbitrary long
list of parameters. Their type will be the last specified.

In previous version you had to "close" the interpolator call by $;.
That is you would write something like "xxx $foo{par1}{par2}...{parn}{$;} xxx".
While this is still suported it is NOT required anymore.

The default type is $->$.

 Ex.:
  'foo:$->$' - pass the argument to function directly and evaluate it in scalar context
                $foo{param}
  'foo:$->@' - pass the argument to function directly, evaluate it in list context and join
               the result by $" (by default space)
                $foo{param}
  'foo:@->$' - split the first parameter by $; and pass the resulting list to the function,
               evaluate in scalar context
                $foo{param1,param2,...}
  'foo:@->@' - split the first parameter by $; and pass the resulting list to the function,
               evaluate in list context and join
                $foo{param1,param2,...}
  'foo:$$->$' - ask for two parameters enclosed in braces
                 $foo{param1}{param2}
  'foo:$@->$' - ask for two parameters enclosed in braces and split the second one
                the list you get from the split will be added to @_ flatlist
                 $foo{paramA}{paramB1,paramB2,...}
  'foo:$\@->$' - ask for two parameters enclosed in braces and split the second one
                 the list you get from the split will be passed as a reference to an array
                  $foo{paramA}{paramB1,paramB2,...}
  'foo:$*->$   - ask for arbitrary number of scalar parameters
                  $foo{par1}{par2}{par3}{$;}
  'foo:->$	- no parameters. This creates a tied scalar.
                  $foo


 'foo:@->$' => &bar   IS EQUAL TO   'foo' => sub {&bar(split /$;/o, $_[0])}
 'foo:$->@' => &bar   IS EQUAL TO   'foo' => sub {join $", &bar($_[0])}
 'foo:@->@' => &bar   IS EQUAL TO   'foo' => sub {join $", &bar(split /$;/o, $_[0])}
 'foo:\@->$' => &bar  IS EQUAL TO   'foo' => sub {&bar([split /$;/o, $_[0] ])}

The builtin function sprintf could be implemented as:
    'sprintf:$@->$' => sub {sprintf shift,@_}

Since version 0.69 it is possible to assign to interpolators of type '$->$', '$->@' and '->$'.
The assigned value will be passed to the function you specified as the last parameter:

	use Interpolation 'count:->$' => sub {if (@_) {$count = $_[0]} else {$count++}};
	# print "Current count is $count\n";
	use Interpolation 'count:$->$' => sub {
		if (@_ == 2) {
			$count{$_[0]} = $_[1]
		} else {
			$count{$_[0]}++
		}
	};
	# print "Current count of A is $count{A}\n";



=head1 Cool examples

=over 2

=item SQL

    use Interpolation "'" => sub {$_ = $_[0]; s/'/''/g; "'".$_};
    ...
    $db->Sql("SELECT * FROM People WHERE LastName = $'{$lastname}'");

When passing strings to SQL you have to escape the apostrophes
(and maybe some other characters) this crazy hack allows you do it quite easily.

Instead of "... = '$variable'" you write "... = $'{$variable}'" et voila ;-)
You may of course use this syntax for whatever string escaping you like.

=item IF

	use Interpolation 'IF:$*->$' => sub {$_[0] ? $_[1] : $_[2]};
	#or
	use Interpolation '?:$*->$' => sub {$_[0] ? $_[1] : $_[2]};
	#...
	print <<"*END*"
	Blah blah blah
	There was $count $IF{$count > 1}{jobs}{job}.
	There was $count $?{$count > 1}{jobs}{job}.
	There was $count job$?{$count > 1}{s}.
	*END*

=back

=head1 Warnings

It's easy to forget that the index to a C<$hash{...}> is an arbitrary
expression, unless it looks like an identifier.  There are two gotchas here.

=over 4

=item Trap 1.

  print "$X{localtime}";

Here the C<X> formatter is used to format the literal string
C<localtime>; the C<localtime> built-in function is not invoked.  If
you really want the current time, use one of these:

  print "$X{+localtime}";
  print "$X{localtime()}";

=item Trap 2.

  print "$X{What ho?}";

This won't compile---you get `search pattern not terminated'.  Why?
Because Perl sees the C<?> and interprets it as the beginning of a
pattern match operator, similar to C</>.  (Ah, you forgot that C<?>
could be a pattern match delimiter even without a leading C<m>, didn't
you?)  You really need

  print "$X{'What ho?'}";

=back

The rule is simple: That thing in the braces that looks like a hash
key really is a hash key, and so you need to put it in quotes under
the same circumstances that you need to put any other hash key in
quotes.  You probably wouldn't expect this to work either:

  $V = $X{What ho?};


=head1 Author

=begin text

Originaly, Mark-Jason Dominus (C<mjd-perl-interpolation@plover.com>), Plover Systems co.
http://www.plover.com/~mjd/perl/Interpolation

Now maintained by, C<Jenda@Krynicky.cz> .
http://Jenda.Krynicky.cz/#Interpolation

=end text

=begin man

Originaly, Mark-Jason Dominus (C<mjd-perl-interpolation@plover.com>), Plover Systems co.
http://www.plover.com/~mjd/perl/Interpolation

Now maintained by, C<Jenda@Krynicky.cz> .
http://Jenda.Krynicky.cz/#Interpolation

=end man

=begin html

<p>Originaly, Mark-Jason Dominus (<a href="mailto:mjd-perl-interpolation@plover.com"><tt>mjd-perl-interpolation@plover.com</tt></a>), Plover Systems co.<BR/>
<a href="http://www.plover.com/~mjd/perl/Interpolation">http://www.plover.com/~mjd/perl/Interpolation</a></p>

Now maintained by, <a href="mailto:Jenda@Krynicky.cz">Jenda Krynicky</a>.<BR/>
<a href="http://Jenda.Krynicky.cz/#Interpolation">http://Jenda.Krynicky.cz/#Interpolation</a></p>

=end html


=cut


