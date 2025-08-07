use strict;
use warnings;
use Test::More qw(no_plan);
use Test::Exception;
use File::Spec;
use File::Basename;
use Nice::Try;
use lib 'lib';

use aliased 'Javonet::Javonet' => 'Javonet', qw(in_memory tcp);

my $this_file_path = dirname(__FILE__);
my $test_file_path = "${this_file_path}/../../../../testResources/perl-package/TestClass.pm";
my $class_name = 'TestClass::TestClass';

sub Test_Perl_StandardLibrary_InvokeStaticMethod_CORE_Abs_minus11_11 {
    my $perl_type = Javonet->in_memory()->perl()->get_type('CORE')->execute();
    my $response = $perl_type->invoke_static_method('abs', -11)->execute();
    my $result = $response->get_value();
    is($result, 11, "Test_Perl_StandardLibrary_InvokeStaticMethod_CORE_Abs_minus11_11");
}

sub Test_Perl_TestResources_LoadLibrary_LibraryPath_NoException {
    Javonet->in_memory()->perl()->load_library($test_file_path);
    is(0, 0, "Test_Perl_TestResources_LoadLibrary_LibraryPath_NoException");
}

sub Test_Perl_TestResources_InvokeStaticMethod_MultiplyByTwo_25_50 {
    Javonet->in_memory()->perl()->load_library($test_file_path);
    my $perl_type = Javonet->in_memory()->perl()->get_type($class_name)->execute();
    my $response = $perl_type->invoke_static_method('multiply_by_two', 25)->execute();
    my $result = $response->get_value();
    is($result, 50, "Test_Perl_TestResources_InvokeStaticMethod_MultiplyByTwo_25_50");
}

sub Test_Perl_TestResources_GetStaticField_StaticValue_3 {
    Javonet->in_memory()->perl()->load_library($test_file_path);
    my $perl_type = Javonet->in_memory()->perl()->get_type($class_name)->execute();
    my $response = $perl_type->get_static_field('static_value')->execute();
    my $result = $response->get_value();
    is($result, 3, "Test_Perl_TestResources_GetStaticField_StaticValue_3");
}

sub Test_Perl_TestResources_SetStaticField_StaticValue_75 {
    Javonet->in_memory()->perl()->load_library($test_file_path);
    my $perl_type = Javonet->in_memory()->perl()->get_type($class_name)->execute();
    $perl_type->set_static_field('static_value', 75)->execute();
    my $response = $perl_type->get_static_field('static_value')->execute();
    $perl_type->set_static_field('static_value', 3)->execute();
    my $result = $response->get_value();
    is($result, 75, "Test_Perl_TestResources_SetStaticField_StaticValue_75");
}

sub Test_Perl_TestResources_InvokeInstanceMethod_MultiplyTwoNumbers_2_25_50 {
    Javonet->in_memory()->perl()->load_library($test_file_path);
    my $perl_type = Javonet->in_memory()->perl()->get_type($class_name)->execute();
    my $instance = $perl_type->create_instance()->execute();
    my $response = $instance->invoke_instance_method("multiply_two_numbers", 2, 25)->execute();
    my $result = $response->get_value();
    is($result, 50, "Test_Perl_TestResources_InvokeInstanceMethod_MultiplyTwoNumbers_2_25_50");
}

sub Test_Perl_TestResources_GetInstanceField_PublicValue_1 {
    Javonet->in_memory()->perl()->load_library($test_file_path);
    my $perl_type = Javonet->in_memory()->perl()->get_type($class_name)->execute();
    my $instance = $perl_type->create_instance()->execute();
    my $response = $instance->get_instance_field("public_value")->execute();
    my $result = $response->get_value();
    is($result, 1, "Test_Perl_TestResources_GetInstanceField_PublicValue_1");
}

sub Test_Perl_TestResources_SetInstanceField_PublicValue_44 {
    Javonet->in_memory()->perl()->load_library($test_file_path);
    my $perl_type = Javonet->in_memory()->perl()->get_type($class_name)->execute();
    my $instance = $perl_type->create_instance()->execute();
    $instance->set_instance_field("public_value", 44)->execute();
    my $response = $instance->get_instance_field("public_value")->execute();
    my $result = $response->get_value();
    is($result, 44, "Test_Perl_TestResources_SetInstanceField_PublicValue_44");
}

sub Test_Perl_TestResources_1DArray_GetIndex_2_StringThree {
    Javonet->in_memory()->perl()->load_library($test_file_path);
    my $perl_type = Javonet->in_memory()->perl()->get_type($class_name)->execute();
    my $instance = $perl_type->create_instance()->execute();
    my $array_reference = $instance->invoke_instance_method("get_1d_array")->execute();
    my $response = $array_reference->get_index(2)->execute();
    my $result = $response->get_value();
    is($result, "three", "Test_Perl_TestResources_1DArray_GetIndex_2_StringThree");
}

sub Test_Perl_TestResources_1DArray_GetSize_5 {
    Javonet->in_memory()->perl()->load_library($test_file_path);
    my $perl_type = Javonet->in_memory()->perl()->get_type($class_name)->execute();
    my $instance = $perl_type->create_instance()->execute();
    my $array_reference = $instance->invoke_instance_method("get_1d_array")->execute();
    my $array_size = $array_reference->get_size()->execute();
    my $result = $array_size->get_value();
    is($result, 5, "Test_Perl_TestResources_1DArray_GetSize_5");
}

sub Test_Perl_TestResources_1DArray_SetIndex_4_StringSeven {
    Javonet->in_memory()->perl()->load_library($test_file_path);
    my $perl_type = Javonet->in_memory()->perl()->get_type($class_name)->execute();
    my $instance = $perl_type->create_instance()->execute();
    my $array_reference = $instance->invoke_instance_method("get_1d_array")->execute();
    my $response = $array_reference->get_index(4)->execute()->get_value();
    $response = $array_reference->get_index(4)->execute()->get_value();
    $array_reference->set_index(4, "seven")->execute()->get_value();
    $response = $array_reference->get_index(4)->execute();
    $array_reference->set_index(4, "five")->execute();
    my $result = $response->get_value();
    is($result, "seven", "Test_Perl_TestResources_1DArray_SetIndex_4_StringSeven");
}

sub Test_Perl_TestResources_Exceptions_InvokeStaticMethod_DivideBy_0_ThrowsException {
    Javonet->in_memory()->perl()->load_library($test_file_path);
    my $perl_type = Javonet->in_memory()->perl()->get_type($class_name)->execute();
    my $exception = "";
    try {
        $perl_type->invoke_static_method('divide_by', 10, 0)->execute()
    }
    catch ($ex) {
        $exception = $ex;
    }
    finally {
        if ($exception eq "") {
            die "Exception not thrown";
        }
    }
        like($exception, qr/Illegal division by zero/, "Test_Perl_TestResources_Exceptions_InvokeStaticMethod_DivideBy_0_ThrowsException");
}

sub Test_Perl_TestResources_PassingNull_AsOnlyArg {
    my $called_runtime = Javonet->in_memory()->perl();
    $called_runtime->load_library($test_file_path);
    my $type_instance = $called_runtime->get_type($class_name)->execute();
    my $response = $type_instance->invoke_static_method("pass_null", undef)->execute();
    my $result = $response->get_value();
    is($result, "Method called with null", "Test_Perl_TestResources_PassingNull_AsOnlyArg");
}

sub Test_Perl_TestResources_PassingNull_AsSecondArg {
    my $called_runtime = Javonet->in_memory()->perl();
    $called_runtime->load_library($test_file_path);
    my $type_instance = $called_runtime->get_type($class_name)->execute();
    my $response = $type_instance->invoke_static_method("pass_null_2", 5, undef)->execute();
    my $result = $response->get_value();
    is($result, "Method2 called with null", "Test_Perl_TestResources_PassingNull_AsSecondArg");
}

sub Test_Perl_TestResources_ReturningNull {
    my $called_runtime = Javonet->in_memory()->perl();
    $called_runtime->load_library($test_file_path);
    my $type_instance = $called_runtime->get_type($class_name)->execute();
    my $response = $type_instance->invoke_static_method("return_null")->execute();
    my $result = $response->get_value();
    is($result, undef, "Test_Perl_TestResources_ReturningNull");
}

sub Test_Perl_TestResources_InvokeGlobalFunction {
    my $called_runtime = Javonet->in_memory()->perl();
    $called_runtime->load_library($test_file_path);
    my $response = $called_runtime->invoke_global_function("TestClass::TestClass::welcome", "John")->execute();
    my $result = $response->get_value();
    is($result, "Hello John!", "Test_Perl_TestResources_InvokeFunction");
}

sub Test_Perl_TestResources_MethodWithDefaultValues {
    my $called_runtime = Javonet->in_memory()->perl();
    $called_runtime->load_library($test_file_path);
    my $type_instance = $called_runtime->get_type($class_name)->execute();
    my $instance = $type_instance->create_instance()->execute();

    my $response = $instance->invoke_instance_method('method_with_default_values', 10)->execute();
    is($response->get_value(), 60, 'Test_Perl_TestResources_MethodWithDefaultValues');

    $response = $instance->invoke_instance_method('method_with_default_values', 10, 20)->execute();
    is($response->get_value(), 600, 'Test_Perl_TestResources_MethodWithDefaultValues');

    $response = $instance->invoke_instance_method('method_with_default_values', 10, 20, 30)->execute();
    is($response->get_value(), 6000, 'Test_Perl_TestResources_MethodWithDefaultValues');
}

sub Test_Perl_TestResources_VariableLengthArgs {
    my $called_runtime = Javonet->in_memory()->perl();
    $called_runtime->load_library($test_file_path);
    my $type_instance = $called_runtime->get_type($class_name)->execute();
    my $instance = $type_instance->create_instance()->execute();

    my $response = $instance->invoke_instance_method('method_with_variable_length_args', 1, 2, 3)->execute();
    is($response->get_value(), 6, 'Test_Perl_TestResources_VariableLengthArgs');

    $response = $instance->invoke_instance_method('method_with_variable_length_args', 4, 5, 6, 7)->execute();
    is($response->get_value(), 22, 'Test_Perl_TestResources_VariableLengthArgs');

    $response = $instance->invoke_instance_method('method_with_variable_length_args')->execute();
    is($response->get_value(), 0, 'Test_Perl_TestResources_VariableLengthArgs');
}

sub Test_Perl_TestResources_VariableLengthArgsAndMultiply {
    my $called_runtime = Javonet->in_memory()->perl();
    $called_runtime->load_library($test_file_path);
    my $type_instance = $called_runtime->get_type($class_name)->execute();
    my $instance = $type_instance->create_instance(0, 1)->execute();

    my $response = $instance->invoke_instance_method('method_with_variable_length_args_and_multiply', 2, 1, 2, 3)->execute();
    is($response->get_value(), 12, 'Test_Perl_TestResources_VariableLengthArgsAndMultiply');

    $response = $instance->invoke_instance_method('method_with_variable_length_args_and_multiply', 3, 4, 5)->execute();
    is($response->get_value(), 27, 'Test_Perl_TestResources_VariableLengthArgsAndMultiply');

    $response = $instance->invoke_instance_method('method_with_variable_length_args_and_multiply', 10)->execute();
    is($response->get_value(), 0, 'Test_Perl_TestResources_VariableLengthArgsAndMultiply');
}

Test_Perl_StandardLibrary_InvokeStaticMethod_CORE_Abs_minus11_11();
Test_Perl_TestResources_LoadLibrary_LibraryPath_NoException();
Test_Perl_TestResources_InvokeStaticMethod_MultiplyByTwo_25_50();
Test_Perl_TestResources_GetStaticField_StaticValue_3();
Test_Perl_TestResources_SetStaticField_StaticValue_75();
Test_Perl_TestResources_InvokeInstanceMethod_MultiplyTwoNumbers_2_25_50();
Test_Perl_TestResources_GetInstanceField_PublicValue_1();
Test_Perl_TestResources_SetInstanceField_PublicValue_44();
Test_Perl_TestResources_1DArray_GetIndex_2_StringThree();
Test_Perl_TestResources_1DArray_GetSize_5();
Test_Perl_TestResources_1DArray_SetIndex_4_StringSeven();
Test_Perl_TestResources_Exceptions_InvokeStaticMethod_DivideBy_0_ThrowsException();
Test_Perl_TestResources_PassingNull_AsOnlyArg();
Test_Perl_TestResources_PassingNull_AsSecondArg();
Test_Perl_TestResources_ReturningNull();
Test_Perl_TestResources_InvokeGlobalFunction();
Test_Perl_TestResources_MethodWithDefaultValues();
Test_Perl_TestResources_VariableLengthArgs();
Test_Perl_TestResources_VariableLengthArgsAndMultiply();


done_testing();
