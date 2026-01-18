use v5.20;
use experimental qw( signatures postderef lexical_subs );
use feature ();
use strict;
use warnings;

package Marlin::Role::Antlers;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002001';

use Exporter::Tiny ();
use Marlin::Antlers ();
use Role::Tiny ();
use Types::Common -lexical, -all;

our @ISA    = qw( Marlin::Antlers );
our @EXPORT = qw( has with requires before after around __FINALIZE__ );

sub import {
	my $me      = shift;
	my $globals = +{ @_ && ref($_[0]) eq q(HASH) ? %{+shift} : () };
	$globals->{__role} = 1;
	delete $globals->{constructor};
	delete $globals->{sloppy};
	unshift @_, $globals;
	unshift @_, $me;
	goto &Exporter::Tiny::import;
}

sub _generate_requires ( $me, $name, $value, $globals ) {
	return sub ( @methods ) {
		
		assert_Str $_ for @methods;
		
		$globals->{MARLIN}{requires} //= [];
		push $globals->{MARLIN}{requires}->@*, @methods;
	};
}

sub _for_cmm ( $me, $kind, $globals ) {
	return sub ( @names ) {
		
		my $coderef = pop @names;
		assert_CodeRef $coderef;
		
		push @{$Role::Tiny::INFO{$globals->{into}}{modifiers}||=[]}, [ $kind, @names, $coderef ];
	};
}

__PACKAGE__
__END__

=pod

=encoding utf-8

=head1 NAME

Marlin::Role::Antlers - a more Moose-like syntax for Marlin::Role

=head1 SYNOPSIS

  package Local::CoolerDump 2.0 {
    use Marlin::Role::Antlers;
    
    requires "dump";
    
    has emoji => sub { "✨" };
    
    around dump => sub ( $next_method, $self, @args ) {
      my $emoji = $self->emoji;
      my $dump  = $self->$next_method( @args );
      return $emoji . $dump . $emoji;
    };
  }
  
  package Local::CoolWidget 1.0 {
    use Marlin::Antlers;
    extends 'Local::Widget 1.0';
    with 'Local::CoolerDump 2.0';
  }
  
  my $w = Local::CoolWidget->new( name => 'Foo' );
  print $w->dump, "\n";

=head1 DESCRIPTION

Marlin::Role::Antlers provides L<Moose>-like C<has>, C<with>, etc keywords
for L<Marlin::Role>.

It also exports everything from L<Types::Common> and L<Marlin::Util>.
This will give you C<true>, C<false>, C<ro>, C<rw>, C<rwp>, etc for
free, plus a whole bunch of type constraints, C<signature_for>, etc.

Everything is exported lexically.

Marlin::Role::Antlers also enables L<strict> and L<warnings>, plus switches
on the following Perl features: signatures, postderef, lexical_subs,
current_sub, evalbytes, fc, say, state, unicode_eval, and unicode_strings.
It requires Perl 5.20, so you don't need to worry about whether modern
Perl syntax features like C<< // >> are supported.

Significant differences from Moose::Role and Moo::Role are noted below.

=head2 Keywords

=over

=item C<< requires METHODS >>

List methods that this role requires any classes that compose it to
provide.

=item C<< has ATTRIBUTE => ( SPEC ) >>

Much like Moose and Moo's C<has> keyword, but defaults to C<< is => 'ro' >>,
so you don't get repetitive strain injury typing that out each time.

Example:

  has foo => (
    is           => 'rw',
    isa          => Int,
    clearer      => true,
    predicate    => true,
    lazy         => true,
    default      => 0,
  );

Note that it's possible to declare multiple attributes at the same time,
as long as they share a spec.

  has [ 'foo', 'bar', 'baz' ] => (
    is           => 'rw',
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

=item C<< with ROLES >>

Compose other roles into your role.

Example:

  with "Local::MyTrait 1.0", "Local::YourTrait";

Marlin doesn't allow you to alias or exclude methods like Moose does.
Moose's syntax for including version numbers is slightly different.
Moo doesn't allow version numbers to be included in the list.

=item C<< before METHODNAME => CODEREF >>

Installs a "before" method modifier.

See L<Role::Tiny>.

=item C<< after METHODNAME => CODEREF >>

Installs an "after" method modifier.

See L<Role::Tiny>.

=item C<< around METHODNAME => CODEREF >>

Installs an "around" method modifier.

See L<Role::Tiny>.

=item C<< __FINALIZE__ >>

You can call this function at the end of your role to finalize it.
Think of it like Moose's C<< __PACKAGE__->meta->make_immutable >>.

However, Marlin::Role::Antlers will automatically run it at the end of the
lexical scope, so it is very rare you'd need to do it manually. (The
only reason would be if you're defining several roles in the same
file and don't want to wrap them in C<< {...} >>.)

=back

=head2 Import Options

You can customize your role using the following option:

  use Marlin::Role::Antlers { x => [ ':XYZ', \%xyz_opts ] };

The C<x> option is used to load Marlin extensions. Each item on the
array is an extension to load and can optionally be followed by a hashref
of options to pass to the extension.

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-marlin-antlers/issues>.

=head1 SEE ALSO

L<Marlin::Antlers>.

L<Marlin::Role>, L<Moose::Role>, L<Moo::Role>.

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

