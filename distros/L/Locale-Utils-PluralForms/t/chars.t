#!perl -T

use strict;
use warnings;

use Cwd qw(getcwd);
use File::Find;
use Test::More;

$ENV{TEST_AUTHOR}
    or plan skip_all => 'Author test. Set $ENV{TEST_AUTHOR} to a true value to run.';

my $UNTAINT_FILENAME_PATTERN = qr{\A (
    (?:
        (?: [A-Z] : )
        | //
    )?
    [0-9A-Z_\-/\. ]+
) \z}xmsi;
my ($PATH) = getcwd() =~ $UNTAINT_FILENAME_PATTERN;
$PATH =~ s{\\}{/}xmsg;

my @list;
find(
    {
        untaint_pattern => $UNTAINT_FILENAME_PATTERN,
        untaint         => 1,
        wanted          => sub {
            -d and return;
            $File::Find::name =~ m{
                / \.svn /
                | / \.git /
                | / \.gitignore \z
            }xms and return;
            $File::Find::name =~ m{
                (
                    (?: /lib/ | /example/ | /t/ )
                    | /Build\.PL \z
                    | /Changes \z
                    | /README \z
                    | /MANIFEST\.SKIP \z
                )
            }xms or return;
            push @list, $File::Find::name;
        },
    },
    $PATH,
);

plan( tests => 5 * scalar @list );

my @ignore_non_ascii = ();

for my $file_name (sort @list) {
    my @lines;
    {
        open my $file, '< :raw', $file_name
            or die "Cannnot open file $file_name";
        local $/ = ();
        my $text = <$file>;
        # repair last line without \n
        $text =~ s{([^\x0D\x0A]) \z}{$1\x0D\x0A}xms;
        @lines = split m{\x0A}, $text;
    }

    my $find_line_numbers = sub {
        my ($test_description, $test_reason, $regex, $regex_negation) = @_;
        my $line_number = 0;
        my @line_numbers = map {
            ++$line_number;
            ($regex_negation xor $_ =~ $regex)
            ? $line_number
            : ();
        } @lines;
        ok(! @line_numbers, $test_description);
        if (@line_numbers) {
            if (@line_numbers > 10) {
                $#line_numbers = 10;
                $line_numbers[10] = '...';
            }
            my $line_numbers = join q{, }, @line_numbers;
            diag("Check line $line_numbers in file $file_name for $test_reason.");
        }
        return;
    };

    $find_line_numbers->(
        "$file_name has Network line endings (LFCR)",
        'line endings',
        qr{\x0D \z}xms,
        1,
    );
    $find_line_numbers->(
        "$file_name has no TABs",
        'TABs',
        qr{\x09}xms,
    );
    $find_line_numbers->(
        "$file_name has no control chars",
        'control chars',
        qr{[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]}xms,
    );
    NON_ASCII: {
        for my $regex (@ignore_non_ascii) {
            if ( $file_name =~ $regex ) {
                ok(1, 'dummy');
                next NON_ASCII;
            }
        }
        $find_line_numbers->(
            "$file_name has no nonASCII chars",
            'nonASCII chars',
            qr{[\x80-\xA6\xA8-\xFF]}xms, # A7 is §
        );
    }
    $find_line_numbers->(
        "$file_name has no trailing space",
        'trailing space',
        qr{[ ] (?: \x0D? \x0A | \z )}xms,
    );
}
