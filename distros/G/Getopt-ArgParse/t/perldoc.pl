use Getopt::ArgParse;

use feature 'say';

$ap = Getopt::ArgParse->new_parser(
 	prog        => 'MyProgramName',
 	description => 'This is a program',
    epilog      => 'This appears at the botton of usage',
);

 # Parse an option: '--foo value' or '-f value'
 $ap->add_argument('--foo', '-f', required => 1);

 # Parse a boolean: '--bool' or '-b' using a different name from
 # the option
 $ap->add_argument('--bool', '-b', type => 'Bool', dest => 'boo');

 # Parse a positonal option.
 # But in this case, better using subcommand. See below
$ap->add_argument('command', required => 1);

 # $ns is also accessible via $ap->namespace
my $ns = $ap->parse_args(split(' ', 'test -f 1 -b'));

say $ns->command; # 'test'
say $ns->foo;     # 1
say $ns->boo;     # 1
say $ns->no_boo;   # false - 'no_' is added for boolean options

 # You can continue to add arguments and parse them again
 # $ap->namespace is accumulatively populated


# Parse an Array type option and split the value into an array of values
$ap->add_argument('--emails', type => 'Array', split => ',');
$ns = $ap->parse_args(split(' ', '--emails a@perl.org,b@perl.org,c@perl.org'));
# Because this is an array option, this allows you to specify the
# option multiple times
$ns = $ap->parse_args(split(' ', '--emails a@perl.org,b@perl.org --emails c@perl.org'));
say join('|', $ns->emails); # a@perl.org|b@perl.org|c@perl.org

# Parse an option as key,value pairs
$ap->add_argument('--param', type => 'Pair', split => ',');
$ns = $ap->parse_args(split(' ', '--param a=1,b=2,c=3'));

say $ns->param->{a}; # 1
say $ns->param->{b}; # 2
say $ns->param->{c}; # 3

# You can use choice to restrict values
$ap->add_argument('--env', choices => [ 'dev', 'prod' ]);

# or use case-insensitive choices
# Override the previous option
$ap->add_argument('--env', choices_i => [ 'dev', 'prod' ], reset => 1);

# or use a coderef
# Override the previous option
$ap->add_argument(
 	'--env',
 	choices => sub {
 		die "--env invalid values" if $_[0] !~ /^(dev|prod)$/i;
 	},
    reset => 1,
);

 # subcommands
$ap->add_subparsers(title => 'subcommands'); # Must be called to initialize subcommand parsing
$list_parser = $ap->add_parser(
    'list',
    help => 'List directory entries',
    description => 'A multiple paragraphs long description.',
);

$list_parser->add_arguments(
    [
        '--verbose', '-v',
        type => 'Count',
        help => 'Verbosity',
    ],
    [
        '--depth',
        help => 'depth',
    ],
);

$ns = $ap->parse_args(split(' ', 'list -v'));

say $ns->current_command();  # current_command stores list,
# Don't use this name for your own option

$ns =$ap->parse_args(split(' ', 'help list')); # This will print the usage for the list command
# help subcommand is automatically added for you
say $ns->help_command();        # list

 # Copy parsing
 $common_args = Getopt::ArgParse->new_parser();
 $common_args->add_arguments(
   [
     '--dry-run',
      type => 'Bool',
      help => 'Dry run',
   ],
 );

 $sp = $ap->add_parser(
   'remove',
   aliases => [qw(rm)],           # prog remove or prog rm
   parents => [ $command_args ],  # prog rm --dry-run
 );

 # Or copy explicitly
 $sp = $ap->add_parser(
   'copy',
   aliases => [qw(cp)],           # prog remove or prog rm
 );

 $sp->copy_args($command_parser); # You can also copy_parsers() but in this case
                                  # $common_parser doesn't have subparsers
1;

