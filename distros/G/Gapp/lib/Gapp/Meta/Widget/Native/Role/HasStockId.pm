package Gapp::Meta::Widget::Native::Role::HasStockId;
{
  $Gapp::Meta::Widget::Native::Role::HasStockId::VERSION = '0.60';
}

use Moose::Role;
use MooseX::SemiAffordanceAccessor;

has 'stock_id' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

1;



__END__

=pod

=head1 NAME

Gapp::Meta::Widget::Native::Role::HasStockId - stock_id attribute for widgets

=head1 SYNOPSIS

    Gapp::Button->new( stock_id => 'gtk-ok' );
    
=head1 PROVIDED ATTRIBUTES

=over 4

=item B<stock_id>

=over 4

=item is rw

=item isa Str|Undef

=back

The stock-id to apply to the widget. 

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut