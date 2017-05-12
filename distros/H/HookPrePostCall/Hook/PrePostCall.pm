# Copyright (C) 1997 Philippe Verdret
require 5.000;

package Hook::PrePostCall;
use strict;
$Hook::PrePostCall::VERSION = '1.2';
sub new {
  my $receiver = shift;
  my $class = '';

  my $callfrom = '';
  my $self = '';
  my $primary = '';

				# The primary routine
  my $name = shift;
  if ($name =~ /^(.*)::/) {
    $callfrom = ($1 or 'main');
  } else {
    $callfrom = (caller(0))[0];
    $name = "${callfrom}::" . $name;
  }

  if ($class = ref $receiver) {	# Object method
    $self = $receiver;
    $primary = ${$self->{primary}}; # initial definition
  } else {			# Class method
    $self = bless {}, $receiver;
    $primary = \&{"$name"};	# current definition
    $self->{primary} = \$primary;
  }


				# Pre and Post hooks
  my $pre = shift;
  my $post = shift;
  my $derived = '';

  $self->{callfrom} = \$callfrom;
  $self->{name} = \$name;
  $self->{pre} = \$pre;
  $self->{post} = \$post;
  $self->{derived} = \$derived;

  if ($pre and $post) {
  } elsif ($pre) {
    $post = sub { @_ };
  } elsif ($post) {
    $pre = sub{ @_ };
  } else {
    $pre = $post = sub{ @_ };
  }

  my @result = ();
  my $sub = $derived = 
  sub { 
    @result = &$pre;
    if (wantarray) {		# preserve the calling context
      &$post(&$primary(@result));
    } else {
      &$post(scalar &$primary(@result));
    }
  };
  
  $self->install($name, $sub);
  $self;
}
sub restore {
  my $self = shift;
  my $name = ${$self->{name}};
  my $sub = ${$self->{primary}};
  $self->install($name, $sub);
}
sub install {
  my $self = shift;
  my $name = shift;
  my $sub = shift;
  no strict qw(refs);		# some hackery and surgery
  my $CW = $^W; $^W = 0;  
  *{$name} = $sub;
  $^W = $CW;
  use strict qw(refs);		# end of operation
  $self;
}
sub pre {
  my $self = shift;
  if (@_) {
    ${$self->{pre}} = shift;
  } else {
    ${$self->{pre}};
  }
}
sub post {
  my $self = shift;
  if (@_) {
    ${$self->{post}} = shift;
  } else {
    ${$self->{post}};
  }
}
sub primary {
  my $self = shift;
  if (@_) {
    ${$self->{primary}} = shift;
  } else {
    ${$self->{primary}};
  }
}
sub derived {
  my $self = shift;
  if (@_) {
    ${$self->{derived}} = shift;
  } else {
    ${$self->{derived}};
  }
}

1;
__END__
=head1 NAME

Hook::PrePostCall - Add actions before and after a routine (alpha 1.2)

=head1 SYNOPSIS

  require 5.000;
  use Hook::PrePostCall;

  sub try {
    print STDERR "in try: @_\n";
    @_;
  }

  PrePostCall->new(
	     'try',
	     sub {
	       print STDERR "pre: @_\n";
	       # process the @_ content...if you want
	       @_;		# defines the 'try' arguments
	     },
	     sub {
	       print STDERR "post: @_\n";
	       # process the @_ content...if you want
	       @_;		# defines what the 'try' returns
	     }
	    );
  print try(10), "\n";


=head1 DESCRIPTION

C<new()> creates a new object of the Hook::PrePostCall
class. Arguments of the new method are:

1. the name of the primary routine you want to "overload",

2. an anonymous routine to call before the primary routine,

3. an anonumous routine to call after the primary routine.

If the name of the primary subroutine has not an explicit package
prefix, it is assumed to be the name of a subroutine in the current
package of the caller of the new() method.

The pre routine acts as a filter of the primary routine arguments.
The post routine acts as a filter of what the primary returns.

new() can be used as a class or an object method. When used as an
object method the derived definition is built from the initial
definition of the primary routine.

C<derived()> Returns the overloaded routine.

C<pre()> Returns or set the pre action part.

C<post()> Returns or set the post action part.

C<primary()> Returns the primary routine.

C<restore()> Retore initial definition of the primary routine.


=head1 AUTHOR

Philippe Verdret, pverdret@sonovision-itep.fr

=cut

