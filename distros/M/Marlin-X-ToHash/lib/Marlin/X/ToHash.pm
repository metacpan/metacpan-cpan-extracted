use 5.008008;
use strict;
use warnings;

package Marlin::X::ToHash;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.020000';

use Marlin::Util          qw( true false );
use Types::Common         qw( -types );

use Marlin (
	-with       => 'Marlin::X',
	method_name => { isa => Str,      default => 'to_hash' },
	strict_args => { isa => Bool,     default => true },
	extra_args  => { isa => Bool,     default => false },
);

use B                     ();
use Clone                 ();
use Eval::TypeTiny::CodeAccumulator;
use Scalar::Util          ();

sub BUILD {
	my $plugin = shift;
	if ( $plugin->marlin->isa('Marlin::Role') ) {
		Marlin::Util::_croak "Marlin::X::ToHash cannot be applied to roles";
	}
}

sub adjust_setup_steps {
	my $plugin = shift;
	my $steps  = shift;
	
	my $callback = sprintf '%s::%s', __PACKAGE__, 'setup_to_hash_method';
	push @$steps, $callback;
}

sub setup_to_hash_method {
	my $plugin = shift;
	my $marlin = shift;
	
	my $code = $plugin->_make_to_hash_method( $marlin );
	$marlin->export( $plugin->method_name, $code->compile );
	
	return $marlin;
}

sub _make_to_hash_method {
	my $plugin = shift;
	my $marlin = shift;
	
	my $code = Eval::TypeTiny::CodeAccumulator->new( description => 'to_hash' );
	$code->addf( 'sub {' );
	$code->increase_indent;
	$code->addf( 'my $self  = shift;' );
	$code->addf( InstanceOf->of( $marlin->this )->inline_assert('$self') );
	$code->addf( 'my $class = ref $self;' );

	{
		my $var = $code->add_variable( '$to_hash_plugin', \$plugin );
		$code->addf( 'if ( $class ne %s ) {', B::perlstring($marlin->this) );
		$code->increase_indent;
		$code->addf( 'my $child_marlin = %s->find_meta( $class ) or %s("$class is not a Marlin class");', ref($marlin), $marlin->_croaker );
		$code->addf( 'my $child_hasher = %s->_make_to_hash_method_for_child( $child_marlin );', $var );
		$code->addf( 'return $self->$child_hasher( @_ );' );
		$code->decrease_indent;
		$code->addf( '}' );
	}

	$code->addf( 'my %%args  = ( @_ == 1 and %s ) ? %%{+shift} : @_;', HashRef->inline_check('$_[0]') );
	$code->addf( 'my $hash = {};' );
	$code->addf( 'my $used = 0;' ) if $plugin->strict_args;
	$code->add_gap;
	
	$marlin->canonicalize_attributes;
	my @allowed;
	
	for my $attr ( @{ $marlin->attributes_with_inheritance } ) {
		
		if ( not exists $attr->{to_hash} ) {
			$attr->{to_hash} = ( $attr->{storage} ne 'PRIVATE' );
		}
		
		$code->addf( '{' );
		$code->increase_indent;
		$code->addf( 'my ( $value, $has_value );' );
		
		if ( $attr->{to_hash} =~ /:build/ ) {
			$code->add_line( $attr->inline_maybe_write_default('$self') );
		}
		
		my @aliases;
		@aliases = @{ $attr->{alias} or [] } if $attr->{alias};
		
		my $if = 'if';
		my $init_arg = exists( $attr->{init_arg} ) ? $attr->{init_arg} : $attr->{slot};
		push @allowed, $init_arg if defined $init_arg;
		
		if ( @aliases ) {
			$code->addf( 'if ( my @found = grep { exists $args{$_} } %s ) {',
				join( q[, ] => map { B::perlstring($_) } $init_arg, @aliases ) );
			$code->increase_indent;
			$code->addf( 'if ( @found > 1 ) {' );
			$code->increase_indent;
			$code->addf( 'shift @found;' );
			$code->addf( '%s("Superfluous %%s used for attribute \'%%s\': %%s" , @found==1 ? "alias" : "aliases", %s, join( q[, ], sort @found ) );', $attr->_croaker, B::perlstring($attr->{slot}) );
			$code->decrease_indent;
			$code->addf( '}' );
			$code->addf( '( $value, $has_value ) = ( $args{$found[0]}, !!1 );' );
			$code->addf( '$used++;' ) if $plugin->strict_args;
			$code->addf( 'undef $has_value unless defined $value;' ) if $attr->{undef_tolerant};
			$code->decrease_indent;
			$code->addf( '}' );
			$if = 'elsif';
			push @allowed, @aliases;
		}
		elsif ( defined $init_arg ) {
			$code->addf( 'if ( exists $args{%s} ) {', B::perlstring($init_arg) );
			$code->increase_indent;
			$code->addf( '( $value, $has_value ) = ( $args{%s}, !!1 );', B::perlstring($init_arg) );
			$code->addf( '$used++;' ) if $plugin->strict_args;
			$code->addf( 'undef $has_value unless defined $value;' ) if $attr->{undef_tolerant};
			$code->decrease_indent;
			$code->addf( '}' );
			$if = 'elsif';
		}
		
		if ( $attr->{to_hash} eq 1 or not exists $attr->{to_hash} ) {
			$code->addf( '%s ( %s ) {', $if, $attr->inline_predicate('$self') );
			$code->increase_indent;
			$code->addf( '( $value, $has_value ) = ( %s, !!1 );', $attr->inline_access('$self') );
			$code->decrease_indent;
			$code->addf( '}' );
		}
		elsif ( 'CODE' eq ref $attr->{to_hash} ) {
			my $var = $code->add_variable( $attr->make_var_name('hash_exporter'), \$attr->{to_hash} );
			$code->addf( '%s ( %s ) {', $if, $attr->inline_predicate('$self') );
			$code->increase_indent;
			$code->addf( '( $value, $has_value ) = ( scalar $self->%s( %s, %s ), !!1 );', $var, B::perlstring($attr->{slot}), $attr->inline_access('$self') );
			$code->decrease_indent;
			$code->addf( '}' );
		}
		elsif ( $attr->{to_hash} eq 0 or $attr->{to_hash} eq ':none' ) {
			# no clone
		}
		elsif ( !ref $attr->{to_hash} and $attr->{to_hash} =~ /:method\((.+?)\)/ ) {
			my $clone_method = $1;
			$code->addf( '%s ( %s and Scalar::Util::blessed( %s ) ) {', $if, $attr->inline_predicate('$self'), $attr->inline_access('$self') );
			$code->increase_indent;
			$code->addf( '( $value, $has_value ) = ( ( %s )->%s, !!1 );', $attr->inline_access('$self'), $clone_method );
			$code->decrease_indent;
			$code->addf( '}' );
		}
		elsif ( !ref $attr->{to_hash} and $attr->{to_hash} =~ /:method/ ) {
			$code->addf( '%s ( %s and Scalar::Util::blessed( %s ) ) {', $if, $attr->inline_predicate('$self'), $attr->inline_access('$self') );
			$code->increase_indent;
			$code->addf( '( $value, $has_value ) = ( ( %s )->to_hash, !!1 );', $attr->inline_access('$self') );
			$code->decrease_indent;
			$code->addf( '}' );
		}
		elsif ( !ref $attr->{to_hash} and $attr->{to_hash} =~ /:selfmethod\((.+?)\)/ ) {
			my $clone_method = $1;
			$code->addf( '%s ( %s ) {', $if, $attr->inline_predicate('$self') );
			$code->increase_indent;
			$code->addf( '( $value, $has_value ) = ( scalar $self->%s( %s, %s ), !!1 );', $clone_method, B::perlstring($attr->{slot}), $attr->inline_access('$self') );
			$code->decrease_indent;
			$code->addf( '}' );
		}
		elsif ( !ref $attr->{to_hash} and $attr->{to_hash} =~ /^[^\W0-9]\w+$/ ) {
			$code->addf( '%s ( %s ) {', $if, $attr->inline_predicate('$self') );
			$code->increase_indent;
			$code->addf( '( $value, $has_value ) = ( scalar $self->%s( %s, %s ), !!1 );', $attr->{to_hash}, B::perlstring($attr->{slot}), $attr->inline_access('$self') );
			$code->decrease_indent;
			$code->addf( '}' );
		}
		elsif ( !ref $attr->{to_hash} and $attr->{to_hash} =~ /:deep/ ) {
			$code->addf( '%s ( %s ) {', $if, $attr->inline_predicate('$self') );
			$code->increase_indent;
			$code->addf( '( $value, $has_value ) = ( scalar Clone::clone( %s ), !!1 );', $attr->inline_access('$self') );
			$code->decrease_indent;
			$code->addf( '}' );
		}
		elsif ( !ref $attr->{to_hash} and $attr->{to_hash} =~ /:simple/ ) {
			$code->addf( '%s ( %s ) {', $if, $attr->inline_predicate('$self') );
			$code->increase_indent;
			$code->addf( '( $value, $has_value ) = ( %s, !!1 );', $attr->inline_access('$self') );
			$code->decrease_indent;
			$code->addf( '}' );
		}
		
		$code->addf( 'if ( $has_value%s ) {', ( $attr->{to_hash} =~ /:defined/ ) ? q{ and defined $value} : q{} );
		$code->increase_indent;
		do {
			local $attr->{storage} = 'HASH';
			if ( $attr->{to_hash} =~ /:key\((.+?)\)/ ) {
				my $new_key = $1;
				local $attr->{slot} = $new_key;
				$code->add_line( $attr->inline_access_w( '$hash', '$value' ) );
			}
			else {
				$code->add_line( $attr->inline_access_w( '$hash', '$value' ) );
			}
		};
		$code->decrease_indent;
		$code->addf( '}' );
		
		$code->decrease_indent;
		$code->addf( '}' );
		$code->add_gap;
	}
	
	if ( $plugin->extra_args ) {
		my $check = do {
			my $enum = Enum->of( @allowed );
			$enum->can( '_regexp' )
				? sprintf( '/\\A%s\\z/', $enum->_regexp )
				: $enum->inline_check( '$_' );
		};
		$code->addf( 'if ( keys( %%args ) > $used ) {' );
		$code->increase_indent;
		$code->addf( 'my @unknown = grep not( %s ), keys %%args;', $check );
		$code->addf( '( exists $hash->{$_} or $hash->{$_} = $args{$_} ) for @unknown;' );
		$code->decrease_indent;
		$code->add_line( '}' );
		$code->add_gap;
	}
	elsif ( $plugin->strict_args ) {
		my $check = do {
			my $enum = Enum->of( @allowed );
			$enum->can( '_regexp' )
				? sprintf( '/\\A%s\\z/', $enum->_regexp )
				: $enum->inline_check( '$_' );
		};
		$code->addf( 'if ( keys( %%args ) > $used ) {' );
		$code->increase_indent;
		$code->addf( 'my @unknown = grep not( %s ), keys %%args;', $check );
		$code->addf( '%s("Unexpected keys in to_hash arguments: " . join( q[, ], sort @unknown ) ) if @unknown;', $marlin->_croaker );
		$code->decrease_indent;
		$code->add_line( '}' );
		$code->add_gap;
	}
	
	{
		my $var = $code->add_variable( '%AFTER_CACHE', {} );
		my $svar = $var; $svar =~ s/\%/\$/;
		$code->addf( '%s{$class} ||= do {;', $svar );
		$code->increase_indent;
		$code->add_line( 'no strict "refs";' );
		$code->add_line( 'my $linear_isa = mro::get_linear_isa($class);' );
		$code->add_line( '[ map { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () } map { "$_\::AFTER_TO_HASH" } reverse @$linear_isa ];' );
		$code->decrease_indent;
		$code->add_line( '};' );
		$code->addf( '$_->( $self, \%%args, $hash ) for @{ %s{$class} };', $svar );
	}
	
	$code->addf('return $hash;');
	$code->decrease_indent;
	$code->addf( '}' );
	
	#warn $code->code;
	
	return $code;
}

sub _make_to_hash_method_for_child {
	my $plugin = shift;
	my $marlin = shift;
	my $code = $plugin->_make_to_hash_method( $marlin );
	my $coderef = $code->compile;
	
	$marlin->export( $plugin->method_name, $coderef );
	return $coderef;
}

__PACKAGE__
__END__

=pod

=encoding utf-8

=head1 NAME

Marlin::X::ToHash - Marlin extension to add a C<to_hash> method to your class.

=head1 SYNOPSIS

  package Local::Date {
    use Marlin qw( year month day :ToHash );
  }
  
  my $xmas      = Local::Date->new( day => 25, month => 12, year => 2025 );
  my $xmas_href = $xmas->to_hash();

=head1 IMPORTING THIS MODULE

The standard way to import Marlin extensions is to include them in the
list passed to C<< use Marlin >>:

  package Local::Date {
    use Marlin qw( year month day :ToHash );
  }

It is possible to additionally load it with C<< use Marlin::X::ToHash >>,
which won't I<do> anything, but might be useful to automatic dependency
analysis.

  package Local::Date {
    use Marlin qw( year month day :ToHash );
    use Marlin::X::ToHash 0.020000;  # does nothing
  }

=head1 DESCRIPTION

This package creates a method in your class that does roughly:

  sub to_hash {
    my ( $self, %args ) = @_;
    my %hash = ( %$self, %args );
    return \%hash;
  }

Except it also:

=over

=item *

Skips over "PRIVATE" storage attributes by default.

=item *

Respects the C<init_arg> for each attribute.

=item *

Calls lazy defaults, checks type constraints, and does type coercions.

=item *

Allows per-attribute tweaks to its behaviour.

=item *

Will call a custom C<AFTER_TO_HASH> before returning the hashref.

=item *

Complains if you give it arguments which it doesn't recognize.

=back

You can tweak an attribute's behaviour using:

  use Marlin foo => { to_hash => ... };

Valid values for C<to_hash>:

=over

=item C<< :simple >>

A simple shallow copy. If the value is a reference, the value in the hash will
refer to the same data.

  ## to_hash => ':simple'
  $hash->{foo} = $self->{foo};

This is the default and will be used if C<to_hash> is omitted, or
for C<< to_hash => true >>.

=item C<< :deep >>

Uses the L<Clone> module to make a deep clone of the original value.

  ## to_hash => ':deep'
  $hash->{foo} = Clone::clone( $self->{foo} );

=item C<< :none >>

Does not copy the attribute value to the hash.

You can also specify this as C<< to_hash => false >>.

=item C<< :method >> or C<< :method(NAME) >>

Calls a method on the original value, assuming it's a blessed object. If the
original value is not a blessed object, it will silently be skipped. If no
C<NAME> is provided, the name is assumed to be "to_hash".

  ## to_hash => ':method'
  if ( blessed $self->{foo} ) {
    $hash->{foo} = $self->{foo}->to_hash;
  }
  
  ## to_hash => ':method(as_hash)'
  if ( blessed $self->{foo} ) {
    $hash->{foo} = $self->{foo}->as_hash;
  }

=item C<< :selfmethod(NAME) >>

Calls a method on the original object.

  ## to_hash => ':selfmethod(make_copy)'
  $hash->{foo} = $self->make_copy( foo => $self->{foo} );

You can also specify this as C<< to_hash => "NAME" >> as a shortcut.

=item CODE

Setting C<< to_hash => sub {...} >> will call the coderef in a similar
style to C<< :selfmethod >>.

  ## to_hash => $coderef
  $hash->{foo} = $self->$coderef( foo => $self->{foo} );

=item C<< :key(KEYNAME) >>

Renames this attribute in the hash.

  ## to_hash => ':key(xyzzy)'
  $hash->{xyzzy} = $self->{foo};

=item C<< :defined >>

Only adds the value to the hash if it's defined.

  ## to_hash => ':defined'
  $hash->{foo} = $self->{foo} if defined $self->{foo};

=item C<< :build >>

Forces any lazy default/builder to be run first.

  ## to_hash => ':build'
  $self->{foo} = $self->_build_foo() unless exists $self->{foo};
  $hash->{foo} = $self->{foo};

=back

Because C<< :method >> only works when the value is a blessed object,
you can indicate a fallback that will be used in other cases.

  ## to_hash => ':method(make_copy) :deep'
  if ( blessed $self->{foo} ) {
    $hash->{foo} = $self->{foo}->make_copy;
  }
  else {
    $hash->{foo} = Clone::clone( $self->{foo} );
  }

In general, you can combine any options that make sense to combine.

  ## to_hash => ':method(make_copy) :simple :build :defined'
  $self->{foo} = $self->_build_foo()
    unless exists $self->{foo};
  if ( blessed $self->{foo} ) {
    my $tmp = $self->{foo}->make_copy;
    $hash->{foo} = $tmp if defined $tmp;
  }
  else {
    my $tmp = $self->{foo};
    $hash->{foo} = $tmp if defined $tmp;
  }

You can also set a few class-wide options for how the plugin behaves:

  use Marlin qw( foo bar ),
    ':ToHash' => {
      method_name     => 'as_hash',  # Name for the method
      strict_args     => true,       # Complain about unrecognized params?
      extra_args      => false,      # Keep unrecognized params?
    };

You can define an C<AFTER_TO_HASH> method in your class to alter the returned
hash:

  sub AFTER_TO_HASH ( $self, $args, $hash_ref ) {
    ...;        # alter hash here
    return 42;  # returned value is ignored
  }

Any C<AFTER_TO_HASH> methods in parent classes will also be automatically
called (like C<BUILD>!), so you don't need to worry about calling
C<< $self->SUPER::AFTER_TO_HASH( $args, $hash_ref ) >> manually. (Indeed,
you should not!)

=head1 COOKBOOK

=head2 Combining Attributes

Imagine you have a class which keeps a Person's first name and last name
in separate attributes but you wish to combine them in the output hashref
instead of them being separate.

In this example, we create a C<full_name> attribute which is built from
the separate names, and make sure that it is built so that it can be
included in the output.

  package Local::Person {
    use Marlin::Util -all;
    use Marlin ':ToHash',
      'first_name!' => { to_hash => false },
      'last_name!'  => { to_hash => false },
      'full_name'   => { is      => lazy,
                         builder => true,
                         to_hash => ':build :simple' },
      'age'         => { to_hash => true };
    
    sub _build_full_name ( $self ) {
      join q[ ], $self->first_name, $self->last_name;
    }
  }

In this alternative implementation, we use C<AFTER_TO_HASH> to manually
add the full name to the hashref.

  package Local::Person {
    use Marlin::Util -all;
    use Marlin ':ToHash',
      'first_name!' => { to_hash => false },
      'last_name!'  => { to_hash => false },
      'age'         => { to_hash => true };
    
    sub AFTER_TO_HASH ( $self, $args, $hashref ) {
      $hashref->{full_name} = 
        join q[ ], $self->first_name, $self->last_name;
    }
  }

In either case, the following test case should pass:

  use Test2::V0;
  
  my $x = Local::Person->new(
    first_name   => 'Alice',
    last_name    => 'Smith',
    age          => 30,
  );
  
  is( $x->to_hash, { full_name => 'Alice Smith', age => 30 } );

=head2 Adding Ad-Hoc Keys

If you set the C<extra_args> option to true, your C<to_hash> method will
accept additional keys and values to pass through into the hash.

  package Local::User {
    use Marlin::Util -all;
    use Marlin qw( name url ),
      ':ToHash' => { extra_args => true };
    
    sub to_json_ld ( $self ) {
      return $self->to_hash(
        '@context' => 'http://schema.org/',
        '@type'    => 'Person',
      );
    }
  }
  
  use Test2::V0;
  
  my $user = Local::User->new( name => 'Bob' );
  
  is(
    $user->to_hash,
    { name => 'Bob' },
  );
  
  is(
    $user->to_json_ld,
    {
      '@context' => 'http://schema.org/',
      '@type'    => 'Person',
      'name'     => 'Bob',
    },
  );

Without enabling the C<extra_args> option, any unrecognized arguments
passed to C<to_hash> would be an error.

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-marlin-x-tohash/issues>.

=head1 SEE ALSO

L<Marlin>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2026 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

🐟🐟
