########################################################################
# housekeeping
########################################################################
package Keyword::Value v0.1.2;
use v5.22;

use Keyword::Declare;

use Data::Lock      qw( dlock           );
use Carp            qw( carp croak      );

########################################################################
# package variables
########################################################################

our @CARP_NOT   = ( __PACKAGE__ );

# variable avoids having to export the sub into every caller's space.

our $const
= sub : lvalue
{
    state $verbose  = $ENV{ VERBOSE_KEYWORD_VALUE } // '';

    # lvalue delays dlock until after state sets its own magic flag.

    $_[0] = $_[1] if @_ > 1;

    $_[0] // carp "Fixing undefined value"
    if $verbose;

    dlock $_[0];

    # returns ref from stack to allow assignment via lvalue.

    $_[0]
};

########################################################################
# exported subs
########################################################################

sub import
{
    # defined inside of "import" this pushes the "value" keyword
    # into the caller's space.
    #
    # lock a variable (i.e., with a sigil).
    # lacking a leading variable, constify the entire expression.

    keyword value( Var $var, Expr $expr )
    {
        ( 0 > index "$var", '::' )
        ? "\$Keyword::Value::const->( my $var $expr )"
        : "\$Keyword::Value::const->(    $var $expr )"
    }

    keyword value ( Expr $expr )
    {{{
        $Keyword::Value::const->( <{$expr}> )
    }}}
}

# keep require happy
1
__END__

=head1 NAME

Keyword::Value -- assign a constant to a variable or symbol.

=head1 SYNOPSIS

    # "value" takes either a variable definition and expression
    # or an expression. the result is locked using Data::Lock.

    use Keyword::Value;    

    value my    $foo    = 'bar';
    value our   $bletch = 'blort';
    value state $bim    = 'bam';
    value       %::blah = ( 'a' .. 'z' );
    value my    @stuff  = ( 1 .. 100 );

    # default is to create a lexical variable if the 
    # variable name lacks '::'.
    #
    # these have identical results in the code:

    value   my $a = 'b';
    value      $a = 'b';

    # at this point modification via assignment to the 
    # variable or sub-parts, undef, delete, push, pop, or
    # assignment to a new key/offset will with an error
    # about modifying a read-only value, disallowed key,
    # readonly offset, or readonly key.


    sub foo
    {
        # return a constant value to the caller.

        value sha256 @_
    }

    # carp if the constant value is undef since that
    # usually indicates an error.

    $ VERBOSE_KEYWORD_VALUE=1 someprog;


    #!/bin/env perl
    ...

    sub blah
    {
        # restrict carp to one call-tree in order to 
        # trace where the undef comes from.
        
        local $ENV{ VERBOSE_KEYWORD_VALUE } = 1;

        ...
    }
   
    $ENV{ VERBOSE_KEYWORD_VALUE } = 1;

=head1 DESCRIPTION

This module installs a "value" keyword which can be used to create
constant-valued varabies in Perl5. The "value" keyword can be applied
to simple scalars, nested structures such as arrays or hashes, or 
the return value of subroutine calls.

The normal use case will be avoiding modification to values that 
percolate through multiple levels of code or when tracking down 
errors due to accidentally-modified variables.

My aproach here is to use Data::Lock and an lvalue function to 
modify $_[0] on the stack, which locks the referenced variable.

=head1 SEE ALSO

=over 4

=item Data::Lock

This is where the locking mechanism comes from, and includes an 
unlock (useful for debugging and testing) and description of how
the locks work.

=item perldoc perlsub

Use of ":lvalue" used in local sub to actually perform the locking.

=back

=head1 AUTHOR

Steven Lembark <lembark@wrkhors.com>

=head1 LICENSE

This code is licensed under the same terms as Perl-5.22 or any
later version of Perl.

