use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'GCCJIT',
    VERSION_FROM      => 'lib/GCCJIT.pm',
    ABSTRACT_FROM     => 'lib/GCCJIT.pm',
    AUTHOR            => 'Vickenty Fesunov <cpan-gccjit@setattr.net>',
    LICENSE           => 'gpl_3',
    LIBS              => ['-lgccjit'],
    TEST_REQUIRES     => {
    	"FFI::Raw" => "0.30",
	"Test::Fatal" => 0,
    },
    META_MERGE => {
        "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type => "git",
                url => "https://github.com/vickenty/gccjit-perl",
                web => "https://github.com/vickenty/gccjit-perl",
            },
            bugtracker => {
                web => "https://github.com/vickenty/gccjit-perl/issues",
            },
        },
    },
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(),
              {name=>"GCC_JIT_BINARY_OP_BITWISE_AND", macro=>"1"},
              {name=>"GCC_JIT_BINARY_OP_BITWISE_OR", macro=>"1"},
              {name=>"GCC_JIT_BINARY_OP_BITWISE_XOR", macro=>"1"},
              {name=>"GCC_JIT_BINARY_OP_DIVIDE", macro=>"1"},
              {name=>"GCC_JIT_BINARY_OP_LOGICAL_AND", macro=>"1"},
              {name=>"GCC_JIT_BINARY_OP_LOGICAL_OR", macro=>"1"},
              {name=>"GCC_JIT_BINARY_OP_LSHIFT", macro=>"1"},
              {name=>"GCC_JIT_BINARY_OP_MINUS", macro=>"1"},
              {name=>"GCC_JIT_BINARY_OP_MODULO", macro=>"1"},
              {name=>"GCC_JIT_BINARY_OP_MULT", macro=>"1"},
              {name=>"GCC_JIT_BINARY_OP_PLUS", macro=>"1"},
              {name=>"GCC_JIT_BINARY_OP_RSHIFT", macro=>"1"},
              {name=>"GCC_JIT_BOOL_OPTION_DEBUGINFO", macro=>"1"},
              {name=>"GCC_JIT_BOOL_OPTION_DUMP_EVERYTHING", macro=>"1"},
              {name=>"GCC_JIT_BOOL_OPTION_DUMP_GENERATED_CODE", macro=>"1"},
              {name=>"GCC_JIT_BOOL_OPTION_DUMP_INITIAL_GIMPLE", macro=>"1"},
              {name=>"GCC_JIT_BOOL_OPTION_DUMP_INITIAL_TREE", macro=>"1"},
              {name=>"GCC_JIT_BOOL_OPTION_DUMP_SUMMARY", macro=>"1"},
              {name=>"GCC_JIT_BOOL_OPTION_KEEP_INTERMEDIATES", macro=>"1"},
              {name=>"GCC_JIT_BOOL_OPTION_SELFCHECK_GC", macro=>"1"},
              {name=>"GCC_JIT_COMPARISON_EQ", macro=>"1"},
              {name=>"GCC_JIT_COMPARISON_GE", macro=>"1"},
              {name=>"GCC_JIT_COMPARISON_GT", macro=>"1"},
              {name=>"GCC_JIT_COMPARISON_LE", macro=>"1"},
              {name=>"GCC_JIT_COMPARISON_LT", macro=>"1"},
              {name=>"GCC_JIT_COMPARISON_NE", macro=>"1"},
              {name=>"GCC_JIT_FUNCTION_ALWAYS_INLINE", macro=>"1"},
              {name=>"GCC_JIT_FUNCTION_EXPORTED", macro=>"1"},
              {name=>"GCC_JIT_FUNCTION_IMPORTED", macro=>"1"},
              {name=>"GCC_JIT_FUNCTION_INTERNAL", macro=>"1"},
              {name=>"GCC_JIT_GLOBAL_EXPORTED", macro=>"1"},
              {name=>"GCC_JIT_GLOBAL_IMPORTED", macro=>"1"},
              {name=>"GCC_JIT_GLOBAL_INTERNAL", macro=>"1"},
              {name=>"GCC_JIT_INT_OPTION_OPTIMIZATION_LEVEL", macro=>"1"},
              {name=>"GCC_JIT_NUM_BOOL_OPTIONS", macro=>"1"},
              {name=>"GCC_JIT_NUM_INT_OPTIONS", macro=>"1"},
              {name=>"GCC_JIT_NUM_STR_OPTIONS", macro=>"1"},
              {name=>"GCC_JIT_OUTPUT_KIND_ASSEMBLER", macro=>"1"},
              {name=>"GCC_JIT_OUTPUT_KIND_DYNAMIC_LIBRARY", macro=>"1"},
              {name=>"GCC_JIT_OUTPUT_KIND_EXECUTABLE", macro=>"1"},
              {name=>"GCC_JIT_OUTPUT_KIND_OBJECT_FILE", macro=>"1"},
              {name=>"GCC_JIT_STR_OPTION_PROGNAME", macro=>"1"},
              {name=>"GCC_JIT_TYPE_BOOL", macro=>"1"},
              {name=>"GCC_JIT_TYPE_CHAR", macro=>"1"},
              {name=>"GCC_JIT_TYPE_COMPLEX_DOUBLE", macro=>"1"},
              {name=>"GCC_JIT_TYPE_COMPLEX_FLOAT", macro=>"1"},
              {name=>"GCC_JIT_TYPE_COMPLEX_LONG_DOUBLE", macro=>"1"},
              {name=>"GCC_JIT_TYPE_CONST_CHAR_PTR", macro=>"1"},
              {name=>"GCC_JIT_TYPE_DOUBLE", macro=>"1"},
              {name=>"GCC_JIT_TYPE_FILE_PTR", macro=>"1"},
              {name=>"GCC_JIT_TYPE_FLOAT", macro=>"1"},
              {name=>"GCC_JIT_TYPE_INT", macro=>"1"},
              {name=>"GCC_JIT_TYPE_LONG", macro=>"1"},
              {name=>"GCC_JIT_TYPE_LONG_DOUBLE", macro=>"1"},
              {name=>"GCC_JIT_TYPE_LONG_LONG", macro=>"1"},
              {name=>"GCC_JIT_TYPE_SHORT", macro=>"1"},
              {name=>"GCC_JIT_TYPE_SIGNED_CHAR", macro=>"1"},
              {name=>"GCC_JIT_TYPE_SIZE_T", macro=>"1"},
              {name=>"GCC_JIT_TYPE_UNSIGNED_CHAR", macro=>"1"},
              {name=>"GCC_JIT_TYPE_UNSIGNED_INT", macro=>"1"},
              {name=>"GCC_JIT_TYPE_UNSIGNED_LONG", macro=>"1"},
              {name=>"GCC_JIT_TYPE_UNSIGNED_LONG_LONG", macro=>"1"},
              {name=>"GCC_JIT_TYPE_UNSIGNED_SHORT", macro=>"1"},
              {name=>"GCC_JIT_TYPE_VOID", macro=>"1"},
              {name=>"GCC_JIT_TYPE_VOID_PTR", macro=>"1"},
              {name=>"GCC_JIT_UNARY_OP_ABS", macro=>"1"},
              {name=>"GCC_JIT_UNARY_OP_BITWISE_NEGATE", macro=>"1"},
              {name=>"GCC_JIT_UNARY_OP_LOGICAL_NEGATE", macro=>"1"},
              {name=>"GCC_JIT_UNARY_OP_MINUS", macro=>"1"});
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'GCCJIT',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
