package  Test::Hessian::V1::Serializer;

use strict;
use warnings;

use parent 'Test::Hessian::V1';

use YAML;
use Test::More;
use Test::Deep;
use Test::Exception;
use DateTime;
use DateTime::Format::Epoch;
use Hessian::Translator;
use Hessian::Serializer;
use Hessian::Translator::V1;
use Hessian::Client;
use SomeType;

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

    #    $client->service( URI->new('http://localhost:8080') );
    my $hessian_string = $client->serialize_chunk("hello");
    like( $hessian_string, qr/S\x{00}\x{05}hello/, "Created Hessian string." );
}

sub t011_serialize_integer : Test(2) {    #{{{
    my $self = shift;
    my $client = $self->{client};

    #    $client->service( URI->new('http://localhost:8080') );
    my $hessian_string = $client->serialize_chunk(-256);
    like( $hessian_string, qr/  \x{c7} \x{00} /x, "Processed integer." );

    $hessian_string = $client->serialize_chunk(-1);
    like( $hessian_string, qr/\x8f/, "Processed -1." );

}

sub t015_serialize_float : Test(1) {    #{{{
    my $self = shift;
    my $client = $self->{client};

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
    my $datastructure = [ 0, 'foobar' ];
    my $hessian_data = $client->serialize_chunk($datastructure);
    like( $hessian_data, qr/V\x90S\x00\x06foobarz/,
        "Interpreted a perl array." );
    $client->input_string($hessian_data);
    my $processed_datastructure = $client->deserialize_message();
    cmp_deeply( $datastructure, $processed_datastructure,
        "Mapped a simple array back to itself." );

}

sub t020_serialize_hash_map : Test(2) {    #{{{
    my $self = shift;
    my $client = $self->{client};
    my $datastructure = { 1 => 'fee', 16 => 'fie', 256 => 'foe' };

    my $hessian_data = $client->serialize_chunk($datastructure);
    like( $hessian_data, qr/S\x00\x03fee/, "Found proper string key." );
    $client->input_string($hessian_data);
    my $processed_datastructure = $client->deserialize_message();
    cmp_deeply( $datastructure, $processed_datastructure,
        "Mapped a simple hash back to itself." );
}

sub t021_serialize_object : Test(1) {    #{{{
    my $self     = shift;
    my $some_obj = SomeType->new(
        color   => 'aquamarine',
        model   => 'Beetle',
        mileage => 65536
    );
    my $client = $self->{client};
    my $hessian_output = $client->serialize_chunk($some_obj);
    # Re-parse hessian to create object:
    $client->input_string($hessian_output);
    my $processed_obj      = $client->deserialize_message();
    my $hessian_serialized = "\x4dt\x00\x08SomeType\x05color\x0aaquamarine"
      . "\x05model\x06Beetle\x07mileageI\x00\x01\x00\x00z";
    $client->input_string($hessian_serialized);
    my $processed_data = $client->deserialize_message();
    cmp_deeply( $processed_obj, $processed_data, "Compared datastructures." );
}

sub t022_serialize_mixed : Test(1) {    #{{{
    my $self = shift;
    my $client = $self->{client};
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
        second    => 31,
        time_zone => 'UTC'
    );
    my $hessian_date = $client->serialize_chunk($date);
    like( $hessian_date, qr/d\x00\x00\x00\xd0\x4b\x92\x84\xb8/,
        "Processed a hessian date." );
    $client->input_string($hessian_date);
    my $processed_time = $client->deserialize_message();
    $self->compare_date( $date, $processed_time );

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
        qr/c\x01\x00m\x00\x04add2\x92\x93z/,
        "Received expected string for hessian call."
    );
    $client->input_string($hessian_data);
    my $processed_data = $client->deserialize_message();
    cmp_deeply(
        $processed_data->{call},
        $datastructure->{call},
        "Received same structure as call."
    );
}

sub t030_client_request : Test(3) {    #{{{
    my $self    = shift;
    my $service = 'http://localhost:8080/HessianRIADemo/words';
    local $TODO =
      "This test requires a running the HessianRIADemo" . " servlet.";
    my ( $reply_header, $reply_body );
    lives_ok {
        my $hessian_client = Hessian::Client->new(
            {
                version => 1,
                service => $service
            }
        );
        my $result = $hessian_client->getRecent();
        $reply_header = $result->[0];
        $reply_body   = $result->[1];
    }
    "No exception thrown by rpc.";
    cmp_deeply(
        $reply_header,
        { hessian_version => '1.0', state => 'reply' },
        "Received expected header from service."
    );
    isa_ok( $reply_body, 'ARRAY', 'Datastructure returned in response body' );

}

sub t032_fail_client_request : Test(1) {    #{{{
    my $self = shift;
    local $TODO =
      "This test requires a running the HessianRIADemo" . " servlet.";
    my $service        = 'http://localhost:8080/HessianRIADemo/words';
    my $hessian_client = Hessian::Client->new(
        {
            version => 1,
            service => $service
        }
    );
    my $result;
    eval { $result = $hessian_client->bogusMethod(); };
    if ( my $e = $@ ) {
        isa_ok( $e, 'NoSuchMethodException',
            "Received expected exception from servlet." );
    }

}

"one, but we're not the same";

__END__


=head1 NAME

Communication::v1Serialization - Test serialization of Hessian version 1
messages.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


