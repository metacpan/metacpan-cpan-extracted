=head1 NAME

Devel::GDB::Reflect - Reflection API for GDB/C++

=head1 SYNOPSIS

  use Devel::GDB;
  use Devel::GDB::Reflect;

  my $gdb = new Devel::GDB( -file => $foo );
  my $reflector = new Devel::GDB::Reflect( $gdb );

  print $gdb->get( "b foo.c:123" );
  $gdb->print( "myVariable" );

=head1 DESCRIPTION

Devel::GDB::Reflect provides a reflection API for GDB/C++, which can
be used to recursively print the contents of STL data structures
(C<vector>, C<set>, C<map>, etc.) within a GDB session.  It is not
limited to STL, however; you can write your own delegates for printing
custom container types.

The module implements the functionality used by the L<gdb++> script, which
serves as a wrapper around GDB.  You should probably familiarize yourself with
the basic functionality of this script first, before diving into the gory
details presented here.

=head2 Global Variables

The following global variables control the behavior of the L</"print"> method.

=over

=item $Devel::GDB::Reflect::INDENT

The number of spaces to indent at each level of recursion.  Defaults to 4.

=item $Devel::GDB::Reflect::MAX_DEPTH

The maximum recursion depth.  Defaults to 5.

=item $Devel::GDB::Reflect::MAX_WIDTH

The maximum number of elements to show from a given container.  Defaults to 10.

=back

=head2 Methods

=cut

package Devel::GDB::Reflect;

use warnings;
use strict;

use Devel::GDB::Reflect::GDBGrammar;
use Devel::GDB::Reflect::PrettyPrinter;
use Data::Dumper;
use Devel::GDB;

our $VERSION   = '0.2';
our $MAX_DEPTH = 5;
our $MAX_WIDTH = 10;
our $INDENT    = 4;

sub load_delegates()
{
	my @insts = ();

	my $DELEGATE_NAMESPACE = __PACKAGE__ . "::DelegateProvider";
	(my $DELEGATE_SUBDIR   = $DELEGATE_NAMESPACE) =~ s!::!/!g;

	foreach my $root_dir (@INC)
	{
		my $dir = "$root_dir/$DELEGATE_SUBDIR";

		opendir(DIR, $dir) or next;
		my @delegate_providers = grep { /\.pm$/ && -f "$dir/$_" } readdir(DIR);
		closedir(DIR);

		foreach my $file (@delegate_providers)
		{
			die "Something wrong here: \$file = $file"
				unless $file =~ /^(.+)\.pm$/;

			my $modname = "${DELEGATE_NAMESPACE}::$1";

			require "$dir/$file";
			my $inst = eval "new $modname"
				or do { warn "Can't instantiate $modname; skipping"; next };

			print STDERR " => $modname\n";

			push @insts, $inst;
		}
	}

	return \@insts;
}

=head3 new

Create a new Devel::GDB::Reflect instance.  Takes a single parameter, an
instance of C<Devel::GDB>.

When the constructor is invoked, it searches C<@INC> for modules named
C<Devel::GDB::Reflect::DelegateProvider::*>, and recruits them as delegates.  See
L</"Delegates">.

=cut

sub new($$)
{
	my $class = shift;
	my ($gdb) = @_;

	return bless
		{
			parser             => new Devel::GDB::Reflect::GDBGrammar(),
			gdb                => $gdb,
			class_cache        => {},
			delegate_cache     => {},
			delegate_providers => load_delegates(),
		};
}

=head3 print

C<< $reflector->print( "myVar" ); >>

Given a variable or expression, recursively print the contents of the referenced
container.  Specifically, this checks the type of the variable, iterates over
the L<delegates|/"Delegates"> to determine the best one, then uses that delegate
to print out the contents of the container.

The recursion is limited by C<$MAX_DEPTH>, and for each container, the number of
elements is limited by C<$MAX_WIDTH>.

=cut

sub print($$)
{
	my $self = shift;
	my ($var) = @_;

	$Devel::GDB::Reflect::PrettyPrinter::PAD = " " x $INDENT;
	$self->_print_rec(0, new Devel::GDB::Reflect::PrettyPrinter(), $var);
	print "\n";
}

sub get_completions($$)
{
    my $self = shift;
    my ($line) = @_;

    my ($result, $error) = $self->{gdb}->get("complete $line");
	die "Fatal Error: $error" if $error;

    return split "\n", $result;
}

sub get_member($$$);
sub get_member($$$)
{
	my $self = shift;
	my ($type, $query) = @_;

	if(ref $type ne 'HASH')
	{
		# Someone passed in a variable, not a type
		$type = $self->get_type($type);
	}

	my $class_spec = $self->_get_class($type->{quotename});
	return undef unless $class_spec->{members};

	foreach my $member (@{$class_spec->{members}})
	{
		foreach my $t ('variable', 'function')
		{
			return $member if (defined $member->{$t} and $member->{$t} eq $query);
		}
	}

	if(defined($class_spec->{parent}))
	{
		return $self->get_member($class_spec->{parent}, $query);
	}

	return undef;
}

sub eval($$)
{
	my $self = shift;
	my ($expr) = @_;

	my ($result, $error) = $self->{gdb}->get("output $expr");
	die "Fatal Error: $error" if $error;

	# We're going to assume that it succeeded if $result either starts with an
	# open brace (it's a struct or class of some sort), OR it's is not
	# terminated with a newline (which is how error messages are shown).
	return undef if($result =~ /^[^{].*\n/); return $result; }

sub _print_rec($$$;$)
{
	my $self = shift;
	my ($depth, $pp, $var, $type) = @_;

	my $pp_fh = $pp->{fh};

	#
	# Control for excessive recursion
	#
	if($depth >= $MAX_DEPTH)
	{
		print $pp_fh "{ ... }";
		return;
	}

	#
	# Get the type of $var, unless we're told what it is
	#

    unless(defined $type)
    {
        $type = $self->get_type($var) or return;
    }

	#
	# Find candidate delegates for this type, unless we already have one cached
	#

    unless(defined $self->{delegate_cache}->{$type->{quotename}})
    {
        my @delegates = ();

        foreach my $inst (@{$self->{delegate_providers}})
        {
            push @delegates, $inst->get_delegates($type, $var, $self);
        }

        if(!@delegates)
        {
            print $pp_fh "[No delegate found!]";
            return;
        }

        #
        # Take the highest-priority one
        #

        my $delegate = (sort { $b->{priority} <=> $a->{priority} } @delegates)[0];
        $self->{delegate_cache}->{$type->{quotename}} = $delegate;
    }

    my $delegate = $self->{delegate_cache}->{$type->{quotename}}
        or die "Something wrong here";

	#
	# Now use $delegate to either dump the object as-is, or iterate
	#

	my $pp_child = new Devel::GDB::Reflect::PrettyPrinter( $pp,
														   $delegate->{print_open_brace},
														   $delegate->{print_separator},
														   $delegate->{print_close_brace} );

	my $callback = sub { $self->_print_rec($depth+1, $pp_child, @_) };
    my $printer = $delegate->{factory}->($var);

	if($delegate->{can_iterate})
	{
		for(my $i=0 ; $i<$MAX_WIDTH && $printer->has_next() ; $i++)
		{
			$printer->print_next($callback, $pp_child->{fh});
		}

		my $pp_child_fh = $pp_child->{fh};
		print $pp_child_fh "..." if($printer->has_next());
	}
	else
	{
		$printer->print($callback, $pp_child->{fh});
	}

	$pp_child->finish($delegate->{print_newline});
}

sub _get_class($$)
{
	my $self = shift;
	my ($typename) = @_;

	unless(defined $self->{class_cache}->{$typename})
	{
		my ($result, $error) = $self->{gdb}->get("ptype $typename");
		die "Fatal Error: $error" if $error;

		my $class_spec = $self->{parser}->parse($result);
		unless(defined $class_spec)
		{
			$DB::single = 2;
			print STDERR "Failed parsing type '$typename'!\n";
			return undef;
		}

		$self->{class_cache}->{$typename} = $class_spec;
	}

	return $self->{class_cache}->{$typename};
}

##
## It would be better to use "whatis" here, rather than "ptype", but GDB
## is stupid.  There, I said it. :-)
##
## If $var is of type std::string, "whatis $var" gives "type = string",
## while "ptype $var" gives the full type specification.
##
sub get_type($$)
{
	my $self = shift;
	my ($var) = @_;

	my ($result, $error) = $self->{gdb}->get("ptype $var");
	die "Fatal Error: $error" if $error;

	if($result !~ /^type =/)
	{
		print STDERR $result;
		return undef;
	}

	# Strip off the class definition, if any.  This is ugly, but it avoids
	# expensively parsing the entire class...
	$result =~ s/ : .*//s;
	$result =~ s/{.*//s;

	my $type = $self->{parser}->parse($result);

	unless(defined $type)
	{
		print STDERR "Failed parsing type!\n  Result was: $result\n";
		return undef;
	}

	return $type;
}

1;

=head2 Delegates

Although this module is designed primarily for printing the contents of STL
containers, it is fully extensible to support custom data types.  The
L</"print"> method works by iterating over a set of I<delegates> to determine
how to print out a given variable.

A I<delegate> is a hash consisting of:

=over

=item priority

A numeric value used to disambiguate which delegate to use when there is more
than one to choose from.  For example, the fallback delegate
(C<Devel::GDB::Reflect::DelegateProvider::Fallback>) can print any data type, but has
very low priority (-1000) to prevent it from being invoked unless no other
delegate is available.

=item can_iterate

A boolean value, B<1> if the delegate is used to print a container that should
be iterated (such as a vector), or B<0> if it is used to print a single value
(such as a string).  If C<can_iterate> is true, then the delegate's factory must
provide C<has_next> and C<print_next>; otherwise, it must provide C<print>.

=item print_open_brace, print_close_brace

The string to print before and after the contents of the variable; defaults to
C<"["> and C<"]"> respectively.

=item print_separator

The string to print between elements within the variable; defaults to C<",">.
Only makes sense with C<can_iterate> is true.

=item print_newline

A boolean indicating whether or not to print a newline after printing the
contents of the container.  Typically this should be B<1> (true) except for
simple types.

=item factory

A C<sub> taking a single parameter, C<$var> (a C++ expression) and returning an
object.  This object is expected to contain either C<print> (if C<can_iterate>
is false) or C<has_next> and C<print_next>:

=over

=item print

Takes two parameters: C<$callback> and C<$fh>.  Either prints the contents of
C<$var> directly to the file handle C<$fh>, or invokes C<$callback> to print
C<$var> recursively.

=item has_next

Like Java's C<Iterator.hasNext()>, this function is called to determine whether or
not there are any items remaining to print out.

=item print_next

Prints out the current element and advances the iterator (similarly again to
Java's C<Iterator.next()>).

Like C<print()>, this function takes two parameters, C<$callback> and C<$fh>,
and either prints directly to C<$fh> or invokes C<$callback> recursively.

=back

=back

=head3 Delegate Providers

A I<delegate provider> is an object containing a method called C<get_delegates>.
This module searches for delegate providers by looking in C<@INC> for modules by
the name of C<Devel::GDB::Reflect::DelegateProvider::*>.

The C<get_delegates> method takes three parameters C<($type, $var, $reflector)>:
a I<type>, a C++ expression, and an instance of C<Devel::GDB::Reflect>.  The
C<$type> is a hash, containing:

=over

=item *

C<fullname>: the full name of the type, including its namespace and template
specialization, e.g. C<<< class std::vector<int,std::allocator<int> > * >>>.
This type should B<never> be passed to GDB; use C<quotename> instead.

=item *

C<shortname>: the type name without the template or namespace, e.g. C<vector>.

=item *

C<quotename>: the full name, properly quoted to pass to GDB, e.g. 
C<<< class 'std::vector<int,std::allocator<int> >' * >>>.

=item *

C<template>: a ref to an array of types, denoting the template parameters (if
any).  In the above example, C<$type->{template}->[1]> would contain

 { fullname  => "std::allocator<int>",
   shortname => "allocator",
   quotename => "'std::allocator<int>'",
   template  => ... }

=back

=head1 AUTHOR

Antal Novak	afn@cpan.org

=cut

__END__

 ============================================================================
 == This is the old grammar, used by Parse::RecDescent.  This was too slow ==
 == for my tastes, so I rewrote the grammar for Parse::Yapp.  This new     ==
 == grammar is in GDBGrammar.{yp,pm}.                                      ==
 ==                                                                        ==
 == Just keeping this here for now, because I am incapable of deleting     ==
 == anything :-)                                                           ==
 ============================================================================

$GRAMMAR = q`
    Start:
        'type' '=' Typedef /\Z/
            { $item[3]; }

    Typedef:
        TypeModifier(s?) ClassDef
      | PCompoundType

    BasicType:
        'void'
      | 'int'
      | 'long'
      | 'float'
      | 'double'
      | 'char'
      | 'size_t'
      | 'ssize_t'

    PCompoundType:
        CompoundType Star(s?)
        {{
            fullname  => join(' ', $item[1]->{fullname}, @{$item[2]}),
            shortname => $item[1]->{shortname},
			quotename => join(' ', @{$item[1]->{decorated}->[0]},
			                       q(') . $item[1]->{decorated}->[1] . q('),
			                       @{$item[1]->{decorated}->[2]},
			                       @{$item[2]}),
        }}

    Star:
        '*'
      | '&'
      | 'const'

    CompoundType:
        TypeModifier CompoundType
        {{
            fullname    => join(' ', $item[1], $item[2]->{fullname}),
            shortname   => $item[2]->{shortname},
			decorated   => [[$item[1], @{$item[2]->{decorated}->[0]}],
			                $item[2]->{decorated}->[1],
			                [@{$item[2]->{decorated}->[2]}]],
        }}
      | BasicType
        {{
            fullname    => $item[1],
            shortname   => $item[1],
			decorated   => [[], $item[1], []],
        }}
      | Type
        {
			$item[1]
		}

    TypeModifier:
        'unsigned'
      | 'long'
      | 'mutable'
      | 'const'
      | 'static'
      | 'const' '*'
            { join ' ', @item[1..$#item] }

    ClassDef:
        'class' Type (':' AccessMod(?) Type)(?) '{' ClassMember(s?) '}'
        {{
            'class'       => $item[2]->{fullname},
            'class_short' => $item[2]->{shortname},
            'parent'      => $item[3][0]->{fullname},
            'members'     => [ grep { ref } @{$item[5]} ],
        }}

    ClassMember:
        AccessMod ':'
            { $return = ""; 1; }
      | FunctionDecl
      | VarDecl

    VarDecl:
        PCompoundType Identifier ';'
        {{
            'variable' => $item[2],
            'type'     => $item[1],
        }}

    FunctionDecl:
        PCompoundType Identifier TemplateSpec(?) '(' PCompoundType(s? /,/) ')' FunctionKeyword(?) ';'
        {{
            'function' => $item[2],
            'type'     => $item[1],
            'params'   => $item[5],
        }}
      | Identifier '(' PCompoundType(s? /,/) ')' ';' # Constructor / Destructor
        {{
            'function' => $item[1],
            'type'     => undef,
            'params'   => $item[3],
        }}

    FunctionKeyword: 'const'

    SpecializedType:
        Identifier TemplateSpec(?)
        {{
            fullname  => $item[1] . $item[2][0],
            shortname => $item[1]
        }}

    Type:
        TypeKeyword(s?) SpecializedType(s /::/)
        {{
            fullname  => join ('::', map { $_->{fullname} } @{$item[2]}),
            shortname => $item[2][$#{$item[2]}]->{shortname},
			decorated => [[], join ('::', map { $_->{fullname} } @{$item[2]}), []],
        }}

    TypeKeyword: 'class' | 'struct'

    TemplateSpec:
        '<' PCompoundType(s? /,/) '>'
        {
            '< ' . join(',', map { $_->{fullname} } @{$item[2]}) . ' >'
        }

    Identifier:
        /operator[<>\[\]=+!-]+/
      | /[A-Za-z_~][A-Za-z0-9_]*/

    AccessMod:
        'private'
      | 'protected'
      | 'public'
`;
