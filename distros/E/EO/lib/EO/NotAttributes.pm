package EO::NotAttributes;

# this isn't an EO object, but it needs the EO::Error::* stuff
# declared in there.
use EO;

use strict;
use warnings;

use Scalar::Util qw(blessed);

our $VERSION = 0.96;

=begin notused

At some point we should implement Private.  We haven't yet.

sub UNIVERSAL::Private : ATTR(CODE) {
  my ($package, $symbol, $referent, $attr, $data) = @_;
  no strict 'refs';
  no warnings 'redefine';
  my $thing = *{$symbol};
  my $meth  = substr($thing, rindex($thing,':')+1);
  *{$symbol} = sub {
    my $self = shift;
    my $class = ref($self);
    my ($callpkg, $callfile, $callline) = caller();
    if ($package ne $callpkg) {
      my $text = "Can't private method \"$meth\" from package $package";
      throw EO::Error::Method::Private
	text => $text,
	  file => $callfile;
    }
    $referent->( $self, @_ );
  };
}

=end notused

=cut

sub sub::Abstract($) {
  my $meth = shift;
  my ($package, $filename, $line) = caller;
  no strict 'refs';
  no warnings 'redefine';
  *{"${package}::${meth}"} = sub {
    my $self = shift;
    my $class = blessed($self) ? ref($self) : $self;
    my ($package, $filename, $line) = caller();
    my $text = "Can't call abstract method \"$meth\" on object of type \"$class\"";
    throw EO::Error::Method::Abstract
      text => $text,
      file => $filename;
  };
}

sub sub::abstract($) { sub::Abstract(@_) }

1;

__END__

=head1 NAME

EO::NotAttributes - alternatives to attributes used by EO

=head1 SYNOPSIS

  use EO::NotAttributes;

  sub::Abstract 'bar';

=head1 DESCRIPTION

Attributes are nice, but they can't be used in all situations.
At the time of writing, perl (5.8.3) cannot apply attributes to
code that is loaded at run time.

This module provides an alternative interface instead of using
attributes;  A declarative syntax that can be used to perform similar
actions to thier EO::Attribute counterparts.

=head1 AUTHOR

Mark Fowler <mark@twoshortplanks.com>

=head1 SEE ALSO

L<EO>, L<EO::Attributes>

=head1 COPYRIGHT

Copyright 2004 Fotango Ltd.  All Rights Reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 BUGS

There's no implementation of 'Private' yet.   This isn't a
problem yet ;-).

=cut

