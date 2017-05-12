package Dist::Maker::Template::Moose;
use utf8;
use Mouse;
use MouseX::StrictConstructor;

extends 'Dist::Maker::Template::Default';
with    'Dist::Maker::Template';

sub distribution {
    return <<'DIST';
: cascade Default

:# @@ Makefile.PL
: override mpl_requires -> {
requires 'Moose'                     => 1.13;
requires 'MooseX::StrictConstructor' => 0.11;
: }

:# @@ <: $dist.module :>.pm
: override module_header -> {
use Moose;
use MooseX::StrictConstructor;
: }

: override module_code -> {
has foo => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);
: }

: override module_footer -> {
no Moose;
__PACKAGE__->meta->make_immutable();
: }

:# @@ t/000_load.t
: after load_t_testing_info -> {
eval { require Moose };
diag "Moose/$Moose::VERSION";
: }

:# @@ t/001_basic.t
: override basic_t_tests -> {
my $object = <: $dist.module :>->new(foo => 42);
isa_ok $object, '<: $dist.module :>';
: }
DIST
}

no Mouse;
__PACKAGE__->meta->make_immutable();
__END__

=head1 NAME

Dist::Maker::Template::Moose -  Distribution template using Moose

=cut
