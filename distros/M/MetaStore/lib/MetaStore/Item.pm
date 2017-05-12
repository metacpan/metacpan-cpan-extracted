package MetaStore::Item;

=head1 NAME

MetaStore::Item - Base class for collections.

=head1 SYNOPSIS

    use MetaStore::Item;
    use base qw( MetaStore::Item );


=head1 DESCRIPTION

Base class for collections.

=head1 METHODS

=cut

use MetaStore::Base;
use Data::Dumper;
use strict;
use warnings;

our @ISA = qw( MetaStore::Base );
our $VERSION = '0.01';
use WebDAO;
__PACKAGE__->mk_attr( __init_rec=>undef, _attr=>undef);


sub _init {
    my $self = shift;
    my $ref = shift;
    $ref->{id} or die "Need id !".__PACKAGE__;
    _attr $self $ref->{attr};
    __init_rec $self $ref;
    return $self->SUPER::_init(@_);
}

#method fo init
sub _create {
    my $self = shift;
}

sub _changed {
   my $self = shift;
    if ( my $ar = tied %{ $self->_attr } ) {
        return $ar->_changed;
    }
    return 0;
}

sub _get_attr {
    my $self = shift;
    return $self->_attr;
}

=head2  dump 

Dump object state

=cut
sub dump {
 my $self = shift;
 return $self->attr
}

=head2 restore (<data ref>)

Restore state

=cut
sub restore {
    my $self= shift;
    if ( my $attr = shift ) {
        %{ $self->attr } =  %{$attr}
    }
}

=head2 attr

Get intem attributes

=cut

sub attr {
    return $_[0]->_attr
}

=head2 id 

Get id of object

=cut

sub id {
    my $self = shift;
    return $self->__init_rec->{id};
}



1;
__END__

=head1 SEE ALSO

MetaStore, Collection::Item, README

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zag@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2006 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

