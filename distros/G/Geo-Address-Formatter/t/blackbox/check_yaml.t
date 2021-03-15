use strict;
use warnings;
use lib 'lib';
use feature qw(say);
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use File::Basename;
use File::Find::Rule;
use File::Slurper 'read_text';
use File::Spec;
use Getopt::Long;
use Test::Exception;
use Test::More;
use YAML::XS qw(LoadFile);
use utf8;
use feature "unicode_strings";

# nicer output for diag and failures, see
# http://perldoc.perl.org/Test/More.html#CAVEATS-and-NOTES
my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(UTF-8)";
binmode $builder->failure_output, ":encoding(UTF-8)";
binmode $builder->todo_output,    ":encoding(UTF-8)";

my $af_path = dirname(__FILE__) . '/../../address-formatting';

my $path = $af_path . '/testcases/';
my $input_country;
my $verbose = 0;

GetOptions(
    'country:s' => \$input_country,
    'verbose'   => \$verbose,
);
if ($input_country) {
    $input_country = lc($input_country);
}

ok(1);

my @dirs = ('conf', 'testcases');

if (-d $path) {

    foreach my $dir (@dirs) {
        my $conf_path = $af_path . '/' . $dir . '/';
        note('looking for yaml files in ' . $conf_path);

        my @files = File::Find::Rule->file()->name('*.yaml')->in($conf_path);
        note('found ' . scalar(@files) . ' yaml files');
        ok(scalar(@files), 'found at least one yaml file');

        foreach my $filename (sort @files) {
            note('checking ' . $filename);

            # special test for main conf file
            if ($filename =~ m/worldwide.yaml/) {
                # escaped parens and \d need to be double escaped for python
                my $no_bad_parens = 1;
                open my $FH, "<:encoding(UTF-8)", $filename
                    or die "unable to open $filename $!";
                while (my $line = <$FH>) {
                    next if ($line =~ m/^\s*#/);
                    my @probchars = ('\(', '\)', 'd');
                    foreach my $c (@probchars) {
                        if ($line =~ m/\\$c/ && $line !~ m/\\\\$c/) {
                            warn $line;
                            $no_bad_parens = 0;
                            last; # bail out
                        }
                    }
                }
                close $FH;
                ok($no_bad_parens == 1, 'no badly escaped parens in worldwide conf file');
            }

            my @a_testcases = ();
            lives_ok {
                @a_testcases = LoadFile($filename);
            }
            "parsing file $filename";

            {
                my $text = read_text($filename);

                ## example "Stauffenstra\u00dfe" which should be "Stauffenstraße"
                if ($text =~ m/\\u00/) {
                    unlike($text, qr!\\u00!, 'don\'t use Javascript utf8 encoding, use characters directly');
                }

                if ($text =~ m/\t/) {
                    unlike($text, qr/\t/, 'there is a TAB in the YAML file. That will cause parsing errors');
                }

                if ($text !~ m/\n$/) {
                    like($text, qr!\n$!, 'file doesnt end in newline. This will cause parsing errors');
                }

                if ($text =~ /:\s*0/) {
                    like($text, qr!:s\*0!, 'zero unquoted. The PHP YAML parser will convert 0012 to 12');
                }
            }
        }
    }
}

done_testing();

1;
