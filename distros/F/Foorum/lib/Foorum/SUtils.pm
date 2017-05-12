package Foorum::SUtils;

use strict;
use warnings;

our $VERSION = '1.001000';

use Foorum::Schema;    # schema
use base qw/Exporter/;
use vars qw/@EXPORT_OK $schema/;
@EXPORT_OK = qw/
    schema
    /;
use Foorum::XUtils qw/config/;

sub schema {

    return $schema if ($schema);
    my $config = config();

    $schema
        = Foorum::Schema->connect( $config->{dsn}, $config->{dsn_user},
        $config->{dsn_pwd},
        { AutoCommit => 1, RaiseError => 1, PrintError => 1 },
        );
    return $schema;
}

1;
__END__

=pod

=head1 NAME

Foorum::SUtils - Foorum::Schema for pl

=head1 FUNCTIONS

=over 4

=item schema

the same as $c->model('DBIC')

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
