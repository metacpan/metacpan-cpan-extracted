package Lexical::Attributes;

use 5.008001;

use strict;
use warnings;
no  warnings 'syntax';
use Filter::Simple;
use Scalar::Util;

our $VERSION  = '2009121601';

my $sigil     = '[$@%]';
my $sec_sigil = '[.]';
my $trait     = '(?:r[ow]|pr(?:iv)?)';        # read-only, read-write, private.
my $name      = qr /[a-zA-Z_][a-zA-Z0-9_]*/;  # Starts with alpha or _, followed
                                              # by one or more alphanumunders.
my $has_attribute = qr /(?>$sigil$sec_sigil$name)/;
my $use_attribute = qr /(?>(?:\$#?|[%\@])$sec_sigil$name)/;
my $int_attribute = qr /(?>(?:\$#?|\@)$sec_sigil$name)/;  # No hash.

my %attributes;

sub declare_attribute {
    my ($attributes, $trait) = @_;

    $trait = "pr" if !$trait || $trait eq "priv";

    my $text = "";

    foreach my $attribute (split /\s*,\s*/ => $attributes) {

        my ($sigil, $sec_sigil, $name) = unpack "A A A*" => $attribute;
        my $str = "";

        if ($attributes {$name}) {
            warn "Duplicate attribute '$attribute' ignored\n";
            next;
        }

        $attributes {$name} = [$sigil, $trait];

        $str .= "my %$name;";
        unless ($trait eq "pr") {
            if ($sigil eq '$') {
                $str .= <<'                --';
                sub _NAME {
                    my $_key = Scalar::Util::refaddr shift;
                    $_NAME {$_key}
                }
                --
            }
                  # @_ ? @{$_NAME {$_key}} [@_] : @{$_NAME {$_key}};
            elsif ($sigil eq '@') {
                $str .= <<'                --';
                sub _NAME {
                    my $_key = Scalar::Util::refaddr shift;
                    @_ ? @{$_NAME {$_key}} [@_] : @{$_NAME {$_key} || []};
                }
                --
            }
            elsif ($sigil eq '%') {
                $str .= <<'                --';
                sub _NAME {
                    my $_key = Scalar::Util::refaddr shift;
                    @_        ?      @{$_NAME {$_key}} {@_}  : 
                    wantarray ?      %{$_NAME {$_key} || {}} :
                                keys %{$_NAME {$_key} || {}};
                }
                --
            }
            else {
                die "'$attribute' not implemented\n";
            }

            if ($trait eq "rw") {
                if ($sigil eq '$') {
                    $str .= <<'                    --';
                    sub set__NAME {
                        my $self = shift;
                        my $_key = Scalar::Util::refaddr $self;
                        $_NAME {$_key} = shift;
                        $self;
                    }
                    --
                }
                elsif ($sigil eq '@') {
                    $str .= <<'                    --';
                    sub set__NAME {
                        my $self = shift;
                        my $_key = Scalar::Util::refaddr $self;
                        if    (@_ == 0) {delete $_NAME {$_key}}
                        elsif (@_ == 1) {
                            if (ref $_ [0] eq 'ARRAY') {$_NAME {$_key} = $_ [0]}
                            else {delete $_NAME {$_key} [$_ [0]]}
                        }
                        else {
                            while (@_ >= 2) {
                                my ($index, $value) = splice @_ => 0, 2;
                                $_NAME {$_key} [$index] = $value;
                            }
                        }
                        $self;
                    }
                    --
                }
                elsif ($sigil eq '%') {
                    $str .= <<'                    --';
                    sub set__NAME {
                        my $self = shift;
                        my $_key = Scalar::Util::refaddr $self;
                        if    (@_ == 0) {delete $_NAME {$_key}}
                        elsif (@_ == 1) {
                            if (ref $_ [0] eq 'HASH') {$_NAME {$_key} = $_ [0]}
                            else {delete $_NAME {$_key} {$_ [0]}}
                        }
                        else {
                            while (@_ >= 2) {
                                my ($key, $value) = splice @_ => 0, 2;
                                $_NAME {$_key} {$key} = $value;
                            }
                        }
                        $self;
                    }
                    --
                }
            }
        }
        $str =~ s/\n\s*/ /g;
        $str =~ s/_NAME/$name/g;

        $text .= $str;
    }
    
    return $text;
}

sub destroy_attributes {
    my $str = "";
    while (my ($key) = each %attributes) {
        $str .= "delete \$$key {Scalar::Util::refaddr \$self};\n";
    }
    $str;
}

sub use_attribute {
    my ($attribute) = @_;

    my ($sigil, $name) = split /[.]/ => $attribute, 2;

    if (!$attributes {$name}) {
        die $_;
        die qq !Attribute "$attribute" requires declaration!;
    }

    my $str;
    if ($sigil eq '$') {
        $str = "\$$name\{Scalar::Util::refaddr \$self}";
    }
    else {
        $str = "$sigil\{\$$name\{Scalar::Util::refaddr \$self}}";
    }
    $str;
}

sub interpolate {
    local $_ = shift;

    # The regex below finds attribute names. We cannot simply use a
    # regex for finding them, we need to parse the entire string, to
    # be able to deal with backslashes.
    #
    # We use loop unrolling for efficiency.
    #
    s {(                     # Capture non attributes in $1.
           [^\$\@\\]*            # Anything that isn't $, @ or \ is ok.
           (?:                   # Group (1)
               (?:                   # Group (2) ("Special things")
                   \\.                   # Escape followed by any character
                   |                     # or
                   (?:                   # Group (3)
                       (?:>\$\#?)            # Scalar sigil, or array count
                                             # The (?> ) is vital here.
                       |                     # Or
                       \@                    # Array sigil
                   )                     # End group (3)
                   (?!\.$name)           # not followed by dot attribute name
               )                     # End group (2)
               [^\$\@\\]*            # Anything that isn't $, @ or \
           )*                    # End group (1), repeated zero or more times.
       )                     # End capture $1
       |                     # Or
       (                     # In $2, capture an attribute
           (?:(?>\$\#?)|\@)      # Primary sigil
           \.$name               # dot attribute name
       )                     # End $2
    }
    {defined $1 ? $1 : use_attribute ($2)}sexg;

    $_
}

FILTER_ONLY 
    #
    # Initialize variables.
    #
    all   => sub {%attributes = ()},

    #
    # Save all attributes found in comments. *Very* simple heuristics
    # to determine comments - note that quote like constructs have been
    # moved out of the way.
    #
    # Moving away the attributes found in comments prevents subsequent
    # passes to modify them. In particular, outcommented attribute
    # declarations shouldn't create methods or hashes. 
    #
    code => sub {
        1 while s/(                   # Save
                    (?<!$sigil)       # Not preceeded by a sigil
                    \#                # Start of a comment.
                    [^\n]*            # Not a newline, not an attribute,
                    (?: $sigil (?!$sec_sigil) [^\n]*)*
                                      # using standard unrolling.
                  ) ($sigil) ($sec_sigil) ($name)
                 /$1$2<$3>$4/xg;
    },

    #
    # Find the attribute declarions and uses. Foreach declararion, the sub
    # 'attribute' is called, which will create an attribute hash,
    # and, for non-private attributes, a constructor (which maybe
    # an lvalue method if the rw trait is given).
    #
    # We recognize:
    #    "has"     [$@%].attribute ( ("is")? "pr(iv)?|ro|rw")? ";"
    #    "has" "(" [$@%].attribute ("," [$@%].attribute)* ")" \
    #                              ( ("is")? "pr(iv)?|ro|rw")? ";"
    #
    # Other attribute usages are just:
    #             ([$@%]|$#).attribute
    #
    # Attribute uses are handled by calling 'use_attribute'.
    #
    code  => sub {
        s{(?:                    # Declaration using 'has',
            \bhas \s*                       # Must start with "has"
             (?:                            # Either 
                      ($has_attribute)      #   a single ttribute, stored in $1.
               |                            # or
              [(] \s* ($has_attribute (?: \s* , \s* $has_attribute)*) \s* [)]
                                            #   an attribute list, stored in $2.
             )
             (?: \s* (?:is \s+)? ($trait))? # Optional trait - stored in $3.
             \s* ;                          # Terminated by semi-colon.
          ) |                    # or actual usage.
           ($use_attribute)                 # It's in $4.
         }
         {$4 ? use_attribute ($4) : declare_attribute ($1 || $2, $3)}egx;
    },

    #
    # Interpolation. Double quoted strings, backticks, slashes and q[qrx] {},
    # m// and s/// constructs.
    #
    # Note that '', qw{}, tr///, m'' and s''' don't interpolate.
    #
    # How to test qx?
    #
    quotelike => sub {
        if (m {^(["`/]|q[qrx]\s*\S|[sm]\s*[^\s'])(.*)(\S)$}s) {
            $_ = $1 . interpolate ($2) . $3
        }
    },

    #
    # If a subroutine uses the keyword 'method' (at the beginning of
    # a line), add an assignment to '$self'.
    #

    code => sub {
        s<^(\s*) method (\s+ [a-zA-Z_]\w* \s*     # sub name
            (?:\([^)]*\) \s*)?                    # Optional prototype
            \{)                                   # Opening of block
         ><$1 sub $2 my \$self = shift;>mgx;
    },

    #
    # Add a DESTROY function
    #
    code => sub {
        my $destroy = <<'        --';

        sub DESTROY {
            our @ISA;
            my  $self     = shift;
            my  $DESTRUCT = __PACKAGE__ . "::DESTRUCT";
            $self -> $DESTRUCT if do {no strict 'refs'; exists &$DESTRUCT};
            DESTROY_ATTRIBUTES;
            foreach my $class (@ISA) {
                my $destroy = $class . "::DESTROY";
                $self -> $destroy if $self -> can ($destroy);
            }
        }
        --

        my $destroy_attributes = destroy_attributes;

        $destroy  =~ s/DESTROY_ATTRIBUTES/$destroy_attributes/;
        $destroy  =~ s/^ {8}//gm;

        $_ .= $destroy;
    },

    #
    # Restore tucked away, outcommented, attributes.
    #
    code => sub {
        1 while s/(                   # Save
                    (?<!$sigil)       # Not preceeded by a sigil
                    \#                # Start of a comment.
                    [^\n]*            # Not a newline, not an attribute,
                    (?: $sigil (?!<$sec_sigil>) [^\n]*)*
                                      # using standard unrolling.
                  ) ($sigil) <($sec_sigil)> ($name)
                 /$1$2$3$4/xg;
    },

    #
    # For debugging purposes; to be removed.
    #
    # all   => sub {print "<<$_>>\n" if $::DEBUG || $ENV {DEBUG}},

;

__END__

=head1 NAME

Lexical::Attributes - Proper encapsulation

=head1 SYNOPSIS

    use Lexical::Attributes;

    has $.scalar;
    has $.key ro;
    has (@.array, %.hash) is rw;

    sub method {
        $self -> another_method;
        print $.scalar;
    }

=head1 DESCRIPTION

B<NOTE>: This module has changed significantly between releases 1.3 and
1.4. Code that works with version 1.3 or earlier I<will not> work with
version 1.4 or later.

B<NOTE>: This is experimental software! Certain things will change, 
specially if they are marked B<FIXME> or mentioned on the B<TODO>
list.

This module was created out of frustration with Perl's default OO 
mechanism, which doesn't offer good data encapsulation. I designed
the technique of I<Inside-Out Objects> several years ago, but I was
not really satisfied with it, as it still required a lot of typing.
This module uses a source filter to hide the details of the Inside-Out
technique from the user.

Attributes, the variables that belong to an object, are stored in lexical
hashes, instead of piggy-backing on the reference that makes the object.
The lexical hashes, one for each attribute, are indexed using the object.
However, the details of this technique are hidden behind a source filter.
Instead, attributes are declared in a similar way as lexical variables.
Except that instead of C<my>, a Perl6 keyword, C<has> is used. Another 
thing is borrowed from Perl6, and that's the second sigil. Attributes 
have a dot separating the sigil from the name of attribute.

=head2 Attributes

To declare an attribute, use the Perl6 keyword C<has>. The simplest way to
declare an attribute is:

    has $.colour;    # Gives the object a 'colour' attribute.

Now your object has an attribute I<colour>. Note the way the attribute is
written, in a Perl6 style, it has the sigil (a C<$>), a period, and then
the attribute name. Attribute names are strings of letters, digits and 
underscores, and cannot start with a digit. Attribute names are case-sensitive.
You can use this attribute in the same way as a normal Perl scalar (except
for interpolation). Here's a sub that prints out the colour of the object:

    sub print_colour {
        print $.colour;
    }

Array and hash attributes work in a similar way:

    has @.array;   # Gives the object an array attribute.
    has %.hash;    # Gives the object a hash attribute.

And you can use them in a similar way as you can with "normal" Perl variables:

    sub first_element {
        return $.array [0];
    }

    sub pop_element {
        return pop @.array;
    }

    sub last_index {
        return $#.array;
    }

    sub gimme_key {
        my $key = shift;
        return $.hash {$key};
    }

    sub gimme_all_keys {
        return keys %.hash;
    }

Note however that you I<cannot> have a scalar and an array (or a scalar 
and a hash, or an array and a hash) with the same name. Using both
C<has $.key;> and C<has @.key;> will result in a warning, and the second
(and third, fourth, etc) declaration of the attibute will be B<ignored>.

If you have several attributes you want to declare, you can use C<has>
in a similar way as you can C<my> and C<local>. C<has> takes a list as
argument as well (parenthesis are required):

    has ($.key1, @.key2, %.key3);

Note that the declaration, that is, the C<has> keyword followed by an 
attribute, or a list of attributes, can be followed by an optional
I<trait> (as discussed below), B<must> be followed by a semi-colon
(after optional whitespace). The following will not work:

    has $.does_not_work = 1;

=head3 Traits

Since inspecting and setting the attributes of an object is a commonly
requested action, it's possible to give the attributes I<traits> that
will achieve this. Traits are given by following the C<has> declaration
with the keyword C<is> and the name of the trait (with the keyword being
optional). Examples include:

    has $.get_set is rw;
    has $.get ro;
    has (@.array, %.hash) is priv;   # Trait applies to both attributes.

The following traits can be given:

=over 5

=item C<pr> or C<priv>

Using C<pr> or C<priv> has the same effect as not giving any traits,
no accessor for this attribute is generated.

=item C<ro>

This trait generates an accessor for the attribute, with the same name
as the attribute.

For scalar attributes, calling the accessor returns the value of the
attribute.  Any parameters given to the accessor will be ignored.

 package MyObject;
 use Lexical::Attributes;

 has $.colour is ro;

 sub new {bless \do {my $obj} => shift}
 sub some_sub {
     ...  # Some code that sets the 'colour' attribute.
 }

 1;

 # Main program

 my $obj = MyObject -> new;
 $obj -> some_sub (...);
 print $obj -> colour;   # Prints the colour.

 __END__

Accessors for arrays and hashes take optional arguments. If no arguments
are given, the accessor will return the array or hash in list context 
(as a list - just as if you'd use an array or hash in list context). In 
scalar context, the number of elements of the array or hash are returned.

If one or more arguments are given, the corresponding arguments are returned.
Some examples:

 package MyObject;
 use Lexical::Attributes;

 has @.colours is ro;
 has %.fruit   is ro;

 sub new  {bless \do {my $obj} => shift}
 method init {  # See below for discussion of 'method'.
     @.colours = qw /red white blue green yellow/;
     %.fruit   = (cherry  =>  'red',
                  peach   =>  'pink',
                  apple   =>  'green',
     );
     $self;
 }

 1;

 # Main program

 my $obj  = MyObject -> new -> init;

 local $, = " ";

 print $obj -> colours;         # red white blue green yellow
 print $obj -> colours (2);     # blue
 print $obj -> colours (1, 3);  # white green

 print sort $obj -> fruit;      # apple cherry green peach pink red
 print $obj -> fruit ('cherry');        # red
 print $obj -> fruit ('apple', 'peach') # green pink

 __END__

=item C<rw>

Attributes with the C<rw> trait have two accessors generated for them.
One accessor, with the same name as the attribute is used to fetch the
value - it's identical to the accessor discussed at above, for C<ro>
attributes. The second accessor is used to store values; its name will
be the name of the attribute, prepended by C<set_>.

For scalar values, calling the setting accessor sets the attribute to
the first argument. Any other argument are ignored.

 package MyObject;
 use Lexical::Attributes;

 has $.name is rw;
 sub new {bless \do {my $var} => shift}

 1;

 # Main program
 my $obj = MyObject -> new;
 $obj -> set_name ("Abigail");

 print $obj -> name;   # Prints 'Abigail'.

 __END__

For aggregates, the situation is a bit more complex. There are four
possibilities:

=over 4

=item No arguments

If the settable accessor was called without arguments, the array or hash
this accessor is associated with is cleared - that is, set to an empty
array or hash.

=item One argument, a reference of the appropriate type

If one argument is given, and the argument is a reference of the appropriate
type (a reference to an array for array attributes, and a reference to a
hash for hash attributes), the array or hash is set to the given argument.
Note that the actual reference is stored - no copies are made.

=item One argument, not a reference of the appropriate type

In this case, the argument is taken to be an index in the array or hash
(so, for array attributes, the argument is cast to an integer if necessary,
and to a string for hash attributes), and the corresponding element is
deleted, in a similar way C<delete> is called on regular arrays and hashes.
Note that for arrays, C<deleting> something that's in the middle of the 
array doesn't cause the array to shrink - the element is just undefined.

=item More than one argument

Then it's assumed a list of key (or index)/value pairs are given. Values
are set to the corresponding keys or indices. Arrays and hashes will grow
if needed.

=back

 package MyObject;
 use Lexical::Attributes;

 has @.colours is rw;
 has %.fruit   is rw;

 sub new {bless \do {my $obj} => shift}

 1;

 # Main program.

 my $obj = MyObject -> new;

 local $, = " ";

 # Set the colours to a specific array.
 $obj -> set_colours (['red', 'white', 'blue']);
 print $obj -> colours;      # 'red white blue'.
 print $obj -> colours (1);  # 'white'.

 # Change colour on index 1.
 $obj -> set_colours (1, 'yellow');
 print $obj -> colours;      # 'red yellow blue'.

 # Change/add multiple colours.
 $obj -> set_colours (1, 'green', 3, 'brown');
 print $obj -> colours;      # 'red green blue brown'.

 # Delete colour on index 3.
 $obj -> set_colours (3);
 print $obj -> colours;      # 'red green blue'.

 # Clear the array.
 $obj -> set_colour;
 print $obj -> colours;      # Nothing, array is empty.


 # Set the fruits to a specific hash.
 $obj -> set_fruit ({apple => 'green', cherry => 'red',
                     peach => 'pink'});
 print $obj -> fruit;        # 'apple green peach pink cherry red'.
 print $obj -> fruit ("apple");  # 'green'.

 # Change the colour of the apple.
 $obj -> set_fruit (apple => 'yellow');
 print $obj -> fruit;        # 'apple yellow peach pink cherry red'.

 # Change/add multiple fruits.
 $obj -> set_fruit (apple => 'red', lemon => 'yellow');
 print $obj -> fruit;        # 'apple red peach pink
                             #  cherry red lemon yellow'.

 # Delete a fruit
 $obj -> set_fruit ("peach");
 print $obj -> fruit;        # 'apple red cherry red lemon yellow'.

 # Delete all fruits.
 $obj -> set_fruit;
 print $obj -> fruit;        # Nothing, hash is empty.

All settable accessors return the object, regardless of the number or
types of arguments. This gives the caller the option of chaining modifications:

 my $obj = Class -> new
                 -> set_age (25)
                 -> set_name ("Jane Doe")
                 -> set_hair_colour ("auburn");

=back

=head2 Methods

In order for the module to access the attributes, it needs access to
the variable holding the current object. It will assume this variable
is called C<$self>. This is not likely to be a problem, as it seems
to be quite common to name the variable holding the current object
C<$self>.

To further add the programmer, if a subroutine uses the keyword C<method>
instead of C<sub>, it will have a variable called C<$self>, in which the
first element of C<@_> is shifted. Essentially, the line C<my $self = shift;>
is prepended to the body of the subroutine.

Subroutines that do not use the keyword C<method> are left as is - these
subroutines are typically reserved for class methods, or private subroutines.

Examples:

    # Don't need to declare $self.
    sub my_method {
        $.attribute + $self -> other_method;
    }

If you do not use the C<method> keyword, you do not put the current object
into a variable called C<$self>, and you use one of the lexical attributes,
your code is unlikely to work.

=head2 DESTROY

Since the attributes are stored in lexical hashes, attributes do not get
garbage collected via a reference counting mechanism when the object goes
out of scope. In order to clean up attribute data, action triggered by 
the call of C<DESTROY> is needed. Hence, this module will insert a C<DESTROY>
subroutine which will take care of cleaning up the attribute data. It
will also propagate calling C<DESTROY> methods in any inherited classes.

If you want to do any other action you'd normally put into C<DESTROY>, 
create a method called C<DESTRUCT>. This method will be called on when
the object goes out of scope. The method will be called before attributes
values have been cleaned up. There is no need to manually call C<DESTRUCT>
in inherited classes, as C<Lexical::Attributes> will do that for you. In
fact, calling C<DESTRUCT> in a super class yourself is likely to cause
unwanted effects, because that will mean C<DESTRUCT> in a superclass is
called more than once.

=head2 Inheritance

Inheritance just works. Classes using this technique require I<nothing>
from their super class implementation, and demand I<nothing> from the
classes that will inherit them. Super classes can use this technique, or
traditional hash based objects, or something else entirely. And it's
the same for classes that will inherit our classes.

=head2 Interpolation

Interpolation of scalars and array is possible in C<"">, C<``>, C<//>, C<m//>,
C<s///>, C<qq {}> C<qr {}>, and C<qx {}> strings. There's no interpolation
in C<''>, C<m''>, C<s'''>, C<tr//> nor in C<qw {}> strings.

=head2 Overloading

Overloading of objects should work in the same way as other types of objects.

=head1 TODO

=over 4

=item o

Compiling a module is slow. This is probably caused by FILTER_ONLY being slow.

=item o

Consider more traits. Methods for pop/push/shift/unshift for arrays, and 
keys/values/each for hashes would be useful. So are getting/setting keys
by index.

=back

=head1 DEVELOPMENT
 
The current sources of this module are found on github,
L<< git://github.com/Abigail/lexical--attributes.git >>.

=head1 AUTHOR

Abigail, L<< mailto:lexical-attributes@abigail.be >>.

=head1 COPYRIGHT and LICENSE
 
This program is copyright 2004, 2005, 2009 by Abigail.
 
Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:
     
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=head1 INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

=cut

