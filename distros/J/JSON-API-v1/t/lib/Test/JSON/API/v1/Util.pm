package Test::JSON::API::v1::Util;
use warnings;
use strict;

use Exporter qw(import);
use Test::Deep qw(cmp_deeply);
use JSON::XS;

our @EXPORT = qw(
    cmp_object_json
);

{
our $json = JSON::XS->new->utf8(0)->convert_blessed();

    sub cmp_object_json {
        my ($object, $want, $msg) = @_;

        my $ds = $json->decode($json->encode($object));
        return cmp_deeply($ds, $want, $msg);
    }

}

1;

__END__

=head1 DESCRIPTION

=head1 SYNOPSIS

