use 5.008008;
use strict;
use warnings;
use utf8;

package Marlin::Role;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.015000';

# Marlin::Role is itself a Marlin class!
use Marlin qw( requires ), -base => 'Marlin';

use B                     ();
use Exporter::Tiny        ();
use Marlin::Util          ();
use Role::Tiny            ();
use Scalar::Util          qw( blessed );

sub setup_steps {
	my $me = shift;

	# We don't really need accessors to be built in this package
	# as the composing class will build them. But Moo wants them,
	# so yeah.
	return qw/
		mark_inc
		sanity_check
		install_role_tiny
		setup_roles
		canonicalize_attributes
		setup_accessors
		setup_imports
		run_delayed
		setup_compat
	/;
}

sub sanity_check {
	my $me = shift;
	
	Marlin::Util::_croak("Roles cannot have parent classes") if @{ $me->parents };
	
	return $me;
}

sub install_role_tiny {
	my $me = shift;
	
	my $this = $me->this;
	my $maybe_requires = '';
	if ( my @req = @{ $me->requires || [] } ) {
		$maybe_requires = sprintf(
			'requires(%s)',
			join( q[, ], map B::perlstring($_), @req ),
		);
	}
	eval qq{
		package $this;
		use Role::Tiny;
		$maybe_requires;
		1;
	} or die $@;
	
	return $me;
}

sub _make_modifier_imports {
	my $me = shift;
	my $info = $Role::Tiny::INFO{$me->this};
	return map {
		my $type = $_;
		$type => sub {
			my $code = pop;
			my @names = ref $_[0] eq 'ARRAY' ? @{ $_[0] } : @_;
			push @{ $info->{modifiers} ||= [] }, [ $type, @names, $code ];
			return;
		};
	} qw( before after around );
}

__PACKAGE__
__END__

=pod

=encoding utf-8

=head1 NAME

Marlin::Role - Marlin, but it's a role

=head1 SYNOPSIS

  use v5.20.0;
  
  package My::Role {
    use Marlin::Role 'foo', -requires => [ 'bar' ];
  }
  
  use My::Class {
    use Marlin -with => [ 'My::Role' ];
    sub bar { return; }
  }
  
  my $obj = My::Class->new( foo => 42 );

=head1 DESCRIPTION

Marlin::Role supports the same options as L<Marlin>, but is intended for
creating roles. It is a fairly thin wrapper around L<Role::Tiny> but performs
one additional task: copies any attributes from the role into any Marlin class
or Marlin role that consumes it.

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
