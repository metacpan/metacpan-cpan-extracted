use strict;
use warnings;
use Cwd qw(getcwd);
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use Test::More;
use Docbook::Convert::Pandoc;


sub write_fixture {

    my ($fn, $text)=@_;
    open(my $output_fh, '>', $fn) || die "unable to open $fn: $!";
    print {$output_fh} $text || die "unable to write $fn: $!";
    close($output_fh) || die "unable to close $fn: $!";
    return 1;

}


my $cwd=getcwd();
my $temporary_dn=tempdir(CLEANUP => 1);
chdir($temporary_dn) || die "unable to chdir $temporary_dn: $!";
make_path('doc/nested', 'doc/build', 'doc/examples');
write_fixture('doc/guide.xml', qq{<?xml version="1.0"?>\n<article><title>Guide</title></article>\n});
write_fixture('doc/nested/reference.xml', qq{<db:article xmlns:db="urn:docbook"><db:title>Reference</db:title></db:article>\n});
write_fixture('doc/fragment.xml', qq{<section><title>Fragment</title></section>\n});
write_fixture('doc/build/generated.xml', qq{<article><title>Generated</title></article>\n});
write_fixture('doc/examples/sample.xml', qq{<article><title>Example</title></article>\n});

my $converter_or=Local::Converter->new();
is_deeply(
    $converter_or->discover_articles('doc'),
    ['doc/guide.xml', 'doc/nested/reference.xml'],
    'article discovery is recursive and excludes fragments and build trees'
);
is_deeply(
    $converter_or->convert_articles('doc'),
    ['doc/guide.md', 'doc/nested/reference.md'],
    'article conversion reports generated Markdown files'
);
is($converter_or->read_file('doc/guide.md'), "converted doc/guide.xml\n",
    'article Markdown is written beside its XML source');
is_deeply($converter_or->convert_articles('doc'), [],
    'unchanged Markdown is not rewritten');

unlink('doc/guide.md') || die "unable to remove doc/guide.md: $!";
my $dry_run_or=Local::Converter->new({dry_run => 1});
is_deeply($dry_run_or->convert_articles('doc'), ['doc/guide.md'],
    'dry-run reports stale Markdown');
ok(!-e 'doc/guide.md', 'dry-run does not write Markdown');

chdir($cwd) || die "unable to chdir $cwd: $!";
done_testing();


package Local::Converter;

use vars qw(@ISA);
BEGIN {@ISA=qw(Docbook::Convert::Pandoc)}

sub convert_file {

    my ($self, $fn)=@_;
    return "converted $fn\n";

}
