use v5.20;
use experimental qw( signatures postderef lexical_subs );
use feature ();
use strict;
use warnings;

package Marlin::Antlers;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003000';

use B::Hooks::AtRuntime qw( at_runtime after_runtime );
use Class::Method::Modifiers qw( install_modifier );
use Exporter::Tiny;
use Import::Into;
use Marlin ();
use Marlin::Role ();
use Marlin::Util -lexical, qw( true false );
use Types::Common -lexical, -all;

use namespace::autoclean;

our @ISA    = qw( Exporter::Tiny );
our @EXPORT = qw( has extends with before after around fresh signature signature_for __FINALIZE__ );

my %PACKAGES;

sub _exporter_validate_opts ( $me, $globals ) {
	
	my $pkg  = $globals->{into};
	my $kind = $globals->{__role} ? 'Marlin::Role' : 'Marlin';
	if ( $PACKAGES{$pkg} ) {
		Marlin::Util::_croak "$pkg already uses $kind\::Antlers";
	}
	elsif ( my $meta = Marlin->find_meta($pkg) ) {
		Marlin::Util::_croak "$pkg already uses " . ( $meta->inhaled_from // ref $meta );
	}
	else {
		$PACKAGES{$pkg} = $kind;
	}

	$globals->{installer} ||= $me->_exporter_lexical_installer( $globals );
	
	experimental->import::into( $pkg, qw( signatures postderef lexical_subs ) );
	feature->import::into( $pkg, qw( current_sub evalbytes fc say state unicode_eval unicode_strings ) );
	strict->import::into( $pkg );
	warnings->import::into( $pkg );
	Marlin::Util->import::into( $pkg, -lexical, -all );
	Types::Common->import::into( $pkg, -lexical, -all, qw( !signature !signature_for ) );
	namespace::autoclean->import::into( $pkg );
	
	my @plugins = do {
		my $tmp = Exporter::Tiny::mkopt(
			is_ArrayRef( $globals->{x} ) ? $globals->{x} :
			is_Str( $globals->{x} )      ? [ $globals->{x} ] :
			is_Defined( $globals->{x} )  ? Marlin::Util::_croak("Invalid value for 'x'") : []
		);
		$_->[0] =~ s/^:/Marlin::X::/s for $tmp->@*;
		$tmp->@*;
	};
	
	my $args = $globals->{MARLIN} = {
		caller      => $pkg,
		this        => $pkg,
		parents     => [],
		roles       => [],
		attributes  => [],
		plugins     => \@plugins,
		delayed     => [],
		strict      => !( $globals->{sloppy} ),
		constructor => $globals->{constructor} // 'new',
		modifiers   => false, # export our own versions!
	};
	my $mods = $globals->{MODIFY} = [];
	
	my $finalize = $globals->{FINALIZE} = sub () {
		state $finalized = 0;
		return if $finalized++;
		my $marlin = $kind->new( $args );
		$marlin->store_meta;
		$marlin->do_setup;
		install_modifier( $pkg, $_->@* ) for $mods->@*;
	};
	
	&after_runtime( $finalize );
}

sub _generate_has ( $me, $name, $value, $globals ) {
	return sub ( $names, @spec ) {
		
		is_ArrayRef $names
			or $names = [ $names ];
		assert_Str $_ for $names->@*;
		
		my $spec = ( @spec == 0 ) ? {} : ( @spec == 1 ) ? $spec[0] : { @spec };
		if ( is_Object $spec and $spec->DOES('Type::API::Constraint') ) {
			my $tc = $spec;
			$spec = {
				isa      => $tc,
				coerce   => !!( $tc->DOES('Type::API::Constraint::Coercible') and $tc->has_coercion ),
			};
		}
		elsif ( is_CodeRef $spec ) {
			$spec = {
				lazy     => !!1,
				builder  => $spec,
			};
		}
		
		for my $name ( $names->@* ) {
			my $default_init_arg = exists( $spec->{constant} ) ? undef : $name;
			push $globals->{MARLIN}{attributes}->@*, {
				is        => 'ro',
				init_arg  => $default_init_arg,
				$spec->%*,
				slot      => $name,
			};
		}
	};
}

sub _generate_extends ( $me, $name, $value, $globals ) {
	return sub ( @packages ) {
		
		assert_Str $_ for @packages;
		
		push $globals->{MARLIN}{parents}->@*,
			map [ split /\s+/ ],
			@packages;
	};
}

sub _generate_with ( $me, $name, $value, $globals ) {
	return sub ( @packages ) {
		
		assert_Str $_ for @packages;
		
		push $globals->{MARLIN}{roles}->@*,
			map [ split /\s+/ ],
			@packages;
	};
}

sub _generate_signature ( $me, $name, $value, $globals ) {
	return sub {
		my ( %opts ) = @_;
		$opts{method}  = 1                if !exists $opts{method};
		$opts{package} = $globals->{into} if !exists $opts{package};
		@_ = ( %opts );
		goto \&Type::Params::signature;
	};
}

sub _generate_signature_for ( $me, $name, $value, $globals ) {
	return sub {
		my ( $function, %opts ) = @_;
		$opts{method}  = 1                if !exists $opts{method};
		$opts{package} = $globals->{into} if !exists $opts{package};
		@_ = ( $function, %opts );
		goto \&Type::Params::signature_for;
	};
}

sub _generate_before ( $me, $name, $value, $globals ) {
	return $me->_for_cmm( before => $globals );
}

sub _generate_after ( $me, $name, $value, $globals ) {
	return $me->_for_cmm( after => $globals );
}

sub _generate_around ( $me, $name, $value, $globals ) {
	return $me->_for_cmm( around => $globals );
}

sub _generate_fresh ( $me, $name, $value, $globals ) {
	return $me->_for_cmm( fresh => $globals );
}

sub _for_cmm ( $me, $kind, $globals ) {
	return sub ( @names ) {
		
		my $coderef = pop @names;
		assert_CodeRef $coderef;
		
		push $globals->{MODIFY}->@*, [ $kind, @names, $coderef ];
	};
}

sub _generate___FINALIZE__ ( $me, $name, $value, $globals ) {
	return $globals->{FINALIZE};
}

__PACKAGE__
__END__

=pod

=encoding utf-8

=head1 NAME

Marlin::Antlers - a more Moose-like syntax for Marlin

=head1 SYNOPSIS

  package Local::Widget 1.0 {
    use Marlin::Antlers;
    
    has name => (
      is       => rw,
      isa      => Str,
      required => true,
    );
    
    our $NEXT_ID = 1;
    has id => sub { $NEXT_ID++ };
    
    sub dump ( $self ) {
      sprintf '%s[%d]', $self->name, $self->id;
    }
  }
  
  package Local::CoolWidget 1.0 {
    use Marlin::Antlers;
    extends 'Local::Widget 1.0';
  }
  
  my $w = Local::CoolWidget->new( name => 'Foo' );
  print $w->dump, "\n";

=head1 DESCRIPTION

Marlin::Antlers provides L<Moose>-like C<has>, C<extends>, etc keywords
for L<Marlin>.

It also exports everything from L<Types::Common> and L<Marlin::Util>.
This will give you C<true>, C<false>, C<ro>, C<rw>, C<rwp>, etc for
free, plus a whole bunch of type constraints, etc.

Everything is exported lexically.

Marlin::Antlers imports L<namespace::autoclean> for you.

Marlin::Antlers also enables L<strict> and L<warnings>, plus switches
on the following Perl features: signatures, postderef, lexical_subs,
current_sub, evalbytes, fc, say, state, unicode_eval, and unicode_strings.
It requires Perl 5.20, so you don't need to worry about whether modern
Perl syntax features like C<< // >> are supported.

Significant differences from Moose and Moo are noted below.

=head2 Keywords

=over

=item C<< has ATTRIBUTE => ( SPEC ) >>

Much like Moose and Moo's C<has> keyword, but defaults to C<< is => 'ro' >>,
so you don't get repetitive strain injury typing that out each time.

Example:

  has foo => (
    is           => rw,
    isa          => Int,
    clearer      => true,
    predicate    => true,
    lazy         => true,
    default      => 0,
  );

Note that it's possible to declare multiple attributes at the same time,
as long as they share a spec.

  has [ 'foo', 'bar', 'baz' ] => (
    is           => rw,
    isa          => Int,
  );

Moose and Moo allow that too!

=item C<< has ATTRIBUTE => CODEREF >>

Shortcut for a lazy builder.

Example:

  has foo => sub { 0 };

Moose and Moo don't allow that.

=item C<< has ATTRIBUTE => TYPE >>

Shortcut for a read-only attribute with a type constraint.

Example:

  has foo => Int;

Moose and Moo don't allow that.

=item C<< has ATTRIBUTE >>

Shortcut for a read-only attribute with no special options.

Example:

  has "foo";

Moose and Moo don't allow that.

=item C<< extends PARENTS >>

Set up inheritance for your class. Multiple inheritance is fine.
Version numbers can be included.

Example:

  extends "Local::BaseClass 1.0", "Local::SomeOtherClass";

Moose's syntax for including version numbers is slightly different.
Moo doesn't allow version numbers to be included in the list.

=item C<< with ROLES >>

Compose roles into your class.

Example:

  with "Local::MyTrait 1.0", "Local::YourTrait";

Marlin doesn't allow you to alias or exclude methods like Moose does.
Moose's syntax for including version numbers is slightly different.
Moo doesn't allow version numbers to be included in the list.

=item C<< before METHODNAME => CODEREF >>

Installs a "before" method modifier.

See L<Class::Method::Modifiers>.

=item C<< after METHODNAME => CODEREF >>

Installs an "after" method modifier.

See L<Class::Method::Modifiers>.

=item C<< around METHODNAME => CODEREF >>

Installs an "around" method modifier.

See L<Class::Method::Modifiers>.

=item C<< fresh METHODNAME => CODEREF >>

Defines a method but complains if you're overwriting an inherited method.

See L<Class::Method::Modifiers>.

Moose and Moo don't provide this keyword.

=item C<< signature_for FUNCTION => ( SPEC ) >>

=item C<< signature( SPEC ) >>

Marlin::Antlers exports slightly modified versions of C<signature> and
C<signature_for> from L<Type::Params>. The main user-visible difference
is that they default to C<< method => true >>, as they are intended for
use in object-oriented packages.

  package Local::Calculator {
    use Marlin::Antlers;
    
    signature_for add_nums => (
      positional => [ Int, Int ],
    );
    
    sub add_nums ( $self, $first, $second ) {
      return $first + $second;
    }
  }
  
  my $calc = Local::Calculator->new;
  say $calc->add_nums( 40, 2 );  # 42

=item C<< __FINALIZE__ >>

You can call this function at the end of your class to finalize it.
Think of it like Moose's C<< __PACKAGE__->meta->make_immutable >>.

However, Marlin::Antlers will automatically run it at the end of the
lexical scope, so it is very rare you'd need to do it manually. (The
only reason would be if you're defining several classes in the same
file and don't want to wrap them in C<< {...} >>.)

=back

=head2 Import Options

You can customize your class using the following options:

  use Marlin::Antlers {
    sloppy      => 1,
    constructor => 'create',
    x           => [ ':Clone' ],
  };

The C<sloppy> option turns off the strict constructor feature which is
otherwise on by default. The C<constructor> option allows you to name
your class's constructor something other than "new". (A good use of
that is to call it "_new" if you need to provide a wrapper for it.)

The C<x> option is used to load Marlin extensions. Each item on the
array is an extension to load and can optionally be followed by a hashref
of options to pass to the extension.

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-marlin-antlers/issues>.

=head1 SEE ALSO

L<Marlin::Role::Antlers>.

L<Marlin>, L<Moose>, L<Moo>.

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

