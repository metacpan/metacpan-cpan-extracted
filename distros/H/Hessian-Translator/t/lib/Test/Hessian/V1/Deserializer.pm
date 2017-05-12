package  Test::Hessian::V1::Deserializer;

use strict;
use warnings;

use parent 'Test::Hessian::V1';

use Test::More;
use Test::Deep;
use YAML;
use Hessian::Translator;
#use Smart::Comments;

sub t007_initialize_hessian_obj : Test(4) {    #{{{
    my $self = shift;
    
    my $hessian_obj = $self->{client};
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
    ok( $hessian_obj->does('Hessian::Translator::V1'),
        "Composed version 1 methods." );
    ok(
        !$hessian_obj->does('Hessian::Translator::V2'),
        "Do not have methods for hessian version 2"
    );

}

sub t008_initialize_hessian_obj : Test(2) {    #{{{
    my $self        = shift;
    my $hessian_obj = Hessian::Translator->new(
        input_string => "Vt\x00\x04[int\x92\x90\x91",
        version      => 1
    );
    ok(
        $hessian_obj->does('Hessian::Deserializer'),
        "Deserializer has been composed."
    );
    ok(
        $hessian_obj->does('Hessian::Translator::V1'),
        "Hessian version 1 methods have been composed."
    );

}

sub t010_read_fixed_length_typed : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "Vt\x00\x04[intl\x00\x00\x00\x02\x90\x91z";
    my $hessian_obj  = $self->{client};
    $hessian_obj->input_string($hessian_data);
    my $datastructure = $hessian_obj->deserialize_data();
    cmp_deeply( $datastructure, [ 0, 1 ], "Received expected datastructure." );
}

sub t012_read_fixed_length_anonymous : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "Vl\x00\x00\x00\x02I\x00\x00\x00\x00I\x00\x00\x00\x01z";
    my $hessian_obj  = $self->{client};
    $hessian_obj->input_string($hessian_data);
    my $datastructure = $hessian_obj->deserialize_data();
    cmp_deeply( $datastructure, [ 0, 1 ], "Received expected datastructure." );
}

sub t013_read_type_reference_list_fixed_length : Test(1) {    #{{{
    my $self         = shift;
    return "Can't find reference to this in version 1.02 specs.";
    my $hessian_data = "v\x00\x02\x90\x91z";
    my $hessian_obj  = $self->{client};
    $hessian_obj->input_string($hessian_data);
    my $datastructure = $hessian_obj->deserialize_data();
    ### Got data: "\n".Dump($datastructure)."\n"
    cmp_deeply( $datastructure, [ 0, 1 ], "Received expected datastructure." );
}

sub t015_read_typed_map : Test(3) {    #{{{
    my $self         = shift;
    my $hessian_data = "\x4dt\x00\x08SomeType\x05color\x0aaquamarine" 
    . "\x05model\x06Beetle\x07mileageI\x00\x01\x00\x00z";
    my $hessian_obj = $self->{client};
    $hessian_obj->input_string($hessian_data);
    my $datastructure = $hessian_obj->deserialize_data();
    isa_ok( $datastructure, 'SomeType',
        'Data structure returned by deserializer' );
    is( $datastructure->{model},
        'Beetle', 'Model attribute has correct value.' );
    like( $datastructure->{mileage},
        qr/\d+/, 'Mileage attribute is an integer.' );

}

sub t016_read_referenced_datastructure : Test(1) {    #{{{
    my $self         = shift;
    my $hessian_data = "Mt\x00\x0aLinkedListS\x00"
      . "\x04headI\x00\x00\x00\x01S\x00\x04tailR\x00\x00\x00\x04z";
    my $hessian_obj = $self->{client};
    $hessian_obj->input_string($hessian_data);
    my $datastructure = $hessian_obj->deserialize_data();

    my $reference_list = $hessian_obj->reference_list();
    isa_ok( $datastructure, 'LinkedList', "Object parsed by deserializer" );
}

sub t017_sparse_array_map : Test(2) {    #{{{
    my $self         = shift;
    my $hessian_data = "MI\x00\x00\x00\x01S\x00\x03fee"
      . "I\x00\x00\x00\x10S\x00\x03fieI\x00\x00\x01\x00S\x00\x03foez";
    my $hessian_obj = $self->{client};
    $hessian_obj->input_string($hessian_data);
    my $datastructure = $hessian_obj->deserialize_data();
    isa_ok( $datastructure, 'HASH', 'Datastructure returned by deserializer' );

    cmp_deeply(
        $datastructure,
        { 1 => 'fee', 16 => 'fie', 256 => 'foe' },
        "Received expected datastructure."
    );
}

sub t019_object_definition : Test(2) {    #{{{
    my $self         = shift;
    my $hessian_data = "O\x9bexample.Car\x92\x05color\x05model";
    my $hessian_obj  = $self->{client};
    $hessian_obj->input_string($hessian_data);
    $hessian_obj->deserialize_data();

    my $object_data = "o\x90\x05green\x05civic";
    my $object =
      $hessian_obj->deserialize_data( { input_string => $object_data } );
    is( $object->color(), 'green', 'Correctly accessed object color' );
    is( $object->model(), 'civic', 'Correclty accessed object model' );
}

sub t021_remote_object_reference : Test(2) {    #{{{
    my $self         = shift;
    my $hessian_data = "rt\x00\x0ctest.TestObjS\x00\x24"
      . "http://slytherin/ejbhome?id=69Xm8-zW";
    my $hessian_obj = $self->{client};
    $hessian_obj->input_string($hessian_data);
    my $datastructure = $hessian_obj->deserialize_data();

    can_ok( $datastructure, qw/remote_url/ ) 
        or $self->FAIL_ALL('Could not build object for test.TestObj');
    my $string = $datastructure->remote_url();
    is($string, "http://slytherin/ejbhome?id=69Xm8-zW");
}

"one, but we're not the same";

__END__


=head1 NAME

Datatype::v1Composite - Test composite parsing methods for Hessian version 1

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


