use 5.008008;
use strict;
use warnings;

package Marlin::XAttribute::Lvalue;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.020000';

use B                     ();
use Eval::TypeTiny        ();
use LV                    ();
use Marlin::Attribute     ();
use Scalar::Util          ();

# This is just a Marlin::Role which will be applied to Marlin::Attribute
use Marlin::Role;

after canonicalize_is => sub {
	my $me = shift;
	
	if ( not ref $me->{':Lvalue'} ) {
		my $method_name = $me->{':Lvalue'};
		$me->{':Lvalue'} = { method_name => $method_name, try => !!0 };
	}

	if ( $me->{':Lvalue'}{method_name} eq 1 ) {
		$me->{':Lvalue'}{method_name} = $me->{slot};
	}
	
	# If user has requested an lvalue method that has the same name
	# as a reader or accessor, assume they don't want the reader or
	# accessor!
	my $method_name = $me->{':Lvalue'}{method_name};
	for my $thing ( qw/ reader accessor / ) {
		delete $me->{$thing} if defined $me->{$thing} && $me->{$thing} eq $method_name;
	}
	
	# We might have removed the reader and/or accessor, leaving this attribute
	# without any reader, writer, accessor, predicate, or clearer, making it
	# technically bare. That doesn't really matter to us, but if inflating to
	# Moose, it will whine about a non-bare attribute which has no methods
	# associated with it.
	unless ( grep { defined $me->{$_} } qw/ reader writer accessor predicate clearer / ) {
		$me->{is} = 'bare';
	}
};

after install_accessors => sub {
	my $me = shift;
	
	my $pkg = $me->{package};
	my $method_name = $me->{':Lvalue'}{method_name};
	
	if ( Marlin::Attribute::HAS_CXSA and $me->has_simple_accessor ) {
		Class::XSAccessor->import(
			class            => $pkg,
			lvalue_accessors => { $method_name => $me->{slot} },
		);
		return;
	}
	
	$me->install_coderef( $method_name, $me->Lvalue );
};

around provides_accessors => sub {
	my $next = shift;
	my $me   = shift;
	
	my @list = $me->$next( @_ );
	push @list, [ $me->{':Lvalue'}{method_name}, 'lvalue accessor', $me ];
	
	return @list;
};

sub Lvalue {
	my $me = shift;
	
	# inline_to_coderef doesn't actually expect any "sub{" and "}" to wrap
	# the code and will add that itself, but we need to include that to add
	# the ":lvalue" attribute. So we need to do this little trick afterwards
	# to remove the "sub {...}" wrapper that inline_to_coderef adds.
	my $coderef = $me->inline_to_coderef( 'lvalue accessor' => qq{
		+sub :lvalue {
			my \$self = shift;
			LV::lvalue
				LV::get { @{[ $me->inline_reader('$self') ]} }
				LV::set { @{[ $me->inline_writer('$self', '$_[0]') ]} }
		}
	} );
	$coderef = $coderef->(); # Little trick
}

my $missing_mxlva_warning;
after injected_metadata => sub {
	my ( $me, $framework, $meta_attr ) = @_;
	
	return unless my $method = $me->{':Lvalue'}{method_name};
	
	if ( $framework eq 'Moose' ) {
	
		if ( not eval { require MooseX::LvalueAttribute; 1 } ) {
			if ( not $missing_mxlva_warning++ ) {
				Marlin::Util::_carp 'MooseX::LvalueAttribute is not installed';
			}
			return;
		}
		
		require Moose::Util;
		require MooseX::LvalueAttribute::Trait::Accessor;
		require MooseX::LvalueAttribute::Trait::Attribute;
		
		Moose::Util::ensure_all_roles(
			$meta_attr,
			'MooseX::LvalueAttribute::Trait::Attribute',
		);
		
		my $accessor = Moose::Meta::Method::Accessor->_new(
			accessor_type => 'accessor',
			attribute => $meta_attr,
			name => $me->{slot},
			body => defined( &{ $me->{package} . "::$method" } ) ? \&{ $me->{package} . "::$method" } : $me->Lvalue,
			package_name => $me->{package},
			definition_context => +{ %{ $meta_attr->{definition_context} } },
		);
		Moose::Util::ensure_all_roles(
			$accessor,
			'MooseX::LvalueAttribute::Trait::Accessor',
		);
		Scalar::Util::weaken( $accessor->{attribute} );
		$meta_attr->associate_method( $accessor );
		
		my $meta_class = Moose::Util::find_meta($meta_attr->associated_class);
		$meta_class->make_mutable;
		$meta_class->add_method( $accessor->name, $accessor );
		$meta_class->make_immutable;
		
		$me->injected_accessor_metadata( Moose => $accessor );
	}
};

__PACKAGE__
__END__

=pod

=encoding utf-8

=head1 NAME

Marlin::XAttribute::Lvalue - Marlin attribute extension for lvalue accessors.

=head1 SYNOPSIS

  package Local::Person {
    use Marlin::Util -all;
    use Types::Common -types;
    use Marlin
      name => {
        required       => true,
        isa            => Str,
        ':Lvalue'      => true,
      };
  }
  
  my $bob = Local::Person->new( name => 'Bob' );
  say $bob->name;           # "Bob"
  $bob->name = "Robert";    # set a new value
  say $bob->name;           # "Robert"

=head1 IMPORTING THIS MODULE

The standard way to import Marlin attribute extensions is to include them in the
attribute definition hashrefs passed to C<< use Marlin >>

  package Local::Person {
    use Marlin::Util -all;
    use Types::Common -types;
    use Marlin
      name => {
        required       => true,
        isa            => Str,
        ':Lvalue'      => true,
      };
  }

It is possible to additionally load it with C<< use Marlin::XAttribute::Lvalue >>,
which won't I<do> anything, but might be useful to automatic dependency
analysis.

  package Local::Person {
    use Marlin::Util -all;
    use Marlin::XAttribute::Lvalue;
    use Types::Common -types;
    use Marlin
      name => {
        required       => true,
        isa            => Str,
        ':Lvalue'      => true,
      };
  }

=head1 DESCRIPTION

Creates an lvalue accessor for your attribute.

If your attribute doesn't have any defaults, type constraints or coercions,
triggers, or anything else to slow it down, then it will be a fairly fast
lvalue accessor generated by L<Class::XSAccessor>.

Otherwise, it will be implemented in Pure Perl, and be much slower.

You can provide a specific name for your lvalue accessor:

  package Local::Person {
    use Marlin::Util -all;
    use Types::Common -types;
    use Marlin
      name => {
        required       => true,
        isa            => Str,
        ':Lvalue'      => 'moniker',
      };
  }
  
  my $alice = Local::Person->new( name => "Alice" );
  
  $alice->moniker = 'Allie';   # Lvalue accessor
  say $alice->name;            # Standard non-lvalue reader

If you don't provide a specific name, it will be created instead of your
standard reader/accessor.

This extension makes no changes to your constructor.

=head2 Usage with C<alias_for>

It should be possible to set C<alias_for> to "Lvalue" (with a capital L).

  package Local::Person {
    use Marlin::Util -all;
    use Types::Common -types;
    use Marlin
      name => {
        required       => true,
        isa            => Str,
        ':Lvalue'      => 1,
        alias          => [ qw/ moniker label / ],
        alias_for      => 'Lvalue',
     };
  }
  
  my $x = Local::Person->new( name => 'Bob' );
  $x->moniker = 'Robert';
  say $x->label;  # Robert

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-marlin-xattribute-lvalue/issues>.

=head1 SEE ALSO

L<Marlin>, L<LV>.

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
