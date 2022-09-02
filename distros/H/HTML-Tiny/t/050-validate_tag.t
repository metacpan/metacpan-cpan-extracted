use strict; use warnings;
use HTML::Tiny;
use Test::More tests => 4;

package My::HTML::Tiny;
use vars qw/@ISA/;
@ISA = qw/HTML::Tiny/;
use HTML::Tiny;

sub validate_tag {
  my $self = shift;
  my ( $closed, $name, $attr ) = @_;

  push @{ $self->{valid_args} }, [ $closed, $name, $attr ];
}

sub get_validation { shift->{valid_args} }

package main;

ok my $h = My::HTML::Tiny->new, 'Created OK';
isa_ok $h, 'HTML::Tiny';

is $h->tag( 'p', { class => 'small' }, 'a', { class => undef }, 'b' ),
 '<p class="small">a</p><p>b</p>', 'change attr OK';

my $got  = $h->get_validation;
my $want = [
  [ 0, 'p', { 'class' => 'small' } ],
  [ 0, 'p', { 'class' => undef } ]
];

is_deeply $got, $want, 'validation hook called OK';
