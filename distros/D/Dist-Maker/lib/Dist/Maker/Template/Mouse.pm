package Dist::Maker::Template::Mouse;
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
requires 'Mouse'                     => 0.70;
requires 'MouseX::StrictConstructor' => 0.02;
requires 'MouseX::NativeTraits'      => 0.002;
: }

:# @@ <: $dist.module :>.pm
: override module_header -> {
use Mouse;
use MouseX::StrictConstructor;
: }

: override module_footer -> {
no Mouse;
__PACKAGE__->meta->make_immutable();
: }
:# t/000_load.t
: after load_t_testing_info -> {
eval { require Mouse };
diag "Mouse/$Mouse::VERSION";
: }
DIST

}

no Mouse;
__PACKAGE__->meta->make_immutable();
__END__

=head1 NAME

Dist::Maker::Template::Mouse - Distribution template using Mouse

=cut
