#-----------------------------------------------------------------------------
# File: Args.pm
#-----------------------------------------------------------------------------

package HTML::Bricks::Args;
use strict;

our $VERSION = '0.02';

#---------------------------------------------------------------------
# process_args
#---------------------------------------------------------------------
sub process_args {

  my $r = Apache->request;

  my %ARGS = $r->method eq 'POST' ? $r->content : $r->args;
  my $rARGS = \%ARGS;

  #
  # If the user pressed a submit button on a form, only the form args
  # are available, but the command line args on the URI 
  # (ex: http://www.somewhere.com/index.html?arg1=val1&arg2=val2) are
  # not available.  Process them here to make them available.
  #
  # Is this a bug or a feature?  
  #

  my %ua = $r->args;
  foreach (keys %ua) {
    if (!defined $$rARGS{$_}) {
      $$rARGS{$_} = $ua{$_};
    }
  }

  #
  # search for global args (denoted by g:arg=value)
  #
 
  %HTML::Bricks::global_args = my %blank_hash;

  foreach (keys %$rARGS) {
    if ($_ =~ /g:(.*)/) {
      $HTML::Bricks::global_args{$1} = $$rARGS{$_};
    }
  }

  #
  # Now that all the args are available, parse 'em
  #

  my %a;

  foreach (keys %$rARGS) {

    my $ra = \%a;

    next if $_ eq '';  

    my @fields = split(':', $_);
    
    if ($#fields != 1) {
      print STDERR "Illegal arg: \"$_\".  Args must be of the form brick_id:arg=value.\n";
      next;
    }

    my $rsub_ARGS;
    my $brick_id = shift @fields;
    my @b = split('\.',$brick_id);
 
    while (defined ($brick_id = shift @b)) {
      next if $brick_id eq 'g';

      if (!defined $$ra{$brick_id}) {
        $$ra{$brick_id} = { rARGS => {}, rsub_ARGS => {} };
      }
      $rsub_ARGS = ${$$ra{$brick_id}}{rARGS};
      $ra = ${$$ra{$brick_id}}{rsub_ARGS};
    }
    $$rsub_ARGS{shift @fields} = $$rARGS{$_};
  }

  return (undef, \%a);
}

return 1;
