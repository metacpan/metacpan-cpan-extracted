package  Test::Hessian::V2::Serializer;

use strict;
use warnings;

use parent 'Test::Hessian::V2';

use Test::More;
use Test::Deep;
use Test::Exception;
use DateTime;
use URI;
use Hessian::Translator;
use Hessian::Serializer;
use Hessian::Translator::V2;
use SomeType;
use YAML;
use Data::Dumper;
use Hessian::Client;


sub t007_compose_serializer : Test(2) {    #{{{
    my $self = shift;
    my $client = $self->{client};
    Hessian::Serializer->meta()->apply($client);
    ok(
        $client->does('Hessian::Serializer'),
        "Serializer role has been composed."
    );

    can_ok( $client, qw/serialize_chunk/, );

}

sub t009_serialize_string : Test(1) {    #{{{
    my $self = shift;
    my $client = $self->{client};
    $client->serializer();
    my $hessian_string = $client->serialize_chunk("hello");
    like( $hessian_string, qr/S\x{00}\x{05}hello/, "Created Hessian string." );
}

sub t011_serialize_integer : Test(2) {    #{{{
    my $self = shift;
    my $client = $self->{client};
    $client->serializer();
    my $hessian_string = $client->serialize_chunk(-256);
    like( $hessian_string, qr/  \x{c7} \x{00} /x, "Processed integer." );

    $hessian_string = $client->serialize_chunk(-1);
    like( $hessian_string, qr/\x8f/, "Processed -1." );

}

sub t015_serialize_float : Test(1) {    #{{{
    my $self = shift;
    my $client = $self->{client};
    $client->serializer();
    my $hessian_string = $client->serialize_chunk(12.25);
    like(
        $hessian_string,
        qr/D\x40\x28\x80\x00\x00\x00\x00\x00/,
        "Processed 12.25"
    );
}

sub t017_serialize_array : Test(2) {    #{{{
    my $self = shift;
    my $client = $self->{client};
    $client->serializer();
    my $datastructure = [ 0, 'foobar' ];
    my $hessian_data = $client->serialize_chunk($datastructure);
    like( $hessian_data, qr/\x57\x90S\x00\x06foobarZ/,
        "Interpreted a perl array." );
    $client->input_string($hessian_data);
    my $processed_datastructure = $client->deserialize_message();
    cmp_deeply( $processed_datastructure, $datastructure,
        "Mapped a simple array back to itself." );

}

sub t020_serialize_hash_map : Test(2) {    #{{{
    my $self = shift;
    my $client = $self->{client};
    $client->serializer();
    my $datastructure = { 1 => 'fee', 16 => 'fie', 256 => 'foe' };

    my $hessian_data = $client->serialize_chunk($datastructure);
    like( $hessian_data, qr/S\x00\x03fee/, "Found proper string key." );
    $client->input_string($hessian_data);
    my $processed_datastructure = $client->deserialize_data();
    cmp_deeply( $datastructure, $processed_datastructure,
        "Mapped a simple hash back to itself." );
}

sub t021_serialize_mixed : Test(1) {    #{{{
    my $self = shift;
    my $client = $self->{client};
    $client->serializer();
    my $datastructure = [
        qw/hello goodbye/,
        {
            1     => 'fee',
            2     => 'fie',
            three => 3
        }
    ];
    my $hessianized = $client->serialize_chunk($datastructure);
    $client->input_string($hessianized);
    my $processed = $client->deserialize_message();
    cmp_deeply( $processed, $datastructure,
        "Matched a complex datastructure to itself." );
}

sub t022_serialize_object : Test(1) {    #{{{
    my $self     = shift;
    my $some_obj = SomeType->new(
        color   => 'aquamarine',
        model   => 'Beetle',
        mileage => 65536
    );
    my $client = $self->{client};
    my $hessian_output = $client->serialize_chunk($some_obj);

#    my ($hessian_obj) = $hessian_output =~ /(O.*)/s;
    my $hessian_obj = $hessian_output;

    # Re-parse hessian to create object:
    $client->input_string($hessian_obj);
    my $processed_obj = $client->deserialize_message();
    cmp_deeply( $processed_obj, $some_obj, "Processed object as expected." );
}

sub t023_serialize_date : Test(2) {    #{{{
    my $self = shift;
    my $client = $self->{client};
    $client->serializer();
    my $date = DateTime->new(
        year      => 1998,
        month     => 5,
        day       => 8,
        hour      => 9,
        minute    => 51,
        time_zone => 'UTC'
    );
    my $hessian_date = $client->serialize_chunk($date);
    $client->input_string($hessian_date);
    my $processed_time = $client->deserialize_message();
    $self->compare_date( $date, $processed_time );
    my $hessian_compact_date = "\x4b\x00\xe3\x83\x8f";
    $client->input_string($hessian_compact_date);
    my $processed_compact_time = $client->deserialize_message();
    $self->compare_date( $date, $processed_compact_time );
}

sub t025_serialize_call : Test(3) {    #{{{
    my $self = shift;
    my $client = $self->{client};
    can_ok( $client, 'serialize_message' );
    my $datastructure = {
        call => {
            method    => 'add2',
            arguments => [ 2, 3 ]
        },
    };
    my $hessian_data = $client->serialize_message($datastructure);
    like(
        $hessian_data,
        qr/H\x02\x00CS\x00\x04add2\x92\x92\x93/,
        "Received expected string for hessian call."
    );
    $client->input_string($hessian_data);
    my $processed_data = $client->process_message();
    cmp_deeply(
        $processed_data->{call},
        $datastructure->{call},
        "Received same structure as call."
    );
}

sub t027_serialize_enveloped_message : Test(2) {    #{{{
    my $self = shift;
    my $client = $self->{client};
    my $datastructure = {
        envelope => {
            packet =>
              { call => { method => 'hello', arguments => ['hello, world'] } },
            meta    => [],
            headers => [],
            footers => []

        }
    };
    my $hessian_data;
    lives_ok {
        $hessian_data = $client->serialize_message($datastructure);

    }
    "No problem serializing envelope.";
    $client->input_string($hessian_data);
    my $data   = $client->process_message();
    my $packet = $data->{envelope}->{packet};
    if ($packet) {
        cmp_deeply(
       $packet,
       $datastructure->{envelope}->{packet},
       "Deserialized call back to itself."
        );
    }


}

"one, but we're not the same";

__END__


=head1 NAME

Communication::v2Serialization - Test serialization of Hessian version 2

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


