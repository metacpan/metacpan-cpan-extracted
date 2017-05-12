package Inline::BC;
use strict;
use Carp;
require Inline;
require DynaLoader;
require Exporter;
use vars qw(@ISA $VERSION @EXPORT_OK $RUN_ONCE);
use vars qw($RE_balanced_brackets $RE_balanced_parens);
use vars qw($use_math_lib);

$use_math_lib = 0;    # assume BC's math library is not required
$VERSION      = '0.08';
@ISA = qw(Inline DynaLoader Exporter);

use Cwd qw(abs_path); 

use Data::Dumper;

my @export_ok = qw(bc_init bc_parse bc_run);

#==============================================================================
# lots of this code has been shamelessly stolen from Inline::Ruby :-)
#==============================================================================

sub dl_load_flags { 0x01 }
eval_support_code();


#==============================================================================
# Prep the BC interpreter
#==============================================================================
sub eval_support_code{
    return if $RUN_ONCE;
    Inline::BC->bootstrap($VERSION);
}



#==============================================================================
# Register BC.pm as a valid Inline language
#==============================================================================
sub register {
    return {
            language => 'BC',
            aliases => ['bc', 'Bc'],
            type => 'interpreted',
            suffix => 'bc',
           };
}

#==============================================================================
# Validate the BC config options
#==============================================================================
sub validate {
    my $o = shift;

    $o->{ILSM} ||= {};
    $o->{ILSM}{FILTERS} ||= [];
    $o->{ILSM}{built} ||= 0;
    $o->{ILSM}{loaded} ||= 0;
    
    $o->{ILSM}{bindto} = [qw(functions)];

    while (@_) {
	my ($key, $value) = (shift, shift);

	if ($key eq 'FILTERS') {
	    next if $value eq '1' or $value eq '0'; # ignore ENABLE, DISABLE
	    $value = [$value] unless ref($value) eq 'ARRAY';
	    my %filters;
	    for my $val (@$value) {
		if (ref($val) eq 'CODE') {
		    $o->add_list($o->{ILSM}, $key, $val, []);
	        }
		else {
		    eval { require Inline::Filters };
		    croak "'FILTERS' option requires Inline::Filters to be installed."
		      if $@;
		    %filters = Inline::Filters::get_filters($o->{API}{language})
		      unless keys %filters;
		    if (defined $filters{$val}) {
			my $filter = Inline::Filters->new($val, 
							  $filters{$val});
			$o->add_list($o->{ILSM},
				     $key,
				     [ $filter ],
				     [ ]);
		    }
		    else {
			croak "Invalid filter $val specified.";
		    }
		}
	    }
	}
	elsif ($key eq 'MATH_LIB') {
	    croak "Invalid value specified for config option 'MATH_LIB'"
	        if ($value ne '1' and $value ne '0');

	    if ($RUN_ONCE) {
	        if ($value ne $use_math_lib) {
		    warn("The BC interpreter was initialised with option ",
			 "MATH_LIB => $use_math_lib.\n",
			 "Any subsequent use of option 'MATH_LIB' will ",
			 "have no effect.\n");
		}
	    }
	    else {
	        $use_math_lib = $value;
	    }
	}
	else {
	    croak "$key is not a valid config option for BC";
	}
    }

    # Ensure the BC interpreter is initialised only once!
    unless ($RUN_ONCE) {
        bc_init( $use_math_lib );
	$RUN_ONCE = 1;
    }
}


sub usage_validate {
    return "Invalid value for config option $_[0]";
}


sub add_list {
    my $o = shift;
    my ($ref, $key, $value, $default) = @_;
    $value = [$value] unless ref $value;
    croak usage_validate($key) unless ref($value) eq 'ARRAY';
    for (@$value) {
	if (defined $_) {
	    push @{$ref->{$key}}, $_;
	}
	else {
	    $ref->{$key} = $default;
	}
    }
}


#==========================================================================
# Print a short information section if PRINT_INFO is enabled.
#==========================================================================
sub info {
    my $o = shift;
    my $info =  "";

    $o->build unless $o->{ILSM}{built};

    my @functions = @{$o->{ILSM}{namespace}{functions}||[]};
    $info .= "The following BC functions have been bound to Perl:\n"
      if @functions;
    for my $function (sort @functions) {
	$info .= "\tdefine $function()\n";
    }

    $info .= "\nThe BC math library has been loaded.\n" if ($use_math_lib);

    return $info;
}


#==========================================================================
# Run the code, study the main namespace, and cache the results.
#==========================================================================
sub build {
    my $o = shift;
    return if $o->{ILSM}{built};

    # Filter the code
    $o->{ILSM}{code} = $o->filter(@{$o->{ILSM}{FILTERS}});

    my $code = $o->{ILSM}{code};

    # get the function signatures
    # These regular expressions were derived from Regexp::Common v0.01.
    my $RE_comment_C   = q{(?:(?:\/\*)(?:(?:(?!\*\/)[\s\S])*)(?:\*\/))};
    my $RE_comment_Cpp = q{(?:\/\*(?:(?!\*\/)[\s\S])*\*\/|\/\/[^\n]*\n)};
    my $RE_quoted      = (q{(?:(?:\")(?:[^\\\"]*(?:\\.[^\\\"]*)*)(?:\")}
                        .q{|(?:\')(?:[^\\\']*(?:\\.[^\\\']*)*)(?:\'))});
    $RE_balanced_brackets =
        qr'(?:[{]((?:(?>[^{}]+)|(??{$RE_balanced_brackets}))*)[}])';
    $RE_balanced_parens   =
        qr'(?:[(]((?:(?>[^()]+)|(??{$RE_balanced_parens}))*)[)])';

    # First, we crush out anything potentially confusing.
    # The order of these _does_ matter.
    $code =~ s/$RE_comment_C/ /go;
    $code =~ s/$RE_comment_Cpp/ /go;
    $code =~ s/^\#.*(\\\n.*)*//mgo;
    $code =~ s/^[\n\s]+//s;
    $code =~ s/[\s\n]+$//s;
    $code =~ s/\n(\s*)?\n/\n/sg;
    $code =~ s/$RE_balanced_brackets/{ }/go;
    $code =~ s/\n//sg;
    my %functions = ();
    while ( $code =~ /define\s+(\w+)\s*?\((.*?)\)\s*?\{.*?\}/gs ){
      $functions{$1} = [ split(/,\s*?/, $2) ];
    }
    my $bytecode = bc_parse($o->{ILSM}{code});

    my $binding = "";
    foreach my $func ( keys %functions ){
       my $bcfunc = $func." ( ";
       $bcfunc .=  join(", ", map { "\$".$_ }(@{$functions{$func}}));
       $bcfunc .= " )";
       $binding .= <<END;
sub $func {
#    my \$self = shift;
END
       $binding .=  join("", map { "    my \$".$_." = shift;\n" }(@{$functions{$func}}));
       $binding .= <<END;
    return &Inline::BC::bc_run( &Inline::BC::bc_parse("$bcfunc\\n") );
}
END
    }

    # Cache the results
    require Inline::denter;
    my $namespace = Inline::denter->new->indent(
	*functions => \%functions,
	*filtered  => $o->{ILSM}{code},
	*bytecode  => $bytecode,
	*binding   => "package ".$o->{API}{pkg}.";\n".$binding,
    );

    $o->mkpath("$o->{API}{install_lib}/auto/$o->{API}{modpname}");

    open BCDAT, "> $o->{API}{location}" or
      croak "Inline::BC couldn't write parse information!";
    print BCDAT $namespace;
    close BCDAT;

    $o->{ILSM}{namespace} = \%functions;
    $o->{ILSM}{built}++;

}


#==============================================================================
# Load the code, run it, and bind everything to Perl
#==============================================================================
sub load {
    my $o = shift;
    return if $o->{ILSM}{loaded};

    # Load the code
    open BCDAT, $o->{API}{location} or 
      croak "Couldn't open parse info!";
    my $bcdat = join '', <BCDAT>;
    close BCDAT;

    require Inline::denter;
    my %bcdat = Inline::denter->new->undent($bcdat);
    $o->{ILSM}{namespace} = $bcdat{functions};
    $o->{ILSM}{code} = $bcdat{filtered};
    $o->{ILSM}{binding} = $bcdat{binding};
    $o->{ILSM}{loaded}++;

    # Run it
    bc_run(bc_parse($o->{ILSM}{code}));

    eval $o->{ILSM}{binding};
    croak $@ if $@;
}

#==============================================================================



=head1 NAME

Inline::BC -  Inline ILSM for bc the arbitrary precision math Language

=head1 SYNOPSIS

  use Inline BC;
  print x(int(rand(time())));
  __DATA__
  __BC__
  define x(a){
    scale = 20;
    return (a*3.456789);
  }
 

=head1 DESCRIPTION

Inline::BC is an ILSM (Inline Support Language Module ) for Gnu bc, the arbitrary
precision numeric processing language.  Inline::BC - like other ILSMs - allows you
to compile (well - render to byte code ), and run Gnu bc code within your Perl
program.

From the Gnu BC README:

bc is an arbitrary precision numeric processing language.  Syntax is
similar to C, but differs in many substantial areas.  It supports
interactive execution of statements.  bc is a utility included in the
POSIX P1003.2/D11 draft standard.

This version was written to be a POSIX compliant bc processor with
several extensions to the draft standard.  Option flags are available
to cause warning or rejection of the extensions to the POSIX standard.
For those who want only POSIX bc with no extensions, a grammar is
provided for exactly the language described in the POSIX document.
The grammar (sbc.y) comes from the POSIX document.  The Makefile
contains rules to make sbc.  (for Standard BC)

"end of quote"

Further documentation about Gnu bc can be found at:
  http://www.gnu.org/software/bc/bc.html
  http://www.gnu.org/manual/bc/html_mono/bc.html


one thing to note is that you should be careful with setting the global
bc parameters like ibase, obase, scale etc.  You should not set these in
the global code - instead, set them in each function, to avoid the chaos 
that would follow.

Looking at the test suite - there are examples of several different ways of 
invoking Inline::BC:

(1) code in the DATA statement
  use Inline BC;
  print x(4) == 5.3 ? "ok 2\n" : "not ok 2\n";
  __DATA__
  __BC__
  define x (a) {
    scale = 20
    return (a * 1.5);
  }

(2) inline code with here document
  use Inline BC => <<'END_BC';
  define z (a, b) {
    scale = 6
    t = a * .357;
    t = b / t;
    return ( t );
  }
  END_BC
  print z(4, 7) > 4 ? "ok 3\n" : "not ok 3\n";

(3) code in an external file
  use Inline BC => './tools/test.dat';
  print aa() =~ /[0\n]/s ? "ok 4\n" : "not ok 4\n";


=head1 CONFIG OPTIONS

Inline::BC provides the following config options.

B<MATH_LIB =E<gt> 0|1>

When Inline::BC is invoked with the config option 'MATH_LIB => 1',
then the GNU bc processor is initialised with its builtin math
library.
The math library offers the following builtin functions:

=over 4

=item s(x)

The sine of x, x is in radians.

=item c(x)

The cosine of x, x is in radians.

=item a(x)

The arctangent of x, arctangent returns radians.

=item l(x)

The natural logarithm of x.

=item e(x)

The exponential function, raising e to the value x.

=item j(n,x)

The Bessel function of integer order n of x.

=back

Example: Calculating the hyperbolic sine of a value.

use Inline BC => "DATA", MATH_LIB => 1;

my $r = bc_sinh(4.712);

__END__

__BC__
  define bc_sinh (u) {
    scale = 12
    t = (e(u) - e(-u)) * 0.5
    return ( t )
  }

An interesting point to note:

To calculate the square root of a number, GNU bc provides
the expression I<sqrt(x)>.  Because GNU bc treats it as an
expression rather than a function, there is no need to load
the math library in order to use sqrt(x).

B<FILTERS =E<gt> [ "filtnam1", ... ]>

The 'FILTERS' option allows the BC code to be pre-processed
before Inline passes it to the BC interpreter.  To use
existing pre-processing filters with Inline::BC the module
I<Inline::Filters> must be installed. This module provides
the filters C<Strip_POD>, C<Strip_Comments>, and
C<Preprocess>.

The filter C<Strip_POD> is used to remove POD documentation
contained in the BC code. C<Strip_Comments> will remove all
comments found in the BC code. The final filter, C<Preprocess>,
allows the programmer to embed C preprocessor directives in
the BC code. The filter processes these directives by invoking
the C preprocessor to generate code that can then be passed
to the BC interpreter.

In the following example, POD documentation is embedded in
the BC code. This must be removed before the BC code is
passed to the BC interpreter.

  use Inline BC => "DATA",
             MATH_LIB => 1,
             FILTERS  => [ qw(Strip_POD) ];

  my $r = bc_sinh(4.712);

  __END__

  __BC__
  =head1 BC Functions

  The following functions are defined in GNU bc language.

  =cut

  /*************************************/
  =pod

  Function Name: bc_sinh(x)
  Description  : Calculates the hyperbolic sine of real value x.
  Return       : The calculated result with 12 fractional decimal
               : digits of precision.

  =cut

  /*************************************/
  define bc_sinh (u) {
    scale = 12
    t = (e(u) - e(-u)) * 0.5
    return ( t )
  }


=head1 VERSION

Inline::BC 0.08

=head1 AUTHOR

Piers Harding - piers@cpan.org

=head1 SEE ALSO

 man bc
 perldoc Inline
 perldoc Inline::Filters

=head1 COPYRIGHT

Copyright (c) 2002, Piers Harding. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.


=cut

1;

