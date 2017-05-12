package Test::Hessian::V2::Deserializer;

use strict;
use warnings;

use parent 'Test::Hessian::V2';

use Test::More;
use Test::Deep;
use Test::Exception;
use YAML;
use Hessian::Translator;
use Hessian::Serializer;
use Config;
#use Smart::Comments;

sub t004_initialize_hessian_obj : Test(4) {    #{{{
    my $self = shift;
    my $hessian_obj = Hessian::Translator->new( version => 2 );
    ok(
        !$hessian_obj->does('Hessian::Deserializer'),
        "Have not yet composed the Deserialization logic."
    );
    my $hessian_data = "V\x04[int\x92\x90\x91";
    $hessian_obj->input_string($hessian_data);

    ok(
        $hessian_obj->does('Hessian::Deserializer'),
        "Have composed the Deserialization logic."
    );
    ok( $hessian_obj->does('Hessian::Translator::V2'),
        "Composed version 2 methods." );
    ok(
        !$hessian_obj->does('Hessian::Translator::V1'),
        "Do not have methods for hessian version 1"
    );

}

sub t008_initialize_hession_obj : Test(2) {    #{{{
    my $self        = shift;
    my $hessian_obj = Hessian::Translator->new(
        input_string => "V\x04[int\x92\x90\x91",
        version      => 2
    );
    ok(
        $hessian_obj->does('Hessian::Deserializer'),
        "Deserializer has been composed."
    );
    ok(
        $hessian_obj->does('Hessian::Translator::V2'),
        "Hessian version 2 methods have been composed."
    );

}

sub t010_read_fixed_length_typed : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "V\x04[int\x92\x90\x91";
    my $hessian_obj  = $self->{client};
    $hessian_obj->input_string($hessian_data);
    my $datastructure = $hessian_obj->deserialize_data();
    cmp_deeply( $datastructure, [ 0, 1 ], "Received expected datastructure." );
}

sub t011_read_variable_length_typed : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "\x55\x04[int\x90\x91\xd7\xff\xffZ";
    $self->{client}->input_string($hessian_data);
    my $datastructure = $self->{client}->deserialize_data();
    cmp_deeply(
        $datastructure,
        [ 0, 1, 262143 ],
        "Received expected datastructure."
    );
}

sub t012_read_fixed_length_type : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "\x73\x04[int\x90\x91\xd7\xff\xff";
    $self->{client}->input_string($hessian_data);
    my $datastructure = $self->{client}->deserialize_data();
    cmp_deeply(
        $datastructure,
        [ 0, 1, 262143 ],
        "Received expected datastructure."
    );
}

sub t013_read_variable_length_untyped : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "\x57\x90\x91D\x40\x28\x80\x00\x00\x00\x00\x00\xd7"
      . "\xff\xff\x52\x00\x07hello, T\x05worldZ";
    $self->{client}->input_string($hessian_data);
    my $datastructure = $self->{client}->deserialize_data();
    cmp_deeply(
        $datastructure,
        [ 0, 1, 12.25, 262143, 'hello, ', 1, 'world' ],
        "Received expected datastructure."
    );
}

sub t014_read_fixed_length_untyped : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "X\x98\x011\x012\x013\x014\x015\x016\x017\x018";
    $self->{client}->input_string($hessian_data);
    my $datastructure = $self->{client}->deserialize_data();
    cmp_deeply(
        $datastructure,
        [ 1, 2, 3, 4, 5, 6, 7, 8 ],
        "Received expected untyped list of length 8."
    );
}

sub t020_read_typed_map : Test(3) {    #{{{
    my $self         = shift;
    my $hessian_data = "\x4d\x08SomeType\x05color\x0aaquamarine"
      . "\x05model\x06Beetle\x07mileageI\x00\x01\x00\x00Z";
    $self->{client}->input_string($hessian_data);
    my $datastructure = $self->{client}->deserialize_data();

    isa_ok( $datastructure, 'SomeType',
        'Data structure returned by deserializer' );
    is( $datastructure->{model},
        'Beetle', 'Model attribute has correct value.' );
    like( $datastructure->{mileage},
        qr/\d+/, 'Mileage attribute is an integer.' );
}

sub t023_read_untyped_map : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "\x48\x91\x05hello\x04word\x06BeetleZ";
    $self->{client}->input_string($hessian_data);

    my $datastructure = $self->{client}->deserialize_data();
    cmp_deeply(
        $datastructure,
        { 1 => 'hello', word => 'Beetle' },
        "Correctly interpreted datastructure."
    );
}

sub t030_read_class_definition : Test(2) {    #{{{
    my $self         = shift;
    my $hessian_data = "C\x0bexample.Car\x92\x05color\x05model";
    $self->{client}->input_string($hessian_data);
    my $datastructure = $self->{client}->deserialize_data();

    # This will need to be linked to the class definition reference list
    # somehow
    push @{ $self->{class_ref} }, $datastructure;

    $hessian_data = "C\x0bexample.Cap\x93\x03row\x04your\x04boat";
    $datastructure =
      $self->{client}->deserialize_data( { input_string => $hessian_data } );
    push @{ $self->{class_ref} }, $datastructure;
    pass("Token test that only passes.");
    pass("Token test that only passes.");
}

sub t031_basic_object : Test(3) {    #{{{
    my $self          = shift;
    my $hessian_data1 = "\x60\x03RED\x06ferari";
    my $example_car   = $self->class_instance_generator($hessian_data1);

    is( $example_car->model(), 'ferari', "Correct car from referenced class." );
    is( $example_car->color(), 'RED',    "Car has the correct color." );

    my $hessian_data2 = "\x61\x05dingy\x06thingy\x05wingy";
    my $example_cap   = $self->class_instance_generator($hessian_data2);

    is( $example_cap->boat(), 'wingy', "Boat is correct." );

}

sub t032_object_long_form : Test(2) {    #{{{
    my $self          = shift;
    my $hessian_data1 = "O\x90\x05green\x05civic";
    my $example_car   = $self->class_instance_generator($hessian_data1);

    is( $example_car->model(), 'civic', "Correct car from referenced class." );
    is( $example_car->color(), 'green', "Correct color from class." );
}

sub t033_retrieve_object_from_reference : Test(2) {    #{{{
    my $self       = shift;
    my $last_index = scalar @{ $self->{client}->reference_list() } - 1;
    Hessian::Serializer->meta()->apply( $self->{client} );
    my $hessian_integer = $self->{client}->serialize_chunk($last_index);

    my $hessian_data = "\x51" . $hessian_integer;
    $self->{client}->input_string($hessian_data);
    my $example_car = $self->{client}->deserialize_data();
    is( $example_car->model(), 'civic', "Correct car from referenced object." );
    is( $example_car->color(), 'green', "Correct color from class." );
}

sub t050_test_int_m0x80000000 : Test(1) {    #{{{
    my $self = shift;

    my $hessian_data = "I\x80\x00\x00\x00";
    $self->{client}->input_string($hessian_data);
    my $byte_order    = $Config{byteorder};
    my $datastructure = $self->{client}->deserialize_data();
    is( $datastructure, -0x80000000,
        "Parsed correct int. Byteorder = $byte_order" )
      or $self->FAIL_ALL(
        "Unable to process integer." . "  Byteorder = $byte_order" );
}

sub t055_test_double_3_14159 : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "D\x40\x09\x21\xf9\xf0\x1b\x86\x6e";
    $self->{client}->input_string($hessian_data);
    my $datastructure = $self->{client}->deserialize_data();
    is( $datastructure, 3.14159, "Parsed correct double." );
}

sub t060_test_double_65_536 : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "\x5f\x00\x01\x00\x00";
    $self->{client}->input_string($hessian_data);
    my $datastructure = $self->{client}->deserialize_data();

    is( $datastructure, 65.536, 'Correct value for 32 bit double' );

}

sub t065_test_double_m32768_0 : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "\x5e\x80\x00";
    $self->{client}->input_string($hessian_data);
    my $datastructure = $self->{client}->deserialize_data();
    is( $datastructure, -32768.0, "Parsed correct double." );
}

sub t070_test_double_0_001 : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "\x5f\x00\x00\x00\x01";
    $self->{client}->input_string($hessian_data);
    my $datastructure = $self->{client}->deserialize_data();
    is( $datastructure, 0.001, 'Correct value for 32 bit double' );
}

sub t075_test_long_mOx80000000 : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "\x59\x80\x00\x00\x00";
    $self->{client}->input_string($hessian_data);
    my $datastructure = $self->{client}->deserialize_data();
    is( $datastructure, -0x80000000, "Parsed 32 bit long." );
}

sub t080_test_long_64_bit_0x80000000 : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "L\x00\x00\x00\x00\x80\x00\x00\x00";
    $self->{client}->input_string($hessian_data);
    my $datastructure = $self->{client}->deserialize_data();
    is( $datastructure, 0x80000000, "Parsed correct long." );
}

sub t085_test_long_64_bit_m0x80000000 : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "L\xff\xff\xff\xff\x7f\xff\xff\xff";
    $self->{client}->input_string($hessian_data);
    my $datastructure = $self->{client}->deserialize_data();
    is( $datastructure, -0x80000001, "Parsed correct long." );
}

sub class_instance_generator {    #{{{
    my ( $self, $object_definition ) = @_;
    $self->{client}->input_string($object_definition);
    return $self->{client}->deserialize_data();
}

"one, but we're not the same";

__END__


=head1 NAME

Datataype::Composite - Test various recursive datatypes into their components.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


