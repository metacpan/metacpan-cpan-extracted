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
