package ExtUtils::Typemaps::Excommunicated;

use strict;
use warnings;
use ExtUtils::Typemaps;

our $VERSION = '0.01';
our @ISA = qw(ExtUtils::Typemaps);

=head1 NAME

ExtUtils::Typemaps::Excommunicated - Typemaps that have been removed from the core

=head1 SYNOPSIS

To use one or more of the typemaps from this module in a CPAN
distribution, add a built-time dependency on this module, and
include the following line in your XS code:

  INCLUDE_COMMAND: $^X -MExtUtils::Typemaps::Cmd \
                   -e "print embeddable_typemap(q{Excommunicated})"

=head1 DESCRIPTION

C<ExtUtils::Typemaps::Excommunicated> is an C<ExtUtils::Typemaps>
subclass that provides typemaps that have been booted from the perl
core. They might have been removed from the core for various reasons,
but we're really honest, it's really because their addition points back
at perl 5.0 and nobody knows what the hell they were intended for.

Right now, this means the following typemaps:

  T_DATAUNIT (OUTPUT only)
  
  T_CALLBACK

=cut

sub new {
  my $class = shift;

  my $self = $class->SUPER::new(@_);
  $self->add_string(string => <<'END_OF_TYPEMAP');
INPUT
T_CALLBACK
        $var = make_perl_cb_$type($arg)

OUTPUT

T_DATAUNIT	
	sv_setpvn($arg, $var.chp(), $var.size());

T_CALLBACK
        sv_setpvn($arg, $var.context.value().chp(),
                        $var.context.value().size());
END_OF_TYPEMAP

  return $self;
}

1;

__END__

=head1 SEE ALSO

L<ExtUtils::Typemaps>, L<ExtUtils::Typemaps::Default>

L<ExtUtils::ParseXS>

=head1 AUTHOR

Steffen Mueller <smueller@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2012 by Steffen Mueller

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
