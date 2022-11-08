use 5.008003;
use strict;
use warnings;

package Macro::Simple;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use Carp;

use constant DO_MACRO => (
	$] ge 5.014000 and
	require Parse::Keyword and
	require PPI and
	require Sub::Boolean
);

use constant DO_CLEAN => eval { require namespace::clean };

sub import {
	my ( $class, $macros ) = ( shift, @_ );
	my $caller = caller;
	$class->setup_for( $caller, $macros );
}

sub setup_for {
	my ( $class, $caller, $macros ) = ( shift, @_ );
	
	my $installer = DO_MACRO ? '_setup_using_parse_keyword' : '_setup_fallback';
	
	for my $key ( sort keys %$macros ) {
		my ( $subname, $prototype ) = ( $key =~ m{\A(\w+)(.+)\z} );
		my $generator = $class->handle_generator( $macros->{$key} );
		
		$class->$installer( {
			caller    => $caller,
			subname   => $subname,
			prototype => $prototype,
			generator => $generator,
		} );
	}
}

sub handle_generator {
	my ( $class, $generator ) = ( shift, @_ );
	
	if ( 'HASH' eq ref $generator and $generator->{is} ) {
		my $code = $generator->{is}->inline_check( '$x' );
		$generator = sub { sprintf 'my $x = %s; %s', $_[0], $code };
	}
	elsif ( 'HASH' eq ref $generator and $generator->{assert} ) {
		my $code = $generator->{assert}->inline_assert( '$x' );
		$generator = sub { sprintf 'my $x = %s; %s', $_[0], $code };
	}
	elsif ( not ref $generator ) {
		my $format = $generator;
		$generator = sub { sprintf $format, @_ };
	}
	
	return $generator;
}

sub _setup_using_parse_keyword {
	my ( $class, $opt ) = ( shift, @_ );
	my ( $caller, $subname ) = @{$opt}{qw/ caller subname /};
	Sub::Boolean::make_true("$caller\::$subname");
	no strict qw( refs );
	Parse::Keyword::install_keyword_handler(
		\&{ "$caller\::$subname" },
		sub { $class->_parse( $opt ) },
	);
	$class->_clean( $caller, $subname );
}

sub _setup_fallback {
	my ( $class, $opt ) = ( shift, @_ );
	my ( $caller, $subname, $prototype, $generator ) =
		@{$opt}{qw/ caller subname prototype generator /};
	my $code = $generator->( map "\$_[$_]", 0 .. 100 );
	no strict 'refs';
	*{"$caller\::$subname"} = eval "sub $prototype { $code }";
	$class->_clean( $caller, $subname );
}

sub _clean {
	my ( $class, $caller, $subname ) = ( shift, @_ );
	'namespace::clean'->import( -cleanee => $caller, $subname ) if DO_CLEAN;
}

sub _parse {
	my ( $class, $opt ) = ( shift, @_ );
	my ( $caller, $subname, $prototype, $generator ) =
		@{$opt}{qw/ caller subname prototype generator /};
	
	require Parse::Keyword;
	require PPI;
	my $str    = Parse::Keyword::lex_peek( 1000 );
	my $ppi    = 'PPI::Document'->new( \$str );
	my $list   = $ppi->find_first( 'Structure::List' );
	my @tokens = $list->find_first( 'Statement::Expression' )->children;
	my $length = 2;
	
	my @args = undef;
	while ( my $t = shift @tokens ) {
		$length += length( "$t" );
		
		if ( $t->isa( 'PPI::Token::Operator' ) and $t =~ m{\A(,|\=\>)\z} ) {
			push @args, undef;
		}
		elsif ( defined $args[-1] or not $t->isa( 'PPI::Token::Whitespace' ) ) {
			no warnings qw(uninitialized);
			$args[-1] .= "$t";
		}
	}
	pop @args unless defined $args[-1];
	
	if ( $prototype =~ /\A\((.+)\)\z/ ) {
		my $i = 0;
		local $_ = $1;
		my $saw_semicolon = 0;
		my $saw_slurpy = 0;
		while ( length ) {
			my $backslashed = 0;
			my $chars = '';
			
			if ( /\A;/ ) {
				$saw_semicolon++;
				s/\A.//;
				redo;
			}
			
			if ( /\A\\/ ) {
				$backslashed++;
				s/\A.//;
			}
			
			if ( /\A\[(.+?)\]/ ) {
				$chars = $1;
				s/\A\[(.+?)\]//;
			}
			else {
				$chars = substr $_, 0, 1;
				s/\A.//;
			}
			
			if (!$saw_semicolon) {
				$#args >= $i
					or croak "Not enough arguments for macro $subname$prototype";
			}
			
			my $arg = $args[$i];
			if ( $backslashed and $chars eq '@' ) {
				$arg =~ /\A\s*\@/
					or croak "Expected array for argument $i to macro $subname$prototype; got: $arg";
			}
			elsif ( $backslashed and $chars eq '%' ) {
				$arg =~ /\A\s*\%/
					or croak "Expected hash for argument $i to macro $subname$prototype; got: $arg";
			}
			elsif ( $chars =~ /[@%]/ ) {
				$saw_slurpy++;
			}
			
			$i++;
		}
		
		if ( $#args >= $i and !$saw_slurpy ) {
			croak "Too many arguments for macro $subname$prototype";
		}
	}
	
	Parse::Keyword::lex_read( $length );
	Parse::Keyword::lex_stuff( sprintf ' && do { %s }', $generator->(@args) );
	return \&Sub::Boolean::truthy; # will never be called. sigh.
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Macro::Simple - preprocessor-like macros in Perl

=head1 SYNOPSIS

  use Macros::Simple {
    'CAN($$)' => 'blessed(%1$s) && %1$s->can(%2$s)',
  };
  
  ...;
  
  if ( CAN($obj, 'get') ) {
    ...;
  }

=head1 DESCRIPTION

This module implements something like C preprocessor macros for Perl 5.14+.
It has fallbacks for Perl 5.8.3+.

I initially wrote this code back in 2014, but never put it on CPAN until now.

=head2 Methods

=head3 C<< import( \%macros ) >>

The primary interface for this module is the C<use> statement as (obviously)
it needs to work its magic at compile time.

Macros are defined as key-value pairs.

The keys are the names of the macros, optionally including a sub prototype.
(The full feature set of Perl prototypes is not supported.) It is recommended
that you use ALL_CAPS for macro names, but this is not enforced.

The values are code generators. A code generator is responsible for generating
a string of Perl code that the macro will expand to.

Code generators can be coderefs which will be passed the macro's arguments
as strings of Perl code, and should return the expanded Perl code as a string.

  use Macro::Simple {
    'ISA($;$)' => sub {
      my ( $obj, $class ) = @_;
      $class ||= '__PACKAGE__';
      require Scalar::Util;
      return sprintf(
        'Scalar::Util::blessed(%s) and %s->isa(%s)',
        $obj, $obj, $class,
      );
    },
  };

In many simple cases though, an sprintf-compatible string is sufficient:

  use Macro::Simple {
    'CAN($$)' => 'blessed(%1$s) && %1$s->can(%2$s)',
  };

Macro::Simple has some built-in support for using L<Type::Tiny> types as
generators too:

  use Types::Standard qw( Str );
  use Macro::Simple {
    'IS_STR($)'     => { is     => Str },
    'ASSERT_STR($)' => { assert => Str },
  };

=head3 C<< setup_for( $package, \%macros ) >>

The C<import> method sets up macros for its caller. If you need to install the
macros into a different package (which should currently be in the process of
compiling!), then you can use C<< Macro::Simple->setup_for( $pkg, \%macros ) >>.

=head3 C<< handle_generator( $generator ) >>

Method used internally to transform a non-coderef generator into a coderef.
(Is also called for coderefs, but the value is simply passed through.)
Overriding this method may be useful in subclasses.

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-macro-simple/issues>.

=head1 SEE ALSO

I dunno.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
