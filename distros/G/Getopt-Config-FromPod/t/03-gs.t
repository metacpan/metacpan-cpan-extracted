use Test::More;
use Test::Exception;

eval 'use Getopt::Std';
plan skip_all => "Getopt::Std required for this test" if $@;

plan tests => 9;

use_ok 'Getopt::Config::FromPod';

@ARGV = qw(-h);
my $opt = {};
getopts(Getopt::Config::FromPod->new->string, $opt);

is($opt->{h}, 1, 'help with -h');
is($opt->{p}, undef, 'port with -h');
is(scalar keys %$opt, 1, 'options with -h');

@ARGV = qw(-s localhost -p 8888 -v);
$opt = {};
getopts(Getopt::Config::FromPod->new->string, $opt);
is($opt->{h}, undef, 'help');
is($opt->{s}, 'localhost', 'server');
is($opt->{p}, 8888, 'port');
is($opt->{v}, 1, 'verbose');
is(scalar keys %$opt, 3, 'options');

__END__

=head1 OPTIONS

=over 4

=item C<-s $server>

Specify the server to connect to.

=for getopt 's:'

=item C<-p $port>

Specify the port to connect to. Defaults to 79.

=for getopt 'p:'

=item C<-v>

Print extra stuff.

=for getopt 'v'

=item C<-h>

Print useage message and exit

=for getopt 'h'

=back

