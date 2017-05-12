package Error::Base::Cookbook;

use 5.008008;
use strict;
use warnings;
use version; our $VERSION = qv('v1.0.2');

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                                                           #
#   Do not use this module directly. It only implements the POD snippets.   #
#                                                                           #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

my @td          ;
sub _get_test_data { @td };

#~         -end    => 1,   # # # # # # # END TESTING HERE # # # # # # # # # 
#~         -do     => 1, 

#----------------------------------------------------------------------------#

sub _words {                         # sloppy match these strings
    my @words   = @_;
    my $regex   = q{};
    
    for (@words) {
        $_      = lc $_;
        $regex  = $regex . $_ . '.*';
    };
    
    return qr/$regex/is;
};

#----------------------------------------------------------------------------#

=head1 NAME

Error::Base::Cookbook - Examples of Error::Base usage

=head1 VERSION

This document describes Error::Base version v1.0.2

=head1 WHAT'S NEW

=over

=item *

Update examples to track API changes.

=back

=head1 DESCRIPTION

Basic use of L<Error::Base|Error::Base> is quite simple; 
and advanced usage is not hard. 
The author hopes that nobody is forced to consult this Cookbook. But I am 
myself quite fond of cookbook-style documentation; I get more from seeing it 
all work together than from cut-and-dried reference manuals. I like those too, 
though; and comprehensive reference documentation is found in 
L<Error::Base|Error::Base>.

If you make use of Error::Base and don't find a similar example here in its 
Cookbook, please be so kind as to send your use case to me for future 
inclusion. Thank you very much.

=head1 EXAMPLES

The examples shown here in POD are also present as executable code. 

=head2 Sanity Check

=cut

{   #
    push @td, {
        -case   => 'sanity-zero',
        -do     => 1, 
        -code   => sub{
#
    my $obviously_true  = 0;
    Error::Base->crash('Unexpected zero')
        unless $obviously_true;
#
            },
        -lby    => 'die',
        -want   => qr/Unexpected zero/,
    };
}   #

=pod

    my $obviously_true  = 0;
    Error::Base->crash('Unexpected zero')
        unless $obviously_true;

You are certain that this will never happen but you decide to check it anyway. 
No need to plan ahead; just drop in a sanity check. 

=cut

{   #
    my ($case1, $case2, $case3, $pointer);
    push @td, {
        -case   => 'sanity-case',
        -do     => 1, 
        -code   => sub{
#
    if    ( $case1 ) { $pointer++ } 
    elsif ( $case2 ) { $pointer-- } 
    elsif ( $case3 ) {  } 
    else             { Error::Base->crash('Unimplemented case') };
#
            },
        -lby    => 'die',
        -want   => qr/Unimplemented case/,
    };
}   #

=pod

    if    ( $case1 ) { $pointer++ } 
    elsif ( $case2 ) { $pointer-- } 
    elsif ( $case3 ) {  } 
    else             { Error::Base->crash('Unimplemented case') };

In constructs like this, it's tempting to think you've covered every possible 
case. Avoid this fallacy by checking explicitly for each implemented case. 

    Error::Base->crash;         # emits 'Undefined error.' with backtrace.
    
Don't forget to pass some error message text. Unless you're in real big foo.

=head2 Construct First

=cut

{   #
    push @td, {
        -case   => 'construct-first-foo',
        -do     => 1, 
        -code   => sub{
#
    my $err     = Error::Base->new('Foo');
    $err->crash;
#
            },
        -lby    => 'die',
        -want   => qr/Foo/,
    };
}   #

{   #
    push @td, {
        -case   => 'construct-first-123',
        -do     => 1, 
        -code   => sub{
#
    my $err     = Error::Base->new(
                        'Third',
                    -base     => 'First',
                    -type     => 'Second',
                );
    $err->crash;
#
            },
        -lby    => 'die',
        -want   => qr/First Second Third/,
    };
}   #

=pod

    my $err     = Error::Base->new('Foo');
    $err->crash;
    
    my $err     = Error::Base->new(
                        'Third',
                    -base     => 'First',
                    -type     => 'Second',
                );
    $err->crash;

If you like to plan your error ahead of time, invoke 
L<new()|Error::Base/new()> with any set of arguments you please. 
This will help keep your code uncluttered. 

=head2 Construct and Throw in One Go

=cut

{   #
    push @td, {
        -case   => 'one-go',
        -do     => 1, 
        -code   => sub{
#
    Error::Base->crash(
        -base     => 'First',
        -type     => 'Second',
        -mesg     => 'Third',
    );
#
            },
        -lby    => 'die',
        -want   => qr/First Second Third/,
    };
}   #

=pod

    Error::Base->crash(
        -base     => 'First',
        -type     => 'Second',
        -mesg     => 'Third',
    );

You aren't I<required> to construct first, though. Each of the public methods 
L<crash()|Error::Base/crash()>, L<crank()|Error::Base/crank()>, 
and L<cuss()|Error::Base/cuss()> function as constructors and may be called 
either as a class or object method. Each method accepts all the same 
parameters as L<new()|Error::Base/new()>. 

=head2 Avoiding Death

=cut

{   #
    push @td, {
        -case   => 'avoid-death-crank-gruel',
        -do     => 1, 
        -code   => sub{
#
    Error::Base->crank('More gruel!');          # as class method
#
            },
        -lby    => 'warn',
        -want   => qr/More gruel!/,
    };
}   #

{   #
    push @td, {
        -case   => 'avoid-death-un-err',
        -do     => 1, 
        -code   => sub{
#
    my $err = Error::Base->new;
    $err->crank;                                # as object method
#
            },
        -lby    => 'warn',
        -want   => qr/Undefined error/,
    };
}   #

{   #
    push @td, {
        -case   => 'avoid-death-tommy',
        -do     => 1, 
        -code   => sub{
#
    my $err = Error::Base->new('See me');
    $err->cuss('Feel me');                      # trace stored in object
#
            },
        -lby    => 'return-scalar',
        -want   => qr/Feel me/,
    };
}   #

{   #
    push @td, {
        -case   => 'avoid-death-cusswords',
        -do     => 1, 
        -code   => sub{
#
    my $err = Error::Base->cuss('x%@#*!');      # also a constructor
#
            },
        -lby    => 'return-object',
        -want   => _words(qw/
            bless frames eval file line package sub
            lines
                     at line
                     at line
                ____ at line
            error base
            /),
    };
}   #

=pod

    Error::Base->crank('More gruel!');          # as class method
    
    my $err = Error::Base->new;
    $err->crank;                                # as object method
    
    my $err = Error::Base->new('See me');
    $err->cuss('Feel me');                      # trace stored in object
    
    my $err = Error::Base->cuss('x%@#*!');      # also a constructor

L<crank()|Error::Base/crank()> B<warn>s of your error condition. Perhaps it's 
not that serious. The current fashion is to make almost all errors fatal but 
it's your call. 

L<cuss()|Error::Base/cuss()> neither B<die>s nor B<warn>s but it does perform 
a full backtrace from the point of call. You might find it most useful when 
debugging your error handling itself; substitute 'crash' or 'crank' later. 

=head2 Escalation

=begin fool_pod_coverage

Really think we don't want to document the dummies. 

=head2 cook_dinner

=head2 serve_chili

=head2 add_recipie

=end   fool_pod_coverage

=cut

# dummy subs
sub cook_dinner {};
sub serve_chili {};
sub add_recipie {};
#~ my $err     = Error::Base->new( -base => 'Odor detected:', -quiet => 1 );
#~ my $err     = Error::Base->new( -base => 'Odor detected:' );
{   #
my $err     = Error::Base->new( -base => 'Odor detected:' );
my ( $fart, $room, $fire ) = ( 0, 0, 0 );
    push @td, {                         # no fart
        -case   => 'escalate-odor',
        -do     => 1, 
        -code   => sub{
#
    cook_dinner;
    $err->init( _cooked => 1 );
    
    serve_chili('mild');
    $err->cuss ( -type => $fart )           if $fart;
    $err->crank( -type => 'Air underflow' ) if $fart > $room;
    add_recipie( $err );
    
    serve_chili('hot');
    $err->crash( -type => 'Evacuate now' )  if $fire;
#
    $err;
            },
        -lby    => 'return-object',
        -want   => qr/Odor detected:/,
    };
}   #

{   #
my $err     = Error::Base->new( -base => 'Odor detected:' );
my ( $fart, $room, $fire ) = ( 1, 1, 0 );
    push @td, {                         # some fart
        -case   => 'escalate-fart',
        -do     => 1, 
        -code   => sub{
#
    cook_dinner;
    $err->init( _cooked => 1 );
    
    serve_chili('mild');
    $err->cuss ( -type => $fart )           if $fart;
    $err->crank( -type => 'Air underflow' ) if $fart > $room;
    add_recipie( $err );
    
    serve_chili('hot');
    $err->crash( -type => 'Evacuate now' )  if $fire;
#
    $err;
            },
        -lby    => 'return-object',
        -want   => qr/Odor detected: 1/,
    };
}   #

{   #
my $err     = Error::Base->new( -base => 'Odor detected:' );
my ( $fart, $room, $fire ) = ( 5, 1, 0 );
    push @td, {                         # too much fart
        -case   => 'escalate-room',
        -do     => 1, 
        -code   => sub{
#
    cook_dinner;
    $err->init( _cooked => 1 );
    
    serve_chili('mild');
    $err->cuss ( -type => $fart )           if $fart;
    $err->crank( -type => 'Air underflow' ) if $fart > $room;
    add_recipie( $err );
    
    serve_chili('hot');
    $err->crash( -type => 'Evacuate now' )  if $fire;
#
    $err;
            },
        -lby    => 'return-object',
        -want   => qr/Odor detected: Air underflow/,
        -cranky => 1,
    };
}   #

{   #
my $err     = Error::Base->new( -base => 'Odor detected:' );
my ( $fart, $room, $fire ) = ( 0, 0, 1 );
    push @td, {                         # FIRE
        -case   => 'escalate-fire',
        -do     => 1, 
        -code   => sub{
#
    cook_dinner;
    $err->init( _cooked => 1 );
    
    serve_chili('mild');
    $err->cuss ( -type => $fart )           if $fart;
    $err->crank( -type => 'Air underflow' ) if $fart > $room;
    add_recipie( $err );
    
    serve_chili('hot');
    $err->crash( -type => 'Evacuate now' )  if $fire;
#
            },
        -lby    => 'die',
        -want   => qr/Odor detected: Evacuate now/,
        -cranky => 1,
    };
}   #

=pod

    my $err     = Error::Base->new( -base => 'Odor detected:' );
    cook_dinner;
    $err->init( _cooked => 1 );
    
    serve_chili('mild');
    $err->cuss ( -type => $fart )           if $fart;
    $err->crank( -type => 'Air underflow' ) if $fart > $room;
    add_recipie( $err );
    
    serve_chili('hot');
    $err->crash( -type => 'Evacuate now' )  if $fire;

Once constructed, the same object may be thrown repeatedly, with multiple 
methods. On each invocation, new arguments overwrite old ones but previously 
declared attributes, public and private, remain in force if not overwritten. 
Also on each invocation, the stack is traced afresh and the error message text 
re-composed and re-formatted. 

=head2 Trapping the Fatal Error Object

=cut

{   #
    push @td, {
        -case   => 'eval',
        -do     => 1, 
        -code   => sub{
#
    eval{ Error::Base->crash('Houston...') };   # trap...
    my $err     = $@ if $@;                     # ... and examine the object
#
            },
        -lby    => 'return-object',
        -want   => _words(qw/
            bless frames eval file line package sub
            lines
                houston
                     at line
                     at line
                ____ at line
            error base
            /),
    };
}   #

=pod

    eval{ Error::Base->crash('Houston...') };   # trap...
    my $err     = $@ if $@;                     # ... and examine the object

L<crash()|Error::Base/crash()> does, internally, construct an object if called 
as a class method. If you trap the error you can capture the object and look 
inside it. 

=head2 Backtrace Control

=cut

{   #
my $err     = Error::Base->new;
    push @td, {
        -case   => 'backtrace-quiet',
        -do     => 1, 
        -code   => sub{
#
    $err->crash( -quiet         => 1, );        # no backtrace
#
            },
        -lby    => 'die',
        -want   => qr/Undefined error\.$/,
    };
}   #

{   #
my $err     = Error::Base->new;
    push @td, {
        -case   => 'backtrace-nest(-2)',
        -do     => 1, 
        -code   => sub{
#
    $err->crash( -nest           => -2, );        # really full backtrace
#
            },
        -lby    => 'die',
        -want   => _words(qw/
            undefined error
            error base fuss     at line
            error base crash    at line
                     at line
                     at line
                ____ at line
            /),
    };
}   #

{   #           # this test could be better: but implementation will change
my $err     = Error::Base->new;
    push @td, {
        -case   => 'backtrace-nest(+2)',
        -do     => 1, 
        -code   => sub{
#
    $err->crash( -nest           => +2, );       # skip top five frames
#
            },
        -lby    => 'die',
        -want   => _words(qw/
            undefined error
                     at line
                     at line
                ____ at line
            /),
    };
}   #

=pod

    $err->crash( -quiet         => 1,  );       # no backtrace
    $err->crash( -nest          => -2, );       # really full backtrace
    $err->crash( -nest          => +2, );       # skip two more top frames

Set L<-quiet|Error::Base/-quiet> to any TRUE value to silence stack 
backtrace entirely. 

By default, you get a full stack backtrace: "full" meaning, from the point of
invocation. Some stack frames are added by the process of crash()-ing itself; 
by default, these are not seen. If you want more or fewer frames you may set 
L<-nest|Error::Base/-nest> to a different value. 

Beware that future implementations may change the number of stack frames 
added internally by Error::Base; and also you may see a different number of 
frames if you subclass, depending on how you do that.  

=cut

=head2 Wrapper Routine

=cut

{   #
    sub _crash { Error::Base->crash( @_, -nest => +1 ) };
    my $obviously_true; 
    push @td, {
        -case   => 'wrapper',
        -do     => 1, 
        -code   => sub{
#
    # ... later...
    _crash('Unexpected zero')
        unless $obviously_true;
#
            },
        -lby    => 'die',
        -want   => qr/Unexpected zero/,
    };
}   #

=pod

    sub _crash { Error::Base->crash( @_, -nest => +1 ) }; 
    # ... later...
    _crash('Unexpected zero')
        unless $obviously_true;

Write a wrapper routine when trying to wedge sanity checks into dense code. 
Error::Base is purely object-oriented and exports nothing. 
Don't forget to use L<-nest|Error::Base/-nest> to drop additional frames 
if you don't want to see the wrapper in your backtrace. 

=head2 Dress Left

=cut

{   #
    push @td, {
        -case   => 'prepend-only',
        -do     => 1, 
        -code   => sub{
#
    Error::Base->crash ( 
        -mesg       => 'Let\'s eat!', 
        -prepend    => '@! Black Tie Lunch:',
    );
        # emits "@! Black Tie Lunch: Let's eat!
        #        @                   in main::fubar at line 42    [test.pl]"
#
            },
        -lby    => 'die',
        -want   => qr/\@! Black Tie Lunch: Let's eat!.\@                   in/s,
    };
}   #

{   #
    push @td, {
        -case   => 'prepend-indent',
        -do     => 1, 
        -code   => sub{
#
    Error::Base->crash ( 
        -mesg       => 'Let\'s eat!', 
        -prepend    => '@! Black Tie Lunch:',
        -indent     => '%--' 
    );
        # emits "@! Black Tie Lunch: Let's eat!
        #        %-- in main::fubar at line 42    [test.pl]"
#
            },
        -lby    => 'die',
        -want   => qr/\@! Black Tie Lunch: Let's eat!.%-- in/s,
    };
}   #

{   #
    push @td, {
        -case   => 'indent-only',
        -do     => 1, 
        -code   => sub{
#
    Error::Base->crash ( 
        -mesg       => 'Let\'s eat!', 
        -indent     => '%--' 
    );
        # emits "%-- Let's eat!
        #        %-- in main::fubar at line 42    [test.pl]"
#
            },
        -lby    => 'die',
        -want   => qr/%-- Let's eat!.%-- in/s,
    };
}   #

=pod

    Error::Base->crash ( 
        -mesg       => 'Let\'s eat!', 
        -prepend    => '@! Black Tie Lunch:',
    );
        # emits "@! Black Tie Lunch: Let's eat!
        #        @                   in main::fubar at line 42    [test.pl]"

    Error::Base->crash ( 
        -mesg       => 'Let\'s eat!', 
        -prepend    => '@! Black Tie Lunch:',
        -indent     => '%--' 
    );
        # emits "@! Black Tie Lunch: Let's eat!
        #        %-- in main::fubar at line 42    [test.pl]"

    Error::Base->crash ( 
        -mesg       => 'Let\'s eat!', 
        -indent     => '%--' 
    );
        # emits "%-- Let's eat!
        #        %-- in main::fubar at line 42    [test.pl]"

Any string passed to L<-prepend|Error::Base/-prepend> will be prepended to 
the first line only of the formatted error message. 
If L<-indent|Error::Base/-indent> is defined then that will be
prepended to all following lines. If -indent is undefined then it will 
be formed (from the first character only of -prepend) 
and (padded with spaces to the length of -prepend). 
If only -indent is defined then it will be prepended to all lines. 
You can override default actions by passing the empty string. 

=head2 Message Composition

=cut

{   #
    my $err     = Error::Base->new;
    push @td, {
        -case   => 'null',
        -do     => 1, 
        -code   => sub{
#
    $err->crash;                        # 'Undefined error'
#
            },
        -lby    => 'die',
        -want   => qr/Undefined error/s,
    };
}   #

{   #
    my $err     = Error::Base->new;
    push @td, {
        -case   => 'pronto-only',
        -do     => 1, 
        -code   => sub{
#
    $err->crash( 'Pronto!' );           # 'Pronto!'
#
            },
        -lby    => 'die',
        -want   => qr/Pronto!/s,
    };
}   #

{   #
    my $err     = Error::Base->new;
    push @td, {
        -case   => 'base-and-type',
        -do     => 1, 
        -code   => sub{
#
    $err->crash(
            -base   => 'Bar',
            -type   => 'last call',
        );                              # 'Bar last call'
#
            },
        -lby    => 'die',
        -want   => qr/Bar last call/s,
    };
}   #

{   #
    my $err     = Error::Base->new;
    push @td, {
        -case   => 'base-type-pronto',
        -do     => 1, 
        -code   => sub{
#
    $err->crash(
                'Pronto!',
            -base   => 'Bar',
            -type   => 'last call',
        );                              # 'Bar last call Pronto!'
#
            },
        -lby    => 'die',
        -want   => qr/Bar last call Pronto!/s,
    };
}   #

{   #
    my $err     = Error::Base->new;
    push @td, {
        -case   => 'base-type-mesg',
        -do     => 1, 
        -code   => sub{
#
    $err->crash(
            -base   => 'Bar',
            -type   => 'last call',
            -mesg   => 'Pronto!',
        );                              # 'Bar last call Pronto!'
#
            },
        -lby    => 'die',
        -want   => qr/Bar last call Pronto!/s,
    };
}   #

{   #
    my $err     = Error::Base->new;
    push @td, {
        -case   => 'mesg-aryref',
        -do     => 1, 
        -code   => sub{
#
    my ( $n1, $n2, $n3 ) = ( 'Huey', 'Dewey', 'Louie' );
    $err->crash(
            -mesg   => [ 'Meet', $n1, $n2, $n3, 'tonight!' ],
        );                              # 'Meet Huey Dewey Louie tonight!'
#

            },
        -lby    => 'die',
        -want   => qr/Meet Huey Dewey Louie tonight!/s,
    };
}   #

=pod

    my $err     = Error::Base->new;
    $err->crash;                        # 'Undefined error'
    $err->crash( 'Pronto!' );           # 'Pronto!'
    $err->crash(
            -base   => 'Bar',
            -type   => 'last call',
        );                              # 'Bar last call'
    $err->crash(
                'Pronto!',
            -base   => 'Bar',
            -type   => 'last call',
        );                              # 'Bar last call Pronto!'
    $err->crash(
            -base   => 'Bar',
            -type   => 'last call',
            -mesg   => 'Pronto!',
        );                              # 'Bar last call Pronto!'

    my $err     = Error::Base->new;
    my ( $n1, $n2, $n3 ) = ( 'Huey', 'Dewey', 'Louie' );
    $err->crash(
            -mesg   => [ 'Meet', $n1, $n2, $n3, 'tonight!' ],
        );                              # 'Meet Huey Dewey Louie tonight!'

As a convenience, if the number of arguments passed in is odd, then the first 
arg is shifted off and appnended to the error message. This is done to 
simplify writing one-off, one-line 
L<sanity checks|Error::Base::Cookbook/Sanity Check>.

For a little more structure, you may pass values to 
L<-base|Error::Base/-base>, 
L<-type|Error::Base/-type>, and
L<-mesg|Error::Base/-mesg>. 
All values supplied will be joined; by default, with a single space.

If you pass an array reference to C<-mesg> then you can print out 
any number of strings, one after the other. 

=cut

{   #
    push @td, {
        -case   => 'pep-boys',
        -do     => 1, 
        -code   => sub{
#
    my $err     = Error::Base->new(
                        'Manny',
                    -base       => 'Pep Boys:',
                );
    $err->init('Moe');
    $err->crash('Jack');                # emits 'Pep Boys: Jack' and backtrace
#
            },
        -lby    => 'die',
        -want   => qr/Pep Boys: Jack/,
    };
}   #

=pod

    my $err     = Error::Base->new(
                        'Manny',
                    -base       => 'Pep Boys:',
                );
    $err->init('Moe');
    $err->crash('Jack');                # emits 'Pep Boys: Jack' and backtrace

Remember, new arguments overwrite old values. The L<init()|Error::Base/init()>
method can be called directly on an existing object to overwrite object 
attributes without expanding the message or tracing the stack. If you I<mean>
to expand and trace without throwing, invoke L<cuss()|Error::Base/cuss()>. 

=head2 Interpolation in Scope

=cut

{   #
    push @td, {
        -case   => 'interpolation-in-scope',
        -do     => 1, 
        -code   => sub{
#
    my $filename    = 'debug246.log';
    open( my $in_fh, '<', $filename )
        or Error::Base->crash("Failed to open $filename for reading.");
#
            },
        -lby    => 'die',
        -want   => qr/Failed to open debug246\.log for reading\./,
    };
}   #

=pod

    my $filename    = 'debug246.log';
    open( my $in_fh, '<', $filename )
        or Error::Base->crash("Failed to open $filename for reading.");

Nothing special here; as usual, double quotes interpolate a variable that is 
in scope at the place where the error is thrown. 

=head2 Late Interpolation

=begin fool_pod_coverage

Really think we don't want to document the dummies. 

=head2 bar

=end   fool_pod_coverage

=cut

{   #
    push @td, {
        -case   => 'late-interpolation',
        -do     => 1, 
        -code   => sub{
#
    my $err     = Error::Base->new(
                        'Failed to open $filename for reading.',
                    -base       => 'My::Module error:',
                );
    bar($err);
#
            },
        -lby    => 'die',
        -want   => qr/Failed to open debug246\.log for reading\./,
    };
    sub bar {
        my $err         = shift;
        my $filename    = 'debug246.log';
      # open( my $in_fh, '<', $filename )
      # or 
               $err->crash(
                            '$filename' => \$filename,
                        );      # 'Failed to open debug246.log for reading.'
    };
}   #

=pod

    my $err     = Error::Base->new(
                        'Failed to open $filename for reading.',
                    -base       => 'My::Module error:',
                );
    bar($err);
    sub bar {
        my $err         = shift;
        my $filename    = 'debug246.log';
        open( my $in_fh, '<', $filename )
            or $err->crash(
                            '$filename' => \$filename,
                        );      # 'Failed to open debug246.log for reading.'

If we want to declare lengthy error text well ahead of time, double-quotey 
interpolation will serve us poorly. In the example, C<$filename> isn't in 
scope when we construct C<$err>. Hey, we don't even know what the filename 
will be. 

Enclose the string to be late-interpolated in B<single quotes> (to avoid a 
failed attempt to interpolate immediately) and pass the value when you have 
it ready, in scope. For clarity, I suggest you pass a reference to the 
I<variable> C<$foo> as the value of the I<key> C<'$foo'>. 
The key must be quoted to avoid it being parsed as a variable.

As with normal, in-scope interpolation, you can late-interpolate scalars, 
arrays, array slices, hash slices, or various escape sequences. There is the 
same potential for ambiguity, since the actual interpolation is 
eventually done by perl. 

See L<perlop/Quote and Quote-like Operators>. 

Late interpolation is performed I<after> the entire error message is composed 
and I<before> any prepending, indentation, line-breaking, or stack tracing. 

=cut

{   #
    push @td, {
        -case   => 'late-interpolate-all',
        -do     => 1, 
        -code   => sub{
#
    my $err     = Error::Base->new(
                    '$sca'          => 'one',
                    '@ary_ref'      => [ 'white', 'black' ],
                    '%hash_ref'     => { hash => 'hog', toe => 'jam' },
                );
    $err->crash( '|$sca|@ary_ref|$ary_ref[1]|@hash_ref{ qw/ hash toe / }|' );
                                # emits '|one|white black|black|hog jam|'
#
            },
        -lby    => 'die',
        -want   => qr/|one|white black|black|hog jam|/,
    };
}   #

=pod

    my $err     = Error::Base->new(
                    '$sca'          => 'one',
                    '@ary_ref'      => [ 'white', 'black' ],
                    '%hash_ref'     => { hash => 'hog', toe => 'jam' },
                );
    $err->crash( '|$sca|@ary_ref|$ary_ref[1]|@hash_ref{ qw/ hash toe / }|' );
                                # emits '|one|white black|black|hog jam|'

You may use scalar or array placeholders, signifying them with the usual 
sigils. Although you pass a reference, use the appropriate 
C<$>, C<@> or C<%> sigil to lead the corresponding key. As a convenience, you 
may pass simple scalars directly. (It's syntactically ugly to pass a 
reference to a literal scalar.) Any value that is I<not> a 
reference will be late-interpolated directly; anything else will be 
deferenced (once). 

This is Perlish interpolation, only delayed. You can interpolate escape 
sequences and anything else you would in a double-quoted string. You can pass 
a reference to a package variable; but do so against a simple key such as 
C<'$aryref'>. 

=cut

{   #
    push @td, {
        -case   => 'late-interpolate-self',
        -do     => 1, 
        -code   => sub{
#
    my $err     = Error::Base->new(
                    '$trigger'      => 1,
                    -base       => 'Trouble:',
                    -type       => 'Right here in $self->{_where}!',
                );
    $err->crash( _where => 'River City' );
                                # emits 'Trouble: Right here in River City!'
#
            },
        -lby    => 'die',
        -want   => qr/Trouble: Right here in River City!/,
    };
}   #

=pod

    my $err     = Error::Base->new(
                    '$trigger'      => 1,       # unused key triggers "late"
                    -base       => 'Trouble:',
                    -type       => 'Right here in $self->{_where}!',
                );
    $err->crash( _where => 'River City' );  
                                # emits 'Trouble: Right here in River City!'

As a further convenience, you may interpolate a value from the error object 
itself. In the previous example, C<< '$self->{_where}' >> is late-interpolated 
into C<< -type >> (please note the single quotes). And also, 
C<< _where >> is defined as C<< 'River City' >>. 
B<Note> that Error::Base has no idea what you have called your error object 
(perhaps '$err'); use the placeholder C<< '$self' >> 
in the string to be expanded. 

Don't forget to store your value against the appropriate key! 
This implementation of this feature does not peek into your pad. 
You may not receive an 'uninitialized' warning if a value is missing. 

If you don't like this feature, don't use it and it won't bug you. 
B<Currently> you must pass a sigiled key to trigger late interpolation. 

=head2 Local List Separator

=cut

{   #
    push @td, {
        -case   => 'local-list-separator',
        -do     => 1, 
        -code   => sub{
#
    local $"    = '=';
    Error::Base->crash(
            'Third',
        -base     => 'First',
        -type     => 'Second',
    );                                  # emits 'First=Second=Third'
#
            },
        -lby    => 'die',
        -want   => qr/First=Second=Third/,
    };
}   #

=pod

    local $"    = '=';
    Error::Base->crash(
            'Third',
        -base     => 'First',
        -type     => 'Second',
    );                                  # emits 'First=Second=Third'

Rationally, I think, message parts should be joined by a single space. 
Note that array elements are normally interpolated, separated by spaces. 
Perl uses the value of C<$"> (C<$LIST_SEPARATOR>). 

If, for some reason, you wish to see message parts and interpolated elements 
joined by something else, localize C<$">. 

=head1 EXAMPLE CODE

This module contains executable code matching each snippet you see in POD; 
this code is exercised by the Error::Base test suite. You're welcome to look. 
Please, don't try to C<use> the ::Cookbook!

=head1 DEMO

Included in this distribution is a script, C<error-base-demo.pl>; 
output shown here. A single error object is constructed and used throughout. 
First there is a silent invocation of C<cuss()>; then you see a warning with 
C<crank()>; then a fatal error is thrown with C<crash()>, trapped, printed, 
and finally dumped using L<Devel::Comments|Devel::Comments>. 
Each invocation generates a stack backtrace from the point of throw.  

Note that when printed, the error object stringifies to the intended 
error message and backtrace. The dump shows the true contents of the object. 
Note also that the private key C<_private> is retained in the object; 
while the message text and backtrace is re-created at each invocation. 

    Demo: cranking in eluder
    in Spathi::eluder at line 38    [demo/error-base-demo.pl]
    in Pkunk::fury    at line 31    [demo/error-base-demo.pl]
    _________________ at line 19    [demo/error-base-demo.pl]
    
    Demo: crashing in scout
    in (eval)          at line 50    [demo/error-base-demo.pl]
    in Shofixti::scout at line 50    [demo/error-base-demo.pl]
    in Spathi::eluder  at line 42    [demo/error-base-demo.pl]
    in Pkunk::fury     at line 31    [demo/error-base-demo.pl]
    __________________ at line 19    [demo/error-base-demo.pl]
    
    ### $trap: bless( {
    ###                 '-all' => 'Demo: crashing in scout',
    ###                 '-base' => 'Demo:',
    ###                 '-frames' => [
    ###                                {
    ###                                  '-eval' => undef,
    ###                                  '-file' => 'demo/error-base-demo.pl',
    ###                                  '-line' => '50',
    ###                                  '-package' => 'Shofixti',
    ###                                  '-sub' => '(eval)         '
    ###                                },
    ###                                {
    ###                                  '-eval' => undef,
    ###                                  '-file' => 'demo/error-base-demo.pl',
    ###                                  '-line' => '50',
    ###                                  '-package' => 'Shofixti',
    ###                                  '-sub' => 'Shofixti::scout'
    ###                                },
    ###                                {
    ###                                  '-eval' => undef,
    ###                                  '-file' => 'demo/error-base-demo.pl',
    ###                                  '-line' => '42',
    ###                                  '-package' => 'Spathi',
    ###                                  '-sub' => 'Spathi::eluder '
    ###                                },
    ###                                {
    ###                                  '-eval' => undef,
    ###                                  '-file' => 'demo/error-base-demo.pl',
    ###                                  '-line' => '31',
    ###                                  '-package' => 'Pkunk',
    ###                                  '-sub' => 'Pkunk::fury    '
    ###                                },
    ###                                {
    ###                                  '-bottom' => 1,
    ###                                  '-eval' => undef,
    ###                                  '-file' => 'demo/error-base-demo.pl',
    ###                                  '-line' => '19',
    ###                                  '-package' => 'main',
    ###                                  '-sub' => '_______________'
    ###                                }
    ###                              ],
    ###                 '-lines' => [
    ###                               'Demo: crashing in scout',
    ###                               'in (eval)          at line 50    [demo/error-base-demo.pl]',
    ###                               'in Shofixti::scout at line 50    [demo/error-base-demo.pl]',
    ###                               'in Spathi::eluder  at line 42    [demo/error-base-demo.pl]',
    ###                               'in Pkunk::fury     at line 31    [demo/error-base-demo.pl]',
    ###                               '__________________ at line 19    [demo/error-base-demo.pl]'
    ###                             ],
    ###                 '-mesg' => '',
    ###                 '-top' => 2,
    ###                 '-type' => 'crashing in scout',
    ###                 _private => 'foo'
    ###               }, 'Error::Base' )

=head1 PHILOSOPHY

Many error-related modules are available on CPAN. Some do bizarre things. 

L<Error> is self-deprecated in its own POD as "black magic"; 
which recommends L<Exception::Class> instead.

L<Exception> installs a C<< $SIG{__DIE__} >> handler that converts text 
passed to C<die> into an exception object. It permits environment variables 
and setting global state; and implements a C<try> syntax. This module may be 
closest in spirit to Error::Base. 
For some reason, I can't persuade C<cpan> to find it. 

L<Carp> is well-known and indeed, does a full backtrace with C<confess()>. 
The better-known C<carp()> may be a bit too clever and in any case, the dump 
is not formatted to my taste. The module is full of global variable settings. 
It's not object-oriented and an error object can't easily be pre-created.  

The pack leader seems to be L<Exception::Class>. Error::Base differs most 
strongly in that it has a shorter learning curve (since it does much less); 
confines itself to error message emission (catching errors is another job); 
and does a full stack backtrace dump by default. Less code may also be 
required for simple tasks. 

To really catch errors, I like L<Test::Trap> ('block eval on steroids'). 
It has a few shortcomings but is extremely powerful. I don't see why its use 
should be confined to testing. 

The line between emitting a message and catching it is blurred in many 
related modules. I did not want a jack-in-the-box object that phoned home if 
it was thrown under a full moon. The only clever part of an Error::Base 
object is that it stringifies. 

It may be true to say that many error modules seem to I<expect> to be caught. 
I usually expect my errors to cause all execution to come to a fatal, 
non-recoverable crash. Oh, yes; I agree it's sometimes needful to catch such 
errors, especially during testing. But if you're regularly throwing and 
catching, the term 'exception' may be appropriate but perhaps not 'error'. 

=head1 AUTHOR

Xiong Changnian  C<< <xiong@cpan.org> >>

=head1 LICENCE

Copyright (C) 2011, 2013 Xiong Changnian C<< <xiong@cpan.org> >>

This library and its contents are released under Artistic License 2.0:

L<http://www.opensource.org/licenses/artistic-license-2.0.php>

=head1 SEE ALSO

L<Error::Base>(3)

=cut

## END MODULE
1;
__END__
