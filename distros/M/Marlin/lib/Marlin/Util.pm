use 5.008008;
use strict;
use warnings;

package Marlin::Util;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.022001';

use B                     ();
use Exporter::Tiny        qw( _croak _carp );

require Marlin;

our @ISA = 'Exporter::Tiny';
our ( %EXPORT_TAGS, @EXPORT_OK );

use constant do {
	my %attr = map {; $_ => $_ } qw( bare lazy ro rw rwp );
	$EXPORT_TAGS{attr} = [ keys %attr ];
	push @EXPORT_OK, keys %attr;
	
	my %bool = ( true => !!1, false => !!0 );
	$EXPORT_TAGS{bool} = [ keys %bool ];
	push @EXPORT_OK, keys %bool;
	
	+{ %attr, %bool };
};

# Things below this point are not exportable.
# Mostly a replacement for Module::Runtime.

{
	no strict 'refs';
	no warnings 'once';
	sub _getglob { \*{shift()} }
	sub _getstash { \%{shift()."::"} }
}

use constant {
	_WORK_AROUND_BROKEN_MODULE_STATE  => !!( "$]" < 5.009 ),
	_WORK_AROUND_HINT_LEAKAGE         => !!( "$]" < 5.011 && !( "$]" >= 5.009004 and "$]" < 5.010001 ) ),
	_MODULE_NAME_RX                   => qr/\A(?!\d)\w+(?:::\w+)*\z/,
};

sub Marlin::Util::__GUARD__::DESTROY {
	delete $INC{$_[0]->[0]} if @{$_[0]};
}

sub _require {
	my ( $file ) = @_;
	my $guard = _WORK_AROUND_BROKEN_MODULE_STATE && bless([ $file ], 'Marlin::Util::__GUARD__');
	local %^H if _WORK_AROUND_HINT_LEAKAGE;
	if ( not eval { require $file; 1 } ) {
		my $e = $@ || "Can't locate $file";
		my $me = __FILE__;
		$e =~ s{ at \Q$me\E line \d+\.\n\z}{};
		return $e;
	}
	pop @$guard if _WORK_AROUND_BROKEN_MODULE_STATE;
	return undef;
}

sub _module_notional_filename {
	my ( $module ) = @_;
	(my $file = "$module.pm") =~ s{::}{/}g;
	return $file;
}

sub _load_module {
	my ( $module ) = @_;
	_croak( qq{%s is not a module name!}, B::perlstring($module) )
		unless $module =~ _MODULE_NAME_RX;
	
	my $file = _module_notional_filename $module;
	return 1 if $INC{$file};

	my $e = _require $file;
	return 1 if !defined $e;

	_croak( $e ) if $e !~ /\ACan't locate \Q$file\E /;

	# can't just ->can('can') because a sub-package Foo::Bar::Baz
	# creates a 'Baz::' key in Foo::Bar's symbol table
	my $stash = _getstash( $module ) || {};
	no strict 'refs';
	return 1 if grep +exists &{"${module}::$_"}, grep !/::\z/, keys %$stash;
	return 1
		if $INC{"Moose.pm"} && Class::MOP::class_of($module)
		or Mouse::Util->can('find_meta') && Mouse::Util::find_meta($module);
	
	_croak( $e );
}

our %MAYBE_LOADED;
sub _maybe_load_module {
	my ( $module ) = @_;
	return $MAYBE_LOADED{$module} if exists $MAYBE_LOADED{$module};
	
	my $file = _module_notional_filename $module;
	my $e = _require $file;
	if ( not defined $e ) {
		return $MAYBE_LOADED{$module} = 1;
	}
	elsif ( $e !~ /\ACan't locate \Q$file\E / ) {
		warn "$module exists but failed to load with error: $e";
	}
	return $MAYBE_LOADED{$module} = 0;
}

sub _use_package_optimistically {
	my ( $module, $ver ) = @_;
	_maybe_load_module $module;
	if ( defined $ver && $module->can( 'VERSION' ) ) {
		$module->VERSION( $ver );
	}
	return $module;
}

__PACKAGE__
__END__

=pod

=encoding utf-8

=head1 NAME

Marlin::Util - exports a few keywords it's nice to have with Marlin

=head1 SYNOPSIS

  use v5.20.0;
  no warnings "experimental::signatures";
  
  package Person {
    use Types::Common -lexical, -all;
    use Marlin::Util -lexical, -all;
    use Marlin
      'name'  => { is => ro, isa => Str, required => true },
      'age'   => { is => rw, isa => Int, predicate => true },
      -strict;
    
    signature_for introduction => (
      method   => true,
      named    => [ audience => Optional[InstanceOf['Person']] ],
    );
    
    sub introduction ( $self, $arg ) {
      say "Hi " . $arg->audience . "!" if $arg->has_audience;
      say "My name is " . $self->name . ".";
    }
  }

=head1 DESCRIPTION

There are a few common values that often appear when defining attributes
in Marlin (and Moo and Moose)! This module exports constants for them so
they can be used as barewords.

If you add the C<< -lexical >> export tag, everything will be exported as
lexical keywords.

=head2 String constants for C<is>

Export these with C<< use Marlin::Util -attr >> or C<< use Marlin::Util -all >>.

=over

=item C<ro>

=item C<rw>

=item C<rwp>

=item C<lazy>

=item C<bare>

=back

=head2 Boolean constants

Export these with C<< use Marlin::Util -bool >> or C<< use Marlin::Util -all >>.

=over

=item C<true>

=item C<false>

=back

These are essentially the same as the C<true> and C<false> constants defined
in the L<builtin> package.

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-marlin/issues>.

=head1 SEE ALSO

This module uses L<Exporter::Tiny>.

L<Marlin>, L<Moose>, L<Moo>.

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
