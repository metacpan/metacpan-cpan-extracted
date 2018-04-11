use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 171;

my @module_files = (
    'HTML/FormFu.pm',
    'HTML/FormFu/Attribute.pm',
    'HTML/FormFu/Constants.pm',
    'HTML/FormFu/Constraint.pm',
    'HTML/FormFu/Constraint/ASCII.pm',
    'HTML/FormFu/Constraint/AllOrNone.pm',
    'HTML/FormFu/Constraint/AutoSet.pm',
    'HTML/FormFu/Constraint/Bool.pm',
    'HTML/FormFu/Constraint/Callback.pm',
    'HTML/FormFu/Constraint/CallbackOnce.pm',
    'HTML/FormFu/Constraint/DateTime.pm',
    'HTML/FormFu/Constraint/DependOn.pm',
    'HTML/FormFu/Constraint/Email.pm',
    'HTML/FormFu/Constraint/Equal.pm',
    'HTML/FormFu/Constraint/File.pm',
    'HTML/FormFu/Constraint/File/MIME.pm',
    'HTML/FormFu/Constraint/File/MaxSize.pm',
    'HTML/FormFu/Constraint/File/MinSize.pm',
    'HTML/FormFu/Constraint/File/Size.pm',
    'HTML/FormFu/Constraint/Integer.pm',
    'HTML/FormFu/Constraint/JSON.pm',
    'HTML/FormFu/Constraint/Length.pm',
    'HTML/FormFu/Constraint/MaxLength.pm',
    'HTML/FormFu/Constraint/MaxRange.pm',
    'HTML/FormFu/Constraint/MinLength.pm',
    'HTML/FormFu/Constraint/MinMaxFields.pm',
    'HTML/FormFu/Constraint/MinRange.pm',
    'HTML/FormFu/Constraint/Number.pm',
    'HTML/FormFu/Constraint/Printable.pm',
    'HTML/FormFu/Constraint/Range.pm',
    'HTML/FormFu/Constraint/Regex.pm',
    'HTML/FormFu/Constraint/Repeatable/Any.pm',
    'HTML/FormFu/Constraint/Required.pm',
    'HTML/FormFu/Constraint/Set.pm',
    'HTML/FormFu/Constraint/SingleValue.pm',
    'HTML/FormFu/Constraint/Word.pm',
    'HTML/FormFu/Deflator.pm',
    'HTML/FormFu/Deflator/Callback.pm',
    'HTML/FormFu/Deflator/CompoundDateTime.pm',
    'HTML/FormFu/Deflator/CompoundSplit.pm',
    'HTML/FormFu/Deflator/FormatNumber.pm',
    'HTML/FormFu/Deflator/PathClassFile.pm',
    'HTML/FormFu/Deflator/Strftime.pm',
    'HTML/FormFu/Deploy.pm',
    'HTML/FormFu/Element.pm',
    'HTML/FormFu/Element/Blank.pm',
    'HTML/FormFu/Element/Block.pm',
    'HTML/FormFu/Element/Button.pm',
    'HTML/FormFu/Element/Checkbox.pm',
    'HTML/FormFu/Element/Checkboxgroup.pm',
    'HTML/FormFu/Element/ComboBox.pm',
    'HTML/FormFu/Element/ContentButton.pm',
    'HTML/FormFu/Element/Date.pm',
    'HTML/FormFu/Element/DateTime.pm',
    'HTML/FormFu/Element/Email.pm',
    'HTML/FormFu/Element/Fieldset.pm',
    'HTML/FormFu/Element/File.pm',
    'HTML/FormFu/Element/Hidden.pm',
    'HTML/FormFu/Element/Hr.pm',
    'HTML/FormFu/Element/Image.pm',
    'HTML/FormFu/Element/Label.pm',
    'HTML/FormFu/Element/Multi.pm',
    'HTML/FormFu/Element/Number.pm',
    'HTML/FormFu/Element/Password.pm',
    'HTML/FormFu/Element/Radio.pm',
    'HTML/FormFu/Element/Radiogroup.pm',
    'HTML/FormFu/Element/Repeatable.pm',
    'HTML/FormFu/Element/Reset.pm',
    'HTML/FormFu/Element/Select.pm',
    'HTML/FormFu/Element/SimpleTable.pm',
    'HTML/FormFu/Element/Src.pm',
    'HTML/FormFu/Element/Submit.pm',
    'HTML/FormFu/Element/Text.pm',
    'HTML/FormFu/Element/Textarea.pm',
    'HTML/FormFu/Element/URL.pm',
    'HTML/FormFu/Exception.pm',
    'HTML/FormFu/Exception/Constraint.pm',
    'HTML/FormFu/Exception/Inflator.pm',
    'HTML/FormFu/Exception/Input.pm',
    'HTML/FormFu/Exception/Transformer.pm',
    'HTML/FormFu/Exception/Validator.pm',
    'HTML/FormFu/FakeQuery.pm',
    'HTML/FormFu/Filter.pm',
    'HTML/FormFu/Filter/Callback.pm',
    'HTML/FormFu/Filter/CompoundJoin.pm',
    'HTML/FormFu/Filter/CompoundSprintf.pm',
    'HTML/FormFu/Filter/CopyValue.pm',
    'HTML/FormFu/Filter/Encode.pm',
    'HTML/FormFu/Filter/ForceListValue.pm',
    'HTML/FormFu/Filter/FormatNumber.pm',
    'HTML/FormFu/Filter/HTMLEscape.pm',
    'HTML/FormFu/Filter/HTMLScrubber.pm',
    'HTML/FormFu/Filter/LowerCase.pm',
    'HTML/FormFu/Filter/NonNumeric.pm',
    'HTML/FormFu/Filter/Regex.pm',
    'HTML/FormFu/Filter/Split.pm',
    'HTML/FormFu/Filter/TrimEdges.pm',
    'HTML/FormFu/Filter/UpperCase.pm',
    'HTML/FormFu/Filter/Whitespace.pm',
    'HTML/FormFu/I18N.pm',
    'HTML/FormFu/I18N/bg.pm',
    'HTML/FormFu/I18N/cs.pm',
    'HTML/FormFu/I18N/da.pm',
    'HTML/FormFu/I18N/de.pm',
    'HTML/FormFu/I18N/en.pm',
    'HTML/FormFu/I18N/es.pm',
    'HTML/FormFu/I18N/fr.pm',
    'HTML/FormFu/I18N/hu.pm',
    'HTML/FormFu/I18N/it.pm',
    'HTML/FormFu/I18N/ja.pm',
    'HTML/FormFu/I18N/no.pm',
    'HTML/FormFu/I18N/pt_br.pm',
    'HTML/FormFu/I18N/pt_pt.pm',
    'HTML/FormFu/I18N/ro.pm',
    'HTML/FormFu/I18N/ru.pm',
    'HTML/FormFu/I18N/tr.pm',
    'HTML/FormFu/I18N/ua.pm',
    'HTML/FormFu/I18N/zh_cn.pm',
    'HTML/FormFu/Inflator.pm',
    'HTML/FormFu/Inflator/Callback.pm',
    'HTML/FormFu/Inflator/CompoundDateTime.pm',
    'HTML/FormFu/Inflator/DateTime.pm',
    'HTML/FormFu/Literal.pm',
    'HTML/FormFu/Localize.pm',
    'HTML/FormFu/Model.pm',
    'HTML/FormFu/Model/HashRef.pm',
    'HTML/FormFu/ObjectUtil.pm',
    'HTML/FormFu/OutputProcessor.pm',
    'HTML/FormFu/OutputProcessor/Indent.pm',
    'HTML/FormFu/OutputProcessor/StripWhitespace.pm',
    'HTML/FormFu/Plugin.pm',
    'HTML/FormFu/Plugin/StashValid.pm',
    'HTML/FormFu/Preload.pm',
    'HTML/FormFu/Processor.pm',
    'HTML/FormFu/QueryType/CGI.pm',
    'HTML/FormFu/QueryType/CGI/Simple.pm',
    'HTML/FormFu/QueryType/Catalyst.pm',
    'HTML/FormFu/Role/Constraint/Others.pm',
    'HTML/FormFu/Role/ContainsElements.pm',
    'HTML/FormFu/Role/ContainsElementsSharedWithField.pm',
    'HTML/FormFu/Role/CreateChildren.pm',
    'HTML/FormFu/Role/CustomRoles.pm',
    'HTML/FormFu/Role/Element/Coercible.pm',
    'HTML/FormFu/Role/Element/Field.pm',
    'HTML/FormFu/Role/Element/FieldMethods.pm',
    'HTML/FormFu/Role/Element/Group.pm',
    'HTML/FormFu/Role/Element/Input.pm',
    'HTML/FormFu/Role/Element/Layout.pm',
    'HTML/FormFu/Role/Element/MultiElement.pm',
    'HTML/FormFu/Role/Element/NonBlock.pm',
    'HTML/FormFu/Role/Element/ProcessOptionsFromModel.pm',
    'HTML/FormFu/Role/Element/SingleValueField.pm',
    'HTML/FormFu/Role/Filter/Compound.pm',
    'HTML/FormFu/Role/FormAndBlockMethods.pm',
    'HTML/FormFu/Role/FormAndElementMethods.pm',
    'HTML/FormFu/Role/FormBlockAndFieldMethods.pm',
    'HTML/FormFu/Role/GetProcessors.pm',
    'HTML/FormFu/Role/HasParent.pm',
    'HTML/FormFu/Role/NestedHashUtils.pm',
    'HTML/FormFu/Role/Populate.pm',
    'HTML/FormFu/Role/Render.pm',
    'HTML/FormFu/Transformer.pm',
    'HTML/FormFu/Transformer/Callback.pm',
    'HTML/FormFu/Upload.pm',
    'HTML/FormFu/UploadParam.pm',
    'HTML/FormFu/Util.pm',
    'HTML/FormFu/Validator.pm',
    'HTML/FormFu/Validator/Callback.pm'
);

my @scripts = (
    'bin/html_formfu_deploy.pl',
    'bin/html_formfu_dumpconf.pl'
);

# no fake home requested

my @switches = (
    -d 'blib' ? '-Mblib' : '-Ilib',
);

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-e', "require q[$lib]"))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { +require blib; blib->VERSION('1.01') };

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
    @switches = (@switches, split(' ', $1)) if $1;

    close $fh and skip("$file uses -T; not testable with PERL5LIB", 1)
        if grep { $_ eq '-T' } @switches and $ENV{PERL5LIB};

    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-c', $file))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-c', $file);
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$file compiled ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { +require blib; blib->VERSION('1.01') };

    # in older perls, -c output is simply the file portion of the path being tested
    if (@_warnings = grep { !/\bsyntax OK$/ }
        grep { chomp; $_ ne (File::Spec->splitpath($file))[2] } @_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
} }



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) );


