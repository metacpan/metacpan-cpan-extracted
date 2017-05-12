package ETLp::Audit::Browser::Model::Item;

use MooseX::Declare;

class ETLp::Audit::Browser::Model::Item with
    (ETLp::Role::Config, ETLp::Role::Schema, ETLp::Role::Audit,
     ETLp::Role::Browser) {
        
    
    use Data::Dumper
    
    method get_items (Maybe[Int] :$page?, Maybe[Int] :$item_id?, Maybe[Int] :$job_id?, Maybe[Int] :$status_id?, Maybe[Str] :$item_name?, Maybe[Str] :$filename?) {
        my $criteria = {};
        my $attributes = {};
    
        $criteria->{job_id}    = $job_id    if ($job_id);
        $criteria->{item_id}   = $item_id   if ($item_id);
        $criteria->{status_id} = $status_id if $status_id;
        $criteria->{item_name} = $item_name if $item_name;
    
        if ($filename) {
            $criteria->{'etlp_file_process.filename'} = $filename;
            $attributes->{join} = 'etlp_file_process';
        }
    
        $attributes->{page}     = $page;
        $attributes->{rows}     = $self->pagesize;
        $attributes->{order_by} = 'date_updated desc, item_id desc';
    
        my $items = $self->EtlpItem()->search($criteria, $attributes);
        return $items;
    }
    
    method get_item_name_list(Maybe[Int] $job_id?) {        
        return $self->EtlpItem()->search(
            {
                job_id => $job_id
            },
            {
                select => {distinct => 'item_name'},
                as => 'item_name'
            }
        )
    }   
}
    
=head1 NAME

ETLp::Audit::Browser::Model::Item - Model Class for interacting
with Runtime Item Audit Records

=head1 SYNOPSIS

    use ETLp::Audit::Browser::Model::Item;
    
    my $model = ETLp::Audit::Browser::Model::Item->new();
    my $items = $model->get_items(page => 1);
    
=head1 METHODS

=head2 get_items

Returns a resultset on the ep_Item table. It will grab 20 rows at
a time, and is ordered by date_updated descending

=head3 Parameters
    
    * page. Integer. The page you to fetch. Defaults to one
    * item_id. Optional. The specific item to fetch
    * job_id. Optional. The job that created the item
    * status_id. Optional. Filter on item status
    * item_name. Optional. Fetch item with the supplied name
    * filename. Optional. Fetch items that processed the supplied file
    
=head3 Returns

    * A DBIx::Class resultset

=head2 get_item_name_list

Returns a list of all distinct item names for the supplied process id

=head3 Parameters

    * job_id. Integer
    
Returns

    * A DBIx:Class resultset containing a list of item names
    
=head1 LICENSE AND COPYRIGHT

Copyright 2010 Redbone Systems Ltd

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The terms are in the LICENSE file that accompanies this application

=cut