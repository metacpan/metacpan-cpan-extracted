use strict;
use Test::More tests => 6;
use MIME::Expander::Guess::MMagic;

sub read_file {
    my $src = shift;
    open IN, "<$src" or die "cannot open $src: $!";
    local $/ = undef;
    my $data = <IN>;
    close IN;
    return \ $data;
}

is( MIME::Expander::Guess::MMagic->type( read_file('t/untitled.txt') ),
    'text/plain', 'type plain' );

is( MIME::Expander::Guess::MMagic->type( read_file('t/untitled.pdf') ),
    'application/pdf', 'type pdf' );

like( MIME::Expander::Guess::MMagic->type( read_file('t/untitled.tar.bz2') ),
    qr'application/(x-)?bzip2', 'type bz2' );

like( MIME::Expander::Guess::MMagic->type( read_file('t/untitled.tar.gz') ),
    qr'application/(x-)?gzip', 'type gzip' );

like( MIME::Expander::Guess::MMagic->type( read_file('t/untitled.tar') ),
    qr'application/(x-)?tar', 'type tar' );

like( MIME::Expander::Guess::MMagic->type( read_file('t/untitled.zip') ),
    qr'application/(x-)?zip', 'type zip' );
