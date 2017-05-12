#!perl

use strict;
use warnings;

use Test::More;
use Test::Differences;
use Carp qw(confess);
use Cwd qw(getcwd chdir);
use English qw(-no_match_vars $OS_ERROR $INPUT_RECORD_SEPARATOR $CHILD_ERROR);

$ENV{AUTHOR_TESTING} 
    or plan skip_all => 'Set $ENV{AUTHOR_TESTING} to run this test.';

plan tests => 2;

my @data = (
    {
        test       => '01_example',
        path       => 'example',
        filename   => '01_example.pl',
        params     => '-I../lib',
        cmd_result => <<'EOT',
01_example.pl [-?hv] [long options...] <some-arg>
    -v --verbose  Print extra stuff. And here I show, how to work with
                  lots of lines as floating text.

    -? -h --help  Print usage message and exit.
EOT
        result     => <<'EOT',
    #!perl ## no critic (TidyCode)

    use strict;
    use warnings;

    our $VERSION = 0;

    use Carp qw(confess);
    use Const::Fast qw(const);
    use English qw(-no_match_vars $OS_ERROR);
    use Getopt::Long::Descriptive;
    use Getopt::Long::DescriptivePod;

    const my $INDENT => 4;

    my ($opt, $usage) = describe_options(
        '01_example.pl %o <some-arg>',
        [ 'verbose|v', trim_lines( <<'EOT' ) ],
            Print extra stuff.
            And here I show, how to work
            with lots of lines as floating text.
    EOT
        [], # an empty line
        [ 'help|h|?', 'Print usage message and exit.' ],
    );

    if ( $opt->{help} ) {
        () = print $usage;
        replace_pod({
            tag               => '=head1 USAGE',
            indent            => $INDENT,
            before_code_block => trim_lines( <<'EOT', $INDENT ),
                This is floating text in Pod before that code
                block with the usage inside.
    EOT
            code_block        => $usage->text,
            # Here indent counts the groups of spaces of the first line
            # and removes that at all next lines.
            # 4 space code ident instead if 1 space works with floating text before.
            after_code_block  => trim_lines( <<'EOT', $INDENT ),
                This is floating text in Pod after that code
                block with the usage inside.

                    this_is_code_in_pod(
                        1,
                    );
    EOT
        });
    }

    # $Id: $

    __END__

    =head1 NAME

    for test only

    =head1 USAGE

    This is floating text in Pod before that code
    block with the usage inside.

        01_example.pl [-?hv] [long options...] <some-arg>
            -v --verbose  Print extra stuff. And here I show, how to work with
                          lots of lines as floating text.

            -? -h --help  Print usage message and exit.

    This is floating text in Pod after that code
    block with the usage inside.

        this_is_code_in_pod(
            1,
        );

    =head1 DESCRIPTION

    =head1 REQUIRED ARGUMENTS

    =head1 OPTIONS

    =head1 DIAGNOSTICS

    =head1 EXIT STATUS

    =head1 CONFIGURATION

    =head1 DEPENDENCIES

    =head1 INCOMPATIBILITIES

    =head1 BUGS AND LIMITATIONS

    =head1 AUTHOR

    =head1 LICENSE AND COPYRIGHT
EOT
    },
);

for my $data (@data) {
    my $current_dir = getcwd();
    my $example_dir = "$current_dir/$data->{path}";
    chdir $example_dir;

    local $INPUT_RECORD_SEPARATOR = ();

    open my $file_handle, q{<}, $data->{filename}
        or confess "$data->{test} read $data->{filename} $OS_ERROR";
    my $old_content = <$file_handle>;
    () = close $file_handle;

    my $cmd_result = qx{perl $data->{params} $data->{filename} --help 2>&1};
    $CHILD_ERROR
        and die "Couldn't run $data->{filename} (status $CHILD_ERROR)";

    open $file_handle, q{<}, $data->{filename}
        or confess "$data->{test} read $data->{filename} $OS_ERROR";
    my $new_content = <$file_handle>;
    () = close $file_handle;

    eq_or_diff
        do {
            $cmd_result =~ s{ \t }{ q{ } x 4 }xmsge;
            $cmd_result =~ s{ [ ]+ $ }{}xmsg;
            $cmd_result;
        },
        $data->{cmd_result},
        "$data->{test} untabified and right trimmed cmd result";
    eq_or_diff
        $new_content,
        do {
            $data->{result} =~ s{^ [ ]{4} }{}xmsg;
            $data->{result};
        },
        "$data->{test} content";

    open $file_handle, q{>}, $data->{filename}
        or confess "$data->{test} write $data->{filename} $OS_ERROR";
    print {$file_handle} $old_content
        or confess "$data->{test} write $data->{filename} $OS_ERROR";
    close $file_handle
        or confess "$data->{test} write $data->{filename} $OS_ERROR";

    chdir $current_dir;
}
