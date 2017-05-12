package Junction::Quotelike;

=head1 NAME

Junction::Quotelike - quotelike junction operators

=cut

use strict;
use warnings;

use Carp qw/croak/;

use PerlX::QuoteOperator qw//;
use Perl6::Junction      qw/all any none one/;


=head1 VERSION

This document describes version 0.01 of Junction::Quotelike,
released Sun Feb 14 16:20:27 CET 2010 @680 /Internet Time/

=cut 

our $VERSION = 0.01;

=head1 SYNOPSIS

  use Junction::Quotelike qw/qany/;
  
  my $x = 'foo';
  
  print "is foo!" if $x eq qany/foo bar baz/; #is foo 


=head1 DESCRIPTION

Junction::Quotelike glues Perl6::Junction and PerlX::QuoteOperator together to 
provide quotelike junction operators. 

=head2 Operators

Junction::Quotelike defines the following Operators

=cut

=head3 qany//

Quotelike version of any(). Returns a junction that tests against one more of
its Elements. See L<<Perl6::Junction>> for details 

=head3 qall//

Quotelike version of all(). Returns a junction that tests against all of its
Elements. See L<<Perl6::Junction>> for details

=head3 qone//

Quotelike version of one(). Returns a junction that tests against one (and only
one) of its Elements. See L<<Perl6::Junction>> for details

=head3 qnone//

Quotelike version of none(). Returns a junction that tests against none of its
Elements. See L<<Perl6::Junction>> for details

=cut


sub import 
{
    my $class = shift;
    my $names;
    my $caller;
    my $valid;
    my $ctx;
    my %code;
    
    $caller = caller;
    
    $valid  = any(qw/qany qall qone qnone/);
    $ctx    = PerlX::QuoteOperator->new;
    
    %code =
    (
            qany  => sub (@){  any(@_)},
            qall  => sub (@){  all(@_)},
            qone  => sub (@){  one(@_)},
            qnone => sub (@){ none(@_)},
    );
    
    if (@_ == 1 && ref $_[0])
    {
            $names = shift;
    }
    elsif(@_ > 0)
    {
            $names = {};
            foreach my $name (@_)
            {
                    $names->{$name} = $name;
            }
    }
    else
    {
            croak "no import spec";
    }
    
    foreach my $name (keys %{$names})
    {
            croak "bad import spec: $name" unless $name eq $valid;
    }
    
    foreach my $name (keys %{$names})
    {
            $ctx->import($names->{$name}, 
                        {-emulate => 'qw', -with => $code{$name}, -parser => 1}, 
                        $caller );
    }
}

=head2 Export

Junction::Quotelike exports qany qall qnone qone upon request. You can import
one or more of them in the usual way. 

  use Junction::Quotelike qw'qall';
  
or

  use Junction::Quotelike qw'qany qall';

Altnernativly you can rename them while importing:

  use Junction::Quotelike { qany => 'any', qall => 'all' };
  
This would export the operators qany and qall to your namespace renamed to any 
and all, so you can write:

  my $anyjunction = any /foo bar baz/;
  my $alljunction = all /foo bar baz/;
  
You must however import at least one operator into your namespace.  


=head1 DIAGNOSTICS

=over

=item "bad import spec: %s"

You requested an invalid operator to be exported. Currently valid operators are:
qany|qall|qone|qnone.


=item "no import spec"

You didn't request any operator to be exported. Without exports this module is
useless. 
 

=back

=head1 BUGS

There are undoubtedly serious bugs lurking somewhere.
If you believe you have found a new, undocumented or ill documented bug,
then please drop me a mail to blade@dropfknuck.net .

=over

=item Delimiters

The list of supported delimiters is a bit more restricted than with standard 
quotelike operators. Currently tested and supported are:

  '/', '\', '!'
  
On the other hand known I<<not>> to work are

  ''', '#'. '()', '[]', '{}'
  
In general, all bracketing delimiters are known not to work, and other non
bracketing delimiters may work or not, but aren't tested (yet). These are
restrictions from PerlX::QuoteOperator. With all these limitations this module
may better be called Junction::Quotelikelike.  

=back

=head1 CAVEATS

Junction::Quotelike relies on the dark magic performed by PerlX::QuoteOperator
which enables custom quotelike operators. While this seems to work very stable,
you should be aware that there may be some unexpected side effects. See
PerlX::QuoteOperator for details. 

It is not possible to use the operators directly witout importing them. 
Qualifying them like Junction::Quotelike::qany/foo bar/ B<<won't work>>. 
I don't think that's bug since using qualified names would make the use of this
module rather pointless. 


=head1 SEE ALSO

Junction::Quotelike doesn't really do much on itself but rather relies on the
services of these Modules to perform its job. 

=over

=item L<<Perl6::Junction>>

Perl6::Junction defines the semantics for junctions used by this module. If
you're intrested in junctions without quotelike behavior this your friend. 

=item L<<PerlX::QuoteOperator>>

PerlX::QuoteOperator enables the definition of custom quotelike operators in a
straightforward manner.

=back

=head1 WHY?

Why not?

As of this writing i am working on some slightly complex piece of code that
makes heavy use of junctions (as provided by Perl6::Junction). While this makes
my code way less complex i'm still forced to write a lot lines like

  ...
  $valid = any(qw/this that something else/);
  ...  

Sure that's not that bad, but it doesn't look nice to me. Writing it like:

  ...
  $valid = qany /this that something else/;
  ...
  
Looks a lot better to me.   

=head1 AUTHOR

  blackhat.blade (formerly Lionel Mehl) <blade@dropfknuck.net>
  dropfknuck.net
  

=head1 COPYRIGHT

         Copyright (c) 2010 blackhat.blade, dropfknuck.net
       This module is free software. It may be used, redistributed
           and/or modified under the terms of the Artistic license.

=cut

1;

__END__
0.01 Sun Feb 14 16:20:22 CET 2010 @680 /Internet Time/ 
     initial release.
