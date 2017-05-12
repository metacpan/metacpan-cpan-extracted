
use Test::More tests => 11;
use File::Temp qw/ tempfile /;

use strict;
use warnings;

package DuffLineGiver;
# simple class which doesn't have a getline() method which returns the next line

sub new {
    my $class = shift;
    my $self = [];
    bless $self, $class;
}

sub addtokens {
    my $self = shift;
    for my $token (@_) {
        if (@$self==0 || $self->[-1] =~ /[\015\012]$/) {
            unshift @$self, $token;
        } else {
            $self->[-1] .= $token;
        }
    }
}

sub get_a_line {
    my $self = shift;
    pop @$self;
}

package main;

BEGIN { use_ok('Hardware::Vhdl::Tidy', qw(tidy_vhdl tidy_vhdl_file) ); }
#use Hardware::Vhdl::Tidy qw(tidy_vhdl tidy_vhdl_file) ;

{
    my $source = \"foo bar baz";
    my @dest;       
    
    eval {
        tidy_vhdl({ source => $source, destination => \@dest });
    };
    is($@, '', 'baseline: construct without error');
    
    eval {
        tidy_vhdl({ destination => \@dest });
    };
    like($@, qr/tidy_vhdl requires a 'source' parameter/ms, 'missing source arg to tidy_vhdl');
    
    eval {
        tidy_vhdl({ source => $source });
    };
    like($@, qr/tidy_vhdl requires a 'destination' parameter/ms, 'missing destination arg to tidy_vhdl');

    eval {
        tidy_vhdl({ source => "a string", destination => \@dest });
    };
    like($@, qr/tidy_vhdl 'source' parameter is not of a valid type \(it is not a reference\)/ms, 'source is not a ref');

    ok(DuffLineGiver->can('get_a_line'), 'test case self-check');
    ok(!DuffLineGiver->can('get_next_line'), 'test case self-check');

    $source = DuffLineGiver->new;
    eval {
        tidy_vhdl({ source => $source, destination => \@dest });
    };
    like($@, qr/tidy_vhdl 'source' parameter is not of a valid type \(type is 'DuffLineGiver'\)/ms, 'bad source type: object without the right method');

    eval {
        tidy_vhdl({ source => \\"hello world", destination => \@dest });
    };
    like($@, qr/tidy_vhdl 'source' parameter is not of a valid type \(type is 'REF'\)/ms, 'bad source type: scalar ref ref');

    eval {
        tidy_vhdl({ source => {hello  => "world"}, destination => \@dest });
    };
    like($@, qr/tidy_vhdl 'source' parameter is not of a valid type \(type is 'HASH'\)/ms, 'bad source type: hash ref');
}

ok( 1, 'End of tests' );

sub string_to_file {
    my $string = shift;
    my $fh = tempfile;
    binmode $fh;
    print $fh $string;
    seek $fh, 0, 0;
    $fh;
}
