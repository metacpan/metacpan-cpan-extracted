package MetaStore;

=head1 NAME

MetaStore - Set of classes for multiuser web applications. 

=head1 SYNOPSIS

    use MetaStore;

=head1 DESCRIPTION

MetaStore - Set of classes for multiuser web applications.

=head1 METHODS

=cut

use Collection;
use Collection::Utl::Base;
use Data::Dumper;

use Data::UUID;
use strict;
use warnings;

our @ISA = qw(Collection);
our $VERSION = '0.62';

attributes qw/ props meta links _sub_ref/;

sub _init {
    my $self = shift;
    my %args = @_;
    props $self $args{props};
    meta $self $args{meta};
    links $self $args{links};
    $self->_sub_ref($args{sub_ref}) if ref $args{sub_ref};
    return 1
}

sub sub_ref {
    my $self = shift;
    if ( my $val = shift ) {
        $self->_sub_ref($val)
     }
    return $self->_sub_ref()
}

sub _fetch {
    my $self = shift;
    my $props_hash_ref = $self->props->fetch(@_);
    my @ids = keys %$props_hash_ref;
    my $meta_ref = $self->meta;
    my $links_ref = $self->links;
    my $meta_hash_ref = { map { $_=>$meta_ref->get_lazy_object($_) } @ids};
    my $links_hash_ref = { map { $_=>$links_ref->get_lazy_object($_) } @ids};
    my %res;
    foreach my $id ( @ids ) {
        $res{$id}= { 
            props=>$props_hash_ref->{$id},
            meta=>$meta_hash_ref->{$id},
            links=>$links_hash_ref->{$id},
            }
    }
    return \%res;
}

sub _prepare_record {
    my ( $self, $key, $ref ) = @_;
    if ( ref($self->_sub_ref) eq 'CODE') {
        return $self->_sub_ref()->($key,$ref)
    } esle {
        LOG $self "Not defined sub_ref"
    }
    return $ref;
}

sub _delete {
    my $self = shift;
    if ( my $ref = $self->fetch(@_) ){ 
        $_->delete  for values %{ $ref };
    }
    $self->props->delete(@_) ;
    $self->meta->delete(@_) ;

}
sub create_obj {
  my $self = shift;
  my ($id,$props) = @_;
  return unless my $class = $props->{__class};
  my $meta_ref = $self->meta->get_lazy_object($id);
  my $code = qq! new $class\:\: \$props,\$id,\$meta_ref; !;
  my $ret = eval $code;
  die ref($self)." die !".$@ if $@;
  return $ret;
}

sub fetch_by_guid {
    my $self = shift;
    my $guid = shift;
    my ( $res ) = values %{ $self->fetch({ 'tval'=>$guid}) };
    return $res;
}

sub create_object {
    my $self = shift;
    my %arg = @_;
    my $class = $arg{class};
    my ($meta_obj_id) = keys %{ $self->meta->create(mdata=>'') };
    $self->props->create($meta_obj_id=>{__class=>$class});
    my $dummy = $self->fetch_one($meta_obj_id);
    $dummy->_attr->{guid} = $arg{guid}||$self->make_uuid;
    return $self->fetch_one($meta_obj_id);
}

sub _fetch_all {
    my $self = shift;
    return $self->fetch( @{ $self->_fetch_all_ids })
}
sub _fetch_all_ids {
    my $self = shift;
    my $all = $self->meta->_fetch_all;
    $all = [ keys %{$all} ] if ref($all) eq 'HASH';
    return $all
}
sub create_item {
    my $self = shift;
    my %arg = @_;
    my $class = $arg{class};
    my ($meta_obj_id) = keys %{ $self->meta->create(mdata=>'') };
    my ( $dummy ) = values %{ $self->props->create($meta_obj_id,$class) || {}};
    return $dummy;
}

sub commit {
    my $self = shift;
    map {
        $_->store_changed;
        $_->release_objects;
        }
     ( $self->props, $self->meta, $self->links) 
}
 
sub make_uuid {
    my $self = shift;
    my $ug =  new Data::UUID::;
    return $ug->to_string( $ug->create() )
}

1;
__END__


=head1 SEE ALSO

WebDAO, README

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2008 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

