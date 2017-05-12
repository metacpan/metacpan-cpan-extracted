#!perl

use strict;
use warnings;

use Test::More tests => 7;
use Test::NoWarnings;
use Test::Exception;
use Test::Differences;

BEGIN {
    use_ok 'Getopt::Long::Descriptive';
    use_ok 'Getopt::Long::DescriptivePod';
}

my $extra_space 
    = $Getopt::Long::Descriptive::VERSION >= 0.100 ? q{}
    : $Getopt::Long::Descriptive::VERSION >= 0.099 ? q{  }
    :                                                q{ };

my $content = <<'EOT' . 'bla';
=head1 FOO
foo
=head1 USAGE
=head1 BAR
EOT

my ($opt, $usage);
lives_ok
    sub {
        ($opt, $usage) = describe_options(
            'my-program %o <some-arg>',
            [ 'verbose|v', 'print extra stuff'            ],
            [],
            [ 'help',      'print usage message and exit' ],
        );
    },
    'describe_options';

lives_ok
    sub {
        replace_pod({
            filename   => \$content,
            tag        => '=head1 USAGE',
            code_block => $usage->text,
            indent     => 4,
            on_verbose => sub {
                my $message = shift;
                $message =~ tr{\n}{ };
                note $message;
                ok 1, $message;
            },
        });
    },
    'replace_pod';

eq_or_diff $content, <<"EOT" . 'bla', 'usage in Pod';
=head1 FOO
foo
=head1 USAGE

    my-program [-v] [long options...] <some-arg>
        -v --verbose  ${extra_space}print extra stuff

        --help        ${extra_space}print usage message and exit

=head1 BAR
EOT
;
