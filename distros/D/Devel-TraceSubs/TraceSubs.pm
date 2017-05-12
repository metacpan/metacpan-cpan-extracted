package Devel::TraceSubs;
use 5.006001;
use strict;
use warnings;
use Hook::LexWrap;
use Carp qw( carp croak );
use Data::Dumper;
our $VERSION = 0.02;

no strict 'refs'; # professional driver on a closed course


sub new { # create a new instance
  my( $class, %arg ) = @_;

  ref $arg{wrap} eq 'ARRAY' and $arg{verbose}
    and croak 'ERROR: cannot use verbose mode with wrappers';

  my @untraceables = qw/ 
  	Carp:: 
  	Data::Dumper:: 
  /;

  my $self = bless { 
    pre => defined $arg{pre} ? $arg{pre} : '>',
    post => defined $arg{post} ? $arg{post} : '<',
    level => defined $arg{level} ? $arg{level} : '~',
    verbose => $arg{verbose} ? '' : "\n",
    params => $arg{params} ? 1 : 0,
    wrap => ref $arg{wrap} eq 'ARRAY' ? $arg{wrap} : ['',''],
    logger => ( defined $arg{logger} && 
       ref $arg{logger} eq 'CODE' && 
        defined &{ $arg{logger} } )
      ? $arg{logger} : \&Carp::carp,
    traced => {},
	_not_a_trace => {},
	_presub => undef,
	_postsub => undef,
  }, $class;
  $self->untraceables( @untraceables );
  return $self;
}

sub trace($;*) { # trace all named subs in passed namespaces
  my( $self ) = ( shift );
  local $, = ' ';

  PACKAGE: for my $pkg ( @_ ) {

    ref $pkg
      and $self->_warning( "References not allowed ($pkg)" )
      and next PACKAGE;

    $pkg =~ /^\*/
      and $self->_warning( "Globs not allowed ($pkg)" )
      and next PACKAGE;

    !defined %{ $pkg }
      and $self->_warning( "Non-existant package ($pkg)" )
      and next PACKAGE;

    $pkg eq __PACKAGE__ . '::'
      and $self->_warning( "Can't trace myself. This way lies madness." )
      and next PACKAGE;

    exists $self->{_not_a_trace}{ $pkg }
	  and $self->_warning( "Package untraceable ($pkg)" )
	  and next PACKAGE;

    my( $sym, $glob );

    SYMBOL: while ( ($sym, $glob) = each %{ $pkg } ) {

      $pkg eq $sym and next SYMBOL;
      $self->{traced}->{ $pkg . $sym } and next SYMBOL;

      if( defined *{ $glob }{CODE} ) {
        my $desc = $pkg . $sym . $self->{verbose};

        $self->{traced}->{$pkg . $sym}++;

        $self->{_presub} = $self->_gen_wrapper( $self->{pre}, $pkg, $sym, 1 );
        $self->{_postsub} = $self->_gen_wrapper( $self->{post}, $pkg, $sym, 0 );

        Hook::LexWrap::wrap $pkg . $sym,
          pre => $self->{_presub},
          post => $self->{_postsub};
      }
    }
  }
  my @val = keys %{ $self->{traced} };
  return wantarray ? @val : "@val";
}

sub untraceables { # get or set untraceable namespaces
  my( $self ) = ( shift );
  @_ and @{ $self->{_not_a_trace} }{@_} = undef;
  @_ or return wantarray
    ? keys %{ $self->{_not_a_trace} }
    : scalar keys %{ $self->{_not_a_trace} }
}

sub _stack_depth { # compute stack depth
  my @stack;
  while( my $sym = caller(1 + scalar @stack) )
  { push @stack, $sym }
  return wantarray ? @stack : scalar @stack;
}

sub _gen_wrapper { # return a wrapper subroutine
  my( $self ) = ( shift );
  my( $direction, $pkg, $sym, $start ) = @_;
  return sub{
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Terse = 1;
    $self->{logger}->( 
      ( $self->{wrap}[0] ),
      ($self->{time} 
        ? sprintf( "%2d:%2d:%2d ", (localtime)[2,1,0] )
        : ()
      ),
      $self->{level} x $self->_stack_depth(),
      $direction, ' ',
      $pkg, $sym, 
      ( $self->{params} && @_ > 1 && $start
        ? "( '" . join( "', '", Data::Dumper::Dumper( @_[0..$#_-1] ) ) . "' )"
        : () 
      ),
	  ( $self->{params} && @_ > 1 && ! $start
        ? ' => '
          . (ref $_[-1] ne 'Hook::LexWrap::Cleanup'
            ? (wantarray 
              ? "( '" . join( "', '", Data::Dumper::Dumper(@$_[-1]) ) . "' )"
              : Data::Dumper::Dumper( $_[-1] )
            )
            : '<void>'
          )
	    : ()
	  ),
      ( $self->{wrap}[1] ),
      $self->{verbose},
    )
  }
}

sub _warning { # return a warning message
  my( $self ) = ( shift);
  carp 'Warning: ', __PACKAGE__, ': ', @_, $self->{verbose}
}


$_ ^=~ { module => 'Devel::TraceSubs', author => 'particle' };

__END__


=head2 NAME

Devel::TraceSubs - Subroutine wrappers for debugging

=head2 VERSION

This document describes version 0.02 of Devel::TraceSubs,
released 22 June 2002.

=head2 SYNOPSIS

  package foo;
  sub bar { print "foobar\n" }

  package etc;
  sub etc { etc::etc() }

  package main;
  use Devel::TraceSubs;

  sub foo { print "foo\n"; foo::bar() }

  my $pkg = 'main::';

  my $dbg = Devel::TraceSubs->new(
    verbose => 0, 
    pre => '>',
    post => '<',
    level => '~',
    params => 1,
    wrap => ['<!--', '-->'],
  );

  $dbg->untraceables( 'etc::etc::' );

  $dbg->trace(
    'foo::',            # valid
    $pkg,               # valid
    'main',             # invalid -- no trailing colons
    'joe::',            # invalid -- non-existant
    $dbg,               # invalid -- references not allowed
    'Debug::SubWrap::', # invalid -- self-reference not allowed
    *main::,            # invalid -- globs not allowed
    'etc::',            # invalid -- untraceable
  );

=head2 DESCRIPTION

Devel::TraceSubs allows you to track the entry and exit of subroutines in a list of namespaces you specify. It will return the proper stack depth, and display parameters passed. Error checking prevents silent failures (err... the ones i know of.) It takes advantage of Hook::LexWrap to do the dirty work of wrapping the subs and return the proper caller context.

NOTE: Using verbose mode with wrap mode will generate a compile-time error.
Don't do that!

ALSO NOTE: using level => '-' and pre=> '>' can cause problems with
wrap => ['<!--', '-->']. Don't do that, either!

=head2 METHODS

=over 4

=item new()

Create a new instance of a Devel::TraceSubs object. Below is a description of the parameters, passed in hash format: parameter => value

=over 4

=item pre =>

(SCALAR) Text specifying subroutine entry. Default value is '>'.

=item post =>

(SCALAR) Text specifying subroutine exit. Default value is '<'.

=item level =>

(SCALAR) Text repeated to show the subroutine stack level. Default value is '~'.

=item verbose =>

( 1 | 0 ) Include verbose carp information. Verbose mode and wrap mode must not be enabled at the same time. Default is 0.

=item params =>

( 1 | 0 ) Display subroutine parameters. If enabled, your subroutine parameters and return values will be displayed. Default is 0.

=item wrap =>

(ref 'ARRAY' size 2) Text to wrap all logging info. For instance, if ['<!-- ',' -->'] is specified, logging info will be wrapped in HTML comment tags. Default is ['',''].

=item logger =>

(ref 'CODE') Specify your own logging handler. Default logging is handled by &Carp::carp();

=item time =>

( 1 | 0 ) Display the time during subroutine entry and exit. Default value is 0.

=back

=item trace()

Trace all named subs in passed namespaces. Call this method with a list of namespaces in which you want to trace subroutine calls. Returns a list of currently traced namespaces in list context, and space seperated string of currently traced namespaces in scalar context.

=item untraceables()

Get or set the list of untraceable namespaces. Call this method with a list of namespaces you're having a problem tracing, and Devel::TraceSubs will happily ignore them. Returns list of untraceable namespaces in list context, and number of untraceable namespaces in scalar context. Default list is 'Carp::', 'Data::Dumper::'.

=item _stack_depth()

Internal use only. Calculates current stack depth. Returns list of stack items in list context, and stack depth in scalar context.

=item _gen_wrapper()

Internal use only. Generates the subroutine wrappers passed to Hook::LexWrap. Returns a code reference.

=item _warning()

Internal use only. Returns a warning message using Carp::carp.

=back

=head2 EXPORT

None. Give a hoot, don't pollute!

=head2 BUGS

Likely so. Not recommended for production use--but why on earth would you be
using a Devel:: module in production?

=head2 AUTHOR

particle E<lt>particle@artfromthemachine.comE<gt>
Jenda E<lt>Jenda@Krynicky.czE<gt>

=head2 COPYRIGHT

Copyright 2002 - Ars Ex Machina, Corp.

This package is free software and is provided "as is" without express or
implied warranty. It may be used, redistributed and/or modified under the terms
of the Perl Artistic License (see http://www.perl.com/perl/misc/Artistic.html)

Address bug reports and comments to: particle@artfromthemachine.com.  
When sending bug reports, please provide the version of Devel::TraceSubs, the 
version of Perl, and the name and version of the operating system you are 
using.

=head2 CREDITS

Thanks to Jenda at perlmonks.org 
for the idea to to display passed parameters, and the patch to implement it. 
Thanks to crazyinsomniac at perlmonks.org 
for the idea to support html (or other) output formats.

=head2 SEE ALSO

L<Hook::LexWrap>.

=cut

