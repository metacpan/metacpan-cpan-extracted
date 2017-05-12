package List::Maker;

our $VERSION = '0.005';

use warnings;
use strict;
use Carp;
use List::Util qw<shuffle sum>;

# Handle contextual returns
sub _context {
    # Return original list in list context...
    return @_ if (caller 1)[5];

    # Otherwise, Anglicize list...
    return ""                   if @_ == 0;
    return "$_[0]"              if @_ == 1;
    return "$_[0] and $_[1]"    if @_ == 2;

    my $sep = grep(/,/, @_) ? q{; } : q{, };
    return join($sep, @_[0..@_-2]) . $sep . "and $_[-1]";
}

# General filters that can be applied...
my %selector_sub = (
    pick => sub {
        return (shuffle @_)[0..shift()-1]
    },

    roll => sub {
        return map { $_[rand @_] } 1..shift;
    },

    all => sub {
        shift; return @_;
    },
);
# Regexes to parse the acceptable list syntaxes...
my $NUM      = qr{\s* [+-]? \d+ (?:\.\d*)? \s* }xms;
my $TO       = qr{\s* \.\. \s*}xms;
my $FILTER   = qr{ (?: : (?! \s* (?:pick|roll)) (.*?) )? }xms;
my $SELECTOR = qr{ (?: : \s* (pick|roll) \s* (\d*) )? \s* }xms;

# Mappings from specifications to handlers...
my @handlers = (
    # <1, 2 .. 10>
    { pat => qr{\A ($NUM) , ($NUM) ,? $TO (\^?) ($NUM) $FILTER $SELECTOR \Z}xms,
      gen => sub{ _gen_range({
                    from=>$1, to=>$4, by=>$2-$1, exto=>$3,
                    filter=>$5, selector => $6, count => $7,
                  })
             },
    },

    # <1 .. 10 by 2>
    { pat => qr{\A ($NUM) (\^?) $TO (\^?) ($NUM) (?:(?:x|by) ($NUM))? $FILTER $SELECTOR \Z}xms,
      gen => sub{ _gen_range({
                    from=>$1, to=>$4, by=>$5, exfrom=>$2, exto=>$3,
                    filter=>$6, selector => $7, count => $8,
                  });
             },
    },

    # <^7 by 2>
    { pat => qr{\A \s* \^ ($NUM) \s* (?:(?:x|by) \s* ($NUM))? $FILTER $SELECTOR \Z}xms,
      gen => sub{ _gen_range({
                    from=>0, to=>$1, by=>$2, exto=>1,
                    filter=>$3, selector => $4, count => $5,
                  });
             },
    },

    # <^@foo>
    { pat => qr{\A \s* \^ \s* ( (?:\S+\s+)* \S+) \s* \Z}xms,
      gen => sub{
                my $specification = $1;
                $specification =~ s{$SELECTOR \Z}{}x;
                my ($selector, $count) = ($selector_sub{$1||'all'}, $2||1);

                my @array = split /\s+/, $specification;
                $selector->($count, _gen_range( {from=>0, to=>@array-1}));
             },
    },

    # MINrMAX random range notation
    { pat => qr/^\s* ([+-]?\d+(?:[.]\d*)?|[.]\d+) \s* r \s* ([+-]?\d+(?:[.]\d*)?|[.]\d+) \s* $/xms,
      gen => sub {
        my ($min, $max) = ($1 < $2) ? ($1,$2) : ($2,$1);
        return $min + rand($max - $min);
      }
    },

    # NdS dice notation
    { pat => qr/^\s* (\d+(?:[.]\d*)?|[.]\d+) \s* d \s* (\d+(?:[.]\d*)?|[.]\d+) \s* $/xms,
      gen => sub {
        my ($count, $sides) = ($1, $2);

        # Non-integer counts require an extra random (partial) value...
        if ($count =~ /[.]/) {
            $count++;
        }

        # Generate random values...
        my @rolls = $sides =~ /[.]/ ? map { rand $sides} 1..$count
                  :                   map {1 + int rand $sides} 1..$count
                  ;

        # Handle a non-integer count by scaling final random (partial) value...
        if ($count =~ /([.].*)/) {
            my $fraction = $1;
            $rolls[-1] *= $fraction;
        }

        return @rolls if wantarray;
        return sum @rolls;
      }
    },

    # Perl 6 xx operator on 'strings'...
    { pat => qr/^ \s* ' ( [^']* ) ' \s* xx \s* (\d+) \s* $/xms,
      gen => sub {
        my ($string, $repetitions) = ($1, $2);
        return ($string) x $repetitions;
      }
    },

    # Perl 6 xx operator on "strings"...
    { pat => qr/^ \s* " ( [^"]* ) " \s* xx \s* (\d+) \s* $/xms,
      gen => sub {
        my ($string, $repetitions) = ($1, $2);
        return ($string) x $repetitions;
      }
    },

    # Perl 6 xx operator on numbers...
    { pat => qr/^ \s* ( [+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)? ) \s* xx \s* (\d+) \s* $/xms,
      gen => sub {
        my ($number, $repetitions) = ($1, $2);
        return (0+$number) x $repetitions;
      }
    },
);

my %caller_expecting_special_behaviour;
my @user_handlers;

# This does the magic...
my $list_maker_sub = sub {
    my ($listspec) = @_;

    # If it doesn't match a special form, it's a < word list >...
    for my $handler (@user_handlers, @handlers) {
        next if $listspec !~ m{$handler->{pat} }xms;
        return $handler->{gen}();
    }

    return _context _qww($listspec);
};

sub import {
    shift; # Don't need package name
    my $caller = caller;

    # Note lexical scope of import...
    $^H{'List::Maker::is_active'} = 1;

    # Explicit export(s) requested...
    if (@_) {
        for my $name (@_) {
            no strict 'refs';
            *{$caller.'::'.$name} = $list_maker_sub;
        }
    }

    # Otherwise use 'glob' (to provide magic behaviour as well)...
    else {
        my ($package, $file) = caller;

        # Get as close to lexical behavior as per-5.10 will allow...
        $caller_expecting_special_behaviour{ $package, $file } = 1;

        no strict 'refs';
        *{$caller.'::glob'} = \&_glob_replacement;
    }
}

# Users can add their own handlers...
sub add_handler {
    while (my ($regex, $sub) = splice @_, 0, 2) {
        croak "Usage: List::Make::add_handler(qr/.../, sub{...})\nError"
            if ref($regex) ne 'Regexp' || ref($sub) ne 'CODE';
        push @user_handlers, { pat=>$regex, gen=>$sub };
    }
    return;
}



# This sub is used instead of globs the special behaviours...
no warnings 'redefine';
sub _glob_replacement {
    # Don't be magical in those files that haven't loaded the module...
    my ($package, $file, $scope_ref) = (caller 0)[0,1,10];

    # Check for lexical scoping (only works in 5.10 and later)...
    my $in_scope = $] < 5.010 || $scope_ref && $scope_ref->{'List::Maker::is_active'};

    # If not being magical...
    if (!$caller_expecting_special_behaviour{$package, $file} || !$in_scope ) {
        # Use any overloaded version of glob...
        goto &CORE::GLOBAL::glob if exists &CORE::GLOBAL::glob;

        # Otherwise, use the core glob behaviour...
        use File::Glob 'csh_glob';
        return &csh_glob;
    }

    # Otherwise, be magical...
    else {
        goto &{$list_maker_sub};
    }
};

# Generate a range of values, selected or filtered as appropriate...
sub _gen_range {
    my ($from, $to, $incr, $filter, $exfrom, $exto, $selector, $count)
        = @{shift()}{ qw<from to by filter exfrom exto selector count> };

    # Trim leading and trailing whitespace from endpoints...
    s/^ \s+ | \s+ $//gxms for $from, $to;

    # Default increment is +/- 1, depending on end-points...
    if (!defined $incr) {
        $incr = -($from <=> $to);
    }

    # Default count is 1...
    $count ||= 1;

    # Check for nonsensical increments (zero or the wrong sign)...
    my $delta = $to - $from;
    croak sprintf "Sequence <%s, %s, %s...> will never reach %s",
        $from, $from+$incr, $from+2*$incr, $to
            if $incr == 0 && $from != $to || $delta * $incr < 0;

    # Generate unfiltered list of values...
    $from += $incr if $exfrom;
    my @vals;
    # <N..N>
    if ($incr==0) {
        @vals = $exto || $exfrom ? () : $from;
    }

    # <M..N>
    elsif ($incr>0) {
        while (1) {
            last if  $exto && ($from >= $to || $from eq $to)
                 || !$exto && $from > $to;
            push @vals, $from;
            $from += $incr;
        }
    }

    # <N..M>
    elsif ($incr<0) {
        while (1) {
            last if  $exto && ($from <= $to || $from eq $to)
                 || !$exto && $from < $to;
            push @vals, $from;
            $from += $incr;
        }
    }

    # Apply any filter before returning the values...
    if (defined $filter) {
        (my $trans_filter = $filter) =~ s/\b[A-Z]\b/\$_/g;
        @vals = eval "grep {package ".caller(2)."; $trans_filter } \@vals";
        croak "Bad filter ($filter): $@" if $@;
    }

    # Apply any selector before returning values...
    if (defined $selector) {
        @vals = $selector_sub{$selector}->($count, @vals);
    }

    return @vals;
};

# Simulate a Perl 6 <<...>> construct...
sub _qww {
    my ($content) = @_;

    # Strip any filter...
    $content =~ s{$SELECTOR \Z}{}x;
    my ($selector, $count) = ($selector_sub{$1||'all'}, $2||1);

    # Break into words (or "w o r d s" or 'w o r d s') and strip quoters...
    return $selector->( $count,
            grep { defined($_) }
                    $content =~ m{ " ( [^\\"]* (?:\\. [^\\"]*)* ) "
                                 | ' ( [^\\']* (?:\\. [^\\']*)* ) '
                                 |   ( \S+                      )
                                 }gxms
    );
}


1; # Magic true value required at end of module
__END__

=head1 NAME

List::Maker - Generate more sophisticated lists than just $a..$b


=head1 VERSION

This document describes List::Maker version 0.005


=head1 SYNOPSIS

    use List::Maker;

    @list = <1..10>;                      # (1,2,3,4,5,6,7,8,9,10)

    @list = <10..1>;                      # (10,9,8,7,6,5,4,3,2,1)

    @list = <1,3,..10>;                   # (1,3,5,7,9)
    @list = <1..10 x 2>;                  # (1,3,5,7,9)

    @list = <0..10 : prime N>;            # (2,3,5,7)
    @list = <1,3,..30  : /7/>;            # (7,17,27)

    @list = < ^10 >;                      # (0,1,2,3,4,5,6,7,8,9)
    @list = < ^@array >;                  # (0..$#array)

    @words = < a list of words >;         # ('a', 'list', 'of', 'words')
    @words = < 'a list' "of words" >;     # ('a list', 'of words')


    use List::Maker 'listify';
    @list = listify '1..10';              # (1,2,3,4,5,6,7,8,9,10)

    use List::Maker 'make_list';
    @list = make_list '10..1';            # (10,9,8,7,6,5,4,3,2,1)

    use List::Maker 'ql';
    @list = ql'1..10 x 2';                # (1,3,5,7,9)


=head1 DESCRIPTION

The List::Maker module hijacks Perl's built-in file globbing syntax
(C<< < *.pl > >> and C<glob '*.pl'>) and retargets it at list creation.

The rationale is simple: most people rarely if ever glob a set of files,
but they have to create lists in almost every program they write. So the
list construction syntax should be easier than the filename expansion syntax.

Alternatively, you can load the module with an explicit name, and it creates a
subroutine of that name that builds the same kinds of lists for you (leaving
the globbing mechanism unaltered).

=head1 INTERFACE

Within any file in which the module has been explicitly loaded:

    use List::Maker;

angle brackets no longer expand a shell pattern into a list of files.
Instead, they expand a list specification into a list of values.

Under Perl 5.10 and later the module is also lexically scoped in its
effects. That is, under Perls that support it, the change in the
behaviour of angle brackets is confined to the specific
lexical scope into which the module was imported.

Under Perl 5.8 and earlier, loading the module changes the effect
of C<< <...> >> and C<glob()> for the remainder of the current
package in the current file.

This means:

    # Code                  Under 5.8 or earlier    Under 5.10 or later
    ====================    ====================    ===================
    @list = <1..10>;        normal glob()           normal glob()
    {
        use List::Maker;    installs in file        installs in block
        @list = <1..10>;    generates list          generates list
    }
    @list = <1..10>;        generates list          normal glob()


=head2 Numeric lists

Numeric list specifications may take any of the following forms:

    Type           Syntax                  For example     Produces
    ==========     ===================     ===========     ===========
    Count up       <MIN..MAX>              <1..5>          (1,2,3,4,5)
    Count down     <MAX..MIN>              <5..1>          (5,4,3,2,1)
    Count to       < ^LIMIT >              < ^5 >          (0,1,2,3,4)
    Count by       <START..END x STEP>     <1..10 x 3>     (1,4,7,10)
    Count via      <START, NEXT,..END>     <1, 3,..10>     (1,3,5,7,9)

The numbers don't have to be integers either:

    @scores = <0.5..4.5>;      # same as: (0.5, 1.5, 2.5, 3.5, 4.5)

    @steps = <1..0 x -0.2>;    # same as: (1, 0.8, 0.6, 0.4, 0.2, 0)


=head2 Filtered numeric lists

Any of the various styles of numeric list may also have a filter applied
to it, by appending a colon, followed by a boolean expression:

    @odds   = <1..100 : \$_ % 2 != 0 >;

    @primes = <3,5..99> : is_prime(\$_) >;

    @available = < ^$max : !allocated{\$_} >

    @ends_in_7 = <1..1000 : /7$/ >

The boolean expression is tested against each element of the list, and
only those for which it is true are retained. During these tests each
element is aliased to C<$_>. However, since angle brackets interpolate,
it's necessary to escape any explicit reference to C<$_> within the
filtering expression, as in the first three examples above.

That often proves to be annoying, so the module also allows the
candidate value to be referred to using any single uppercase letter
(which is replaced with C<\$_> when the filter is applied. So the
previous examples could also be written:

    @odds   = <1..100 : N % 2 != 0 >;

    @primes = <3,5..99> : is_prime(N) >;

    @available = < ^$max : !allocated{N} >

or (since the specific letter is irrelevant):

    @odds   = <1..100 : X % 2 != 0 >;

    @primes = <3,5..99> : is_prime(I) >;

    @available = < ^$max : !allocated{T} >


=head2 Randomly selecting from lists

In addition to (or instead of) specifying a filter on a list,
you can also select a specific number of the list's items
at random, by appending C<:pick> I<N> to the list specification.

For example:

    $N_random_percentages = <0..100 : pick $N >;

    @any_three_primes = <3,5..99> : is_prime(I) : pick 3>;

    $one_available = < ^$max : !allocated{T} :pick>

The requested number of elements are picked at random, and without
replacement. If the number of elements to be picked is omitted,
a single element is randomly picked.

You can also pick I<with> replacement (which is equivalent to rolling
some number of M-sided dice, with one list element on each face), by
using C<:roll> instead of C<:pick>:

    $N_nonunique_random_percentages = <0..100 : roll $N >;

    @three_nonunique_primes = <3,5..99> : is_prime(I) : roll 3>;

    $one_available = < ^$max : !allocated{T} :roll>

If the number of elements to be rolled is omitted, a single element is
randomly rolled (which is exactly the same as randomly picking it).

Note that, because each requested "roll" is independent, it's entirely
possible for one or more values to be selected repeatedly.


=head2 String lists

Any list specification that doesn't conform to one of the four pattern
described above is taken to be a list of whitespace-separated strings,
like a C<qw{...}> list:

    @words = <Eat at Joe's>;     # same as: ( 'Eat', 'at', 'Joe\'s' )

However, unlike a C<qw{...}>, these string lists interpolate (before
listification):

    $whose = q{Joe's};

    @words = <Eat at $whose>;    # same as: ( 'Eat', 'at', 'Joe\'s' )

More interestingly, the words in these lists can be quoted to change the
default whitespace separation. For example:

    @names = <Tom Dick "Harry Potter">;
                        # same as: ( 'Tom', 'Dick', 'Harry Potter' )

Single quotes may be also used, but this may be misleading, since the
overall list still interpolates in that case:

    @names = <Tom Dick '$Harry{Potter}'>;
                        # same as: ( 'Tom', 'Dick', "$Harry{Potter}" )

In a scalar context, any string list is converted to the standard
English representation:

    $names = <Tom>;                       # 'Tom'
    $names = <Tom Dick>;                  # 'Tom and Dick'
    $names = <Tom Dick 'Harry Potter'>;   # 'Tom, Dick, and Harry Potter'


=head2 Perl 6 repetition list operator

List::Maker also understands the Perl 6 C<xx> listification operator:

    @affirmations = <'aye' xx 5>;         # ('aye','aye','aye','aye','aye')


=head2 Random number generation

The module understands two syntaxes for generating random numbers. It can
generate a random number within a range:

    $random = < 2r5.5 >;     # 2 <= Random number < 5.5


It can also generate an "NdS" dice roll (i.e. the sum of rolling N dice, each
with S sides):

    $roll = < 3d12 >;        # Sum of three 12-sided dice

The dice notation cares nothing for the laws of physics or rationality
and so it will even allow you to specify a non-integer number of
"fractal dice", each with an non-integer numbers of sides:

    $roll = < 3.7d12.3 >;    # Sum of three-point-seven 12.3-sided dice

In a list context, the dice notation returns the results of each of the
individual die rolls (including the partial result of a "fractal" roll)

    @rolls = < 3d12 >;       # (6, 5, 12)
    @rolls = < 3.7d12.3 >;   # (6.1256, 5.9876, 12.0012, 0.3768)

The values returned in list context will always add up to the value that would
have been returned in a scalar context.


=head2 User-defined syntax via C<add_handler>

You can add new syntax variations to the C<< <...> >> format using the
C<add_handler()> function:

    add_handler($pattern => $sub_ref, $pattern => $sub_ref...);

Each pattern is added to the list of syntax checkers and, if it
matches, the corresponding subroutine is called to furnish the result
of the C<< <...> >>. User-defined handlers are tested in the same order
that they are defined, but I<before> the standard built-in formats
described above.


=head1 ALTERNATE INTERFACE

If an argument is passed to the C<use List::Maker> statement, then that
argument is used as the name of a subroutine to be installed in the current
package. That subroutine then expects a single argument, which may be used to
generate any of the lists described above.

In other words, passing an argument to C<use List::Maker> creates an explicit
list-making subroutine, rather than hijacking the built-in C<< <..> >> and
C<glob()>.

For example:

    use List::Maker 'range';

    for (range '1..100 x 5') {
        print "$_: $result{$_}\n";
    }


    use List::Maker 'roll';

    if (roll '3d12' > 20) {
        print "The $creature hits you\n";
    }


    use List::Maker 'conjoin';

    print scalar conjoin @names;


=head1 DIAGNOSTICS

=over

=item C<< Sequence <%s, %s, %s...> will never reach %s >>

The specified numeric list didn't make sense. Typically, because you
specified an increasing list with a negative step size (or vice versa).

=back


=head1 CONFIGURATION AND ENVIRONMENT

List::Maker requires no configuration files or environment variables.


=head1 DEPENDENCIES

None.


=head1 INCOMPATIBILITIES

Using this module normally prevents you from using the built-in
behaviours of C<< <...> >> or C<glob()> in any files that directly
C<use> the module (though files that don't load the module are
unaffected). In files that use the module, you would need to use the
C<File::Glob> module directly:

    use File::Glob;

    my @files = bsd_glob("*.pl");

Alternatively, export the list maker by name (see L<"ALTERNATE INTERFACE">).


=head1 BUGS AND LIMITATIONS

The lists generated are not lazy. So this:

    for (<1..10000000>) {
        ...
    }

will be vastly slower than:

    for (1..10000000) {
        ...
    }



Please report any bugs or feature requests to
C<bug-list-maker@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@CPAN.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, Damian Conway C<< <DCONWAY@CPAN.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
