use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.054

use Test::More;

plan tests => 187 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'MarpaX/Java/ClassFile.pm',
    'MarpaX/Java/ClassFile/BNF/Annotation.pm',
    'MarpaX/Java/ClassFile/BNF/AnnotationArray.pm',
    'MarpaX/Java/ClassFile/BNF/AnnotationDefaultAttribute.pm',
    'MarpaX/Java/ClassFile/BNF/AppendFrame.pm',
    'MarpaX/Java/ClassFile/BNF/ArrayValue.pm',
    'MarpaX/Java/ClassFile/BNF/AttributesArray.pm',
    'MarpaX/Java/ClassFile/BNF/BootstrapMethodArray.pm',
    'MarpaX/Java/ClassFile/BNF/BootstrapMethodsAttribute.pm',
    'MarpaX/Java/ClassFile/BNF/CatchTarget.pm',
    'MarpaX/Java/ClassFile/BNF/ChopFrame.pm',
    'MarpaX/Java/ClassFile/BNF/ClassFile.pm',
    'MarpaX/Java/ClassFile/BNF/ClassInfoIndex.pm',
    'MarpaX/Java/ClassFile/BNF/ClassesArray.pm',
    'MarpaX/Java/ClassFile/BNF/CodeAttribute.pm',
    'MarpaX/Java/ClassFile/BNF/ConstValueIndex.pm',
    'MarpaX/Java/ClassFile/BNF/ConstantClassInfo.pm',
    'MarpaX/Java/ClassFile/BNF/ConstantDoubleInfo.pm',
    'MarpaX/Java/ClassFile/BNF/ConstantFieldrefInfo.pm',
    'MarpaX/Java/ClassFile/BNF/ConstantFloatInfo.pm',
    'MarpaX/Java/ClassFile/BNF/ConstantIntegerInfo.pm',
    'MarpaX/Java/ClassFile/BNF/ConstantInterfaceMethodrefInfo.pm',
    'MarpaX/Java/ClassFile/BNF/ConstantInvokeDynamicInfo.pm',
    'MarpaX/Java/ClassFile/BNF/ConstantLongInfo.pm',
    'MarpaX/Java/ClassFile/BNF/ConstantMethodHandleInfo.pm',
    'MarpaX/Java/ClassFile/BNF/ConstantMethodTypeInfo.pm',
    'MarpaX/Java/ClassFile/BNF/ConstantMethodrefInfo.pm',
    'MarpaX/Java/ClassFile/BNF/ConstantNameAndTypeInfo.pm',
    'MarpaX/Java/ClassFile/BNF/ConstantPoolArray.pm',
    'MarpaX/Java/ClassFile/BNF/ConstantStringInfo.pm',
    'MarpaX/Java/ClassFile/BNF/ConstantUtf8Info.pm',
    'MarpaX/Java/ClassFile/BNF/ConstantValueAttribute.pm',
    'MarpaX/Java/ClassFile/BNF/DeprecatedAttribute.pm',
    'MarpaX/Java/ClassFile/BNF/ElementValue.pm',
    'MarpaX/Java/ClassFile/BNF/ElementValueArray.pm',
    'MarpaX/Java/ClassFile/BNF/ElementValuePairArray.pm',
    'MarpaX/Java/ClassFile/BNF/EnclosingMethodAttribute.pm',
    'MarpaX/Java/ClassFile/BNF/EnumConstValue.pm',
    'MarpaX/Java/ClassFile/BNF/ExceptionTableArray.pm',
    'MarpaX/Java/ClassFile/BNF/ExceptionsAttribute.pm',
    'MarpaX/Java/ClassFile/BNF/FieldsArray.pm',
    'MarpaX/Java/ClassFile/BNF/FormalParameterTarget.pm',
    'MarpaX/Java/ClassFile/BNF/FullFrame.pm',
    'MarpaX/Java/ClassFile/BNF/InnerClassesAttribute.pm',
    'MarpaX/Java/ClassFile/BNF/InterfacesArray.pm',
    'MarpaX/Java/ClassFile/BNF/LineNumberArray.pm',
    'MarpaX/Java/ClassFile/BNF/LineNumberTableAttribute.pm',
    'MarpaX/Java/ClassFile/BNF/LocalVariableArray.pm',
    'MarpaX/Java/ClassFile/BNF/LocalVariableTableAttribute.pm',
    'MarpaX/Java/ClassFile/BNF/LocalVariableTypeArray.pm',
    'MarpaX/Java/ClassFile/BNF/LocalVariableTypeTableAttribute.pm',
    'MarpaX/Java/ClassFile/BNF/LocalvarTarget.pm',
    'MarpaX/Java/ClassFile/BNF/MethodParametersAttribute.pm',
    'MarpaX/Java/ClassFile/BNF/MethodsArray.pm',
    'MarpaX/Java/ClassFile/BNF/OffsetTarget.pm',
    'MarpaX/Java/ClassFile/BNF/OpCodeArray.pm',
    'MarpaX/Java/ClassFile/BNF/ParameterAnnotation.pm',
    'MarpaX/Java/ClassFile/BNF/ParameterAnnotationArray.pm',
    'MarpaX/Java/ClassFile/BNF/ParameterArray.pm',
    'MarpaX/Java/ClassFile/BNF/PathArray.pm',
    'MarpaX/Java/ClassFile/BNF/RuntimeInvisibleAnnotationsAttribute.pm',
    'MarpaX/Java/ClassFile/BNF/RuntimeInvisibleParameterAnnotationsAttribute.pm',
    'MarpaX/Java/ClassFile/BNF/RuntimeInvisibleTypeAnnotationsAttribute.pm',
    'MarpaX/Java/ClassFile/BNF/RuntimeVisibleAnnotationsAttribute.pm',
    'MarpaX/Java/ClassFile/BNF/RuntimeVisibleParameterAnnotationsAttribute.pm',
    'MarpaX/Java/ClassFile/BNF/RuntimeVisibleTypeAnnotationsAttribute.pm',
    'MarpaX/Java/ClassFile/BNF/SameFrame.pm',
    'MarpaX/Java/ClassFile/BNF/SameFrameExtended.pm',
    'MarpaX/Java/ClassFile/BNF/SameLocals1StackItemFrame.pm',
    'MarpaX/Java/ClassFile/BNF/SameLocals1StackItemFrameExtended.pm',
    'MarpaX/Java/ClassFile/BNF/SignatureAttribute.pm',
    'MarpaX/Java/ClassFile/BNF/SourceDebugExtensionAttribute.pm',
    'MarpaX/Java/ClassFile/BNF/SourceFileAttribute.pm',
    'MarpaX/Java/ClassFile/BNF/StackMapFrameArray.pm',
    'MarpaX/Java/ClassFile/BNF/StackMapTableAttribute.pm',
    'MarpaX/Java/ClassFile/BNF/SupertypeTarget.pm',
    'MarpaX/Java/ClassFile/BNF/SyntheticAttribute.pm',
    'MarpaX/Java/ClassFile/BNF/TableArray.pm',
    'MarpaX/Java/ClassFile/BNF/ThrowsTarget.pm',
    'MarpaX/Java/ClassFile/BNF/TypeAnnotation.pm',
    'MarpaX/Java/ClassFile/BNF/TypeAnnotationArray.pm',
    'MarpaX/Java/ClassFile/BNF/TypeArgumentTarget.pm',
    'MarpaX/Java/ClassFile/BNF/TypeParameterBoundTarget.pm',
    'MarpaX/Java/ClassFile/BNF/TypeParameterTarget.pm',
    'MarpaX/Java/ClassFile/BNF/TypePath.pm',
    'MarpaX/Java/ClassFile/BNF/UnmanagedAttribute.pm',
    'MarpaX/Java/ClassFile/BNF/VerificationTypeInfoArray.pm',
    'MarpaX/Java/ClassFile/Role/Parser.pm',
    'MarpaX/Java/ClassFile/Role/Parser/Actions.pm',
    'MarpaX/Java/ClassFile/Role/Parser/InnerGrammar.pm',
    'MarpaX/Java/ClassFile/Struct/Annotation.pm',
    'MarpaX/Java/ClassFile/Struct/AnnotationDefaultAttribute.pm',
    'MarpaX/Java/ClassFile/Struct/AppendFrame.pm',
    'MarpaX/Java/ClassFile/Struct/ArrayValue.pm',
    'MarpaX/Java/ClassFile/Struct/BootstrapMethod.pm',
    'MarpaX/Java/ClassFile/Struct/BootstrapMethodsAttribute.pm',
    'MarpaX/Java/ClassFile/Struct/CatchTarget.pm',
    'MarpaX/Java/ClassFile/Struct/ChopFrame.pm',
    'MarpaX/Java/ClassFile/Struct/Class.pm',
    'MarpaX/Java/ClassFile/Struct/ClassFile.pm',
    'MarpaX/Java/ClassFile/Struct/ClassInfoIndex.pm',
    'MarpaX/Java/ClassFile/Struct/CodeAttribute.pm',
    'MarpaX/Java/ClassFile/Struct/ConstValueIndex.pm',
    'MarpaX/Java/ClassFile/Struct/ConstantClassInfo.pm',
    'MarpaX/Java/ClassFile/Struct/ConstantDoubleInfo.pm',
    'MarpaX/Java/ClassFile/Struct/ConstantFieldrefInfo.pm',
    'MarpaX/Java/ClassFile/Struct/ConstantFloatInfo.pm',
    'MarpaX/Java/ClassFile/Struct/ConstantIntegerInfo.pm',
    'MarpaX/Java/ClassFile/Struct/ConstantInterfaceMethodrefInfo.pm',
    'MarpaX/Java/ClassFile/Struct/ConstantInvokeDynamicInfo.pm',
    'MarpaX/Java/ClassFile/Struct/ConstantLongInfo.pm',
    'MarpaX/Java/ClassFile/Struct/ConstantMethodHandleInfo.pm',
    'MarpaX/Java/ClassFile/Struct/ConstantMethodTypeInfo.pm',
    'MarpaX/Java/ClassFile/Struct/ConstantMethodrefInfo.pm',
    'MarpaX/Java/ClassFile/Struct/ConstantNameAndTypeInfo.pm',
    'MarpaX/Java/ClassFile/Struct/ConstantStringInfo.pm',
    'MarpaX/Java/ClassFile/Struct/ConstantUtf8Info.pm',
    'MarpaX/Java/ClassFile/Struct/ConstantValueAttribute.pm',
    'MarpaX/Java/ClassFile/Struct/DeprecatedAttribute.pm',
    'MarpaX/Java/ClassFile/Struct/DoubleVariableInfo.pm',
    'MarpaX/Java/ClassFile/Struct/ElementValue.pm',
    'MarpaX/Java/ClassFile/Struct/ElementValuePair.pm',
    'MarpaX/Java/ClassFile/Struct/EmptyTarget.pm',
    'MarpaX/Java/ClassFile/Struct/EnclosingMethodAttribute.pm',
    'MarpaX/Java/ClassFile/Struct/EnumConstValue.pm',
    'MarpaX/Java/ClassFile/Struct/ExceptionTable.pm',
    'MarpaX/Java/ClassFile/Struct/ExceptionsAttribute.pm',
    'MarpaX/Java/ClassFile/Struct/FieldInfo.pm',
    'MarpaX/Java/ClassFile/Struct/FloatVariableInfo.pm',
    'MarpaX/Java/ClassFile/Struct/FormalParameterTarget.pm',
    'MarpaX/Java/ClassFile/Struct/FullFrame.pm',
    'MarpaX/Java/ClassFile/Struct/InnerClassesAttribute.pm',
    'MarpaX/Java/ClassFile/Struct/IntegerVariableInfo.pm',
    'MarpaX/Java/ClassFile/Struct/LineNumber.pm',
    'MarpaX/Java/ClassFile/Struct/LineNumberTableAttribute.pm',
    'MarpaX/Java/ClassFile/Struct/LocalVariable.pm',
    'MarpaX/Java/ClassFile/Struct/LocalVariableTableAttribute.pm',
    'MarpaX/Java/ClassFile/Struct/LocalVariableType.pm',
    'MarpaX/Java/ClassFile/Struct/LocalVariableTypeTableAttribute.pm',
    'MarpaX/Java/ClassFile/Struct/LocalvarTarget.pm',
    'MarpaX/Java/ClassFile/Struct/LongVariableInfo.pm',
    'MarpaX/Java/ClassFile/Struct/MethodInfo.pm',
    'MarpaX/Java/ClassFile/Struct/MethodParametersAttribute.pm',
    'MarpaX/Java/ClassFile/Struct/NullVariableInfo.pm',
    'MarpaX/Java/ClassFile/Struct/ObjectVariableInfo.pm',
    'MarpaX/Java/ClassFile/Struct/OffsetTarget.pm',
    'MarpaX/Java/ClassFile/Struct/OpCode.pm',
    'MarpaX/Java/ClassFile/Struct/Parameter.pm',
    'MarpaX/Java/ClassFile/Struct/ParameterAnnotation.pm',
    'MarpaX/Java/ClassFile/Struct/Path.pm',
    'MarpaX/Java/ClassFile/Struct/RuntimeInvisibleAnnotationsAttribute.pm',
    'MarpaX/Java/ClassFile/Struct/RuntimeInvisibleParameterAnnotationsAttribute.pm',
    'MarpaX/Java/ClassFile/Struct/RuntimeInvisibleTypeAnnotationsAttribute.pm',
    'MarpaX/Java/ClassFile/Struct/RuntimeVisibleAnnotationsAttribute.pm',
    'MarpaX/Java/ClassFile/Struct/RuntimeVisibleParameterAnnotationsAttribute.pm',
    'MarpaX/Java/ClassFile/Struct/RuntimeVisibleTypeAnnotationsAttribute.pm',
    'MarpaX/Java/ClassFile/Struct/SameFrame.pm',
    'MarpaX/Java/ClassFile/Struct/SameFrameExtended.pm',
    'MarpaX/Java/ClassFile/Struct/SameLocals1StackItemFrame.pm',
    'MarpaX/Java/ClassFile/Struct/SameLocals1StackItemFrameExtended.pm',
    'MarpaX/Java/ClassFile/Struct/SignatureAttribute.pm',
    'MarpaX/Java/ClassFile/Struct/SourceDebugExtensionAttribute.pm',
    'MarpaX/Java/ClassFile/Struct/SourceFileAttribute.pm',
    'MarpaX/Java/ClassFile/Struct/StackMapTableAttribute.pm',
    'MarpaX/Java/ClassFile/Struct/SupertypeTarget.pm',
    'MarpaX/Java/ClassFile/Struct/SyntheticAttribute.pm',
    'MarpaX/Java/ClassFile/Struct/Table.pm',
    'MarpaX/Java/ClassFile/Struct/ThrowsTarget.pm',
    'MarpaX/Java/ClassFile/Struct/TopVariableInfo.pm',
    'MarpaX/Java/ClassFile/Struct/TypeAnnotation.pm',
    'MarpaX/Java/ClassFile/Struct/TypeArgumentTarget.pm',
    'MarpaX/Java/ClassFile/Struct/TypeParameterBoundTarget.pm',
    'MarpaX/Java/ClassFile/Struct/TypeParameterTarget.pm',
    'MarpaX/Java/ClassFile/Struct/TypePath.pm',
    'MarpaX/Java/ClassFile/Struct/UninitializedThisVariableInfo.pm',
    'MarpaX/Java/ClassFile/Struct/UninitializedVariableInfo.pm',
    'MarpaX/Java/ClassFile/Struct/UnmanagedAttribute.pm',
    'MarpaX/Java/ClassFile/Struct/_Base.pm',
    'MarpaX/Java/ClassFile/Struct/_Types.pm',
    'MarpaX/Java/ClassFile/Util/AccessFlagsStringification.pm',
    'MarpaX/Java/ClassFile/Util/ArrayRefWeakenisation.pm',
    'MarpaX/Java/ClassFile/Util/ArrayStringification.pm',
    'MarpaX/Java/ClassFile/Util/BNF.pm',
    'MarpaX/Java/ClassFile/Util/FrameTypeStringification.pm',
    'MarpaX/Java/ClassFile/Util/MarpaTrace.pm',
    'MarpaX/Java/ClassFile/Util/ProductionMode.pm'
);

my @scripts = (
    'bin/javapp'
);

# fake home for cpan-testers
use File::Temp;
local $ENV{HOME} = File::Temp::tempdir( CLEANUP => 1 );


my $inc_switch = -d 'blib' ? '-Mblib' : '-Ilib';

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}

foreach my $file (@scripts)
{ SKIP: {
    open my $fh, '<', $file or warn("Unable to open $file: $!"), next;
    my $line = <$fh>;

    close $fh and skip("$file isn't perl", 1) unless $line =~ /^#!\s*(?:\S*perl\S*)((?:\s+-\w*)*)(?:\s*#.*)?$/;
    my @flags = $1 ? split(' ', $1) : ();

    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, @flags, '-c', $file);
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$file compiled ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { require blib; blib->VERSION('1.01') };

    # in older perls, -c output is simply the file portion of the path being tested
    if (@_warnings = grep { !/\bsyntax OK$/ }
        grep { chomp; $_ ne (File::Spec->splitpath($file))[2] } @_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
} }



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


