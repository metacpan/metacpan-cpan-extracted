package Lexical::Types;

use 5.008_004;

use strict;
use warnings;

=head1 NAME

Lexical::Types - Extend the semantics of typed lexicals.

=head1 VERSION

Version 0.16

=cut

our $VERSION;
BEGIN {
 $VERSION = '0.16';
}

=head1 SYNOPSIS

    { package Str; }

    {
     package My::Types::Str;

     sub new { bless { }, shift }
    }

    use Lexical::Types as => sub { 'My::Types::' . $_[0] => 'new' };

    my Str $x; # $x is now a My::Types::Str object

    {
     package My::Types::Int;

     sub TYPEDSCALAR { bless { }, shift }
    }

    use Lexical::Types;

    use constant Int => 'My::Types::Int';

    my Int $y; # $y is now a My::Types::Int object

=head1 DESCRIPTION

This pragma allows you to hook the execution of typed lexicals declarations (C<my Str $x>) by calling a configurable method in a configurable package at each run.
In particular, it can be used to automatically tie or bless typed lexicals whenever they are initialized.

Remind that for C<perl> to be able to parse C<my Str $x>, you need :

=over 4

=item *

either the C<Str> package to be defined ;

=item *

or for C<Str> to be a constant sub returning a valid defined package.

=back

so make sure you follow one of those two strategies to define your types.

This pragma is B<not> implemented with a source filter.

=cut

BEGIN {
 require XSLoader;
 XSLoader::load(__PACKAGE__, $VERSION);
}

=head1 METHODS

=head2 C<import>

    use Lexical::Types;
    use Lexical::Types as => $prefix;
    use Lexical::Types as => sub { ... }; # = $mangler

Magically called when C<use Lexical::Types> is encountered.
All the occurences of C<my Str $x> in the current lexical scope will be changed to call at each run a given method in a given package.
The method and package are determined by the parameter C<'as'> :

=over 4

=item *

If it's left unspecified, the C<TYPEDSCALAR> method in the C<Str> package will be called.

    use Lexical::Types;
    my Str $x; # calls Str->TYPEDSCALAR

=item *

If a plain scalar C<$prefix> is passed as the value, the C<TYPEDSCALAR> method in the C<${prefix}::Str> package will be used.

    use Lexical::Types as => 'My::'; # or "as => 'My'"
    my Str $x; # calls My::Str->TYPEDSCALAR

=item *

If the value given is a code reference C<$mangler>, it will be called at compile-time with arguments C<'Str'> and C<'TYPEDSCALAR'> and is expected to return :

=over 4

=item *

either an empty list, in which case the current typed lexical definition will be skipped (thus it won't be altered to trigger a run-time hook) ;

    use Lexical::Types as => sub {
     return $_[0] =~ /Str/ ? @_ : ()
    };
    my Str $y; # calls Str->TYPEDSCALAR
    my Int $x; # nothing special

=item *

or the desired package and method name, in that order (if any of those is C<undef>, the default value will be used instead).

    use Lexical::Types as => sub { 'My', 'new_' . lc($_[0]) };
    my Str $x; # the coderef indicates to call My->new_str

=back

Note that if the type is a constant, C<$_[0]> will be set to the I<value> of constant and not to its name.

    use Lexical::Types as => sub { $_[0] => 'new' };
    use constant Str => 'MyStr';
    my Str $x; # calls MyStr->new

This means in particular that you can't both use constant types and redirect several types to different methods of the same package, because then you can't distinguish between the original types with C<$_[0]>.

=back

=cut

sub import {
 shift;
 my %args = @_;

 my $hint;

 my $as = delete $args{'as'};
 if ($as) {
  my $r = ref $as;
  if ($r eq 'CODE') {
   $hint = _tag($as);
  } elsif (!$r) {
   $as .= '::' if $as !~ /::$/;
   $hint = _tag(sub { $as . $_[0] });
  } else {
   require Carp;
   Carp::croak("Invalid $r reference for 'as'");
  }
 } else {
  $hint = _tag(sub { @_ });
 }

 $^H |= 0x020000;
 $^H{+(__PACKAGE__)} = $hint;

 return;
}

=head2 C<unimport>

    no Lexical::Types;

Magically called when C<no Lexical::Types> is encountered.
Turns the pragma off.

=cut

sub unimport {
 $^H |= 0x020000;
 $^H{+(__PACKAGE__)} = undef;

 return;
}

=head1 RUN-TIME INITIALIZER METHOD

The initializer method receives an alias to the pad slot of the initialized lexical in C<$_[1]> and the original type name in C<$_[2]>.
You can either edit C<$_[1]> in place, in which case you should return an empty list, or return a new scalar that will be copied into the pad slot.

    use Lexical::Types as => 'My';

    my Str $x;

    ...

    sub My::Str::TYPEDSCALAR {
     # $_[1] is an alias to $x, and $_[2] is 'Str'
     ...
    }

=head1 INTEGRATION

You can integrate L<Lexical::Types> in your module so that using it will provide types to your users without asking them to load either L<Lexical::Types> or the type classes manually.

    package MyTypes;

    BEGIN { require Lexical::Types; }

    sub import {
     eval 'package Str; package Int'; # The types you want to support
     Lexical::Types->import(
      as => sub { __PACKAGE__, 'new_' . lc($_[0]) }
     );
    }

    sub unimport {
     Lexical::Types->unimport;
    }

    sub new_str { ... }

    sub new_int { ... }

If you prefer to use constants rather than creating empty packages, you can replace the previous example with something like this :

    package MyTypes;

    BEGIN { require Lexical::Types; }

    sub import {
     my $pkg = caller;
     for (qw<Str Int>) {
      my $type = __PACKAGE__ . '::' . $_;
      no strict 'refs';
      no warnings 'redefine';
      *{$pkg.'::'.$_} = eval "sub () { '$type' }";
     }
     Lexical::Types->import(
      as => sub { $_[0] => 'new' }
     );
    }

    sub unimport {
     Lexical::Types->unimport;
    }

    package MyTypes::Str;

    sub new { ... }

    package MyTypes::Int;

    sub new { ... }

=head1 CONSTANTS

=head2 C<LT_THREADSAFE>

True iff the module could have been built with thread-safety features enabled.

=head2 C<LT_FORKSAFE>

True iff this module could have been built with fork-safety features enabled.
This will always be true except on Windows where it's false for perl 5.10.0 and below .

=head1 CAVEATS

Using this pragma will cause a slight global slowdown of any subsequent compilation phase that happens anywere in your code - even outside of the scope of use of C<use Lexical::Types> - which may become noticeable if you rely heavily on numerous calls to C<eval STRING>.

The restrictions on the type (being either a defined package name or a constant) apply even if you use the C<'as'> option to redirect to another package, and are unlikely to find a workaround as this happens deep inside the lexer - far from the reach of an extension.

Only one mangler or prefix can be in use at the same time in a given scope.

Typed lexicals declarations that appear in code C<eval>'d during the global destruction phase of a spawned thread or pseudo-fork (the processes used internally for the C<fork> emulation on Windows) are ignored.

The implementation was tweaked to work around several limitations of vanilla C<perl> pragmas : it's thread safe, and doesn't suffer from a C<perl 5.8.x-5.10.0> bug that causes all pragmas to propagate into C<require>d scopes.

With 5.8 perls, the pragma does not propagate into C<eval STRING>.
This is due to a shortcoming in the way perl handles the hints hash, which is addressed in perl 5.10.

=head1 DEPENDENCIES

L<perl> 5.8.4.

A C compiler.
This module may happen to build with a C++ compiler as well, but don't rely on it, as no guarantee is made in this regard.

L<XSLoader> (standard since perl 5.6.0).

=head1 SEE ALSO

L<fields>.

L<Attribute::Handlers>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-lexical-types at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lexical-Types>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lexical::Types

=head1 ACKNOWLEDGEMENTS

Inspired by Ricardo Signes.

Thanks Florian Ragwitz for suggesting the use of constants for types.

=head1 COPYRIGHT & LICENSE

Copyright 2009,2010,2011,2012,2013,2014,2015,2017 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of Lexical::Types
