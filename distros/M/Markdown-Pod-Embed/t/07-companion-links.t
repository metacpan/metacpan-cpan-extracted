#!perl

use strict;
use warnings;
use lib 'lib';

use File::Path qw(make_path);
use File::Temp qw(tempdir);
use Pod::Checker;
use Test::More;

use Markdown::Pod::Embed;

sub slurp {
    my ($fn)=@_;
    open(my $input_fh, '<', $fn) || die "unable to read $fn: $!";
    local $/;
    my $text=<$input_fh>;
    close($input_fh) || die "unable to close $fn: $!";
    return $text;
}

sub spew {
    my ($fn, $text)=@_;
    open(my $output_fh, '>', $fn) || die "unable to write $fn: $!";
    print {$output_fh} $text;
    close($output_fh) || die "unable to close $fn: $!";
}

my $root_dn=tempdir(CLEANUP => 1);
my $lib_dn="${root_dn}/lib";
my $example_dn="${lib_dn}/Example";
make_path($example_dn);

my $parent_fn="${example_dn}/Parent.pm";
my $child_fn="${example_dn}/Child.pm";
my $root_fn="${lib_dn}/Root.pm";

spew($parent_fn, "package Example::Parent;\n1;\n");
spew($child_fn, "package Example::Child;\n1;\n");
spew("${child_fn}.md", "# NAME\n\nExample::Child - child module\n");
spew($root_fn, "package Root;\n1;\n");
spew("${root_fn}.md", "# NAME\n\nRoot - root module\n");
spew("${example_dn}/guide.md", "# Guide\n");
spew("${parent_fn}.md", <<'MARKDOWN');
# NAME

Example::Parent - parent module

# SEE ALSO

[Example::Child](Child.pm.md), [the root module](../Root.pm.md),
[guide](guide.md), [missing module](Missing.pm.md),
[child methods](Child.pm.md#methods), and
[external documentation](https://example.test/).
MARKDOWN

my $processor_or=Markdown::Pod::Embed->new({nobackup => 1});
ok($processor_or->update($parent_fn), 'companion links cause an initial update');

my $updated=slurp($parent_fn);
like(
    $updated,
    qr{\[Example::Child\]\(Child\.pm\.md\)},
    'retained Markdown keeps the relative companion link'
);
like(
    $updated,
    qr{L<Example::Child\|Example::Child>},
    'same-directory companion link targets the declared package in POD'
);
like(
    $updated,
    qr{L<the root module\|Root>},
    'parent-directory companion link targets the declared package in POD'
);
like($updated, qr{L<guide\|guide\.md>}, 'ordinary Markdown link is unchanged');
like(
    $updated,
    qr{L<missing module\|Missing\.pm\.md>},
    'missing companion module link is unchanged'
);
like(
    $updated,
    qr{L<child methods\|Child\.pm\.md#methods>},
    'companion link with a fragment is unchanged'
);
like(
    $updated,
    qr{L<external documentation\|https://example\.test/>},
    'external link is unchanged'
);

my $diagnostic='';
open(my $diagnostic_fh, '>', \$diagnostic) ||
    die "unable to capture POD diagnostics: $!";
my $checker_or=Pod::Checker->new(-warnings => 1);
$checker_or->parse_from_file($parent_fn, $diagnostic_fh);
close($diagnostic_fh);
is($checker_or->num_errors(), 0, 'generated POD has no syntax errors');
is($checker_or->num_warnings(), 0, 'generated POD has no warnings');
diag($diagnostic) if length($diagnostic);

is($processor_or->update($parent_fn), 0, 'second update is unchanged');

done_testing();
