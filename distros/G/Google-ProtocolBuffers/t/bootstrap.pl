use strict;
use warnings;
use Math::BigInt;

my @cases = (
 optional_int32    => [0, 1, -1, 2, 23424, 0x7fffffff, -0x80000000],
 optional_int64    => [0, 1, -1, Math::BigInt->new("234234234234"), Math::BigInt->new("0x7fffffffffffffff"), Math::BigInt->new("-0x8000000000000000")],
 optional_uint32   => [0, 1, 2, 2374234, 0xffffffff],
 optional_uint64   => [0, 1, 2, Math::BigInt->new("2336346474234"), Math::BigInt->new("0xffffffffffffffff")],
 optional_sint32   => [0, 1, -1, 2, 237374, -4858558, 0x7fffffff, -0x80000000],
 optional_sint64   => [0, 1, -1, 2, Math::BigInt->new("234234234234"), Math::BigInt->new("0x7fffffffffffffff"), Math::BigInt->new("-0x8000000000000000")],
 optional_fixed32  => [0, 1, 2, 1453468424, 0x7fffffff, 0xffffffff],
 optional_fixed64  => [0, 1, 2, Math::BigInt->new("234234234234"), Math::BigInt->new("0x7fffffffffffffff"), Math::BigInt->new("0xffffffffffffffff")],
 optional_sfixed32 => [0, 1, -1, 2, 1130468424, 0x7fffffff, -0x80000000],
 optional_sfixed64 => [0, 1, -1, 2, Math::BigInt->new("234234234234"), Math::BigInt->new("0x7fffffffffffffff"), Math::BigInt->new("-0x8000000000000000")],
 optional_float    => [0, 1, 0.5, -0.5, 1e10, -1e20, 1e-10, -2e-20],
 optional_double   => [0, 1, 0.5, -0.5, 1e10, -1e20, 1e-10, -2e-20, 1e-40, 1e+50],
 optional_bool     => [0, 1],
 optional_string   => ["", "\t", "\n", "\r", "Hello, world",],
 optional_bytes    => ["", "\0", "Hello, world", "\x{ff}\x{fe}\x{fd}"],
 OptionalGroup     => [ {a => 0}, {a => -1}, {a => 199}, ],
 optional_nested_message	=> [ {bb => 0}, {bb => 1}, {bb => -1}],
 optional_foreign_message	=> [ {c => 0}, {c=> -1}, {c=> 1}],
 optional_import_message	=> [ {d=>0}, {d=>-1}, {d=>1}],
 optional_nested_enum		=> [
                        {   
                            protoc  => 'optional_nested_enum: FOO',
                            encode  => '{optional_nested_enum => ProtobufUnittest::TestAllTypes::NestedEnum::FOO()}',
                            decode  => 'is($data->{optional_nested_enum}, ProtobufUnittest::TestAllTypes::NestedEnum::FOO(), "optional_nested_enum:FOO")',
                        },
                        {   
                            protoc  => 'optional_nested_enum: BAR',
                            encode  => '{optional_nested_enum => ProtobufUnittest::TestAllTypes::NestedEnum::BAR()}',
                            decode  => 'is($data->{optional_nested_enum}, ProtobufUnittest::TestAllTypes::NestedEnum::BAR(), "optional_nested_enum:BAR")',
                        },
                        {   
                            protoc  => 'optional_nested_enum: BAZ',
                            encode  => '{optional_nested_enum => ProtobufUnittest::TestAllTypes::NestedEnum::BAZ()}',
                            decode  => 'is($data->{optional_nested_enum}, ProtobufUnittest::TestAllTypes::NestedEnum::BAZ(), "optional_nested_enum:BAZ")',
                        },
                    ],
	optional_foreign_enum => [
                        {   
                            protoc  => 'optional_foreign_enum: FOREIGN_FOO',
                            encode  => '{optional_foreign_enum => ProtobufUnittest::ForeignEnum::FOREIGN_FOO()}',
                            decode  => 'is($data->{optional_foreign_enum}, ProtobufUnittest::ForeignEnum::FOREIGN_FOO(), "optional_foreign_enum:FOREIGN_FOO")',
                        },
                        {   
                            protoc  => 'optional_foreign_enum: FOREIGN_BAR',
                            encode  => '{optional_foreign_enum => ProtobufUnittest::ForeignEnum::FOREIGN_BAR()}',
                            decode  => 'is($data->{optional_foreign_enum}, ProtobufUnittest::ForeignEnum::FOREIGN_BAR(), "optional_foreign_enum:FOREIGN_BAR")',
                        },
                        {   
                            protoc  => 'optional_foreign_enum: FOREIGN_BAZ',
                            encode  => '{optional_foreign_enum => ProtobufUnittest::ForeignEnum::FOREIGN_BAZ()}',
                            decode  => 'is($data->{optional_foreign_enum}, ProtobufUnittest::ForeignEnum::FOREIGN_BAZ(), "optional_foreign_enum:FOREIGN_BAZ")',
                        },
					],
	optional_import_enum => [
                        {   
                            protoc  => 'optional_import_enum: IMPORT_FOO',
                            encode  => '{optional_import_enum => ProtobufUnittestImport::ImportEnum::IMPORT_FOO()}',
                            decode  => 'is($data->{optional_import_enum}, ProtobufUnittestImport::ImportEnum::IMPORT_FOO(), "optional_import_enum:IMPORT_FOO")',
                        },
                        {   
                            protoc  => 'optional_import_enum: IMPORT_BAR',
                            encode  => '{optional_import_enum => ProtobufUnittestImport::ImportEnum::IMPORT_BAR()}',
                            decode  => 'is($data->{optional_import_enum}, ProtobufUnittestImport::ImportEnum::IMPORT_BAR(), "optional_import_enum:IMPORT_BAR")',
                        },
                        {   
                            protoc  => 'optional_import_enum: IMPORT_BAZ',
                            encode  => '{optional_import_enum => ProtobufUnittestImport::ImportEnum::IMPORT_BAZ()}',
                            decode  => 'is($data->{optional_import_enum}, ProtobufUnittestImport::ImportEnum::IMPORT_BAZ(), "optional_import_enum:IMPORT_BAZ")',
                        },
					],
	optional_string_piece => ["", "Hello, world", "\r\t\n"],	
	optional_cord		=> ["", "Hello, world", "\r\t\n"],
	
	repeated_int32 => [ 
						## test that input field may be a single scalar value
						## after deserializing, it will be reference to one-element array
                        {   
                            protoc  => 'repeated_int32: 0',
                            encode  => '{repeated_int32 => 0}',
                            decode  => 'is_deeply($data->{repeated_int32}, [0], "repeated_int32:0")',
                        },
						[0], [0, -1, 1] 
					],
	repeated_int64		=> [ [0], [0, -1, 1] ],
	repeated_uint32		=> [ [0], [0, 2, 1] ],
	repeated_uint64		=> [ [0], [0, 2, 1] ],
	repeated_sint32		=> [ [0], [0, -1, 1] ],
	repeated_sint64		=> [ [0], [0, -1, 1] ],
	repeated_fixed32	=> [ [0], [0, 3, 1] ],
	repeated_fixed64	=> [ [0], [0, 3, 1] ],
	repeated_sfixed32	=> [ [0], [0, -1, 1] ],
	repeated_sfixed64   => [ [0], [0, -1, 1] ],
	repeated_float      => [ [0], [0, -0.5, 1e10] ],
	repeated_double		=> [ [0], [0, -0.5, 1e10] ],
	repeated_bool		=> [ [0], [0, 1, 1, 0] ],
	repeated_string		=> [ [""], ["hello"], ["hello","world" ] ],
	repeated_bytes		=> [ [""], ["\0"], ["", "\0", "\0\0" ] ],

	RepeatedGroup				=> [ [{a=>0}], [{a=>0}, {a=>-1}] ],
	repeated_nested_message		=> [ [{bb=>0}], [{bb=>1}, {bb=>2}] ],
	repeated_foreign_message	=> [ [{c=>0}],  [{c => 0}, {c=> -1}, {c=> 1}] ],
	repeated_import_message		=> [ [{d=>0}],  [{d => 0}, {d=> -1}, {d=> 1}] ], 

	repeated_nested_enum		=> [
                       {   
                            protoc  => 'repeated_nested_enum: FOO repeated_nested_enum: BAR',
                            encode  => '{repeated_nested_enum => [ProtobufUnittest::TestAllTypes::NestedEnum::FOO(), ProtobufUnittest::TestAllTypes::NestedEnum::BAR()]}',
                            decode  => 'is_deeply($data->{repeated_nested_enum}, [ProtobufUnittest::TestAllTypes::NestedEnum::FOO(), ProtobufUnittest::TestAllTypes::NestedEnum::BAR()], "repeated_nested_enum:[FOO, BAR]")',
                        },
	],
#  repeated ForeignEnum                          repeated_foreign_enum    = 52;
#  repeated protobuf_unittest_import.ImportEnum    repeated_import_enum     = 53;

	repeated_string_piece => [ [""], ["a"], ["a", "b", "\r\n"] ],
	repeated_cord => [ [""], ["a"], ["a", "b", "\r\n"] ],
);

my $number_of_tests = 0;
foreach my $i (0..(@cases/2-1)) {
    $number_of_tests += scalar @{ $cases[$i*2+1] };
}

open ENCODER, ">03-encoder.t";
open DECODER, ">04-decoder.t";

print ENCODER <<".";
use Test::More tests => $number_of_tests;
use strict;
use warnings;
use Google::ProtocolBuffers;
use Math::BigInt;

BEGIN{
	\$SIG{__DIE__} = \\&Carp::confess;
}

Google::ProtocolBuffers->parsefile(
    "google/protobuf/unittest.proto", 
    { include_dir => 't' }
);

my \$str;
.

print DECODER <<".";
use Test::More tests => $number_of_tests;
use strict;
use warnings;
use Google::ProtocolBuffers;
use Math::BigInt;

BEGIN{
	\$SIG{__DIE__} = \\&Carp::confess;
}

Google::ProtocolBuffers->parsefile(
    "google/protobuf/unittest.proto", 
    { include_dir => 't' }
);

my \$data;
.

while (my ($k, $ar) = splice(@cases, 0, 2) ) {
    print ENCODER "##\n## $k\n##\n";
    print DECODER "##\n## $k\n##\n";
    
    foreach my $v (@$ar) {
        
        ##
        ## Write a human-readable message into input file for Google's protoc
        ##
        open FILE, ">1";
        if (ref($v) && ref($v) eq 'HASH' && $v->{protoc}) {
            print FILE $v->{protoc};
        } elsif (ref($v) && ref($v) eq 'ARRAY') {
			foreach (@$v) {
				print FILE "$k: ", get_text_message_value($k, $_), " "; 
			}
        } else {
			print FILE "$k: ", get_text_message_value($k, $v); 
        }
        close FILE;

        ## 
        ## Run the compiler to encode message
        ##
        system("..\\..\\protoc.exe google/protobuf/unittest.proto --encode protobuf_unittest.TestAllTypes <1 >2") ==0 or die;

        ##
        ## Read the serialized data
        ##
        open FILE, 2;
        binmode FILE;
        local $/;
        my $data = <FILE>;
        close FILE;

        $data =~ s/(\W)/ '\\x{' . sprintf("%02x", ord($1)) . '}' /ge;

        ##
        ## Write scripts for encoder and decoder tests
        ##
        if (ref($v) && ref($v) eq 'HASH' && $v->{protoc}) {
            my $test_name;
            if ($v->{name}) {
                $test_name=$v->{name}; 
            } elsif ($v->{decode} =~ /"([^"]+)"\)$/) {
                $test_name = $1;
            } else {
                $test_name = '';
            }

            print ENCODER qq[\$str = ProtobufUnittest::TestAllTypes->encode($v->{encode});\n];
            print ENCODER qq[is(\$str, "$data", "$test_name");\n\n];

            print DECODER qq[\$data = ProtobufUnittest::TestAllTypes->decode("$data");\n];
            print DECODER qq[$v->{decode};\n\n];
        }
        else {
            my ($perl_literal, $need_deep_cmp) = get_perl_literal($v);
            my $test_name = qq[$k=$perl_literal];
            $test_name =~ s/([\x00-\x1f'"\\$@%\x80-\xff])/ '\\\\x{' . sprintf("%02x", ord($1)) . '}' /ge;
            
            print ENCODER qq[\$str = ProtobufUnittest::TestAllTypes->encode({$k => $perl_literal});\n];
            print ENCODER qq[is(\$str, "$data", "$test_name");\n\n];

            print DECODER qq[\$data = ProtobufUnittest::TestAllTypes->decode("$data");\n];
            if ($need_deep_cmp) {
				print DECODER qq[is_deeply(\$data->{$k}, $perl_literal, "$test_name");\n\n];
            } elsif ($k =~ /float|double/) {
                if ($perl_literal eq '0') {
                    print DECODER qq[cmp_ok(\$data->{$k}, '==', 0, "$test_name");\n\n];
                } else {
                    print DECODER qq[ok(abs(1-\$data->{$k}/($perl_literal))<0.0000001);\n\n];
                }
            } else {
                print DECODER qq[is(\$data->{$k}, $perl_literal, "$test_name");\n\n];
            }
        }
    }
}

sub get_text_message_value {
	my ($k, $v) = @_;
	
	if (ref($v) && ref($v) eq 'HASH') {
		return "{" . join(" ", map {"$_:" . get_text_message_value($k, $v->{$_}) } keys %$v) . "}";
	} elsif ($k =~ /bool/) {
		return ($v) ? 'true' : 'false';
	} elsif ($v =~ /^[\d\.e+-]+$/i) {
		return $v;
    } else {
		my $str = $v;
		$str =~ s/(\W)/ '\\x' . sprintf("%02x", ord($1)) /ge;
		return "'$str'";
    }
}

sub get_perl_literal {
	my $v = shift;
	
	if (ref($v) && ref($v) eq "ARRAY") {
		return ("[" . join(", ", map {(get_perl_literal($_))[0]} @$v ) . "]", 1);
	} elsif (ref($v) && ref($v) eq "HASH") {
		return ("{" . join(", ", map { "$_ => " . (get_perl_literal($v->{$_}))[0]} keys %$v) . "}", 1);
	} elsif (ref($v)) {
		return qq[Math::BigInt->new("$v")];
	} elsif ($v =~ /^[\d\.e+-]+$/i) {
		return  $v;
	} else {
		my $str = $v;            
		$str =~ s/(\W)/ '\\x{' . sprintf("%02x", ord($1)) . '}' /ge;
		return  qq["$str"];
	}
}
__END__






