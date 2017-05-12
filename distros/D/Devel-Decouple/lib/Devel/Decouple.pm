# $Id$
package Devel::Decouple;

use strict;
use warnings;
use Carp;
use version; our $VERSION = qv(0.0.3);

use base 'Exporter';
our @EXPORT = qw{ from function functions as default_sub preserved };

use Class::Inspector;
use PPI::Document;
use PPI::Find;
use Monkey::Patch   qw{ patch_package };
use List::MoreUtils qw{ uniq };

### PUBLIC METHODS: ########################

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub decouple {
    my $self    = shift;
    my $module  = shift || croak q{You must supply a module name to the 'decouple' method};
    my @args    = @_;
    my $modules = shift @args if ref $args[0] eq 'ARRAY';
    
    # build the params hash
    my %params;
    $params{_MODULE_}   = $module;
    $params{_DOCUMENT_} = Class::Inspector->resolved_filename( $module )
                            or croak "could not resolve the canonical name of $module";
    $params{_MODULES_}  = $modules || '_ALL_';
    $params{_CODE_}     = { @args };
    $params{_CODE_}{_DEFAULT_} ||= sub { return };
    
    $self->{$_} = $params{$_} for keys %params;
    
    $self->_build;
    
    return $self;
}

sub module {
    my $self = shift;
    return $self->{_MODULE_};
}

sub document {
    my $self = shift;
    return $self->{_DOCUMENT_};
}

sub modules {
    my $self = shift;
    return exists $self->{_MODULES_}
        ? @{ $self->{_MODULES_} }
        : undef;
}

sub called_imports{
    my $self = shift;
    return exists $self->{_CALLED_IMPORTS_}
        ? @{ $self->{_CALLED_IMPORTS_} }
        : undef;
}

sub all_functions {
    my $self = shift;
    
    return $self->module
        ? @{Class::Inspector->functions( $self->module )}
        : undef;
}

sub revert{
    my $self      = shift;
    my @functions = @_;
    
    map { $self->{_PATCHES_}{$_} = undef } @functions;
    
    return $self;
}

sub report{
    my $self = shift;
    
    return $self->document
        ? $self->_build_report
        : croak qq{ 'report' called on uninitialized object };
}

### EXPORTS FOR SYNTACTIC SUGAR: ###########

sub from(\@;%) {
    return @_;
}

sub function($) {
    return shift;
}

sub functions(\@$;%) {
    my $functions = shift;
    my $code      = shift;
    my %args      = @_;
    
    my %map = map { $_ => $code } @{$functions};
    
    return %map, %args;
}

sub as(&) {
    return shift;
}

sub default_sub() {
    return '_DEFAULT_';
}

sub preserved() {
    return '_PRESERVED_';
}

### PRIVATE METHODS: #######################

sub _build {
    my $self   = shift;
    
    $self->_build_imports();
    $self->_set_code_substitutions();
}

sub _build_report {
    my $self    = shift;
    my $spacing = 20;
    my $indent  = 4;
    
    # format a simplistic report...
    my $report = "\nFunction-import usage statistics for ".($self->module||$self->document).":\n";
    
    for my $module ( $self->modules ){
        $report .= " "x($indent)."$module\n";
        map { $report .= " "x(2*$indent)."$_"." "x($spacing-length($_))."calls: ".
              $self->{_CALLED_IMPORT_STATS_}{$module}{$_}{ _NUMBER_OF_CALLS_ }."\tlines: ". 
              (join ',', @{$self->{_CALLED_IMPORT_STATS_}{$module}{$_}{_LINE_NUMBERS_}}).".\n" }
            sort keys %{$self->{_CALLED_IMPORT_STATS_}{$module}};
    }
    
    return $report;
}

sub _build_imports {
    my $self = shift;
    
    my ($CallFinder,$Document) = $self->_create_call_finder;
    my @found = $CallFinder->in( $Document );
    
    for my $module ( $self->_get_modules ){
        no strict 'refs';
        for my $function ( @{$module.'::EXPORT'}, @{$module.'::EXPORT_OK'} ){
            for my $token ( @found ){
                if ( $token eq $function ){
                    $self->{_CALLED_IMPORT_STATS_}{$module}{$function}{_NUMBER_OF_CALLS_}++;
                    push @{$self->{_CALLED_IMPORT_STATS_}{$module}{$function}{_LINE_NUMBERS_}}, $token->line_number;
                }
            }
        }
    }
    
    $self->{ _MODULES_ } = [ keys %{ $self->{_CALLED_IMPORT_STATS_} }];
    for my $module ( $self->modules ){
        push @{$self->{_CALLED_IMPORTS_}}, $_ for keys %{$self->{_CALLED_IMPORT_STATS_}{$module}};
    }
    
    return $self;
}

sub _get_modules {
    my $self    = shift;
    
    $self->{_MODULES_} eq '_ALL_'
        ? return map { my $module = $_; $module =~ s{\.pm}{}; $module }
                    map { my $module = $_; $module =~ s{[\/\\]}{::}g; $module }
                        grep { m{\.pm$} } keys %INC
        : return @{ $self->{_MODULES_} };
}

sub _create_call_finder {
    my $self = shift;
    
    my $Document = PPI::Document->new( $self->document );
    my $Finder   = PPI::Find->new(
                        sub {
                            $_[1]->isa( 'PPI::Element' ) | $_[1]->isa( 'PPI::Token' )
                                ? $_[0]->isa( 'PPI::Token::Word' )
                                    ? return 1
                                    : return 0
                                : return;
                        });
    
    return $Finder, $Document;
}

sub _set_code_substitutions{
    my $self = shift;
    
    for my $function ( uniq $self->called_imports, keys %{$self->{_CODE_}} ){
        next if ( (defined $self->{_CODE_}{$function} && ref $self->{_CODE_}{$function} ne 'CODE')
                    || $function eq '_DEFAULT_');
        
        if ( ref $self->{_CODE_}{$function} eq 'CODE' || ref $self->{_CODE_}{_DEFAULT_} eq 'CODE' ){
            $self->{_PATCHES_}{$function} = patch_package(
                    $self->module,                                              # module
                    $function,                                                  # function-name
                    ref $self->{_CODE_}{$function} eq 'CODE'                    # code
                        ? $self->{_CODE_}{$function}
                        : $self->{_CODE_}{_DEFAULT_}
                    ) or croak "couldn't install the code stub for '$function'";
        }
    }
}

1; # return true
__END__

=head1 NAME

Devel::Decouple - Decouple code from imported functions


=head1 SYNOPSIS

This module is intended to facilitate the testing and refactoring of legacy Perl code.

To generate a simple report about a module's or script's use of imported functions you can simply use the C<Devel::Decouple> subclass C<Devel::Decouple::DB> via the debugger.
    
    perl -d:Decouple::DB myscript.pl
    

Then, perhaps in a test file, you can redefine all those functions easily to decouple the problematic dependencies.
    
    # for the given module automatically redefine ALL
    # imported functions as no-ops... the default
    
    my $DD = Devel::Decouple->new();
    $DD->decouple( 'Some::Module' );
    
    
This module also provides for a high degree of customization of how, or whether, functions will be redefined, and to do so there is a clean declarative syntax.
    
    # only decouple the named module from those modules that are explicitly listed
    
    my @modules = qw{ Another::Module And::Another };
    $DD->decouple( 'Some::Module', from @modules );         # you MUST use a literal array here, not a list!
    
    
    # use the default (no-op) code stub... except where an alternative is
    # specified or the original imported function is explicitly preserved
    
    my @stooges = qw{ larry moe curly };
    $DD->decouple( 'Some::Module',
            function 'foo', as { return 2.167 },
            function 'bar', as { return 'hello' },
            function 'baz', preserved,
            functions @stooges,                             # again, you MUST use a literal array here!
                            as { return "I'm a stooge!" });
    
    
    # define a custom default code stub, as with this simple stack trace,
    # that re-dispatches to the original code
    
    $DD->decouple( 'Some::Module',
            default_sub, as { warn "calling '",  (caller(0))[3],
                                   "' from ",    (caller(1))[3],
                                   " at line ",  (caller(0))[2];
                              shift->(@_) });
    
    
=head1 DESCRIPTION

When testing software it's often useful to use dummy, or 'mock', objects to represent external dependencies. This practice presupposes that the code being tested is object-oriented and can usually simply accept these objects to its constructor, i.e. the dependencies are loosely-coupled and we can use simple dependency-injection tactics to test the code.

If only the world were always so simple.

Unfortunately, legacy Perl code-bases often tightly couple external dependencies by creating those dependencies either inside modules, or inside monolithic scripts.

When faced with maintaining and extending such code this brings to light several obvious and serious problems. First, pervasive hardcoding and tight coupling ties us to a particular (often production) implementation. This is a testing nightmare and it can be dangerous to even attempt to test some code in production environments without long and careful consideration of the consequences. Second, it seems to require us to make a lot of changes all over the code-base to try to isolate particular moving-parts so that we can specify controlled behavior. This controlled behavior could stem the side effects of the tightly coupled code in order to facilitate testing, but how can we change the code safely and confidently to do this without first having tests? It's a chicken and egg scenario.

Further, because legacy Perl code uses predominantly functional interfaces, rather than object orientation, it often pollutes the consumers name-space with imported functions (and other symbols) that can be difficult to identify. Our only recourse in the past has generally been to eyeball the code, perhaps several thousand lines of it, and make careful notes.

C<Devel::Decouple> is designed to do static analysis on the parts of the code that you intend to create Characterization tests (L<http://en.wikipedia.org/wiki/Characterization_Test>) for to facilitate refactoring. It can programmatically identify the imported functions that have I<actually been called> for the given name-space. It can also automatically install default stub functions into the symbol table to replace these functions, or allow the specification of individual and specialized behavior (e.g. returning mocked data from a tabular data-file or here-doc in a standard L<Test::More> test script).


=head1 INTERFACE 

=head2 new

=over

A simple contructor. It takes no arguments and returns an empty object.

=back

=head2 decouple

=over

A method to specify what and how to decouple the code in question. Please refer to the L<SYNOPSIS> and L<SYNTACTIC SUGAR> sections for full details about the options taken and how to use them.

=back


=head2 report

=over

Return a simple formatted report about the use of imported functions.

=back


=head2 revert [LIST]

=over

Un-patch the functions given in LIST.

=back


=head2 module

=over

Returns the name of the module being operated upon.

=back


=head2 document

=over

Returns the canonical name of the module being operated upon.

=back


=head2 modules

=over

Returns the names of the modules that are being decoupled from the module being operated upon. That is, either the constrained list of modules given to C<decouple> in the C<from> sub-clause (but only if their functions were actually called), or, if unconstrained, the list of all modules whose exported functions were actually called in the primary code.

=back


=head2 called_imports

=over

Returns the list of all imported functions that were actually called.

=back


=head2 all_functions

=over

Returns the list of all functions, but not methods, in the primary code's immediate namespace.

=back



=head1 SYNTACTIC SUGAR

C<Devel::Decouple> provides a decalrative syntax to specify how and what to decouple. Each statement can be thought of as a clause, and each clause (or sub-clause) needs to be seperated with a (plain) comma (i.e. not a 'fat-comma', aka 'quoting-comma').

The order of the clauses is significant but intuitive. The first clause is always the name of the module to operate upon followed by an optional array of modules you wish to decouple listed in a C<from> sub-clause. A C<function>, C<functions>, or C<default_sub> clause is always followed by either an C<as> sub-clause, which specifies the behavior you wish to implement for that entity, or the C<preserved> marker.

The special marker C<preserved> is used in place of an C<as> sub-clause to indicate that no custom behavior should be added to the symbol table for the entity in question.


=head2 from [@literal_array]

=over

Specify the explicit list of modules to decouple from the primary module. If not provided C<Devel::Decouple> will default to all modules whose imported functions were actually called.

=back


=head2 function [STRING]

=over

The name of a function in the primary module's name-space for which you wish to specify custom behavior. Use an C<as> clause to define the behavior itself.

=back


=head2 functions [@literal_array]

=over

The names of one or more functions in the primary module's name-space for which you wish to specify custom I<shared> behavior. Use an C<as> clause to define the behavior itself.

=back


=head2 as [{bare_code_block} | \&sub_ref]

=over

Behavior to install in the symbol table. The C<as> sub-clause must follow C<function>, C<functions>, or C<default_sub> separated by a comma.

=back


=head2 default_sub

=over

Specify the default override behavior for any called (imported) function that has no other explicitly defined custom behavior and which is not C<preserved>. Use an C<as> clause to define the behavior itself. If not specified the default C<default_sub> is a no-op that always simply returns C<undef>.

It is of course possible for the C<default_sub> to specify that the previously defined behavior should be preserved:

    # with the default_sub "preserved" and without any other behavior specified
    # the following statement would not affect the normal operation of My::Module...
    my $Decoupler = Devel::Decouple->new;
    $Decoupler->decouple( 'My::Module', default_sub, preserved );

If combined with specialized behavior in the C<as> sub-clause of a C<function> or C<functions> clause this permits surgical precision in what functions are redefined and how. See also, L<C<Devel::Decouple> ADVANCED TOPICS>.

=back


=head2 preserved

=over

The C<preserved> marker can be used in place of any C<as> sub-clause to indicate that the previous behavior of the imported function should be preserved.

=back



=head1 ADVANCED TOPICS

Internally the patching of the symbol table is carried out by the C<Monkey::Patch> module. As such there is a 'stack' of code definitions preserved for all function definitions up to and including the original source definition. As with all stacks we can push new entities (code definitions) onto the stack and also pop them off. By using this feature you can modify the behavior of your functions on-the-fly.

There is also the ability to redispatch to the next most recent previously defined code on the stack. By using this feature you can essentially create custom wrappers. These wrappers can alter the code by adding new features and behavior to previous code definitions.

These are very powerful features and can be used to great advantage individually or together.


=head2 The Stack

=over

Push code-definition entities onto the stack by calling C<decouple> on a new Devel::Decouple object instance and defining some new behavior, pop by calling C<revert> for specified functions on that instance... or by C<undef>ing the object entirely.

In contrast, calling C<decouple> on an I<already defined> C<Devel::Decouple> object will overwrite the definitions at that location on the stack. This behavior may not be what you intend, and care should be taken to preserve the behavior that's already been set-up, e.g. by using a C<default_sub, preserved> clause when redefining a C<Devel::Decouple> object instance.


    # Adapted from override.t in the Devel::Decouple test suite...
    
    ### THE ORIGINAL BEHAVIOR
    #           GOT                     EXPECTED
    is( TestMod::Baz::inhibit(),        "I'm inhibited"     );
    is( TestMod::Baz::prohibit(),       "I'm prohibited"    );
    
    
    ### OVERRIDING: pushing new function definitions onto the stack...
    
    ### PUSH
    my $DD1 = Devel::Decouple->new;
    $DD1->decouple( 'TestMod::Baz', from @modules,
                        function 'prohibit', as { return 2 },
                        function 'inhibit',  as { return 3 }
                        );
    
    is( TestMod::Baz::prohibit(),       2                   );
    is( TestMod::Baz::inhibit(),        3                   );
    
    
    ### PUSH
    my @functions = qw{ inhibit prohibit };
    my $DD2 = Devel::Decouple->new;
    $DD2->decouple( 'TestMod::Baz',
                        functions @functions, as { return "defined by \$DD2" }
                        );
    
    is( TestMod::Baz::inhibit(),        "defined by \$DD2"  );
    is( TestMod::Baz::prohibit(),       "defined by \$DD2"  );
    
    
    ### PUSH
    my @modules = qw{ TestMod::Foo TestMod::Bar };
    my $DD3 = Devel::Decouple->new;
    $DD3->decouple( 'TestMod::Baz', from @modules,
                        function 'prohibit', preserved,
                        function 'inhibit',  as { return "defined by \$DD3" }
                        );              ### NOTE: 'prohibit' is 'preserved'... thus, 'defined by $DD2'
    
    is( TestMod::Baz::inhibit(),        "defined by \$DD3"  );
    is( TestMod::Baz::prohibit(),       "defined by \$DD2"  );
    
    
    ### PUSH
    my $DD4 = Devel::Decouple->new;
    $DD4->decouple( 'TestMod::Baz', from @modules,
                        function 'inhibit',  as { return "defined by \$DD4" }
                        );              ### NOTE: 'prohibit' is redefined by the no-op 'default_sub'
    
    is( TestMod::Baz::inhibit(),        "defined by \$DD4"  );
    is( TestMod::Baz::prohibit(),       undef               );
    
    
    ### REVERTING: popping function definitions off the stack...
    
    ### POP
    undef $DD4;
    
    is( TestMod::Baz::inhibit(),        "defined by \$DD3"  );
    is( TestMod::Baz::prohibit(),       "defined by \$DD2"  );
    
    
    ### POP
    $DD3->revert( 'inhibit' );
    
    is( TestMod::Baz::inhibit(),        "defined by \$DD2"  );
    is( TestMod::Baz::prohibit(),       "defined by \$DD2"  );
    
    
    ### POP
    undef $DD2;
    
    is( TestMod::Baz::inhibit(),        3                   );
    is( TestMod::Baz::prohibit(),       2                   );
    
    ### And so on...
    
Caution should be exercised here as the C<Devel::Decouple> object instances are actually collections of stacks maintained for each function. It can become confusing to keep track of what behavior was specified in which objects and how those objects relate to the ordering of the underlying stacks. Please see L<Devel::Decouple Testing Kata> for some ideas about how to deal with this issue.

=back


=head2 Redispatching

=over

For any function definition you provide you have access to the immediately previous code definition on the stack. This behavior is passed to your new function definition as a sub-ref in the first element of C<@_>. The remainder of C<@_> contains the original arguments to the function.

    # Define a 'default_sub' that reports the arguments a function was called with
    # and then delegates back to the previous behavior on the stack...
    
    my $Decoupler = Devel::Decouple->new;
    $Decoupler->decouple( 'My::Module',
                        default_sub, as { my $orig = shift;
                                          warn ("'", caller(0))[3],
                                               "' called with args: ",
                                               join '=|=', @_;
                                          $orig->(@_)},                 # redispatch!
                        );

If you wish, you can redispatch to any arbitrary depth down the stack of function definitions in this way, continually passing the original arguments along until ultimately terminating at the original source function definition.

Combining the use of the stack and this re-dispatch mechanism is a powerful way to implement stack traces, data serialization, and other exploratory testing for I<all> the functions in a complex or convoluted name-space. C<Devel::Decouple> isn't just for redefining the imported functions, although these can be automated to a greater extent by the use of the C<default_sub> clause. C<Devel::Decouple> can redefine native functions when listed explicitly in a C<function> or C<functions> clause.

Using such a technique can help you to understand the behavior of legacy Perl code so that you can clear the seemingly insurmountable hurdle of writing the initial tests. By automating much of the exploratory analysis of dense code it can also aid you in gradually adding increasingly granular test cases as you begin to better understand the behavior of your code. Once you understand the behavior of your code well and have a handle on complex dependencies then safely refactoring toward a more modern and maintainable idiom is possible.

=back


=head2 Devel::Decouple Testing Kata

=over

Red. Green. Refactor.

Helpful code snippets coming soon...

=back



=head1 CONFIGURATION AND ENVIRONMENT

Devel::Decouple requires no configuration files or environment variables.


=head1 BUGS AND LIMITATIONS

C<Devel::Decouple> does not currently identify imported symbols other than subroutines.

Please report any bugs or feature requests to <F<dev@namimedia.com>>.


=head1 AUTHOR

Montgomery Conner <F<mconner@cpan.org>>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, NamiMedia <F<dev@namimedia.com>>. All rights reserved.

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