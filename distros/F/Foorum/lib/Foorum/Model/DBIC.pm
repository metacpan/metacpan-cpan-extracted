package Foorum::Model::DBIC;

use strict;
our $VERSION = '1.001000';

use Catalyst::Model::DBIC::Schema;
use base qw/Catalyst::Model::DBIC::Schema/;

__PACKAGE__->config(
    schema_class => 'Foorum::Schema',
    ( Foorum->config->{debug_mode} ) ? ( traits => ['QueryLog'] ) : (),
    connect_info => [
        Foorum->config->{dsn},
        Foorum->config->{dsn_user},
        Foorum->config->{dsn_pwd},
        { AutoCommit => 1, RaiseError => 1, PrintError => 1 },
    ],
);

1;
__END__

=pod

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
