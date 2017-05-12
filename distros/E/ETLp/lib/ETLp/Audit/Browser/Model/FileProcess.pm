package ETLp::Audit::Browser::Model::FileProcess;

use MooseX::Declare;

class ETLp::Audit::Browser::Model::FileProcess with
    (ETLp::Role::Config, ETLp::Role::Schema, ETLp::Role::Audit,
     ETLp::Role::Browser) {
        
    method get_file_processes(Maybe[Int] :$page?, Maybe[Int] :$item_id?, Maybe[Int] :$file_id?) {
    
        my $criteria = {};
        $criteria->{item_id} = $item_id if ($item_id);
        $criteria->{file_id} = $file_id if ($file_id);
    
        my $processes = $self->EtlpFileProcess()->search(
            $criteria,
            {
                page     => $page,
                rows     => $self->pagesize,
                order_by => 'date_updated desc, file_proc_id desc'
            }
        );
        return $processes;
    }

    method get_canonical_file(Int $file_id) {
        return $self->EtlpFile()->find($file_id);
    }
}
    
=head1 NAME

ETLp::Audit::Browser::Model::FileProcess - Model Class for interacting
with Runtime FileProcess Audit Records

=head1 SYNOPSIS

    use ETLp::Audit::Browser::Model::FileProcess;
    
    my $model = ETLp::Audit::Browser::Model::FileProcess->new();
    my $processes = $model->get_file_processes(item_id => 1013);
    
=head1 METHODS

=head2 get_file_processes

Returns a resultset on the ep_process table. It will grab 20 rows at
a time, and is ordered by date_updated descending

=head3 Parameters
 
    * item_id. Optional. Filter by the parent item
    * file_id. Optional. Specific file processed
    * page. Integer. The page you wish to return. Defaults to 1
    
=head3 Returns

    * A DBIx::Class resultset
    
=head2 get_canonical_file

Given a file_id, return the canonical file record

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Redbone Systems Ltd

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The terms are in the LICENSE file that accompanies this application

=cut