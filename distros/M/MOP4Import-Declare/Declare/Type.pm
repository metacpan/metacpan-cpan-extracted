package MOP4Import::Declare::Type;
use 5.010;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;

use MOP4Import::Declare -as_base, qw/Opts m4i_args m4i_opts/;
use MOP4Import::Pairs -as_base;
use MOP4Import::Util qw/symtab globref ensure_symbol_has_array/;

use constant DEBUG => $ENV{DEBUG_MOP4IMPORT};

sub default_exports {
  (my $myPack) = @_;
  my $symtab = symtab($myPack);
  my $exportSym = $symtab->{EXPORT}
    or return;
  my $exportArray = *{$exportSym}{ARRAY}
    or return;
  @$exportArray
}

sub declare_type {
  (my $myPack, my Opts $opts, my ($name, @spec)) = m4i_args(@_);

  if ($opts->{extending}) {
    my $sub = $opts->{destpkg}->can($name)
      or croak "Can't find base class $name in parents of $opts->{destpkg}";
    unshift @spec, [fileless_base => $sub->()];
  } elsif ($opts->{basepkg}) {
    unshift @spec, [fileless_base => $opts->{basepkg}];
  }

  $myPack->declare___inner_class_in($opts
				    , $opts->{destpkg}, $name, @spec);
}

sub declare_extends {
  (my $myPack, my Opts $opts, my ($baseClassName)) = m4i_args(@_);

  my $baseClass = do {
    if (my $sub = $opts->{destpkg}->can($baseClassName)) {
      $sub->()
    } elsif (MOP4Import::Util::maybe_fields_hash($baseClassName)) {
      $baseClassName
    } else {
      Carp::croak "Can't find base class $baseClassName in (parents of) $opts->{destpkg}";
    }
  };

  $myPack->declare_fileless_base($opts, $baseClass);
}

#
# Create a new class $extended, deriving from $callpack->SUPER::$extended,
# in $callpack.
#
sub declare_extend {
  (my $myPack, my Opts $opts, my ($extended, @spec)) = m4i_args(@_);

  my $sub = $opts->{destpkg}->can($extended)
    or croak "Can't find base class $extended in parents of $opts->{destpkg}";

  $myPack->declare___inner_class_in($opts
				    , $opts->{destpkg}, $extended
				    , [fileless_base => $sub->()]
				    , @spec);
}

sub declare___inner_class_in {
  (my $myPack, my Opts $opts, my ($destpkg, $name, @spec)) = m4i_args(@_);

  my $innerClass = join("::", $destpkg, $name);

  $myPack->declare_alias($opts, $name, $innerClass);

  if (@spec) {
    $myPack->dispatch_declare($opts->with_objpkg($innerClass)
			      , @spec);
  } else {
    # Note: To make sure %FIELDS is defined. Without this we get:
    #   No such class Foo at (eval 45) line 1, near "(my Foo"
    #
    $myPack->declare_fields($opts->with_objpkg($innerClass));
  }

  my $export = ensure_symbol_has_array(globref($destpkg, 'EXPORT'));
  unless (grep {$_ eq $name} @$export) {
    push @$export, $name;
    print STDERR " type $name is added to default exports of $destpkg\n" if DEBUG;
  }
}

sub declare_subtypes {
  (my $myPack, my Opts $opts, my @specs) = m4i_args(@_);

  $myPack->dispatch_pairs_as_declare(
    type => $opts->with_basepkg($opts->{objpkg}),
    @specs
  );
}

1;

=head1 NAME

MOP4Import::Declare::Type - inner-type related pragmas

=head1 SYNOPSIS

  package MyApp;
  use MOP4Import::Types
    BaseUser => [
      [fields => qw/sessid/],
      [subtypes =>
        Guest => [],
        RegisteredUser => [[fields => qw/uid registered_at/]],
     ]
    ],
    AdminUser => [
      [extends => 'RegisteredUser'],
      [fields => qw/impersonation/],
    ],
    ;

=head1 DESCRIPTION

This module implements inner-type related pragmas.
Usually used via L<MOP4Import::Types>.

=head1 PRAGMAS

=head2 [subtypes => ($typename => [@spec])...]
X<subtypes>

Declare multiple inner-types which are subtypes of currently-defining inner-type by C<< $typename => [@spec] >> pair list.

=head2 [extends => $typename]
X<extends>

Set superclass for currently-defining inner-type to C<< $typename >>.

=head2 (Internal) [type => $typename, @spec]
X<type>

Declare inner-type C<$typename> based on given C<@spec>.

=head2 (Not recommended) [extend => $typename, @spec]
X<extend>

Declare extended version of C<$typename>, which is inherited from parent class,
based on given C<@spec>.

=head1 AUTHOR

Kobayashi, Hiroaki E<lt>hkoba@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
