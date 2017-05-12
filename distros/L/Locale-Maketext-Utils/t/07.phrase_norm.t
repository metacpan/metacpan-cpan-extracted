use Test::More tests => 618 + 1;
use Test::NoWarnings;    # + 1

BEGIN {
    use_ok('Locale::Maketext::Utils::Phrase::Norm');
}

our $norm = Locale::Maketext::Utils::Phrase::Norm->new_source( { 'run_extra_filters' => 1 } );
my $spec = Locale::Maketext::Utils::Phrase::Norm->new_source( 'WhiteSpace', { 'run_extra_filters' => 1, 'skip_defaults_when_given_filters' => 1 } );

our %global_all_warnings = (
    'special' => [],
    'default' => [],
);

our %global_filter_warnings = (
    'special' => [],
    'default' => [],
);

{
    # need to skip BeginUpper and EndPunc since it bumps 1 value in one test but not the others. Also Ellipsis so we don't have to factor in an extra change
    local $norm = Locale::Maketext::Utils::Phrase::Norm->new_source( qw(NonBytesStr WhiteSpace Grapheme Ampersand Markup Escapes), { 'run_extra_filters' => 1, 'skip_defaults_when_given_filters' => 1 } );

    run_32_tests(
        'filter_name'    => 'WhiteSpace',
        'filter_pos'     => 1,
        'original'       => "\xc2\xa0… I have \xc2\xa0  all \x00sorts of\tthings.\n ",
        'modified'       => " … I have all [comment,invalid char Ux0000]sorts of[comment,invalid char Ux0009]things.[comment,invalid char Ux000A]",
        'all_violations' => {
            'special' => [
                'Invalid whitespace, control, or invisible characters',
                'Beginning ellipsis space should be a normal space',
                'Beginning white space',
                'Trailing white space',
                'Multiple internal white space',
            ],
            'default' => undef,    # undef means "same as special"
        },
        'all_warnings'      => \%global_all_warnings,
        'filter_violations' => undef,                      # undef means "same as all_violations"
        'filter_warnings'   => \%global_filter_warnings,
        'return_value'      => {
            'special' => [ 0, 5,                             0, 1 ],
            'default' => undef, # undef means "same as special"
        },
        'diag' => 0,
    );
}

run_32_tests(
    'filter_name' => 'NonBytesStr',
    'filter_pos'  => 0,
    'original'    => 'X \x{2026} N \N{WHITE SMILING FACE} u \u1F37A U Cruel U+22EE NU \N{U+22EE} X\'2026\' Ux2020 u"\u2026".',
    'modified' =>
      'X [comment,non bytes unicode string “\x{2026}”] N [comment,charnames.pm type string “\N{WHITE SMILING FACE}”] u [comment,unicode notation “\u1F37A”] U Cruel [comment,unicode notation “U+22EE”] NU [comment,charnames.pm type string “\N{U+22EE}”] [comment,unicode notation “X‘2026’”] [comment,unicode notation “Ux2020”] [comment,unicode notation “u“\u2026””].',
    'all_violations' => {
        'special' => [
            'non-bytes string (perl)',
            'charnames.pm string notation',
            'unicode code point notation (Python style)',
            'unicode code point notation (C/C++/Java style)',
            'unicode code point notation (alternate style)',
            'unicode code point notation (visual notation style)',
            'unicode code point notation (visual notation type 2 style)',
        ],
        'default' => [
            'non-bytes string (perl)',
            'charnames.pm string notation',
            'unicode code point notation (Python style)',
            'unicode code point notation (C/C++/Java style)',
            'unicode code point notation (alternate style)',
            'unicode code point notation (visual notation style)',
            'unicode code point notation (visual notation type 2 style)',
            'Contains markup related characters',
        ],
    },
    'all_warnings' => {
        'special' => [],
        'default' => [
            'consider if, instead of using a straight apostrophe, using ‘’ for single quoting and ’ for an apostrophe is the right thing here (i.e. instead of bracket notation)',
            'consider if, instead of using straight double quotes, using “” is the right thing here (i.e. instead of bracket notation)',
        ],
    },
    'filter_violations' => {
        'special' => [
            'non-bytes string (perl)',
            'charnames.pm string notation',
            'unicode code point notation (Python style)',
            'unicode code point notation (C/C++/Java style)',
            'unicode code point notation (alternate style)',
            'unicode code point notation (visual notation style)',
            'unicode code point notation (visual notation type 2 style)',
        ],
        'default' => undef,
    },
    'filter_warnings' => {},
    'return_value'    => {
        'special' => [ 0, 7,                             0, 1 ],
        'default' => undef, # undef means "same as special"
    },
    'diag' => 0,
);

run_32_tests(
    'filter_name'    => 'Grapheme',
    'filter_pos'     => 2,
    'original'       => 'X \xe2\x98\xba\xe2\x80\xa6®.',                             # not interpolated on purpose, we're looking at literal strings e.g. parsing this source code maketext("X \xe2\x98\xba\xe2\x80\xa6®") to find the string 'X \xe2\x98\xba\xe2\x80\xa6®' not 'X ☺…®'
    'modified'       => 'X [comment,grapheme “\xe2\x98\xba\xe2\x80\xa6”]®.',    # not interpolated on purpose, we're looking at literal strings …
    'all_violations' => {
        'special' => [
            'Contains grapheme notation',
        ],
        'default' => undef,                                                          # undef means "same as special"
    },
    'all_warnings'      => \%global_all_warnings,
    'filter_violations' => undef,                                                    # undef means "same as all_violations"
    'filter_warnings'   => \%global_filter_warnings,
    'return_value'      => {
        'special' => [ 0, 1,                             0, 1 ],
        'default' => undef, # undef means "same as special"
    },
    'diag' => 0,
);

run_32_tests(
    'filter_name'    => 'Ampersand',
    'filter_pos'     => 3,
    'original'       => 'Z &[output,chr,&] X[asis,ATchr(&)T®]Y Z[output,chr,38]Z?',
    'modified'       => 'Z [output,amp] [output,amp] X[asis,ATchr(38)T®]Y Z [output,amp] Z?',
    'all_violations' => {
        'special' => [
            'Prefer [output,amp] over [output,chr,&] or [output,chr,38].',
            'Prefer chr(38) over chr(&).',
            'Ampersands need done via [output,amp].',
            'Ampersand should have one space before and/or after unless it is embedded in an asis().',
        ],
        'default' => undef,    # undef means "same as special"
    },
    'all_warnings'      => \%global_all_warnings,
    'filter_violations' => undef,                      # undef means "same as all_violations"
    'filter_warnings'   => \%global_filter_warnings,
    'return_value'      => {
        'special' => [ 0, 4,                             0, 1 ],
        'default' => undef, # undef means "same as special"
    },
    'diag' => 0,
);

run_32_tests(
    'filter_name'    => 'Markup',
    'filter_pos'     => 4,
    'original'       => q{Z<'""'><>!},
    'modified'       => 'Z[output,lt][output,apos][output,quot][output,quot][output,apos][output,gt][output,lt][output,gt]!',
    'all_violations' => {
        'special' => [
            'Contains markup related characters',
        ],
        'default' => undef,    # undef means "same as special"
    },
    'all_warnings' => {
        'default' => [
            'consider if, instead of using a straight apostrophe, using ‘’ for single quoting and ’ for an apostrophe is the right thing here (i.e. instead of bracket notation)',
            'consider if, instead of using straight double quotes, using “” is the right thing here (i.e. instead of bracket notation)',
        ],
        'special' => undef,    # undef means "same as default"
    },
    'filter_violations' => undef,    # undef means "same as all_violations"
    'filter_warnings'   => {
        'default' => [
            'consider if, instead of using a straight apostrophe, using ‘’ for single quoting and ’ for an apostrophe is the right thing here (i.e. instead of bracket notation)',
            'consider if, instead of using straight double quotes, using “” is the right thing here (i.e. instead of bracket notation)',
        ],
        'special' => undef,          # undef means "same as default"
    },
    'return_value' => {
        'special' => [ 0, 1,                             2, 1 ],
        'default' => undef, # undef means "same as special"
    },
    'diag' => 0,
);
{
    my $ell = Locale::Maketext::Utils::Phrase::Norm->new_source( 'Ellipsis', { 'run_extra_filters' => 1, 'skip_defaults_when_given_filters' => 1 } );
    for my $good (
        ' … I am … good, you …',                                                    # normal spaces
        ' … I am … good, you …',                                                # character (OSX: ⌥space)
        ' …[output,nbsp]I am[output,nbsp]…[output,nbsp]good, you[output,nbsp]…',    # visual [output,nbsp]
        'Foo ….',
        'Foo …!',
        'Foo …?',
        'Foo …:',
      ) {
        my $valid = $ell->normalize($good);
        ok( $valid->get_status(),             "valid: RES get_status()" );
        ok( !$valid->filters_modify_string(), "valid: RES filters_modify_string()" );
        is( $valid->get_warning_count(),   0, "valid: RES get_warning_count()" );
        is( $valid->get_violation_count(), 0, "valid: RES get_violation_count()" );
    }
}
{

    # need to skip BeginUpper and Whitespace since it bumps 1 value in one test but not the others.
    local $norm = Locale::Maketext::Utils::Phrase::Norm->new_source( qw(NonBytesStr Grapheme Ampersand Markup Ellipsis EndPunc Escapes), { 'run_extra_filters' => 1, 'skip_defaults_when_given_filters' => 1 } );

    run_32_tests(
        'filter_name'    => 'Ellipsis',
        'filter_pos'     => 4,                                                                                                                                    # is 5 with no args to new_source()
        'original'       => " …I… am .. bad ,,, you …e.g., foo … bar[output,nbsp]…[output,nbsp]baz … (… foo …) what…you…[output,nbsp]",
        'modified'       => " … I … am … bad … you … e.g., foo … bar[output,nbsp]…[output,nbsp]baz … (… foo …) what … you …",
        'all_violations' => {
            'special' => [],
            'default' => [],
        },
        'all_warnings' => {
            'special' => [
                'multiple period/comma instead of ellipsis character',
                'initial ellipsis should be preceded by a normal space',
                'initial ellipsis should be followed by a normal space or a non-break-space (in bracket notation or character form)',
                'final ellipsis should be followed by a valid punctuation mark or nothing',
                'final ellipsis should be preceded by a normal space or a non-break-space (in bracket notation or character form)',
                'medial ellipsis should be surrounded on each side by a parenthesis or normal space or a non-break-space (in bracket notation or character form)',
            ],
            'default' => undef,    # undef means "same as special"
        },
        'filter_violations' => undef,
        'filter_warnings'   => undef,
        'return_value'      => {
            'special' => [ -1, 0,                             6, 1 ],
            'default' => undef, # undef means "same as special"
        },
        'get_status_is_warnings'        => 1,
        'filter_does_not_modify_string' => 0,
        'diag'                          => 0,
    );
}

run_32_tests(
    'filter_name'    => 'BeginUpper',
    'filter_pos'     => 6,
    'original'       => 'wazzup?',
    'modified'       => 'wazzup?',
    'all_violations' => {
        'special' => [],
        'default' => [],
    },
    'all_warnings' => {
        'special' => ['Does not start with an uppercase letter, ellipsis preceded by space, or bracket notation.'],
        'default' => undef,
    },
    'filter_violations' => undef,    # undef means "same as all_violations"
    'filter_warnings'   => undef,
    'return_value'      => {
        'special' => [ -1, 0,                             1 ],
        'default' => undef, # undef means "same as special"
    },
    'get_status_is_warnings'        => 1,
    'filter_does_not_modify_string' => 1,
    'diag'                          => 0,
);

{
    local %global_all_warnings = %global_all_warnings;
    $global_all_warnings{'special'} = \@{ $global_all_warnings{'special'} };
    $global_all_warnings{'default'} = \@{ $global_all_warnings{'default'} };

    push @{ $global_all_warnings{'special'} }, 'Non title/label does not end with some sort of punctuation or bracket notation.';
    push @{ $global_all_warnings{'default'} }, 'Non title/label does not end with some sort of punctuation or bracket notation.';

    local %global_filter_warnings = %global_filter_warnings;
    $global_filter_warnings{'special'} = \@{ $global_filter_warnings{'special'} };
    $global_filter_warnings{'default'} = \@{ $global_filter_warnings{'default'} };

    push @{ $global_filter_warnings{'special'} }, 'Non title/label does not end with some sort of punctuation or bracket notation.';
    push @{ $global_filter_warnings{'default'} }, 'Non title/label does not end with some sort of punctuation or bracket notation.';

    run_32_tests(
        'filter_name'    => 'EndPunc',
        'filter_pos'     => 7,
        'original'       => 'I am an evil partial phrase',
        'modified'       => 'I am an evil partial phrase',
        'all_violations' => {
            'special' => [],
            'default' => [],
        },
        'all_warnings'      => \%global_all_warnings,
        'filter_violations' => undef,                      # undef means "same as all_violations"
        'filter_warnings'   => \%global_filter_warnings,
        'return_value'      => {
            'special' => [ -1, 0,                             1 ],
            'default' => undef, # undef means "same as special"
        },
        'get_status_is_warnings'        => 1,
        'filter_does_not_modify_string' => 1,
        'diag'                          => 0,
    );
}

# all phrase:
run_32_tests(
    'filter_name'    => 'Consider',
    'filter_pos'     => 8,
    'original'       => '[comment,this is a an “all BN” phrase]',
    'modified'       => '[comment,this is a an “all BN” phrase][comment,does this phrase really need to be entirely bracket notation?]',
    'all_violations' => {
        'special' => [],
        'default' => undef,    # undef means "same as special"
    },
    'all_warnings' => {
        'default' => [
            'Entire phrase is bracket notation, is there a better way in this case?',
        ],
        'special' => undef,
    },
    'filter_violations' => undef,    # undef means "same as all_violations"
    'filter_warnings'   => undef,    # undef means "same as all_warnings"
    'return_value'      => {
        'special' => [ -1, 0,                             1, 1 ],
        'default' => undef, # undef means "same as special"
    },
    'get_status_is_warnings' => 1,
    'diag'                   => 0,
);

# hardcoded URL
run_32_tests(
    'filter_name'    => 'Consider',
    'filter_pos'     => 8,
    'original'       => 'X [output,url,_1] [output,url,http://search.cpan.org] Y.',
    'modified'       => 'X [output,url,_1] [output,url,why hardcode “http://search.cpan.org”] Y.',
    'all_violations' => {
        'special' => [],
        'default' => undef,    # undef means "same as special"
    },
    'all_warnings' => {
        'default' => [
            'Hard coded URLs can be a maintenance nightmare, why not pass the URL in so the phrase does not change if the URL does',
        ],
        'special' => undef,
    },
    'filter_violations' => undef,    # undef means "same as all_violations"
    'filter_warnings'   => undef,    # undef means "same as all_warnings"
    'return_value'      => {
        'special' => [ -1, 0,                             1, 1 ],
        'default' => undef, # undef means "same as special"
    },
    'get_status_is_warnings' => 1,
    'diag'                   => 0,
);

# hardcoded URL w/ additional args
run_32_tests(
    'filter_name'    => 'Consider',
    'filter_pos'     => 8,
    'original'       => 'X [output,url,_1] [output,url,http://search.cpan.org,foo,bar] Y.',
    'modified'       => 'X [output,url,_1] [output,url,why hardcode “http://search.cpan.org”,foo,bar] Y.',
    'all_violations' => {
        'special' => [],
        'default' => undef,    # undef means "same as special"
    },
    'all_warnings' => {
        'default' => [
            'Hard coded URLs can be a maintenance nightmare, why not pass the URL in so the phrase does not change if the URL does',
        ],
        'special' => undef,
    },
    'filter_violations' => undef,    # undef means "same as all_violations"
    'filter_warnings'   => undef,    # undef means "same as all_warnings"
    'return_value'      => {
        'special' => [ -1, 0,                             1, 1 ],
        'default' => undef, # undef means "same as special"
    },
    'get_status_is_warnings' => 1,
    'diag'                   => 0,
);

# Simple bare var
# 32k more: for (1..1001) {

{
    local $SIG{__WARN__} = sub { };    # [rt 76706] the funny args in this string make L::M::_compile give repeated warning of: Use of uninitialized value in join or string at (eval 240) line 2
    run_32_tests(
        'filter_name'    => 'Consider',
        'filter_pos'     => 8,
        'original'       => 'X [_1] foo, [_8], [_-23] ‘[_99]’ [_*] ([_42]): [_2]',
        'modified'       => 'X “[_1]” foo, [_8], “[_-23]” ‘[_99]’ “[_*]” ([_42]): [_2]',
        'all_violations' => {
            'special' => [],
            'default' => undef,        # undef means "same as special"
        },
        'all_warnings' => {
            'default' => [
                'Bare variable can lead to ambiguous output',
            ],
            'special' => undef,
        },
        'filter_violations' => undef,    # undef means "same as all_violations"
        'filter_warnings'   => undef,    # undef means "same as all_warnings"
        'return_value'      => {
            'special' => [ -1, 0,                             1, 1 ],
            'default' => undef, # undef means "same as special"
        },
        'get_status_is_warnings' => 1,
        'diag'                   => 0,
    );
}

# /32k more }

# TODO Complex bare vars (see filter mod for comment specifics)
#    [output,strong,_2] [output,strong,_-42] [output,strong,_*] [output,strong,_2,Z] [output,strong,_-42,Z] [output,strong,_*,Z] [output,strong,X_2X] [output,strong,X_-42X] [output,strong,X_*X] [output,strong,X_2X,Z] [output,strong,X_-42X,Z] [output,strong,X_*X,Z]

run_32_tests(
    'filter_name'    => 'Escapes',
    'filter_pos'     => 9,
    'original'       => 'I am here.\n\fled.',
    'modified'       => 'I am here.[comment,escaped sequence “n”][comment,escaped sequence “f”]led.',
    'all_violations' => {
        'special' => [
            'Contains escape sequence',
        ],
        'default' => undef,
    },
    'all_warnings' => {
        'default' => [],
        'special' => undef,
    },
    'filter_violations' => {
        'special' => [
            'Contains escape sequence',
        ],
    },
    'filter_warnings' => {},    # undef means "same as all_warnings"
    'return_value'    => {
        'special' => [ 0, 1,                             0, 1 ],
        'default' => undef, # undef means "same as special"
    },
    'get_status_is_warnings' => 0,
    'diag'                   => 0,
);

{

    # Consider parser throws syntax error
    local $norm = Locale::Maketext::Utils::Phrase::Norm->new_source( qw(NonBytesStr WhiteSpace Grapheme Ampersand Markup Ellipsis BeginUpper EndPunc Escapes Compiles), { 'skip_defaults_when_given_filters' => 1 } );

    run_32_tests(
        'filter_name'    => 'Compiles',
        'filter_pos'     => 9,                                                                                # would be 10 if not special
        'original'       => 'Hello [_1',
        'modified'       => '[comment,Bracket Notation Error: Unterminated bracket group, in: Hello ~[_1]',
        'all_violations' => {
            'special' => [
                'Bracket Notation Error',
            ],
            'default' => undef,
        },
        'all_warnings' => {
            'default' => [],
            'special' => undef,
        },
        'filter_violations' => {
            'special' => [
                'Bracket Notation Error',
            ],
        },
        'filter_warnings' => {},    # undef means "same as all_warnings"
        'return_value'    => {
            'special' => [ 0, 1,                             0, 1 ],
            'default' => undef, # undef means "same as special"
        },
        'diag' => 0,
    );

    run_32_tests(
        'filter_name'    => 'Compiles',
        'filter_pos'     => 9,                                                                       # would be 10 if not special
        'original'       => 'Hello _1]',
        'modified'       => '[comment,Bracket Notation Error: Unbalanced \'~]\', in: Hello _1~]]',
        'all_violations' => {
            'special' => [
                'Bracket Notation Error',
            ],
            'default' => undef,
        },
        'all_warnings' => {
            'default' => [],
            'special' => undef,
        },
        'filter_violations' => {
            'special' => [
                'Bracket Notation Error',
            ],
        },
        'filter_warnings' => {},    # undef means "same as all_warnings"
        'return_value'    => {
            'special' => [ 0, 1,                             0, 1 ],
            'default' => undef, # undef means "same as special"
        },
        'diag' => 0,
    );

    run_32_tests(
        'filter_name'    => 'Compiles',
        'filter_pos'     => 9,                                                                                                                                                      # would be 10 if not special
        'original'       => 'Hello [i_do_not_exist]',
        'modified'       => '[comment,Bracket Notation Error: “Locale::Maketext::Utils::Mock::en” does not have a method “i_do_not_exist” in: Hello ~[i_do_not_exist~]]',
        'all_violations' => {
            'special' => [
                'Bracket Notation Error',
            ],
            'default' => undef,
        },
        'all_warnings' => {
            'default' => [],
            'special' => undef,
        },
        'filter_violations' => {
            'special' => [
                'Bracket Notation Error',
            ],
        },
        'filter_warnings' => {},    # undef means "same as all_warnings"
        'return_value'    => {
            'special' => [ 0, 1,                             0, 1 ],
            'default' => undef, # undef means "same as special"
        },
        'diag' => 0,
    );
}

# existing BN method
my $comp_filt = Locale::Maketext::Utils::Phrase::Norm->new_source( 'Compiles', { 'run_extra_filters' => 1, 'skip_defaults_when_given_filters' => 1 } );
my $comp_filt_res = $comp_filt->normalize('Hello [format_bytes,_1].');
ok( $comp_filt_res->get_status(),             "spec: Compiles.pm w/ existing BN method: RES get_status()" );
ok( !$comp_filt_res->filters_modify_string(), "spec: Compiles.pm w/ existing BN method: RES filters_modify_string()" );
is( $comp_filt_res->get_warning_count(),   0, "spec: Compiles.pm w/ existing BN method: RES get_warning_count()" );
is( $comp_filt_res->get_violation_count(), 0, "spec: Compiles.pm w/ existing BN method: RES get_violation_count()" );

my $norm_comp_filt_res = $norm->normalize('Hello [format_bytes,_1].');
ok( $norm_comp_filt_res->get_status(),             "norm: Compiles w/ existing BN method: RES get_status()" );
ok( !$norm_comp_filt_res->filters_modify_string(), "norm: Compiles w/ existing BN method: RES filters_modify_string()" );
is( $norm_comp_filt_res->get_warning_count(),   0, "norm: Compiles w/ existing BN method: RES get_warning_count()" );
is( $norm_comp_filt_res->get_violation_count(), 0, "norm: Compiles w/ existing BN method: RES get_violation_count()" );

# argument count
my $comp_filt_n = Locale::Maketext::Utils::Phrase::Norm->new_source( 'Compiles', { 'run_extra_filters' => 1, 'skip_defaults_when_given_filters' => 1 } );
my $comp_filt_n_res = $comp_filt_n->normalize('Hello [numf,_1] and [numf,_2].');
ok( $comp_filt_n_res->get_status(),             "spec: Compiles.pm w/ existing BN method (more than 1 arg): RES get_status()" );
ok( !$comp_filt_n_res->filters_modify_string(), "spec: Compiles.pm w/ existing BN method (more than 1 arg): RES filters_modify_string()" );
is( $comp_filt_n_res->get_warning_count(),   0, "spec: Compiles.pm w/ existing BN method (more than 1 arg): RES get_warning_count()" );
is( $comp_filt_n_res->get_violation_count(), 0, "spec: Compiles.pm w/ existing BN method (more than 1 arg): RES get_violation_count()" );

my $norm_filt_n_res = $norm->normalize('Hello [numf,_1] and [numf,_2].');
ok( $norm_filt_n_res->get_status(),             "norm: Compiles.pm w/ existing BN method (more than 1 arg): RES get_status()" );
ok( !$norm_filt_n_res->filters_modify_string(), "norm: Compiles.pm w/ existing BN method (more than 1 arg): RES filters_modify_string()" );
is( $norm_filt_n_res->get_warning_count(),   0, "norm: Compiles.pm w/ existing BN method (more than 1 arg): RES get_warning_count()" );
is( $norm_filt_n_res->get_violation_count(), 0, "norm: Compiles.pm w/ existing BN method (more than 1 arg): RES get_violation_count()" );

# escapes special cases
my $esc_filt = Locale::Maketext::Utils::Phrase::Norm->new_source( 'Escapes', { 'run_extra_filters' => 1, 'skip_defaults_when_given_filters' => 1 } );
my $esc_filt_res = $esc_filt->normalize('I am \x{263A}.');
is( $esc_filt_res->get_aggregate_result(), 'I am \x{263A}.', 'Escapes–leaves \x alone.' );

my $norm_res = $norm->normalize('I have escaped \\" do you?');
is( $norm_res->get_aggregate_result(), 'I have escaped [comment,escaped sequence “~[output,quot~]”] do you?', 'Escapes–detects and BN escapes previosuly aggregated escaped markup characters.' );

# No violations or warnings
my $valid = $norm->normalize('Hello World');
ok( $valid->get_status(),             "valid: RES get_status()" );
ok( !$valid->filters_modify_string(), "valid: RES filters_modify_string()" );
is( $valid->get_warning_count(),   0, "valid: RES get_warning_count()" );
is( $valid->get_violation_count(), 0, "valid: RES get_violation_count()" );

# diag explain $valid;

# No violations or warnings
$valid = $norm->normalize('Hello World …');
ok( $valid->get_status(),             "valid end …: RES get_status()" );
ok( !$valid->filters_modify_string(), "valid end …: RES filters_modify_string()" );
is( $valid->get_warning_count(),   0, "valid end …: RES get_warning_count()" );
is( $valid->get_violation_count(), 0, "valid end …: RES get_violation_count()" );

# specific case test #
my %test_case = (
    '“[_1]” is blah blah blah.' => 'allow for beginning quoted value',
    'X [_1]’s Z.'                 => 'allow BV-apostrophe-s',
    'X ([_1]) Y.'                   => 'parens BV',
    'X (Y [_1]) Z.'                 => 'parens end BV',
    'X ([_1] Y) Z.'                 => 'parens start BV',
);
for my $str ( sort keys %test_case ) {
    $valid = $norm->normalize($str);
    ok( $valid->get_status(),             "valid ($test_case{$str}): RES get_status()" );
    ok( !$valid->filters_modify_string(), "valid ($test_case{$str}): RES filters_modify_string()" );
    is( $valid->get_warning_count(),   0, "valid ($test_case{$str}): RES get_warning_count()" );
    is( $valid->get_violation_count(), 0, "valid ($test_case{$str}): RES get_violation_count()" );
}

my %bv_case = (
    'X ( [_1]) Z.'  => 'parens BV w/ space before',
    'X ([_1] ) Z.'  => 'parens BV w/ space after',
    'X ( [_1] ) Z.' => 'parens BV w/ space both',
    '[_1]x Y.'      => 'begin w/ immediate letter after',
    'W x[_1]x Y.'   => 'surrounding immediate letter',
    'W x[_1]'       => 'end w/ immediate letter before',
);
for my $bv ( sort keys %bv_case ) {
    $valid = $norm->normalize($bv);
    is( $valid->get_status(), "-1", "invalid ($bv_case{$bv}): RES get_status()" );
    ok( $valid->filters_modify_string(), "invalid ($bv_case{$bv}): RES filters_modify_string()" );
    is( $valid->get_warning_count(),   1, "invalid ($bv_case{$bv}): RES get_warning_count()" );
    is( $valid->get_violation_count(), 0, "invalid ($bv_case{$bv}): RES get_violation_count()" );
}

# we do odd concat below so we can blanket update the all class names when building the cPanel.pm recipe version
my $ep_class      = 'Locale::Maketext::Utils::Phrase::' . 'Norm::EndPunc';
my $is_title_case = $ep_class->can('__is_title_case');
ok( $is_title_case->('Click to View'),                               'title case: spec yes 1' );
ok( $is_title_case->('Preview x4 Alpha'),                            'spec yes 2' );
ok( $is_title_case->('Buy [asis,aCme™] Products'),                 'lc via asis' );
ok( $is_title_case->('Coders [comment,isa-prepostion-yo]for Peace'), 'lc vianon-WS comment' );
ok( !$is_title_case->('Faster load times'),                          'title case: spec no 1' );
ok( !$is_title_case->('Last login from'),                            'title case: spec no 2' );

{
    my @w;
    local $SIG{__WARN__} = sub { push @w, \@_; };
    $norm->normalize('[_1] X.');    # uninit value $begin
    $norm->normalize('Y[_1]');      # uninit value $after
    warn "foo\n";
    is_deeply( \@w, [ ["foo\n"] ], 'uninit value $begin/$end does not happen' );
}

#################
#### functions ##
#################

sub run_32_tests {
    my %args = @_;

    diag("Norm.pm $args{'filter_name'} filter");
    my $spec = Locale::Maketext::Utils::Phrase::Norm->new_source( $args{'filter_name'}, { 'run_extra_filters' => 1, 'skip_defaults_when_given_filters' => 1 } );

    if ( !defined $args{'return_value'}{'special'} ) {
        $args{'return_value'}{'special'} = $args{'return_value'}{'default'};
    }
    if ( !defined $args{'return_value'}{'default'} ) {
        $args{'return_value'}{'default'} = $args{'return_value'}{'special'};
    }

    for my $k ( 'violations', 'warnings' ) {
        if ( !defined $args{"all_$k"}{'special'} ) {
            $args{"all_$k"}{'special'} = $args{"all_$k"}{'default'};
        }
        if ( !defined $args{"all_$k"}{'default'} ) {
            $args{"all_$k"}{'default'} = $args{"all_$k"}{'special'};
        }

        if ( !defined $args{"filter_$k"} ) {
            $args{"filter_$k"} = $args{"all_$k"};
        }

        if ( !defined $args{"filter_$k"}{'special'} ) {
            $args{"filter_$k"}{'special'} = $args{"all_$k"}{'special'};
        }

        if ( !defined $args{"filter_$k"}{'special'} ) {
            $args{"filter_$k"}{'special'} = $args{"filter_$k"}{'default'};
        }
        if ( !defined $args{"filter_$k"}{'default'} ) {
            $args{"filter_$k"}{'default'} = $args{"filter_$k"}{'special'};
        }

        # if they are still undef then use the "all" variant
        if ( !defined $args{"filter_$k"}{'default'} ) {
            $args{"filter_$k"}{'default'} = $args{"all_$k"}{'default'};
        }
        if ( !defined $args{"filter_$k"}{'special'} ) {
            $args{"filter_$k"}{'special'} = $args{"all_$k"}{'special'};
        }
    }

    for my $o ( $norm, $spec ) {
        $res = $o->normalize( $args{'original'} );
        my $label = @{ $o->{'filters'} } == 1 ? 'special' : 'default';

        if ( $args{'diag'} ) {
            diag explain $o;
            diag explain $res;
        }

        my $violation_count = @{ $args{'all_violations'}{$label} };
        my $warning_count   = @{ $args{'all_warnings'}{$label} };

        $args{'get_status_is_warnings'} ? is( $res->get_status(), '-1', "“$args{'filter_name'}” $label: RES get_status()" ) : ok( !$res->get_status(), "“$args{'filter_name'}” $label: RES get_status()" );
        ok( $args{'filter_does_not_modify_string'} ? !$res->filters_modify_string() : $res->filters_modify_string(), "“$args{'filter_name'}” $label: RES filter_modifies_string()" );
        is( $res->get_warning_count(),    $warning_count,    "“$args{'filter_name'}” $label: RES get_warning_count()" );
        is( $res->get_violation_count(),  $violation_count,  "“$args{'filter_name'}” $label: RES get_violation_count()" );
        is( $res->get_orig_str(),         $args{'original'}, "“$args{'filter_name'}” $label: RES get_orig_str()" );
        is( $res->get_aggregate_result(), $args{'modified'}, "“$args{'filter_name'}” $label: RES get_aggregate_result()" );

        $filt = $res->get_filter_results()->[ $label eq 'special' ? 0 : $args{'filter_pos'} ];

        if ( $args{'diag'} ) {
            diag explain $filt;
        }

        $violation_count = @{ $args{'filter_violations'}{$label} };
        $warning_count   = @{ $args{'filter_warnings'}{$label} };

        # we do odd concat below so we can blanket update the all class names when building the cPanel.pm recipe version
        is( $filt->get_package(), "Locale::Maketext::Utils::Phrase::" . "Norm::$args{'filter_name'}", "“$args{'filter_name'}” $label: FILT get_package()" );
        $args{'get_status_is_warnings'} ? is( $filt->get_status(), '-1', "“$args{'filter_name'}” $label: FILT get_status()" ) : ok( !$filt->get_status(), "“$args{'filter_name'}” $label: FILT get_status()" );
        ok( $args{'filter_does_not_modify_string'} ? !$filt->filter_modifies_string() : $filt->filter_modifies_string(), "“$args{'filter_name'}” $label: FILT filter_modifies_string()" );
        is( $filt->get_warning_count(),   $warning_count,   "“$args{'filter_name'}” $label: FILT get_warning_count()" );
        is( $filt->get_violation_count(), $violation_count, "“$args{'filter_name'}” $label: FILT get_violation_count()" );
        is_deeply(
            [ $filt->return_value() ],
            $args{'return_value'}{$label},
            "“$args{'filter_name'}” $label: FILT return_value()"
        );
        is( $filt->get_orig_str(), $args{'original'}, "“$args{'filter_name'}” $label: FILT get_orig_str()" );
        is( $filt->get_new_str(),  $args{'modified'}, "“$args{'filter_name'}” $label: FILT get_aggregate_result()" );

        is_deeply(
            [ $filt->get_violations() ? @{ $filt->get_violations() } : () ],
            $args{'filter_violations'}{$label},
            "“$args{'filter_name'}” $label: FILT filter get_violations()"
        );
        is_deeply(
            [ $filt->get_warnings() ? @{ $filt->get_warnings() } : () ],
            $args{'filter_warnings'}{$label},
            "“$args{'filter_name'}” $label: FILT get_warnings()"
        );
    }

    $norm->delete_cache();
}
