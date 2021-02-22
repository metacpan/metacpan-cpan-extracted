use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 87;

my @module_files = (
    'Markdent.pm',
    'Markdent/CLI.pm',
    'Markdent/CapturedEvents.pm',
    'Markdent/CheckedOutput.pm',
    'Markdent/Dialect/GitHub/BlockParser.pm',
    'Markdent/Dialect/GitHub/SpanParser.pm',
    'Markdent/Dialect/Theory/BlockParser.pm',
    'Markdent/Dialect/Theory/SpanParser.pm',
    'Markdent/Event/AutoLink.pm',
    'Markdent/Event/CodeBlock.pm',
    'Markdent/Event/EndBlockquote.pm',
    'Markdent/Event/EndCode.pm',
    'Markdent/Event/EndDocument.pm',
    'Markdent/Event/EndEmphasis.pm',
    'Markdent/Event/EndHTMLTag.pm',
    'Markdent/Event/EndHeader.pm',
    'Markdent/Event/EndLink.pm',
    'Markdent/Event/EndListItem.pm',
    'Markdent/Event/EndOrderedList.pm',
    'Markdent/Event/EndParagraph.pm',
    'Markdent/Event/EndStrikethrough.pm',
    'Markdent/Event/EndStrong.pm',
    'Markdent/Event/EndTable.pm',
    'Markdent/Event/EndTableBody.pm',
    'Markdent/Event/EndTableCell.pm',
    'Markdent/Event/EndTableHeader.pm',
    'Markdent/Event/EndTableRow.pm',
    'Markdent/Event/EndUnorderedList.pm',
    'Markdent/Event/HTMLBlock.pm',
    'Markdent/Event/HTMLComment.pm',
    'Markdent/Event/HTMLCommentBlock.pm',
    'Markdent/Event/HTMLEntity.pm',
    'Markdent/Event/HTMLTag.pm',
    'Markdent/Event/HorizontalRule.pm',
    'Markdent/Event/Image.pm',
    'Markdent/Event/LineBreak.pm',
    'Markdent/Event/Preformatted.pm',
    'Markdent/Event/StartBlockquote.pm',
    'Markdent/Event/StartCode.pm',
    'Markdent/Event/StartDocument.pm',
    'Markdent/Event/StartEmphasis.pm',
    'Markdent/Event/StartHTMLTag.pm',
    'Markdent/Event/StartHeader.pm',
    'Markdent/Event/StartLink.pm',
    'Markdent/Event/StartListItem.pm',
    'Markdent/Event/StartOrderedList.pm',
    'Markdent/Event/StartParagraph.pm',
    'Markdent/Event/StartStrikethrough.pm',
    'Markdent/Event/StartStrong.pm',
    'Markdent/Event/StartTable.pm',
    'Markdent/Event/StartTableBody.pm',
    'Markdent/Event/StartTableCell.pm',
    'Markdent/Event/StartTableHeader.pm',
    'Markdent/Event/StartTableRow.pm',
    'Markdent/Event/StartUnorderedList.pm',
    'Markdent/Event/Text.pm',
    'Markdent/Handler/CaptureEvents.pm',
    'Markdent/Handler/HTMLFilter.pm',
    'Markdent/Handler/HTMLStream/Document.pm',
    'Markdent/Handler/HTMLStream/Fragment.pm',
    'Markdent/Handler/MinimalTree.pm',
    'Markdent/Handler/Multiplexer.pm',
    'Markdent/Handler/Null.pm',
    'Markdent/Parser.pm',
    'Markdent/Parser/BlockParser.pm',
    'Markdent/Parser/SpanParser.pm',
    'Markdent/Regexes.pm',
    'Markdent/Role/AnyParser.pm',
    'Markdent/Role/BalancedEvent.pm',
    'Markdent/Role/BlockParser.pm',
    'Markdent/Role/DebugPrinter.pm',
    'Markdent/Role/Dialect/BlockParser.pm',
    'Markdent/Role/Dialect/SpanParser.pm',
    'Markdent/Role/Event.pm',
    'Markdent/Role/EventAsText.pm',
    'Markdent/Role/EventsAsMethods.pm',
    'Markdent/Role/FilterHandler.pm',
    'Markdent/Role/HTMLStream.pm',
    'Markdent/Role/Handler.pm',
    'Markdent/Role/Simple.pm',
    'Markdent/Role/SpanParser.pm',
    'Markdent/Simple/Document.pm',
    'Markdent/Simple/Fragment.pm',
    'Markdent/Types.pm',
    'Markdent/Types/Internal.pm'
);

my @scripts = (
    'bin/markdent-html'
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


