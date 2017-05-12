package Inline::Awk;


###############################################################################
#
# Inline::Awk - Add awk code to your Perl programs.
#
# John McNamara, jmcnamara@cpan.org
#
# Documentation after __END__
#


use strict;
use Carp;
require Inline;


use vars qw($VERSION @ISA);
@ISA = qw(Inline);
$VERSION = '0.04';


###############################################################################
#
# register(). This function is required by Inline See the Inline-API pod.
#
sub register {
    return {
                language => 'Awk',
                aliases  => ['AWK', 'awk'],
                type     => 'interpreted',
                suffix   => 'pl',
           };
}


###############################################################################
#
# build(). This function is required by Inline See the Inline-API pod.
#
# Unlike other inline modules we don't interface with a compiler or
# interpreter. Instead we translate the awk code into Perl code using a2p and
# eval it into the user's program.
#
# The main body of the awk code is wrapped in a sub called awk() that the user
# can call. It accepts arguments and localised them into @ARGV.
#
# Any functions are stripped out and given there own copy of the global
# variables created by a2p. This allows the user to write functions and then
# call them from Perl.
#
# The code is derived from Foo.pm. The majority of the smoke and mirrors is
# handled by Inline.
#
sub build {

    my $self    = shift;


    # Set up the path and object names.
    my $awk_obj;
    my $path    = $self->{API}{install_lib} .'/auto/' .$self->{API}{modpname};
    my $obj     = $self->{API}{location};
    ($awk_obj   = $obj) =~ s|$self->{API}{suffix}$|awk|;


    # Create the build directory if necessary.
    $self->mkpath($path) unless -d $path;


    # Get the awk code.
    my $awk_code = $self->{API}{code};


    # In awk a standalone END block implies a default PATTERN block.
    # This behaviour isn't replicated by a2p. Therefore, if the awk code
    # includes an END block we append an empty PATTERN block to force a2p
    # to generate the required while loop.
    #
    $awk_code .= "\n{}\n" if $awk_code =~ m[END(\s*)?{];


    # Create the awk "object" file. In this case it is just a source file.
    open  OBJ, "> $awk_obj" or croak "Can't open $awk_obj for output: $!\n";
    print OBJ  $awk_code;
    close OBJ;


    # Run the awk code through a2p to generate the Perl code.
    #
    my @code = `a2p $awk_obj`;
    chomp(@code);


    # Remove the shebang lines and the switch processing
    splice(@code, 0, 9);


    # Add code for processing args other than @ARGV and add a modified switch
    # processor to take account of the fact that the code is being called from
    # within a sub.
    #
    my @main = ( 'local @ARGV = @_ if @_;',
                 '',
                 '# process any FOO=bar switches',
                 'if (@ARGV) {',
                 '    eval "\$$1$2;" while $ARGV[0] =~ /^(\w+=)(.*)/ '.
                                                       '&& shift @ARGV;',
                 '}',
                 ''
               );


    # The following code is a workaround for the fact that a2p sometimes chomps
    # lines without setting $\ for subsequent print statements.
    #
    push @main, '$\ = "\n";' if grep { /\s+chomp;/ } @code;


    # Store global assignments for use in any subroutines. Variables can be
    # declared more than once so we use a hash to store the last declaration
    # only. We also deal with chained assignments such as $\ = $/ = "\n";.
    #
    my $globals;
    my %globals;

    foreach (@code) {
        last if /while \(/;             # Bail at first while
        last if /^sub /;                # or bail at first sub
        next unless /^(\$\S+)\s=\s/;    # Match assignment

        # Extract chained assignments
        my $line = $_;
        my @vars;
        push @vars, $1 while $line =~ s|^(\$\S+)\s=\s||;

        # Strip trailing comments, crudely
        $line =~ s|;\s+#.*|;|;

        # Literal value remains in $line
        foreach my $var (@vars) {
            $globals{$var} = "    $var = $line\n";
        }
    }


    # Format the globals for printing
    $globals = "\n". join '', values %globals;


    # Separate the main code from the subs.
    while (@code) {
        last if $code[0] =~ /^sub \w+ \{$/;
        push @main, shift @code;
    }


    # Add the global variable to any subroutines
    foreach (@code) {
        s/(^sub .*)/$1$globals/;
    }


    # Enclose the program main in a subroutine and prettify the code in case
    # anyone looks at it. Well...you're looking at this. ;-)
    #
    # Text::Tabs is probably overkill for the tab expansion.
    #
    for (@main) {                       # Indent code 4 spaces.
        $_ = "    $_" unless $_ eq '';
    }

    s[\t][' ' x 8]eg for @code;         # Expand tabs.
    s[\t][' ' x 8]eg for @main;         # Expand tabs.
    pop @main if $main[-1] eq '';       # Remove trailing blank line.
    unshift @main, "sub awk {";         # Add the function header.
    push @main, "}\n";                  # Add the function tail.


    # Join the main and subs into a single source.
    my $perl_code = join "\n", @main, @code, "\n";


    # Write the Perl code to the "object" file.
    open  OBJ, "> $obj" or croak "Can't open $obj for output: $!\n";
    print OBJ  $perl_code;
    close OBJ;
}


###############################################################################
#
# load(). This function is required by Inline See the Inline-API pod.
#
# This function reloads the Perl code created by build() and evals it into the
# user's program. Nice.
#
sub load {

    my $self    = shift;
    my $obj     = $self->{API}{location};

    # Re-read the converted Perl source code
    open OBJ, "$obj" or croak "Can't open $obj for reading $!";

    # Slurp Perl code
    my $code = do {local $/; <OBJ>};

    close OBJ;

    # Stop strict "vars" and "subs" propagating to the eval
    no strict;
    eval  "package $self->{API}{pkg};\n$code";
    croak "Problems compiling Perl code $obj: $@\n" if $@;
}


###############################################################################
#
# validate(). This function is required by Inline See the Inline-API pod.
#
sub validate {

    my $self = shift;
    # Place holder
}


###############################################################################
#
# info(). This function is required by Inline See the Inline-API pod.
#
sub info {

    my $self = shift;
    # Place holder
}


1;


__END__




=head1 NAME


Inline::Awk - Add awk code to your Perl programs.




=head1 SYNOPSIS


Call an awk function from a Perl program:


    use Inline AWK;

    hello("awk");

    __END__
    __AWK__

    function hello(str) {
        print "Hello " str
    }

Or, call an entire awk program using the C<awk()> function:

    use Inline AWK;

    awk(); # operates on @ARGV by default

    __END__
    __AWK__

    # Count the number of lines in a file
    END { print NR }




=head1 DESCRIPTION


The C<Inline::Awk> module allows you to include awk code in your Perl program. You can call awk functions or entire programs.

Inline::Awk works by converting awk code into Perl code using the C<a2p> utility which comes as standard with Perl. This means that you don't require awk to use the Inline::Awk module.

Here is an example of how you would incorporate some awk functions into a Perl program:

    use Inline AWK;

    $num = 5;
    $str = 'ciao';

    print square($num), "\n";
    print echo($str),   "\n";

    print "Now, back to our normal program.\n"

    __END__
    __AWK__

    function square(num) {
        return num * num
    }

    function echo(str) {
        return str " " str
    }

You can call an awk program via the C<awk()> function. Here is a simple version of the Unix utility C<wc> which counts the number of lines, words and characters in a file:

    use Inline AWK;

    awk();

    __END__
    __AWK__

    # Simple minded wc
    BEGIN {
        file = ARGV[1]
    }

    {
        words += NF
        chars += length($0) +1 # +2 in DOS
    }

    END {
        printf("%7d%8d%8d %s\n", NR, words, chars, file)
    }




=head2 awk()

The C<awk()> function is imported into you Inline::Awk program by default. It allows you to run C<Inline::Awk> code as a program and to pass arguments to it.

Say, for example, that you have an awk program called C<parsefile.awk> that is normally run like this:

    awk -f parsefile.awk type=1 example.ini

If you then turned C<parsefile.awk> into an Inline::Awk program, (perhaps by using the C<a2a> utility in the distro), you could run the code from within a Perl program as follows:

    awk('type=1', 'example.ini');

If you are using C<-w> or C<warnings> in your Perl program you should quote any literal string in the variable assignment that you pass:

    awk('type=ini',   'example.ini'); # gives a warning with -w
    awk('type="ini"', 'example.ini'); # no warning

The default action of an awk program is to loop over the files that it is passed as arguments. Therefore, the C<awk()> function without arguments is equivalent to inserting the following code into your Perl program:

    while (<>) {
        # Converted awk code here
    }

As usual, the empty diamond operator, C<E<lt>E<gt>> will operate on C<@ARGV>, shifting off the elements until it is empty. Therefore, C<@ARGV> will be cleared after you call C<awk()>. However, C<awk()> creates a C<local> copy of any arguments that it receives so you can avoid clearing C<@ARGV> by passing it as an argument:

    awk(@ARGV);
    # Do something else with @ARGV in Perl

An awk program doesn't loop over a file if it contains a BEGIN block only:

    use Inline AWK;

    awk();

    __END__
    __AWK__

    BEGIN { print "Hello, world!" }


As with all Perl functions the return value of C<awk()> is the last expression evaluated. This is an unintentional feature but you may find a use for it.

If your program only has awk functions and no awk program you can ignore C<awk()>. However, it is still imported into you Perl program.




=head1 HOW TO USE Inline::Awk

You can use C<Inline::Awk> in any of the following ways. See also the Inline documentation:

Method 1 (the standard method):

    use Inline AWK;

    # Call the awk code

    __END__
    __AWK__

    # awk code here

Method 2 (for simple code):

    use Inline AWK => "# awk code here";


Method 3 (requires Inline::Files):

    use Inline::Files;
    use Inline AWK;

    # Call the awk code

    __AWK__

    # awk code here

Note, any of the following use declarations are valid:

    use Inline awk;
    use Inline Awk;
    use Inline AWK;

However, they should be matched by a corresponding data section:

    __awk__
    __Awk__
    __AWK__




=head1 HOW Inline::Awk works

C<Inline::Awk> in based on the same framework that underlies all of the C<Inline::> modules. This is described in detail in the C<Inline-API> document.

Inline::Awk works by filtering awk code through the Perl utility C<a2p>. The a2p utility converts awk code to Perl code using a parser written in C and YACC. Inline::Awk pre and post-processes the code going through a2p to obtain a result that is as close as possible to the output of a real awk compiler. However, it doesn't always get it completely right, see L<BUGS>.

Nevertheless, Inline::Awk can compile and run 130 of the code examples and programs in "The AWK Programming Language" and produce the same results as awk, mawk or gawk. It can run an additional 20 programs from the book with only minor modifications to the awk code. See, the regression test at: http://homepage.eircom.net/~jmcnamara/perl/iawk_regtest_0.03.tar.gz


=head1 BUGS


While C<a2p> does a very good job of converting awk code to Perl it was never intended for the use that C<Inline::Awk> put it to. Where possible Inline::Awk compensates for the cases where a2p differs from awk. However, you may still encounter bugs or discrepancies. The following sections give some hints on how to work around these, ahem, issues.


=head2 String versus numeric context

Awk uses the same equality operators for both numbers and strings whereas Perl uses different operators. For example consider the following awk function:

    function max(m, n) {
        return (m > n ? m : n)
    }

There isn't enough information here for a2p to tell if C<m> and C<n> will be numeric or string values so it defaults to a string comparison and generates a warning (See the L<THE VOICE OF LARRY>):

    sub max {
        local($M, $n) = @_;
        ($M gt $n ? $M : $n);   #???
    }

This is probably not what was intended.

However, a2p will take into account any previous uses of a variable in a numeric or string context. Therefore, the following modified code:

    function max(m, n) {
        m += 0;
        return (m > n ? m : n)
    }

Will produce a numeric comparison (although the warning is still generated):

    sub max {
        local($M, $n) = @_;
        $M += 0;
        ($M > $n ? $M : $n);    #???
    }


=head2 Return statements

In an awk function C<return expression> is a valid statement for any valid expression. However, some expressions can cause problems for a2p. For example the following function would cause a translation failure:

    function isnum(n) { return n ~ /^[+-]?[0-9]+$/ }    # Fails

The simple workaround for this is to include parenthesis around any complex expression in a return statement:

    function isnum(n) { return (n ~ /^[+-]?[0-9]+$/) }  # Passes


=head2 The ternary operator

A2p can also have problems with the ternary operator C<exp1 ? exp2 : exp3> when it is used in complex expressions. Therefore, it is best to put parentheses around all ternary conditionals.

    printf "Found %d file%s", n,  n == 1 ? "": "s"      # Fails
    printf "Found %d file%s", n, (n == 1 ? "": "s")     # Passes

This isn't a problem for simpler assignments.


=head2 The module name

Since I have always wanted to write an awk compiler it would have been nice to call the module C<Inline::Jawk>: that is to say, John's awk. However, I was chastened by the BUGS section of the mawk man page where mawk's author Mike Brennan says: "Implementors of the AWK language have shown a consistent lack of imagination when naming their programs.".




=head1 THE VOICE OF LARRY

The following warning indicates that C<a2p> couldn't determine if a string or numeric context was required at some point in your awk code:

    Please check my work on the lines I've marked with "#???".
    The operation I've selected may be wrong for the operand types.

See, the BUGS section for an explanation of why you should heed this warning.

Due to the nature of the Inline mechanism you will only see this warning the first time that you run your program. This may be a good thing or a bad thing, it depends on your point of view.




=head1 RATIONALE

The utility of this module is questionable: it doesn't do much
more than you can already do with C<a2p>; you can do something similar
with C<Filter::exec "a2p";> and even without C<a2p> it's generally easy to
translate awk code to Perl code.

However, I am fond of awk and if nothing else it will give Brian
Ingerson an extra bullet point on his Inline languages slide.

Also, C<Inline::Awk> serves as an atonement for C<Inline::PERL>. ;-)




=head1 SEE ALSO


Inline.pm, the Inline API and Foo.pm.

"The AWK Programming Language" by Alfred V. Aho, Brian W. Kernighan, and Peter J. Weinberger, Addison-Wesley, 1988. ISBN 0-201-07981-X.




=head1 ACKNOWLEDGEMENTS

Thanks to Brian Ingerson for the excellent C<Inline::C> and the C<Inline> framework.




=head1 AUTHOR

John McNamara jmcnamara@cpan.org




=head1 COPYRIGHT

© MMI, John McNamara.


All Rights Reserved. This module is free software. It may be used,
redistributed and/or modified under the same terms as Perl itself.
