#package ETLp::Role::Browser;

use MooseX::Declare;
=head1 NAME

ETLp::Role::Browser - utility methods for the audir owser

=head1 DESCRIPTION

This role provides a attributes and methods for the audit browser -
specifically the models

=head1 ATTRIBUTES

=head2 pagesize

The number of elements to put on a page. Defaults to 10

=head1 METHODS

=head2 get_status_list

Returns a list of all possible statuses as a DBIx::Class resultset

=cut
role ETLp::Role::Browser {
    has 'pagesize'  => (is => 'rw', isa => 'Int', required => 0, default => 10);
    
    method get_status_list {
        return $self->EtlpStatus()->search(undef, {order_by => 'status_name'});
    }    
}