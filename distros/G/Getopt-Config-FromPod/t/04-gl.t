use Test::More;
use Test::Exception;

eval 'use Getopt::Long';
plan skip_all => "Getopt::Long required for this test" if $@;

plan tests => 9;

use_ok 'Getopt::Config::FromPod';

@ARGV = qw(--help);
my $opt = { port => 79 };
GetOptions($opt, Getopt::Config::FromPod->new->array);

is($opt->{help}, 1, 'help with --help');
is($opt->{port}, 79, 'port with --help');
is(scalar keys %$opt, 2, 'options with --help'); # 1 for port with default

$opt = { port => 79 };
@ARGV = qw(-s localhost -p 8888 -v);
GetOptions($opt, Getopt::Config::FromPod->new->array);
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

=for getopt 'server|s=s'

=item C<--port|p=$port>

Specify the port to connect to. Defaults to 79.

=for getopt 'port|p=i'

=item C<--verbose|v>

Print extra stuff.

=for getopt 'verbose|v'

=item C<--help>

Print useage message and exit

=for getopt 'help'

=back
