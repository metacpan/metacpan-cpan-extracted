#!perl

use strict;
use warnings;
use lib 'lib';

use File::Temp qw(tempfile);
use Pod::Checker;
use Test::More;

use Markdown::Pod::Embed;

my $em_dash="\xE2\x80\x94";
my $markdown=<<'MARKDOWN';
# Example::Client #

# NAME #

Example::Client - exercise Markdown conversion

# METHODS #

The base URL is `https://api.example.test/client/v4`.

* **upload_script($name, metadata => \%metadata, ...)** — upload a script, **immediately**. Returns `result`, or the envelope with `full_response => 1`. See **Uploads**.
MARKDOWN
$markdown=~s/ — / ${em_dash} /;

my $processor_or=Markdown::Pod::Embed->new();
my $merged=$processor_or->markpod_pod_merge($markdown);
my $pod=$processor_or->pod();

like($pod, qr/^=encoding utf8$/m, 'UTF-8 POD declares its encoding');
like($merged, qr/\A=encoding utf8\n\n=begin markdown/, 'encoding precedes retained Markdown');
unlike($pod, qr/^=head1 Example::Client$/m, 'leading Markdown page title is omitted from POD');
like($pod, qr/^=head1 NAME$/m, 'conventional NAME section remains');
like($pod, qr{C<https://api\.example\.test/client/v4>}, 'code-formatted URL remains code');
unlike($pod, qr{L<https://api\.example\.test}, 'code-formatted URL is not converted to a link');
unlike($pod, qr/MARKPODTOKEN/, 'conversion placeholders are fully restored');
like(
    $pod,
    qr{B<< upload_script\(\$name, metadata => \\%metadata, \.\.\.\) >>},
    'bold text containing a fat comma uses extended POD delimiters'
);

my ($pod_fh, $pod_fn)=tempfile();
binmode($pod_fh);
print {$pod_fh} $merged;
close($pod_fh);
my $diagnostic='';
open(my $diagnostic_fh, '>', \$diagnostic) || die "unable to capture POD diagnostics: $!";
my $checker_or=Pod::Checker->new(-warnings => 1);
$checker_or->parse_from_file($pod_fn, $diagnostic_fh);
close($diagnostic_fh);
is($checker_or->num_errors(), 0, 'generated POD has no syntax errors');
is($checker_or->num_warnings(), 0, 'generated POD has no warnings');
diag($diagnostic) if length($diagnostic);

done_testing();
