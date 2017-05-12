
use Test::More tests => 32;
use JSON::Streaming::Reader::TestUtil;

test_parse "Unclosed object", "{", [
    [ 'start_object' ],
    [ 'error', 'Unexpected end of input' ],
];

test_parse "Unclosed array", "[", [
    [ 'start_array' ],
    [ 'error', 'Unexpected end of input' ],
];

test_parse "Mismatched brackets starting with array", "[}", [
    [ 'start_array' ],
    [ 'error', 'End of object without matching start' ],
];

test_parse "Mismatched brackets starting with object", "{]", [
    [ 'start_object' ],
    [ 'error', 'Expected " but encountered ]' ],
];

test_parse "Junk at the end of the root value", "{}{}", [
    [ 'start_object' ],
    [ 'end_object' ],
    [ 'error', 'Unexpected junk at the end of input' ],
];

test_parse "Unterminated string", '"hello', [
    [ 'error', 'Unterminated string' ],
];

test_parse "Unknown escape sequence", '"hell\\o', [
    [ 'error', 'Invalid escape sequence \o' ],
];

test_parse "Unterminated true", 'tru', [
    [ 'error', 'Expected e but encountered EOF' ],
];

test_parse "Unterminated false", 'fals', [
    [ 'error', 'Expected e but encountered EOF' ],
];

test_parse "Mis-spelled false", 'flase', [
    [ 'error', 'Expected a but encountered l' ],
];

test_parse "Unterminated null", 'nul', [
    [ 'error', 'Expected l but encountered EOF' ],
];

test_parse "Unknown keyword", 'cheese', [
    [ 'error', 'Unexpected character c' ],
];

test_parse "Unterminated number", '1.', [
    [ 'error', 'Expected digits but got EOF' ],
];

test_parse "Number with only fraction", '.5', [
    [ 'error', 'Unexpected character .' ],
];

test_parse "Negative number with only fraction", '-.5', [
    [ 'error', 'Expected digits but got .' ],
];

test_parse "Number with two decimal points", '1.2.2', [
    [ 'add_number', 1.2 ],
    [ 'error', 'Unexpected junk at the end of input' ],
];

test_parse "Number with spaces in it", '1 2', [
    [ 'add_number', 1 ],
    [ 'error', 'Unexpected junk at the end of input' ],
];

test_parse "Number with spaces in it after decimal point", '1. 2', [
    [ 'error', 'Expected digits but got  ' ],
];

test_parse "Number with two signs", '--5', [
    [ 'error', 'Expected digits but got -' ],
];

test_parse "Number with positive sign", '+5', [
    [ 'error', 'Unexpected character +' ],
];

test_parse "Number with empty exponent", '5e', [
    [ 'error', 'Expected digits but got EOF' ],
];

test_parse "Number with exponent with sign but no digits", '5e-', [
    [ 'error', 'Expected digits but got EOF' ],
];

test_parse "Number with multiple exponents", '5e5e5', [
    [ 'add_number', 500000 ],
    [ 'error', 'Unexpected junk at the end of input' ],
];

test_parse "Property with no value and end of object", '{"property":}', [
    [ 'start_object' ],
    [ 'start_property', 'property' ],
    [ 'error', 'Property has no value' ],
];

test_parse "Property with no value with subsequent property", '{"property":,"another":true}', [
    [ 'start_object' ],
    [ 'start_property', 'property' ],
    [ 'error', 'Property has no value' ],
];

test_parse "Property with no value or colon and end of object", '{"property"}', [
    [ 'start_object' ],
    [ 'error', 'Expected : but encountered }' ],
];

test_parse "Property with no value or colon with subsequent property", '{"property","another":true}', [
    [ 'start_object' ],
    [ 'error', 'Expected : but encountered ,' ],
];

test_parse "Unterminated property name", '{"proper', [
    [ 'start_object' ],
    [ 'error', 'Unterminated string' ],
];

test_parse "Unquoted property name", '{property:true}', [
    [ 'start_object' ],
    [ 'error', 'Expected " but encountered p' ],
];

test_parse "Array containing a property", '["property":true]', [
    [ 'start_array' ],
    [ 'add_string', 'property' ],
    [ 'error', 'Unexpected character :' ],
];

test_parse "Array with two values missing comma", '[true false]', [
    [ 'start_array' ],
    [ 'add_boolean', 1 ],
    [ 'error', 'Expected ,' ],
];

test_parse "Object with two properties missing comma", '{"property1":true "property2":false}', [
    [ 'start_object' ],
    [ 'start_property', 'property1' ],
    [ 'add_boolean', 1 ],
    [ 'error', 'Unexpected string value' ],
];

