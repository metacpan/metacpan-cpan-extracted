package Language::XSB;

our $VERSION = '0.14';

use strict;
use warnings;

use Carp;

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'query' => [ qw( xsb_set_query
				      xsb_clear_query
				      xsb_result
				      xsb_next
				      xsb_var
				      xsb_query
				      xsb_cut
				      xsb_find_all
				      xsb_find_one
				      xsb_call
				      xsb_assert
				      xsb_facts ) ]);

our @EXPORT_OK = ( qw(xsb_nreg),
		   map { @{$EXPORT_TAGS{$_}} } keys(%EXPORT_TAGS));
our @EXPORT = ();

our (@vars, %vars);

use Language::Prolog::Types qw(F L C isV);
use Language::XSB::Config;
use Language::XSB::Base;

sub xsb_nreg () { 7 };

sub callback_perl {
    my $cmd;
    while(defined($cmd=getreg_int(0))) {
	# use Language::XSB::Register;
	# print STDERR "callback_perl 0 regs: @XsbReg\n";
	if ($cmd==4) {
	    my $sub=getreg(3);
	    my $args=getreg(4);
	    go();
	    # print STDERR "callback_perl 1 regs: @XsbReg\n";
	    my $result;
	    eval {
		ref($sub) and
		    die "subroutine name '$sub' is not a string";
		UNIVERSAL::isa($args, 'ARRAY') or
			die "args '$args' is not a list";
		local (@vars, %vars);
		# print STDERR "calling sub $sub ( @{$args} )\n";
		package main;
		no strict 'refs';
		$result=[$sub->(@{$args})];
	    };
	    my $exception=$@;
	    while(defined(getreg_int(0))) {
		carp "query '".eval{getreg(1)}."' still open, closing";
		xsb_cut();
	    };
	    setreg_int(0, 5);
	    go();
	    # print STDERR "callback_perl 2 regs: @XsbReg\n";
	    getreg_int(0)==6 or
		die "unexpected command sequence";
	    if(defined $result) {
		setreg(5, $result);
	    }
	    else {
		setreg(6, $exception);
	    }
	    go();
	    # print STDERR "callback_perl 3 regs: @XsbReg\n";
	}
	else {
	    die "unexpected command sequence, expecting 4 or none, found $cmd";
	}
    }
}

sub ok {
    go();
    callback_perl();
    if ( regtype(1)==1) {
	@vars=(); %vars=();
	return 0;
    }
    return 1;
}

sub xsb_set_query (@) {
    defined getreg_int(0) and
	die "unexpected command sequence";
    while (regtype(1)!=1) {
	carp "query '".eval{getreg(1)}."' still open, closing";
	xsb_cut();
    }
    @vars=grep { isV $_ } @{setreg(1,C(',',@_))};
    return @vars;
}

sub xsb_query () {
    getreg(1);
}

sub xsb_next () {
    defined getreg_int(0) and
	die "unexpected command sequence";
    regtype(1)==1 and
	croak "not in a query";
    %vars=();
    setreg_int(0, 1);
    ok()
}

sub xsb_var($) {
    unless (%vars) {
	defined getreg_int(0) and
	    die "unexpected command sequence";
	regtype(1)==1 and
	    croak "not in a query";
	@vars{map {$_->name} @vars}=getreg(2)->fargs()
    }
    my $name=shift->name;
    croak "unexistant variable '$name'"
	unless exists $vars{$name};
    return $vars{$name}
}

sub xsb_result () {
    defined getreg_int(0) and
	die "unexpected command sequence";
    regtype(1)==1 and
	croak "not in a query";
    my $r2=regtype(2);
    $r2==3 and return ();
    $r2==7
	or croak "result is not ready, call xsb_next first";
    getreg(2)->fargs
}

sub xsb_clear_query () {
    defined getreg_int(0) and
	die "unexpected command sequence";
    regtype(1)==1 and
	croak "query not set";
    setreg_int(0, 2);
    ok();
}

sub xsb_cut () {
    defined getreg_int(0) and
	die "unexpected command sequence";
    regtype(1)==1 and
	croak "not in a query";
    setreg_int(0, 2);
    ok();
}


sub map_vars {
    return map {
	isV($_)     ? xsb_var($_) :
        isL($_)     ? L(_vars(prolog_list2perl_list($_))) :
        ($_ eq '*') ? xsb_query() :
	(ref($_) eq '') ? $_ :
	croak "invalid mapping '$_'";
    } @_;
}


sub xsb_find_all (@) {
  my @r;
  xsb_set_query(shift);
  push (@r, map_vars(@_)) while xsb_next;
  return @r
}

sub xsb_find_one ($;@) {
    xsb_set_query(shift);
    if (xsb_next) {
	my @r=map_vars(@_);
	xsb_cut;
	return wantarray ? @r : $r[0];
    }
    return ();
}

sub xsb_call {
    xsb_set_query(@_);
    if (xsb_next) {
	xsb_cut;
	return 1;
    }
    return undef;
}

sub xsb_assert {
    my $head=shift;
    defined $head or croak "xsb_assert called without head";
    xsb_call F(assertz => C(':-' => $head, C(',', @_)))
}

sub xsb_facts {
    return xsb_call C(',', (map { F(assertz => $_) } @_));
}


my $perlcallxsb;
for my $path (@INC) {
    next if ref $path;
    my $name=$path.'/Language/XSB/xsblib/perlcallxsb';
    $perlcallxsb=$name, last if (-f $name.'.xwam' or -f $name.'.P');
}

# warn "perlcallxsb found at '$perlcallxsb'";

xsb_init($perlcallxsb||'perlcallxsb');
callback_perl();

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Language::XSB - use XSB from Perl.

=head1 SYNOPSIS

    use Language::XSB ':query';
    use Language::Prolog::Types::overload;
    use Language::Prolog::Sugar vars=>[qw(X Y Z)],
                                functors=>{equal => '='},
                                functors=>[qw(is)],
                                chains=>{plus => '+',
					 orn => ';'};

    xsb_set_query( equal(X, 34),
                   equal(Y, -12),
                   is(Z, plus( X,
		 	       Y,
			       1000 )));

    while(xsb_next()) {
	printf("X=%d, Y=%d, Z=%d\n",
               xsb_var(X), xsb_var(Y), xsb_var(Z))
    }

    print join("\n", xsb_find_all(orn(equal(X, 27),
				      equal(X, 45)), X)), "\n";

=head1 ABSTRACT

Language::XSB provides a bidirectional interface to XSB
(L<http://xsb.sourceforge.net/>).

=head1 DESCRIPTION

From the XSB manual:

  XSB is a research-oriented Logic Programming and Deductive
  Database System developed at SUNY Stony Brook.  In addition to
  providing all the functionality of Prolog, it contains
  features not usually found in Logic Programming Systems such
  as evaluation according to the Well Founded Semantics through
  full SLG resolution, constraint handling for tabled programs,
  a compiled HiLog implementation, unification factoring and
  interfaces to other systems such as ODBC, C, Java, Perl, and
  Oracle

This package implements a bidirectional interface to XSB, thats
means that Perl can call XSB that can call Perl back that can
call XSB again, etc.:

  Perl -> XSB -> Perl -> XSB -> ...

(Unfortunately, you have to start from Perl, C<XSB-E<gt>Perl-E<gt>...>
is not possible.)

The interface to XSB is based on the objects created by the
package L<Language::Prolog::Types>. You can also use
L<Language::Prolog::Sugar> package, a front end for the types
package to improve the look of your source (just some syntactic
sugar).

To make queries to XSB you have to set first the query term with
the function C<xsb_set_query>, and then use C<xsb_next> and
C<xsb_result> to iterate over it and get the results back.

Only one query can be open at any time, unless when Perl is
called back from XSB, but then the old query is not visible.

=head2 EXPORT_TAGS

In this versions there is only one tag to import all the
soubrutines in your script or package:

=over 4

=item C<:query>

=over 4

=item C<xsb_set_query(@terms)>

sets the query term, if multiple terms are passed, then the are
first chained with the ','/2 functor and the result stored as
the query.

It returns the free variables found in the query.


=item C<xsb_var($var)>

Returns the value binded to C<$var> in the current query/solution combination.


=item C<xsb_query()>

returns the current query, variables are bounded to their current
values if C<xsb_next> has been called with success.


=item C<xsb_next()>

iterates over the query and returns a true value if a new
solution is found.


=item C<xsb_result()>

after calling xsb_next, this soubrutine returns the values
assigned to the free variables in the query.


=item C<xsb_cut()>

ends an unfinished query, similar to XSB (or Prolog) cut
C<!>. As the real cut in XSB, special care should be taken to
not cut over tables.


=item C<xsb_clear_query()>

a deprecated alias for C<xsb_cut>.


=item C<xsb_find_all($query, @pattern)>

iterates over $query and returns and array with @pattern binded to
every solution. i.e:

  xsb_find_all(member(X, [1, 3, 7, 21]), X)

returns the array C<(1, 3, 7, 21)> and

  xsb_find_all(member(X, [1, 3, 7, 21]), [X])

returns the array C<([1], [3], [7], [21])>.

More elaborate constructions can be used:

  %mothers=xsb_find_all(mother(X,Y), X, Y)


=item C<xsb_find_one($query, @pattern)>

as C<xsb_find_all> but only for the first solution.


=item C<xsb_call(@query)>

runs the query once and return true if a solution was found or false
otherwise.

=item C<xsb_assert($head =E<gt> @body)>

add new definitions at the botton of the database

=item C<xsb_facts(@facts)>

commodity subroutine to add several facts (facts, doesn't have body)
to the database in one call.

i.e.:

  use Language::Prolog::Sugar functors=>[qw(man woman)];

  xsb_facts( man('teodoro'),
             man('socrates'),
             woman('teresa'),
             woman('mary') );


=back

=back

=head2 BUGS

This is alpha software so there should be some of them.

clpr is not callable from Perl. A FPE signal will raise if you try to
do so.

No threads support as XSB doesn't support them (take a look at
L<Language::Prolog::Yaswi> for an interface to SWI-Prolog with thread
support).


=head1 SEE ALSO

L<Language::Prolog::Types>, L<Language::Prolog::Types::overload>
and L<Language::Prolog::Sugar> for instructions on creating
Prolog (or XSB) terms from Perl.

For XSB and Prolog information see L<xsb(1)>, the XSB website at
L<Sourceforge|http://xsb.sourceforge.net> and the FAQ of
L<comp.lang.prolog|news:comp.lang.prolog>.

A good Prolog book would also help. I personally recommend you

=over 4

=item - L<PROLOG Programming for Artificial Intelligence> by Ivan
Bratko.

=item - L<The Art of Prolog> by Leon Sterling and Ehud Shapiro.

=back

If you want to look at the inners details of this package then
take a look at L<Language::XSB::Base> and
L<Language::XSB::Register>.


=head1 AUTHOR

Salvador Fandiño, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002, 2003 by Salvador Fandiño

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
