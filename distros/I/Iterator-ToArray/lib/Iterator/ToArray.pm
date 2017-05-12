package Iterator::ToArray;

use 5.008_003;
use strict;
use warnings;
use base 'Exporter';
use Scalar::Util qw(blessed reftype);

our $VERSION   = '0.04';
our @EXPORT_OK = qw/to_array/;

sub new {
    my $class    = shift;
    my $iterator = _is_iterable(shift);
    $class = ref $class || $class;

    bless { iterator => $iterator }, $class;
}

sub apply {
    my $self     = shift;
    my $code     = _is_coderef(shift);
    my $iterator = $self->{iterator};
    my @tmp;
    while ( defined( my $r = $iterator->next() ) ) {
        local $_ = $r;
        push @tmp, $code->();
    }
    wantarray ? @tmp : \@tmp;
}

sub to_array($&) {
    my ( $iterator, $code ) = @_;
    __PACKAGE__->new($iterator)->apply($code);
}

sub _is_iterable {
    my $object = shift;
    if ( $object && blessed($object) && $object->can('next') ) {
        return $object;
    }
    else {
        die "not a iterable object. object must have next method";
    }
}

sub _is_coderef {
    my $code = shift;
    if ( $code && reftype $code eq 'CODE' ) {
        return $code;
    }
    else {
        die "apply takes one code reference only";
    }
}
1;
__END__

=head1 NAME

Iterator::ToArray - create array or arrayref from iterator

=head1 SYNOPSIS

  use Iterator::ToArray qw/to_array/;
  
  my $iterator = Your::Iterator->new();

  # OO style
  my $to_array = Iterator::ToArray->new($iterator);
  my $coderef  = sub { $_ * $_ };
  my $array = $to_array->apply($coderef);

  # function style
  my $array    = to_array $iter, sub { $_* $_ };

=head1 DESCRIPTION

Iterator::ToArray convert iterator to array using coderef.

=head1 AUTHOR

Yoshihiro Sasaki E<lt>ysasaki {at} cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
