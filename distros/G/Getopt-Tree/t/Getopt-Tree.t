# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Getopt-Tree.t'
use Test::More qw/ no_plan /;

use strict;
use lib '../lib';
use Getopt::Tree;

sub call_with_slurped_pipe {
    my ( $callme ) = @_;
    my ( $usage_reader, $usage_writer );

    pipe( $usage_reader, $usage_writer );
    ok( $usage_writer );

    select $usage_writer;
    $|++;
    select STDOUT;
    local $/ = undef;

    $callme->($usage_writer);
    close( $usage_writer );
    my $r = <$usage_reader>;
    close( $usage_reader );
    return $r;
}

sub test_parse_command_line {
    my ( $params, $cli ) = @_;

    local @ARGV = split( m/ +/, $cli );
    local $SIG{__WARN__} = sub {};
    my ( $op, $config ) = parse_command_line( $params );
    ok( $op && $config, $cli );
    return ( $op, $config );
}

#########################

use constant STATUS_REGEX => qr/(OPEN|CLOSED|HOLD)/;
use constant TICKET_REGEX => qr/(\d+)/;

my $p;
{
    my $param_status_sub = sub {
        my ( $v ) = @_;
        if   ( $v =~ /hold/i ) { return 'On Hold' }
        else                   { return ucfirst( lc( $v ) ) }
    };

    $p = [
        { name => 'debug', abbr => 'd', exists => 1, optional => 1, descr => 'Enable debugging output.' },
        {
            name     => 'user',
            abbr     => 'u',
            optional => 1,
            descr    => 'Ticketing username, defaults to scalar(getpwuid($<)).'
        },
        {
            name     => 'no-cache',
            abbr     => 'nc',
            exists   => 1,
            optional => 1,
            descr    => 'Don\'t cache your credentials in /tmp/.'
        },
        {
            name     => 'qa',
            exists   => 1,
            optional => 1,
            descr    => 'Connect to the test system instead of the prod system.'
        },
        {
            name     => 'help',
            abbr     => 'h',
            exists   => 1,
            descr    => 'Print usage information.',
        },
        {
            name   => 'search',
            abbr   => 's',
            descr  => 'Search for ticket, list tickets in queue, or print contents of a ticket.',
            exists => 1,
            params => [{
                    name   => 'ticket',
                    abbr   => 't',
                    re     => TICKET_REGEX,
                    descr  => 'The ticket number to search for.',
                    params => [{
                            name     => 'show-all-fields',
                            exists   => 1,
                            optional => 1,
                            descr    => 'Show all ticket fields.'
                        },
                        {
                            name     => 'show-worklog',
                            abbr     => 'w',
                            exists   => 1,
                            optional => 1,
                            descr    => 'Display the ticket\'s worklog.',
                            params   => [{
                                    name     => 'show-all-worklog-fields',
                                    exists   => 1,
                                    optional => 1,
                                    descr    => 'Show all worklog fields.'
                                }
                            ],
                        },
                        {
                            name     => 'shrink-whitespace',
                            abbr     => 'sw',
                            exists   => 1,
                            optional => 1,
                            descr    => 'Compress multiple newlines to a single newline for display.',
                        },
                    ]
                },
                {
                    name => 'id',
                    descr => 'Search by ticket ID number',
                },
                {
                    name => 'queue',
                    abbr => 'q',
                    descr =>
                     'The name of the queue to search in. By default, only non-closed tickets are shown.',
                    params => [{
                            name => 'status',
                            re   => STATUS_REGEX,
                            eval => $param_status_sub,
                            descr =>
                             'Show tickets with the requested status (unassigned, assigned, closed, hold).',
                            optional => 1
                        }]
                },
                {
                    name   => 'requestor',
                    descr  => 'Search by requestor.',
                    params => [{
                            name => 'status',
                            descr =>
                             'Show tickets with the requested status (unassigned, assigned, closed, hold).',
                            re       => STATUS_REGEX,
                            eval     => $param_status_sub,
                            optional => 1,
                        }]
                },
            ]
        },
        {
            name   => 'edit',
            abbr   => 'e',
            re     => TICKET_REGEX,
            descr  => 'Given a ticket number, edit / add a worklog interactively.',
            params => [{
                    name     => 'show-all-worklog-fields',
                    exists   => 1,
                    optional => 1,
                    descr    => 'Show all worklog fields.'
                }]
        },
        {
            name   => 'update',
            abbr   => 'u',
            descr  => 'Update specified ticket fields.',
            re     => TICKET_REGEX,
            params => [{
                    name     => 'field',
                    abbr     => 'f',
                    descr    => 'Given \'field=value\', sets the given field to the given value. Can be set multiple times. Note: Field names are case-sensitive.',
                    multi    => 1
                },
            ]
        },
        {
            name => 'new',
            abbr => 'n',
            descr => 'Create a new ticket with the specified ticket fields.',
            exists => 1,
            params => [{
                name     => 'field',
                abbr     => 'f',
                descr    => 'Given \'field=value\', sets the given field to the given value. Can be set multiple times. Note: Field names are case-sensitive.',
                multi    => 1,
                optional => 1,
                exists   => 1,
            },
            {
                name => 'stdin',
                abbr => 't',
                descr => 'read from stdin!',
                exists => 1,
            }
            ],
        }
    ];
}

$Getopt::Tree::USAGE_HEADER = "Header test!\n";
$Getopt::Tree::USAGE_FOOTER = "Footer test!\n";

# I don't know a good way to tes this output other than by testing it against
# a hard-coded string. For now, just check parts. The module should wrap text
# at 80 columns when STDOUT isn't a TTY, which is the case when run from here,
# so we should expect the output below to be wrapped.
my $usage = call_with_slurped_pipe( sub { print_usage( $p, $_[0] ); } );
ok( $usage =~ /Header test!/ );
ok( $usage =~ /Footer test!/ );
# Message truncated here to match wrapped text
ok( $usage =~ /Create a new ticket with the specified$/m );

my ( $o, $c );

test_parse_command_line( $p, '-s -t 1234' );
test_parse_command_line( $p, '-n -t' );

( $o, $c ) = test_parse_command_line( $p, '-e 234' );
ok( $o eq 'edit', 'edit op' );
ok( $c->{edit} == 234, 'edit config' );

( $o, $c ) = test_parse_command_line( $p, '-s -q tacos -status OPEN' );
ok( $o eq 'search', 'search op' );
ok( $c->{queue} eq 'tacos', 'search config queue' );
ok( $c->{status} eq 'Open', 'search config status' );

