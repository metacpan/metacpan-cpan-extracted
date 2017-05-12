package Language::Prolog::Yaswi;

our $VERSION = '0.21';

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'query' => [ qw( swi_set_query
				      swi_set_query_module
				      swi_result
				      swi_next
				      swi_var
				      swi_vars
				      swi_query
				      swi_cut
				      swi_find_all
				      swi_find_one
				      swi_call
				      swi_parse
				      swi_eval )],
		     'load' => [ qw( swi_inline
				     swi_inline_module
				     swi_consult
				     swi_use_modules )],
		     'assert' => [ qw( swi_assert
				       swi_asserta
				       swi_assertz
				       swi_facts
                                       swi_retractall )],
		     'interactive' => [ qw( swi_toplevel )],
		     'context' => [ qw( *swi_module
					*swi_temp_dir
					*swi_converter) ],
		     'run' => [ qw( swi_init
				    swi_cleanup )] );

our @EXPORT_OK = ( @{$EXPORT_TAGS{query}},
		   @{$EXPORT_TAGS{assert}},
		   @{$EXPORT_TAGS{interactive}},
		   @{$EXPORT_TAGS{context}},
		   @{$EXPORT_TAGS{run}},
		   @{$EXPORT_TAGS{load}});

our @EXPORT = qw();

use Carp;
our @CARP_NOT=qw( Prolog::Language::Yaswi::Low
		  Prolog::Language::Types );

use File::Temp;
use Language::Prolog::Types qw(:util F L C V isF isL isV isN);
use Language::Prolog::Yaswi::Low;


our $swi_module = undef;
our $swi_temp_dir = undef;
our $swi_debug = undef;


sub swi_init;
*swi_init=\&init;

sub swi_cleanup();
*swi_cleanup=\&cleanup;

sub swi_toplevel();
*swi_toplevel=\&toplevel;

*swi_converter=*converter;

sub swi_set_query_module {
    @{&openquery(@_)}
}

sub swi_cut();
*swi_cut=\&cutquery;


sub swi_set_query {
    return swi_set_query_module(C(',', @_),
				$swi_module);
}

sub swi_next() {
    package main;
    Language::Prolog::Yaswi::Low::nextsolution();
}

sub swi_query {
    testquery();
    getquery();
}

sub swi_var($) {
    testquery();
    getvar($_[0]);
}

sub swi_result() {
    testquery();
    getallvars();
}

sub swi_vars {
    testquery();
    my @res=map {
	isV($_)     ? getvar($_) :
        isL($_)     ? L(swi_vars(prolog_list2perl_list($_))) :
	isF($_)     ? F($_->functor => swi_vars($_->fargs)) :
        ($_ eq '*') ? getquery() :
	isN($_)     ? $_ :
	(ref($_) eq '') ? $_ :
	croak "invalid mapping '$_'";
    } @_;
    wantarray ? @res : $res[0]
}

sub swi_find_all ($;@) {
    my @r;
    swi_set_query(shift);
    while (swi_next) {
	# warn "new solution found\n";
	push @r, swi_vars(@_);
    }
    return wantarray ? @r : $r[0]
}

sub swi_find_one ($;@) {
    swi_set_query(shift);
    if (swi_next) {
	my @r=swi_vars(@_);
	swi_cut;
	return wantarray ? @r : $r[0];
    }
    return ();
}

sub swi_call {
    swi_set_query(@_);
    if (swi_next) {
	swi_cut;
	return 1;
    }
    return undef;
}

sub swi_assertz {
    my $head=shift;
    defined $head or croak "swi_assertz called without head";
    swi_call F(assertz => C(':-' => $head, C(',', @_)))
}

*swi_assert=\&swi_assertz;

sub swi_asserta {
    my $head=shift;
    defined $head or croak "swi_asserta called without head";
    swi_call F(asserta => C(':-' => $head, C(',', @_)))
}

sub swi_retractall {
    for my $head (@_) {
        swi_call F(retractall => $head);
    }
}

sub swi_facts {
    return swi_call C(',', (map { F(assertz => $_) } @_));
}

sub swi_consult {
    return swi_call([@_]);
}

sub swi_use_modules {
    swi_call F(use_module => $_) for @_
}

sub swi_parse {
    my @r;
    for my $atom (@_) {
	my ($t, $b) = swi_find_one(F(atom_to_term => $atom, V('T'), V('B')),
				   V('T'), V('B'));
	if (isL $b) {
	    for my $pair (@{$b}) {
		my $var = $pair->farg(1);
		$var->rename($pair->farg(0))
	    }
	}
	push @r, $t
    }
    return wantarray ? @r : $r[0]
}

sub swi_eval {
    swi_call(C(',' => swi_parse(@_)))
}

sub swi_inline {
    _swi_inline(load_files => @_)
}

sub swi_inline_module {
    _swi_inline(use_module => @_)
}

sub _swi_inline {
    my $action = shift;
    my $tmp=File::Temp->new(TEMPLATE => 'swi_inline_XXXXXXXX', SUFFIX => '.swi',
			    ((defined $swi_temp_dir) ?
			     (DIR => $swi_temp_dir) : ()));
    defined ($tmp) or croak "unable to create temporal prolog source file";
    my $fn=$tmp->filename;

    $tmp->print(@_, "\n");
    $tmp->close;

    eval { swi_call F($action => $fn) };
    unlink $fn;
    die $@ if $@;
}


package Language::Prolog::Yaswi::HASH;
our @ISA=qw(Language::Prolog::Types::Opaque::Auto);

sub new { return bless {}; }


1;
__END__


=head1 NAME

Language::Prolog::Yaswi - Yet another interface to SWI-Prolog

=head1 SYNOPSIS

  use Language::Prolog::Yaswi ':query';
  use Language::Prolog::Types::overload;
  use Language::Prolog::Sugar functors => { equal => '=',
                                            is    => 'is' },
                              chains => { orn => ';',
                                          andn => ',',
                                          add => '+' },
                              vars => [qw (X Y Z)];

  swi_set_query( equal(X, Y),
                 orn( equal(X, 27),
                      equal(Y, 'hello')));

  while (swi_next) {
      printf "Query=".swi_query()."\n";
      printf "  X=%s, Y=%s\n\n", swi_var(X), swi_var(Y);
  }

  print join("\n",
             swi_findall(andn(equal(X, 2),
                              orn(equal(Y, 1),
                                  equal(Y, 3.1416)),
                              is(Z, plus(X,Y,Y))),
                         [X, Y, Z]));


=head1 ABSTRACT

Language::Prolog::Yaswi implements a bidirectional interface to the
SWI-Prolog system (L<http://www.swi-prolog.org/>).


=head1 DESCRIPTION

This package provides a bidirectional interface to SWI-Prolog. That
means that Prolog code can be called from Perl that can call Perl code
again and so on:

  Perl -> Prolog -> Perl -> Prolog -> ...

(unfortunately, by now, the cicle has to be started from Perl,
although it is very easy to circunvent this limitation with the help
of a dummy Perl script that just calls Prolog the first time).

The interface is based on the set of classes defined in
Language::Prolog::Types. Package Language::Prolog::Sugar can also be
used to improve the look and readability of scripts mixing Perl and
Prolog code.

The interface to call Prolog from Perl is very simple, at least if you
are used to Prolog non deterministic nature.

=head2 SUBROUTINES

Grouped by export tag:

=over 4

=item :query

=over 4

=item swi_set_query($query1, $query2, $query3, ...)

Composes a query with all the parameters given and sets it.

The set of free variables found in the query is returned.

=item swi_set_query_module($query, $module)

Allows to set a query in a module different than the default.

=item swi_result

Returns the values binded to the variables in the query.

=item swi_next

Iterates over the query solutions.

If a new solution is available returns true, if not, closes the query
and returns false.

It has to be called after C<swi_set_query(...)> to obtain the first
solution.

=item swi_var($var)

Returns the value binded to C<$var> in the current query/solution combination.

=item swi_vars(@vars)

Returns the values binded to C<@vars> in the current query/solution combination.

Actually, it accepts more powerfull contructions, i.e.

  $a = swi_vars([X, Y, [Z]])



=item swi_query

Returns the current query with the variables binded to its values in
the current solution (or unbinded if swi_next has not been called
yet).

=item swi_cut

Closes the current query even if not all of its solutions have been
retrieved. Similar to prolog cut (C<!>).

=item swi_find_all($query, @pattern)

iterates over $query and returns and array with @pattern binded to
every solution. i.e:

  swi_find_all(member(X, [1, 3, 7, 21]), X)

returns the array C<(1, 3, 7, 21)> and

  swi_find_all(member(X, [1, 3, 7, 21]), [X])

returns the array C<([1], [3], [7], [21])>.

More elaborate constructions can be used:

  %mothers = swi_find_all(mother(X,Y), X, Y)


There is also an example of its usage in the SYNOPSIS.


=item swi_find_one($query, @pattern)

as C<swi_find_all> but only for the first solution.

=item swi_call($query)

runs the query once and returns true if a solution was found or false
otherwise.

=item swi_parse(@strings)

commodity interface to prolog predicate C<atom_to_term/3>. Converts
strings to prolog terms.

=item swi_eval(@strings)

parses C<@strings> and calls them on the prolog engine.



=back

=item :interactive

=over 4

=item swi_toplevel

mostly for debugging pourposes, runs SWI-Prolog shell.

=back

=item :load

=over 4

=item swi_inline @code

dumps C<@code> to a temporary file and C<consult>s it from prolog.

Use C<$swi_temp_dir> to change the directory where the file is
created.

=item swi_inline_module @code

similar to C<swi_inline()> but using C<use_module/1> to load the file.

=item swi_consult @files

=item swi_use_modules @modules

=back

=item :assert

=over 4

=item swi_assert($head =E<gt> @body)

=item swi_assertz($head =E<gt> @body)

add new definitions at the bottom of the database

=item swi_asserta($head =E<gt> @body)

adds new definitions at the top of the database

=item swi_facts(@facts)

commodity subroutine to add several facts to the database in one call
(a fact is a predicate with an empty body).

i.e.:

  use Language::Prolog::Sugar functors=>[qw(man woman)];

  swi_facts( man('teodoro'),
             man('socrates'),
             woman('teresa'),
             woman('mary') );

=item swi_retractall(@heads)

loops over C<@heads> calling C<retractall/1> Prolog predicate.

=back


=item :context

=over 4



=item $swi_module

allow to change the module for the upcoming queries.

use the C<local> operator when changing their values ALWAYS!!!

i.e.:

   local $swi_module='mymodule'
   swi_set_query($query_from_mymodule);

=item $swi_converter

allows to change the way data is converter from Perl to Prolog.

You should really not use it for anything different than configuring
perl classes as opaque, i.e.:

  $swi_converter->pass_as_opaque(qw(LWP::UserAgent
                                    HTTP::Request
                                    HTTP::Result))

... unless you know what you are doing!!!

=item $swi_temp_dir

see docs for L<swi_inline()>

=back

=item :run

=over 4

=item swi_init(@args)

lets init the prolog engine with a different set of arguments
(identical to the command line arguments for the C<pl> SWI-Prolog
executable.

Defaults arguments are C<-q> to stop the SWI-Prolog welcome banner
for being printed to the console.

Language::Prolog::Yaswi will automatically create a new engine with
the default arguments (or with the last passed via swi_init), when
needed.

=item swi_cleanup

releases the prolog engine.

Language::Prolog::Yaswi will release the engine when the script
finish, this function is usefull to release the engine to free
resources or to be able to init it again with a different set of
arguments.

=back

=back

=head2 CALLBACKS

Yaswi adds to SWI-Prolog three new predicates to call perl back.

All the calls are made in array contest and the Result value is always
a list. There is no way to make a call in scalar context other than
explicitly calling scalar.

=over 4

=item perl5_eval(+Code, -Result)

evaluates the Perl code passed on the atom C<Code> and
return the results as a list in C<Result>.

=item perl5_call(+Sub, +Args, -Result)

calls the Perl sub C<Sub> with the arguments in the list C<Args> and
returns the list of results in C<Result>.

=item perl5_method(+Object, +Method, +Args, -Result)

calls the method C<Method> from the perl object C<Object>.

To get a Perl object passed to prolog as an opaque value instead of
marshaled into prolog types, its class (or one of its parent classes)
has to be previously registered as opaque with the $swi_converter
object. i.e.:

  perl5_eval('$Language::Prolog::Yaswi::swi_converter \
               -> pass_as_opaque("HTTP::Request")',_),
  perl5_eval('use HTTP::Request',_),
  perl5_method('HTTP::Request', new, [], [Request]),
  perl5_method(Request, as_string, [], [Text]).

Registering class C<UNIVERSAL> causes all objects to be passed as
opaques to prolog.


=back

=head2 EXPORT

This module doesn't export anything by default. Subroutines should be
explicitely imported.

=head2 THREADS

To get thread support in this module both Perl and SWI-Prolog have to
be previously compiled with threads. Perl needs the ithread model
available from Perl version 5.8.0 and upwards.

When Perl is called back from a thread created from Prolog a new fresh
Perl engine is constructed. That means there will be no modules
preloaded on it, no access to Perl data from other threads (not even
data marked as shared!), etc. Threads created from Perl do not suffer
from this limitation.


=head1 KNOWN BUGS

It is not possible to use Prolog C extensions (i.e. pce) in every
OS. Though it works at least on Linux, Solaris and Windows.

Unicode support is experimental.

Variable attributes are discarded when they cross the Perl/Prolog
interface.

=head1 SEE ALSO

SWI-Prolog documentation L<http://www.swi-prolog.org/>, L<pl(1)>,
L<Languages::Prolog::Types> and L<Language::Prolog::Sugar>.

L<AI::Prolog> is a well maintained Prolog implementation in pure Perl.


=head1 COPYRIGHT AND LICENSE

Copyright 2003-2006, 2008, 2011, 2012 by Salvador FandiE<ntilde>o
E<lt>sfandino@yahoo.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
