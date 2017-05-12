package Devel::UseAnyFunc;

use strict;
use vars qw($VERSION $DIGANOSTICS);
use Carp;

BEGIN {
  $VERSION = 1.00;
  $DIGANOSTICS ||= 0;
}

sub import { 
  my ( $self, $name, @sources ) = @_;

  if ( $name eq '-isasubclass' ) {
    my $subclass = ( caller )[0];
    no strict 'refs';
    unshift @{"$subclass\::ISA"}, $self;
    return;
  }
  
  $name or croak( "$self called without a function name" );
  scalar(@sources) or croak("$self $name called without any function sources");
  scalar(@sources) % 2 and croak("$self name called with odd number of source ".
				 "arguments, should be key-value pairs" );
  
  # Find the first class in the caller() stack that's not a subclass of us 
  my $target;
  my $i = 0;
  do { $target = ( caller($i ++) )[0] } 
	while UNIVERSAL::isa($target, __PACKAGE__ );
  
  my @candidates = my %candidates = @sources;
  while ( my ($class, $function) = splice @candidates, 0, 2 ) {
    (my $pm = "$class.pm") =~ s{::}{/}g;
    warn "Attempting to load $pm...\n" if $DIGANOSTICS;
    eval { require $pm };
    if ( $@ ) { warn "Failed to load $pm: $@" if $DIGANOSTICS; next }
    warn "Installing $class\::$function as $target\::$name\n" if $DIGANOSTICS;
    no strict 'refs';
    return *{"$self\::$name"} = *{"$target\::$name"} = 
			ref($function) ? $function : \&{"$class\::$function"};
  }
 croak( "Can't locate any module to provide $name: " . 
			    join(', ', keys %candidates) . ")" )
}

1;

__END__

=head1 NAME

Devel::UseAnyFunc - Import any of several equivalent functions

=head1 SYNOPSIS

  use Devel::UseAnyFunc 'url_esc', HTML::Mason::Escapes => 'url_escape', 
                                   URI::Escape          => 'uri_escape',
                                   CGI::Util            => 'escape',
                                   PApp::HTML           => 'escape_uri';
  
  # I don't care which of the above I get, as long as it works locally.
  print url_esc( $my_address );

=head1 DESCRIPTION

Devel::UseAnyFunc allows you to request any one of several equivalent functions from separate modules without forcing a dependancy on a specific one. 

=head2 Motivation

As an example, many different modules provide essentially-equivalent URL escaping functions. A developer writing a CGI script might use Devel::UseAnyFunc to allow their script to run on a variety of different hosts, as long as it has at least one of the relevant modules is installed.

=head2 Operation

To take advantage of this module, C<use> it, passing the name of the function you would like, followed by a list of pairs of a package name and a function name.

Each of the listed packages is tested in turn, in the order provided. If that module can be loaded with C<require>, then the associated function is selected; if not, then the next one is tested. If none of the modules is found, it C<croak>s and lists the modules it tried.

Whichever function is selected, it is installed in the callers namespace under the name provided by the first argument to the use statement. (Internally, the same type of symbol-table manipulation is used as in Exporter.)

=head2 Diagnostics

If you set $DIGANOSTICS to a true value before using the module, it will warn a series of diagnostic messages that explain which modules it's testing and which one it settles on.

  BEGIN { $Devel::UseAnyFunc::DIGANOSTICS = 1 }
  use Devel::UseAnyFunc ...

=head2 Subcassing

You may easily subclass this packge in order to provde a specialized "Any" module. 

  package My::AnyFoo;
  use strict;
  use Devel::UseAnyFunc '-isasubclass';
  
  sub import { 
    my ( $self, $name, @sources ) = @_;
    ... adjust the contents of $name and @sources as needed...
    $self->SUPER::import( $name, @sources );
  }

=head1 CREDITS AND COPYRIGHT

Developed by Matthew Simon Cavalletto at Evolution Softworks. 
More free Perl software is available at C<www.evoscript.org>.

You may contact the author directly at C<evo@cpan.org> or C<simonm@cavalletto.org>. 

To report bugs via the CPAN web tracking system, go to C<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devel-UseAnyFunc> or send mail to C<Dist=Devel-UseAnyFuncE#rt.cpan.org>, replacing C<#> with C<@>.

Copyright 2003 Matthew Simon Cavalletto. 

You may use, modify, and distribute this software under the same terms as Perl.

=cut
