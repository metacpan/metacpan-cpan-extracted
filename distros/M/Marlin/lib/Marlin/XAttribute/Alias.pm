use 5.008008;
use strict;
use warnings;

package Marlin::XAttribute::Alias;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.013001';

use Eval::TypeTiny ();
use Role::Tiny;

after canonicalize_is => sub {
	my $me = shift;
	
	if ( 'HASH' ne ref $me->{':Alias'} ) {
		my $aliases = $me->{':Alias'};
		$me->{':Alias'} = { alias => $aliases, try => !!0 };
	}

	if ( 'ARRAY' ne ref $me->{':Alias'}{alias} ) {
		$me->{':Alias'}{alias} = [ $me->{':Alias'}{alias} ];
	}
	
	if ( not $me->{':Alias'}{for} ) {
		$me->{':Alias'}{for} = ( $me->{is} eq 'rw' ) ? 'accessor' : 'reader';
	}
};

after install_accessors => sub {
	my $me = shift;
	
	my $pkg = $me->{package};
	my @aliases = @{ $me->{':Alias'}{alias} };
	my $for     = $me->{':Alias'}{for};
	
	my $coderef;
	if ( my $orig_method_name = $me->{$for} ) {
		no strict 'refs';
		$coderef = \&{ $me->{package} . "::$orig_method_name" };
	}
	
	if ( not $coderef ) {
		$coderef = $me->$for;
	}
	
	$me->install_coderef( $_, $coderef ) for @aliases;
};

around allowed_constructor_parameters => sub {
	my $next = shift;
	my $me = shift;
	return (
		$me->$next( @_ ),
		@{ $me->{':Alias'}{alias} },
	);
};

around xs_constructor_args => sub {
	my $next = shift;
	my $me = shift;
	my @args = $me->$next( @_ );
	if ( @args ) {
		$args[-1]{alias} = [ @{ $me->{':Alias'}{alias} } ];
	}
	return @args;
};

my $missing_mxa_warning;
after injected_metadata => sub {
	my ( $me, $framework, $meta_attr ) = @_;
	
	return unless $me->{':Alias'} && @{ $me->{':Alias'}{alias} or [] };
	
	if ( $framework eq 'Moose' ) {
	
		if ( not eval { require MooseX::Aliases; 1 } ) {
			if ( not $missing_mxa_warning++ ) {
				require Carp;
				Carp::carp('MooseX::Aliases is not installed');
			}
			return;
		}
		
		require Moose::Util;
		if ( $meta_attr->can('associated_role') ) {
			Moose::Util::ensure_all_roles(
				Moose::Util::find_meta($meta_attr->associated_role),
				'MooseX::Aliases::Meta::Trait::Role',
			);
		}
		else {
			my $meta = Moose::Util::find_meta($meta_attr->associated_class);
			$meta->make_mutable;
			Moose::Util::ensure_all_roles(
				$meta,
				'MooseX::Aliases::Meta::Trait::Class',
			);
			$meta->make_immutable;
		}
		
		Moose::Util::ensure_all_roles(
			$meta_attr,
			'MooseX::Aliases::Meta::Trait::Attribute',
		);
		
		$meta_attr->{alias} = [ @{ $me->{':Alias'}{alias} } ];
	}
};

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Marlin::XAttribute::Alias - Marlin attribute extension for attribute aliases.

=head1 SYNOPSIS

  package Local::Person {
    use Marlin::Util -all;
    use Types::Common -types;
    use Marlin
      name => {
        required     => true,
        isa          => Str,
        ':Alias'     => 'moniker',
      },
      age => {
        isa          => Int,
        handles_via  => 'Num',
        handles      => {
          is_adult => [ ge => 18 ],
          is_child => [ lt => 18 ],
        },
      };
  }
  
  my $alice = Local::Person->new( name => 'Alice', age => 21 );
  say $alice->moniker if $alice->is_adult;  # says "Alice"
  
  my $bob = Local::Person->new( moniker => 'Bob', age => 12 );
  say $bob->name if $bob->is_child;  # says "Bob"

=head1 DESCRIPTION

Adds constructor and accessor aliases for an attribute.

You can use an arrayref to declare multiple aliases.

  use Marlin
    name => {
      required     => true,
      isa          => Str,
      ':Alias'     => [ 'moniker', 'label' ],
    }, ...;

If you also wish to provide other options, you can use a hashref.

  use Marlin
    name => {
      required     => true,
      isa          => Str,
      ':Alias'     => {
        alias    => [ 'moniker', 'label' ],
        for      => 'reader',
      },
    }, ...;

The C<for> option allows you to indicate whether these are aliases for the
attribute's reader method or accessor method. By default they will be aliases
for the reader, unless the attribute C<< is => "rw" >>, in which case the
aliases will be aliases for the accessor. (In theory, it is possible to set
them as aliases for a writer, predicate, or clearer, but that would be weird.)

=head1 DIAGNOSTICS

=over

=item *

B<< Superfluous alias used for attribute '%s' >>

The following examples are errors as the same attribute is being initialized
twice:

  my $bob = Local::Person->new( name => 'Bob', moniker => 'Bob' );
  
  my $bob = Local::Person->new( label => 'Bob', moniker => 'Bob' );

=item *

B<< Superfluous aliases used for attribute '%s' >>

Variant used when reporting multiple superfluous aliases.

=back

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-marlin/issues>.

=head1 SEE ALSO

L<Marlin>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025-2026 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

🐟🐟
