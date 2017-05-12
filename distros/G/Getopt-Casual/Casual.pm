package Getopt::Casual;

=pod

=head1 NAME

Getopt::Casual - A casual replacement for other Getopt modules and C<-s>.

=head1 SYNOPSIS

  use Getopt::Casual;

  print $_, ' = ', $ARGV{ $_ }, "\n" for keys %ARGV 
    if $ARGV{ '--demo' };

  (see F<example.pl>)

  #-- Using import() to create casual defaults.

  perl C<->e 'use Getopt::Casual qw/ --debug=2 C<-l> C<-t> /; 
    print "$_ = $ARGV{ $_ }\n" for keys %ARGV' C<-t> foo

  --debug = 2
  -t = foo
  -l = 1

=head1 DESCRIPTION

The Getopt::Casual module simplifies the manipulation of command line
arguments in what should be a familiar way to most UNIX command line 
utility users.  The following basic rules explain the assumptions that
the C<&casual()> makes for either C<&import()> or C<@ARGV> command
line processing:

 1)  Arguments can be single characters or and combination of
     characters, although depending on your shell, some characters will
     be interpreted by the shell.

 2)  Arguments that begin with a '-' followed by another item in
     @ARGV, which can include spaces if the string is enclosed by 
     quotes or double quotes, will have the value of that string.  
     See Rule 3.

 3)  Arguments that begin with a '-' followed by another argument in 
     @ARGV that begins with a '-', including quoted strings that 
     contain spaces, will have a value of 1.

 4)  Arguments that do not begin with a '-' will have a value of one.
     When preceded by an odd number of arguments that begin with a dash,
     this string is a value of the previous command line argument.

 5)  Arguments that begin with a '--' have a value of one.  (See Rule 7)

 6)  The string '--' will terminate command line processing.

 7)  If the string contains an '=', the part of the string preceding 
     the first '=' will be a key of %ARGV and the value will be the
     part following the first '=' until the end of that element of @ARGV.

 8)  All arguments of the script can be found as either a key or a
     value of %ARGV.

 9)  @ARGV will contain only the arguments that meet the following criteria.

     a)  All arguments after a '--' will be contained in @ARGV unless
	 one of the next two criteria are met first.

     b)  All arguments after the last occurance of an argument that
         begins with a '-' and that arguments value.

				 -OR-

	 All arguments after the last occurance of an argument that
	 contains an '='.

The same set of rules apply to the arguments you pass the import() 
subroutine.

=head1 EXAMPLES

See the included program called F<example.pl>.

=head1 BUGS

If you find one, please tell me or supply a patch.

=cut

use strict qw/ vars subs /;
use vars qw/ $VERSION @ISA /;

#-- $Id: Casual.pm,v 1.3 2001/04/12 20:45:37 daniel Exp $
$VERSION = "0.13.1";

sub import {

  my $self = shift;

  &casual( @_ );
  &casual( @ARGV );
  &clean_argv;

};

sub casual {

  #-- $i:  Points to the position in the array we are currently at.
  #--	   The benefit of this type of for loop is that we can point
  #--	   $i out of sequence.
  #-- $_:  Used for regexps like /^-/.
  #-- $next: Points to the next element in the array, not the
  #--	     position.  Used for forward look ups.
  for (my $i = 0; $_ = $_[ $i ], my $next = $_[ $i + 1 ], $i < @_; $i++) {

    #-- $skip: If $_ begin with a '-' and/or $next is digits, then
    #-- we will assume that $next is the value of $ARGV{ $_ }.
    my $skip;

    #-- $dash:  There just has to be a better way to do this.
    #--		If $_ begins with a -, return '-', else return ''.
    my ($dash) =  /^(-|)/;

    #-- If there is an equals sign in the argument, it is assumed that
    #-- anything before the first equals sign is the key and anything
    #-- after is the value.
    next if s/^([^=]+)=(.*)/$ARGV{ $1 } = $2/e;

    #-- Stop processing arguments.
    last if /^--$/;

    $ARGV{ $_[ do { s#([^-])#$ARGV{ $dash . $1 } = 1 
      unless exists $ARGV{ $dash . $1 }#eg unless /^--/; $i } ] } = 
        defined $next ? /^--/ ? 1 : $next =~ /^-/ || 
          (!/^-/ && $next =~ /\D/) ? 1 : ($skip = $next) : 1;

    #-- Go to next key if the next value is actually a value.
    $i++ if defined $skip;

  }

}

sub clean_argv {

  #-- RJK: No script options should remain in @ARGV.
  while (@ARGV) {

    #-- Stop shifting off of @ARGV when '--' is found.
    if ($ARGV[ 0 ] eq '--') {
      shift @ARGV;
      last;

    #-- If there is an /=/ or a /^--/, then only this argument should
    #-- be removed from @ARGV.
    } elsif ($ARGV[ 0 ] =~ /=/ || $ARGV[ 0 ] =~ /^--/) {
      shift @ARGV; 

    #-- If the argument begins with /^-/, remove the argument and
    #-- any values if they are found.
    } elsif ($ARGV[ 0 ] =~ /^-/) {
      defined $ARGV[ 1 ] ? $ARGV[ 1 ] =~ /^-/ ? shift @ARGV :
        splice @ARGV, 0, 2 : shift @ARGV;

    #-- If none of these conditions are met, stop, the rest of the 
    #-- items in @ARGV are arguments.
    } else { 
      last;
    }

  }

}


=pod

=head1 SEE ALSO

L<Getopt::Std>, L<Getopt::Long>

=head1 NOTES

There has been some doubt as to whether or not this was useful enough
to have to remember to tote it with you to every system on which you
had command line perl scripts.  The obvious advantage of the core
modules is that they are wherever perl is installed.  If portablity 
is really a key issue, use the core modules.

=head2 AUTHOR

Daniel M. Lipton  <photo@tiac.net>

=head2 Contributors

Patrick M. Jordan <patrick@antistatic.com>
Ronald J. Kimball <rjk@linguist.dartmouth.edu>
Andrew N. Hicox <Andrew N. Hicox>

=cut

1;
