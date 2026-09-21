#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(write_binary);
use JSON::MaybeXS qw(JSON);

use File::SOPS::Metadata;
use File::SOPS::Metadata::Flat;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# The flat metadata encoding (sops_age__list_0__map_enc) is the ENV and INI
# formats' way of carrying the `sops` section, and it is a second metadata wire
# format rather than a formatting detail -- k75.
#
# This file has two halves, and they prove different things:
#
#   * The UNIT half pins the scheme itself against the bytes measured off
#     sops 3.13.3. It needs no binary, and it fails if our mangling, ordering,
#     escaping or empty-list handling moves.
#   * The INTEROP half hands sops a document whose ENTIRE metadata section we
#     wrote, and requires sops to decrypt it. Our flatten agreeing with our
#     unflatten proves nothing about sops; only this half does.
#
# The fixture below is a real sops 3.13.3 layout -- separators, key order,
# alignment and the literal backslash-n inside the age armor are verbatim --
# with the base64 armor bodies replaced by obvious placeholders, because a
# wrapped data key is key material and does not belong in a committed file.
# The interop half uses genuinely real armor, generated at run time.

my $ARMOR_0 = '-----BEGIN AGE ENCRYPTED FILE-----\nWTBGblpTMWxibU55ZVhCMA\n'
            . 'ncGx2Ymk1dmNtY3ZkakVLTFQ0Z1dESTFOVEU1SUhKNk5VcFhWMEZLVTJWM1J'
            . 'nCg==\n-----END AGE ENCRYPTED FILE-----\n';
my $ARMOR_1 = '-----BEGIN AGE ENCRYPTED FILE-----\nZVUwd2Uzb1RTM1UyWjJKcQ\n'
            . 'nbTV6ZEdKcVpXNXpaWEpsY0hWaWJHbGpMbTl5Wnk5Mk1Rbz0K\n'
            . '-----END AGE ENCRYPTED FILE-----\n';
my $MAC = 'ENC[AES256_GCM,data:oxeR7QcP1x21EOnaV9KLWWi1lT1QmLPfRy0DVkSmA6JB,'
        . 'iv:bC8HOUFjNEbqtmxZZVwbaXQ0jkU91FXBLtGreAYzIoU=,'
        . 'tag:KRPLX1zT4uSuvF1WAiddrw==,type:str]';

my @FIXTURE = (
    [ 'age__list_0__map_enc'       => $ARMOR_0 ],
    [ 'age__list_0__map_recipient' => 'age1za8ys4vd4e04tgqngzghdumexg8vm3jzmk57rcvzlmfdlv2fhplqgtxxqt' ],
    [ 'age__list_1__map_enc'       => $ARMOR_1 ],
    [ 'age__list_1__map_recipient' => 'age1dj54v6hmzpkjkcw9ds04sxa924rgn8jze2yncamw706f8tzxagkshy8h4e' ],
    [ 'lastmodified'               => '2026-08-21T01:34:51Z' ],
    [ 'mac'                        => $MAC ],
    [ 'unencrypted_suffix'         => '_unencrypted' ],
    [ 'version'                    => '3.13.3' ],
);

sub as_lines { return map { "$_->[0]=$_->[1]" } @_ }

###############################################################################
# The mangling scheme
###############################################################################
subtest 'the path mangling scheme, as sops writes it' => sub {
    my $flat = File::SOPS::Metadata::Flat->new;

    my @pairs = $flat->flatten({
        age => [
            { enc => 'E0', recipient => 'R0' },
            { enc => 'E1', recipient => 'R1' },
        ],
        lastmodified => 'T',
    });

    is_deeply(
        [ map { $_->[0] } @pairs ],
        [ qw(
            age__list_0__map_enc
            age__list_0__map_recipient
            age__list_1__map_enc
            age__list_1__map_recipient
            lastmodified
        ) ],
        'a map key appends __map_K, a list index appends __list_N, the root is bare',
    );

    # key_groups is the deepest thing sops writes -- five levels, measured on a
    # `--shamir-secret-sharing-threshold 2` document.
    my @deep = $flat->flatten({
        key_groups => [ { age => [ { enc => 'E', recipient => 'R' } ] } ],
        shamir_threshold => 2,
    });
    is_deeply(
        [ map { $_->[0] } @deep ],
        [ qw(
            key_groups__list_0__map_age__list_0__map_enc
            key_groups__list_0__map_age__list_0__map_recipient
            shamir_threshold
        ) ],
        'the separators compose to any depth',
    );

    # Measured with eleven recipients: sops writes list_10 AFTER list_9, so the
    # output is a structural walk and not a byte sort of the finished keys.
    my @many = $flat->flatten({ age => [ map { { enc => "E$_" } } 0 .. 10 ] });
    is_deeply(
        [ map { $_->[0] } @many ],
        [ map { "age__list_${_}__map_enc" } 0 .. 10 ],
        'list indices come out in ascending numeric order, so list_10 follows list_9',
    );
};

###############################################################################
# The escape
###############################################################################
subtest 'escaping: a newline and nothing else' => sub {
    my $flat = File::SOPS::Metadata::Flat->new;

    # Measured by putting each of these through sops as an unencrypted_suffix
    # and reading the bytes back off the file it wrote.
    is $flat->escape_value("a\nb"),   'a\nb',    'a newline becomes backslash-n';
    is $flat->escape_value("a\n\nb"), 'a\n\nb',  'two newlines become two';
    is $flat->escape_value("a\tb"),   "a\tb",    'a real tab is left alone';
    is $flat->escape_value("a\rb"),   "a\rb",    'a real CR is left alone';
    is $flat->escape_value('a\\b'),   'a\\b',    'a backslash is NOT doubled';
    is $flat->escape_value('a\tb'),   'a\tb',    'a literal backslash-t is left alone';

    # Measured by reading the value back out of Go's own parse error, which
    # quotes the string it got.
    is $flat->unescape_value('A\nB'),  "A\nB",   'backslash-n becomes a newline';
    is $flat->unescape_value('A\\\nB'), "A\\\nB",
        'a preceding backslash does not escape it: backslash then newline';
    is $flat->unescape_value('A\tB'),  'A\tB',   'backslash-t is untouched';
    is $flat->unescape_value('A\rB'),  'A\rB',   'backslash-r is untouched';

    # The one that matters: PEM armor is almost entirely newlines and has to
    # come back byte-exact or the data key does not unwrap.
    my $armor = "-----BEGIN AGE ENCRYPTED FILE-----\nYWdl\nZm9v\n"
              . "-----END AGE ENCRYPTED FILE-----\n";
    is $flat->unescape_value($flat->escape_value($armor)), $armor,
        'an age armor block survives the round trip exactly';
    unlike $flat->escape_value($armor), qr/\n/,
        'and holds no real newline while it is on one line';
};

###############################################################################
# Empty lists
###############################################################################
subtest 'an empty list vanishes, because the format cannot write one' => sub {
    my $flat = File::SOPS::Metadata::Flat->new;

    # Measured: adding `sops_kms=` to a document sops wrote makes sops -d fail
    # with "'kms[0]' expected a map or struct, got \"string\"", because an
    # empty value reads back as a one-element list, not an empty one.
    my @pairs = $flat->flatten({
        kms => [], pgp => [], gcp_kms => [], azure_kv => [], hc_vault => [],
        age => [ { enc => 'E' } ],
        empty_map => {},
    });
    is_deeply(
        [ map { $_->[0] } @pairs ],
        [ 'age__list_0__map_enc' ],
        'empty lists and maps contribute no line at all',
    );

    # Nothing is lost: from_hash puts them back.
    my $meta = File::SOPS::Metadata->from_hash($flat->unflatten({ 'age__list_0__map_enc' => 'E' }));
    is_deeply $meta->kms, [], 'from_hash restores kms as an empty list';
    is_deeply $meta->pgp, [], 'from_hash restores pgp as an empty list';
};

###############################################################################
# The prefix -- the ONLY difference between the two formats
###############################################################################
subtest 'prefix is the whole difference between ENV and INI' => sub {
    my $env = File::SOPS::Metadata::Flat->new(prefix => 'sops_');
    my $ini = File::SOPS::Metadata::Flat->new;

    my $section = { lastmodified => 'T' };
    is_deeply [ as_lines($env->flatten($section)) ], [ 'sops_lastmodified=T' ],
        'ENV puts the flat keys under a sops_ prefix';
    is_deeply [ as_lines($ini->flatten($section)) ], [ 'lastmodified=T' ],
        'INI writes them bare, inside its [sops] section';

    ok  $env->is_metadata_key('sops_lastmodified'), 'ENV claims a sops_ key';
    ok !$env->is_metadata_key('DATABASE_URL'),      'ENV leaves a data key alone';
    ok  $ini->is_metadata_key('anything'),          'INI claims everything it is given';

    # An ENV caller may hand over the whole document; the data keys are skipped.
    is_deeply $env->unflatten({
        DATABASE_URL      => 'postgres://x',
        sops_lastmodified => 'T',
    }), { lastmodified => 'T' }, 'unflatten skips keys without the prefix';
};

###############################################################################
# Refusals
###############################################################################
subtest 'it refuses what sops refuses, instead of guessing' => sub {
    my $flat = File::SOPS::Metadata::Flat->new;

    # Measured: renumbering age__list_1__ to age__list_2__ in a file sops wrote
    # makes sops stop with "Error while unflattening: Incomplete list", exit 1.
    like exception_from(sub { $flat->unflatten({
        'age__list_0__map_enc' => 'E', 'age__list_2__map_enc' => 'E',
    }) }), qr/[Ii]ncomplete list/, 'a gap in the list indices is refused';

    like exception_from(sub { $flat->unflatten({ 'age__list_x' => 'E' }) }),
        qr/non-negative integer/, 'a list index that is not a number is refused';

    like exception_from(sub { $flat->unflatten({
        'age' => 'scalar', 'age__list_0__map_enc' => 'E',
    }) }), qr/needs a list/, 'a key that contradicts another key is refused';

    like exception_from(sub { $flat->unflatten({
        'age__map_x' => 'a', 'age__map_x__map_y' => 'b',
    }) }), qr/needs a mapping/, 'a scalar where a mapping has to go is refused';

    like exception_from(sub { $flat->unflatten('not a hashref') }),
        qr/needs a HashRef/, 'unflatten refuses a non-HashRef';
    like exception_from(sub { $flat->flatten([]) }),
        qr/HashRef/, 'flatten refuses a non-HashRef';

    like exception_from(sub { $flat->flatten({ k => sub { 1 } }) }),
        qr/CODE reference/, 'a code reference has no flat encoding';
    like exception_from(sub { $flat->flatten({ k => bless {}, 'Some::Class' }) }),
        qr/Some::Class/, 'a blessed non-boolean has no flat encoding';
};

###############################################################################
# Booleans and the mac_only_encrypted trap
###############################################################################
subtest 'mac_only_encrypted writes a bare true, and reads back a STRING' => sub {
    my $flat = File::SOPS::Metadata::Flat->new(prefix => 'sops_');

    # Measured: sops writes `sops_mac_only_encrypted=true`, lowercase and bare.
    my $meta = File::SOPS::Metadata->new(mac_only_encrypted => 1, lastmodified => 'T');
    my %got  = map { @$_ } $flat->flatten($meta->to_hash);
    is $got{sops_mac_only_encrypted}, 'true',
        'a JSON::PP::Boolean is written as a bare lowercase true';

    is $flat->escape_value(JSON->false), 'false', 'and false as a bare false';

    # This is a documented hazard, not an accident, and the assertion exists so
    # that closing it is a deliberate change rather than a silent one.
    #
    # Measured against sops 3.13.3: sops_mac_only_encrypted=false on a document
    # whose MAC covers every value decrypts (exit 0), and =true on the same
    # document fails with "MAC mismatch", exit 51 -- the option picks the
    # digest. The flat formats are untyped, so unflatten hands back the STRING
    # "false", which is TRUE in Perl. A format handler wiring this up has to
    # map it before from_hash sees it. k77 owns that decision.
    my $section = $flat->unflatten({ sops_mac_only_encrypted => 'false' });
    is $section->{mac_only_encrypted}, 'false',
        'unflatten is faithful to an untyped format and returns the string';
    ok !ref $section->{mac_only_encrypted},
        'it does NOT quietly become a boolean here -- k77 owns that';
};

###############################################################################
# The fixture: a real sops layout, through Metadata and back
###############################################################################
subtest 'a real sops 3.13.3 layout round-trips through Metadata unchanged' => sub {
    my $flat = File::SOPS::Metadata::Flat->new;
    my %lines = map { @$_ } @FIXTURE;

    my $section = $flat->unflatten(\%lines);

    is scalar @{ $section->{age} }, 2, 'two age recipients came back';
    like $section->{age}[0]{enc}, qr/\A-----BEGIN AGE ENCRYPTED FILE-----\n/,
        'the armor has real newlines again';
    like $section->{age}[0]{enc}, qr/-----END AGE ENCRYPTED FILE-----\n\z/,
        'including the trailing one';
    is $section->{version}, '3.13.3', 'version came through';

    my $meta = File::SOPS::Metadata->from_hash($section);
    is scalar($meta->get_age_encrypted_keys), 2, 'Metadata accepted it';
    is $meta->unencrypted_suffix, '_unencrypted', 'and kept the rule';

    # to_hash adds the six empty backend lists; flatten drops them again, so
    # the whole trip has to land back on the fixture byte for byte.
    is_deeply
        [ as_lines($flat->flatten($meta->to_hash)) ],
        [ as_lines(@FIXTURE) ],
        'unflatten -> from_hash -> to_hash -> flatten reproduces the file exactly';
};

###############################################################################
# Interop -- the only half that proves anything about sops
###############################################################################
SKIP: {
    my $sops_bin = find_sops_bin();
    skip "No sops binary found (checked \$SOPS_BIN, PATH, .sops-bin/sops, "
       . "/tmp/sops) -- the flat metadata encoding was NOT proven against "
       . "sops, only against itself. Run maint/fetch-sops or set SOPS_BIN.", 1
        unless $sops_bin;

    require Crypt::Age;
    diag("Using sops binary: $sops_bin");

    subtest 'sops decrypts a document whose metadata section we wrote' => sub {
        my ($pub1, $sec1) = Crypt::Age->generate_keypair();
        my ($pub2, $sec2) = Crypt::Age->generate_keypair();
        my $dir = tempdir(CLEANUP => 1);

        # Only the SECOND recipient's key is available for the decrypt, so the
        # test cannot pass unless the age entry at __list_1__ survived our
        # round trip byte-exactly.
        write_binary("$dir/key.txt", $sec2);
        local $ENV{SOPS_AGE_KEY_FILE} = "$dir/key.txt";

        for my $case (
            { format => 'dotenv', file => 'x.env',
              plain  => "FOO=bar\nNUM=5\n" },
            { format => 'ini',    file => 'x.ini',
              plain  => "[db]\nhost = localhost\nport = 5432\n" },
        ) {
            my $path = "$dir/$case->{file}";
            write_binary($path, $case->{plain});

            my $enc = `$sops_bin -e --age '$pub1,$pub2' '$path' 2>&1`;
            unless ($? == 0) {
                fail "sops -e failed for $case->{format}: $enc";
                next;
            }

            my ($body, $lines, $render) = $case->{format} eq 'dotenv'
                ? split_env($enc) : split_ini($enc);

            my $flat = File::SOPS::Metadata::Flat->new(
                $case->{format} eq 'dotenv' ? (prefix => 'sops_') : ()
            );

            # Our flatten must reproduce what sops wrote, key for key.
            my $meta   = File::SOPS::Metadata->from_hash($flat->unflatten($lines));
            my @ours   = $flat->flatten($meta->to_hash);
            my @theirs = map { [ $_ => $lines->{$_} ] }
                         sort { $a cmp $b } keys %$lines;
            is_deeply [ as_lines(@ours) ], [ as_lines(@theirs) ],
                "$case->{format}: our flat metadata is byte-identical to sops's";

            # And sops has to accept the file we rebuild from it.
            my $ours_path = "$dir/ours-$case->{file}";
            write_binary($ours_path, $body . $render->(\@ours));

            my $out = `$sops_bin -d '$ours_path' 2>&1`;
            is $?, 0, "$case->{format}: sops decrypts a file we wrote the metadata of"
                or diag("sops said: $out");
            is $out, $case->{plain},
                "$case->{format}: and gives back the original plaintext";
        }
    };
}

###############################################################################

sub exception_from {
    my ($code) = @_;
    my $error = '';
    eval { $code->(); 1 } or $error = $@;
    return $error;
}

# Each returns: the document text before the metadata, the flat key/value pairs,
# and a coderef that renders our pairs back into that format's shape.
sub split_env {
    my ($text) = @_;
    my (@body, %lines);
    for my $line (split /\n/, $text) {
        if ($line =~ /^sops_/) {
            my ($k, $v) = split /=/, $line, 2;
            $lines{$k} = $v;
        }
        else { push @body, $line }
    }
    return (
        join('', map { "$_\n" } @body),
        \%lines,
        sub { join '', map { "$_->[0]=$_->[1]\n" } @{ $_[0] } },
    );
}

sub split_ini {
    my ($text) = @_;
    my (@body, %lines);
    my $in_sops = 0;
    for my $line (split /\n/, $text) {
        if ($line =~ /^\[(.+)\]$/) {
            $in_sops = ($1 eq 'sops');
            push @body, $line unless $in_sops;
            next;
        }
        if ($in_sops) {
            next unless length $line;
            my ($k, $v) = $line =~ /^(\S+)\s*=\s?(.*)$/;
            $lines{$k} = $v;
        }
        else { push @body, $line }
    }
    return (
        join('', map { "$_\n" } @body) . "[sops]\n",
        \%lines,
        sub {
            my ($pairs) = @_;
            my $width = 0;
            for (@$pairs) { $width = length $_->[0] if length $_->[0] > $width }
            return join '', map { sprintf "%-*s = %s\n", $width, @$_ } @$pairs;
        },
    );
}

done_testing;
