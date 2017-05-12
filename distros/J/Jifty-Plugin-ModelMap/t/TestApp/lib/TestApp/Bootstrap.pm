package TestApp::Bootstrap;
use base 'Jifty::Bootstrap';

use strict;
use warnings;

sub run {
    my $user = TestApp::CurrentUser->new( _bootstrap => 1);

    {
        my $supplier_class = TestApp::Model::Supplier->new(current_user => $user);
        my @items = (
            [qw/1 Smith 20 London/],
            [qw/2 Jones 10 Paris/],
            [qw/3 Black 30 Paris/],
            [qw/4 Clark 20 London/],
            [qw/5 Adams 30 Athens/],
        );
        $supplier_class->create( id => $_->[0], supplier_name => $_->[1], status => $_->[2], city => $_->[3]) for @items;
    }

    {
        my $supplier_class = TestApp::Model::Part->new(current_user => $user);
        my @items = (
            [qw/1 Nut     Red     12/],
            [qw/2 Bolt    Green   17/],
            [qw/3 Screw   Blue    17/],
            [qw/4 Screw   Red     14/],
            [qw/5 Cam     Blue    12/],
            [qw/6 Cog     Red     19/],
        );
        $supplier_class->create( id => $_->[0], part_name => $_->[1], color => $_->[2], weight => $_->[3]) for @items;
    }

    {
        my $link_class = TestApp::Model::PartSupplierLink->new(current_user => $user);
        my @items = (
            [qw/1 1 300/],
            [qw/1 2 200/],
            [qw/1 3 400/],
            [qw/1 4 200/],
            [qw/1 5 100/],
            [qw/1 6 100/],
            [qw/2 1 300/],
            [qw/2 2 400/],
            [qw/3 2 200/],
            [qw/4 2 200/],
            [qw/4 4 300/],
            [qw/4 5 400/],
        );
        $link_class->create( supplier => $_->[0], part => $_->[1], qty => $_->[2] ) for @items;
    }
}; 

1;
