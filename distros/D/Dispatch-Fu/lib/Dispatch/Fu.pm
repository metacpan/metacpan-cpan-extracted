package Dispatch::Fu;

use strict;
use warnings;
use Exporter qw/import/;

our $VERSION       = q{0.99};
our @EXPORT        = qw(dispatch on cases xdefault);
our @EXPORT_OK     = qw(dispatch on cases xdefault);

my $DISPATCH_TABLE = {};

sub dispatch (&@) {
    my $code_ref  = shift;    # catch sub ref that was coerced from the 'dispatch' BLOCK
    my $match_ref = shift;    # catch the input reference passed after the 'dispatch' BLOCK

    # build up dispatch table for each k/v pair preceded by 'on'
    while ( my $key = shift @_ ) {
        my $HV = shift @_;
        $DISPATCH_TABLE->{$key} = _to_sub($HV);
    }

    # call $code_ref that needs to return a valid bucket name
    my $key = $code_ref->($match_ref);

    die qq{Computed static bucket not found\n} if not $DISPATCH_TABLE->{$key} or 'CODE' ne ref $DISPATCH_TABLE->{$key};

    # call subroutine ref defined as the v in the k/v $DISPATCH_TABLE->{$key} slot
    my $sub_to_call = $DISPATCH_TABLE->{$key};

    # reset table
    $DISPATCH_TABLE = {};

    # dispatch with $match_ref
    $sub_to_call->($match_ref);
}

# on accumulater, wants h => v pair, where h is a static bucket string and v is a sub ref
sub on (@) {
    return @_;
}

# sub for introspection, returns the string names of each case
# added using the C<on> keyword
sub cases () {
    return keys %$DISPATCH_TABLE;
}

# if $case is in cases(), return $case; otherwise return $default
# Note: $default defaults to q{default}; i.e., if the name of the
# default case is not specified, the string 'default' is returned
sub xdefault($;$) {
  my ($case, $default) = @_;
  if ($case and grep { /$case/ } (cases)){
    return $case;
  }
  return $default // q{default};
}

# utility sub to force a BLOCK into a sub reference
sub _to_sub (&) {
    shift;
}

1;

__END__

=head1 NAME

Dispatch::Fu - Converts any complicated conditional dispatch situation into familiar static hash-key based dispatch

=head1 SYNOPSIS

  use strict;
  use warnings;
  use Dispatch::Fu; # 'dispatch', 'cases', 'xdefault', and 'on' are exported by default, just for show here

  my $INPUT = [qw/1 2 3 4 5/];

  my $results = dispatch {                       # <~ start of 'dispatch' construct
      my $input_ref = shift;                     # <~ input reference
      return ( scalar @$input_ref > 5 )          # <~ return a string that must be
       ? q{case5}                                #    defined below using the 'on'
       : sprintf qq{case%d}, scalar @$input_ref; #    keyword, this i
  } $INPUT,                                      # <~ input reference, SCALAR passed to dispatch BLOCK
    on case0 => sub { my $INPUT = shift; return qq{case 0}},    # <~ if dispatch returns 'case0', run this CODE
    on case1 => sub { my $INPUT = shift; return qq{case 1}} ,   # <~ if dispatch returns 'case1', run this CODE
    on case2 => sub { my $INPUT = shift; return qq{case 2}},    #    ...   ...   ...   ...   ...   ...   ...
    on case3 => sub { my $INPUT = shift; return qq{case 3}},    # ...   ...   ...   ...   ...   ...   ...   ...
    on case4 => sub { my $INPUT = shift; return qq{case 4}},    #    ...   ...   ...   ...   ...   ...   ...
    on case5 => sub { my $INPUT = shift; return qq{case 5}};    # <~ if dispatch returns 'case5', run this CODE

=head1 DESCRIPTION

C<Dispatch::Fu> provides an idiomatic and succinct way to organize a C<HASH>-based
dispatch table by first computing a static key using a developer defined process.
This static key is then used immediate to execute the subroutine reference registered
to the key.

This module presents a generic structure that can be used to implement all of the past
attemts to bring things to Perl like, I<switch> or I<case> statements, I<given>/I<when>,
I<smartmatch>, etc.

=head2 The Problem

C<HASH> based dispatching in Perl is a very fast and well established way
to organize your code.  A dispatch table can be fashioned easily when the
dispatch may occur on a single variable that may be one or more static
strings suitable to serve also as C<HASH> a key.

For example, the following is more or less a classical example of this approach
that is fundamentally based on a 1:1 mapping of a value of C<$action> to a
C<HASH> key defined in C<$dispatch>:

  my $CASE = get_case(); # presumed to return one of the hash keys used below

  my $dispatch = {
    do_dis  => sub { ... },
    do_dat  => sub { ... },
    do_deez => sub { ... },
    do_doze => sub { ... },
  };

  if (not $CASE or not exists $dispatch->{$CASE}) {
    die qq{case not supported\n};
  }

  my $results = $dispatch->{$CASE}->();

But this nice situation breaks down if C<$CASE> is a value that is not suitable
for us as a C<HASH> key, is a range of values, or a single variable (e.g.,
C<$CASE>) is not sufficient to determine what case to dispatch. C<Dispatch::Fu>
solves this problem by providing a stage where a static key might be computed
or classified.

=head2 The Solution

C<Dispatch::Fu> solves the problem by providing a I<Perlish> and I<idiomatic>
hook for computing a static key from an arbitrarily defined algorithm written
by the developer using this module.

The C<dispatch> keyword and associated lexical block (I<that should be treated
as the body of a subroutine that receives exactly one parameter>), determines
what I<case> defined by the C<on> keyword is immediately executed.

The simple case above can be trivially replicated below using C<Dispatch::Fu>,
as follows:

  my $results = dispatch {
    my $case = shift;
    return $case;
  },
  $CASE,
   on do_dis  => sub { ... },
   on do_dat  => sub { ... },
   on do_deez => sub { ... },
   on do_doze => sub { ... };

The one difference here is, if C<$case> is defined but not accounted for
using the C<on> keyword, then C<dispatch> will throw an exception via
C<die>. Certainly any logic meant to deal with the value (or lack thereof)
of C<$CASE> should be handled in the C<dispatch> BLOCK.

An example of a more complicated scenario for generating the static key might
be defined, follows:

  my $results = dispatch {
    my $input_ref = shift;
    my $rand  = $input_ref->[0];
    if ( $rand < 2.5 ) {
        return q{do_dis};
    }
    elsif ( $rand >= 2.5 and $rand < 5.0 ) {
        return q{do_dat};
    }
    elsif ( $rand >= 5.0 and $rand < 7.5 ) {
        return q{do_deez};
    }
    elsif ( $rand >= 7.5 ) {
        return q{do_doze};
    }
  },
  [ rand 10 ],
   on do_dis  => sub { ... },
   on do_dat  => sub { ... },
   on do_deez => sub { ... },
   on do_doze => sub { ... };

The approach facilited by C<Dispatch::Fu> is one that requires the programmer
to define each case by a static key via C<on>, and define a custom algorithm
for picking which case (by way of C<return>'ing the correct static key as
a string) to execute using the C<dispatch> BLOCK.

=head1 USAGE

For more working examples, look at the tests in the C<./t> directory. It
should quickly become apparent how to use this method and what it's for by
trying it out. But if in doubt, please inquire here, there, everywhere.

=over 4

=item C<dispatch> BLOCK

C<BLOCK> is required, and is coerced to be an anonymous subroutine that
is passed a single scalar reference; this reference can be a single value
or point to anything a Perl scalar reference can point to. It's the single
point of entry for input.

  my $results = dispatch {
    my $input_ref = shift; # <~ there is only one parameter, but can a reference to anything
    my $key = q{default};  # <~ initiate the default key to use, 'default' by convention not required
    ...                    # <~ compute $key (yada yada)
    return $key;           # <~ key must be limited to the set of keys added with C<on>
  }
  ...

The C<dispatch> implementation must return a static string, and that string
should be one of the keys added using the C<on> keyword. Otherwise, an exception
will be thrown via C<die>.

=item C<cases>

This routine is for introspection inside of the C<dispatch> BLOCK. It returns
the list of all cases added by the C<on> routine. Outside of the C<dispatch>
BLOCK, it returns an empty C<HASH> reference.

B<Note:> do not rely on the ordering of these cases to be consistent; it relies
on the C<keys> keyword, which operates on C<HASH>es and key order is therefore
not deterministic.

Given the full example above,

  my $results = dispatch {
    my $input_ref = shift;
    ...
    my @cases = cases; # (qw/do_dis do_dat do_deez do_doze/)
    ...
  },
  [ rand 10 ],
   on do_dis  => sub { ... },
   on do_dat  => sub { ... },
   on do_deez => sub { ... },
   on do_doze => sub { ... };

=item C<xdefault> SCALAR, [DEFAULT_STRING]

Note: SCALAR must be an actual value (string, e.g.) or C<undef>. 

Provides a shortcut for the common situation where one static value really
define the case key. Used idiomatically without the explicit return provided
it is as the very last line of the C<dispatch> BLOCK.

  my $results = dispatch {
    my $input_str = shift;
    xdefault $input_str, q{do_default}; # if $input_str is not in supported cases, return the string 'default'
  },
  $somestring,
   on do_default => sub { ... },        #<~ default case
   on do_dis     => sub { ... },
   on do_dat     => sub { ... },
   on do_deez    => sub { ... },
   on do_doze    => sub { ... };

C<xdefault> can be passed just the string that is checked for membership in C<cases>,
if just provided the I<default> case key, the string C<default> will be used if the
string being tested is not in the set of cases defined using C<on>.

  my $results = dispatch {
    my $input_str = shift;
    xdefault $input_str;      # if $input_str is not in the set of supported cases, it will return the string 'default'
  },
  $somestring,
   on default => sub { ... }, #<~ default case
   on do_dis  => sub { ... },
   on do_dat  => sub { ... },
   on do_deez => sub { ... },
   on do_doze => sub { ... };

And just for the sake of minimization, we can get rid of one more line here:

  my $results = dispatch {
    xdefault shift;           # if $input_str is not in supported cases, return the string 'default'
  },
  $somestring,
   on default => sub { ... }, #<~ default case
   on do_dis  => sub { ... },
   on do_dat  => sub { ... },
   on do_deez => sub { ... },
   on do_doze => sub { ... };

=item C<REF>

This is the singular scalar reference that contains all the stuff to be used
in the C<dispatch> BLOCK. In the example above it is, C<[rand 10]>. It is
the way to pass arbitrary data into C<dispatch>. E.g.,

  my $INPUT  = [qw/foo bar baz 1 3 4 5/];

  my $result = dispatch {
    my $input_ref = shift; # <~ there is only one parameter, but can a reference to anything
    my $key = q{default};  # <~ initiate the default key to use, 'default' by convention not required
    ...                    # <~ compute $key (yada yada)
    return $key;           # <~ key must be limited to the set of keys added with C<on>

  } $INPUT,                ### <><~ the single scalar reference to be passed to the C<dispatch> BLOCK
  ...

=item C<on>

This keyword builds up the dispatch table. It consists of a static string and
a subroutine reference. In order for this to work for you, the C<dispatch>
BLOCK must return strictly only the keys that are defined via C<on>.

  my $INPUT = [qw/foo bar baz 1 3 4 5/];

  my $results = dispatch {

    my $input_ref = shift; # <~ there is only one parameter, but can a reference to anything
    my $key = q{default};  # <~ initiate the default key to use, 'default' by convention not required
    ...                    # <~ compute $key (yada yada)
    return $key;           # <~ key must be limited to the set of keys added with C<on>

  } $INPUT,                ### <><~ the single scalar reference to be passed to the C<dispatch> BLOCK
   on case1 => sub { my $INPUT = shift; ... },
   on case2 => sub { my $INPUT = shift; ... },
   on case3 => sub { my $INPUT = shift; ... },
   on case4 => sub { my $INPUT = shift; ... },
   on case5 => sub { my $INPUT = shift; ... };

Note: when the subroutine associated with each I<case> is dispatched, the C<$INPUT> scalar is provide
as input.

  my $INPUT = [qw/foo bar baz 1 3 4 5/];

  my $results = dispatch {

    my $input_ref = shift;      # there is only one parameter, but can a reference to anything
    my $key    = q{default};    # initiate the default key to use, 'default' by convention not required
    ...                         # compute $key
    return $key;                # key must be limited to the set of keys added with C<on>

  } $INPUT,                     # <~ the single scalar reference to be passed to the C<dispatch> BLOCK
   on default  => sub {
     my $INPUT = shift;
     do_default($INPUT);
   },
   on key1     => sub {
     my $INPUT = shift;
     do_key1(cases => $INPUT);
   },
   on key2     => sub { 
     my $INPUT = shift;
     do_key2(qw/some other inputs entirely/);
   };

=back

=head1 BUGS

Please report any bugs or ideas about making this module an even better
basis for doing dynamic dispatching.

=head1 AUTHOR

O. ODLER 558 L<< <oodler@cpan.org> >>.

=head1 LICENSE AND COPYRIGHT

Same as Perl.
