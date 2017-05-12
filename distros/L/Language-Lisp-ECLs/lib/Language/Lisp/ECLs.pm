package Language::Lisp::ECLs;

use 5.008;
use strict;

our $VERSION = '0.27';

require XSLoader;
XSLoader::load('Language::Lisp::ECLs', $VERSION);

sub new {
    cl_boot();
    return bless {}, __PACKAGE__;
}

sub char {
    shift;
    Language::Lisp::ECLs::_char(@_);
}

sub shutdown {
    cl_shutdown();
}

sub eval {
    my $self = shift;
    return _eval(@_);
}
sub eval_form {
    my $self = shift;
    return _eval_form(@_);
}

sub stringify {
    my $self = shift;
    return "{dummied stringification}";
}

my %meth;

sub vivify_lisp_method {
    my ($package, $method) = @_;
    my $method0;
    for ($method) {
	s/^(Language::Lisp::ECLs::)//
	    or die "weird inheritance ($method)";
	$package = $1;
        $method0 = $method;
	s/(?<!_)__(?!_)/::/g;
	s/(?<!_)___(?!_)/_/g;
	# camelCase becomes camel-case
	s/([a-z])(?=[A-Z])/$1-/g;
    }
    #print STDERR "AUTOLOAD($method,$package)\n";

    if (!exists $meth{$method}) {
	$meth{$method} = _search_lisp_function(uc($method));
    }
    my $code = $meth{$method};
    unless (defined $code) {
        print STDERR "code $method not found\n";
	return;
    }

    # search for right corresponding lisp method, and create it afterwards
    # (so no consequent AUTOLOAD will happen)
    # TBD bind to fast subroutine
    my $sub =  sub {
	my $int = shift;
	$code->funcall(@_);
    };
    no strict 'refs';
    *{"$package$method0"} = $sub;
    return $sub;
}

#
# AUTOLOAD method for lisp interpreter object, which will bring into
# existance interpreter methods
sub AUTOLOAD {
    my $int = shift;
    my ($method,$package) = $Language::Lisp::ECLs::AUTOLOAD;
    my $sub = vivify_lisp_method($package,$method);
    if ($sub) {
	return $sub->($int,@_);
    }
}

sub DESTROY {
}

# stringify0 is "purified" stringify
sub stringify0 {stringify(@_);}

package Language::Lisp::ECLs::Symbol;
our @ISA = ('Language::Lisp::ECLs');
package Language::Lisp::ECLs::Package;
our @ISA = ('Language::Lisp::ECLs');
package Language::Lisp::ECLs::String;
our @ISA = ('Language::Lisp::ECLs');
package Language::Lisp::ECLs::Char;
our @ISA = ('Language::Lisp::ECLs');
package Language::Lisp::ECLs::Ratio;
our @ISA = ('Language::Lisp::ECLs');
package Language::Lisp::ECLs::Bignum;
our @ISA = ('Language::Lisp::ECLs');
package Language::Lisp::ECLs::Code;
our @ISA = ('Language::Lisp::ECLs');
sub stringify {return "#<CODE>"}

package Language::Lisp::ECLs::Generic;
our @ISA = ('Language::Lisp::ECLs');

package Language::Lisp::ECLs::List;
our @ISA = ('Language::Lisp::ECLs');

sub item {
    return FETCH(@_);
}

sub _tie {
    my $self = shift;
    tie my @array, "Language::Lisp::ECLs::List", $self;
    #my $len = scalar(@array);
    #print "TIE: list len is $len;\n",(map {
    #        do {
    #    	my $r = $array[$_];
    #            "$_: $r ".$r->stringify."\n"
    #        }
    #    } 0..$len-1),";\n";
    #if (tied @array) {print "TIED!"}
    return \@array;
}

# tied array methods
#xs - sub TIEARRAY { ... }
#xs - sub FETCH { ... }
#xs - sub FETCHSIZE { ... }

# ... not done (yet) mehods:
#sub STORE { ... }        # mandatory if elements writeable
#sub STORESIZE { ... }    # mandatory if elements can be added/deleted
#sub EXISTS { ... }       # mandatory if exists() expected to work
#sub DELETE { ... }       # mandatory if delete() expected to work

# optional methods - for efficiency
#sub CLEAR { ... }
#sub PUSH { ... }
#sub POP { ... }
#sub SHIFT { ... }
#sub UNSHIFT { ... }
#sub SPLICE { ... }
#sub EXTEND { ... }
#sub DESTROY { ... }

sub stringify {
    my $self = shift;
    return "#<LIST(".$self->FETCHSIZE.")>";
}

package Language::Lisp::ECLs::HashTable;
our @ISA = ('Language::Lisp::ECLs');

sub new {
    return _eval("(make-hash-table :test #'equal)");
}
sub _tie {
    my $self = shift;
    tie my %hash, "Language::Lisp::ECLs::HashTable", $self;
    return \%hash;
}

# tied hash methods
#xs - sub TIEHASH { ... }
#xs - sub FETCH { ... }
#xs - sub FETCHSIZE { ... }

1;

__END__

=head1 NAME

Language::Lisp::ECLs - Perl extension for ECL lisp

=head1 SYNOPSIS

  use Language::Lisp::ECLs;
  my $cl = new Language::Lisp::ECLs;
  my $r = $cl->eval("(format nil \"[~S]\" 'qwerty)");
  my $lam = $cl->eval("(lambda (x y) (+ x y))");
  $lam->funcall(5,9); # results 14

=head1 DESCRIPTION

Language::Lisp::ECLs is a bit easier to use than Language::Lisp because of
embeddable nature of ECLs. Language::Lisp uses different approach because
they are other way down: Lisp calls Perl and not vice versa.

=head2 new()

The C<new> method used to create C<Language::Lisp::ECLs> object which is
used to talk with underlying lisp. This object looks like an interpreter
instance, although there is actually no interpreter instance created.
Instead, this object is used to create a handy way of invoking API: given that
you have C<$cl> object you can execute:

  my $res = $cl->eval("(format nil \"~A\" (expt 2 1000))");

which is equivalent to

  my $res = Language::Lisp::ECLs::eval(undef, "....");

but is much better to use.

=head2 Passing parameters to ECL and getting results from ECL

Required Perl objects converted to Lisp objects and vice versa.
Compatible types are converted as-is (e.g. ECL type t_integer becomes
SvIV), all other types are blessed into some package, for example into
C<Language::Lisp::ECLs::Symbol>

This is done behind the scenes and user should not bother about this.

This makes following code to work:

  my $lam = $cl->eval("(lambda (x y) (+ x y))");
  print $lam->funcall(40,2);     # prints 42
  print $cl->funcall($lam,40,2); # ... another way to say the same

=head3 $cl->eval(string)

runs string within ECLs interpreter and returns whatever lisp returns to us.
Internally this transforms to the call C<si_safe_eval(...);>

=head3 $cl->eval(lisp_object)

same as eval but takes lisp object instead of string as argument.

=head3 $cl->keyword("QWERTY")

returns LISP keyword as a symbol (from Perl side this means it is blessed
to C<Language::Lisp::ECLs::Symbol> package). In Lisp this symbol belongs
to the 'keyword' package. These keywords correspond to lisp's C<:keywords>.

=head3 $lispobj->funcall(...)

given lisp object blessed to package Language::Lisp::ECLs::Code calls the
procedure.

=head2 AUTOLOADing

$cl->someFunctionName(args) get transformed into function call to
"some-function-name"

This is done by finding lisp object for evaluating arguments, and blessing
it into Language::Lisp::ECLs::Code package

  $cl->prin1("qwerty");

=head2 ECL Objects

=head3 Language::Lisp::ECLs::Symbol

LISP symbols are blessed to this package

=head3 Language::Lisp::ECLs::Package
=head3 Language::Lisp::ECLs::String

=head3 Language::Lisp::ECLs::Char

Object to represent character type within Lisp.
Here are 3 equivalent ways to get it:

  $ch = $cl->char("c");
  $ch = $cl->char(ord("c"));
  $ch = Language::Lisp::ECLs::_char("c");

Another way is:

  $ch = $cl->eval('#\c');

=head3 Language::Lisp::ECLs::Code
=head3 Language::Lisp::ECLs::Generic

=head3 Language::Lisp::ECLs::Ratio

t_ratio

=head3 Language::Lisp::ECLs::Bignum

t_bignum

=head3 Language::Lisp::ECLs::List

If you have a list object in Lisp, it will be automatically blessed
into the C<Language::Lisp::ECLs::List> package:

  my $list = $cl->eval("'(a b c d qwerty)");

List object have C<item(n)> method to return n-th value from the list.

List object have TIEARRAY, FETCH, FETCHSIZE methods and so ready for tie-ing
as array with a C<tie> perl funciton:

  tie my @arr, "Language::Lisp::ECLs::List", $list;

Even simplier, $list have C<_tie> method to return tied array reference:

  my $arr = $list->_tie;

Fetching items from this array works, storing them currently do not work.

=head3 Language::Lisp::ECLs::HashTable

=head2 EXPORT

None. No namespace pollution, the greens are happy.

=head1 BUGS

=over

=item *

ECL uses Boehm GC, and at the moment of writing it did not had reliable
interface on returning memory to GC, so the leaks of memory are unavoidable.

=item *

C<funcall> can not take more than 10 args - this should be fixed.

=back

=head1 SEE ALSO

Language::Lisp

See ecls.sf.net to read about ECL lisp project.

=head1 AUTHOR

Vadim Konovalov, E<lt>vkon@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by VKON

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.004 or,
at your option, any later version of Perl 5 you may have available.


=cut

