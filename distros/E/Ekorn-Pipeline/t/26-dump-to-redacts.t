use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# dump_to redacting secrets with Text::Redact::Secrets: with the real
# module, when it's installed; without it; and with fakes that fail each
# way, given by a hook at the front of @INC.

use Ekorn::Pipeline;
use Ekorn::Pipeline::Stages::Taps qw(dump_to);

my $class = 'Ekorn::Pipeline';

# Made-up secrets, each built from pieces, so that no line holds one
# whole for a scanner.
my $password = join '', 'Zq8vR2mX', 'kP4wL9nT';
my $key_id   = join '', 'AKIA',     'QYLPMN5H', 'HHFPZAM2';

my $file = 'Text/Redact/Secrets.pm';

# Dump the values given, and return what was written.
sub dumped (@values) {
    open my $fh, '>', \my $out or die "Can't open a string: $!";
    $class->new(dump_to($fh))->(@values);
    close $fh;
    return $out;
}

# Run the block with Text::Redact::Secrets as the source given makes it,
# or missing when it's undef, and dump_to looking for it afresh; return
# how many times it was looked for.
sub with_module ($source, $block) {
    my $looked = 0;
    my $hook   = sub ($, $wanted) {
        return unless $wanted eq $file;
        $looked++;
        die "Can't locate $file in \@INC (faked)\n" unless defined $source;
        return \
            "package Text::Redact::Secrets; use v5.36; no warnings; $source; 1;";
    };
    local @INC = ($hook, @INC);
    my $real = delete $INC{$file};
    my %real = %Text::Redact::Secrets::;
    delete $Text::Redact::Secrets::{$_} for qw(redact VERSION);
    Ekorn::Pipeline::Stages::Taps::_forget_redactor();
    $block->();
    Ekorn::Pipeline::Stages::Taps::_forget_redactor();
    delete $INC{$file};
    $INC{$file} = $real if defined $real;
    delete $Text::Redact::Secrets::{$_} for qw(redact VERSION);
    $Text::Redact::Secrets::{$_} = $real{$_}
        for grep { exists $real{$_} } qw(redact VERSION);
    return $looked;
}

subtest 'with Text::Redact::Secrets' => sub {
    skip_all 'Text::Redact::Secrets v1.x is not installed'
        unless eval { require Text::Redact::Secrets; 1 }
        && version->parse(Text::Redact::Secrets->VERSION) >= v1.0.0
        && version->parse(Text::Redact::Secrets->VERSION) < v2.0.0;
    Ekorn::Pipeline::Stages::Taps::_forget_redactor();

    my $row = {user => 'ekorn', password => $password, key_id => $key_id};
    open my $fh, '>', \my $out or die "Can't open a string: $!";
    is [$class->new(dump_to($fh))->($row)], [$row],
        'passes the value on as it came';
    is $row->{password}, $password, 'leaving its secrets in it';
    close $fh;
    is $out,
        "{\n  'key_id' => '*REDACTED*',\n  'password' => '*REDACTED*',\n"
        . "  'user' => 'ekorn'\n}\n",
        'and writes the dump with each secret redacted';

    is dumped("postgres://app:$password\@db/app"),
        "'postgres://app:*REDACTED*\@db/app'\n", "a DSN's password too";
    is dumped({b => 2, a => [1]}),
        "{\n  'a' => [\n    1\n  ],\n  'b' => 2\n}\n",
        'a dump with no secret is as it was';

    {
        local $Ekorn::Pipeline::Stages::Taps::DumpSecrets = 1;
        like dumped({password => $password}), qr( \Q$password\E )x,
            'with $DumpSecrets true, secrets are written';
    }
    like dumped({password => $password}), qr( \*REDACTED\* )x,
        'and redacted again once it is false';
    Ekorn::Pipeline::Stages::Taps::_forget_redactor();
};

subtest 'without Text::Redact::Secrets' => sub {
    my $looked = with_module(
        undef,
        sub {
            like dumped({password => $password}), qr( \Q$password\E )x,
                'secrets are written as they are';
            dumped(1);
        },
    );
    is $looked, 1, 'and the module is looked for once';
};

subtest 'with $DumpSecrets true' => sub {
    local $Ekorn::Pipeline::Stages::Taps::DumpSecrets = 1;
    my $looked = with_module(
        'die "broken\n"',
        sub {
            like dumped({password => $password}), qr( \Q$password\E )x,
                'secrets are written as they are';
        },
    );
    is $looked, 0, 'and the module is neither loaded nor tested';
};

my $works = q{
    our $VERSION = 'v1.0.2';


    sub redact ($text) { $text =~ s( Zq8v\w+ | AKIA\w+ )(*REDACTED*)xgr }
};

subtest 'a module that works' => sub {
    with_module(
        $works,
        sub {
            like dumped({password => $password}), qr( \*REDACTED\* )x,
                'is used';
        },
    );
};

my %broken = (
    'fails to load' => [
        'die "it broke\n"',
        'failed to load: it broke',
    ],
    'is v2' => [
        $works =~ s( v1\.0\.2 )(v2.0.0)xr,
        'is v2.0.0, not v1.x',
    ],
    'is v0' => [
        $works =~ s( v1\.0\.2 )(v0.9.0)xr,
        'is v0.9.0, not v1.x',
    ],
    'has a version that cannot be read' => [
        $works =~ s( v1\.0\.2 )(not.a.version)xr,
        'has no version we can read',
    ],
    'has no redact' => [
        q{our $VERSION = 'v1.0.2'},
        'has no redact',
    ],
    'redacts nothing' => [
        q{our $VERSION = 'v1.0.2'; sub redact ($text) { $text }},
        'failed its self-test',
    ],
    'misses the password' => [
        q{our $VERSION = 'v1.0.2'; sub redact ($text) { $text =~ s( AKIA\w+ )(*REDACTED*)xgr }},
        'failed its self-test',
    ],
    'misses the key id' => [
        q{our $VERSION = 'v1.0.2'; sub redact ($text) { $text =~ s( Zq8v\w+ )(*REDACTED*)xgr }},
        'failed its self-test',
    ],
    'takes secrets out without saying so' => [
        q{our $VERSION = 'v1.0.2'; sub redact ($text) { $text =~ s( Zq8v\w+ | AKIA\w+ )()xgr }},
        'failed its self-test',
    ],
    'dies when it redacts' => [
        q{our $VERSION = 'v1.0.2'; sub redact ($text) { die "no\n" }},
        'failed its self-test',
    ],
    'returns a reference' => [
        q{our $VERSION = 'v1.0.2'; sub redact ($text) { [] }},
        'failed its self-test',
    ],
);

for my $case (sort keys %broken) {
    my($source, $why) = $broken{$case}->@*;
    subtest "a module that $case" => sub {
        my $looked = with_module(
            $source,
            sub {
                for my $try (1, 2) {
                    open my $fh, '>', \my $out or die "Can't open a string: $!";
                    my $p    = $class->new(dump_to($fh));
                    my $line = __LINE__ + 1;
                    is dies { $p->({password => $password}) },
                        "Pipeline stage #1 failed at ${\ __FILE__ } line $line:\n"
                        . "    Text::Redact::Secrets $why, so dump_to won't write a dump"
                        . ' that may hold secrets; local'
                        . ' $Ekorn::Pipeline::Stages::Taps::DumpSecrets = 1 dumps'
                        . " them without redacting at ${\ __FILE__ } line $line.\n",
                        "croaks at the caller's line, dump $try";
                    is $out, undef, 'having written nothing';
                }
            },
        );
        is $looked, 1, 'looked for once';
    };
}

done_testing;
