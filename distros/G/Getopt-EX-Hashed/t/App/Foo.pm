package App::Foo;

use strict;
use warnings;
use Data::Dumper;

use Getopt::EX::Hashed;

has string   => ( spec => '=s' );
has say      => ( spec => '=s', default => "Hello" );
has number   => ( spec => '=i' );
has implicit => ( spec => ':42' );
has start    => ( spec => '=i s begin' );
has finish   => ( spec => '=i f end' );
has tricia   => ( spec => 'trillian=s' );
has zaphord  => ( spec => '', alias => 'beeblebrox' );
has so_long  => ( spec => '' );
has list     => ( spec => '=s@' );
has hash     => ( spec => '=s%' );

# imcremental coderef
has [ qw( left right both ) ] => ( spec => '=i' );
has '+both' => default => sub {
    $_->{left} = $_->{right} = $_[1];
};

# erroneous incremental usage: live or die?
if (our $WRONG_INCREMENTAL) {
    has '+no_no_no' => default => 1;
}

if (our $TAKE_IT_ALL) {
    has ARGV => default => [];
    has '<>' => default => sub {
	push @{$_->{ARGV}}, $_[0];
    };
}

no Getopt::EX::Hashed;

sub run {
    my $app = shift;
    local @ARGV = @_;
    use Getopt::Long;
    $app->getopt or die;
    return @ARGV;
}

1;
