# Copyright (c) 2012, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use Mail::Alias::Reader         ();
use Mail::Alias::Reader::Token  ();
use Mail::Alias::Reader::Parser ();

use Test::More ( 'tests' => 18 );
use Test::Exception;

sub open_reader {
    my ( $mode, @statements ) = @_;

    pipe my ( $out, $in ) or die("Unable to pipe(): $!");
    my $pid = fork();

    if ( $pid == 0 ) {
        close($out);

        foreach my $statement (@statements) {
            print {$in} "$statement\n";
        }

        exit(0);
    }
    elsif ( !defined($pid) ) {
        die("Unable to fork(): $!");
    }

    close($in);

    my $reader = Mail::Alias::Reader->open(
        'handle' => $out,
        'mode'   => $mode
    );

    return ( $reader, $pid );
}

#
# Coverage for aliases(5) mode
#
{
    my %TESTS = (
        'foo: bar, baz' => sub {
            my ( $name, $destinations ) = $_[0]->read;

            is( $name, 'foo', "Alias name in '$_[1]' is '$name'" );
        },

        'bar baz' => sub {
            my ( $reader, $statement ) = @_;

            throws_ok {
                $reader->read;
            }
            qr/Alias statement has no name/, "'$statement' produces an error";
        },

        '/dev/null: this, will, not, work' => sub {
            my ($reader) = @_;

            throws_ok {
                $reader->read;
            }
            qr/Expected address as name of alias/, "Mail::Alias::Reader::Parser needs an address as name of alias";
        },

        'this, should, : not, work' => sub {
            my ($reader) = @_;

            throws_ok {
                $reader->read;
            }
            qr/Unexpected colon/, "Mail::Alias::Reader::Parser is intolerant of misplaced colons";
        },

        'this: should: not: work' => sub {
            my ($reader) = @_;

            throws_ok {
                $reader->read;
            }
            qr/Too many colons/, "Mail::Alias::Reader::Parser is intolerant of multiple colons";
        },

        'this: should,,work' => sub {
            my ($reader) = @_;

            lives_ok {
                $reader->read;
            }
            "Mail::Alias::Reader::Parser is tolerant of consecutive commas in aliases(5) statement";
        },

        'this, should, fail:' => sub {
            my ($reader) = @_;

            throws_ok {
                $reader->read;
            }
            qr/Unexpected end of alias/, "Mail::Alias::Reader::Parser wants a value at the end of statement";
        },

        'this: , should, fail' => sub {
            my ($reader) = @_;

            throws_ok {
                $reader->read;
            }
            qr/Unexpected comma/, "Mail::Alias::Reader::Parser does not tolerate commas after name:";
        },

        'this: should, pass,' => sub {
            my ($reader) = @_;

            lives_ok {
                $reader->read;
            }
            "Mail::Alias::Reader::Parser tolerates aliases(5) statements ending with commas";
        },
    );

    my @STATEMENTS = keys %TESTS;
    my ( $reader, $pid ) = open_reader( 'aliases', @STATEMENTS );

    foreach my $statement (@STATEMENTS) {
        my $test = $TESTS{$statement};

        $test->( $reader, $statement );
    }

    $reader->close;

    waitpid( $pid, 0 );
}

#
# Coverage for ~/.forward mode
#
{
    my %TESTS = (
        'foo, bar, baz' => sub {
            my ( $reader, $statement ) = @_;
            my $destinations = $reader->read;

            is( $destinations->[1]->{'value'}, 'bar', "Second destination in '$statement' is 'bar'" );
        },

        'foo: cats' => sub {
            my ($reader) = @_;

            throws_ok {
                $reader->read;
            }
            qr/Unexpected T_COLON/, "Parsing in 'forward' mode will not allow aliases(5) names";
        },

        'foo bar baz' => sub {
            my ($reader) = @_;

            throws_ok {
                $reader->read;
            }
            qr/Unexpected value/, "Values in 'forward' mode not separate by commas are illegal";
        },

        'foo,,bar' => sub {
            my ($reader) = @_;

            lives_ok {
                $reader->read;
            }
            "Consecutive commas in 'forward' mode are illegal";
        },

        'foo,' => sub {
            my ($reader) = @_;

            lives_ok {
                $reader->read;
            }
            "Comma at end of statement in 'forward' mode is tolerated";
        },

        ',' => sub {
            my ($reader) = @_;

            throws_ok {
                $reader->read;
            }
            qr/Unexpected comma/, "Commas outside the context of destinations are illegal";
        },
    );

    my @STATEMENTS = keys %TESTS;
    my ( $reader, $pid ) = open_reader( 'forward', @STATEMENTS );

    foreach my $statement ( keys %TESTS ) {
        my $test = $TESTS{$statement};

        $test->( $reader, $statement );
    }

    $reader->close;

    waitpid( $pid, 0 );
}

#
# Some more in-depth coverage of internal details of ~/.forward parsing mode
#
{
    my @tokens = map { Mail::Alias::Reader::Token->new($_) } qw(T_BEGIN T_WHITESPACE);

    throws_ok {
        Mail::Alias::Reader::Parser::_parse_forward_statement( \@tokens );
    }
    qr/Statement contains no destinations/, "Mail::Alias::Reader::Parser expects forward statements to have values";
}

#
# Internal details of aliases(5) parsing mode
#
{
    throws_ok {
        my @tokens = map { Mail::Alias::Reader::Token->new($_) } qw(T_BEGIN T_ADDRESS T_COLON T_STRING T_END);

        Mail::Alias::Reader::Parser::_parse_aliases_statement( \@tokens );
    }
    qr/Unexpected T_STRING/, "Mail::Alias::Reader::Parser freaks out if it receives an unprocessed T_STRING";
}

#
# Trying really hard to trip up the parser
#
{
    throws_ok {
        Mail::Alias::Reader::Parser->parse( 'foo', 'bar' );
    }
    qr/Invalid parsing mode/, "Mail::Alias::Reader::Parser likes to have a valid parsing mode passed";
}
