use Test::More;
use Test::Exception;

eval 'use Getopt::Long::Descriptive';
plan skip_all => "Getopt::Long::Descriptive required for this test" if $@;

plan tests => 10;

use_ok 'Getopt::Config::FromPod';

@ARGV = qw(--help);
my @arg = ('my-program %o <some-arg>', Getopt::Config::FromPod->new->array);
my ($opt, $usage) = describe_options(@arg);

my $help = qr/my-program \[-psv\] \[long options\.\.\.\] <some-arg>
\t-s(\s+STR)?\s+--server(\s+STR)?\s+the server to connect to
\t-p(\s+INT)?\s+--port(\s+INT)?\s+the port to connect to
\s*
\t-v\s+--verbose\s+print extra stuff
\t--help\s+print usage message and exit/;
like($usage->text, $help, 'usage text');
is($opt->{help}, 1, 'help with --help');
is($opt->{port}, 79, 'port with --help');
is(scalar keys %$opt, 2, 'options with --help'); # 1 for port with default

@ARGV = qw(-s localhost -p 8888 -v);
($opt, $usage) = describe_options(@arg);
is($opt->{help}, undef, 'help');
is($opt->{server}, 'localhost', 'server');
is($opt->{port}, 8888, 'port');
is($opt->{verbose}, 1, 'verbose');
is(scalar keys %$opt, 3, 'options');

__END__

=head1 OPTIONS

=over 4

=item C<--server|-s=$server>

Specify the server to connect to.

=for getopt [ 'server|s=s', "the server to connect to"                  ]

=item C<--port|p=$port>

Specify the port to connect to. Defaults to 79.

=for getopt [ 'port|p=i',   "the port to connect to", { default => 79 } ]

=for getopt []

=item C<--verbose|v>

Print extra stuff.

=for getopt [ 'verbose|v',  "print extra stuff"            ]

=item C<--help>

Print useage message and exit

=for getopt [ 'help',       "print usage message and exit" ]

=back
