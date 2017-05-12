package Dist::Maker::Template::Any::Moose;
use utf8;
use Mouse;
use MouseX::StrictConstructor;

extends 'Dist::Maker::Template::Moose';
with    'Dist::Maker::Template';

sub distribution {
    return <<'DIST';
: cascade Moose

:# @@ Makefile.PL
: override mpl_requires -> {
requires 'Any::Moose'                => 0.13;
requires 'Mouse'                     => 0.70;
requires 'MouseX::StrictConstructor' => 0.02;
requires 'MouseX::NativeTraits'      => 0.02;
: }

:# @@ <: $dist.module :>.pm
: override module_header -> {
use Any::Moose;
use Any::Moose 'X::StrictConstructor';
: }

: override module_footer -> {
no Any::Moose;
__PACKAGE__->meta->make_immutable();
: }
:# t/000_load.t
: after load_t_testing_info -> {
: for ["Any::Moose", "Moose", "Mouse"] -> $m {
eval { require <: $m :> };
diag "<: $m :>/$<: $m :>::VERSION";
: } # end for
: } # end load_t_testing_info
DIST
}

no Mouse;
__PACKAGE__->meta->make_immutable();
__END__

=head1 NAME

Dist::Maker::Template::Any::Moose - Distribution template using Any::Moose

=cut
