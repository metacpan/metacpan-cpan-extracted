use strict;
use warnings;
use autodie;
use Test::More;
use Test::Warn;

BEGIN { use_ok('Makefile::Update::Makefile'); }

sub do_update
{
    my ($instr, $vars) = @_;

    open my $out, '>', \my $outstr;
    open my $in, '<', \$instr;

    update_makefile($in, $out, $vars)
}

warning_like {
        do_update(<<'EOF',
sources = \
      file1.c \
    file2.c
EOF
            { sources => [] }
        )
    }
    qr/^Inconsistent indent.*/,
    'inconsistent indent warning given';

warning_like {
        do_update(<<'EOF',
sources = \
      file.c \
      file.c
EOF
            { sources => [qw(file.c)] }
        )
    }
    qr/^Duplicate file.*/,
    'duplicate file warning given';

warning_like {
        do_update(<<'EOF',
sources = \
      file.c \
# comment after line continuation
EOF
            { sources => [qw(file.c)] }
        )
    }
    qr/^Expected blank line.*/,
    'missing blank line warning given';

warning_like {
        do_update(<<'EOF',
sources = file.c
EOF
            { sources => [qw(file.c)] }
        )
    }
    qr/^Unsupported format for variable.*/,
    'variable format warning given';

done_testing()
