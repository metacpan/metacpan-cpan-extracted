#!perl
use Test::Most;

use strict;
use warnings;

use autodie;
use Test::DZil;

use Dist::Zilla::Plugin::ReadmeAnyFromPod;

# Pull out types from the plugin to get default filenames

sub type_filename {
    return $Dist::Zilla::Plugin::ReadmeAnyFromPod::_types->{$_[0]}->{filename};
}

sub config_explicit {
    my $type = lc shift;
    return "InvalidReadmeType::$type" unless type_filename($type);
    # The X's defeat the auto-detection
    return [ "ReadmeAnyFromPod", "X${type}X", {
        type => "$type",
        filename => type_filename($type),
        location => "build",
    }];
}

sub config_implicit {
    my $type = lc shift;
    my $tc_type = ucfirst $type;
    return 0 unless type_filename($type);
    return [ 'ReadmeAnyFromPod', "Readme${tc_type}InBuild"];
}

my %tests = (
    text => [
        [ qr/^SYNOPSIS$/m, "plaintext header" ],
    ],
    pod => [
        [ qr/^=head1\s+SYNOPSIS/m, "POD header" ],
        [ qr/B<.*?>/, "POD bold formatting" ],
        [ qr/I<.*?>/, "POD italic formatting" ],
    ],
    html => [
        [ qr/<html>/, "HTML code" ],
        [ qr/<b>/i, "HTML bold formatting"],
        [ qr/<i>/i, "HTML italic formatting"],
    ],
    markdown => [
        [ qr/^# SYNOPSIS\s*$/m, "Markdown header" ],
        [ qr/([_*]{2})[^\s_*]+\1/, "Markdown bold formatting" ],
        [ qr/(?<!_)_[^\s_]+_(?!_)|(?<!\*)\*[^\s*]+\*(?!\*)/, "Markdown italic formatting" ],
    ],
    gfm => [
        [ qr/^# SYNOPSIS\s*$/m, "Markdown header" ],
        [ qr/([_*]{2})[^\s_*]+\1/, "Markdown bold formatting" ],
        [ qr/(?<!_)_[^\s_]+_(?!_)|(?<!\*)\*[^\s*]+\*(?!\*)/, "Markdown italic formatting" ],
    ],
    never => [
        [ qr/\r/, "Carriage return", ],
        [ qr/^__END__$/m, "Perl code __END__ marker", ],
    ],
);

my @possible_types = keys %$Dist::Zilla::Plugin::ReadmeAnyFromPod::_types;

for my $tested_type (@possible_types) {
    my @other_types = grep { $_ ne $tested_type } keys %tests;
    my $filename = type_filename($tested_type);

    my %config = (
        explicit => config_explicit($tested_type),
        implicit => config_implicit($tested_type),
    );

    my %tzil = map {
        $_ => Builder->from_config(
            { dist_root => 'corpus/dist/DZT' },
            {
                add_files => {
                    'source/dist.ini' => simple_ini('GatherDir', $config{$_})
                },
            }
        )
    } keys %config;

    my @positive_tests = $tests{$tested_type} ? @{$tests{$tested_type}} : ();
    my @positive_test_names = map { $_->[1] } @positive_tests;
    my @negative_tests = map { $tests{$_} ? @{$tests{$_}} : () } @other_types;
    @negative_tests = grep { my $item = $_; not grep { $item->[1] eq $_ } @positive_test_names } @negative_tests;

    for my $tzil_name (keys %tzil) {
      SKIP: {
            my $tzil = $tzil{$tzil_name};
            lives_ok { $tzil->build; } "$tzil_name $tested_type dist builds successfully"
                    or skip "Build failed for $tzil_name $tested_type", 1 + scalar @positive_tests + scalar @negative_tests;
            my $readme_content = eval { $tzil->slurp_file("build/" . type_filename($tested_type)); };
            ok $readme_content, "$tzil_name $tested_type dist contains README file at expected location " . type_filename($tested_type) . "."
                or skip "Missing readme file for $tzil_name $tested_type dist", scalar @positive_tests + scalar @negative_tests;


            for my $test (@positive_tests) {
                my ($regex, $desc) = @$test;
                my $message = "$tzil_name $tested_type readme file contains $desc";
                like $readme_content, $regex, $message;
            }
            for my $test (@negative_tests) {
                my ($regex, $desc) = @$test;
                my $message = "$tzil_name $tested_type readme file does not contain $desc";
                unlike $readme_content, $regex, $message;
            }
        }
    }
}

done_testing();
