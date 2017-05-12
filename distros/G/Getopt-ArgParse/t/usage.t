use lib "lib";
use Test::More; # tests => 4;
use Test::Exception;

use Getopt::ArgParse::Parser;

my $parser = Getopt::ArgParse::Parser->new(
    prog => 'usage.t',
    description => 'This is the suite that contains usage message test cases',
);

ok($parser);

$parser->add_argument('--foo', '-f');

$parser->add_argument('--boo', type => 'Bool');

$parser->add_argument('--nboo', type => 'Bool');

$parser->add_argument('--verbose', '-v', type => 'Bool');

throws_ok (
    sub { $parser->add_argument('--verbose', type => 'Count'); },
    qr/Redefine option verbose without reset/,
    'redefine option'
);

$parser->add_argument('--verbose', type => 'Count', reset => 1);
$parser->add_argument('--email', required => 1);

$parser->add_argument('--email2', '--e2', required => 1);

throws_ok(
  sub {  $parser->add_argument('boo', required => 1); },
  qr/used by an optional/,
  'dest=boo is used',
);

$parser->add_argument('boo', required => 1, dest => 'boo_post');

$parser->add_argument('boo2', type => 'Pair', required => 1, default => { a => 1, 3 => 90 });


# subcommands

$parser->add_subparsers(title => 'Some subcommands', description => 'there are some subcommands');

$sp = $parser->add_parser(
    'list',
    aliases => [qw(ls)],
    help => 'this is the list subcommand message',
    description =><<'EOS',
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum ac
diam iaculis, consectetur nunc sit amet, vulputate lacus. Suspendisse
vitae felis nisl. Sed posuere aliquet placerat. Nunc eget sollicitudin
eros, quis porta nunc. Mauris laoreet lacinia aliquet. Cras porttitor
erat ac elit semper blandit. Vestibulum porttitor nulla id nisl
eleifend venenatis. In hac habitasse platea dictumst. Cras ut leo
rhoncus, bibendum lectus at, hendrerit tortor. Etiam congue ligula
magna, nec malesuada lorem semper ac.

Sed luctus malesuada felis, in mollis lectus aliquam ut. Ut adipiscing
massa id felis interdum semper sit amet in leo. Morbi imperdiet
fringilla sodales. Donec at ipsum eu lorem lacinia pharetra eu non
quam. Duis a porttitor nulla. In hac habitasse platea dictumst. Aenean
hendrerit sit amet quam nec malesuada. Vivamus lobortis placerat diam,
a lobortis ante sollicitudin vel. Cras ullamcorper enim urna, non
dignissim velit iaculis id. Sed odio libero, hendrerit sed blandit
eget, luctus ut velit. Suspendisse lobortis ullamcorper magna at
tincidunt. In hac habitasse platea dictumst. Curabitur accumsan, massa
vitae rutrum euismod, quam purus ultrices lectus, sed sodales metus
sem sed nulla. Vestibulum tincidunt ligula eget enim pulvinar, non
condimentum turpis dignissim. Maecenas sed nulla eu lorem dictum
semper. Nulla fringilla egestas nibh vitae blandit.

In vitae arcu accumsan turpis commodo varius. Pellentesque id massa
ligula. Vestibulum pharetra, metus in semper rutrum, odio urna
vulputate magna, nec tristique sem arcu sit amet dui. Suspendisse nec
risus consequat, rhoncus tellus vitae, tincidunt augue. Suspendisse
cursus felis nulla, non luctus lorem pharetra quis. Nunc pulvinar
lectus enim, sit amet interdum felis ultrices vel. Vestibulum neque
metus, condimentum eget convallis nec, euismod vitae nunc. Proin
sagittis ullamcorper risus, vel rutrum turpis posuere eu.
EOS
);

$sp->add_argument(
    'name',
    help => 'positional NAME',
    required => 1
);

$sp->add_argument(
    'name2',
    help => 'positional NAME2',
);

$sp->add_argument(
    '--foo', '-f',
    help => 'subcommand foo',
);

$sp->add_argument(
    '--boo', '-b',
    help => 'subcommand boo',
    required => 1,
);

$parser->print_usage();

print STDERR $_, "\n" for @{ $parser->format_command_usage('ls') };

done_testing;

__END__

my $ns = $parser->parse_args(
    '-h',
    '-f', 100,
    '--verbose', 'left', '--verbose',
    '--email', 'a@b', 'c@b', 'a@b', 1, 2,
    '--verbose', 123, '--verbose',
    '--boo', 3,
    '-e2', 'e2@e2', 9999
);

$\ = "\n";

print $ns->foo;

print $ns->nboo;

print $ns->boo;

print $ns->verbose;

print "email: ", join(', ', $ns->email);

print "argv: ", join(', ', @{$parser->{-argv}});

done_testing;

1;
