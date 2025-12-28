use 5.008008;
use strict;
use warnings;

package Marlin::X::Clone;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.009000';

use Carp 'croak';
use Clone;
use Eval::TypeTiny::CodeAccumulator;
use Types::Common -types;

use Marlin
	# All Marlin::X::* plugins need to accept these attributes
	marlin      => { isa => Object,  required => !!1, },
	try         => { isa => Bool,    default => !!0, },
	# These are specific to Marlin::X::Clone
	method_name => { isa => Str,     default => 'clone' },
	call_build  => { isa => Bool,    default => !!1 },
	strict_args => { isa => Bool,    default => !!1 },
	;

# Is possible to do some sanity checking here.
sub BUILD {
	my $plugin = shift;
	if ( $plugin->marlin->isa('Marlin::Role') ) {
		croak "Marlin::X::Clone cannot be applied to roles";
	}
}

# This is the main hook Marlin uses to give plugins a chance to do something.
# $steps is a list of subs which will be called by Marlin when setting up the
# class or role. Plugins can add or remove steps.
sub adjust_setup_steps {
	my $plugin = shift;
	my $steps  = shift;

	# Add an extra step called "Marlin::X::Clone::setup_clone_method".
	# In our case, it doesn't really matter where we add the step, so
	# we'll just add it at the end.
	push @$steps, sprintf '%s::%s', __PACKAGE__, 'setup_clone_method';
}

# When our step is called, it is passed the Marlin object and the plugin
# object. Note the Marlin object is the FIRST parameter!
sub setup_clone_method {
	my $marlin = shift;
	my $plugin = shift;
	
	# All we're doing here is creating a method called "clone" and
	# then telling Marlin to export it.
	my $code = $plugin->_make_clone_method( $marlin );
	$marlin->export( $plugin->method_name, $code->compile );
	
	# Marlin offers "export" and "lexport". The former will export methods
	# into the class/role currently being built. The latter will export a
	# function lexically into the compiling package (or the caller if lexical
	# exports are unavailable).
	#
	# Use "export" to install methods into the class being built. Use
	# "lexport" for utility functions, keywords, etc.
	
	return $marlin;
}

# This is the guts to the Marlin::X::Clone plugin. It is building up
# a coderef as a string using Eval::TypeTiny::CodeAccumulator. Using
# CodeAccumulator is just a little prettier than concatenating strings
# and doing an `eval` at the end.
sub _make_clone_method {
	my $plugin = shift;
	my $marlin = shift;
	
	my $code = Eval::TypeTiny::CodeAccumulator->new( description => 'clone' );
	$code->addf( 'sub {' );
	$code->increase_indent;
	$code->addf( 'my $self  = shift;' );
	$code->addf( InstanceOf->of( $marlin->this )->inline_assert('$self') );
	$code->addf( 'my $class = ref $self;' );

	# ->clone() has been called on a child class which doesn't override clone.
	# This means it may need to handle additional attributes. So attempt to
	# create a clone method for the child class!
	{
		my $var = $code->add_variable( '$clone_plugin', \$plugin );
		$code->addf( 'if ( $class ne %s ) {', B::perlstring($marlin->this) );
		$code->increase_indent;
		$code->addf( 'my $child_marlin = %s->find_meta( $class ) or %s("$class is not a Marlin class");', ref($marlin), $marlin->_croaker );
		$code->addf( 'my $child_cloner = %s->_make_clone_method_for_child( $child_marlin );', $var );
		$code->addf( 'return $self->$child_cloner( @_ );' );
		$code->decrease_indent;
		$code->addf( '}' );
	}

	$code->addf( 'my %%args  = ( @_ == 1 and %s ) ? %%{+shift} : @_;', HashRef->inline_check('$_[0]') );
	$code->addf( 'my $clone = bless( {}, $class );' );
	$code->add_gap;
	
	$marlin->canonicalize_attributes;
	my @allowed;
	
	for my $attr ( @{ $marlin->attributes_with_inheritance } ) {
		
		if ( not exists $attr->{on_clone} ) {
			$attr->{on_clone} = ( $attr->{storage} ne 'PRIVATE' );
		}
		
		$code->addf( '{' );
		$code->increase_indent;
		$code->addf( 'my ( $value, $has_value );' );
		
		my $if = 'if';
		my $init_arg = exists( $attr->{init_arg} ) ? $attr->{init_arg} : $attr->{slot};
		push @allowed, $init_arg if defined $init_arg;
		
		if ( defined $init_arg ) {
			$code->addf( 'if ( exists $args{%s} ) {', B::perlstring($init_arg) );
			$code->increase_indent;
			$code->addf( '( $value, $has_value ) = ( $args{%s}, !!1 );', B::perlstring($init_arg) );
			$code->decrease_indent;
			$code->addf( '}' );
			$if = 'elsif';
		}
		
		if ( $attr->{on_clone} eq 1 or not exists $attr->{on_clone} ) {
			$code->addf( '%s ( %s ) {', $if, $attr->inline_predicate('$self') );
			$code->increase_indent;
			$code->addf( '( $value, $has_value ) = ( %s, !!1 );', $attr->inline_access('$self') );
			$code->decrease_indent;
			$code->addf( '}' );
		}
		elsif ( 'CODE' eq ref $attr->{on_clone} ) {
			my $var = $code->add_variable( $attr->make_var_name('cloner'), \$attr->{on_clone} );
			$code->addf( '%s ( %s ) {', $if, $attr->inline_predicate('$self') );
			$code->increase_indent;
			$code->addf( '( $value, $has_value ) = ( scalar $self->%s( %s, %s ), !!1 );', $var, B::perlstring($attr->{slot}), $attr->inline_access('$self') );
			$code->decrease_indent;
			$code->addf( '}' );
		}
		elsif ( !ref $attr->{on_clone} and $attr->{on_clone} =~ /^[\W0-9]\w+$/ ) {
			$code->addf( '%s ( %s ) {', $if, $attr->inline_predicate('$self') );
			$code->increase_indent;
			$code->addf( '( $value, $has_value ) = ( scalar $self->%s( %s, %s ), !!1 );', $attr->{on_clone}, B::perlstring($attr->{slot}), $attr->inline_access('$self') );
			$code->decrease_indent;
			$code->addf( '}' );
		}
		elsif ( !ref $attr->{on_clone} and $attr->{on_clone} eq ':deep' ) {
			$code->addf( '%s ( %s ) {', $if, $attr->inline_predicate('$self') );
			$code->increase_indent;
			$code->addf( '( $value, $has_value ) = ( scalar Clone::clone( %s ), !!1 );', $attr->inline_access('$self') );
			$code->decrease_indent;
			$code->addf( '}' );
		}
				
		$code->addf( 'if ( $has_value ) {' );
		$code->increase_indent;
		$code->add_line( $attr->inline_writer( '$clone', '$value' ) );
		$code->decrease_indent;
		$code->addf( '}' );
		
		if ( ( exists $attr->{default} or defined $attr->{builder} ) and not $attr->{lazy} ) {
			my $var = $code->add_variable( $attr->make_var_name('default'), \$attr->{default} );
			$code->addf( 'else {' );
			$code->increase_indent;
			$code->addf( '$value = %s;', $attr->inline_default('$clone', $var) );
			delete local $attr->{trigger};
			$code->add_line( $attr->inline_writer( '$clone', '$value' ) );
			$code->decrease_indent;
			$code->addf( '}' );
		}

		$code->decrease_indent;
		$code->addf( '}' );
		$code->add_gap;
	}
	
	if ( $plugin->call_build ) {
		$code->addf( '$%s::BUILD_CACHE{$class} ||= do {', ref($marlin) );
		$code->increase_indent;
		$code->add_line( 'no strict "refs";' );
		$code->add_line( 'my $linear_isa = mro::get_linear_isa($class);' );
		$code->add_line( '[ map { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () } map { "$_\::BUILD" } reverse @$linear_isa ];' );
		$code->decrease_indent;
		$code->add_line( '};' );
		$code->addf( '$_->( $clone, \%%args ) for @{ $%s::BUILD_CACHE{$class} };', ref($marlin) );
		$code->add_gap;
	}
	
	if ( $plugin->strict_args ) {
		my $check = do {
			my $enum = Enum->of( @allowed );
			$enum->can( '_regexp' )
				? sprintf( '/\\A%s\\z/', $enum->_regexp )
				: $enum->inline_check( '$_' );
		};
		$code->addf( 'my @unknown = grep not( %s ), keys %%args;', $check );
		$code->addf( '%s("Unexpected keys in clone arguments: " . join( q[, ], sort @unknown ) ) if @unknown;', $marlin->_croaker );
		$code->add_gap;
	}
	
	$code->addf('return $clone;');
	$code->decrease_indent;
	$code->addf( '}' );
	
	# warn $code->code;
	
	return $code;
}

# Utility method used by ->clone() to prepare a separate ->clone() method
# for any child classes.
sub _make_clone_method_for_child {
	my $plugin = shift;
	my $marlin = shift;
	my $code = $plugin->_make_clone_method( $marlin );
	my $coderef = $code->compile;
	
	$marlin->export( $plugin->method_name, $coderef );
	return $coderef;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Marlin::X::Clone - Marlin extension to add a C<clone> method to your class.

=head1 SYNOPSIS

  package Local::Date {
    use Marlin qw( year month day :Clone );
  }
  
  my $xmas     = Local::Date->new( day => 25, month => 12, year => 2025 );
  my $xmas_eve = $xmas->clone( day => 24 );

=head1 DESCRIPTION

This package creates a method in your class that does roughly:

  sub clone {
    my ( $self, %args ) = @_;
    my %clone = ( %$self, %args );
    return bless \%clone, ref($self);
  }

Except it also:

=over

=item *

Skips over "PRIVATE" storage attributes by default.

=item *

Respects the C<init_arg> for each attribute.

=item *

Calls trigger methods, uses defaults, checks type constraints, and does type coercions.

=item *

Allows per-attribute tweaks to its behaviour.

=item *

Calls C<BUILD> methods.

=item *

Complains if you give it arguments which it doesn't recognize.

=back

You can tweak an attribute's behaviour using:

  use Marlin foo => { on_clone => ... };

The C<on_clone> option can be set to "1" if you wish to allow that attribute
to be copied to clones (this is the default except for "PRIVATE" stored
attributes), set to "0" to forbid if from being copied to clones, set to
":deep" to make a deep clone of the attibute's value, or set to a coderef or
the name of a method to make a custom clone of the attribute's value.
(The coderef or method will be passed the name of the attribute and the
attribute's value as parameters and should return the cloned value.)

You can also set a few options for how the plugin behaves:

  use Marlin qw( foo bar ),
    ':Clone' => {
      method_name     => 'clone', # Name for the clone method
      call_build      => true,    # Call BUILD after cloning?
      strict_args     => true,    # Complain about unrecognized params?
    };

This module also acts as a demonstration of Marlin's extension API.
See comments in the source code for more details.

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-marlin/issues>.

=head1 SEE ALSO

L<Marlin>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

🐟🐟
