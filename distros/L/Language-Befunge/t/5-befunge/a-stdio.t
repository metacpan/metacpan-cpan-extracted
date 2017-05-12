#!perl
#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

# -- basic i/o

use strict;
use warnings;

use Test::More tests => 13;
use Test::Output;

use IO::Handle;
use Language::Befunge;
use Language::Befunge::IP;
my $bef = Language::Befunge->new;


# ascii output
$bef->store_code( <<'END_OF_CODE' );
ff+7+,q
END_OF_CODE
stdout_is { $bef->run_code } '%', 'ascii output';
# output error
{
    # printing to a closed filehandle issues a warning
    local $SIG{__WARN__} = sub {};

    # change stdout to a closed filehandle
    my $fh = IO::Handle->new;
    $fh->close;
    my $stdout = select $fh;

    # try to print, which should raise an error
    my $ip = Language::Befunge::IP->new;
    $ip->set_delta( Language::Befunge::Vector->new(1,0) );
    $ip->spush( 65 );
    $bef->set_curip($ip);
    $bef->get_ops->{','}->($bef);
    is( $ip->get_delta, '(-1,0)', 'output error reverse ip delta' );

    # select back the old stdout
    select $stdout;
}


# number output
$bef->store_code( <<'END_OF_CODE' );
f.q
END_OF_CODE
stdout_is { $bef->run_code } '15 ', 'number output';
# output error
{
    # printing to a closed filehandle issues a warning
    local $SIG{__WARN__} = sub {};

    # change stdout to a closed filehandle
    my $fh = IO::Handle->new;
    $fh->close;
    my $stdout = select $fh;

    # try to print, which should raise an error
    my $ip = Language::Befunge::IP->new;
    $ip->set_delta( Language::Befunge::Vector->new(1,0) );
    $ip->spush( 65 );
    $bef->set_curip($ip);
    $bef->get_ops->{'.'}->($bef);
    is( $ip->get_delta, '(-1,0)', 'output error reverse ip delta' );

    # select back the old stdout
    select $stdout;
}


# not testing input.
# if somebody know how to test input programatically...


# file input
$bef->store_code( <<'END_OF_CODE' );
v q.2 i v# "/dev/a_file_that_probably_does_not_exist"0 <
>                 ;vector; 3 6   ;flag; 0              ^
        > 1.q
END_OF_CODE
stdout_is { $bef->run_code } '1 ', 'file input, non-existing file';
$bef->store_code( <<'END_OF_CODE' );
v v i "t/_resources/hello.bf"0   <
>     ;vector; 3 6  ;flag; 0     ^
  .
  .
  .
  .
  >
END_OF_CODE
stdout_is { $bef->run_code } "6 3 2 35 hello world!\n", 'file input, existing file';


# binary file input
$bef->store_code( <<'END_OF_CODE' );
v qiv# "t/_resources/hello.bf"0  <
>     ;vector; 6 9 ;flag; 1      ^
    <q ,,,,,,,,,"IO Error"a
END_OF_CODE
stdout_is { $bef->run_code } '', 'binary file input';
is( $bef->get_storage->rectangle(
        Language::Befunge::Vector->new( 6, 9),
        Language::Befunge::Vector->new( 71, 1) ),
    qq{v q  ,,,,,,,,,,,,,"hello world!"a <\n>                                 ^},
    'binary file input' );


# file output
$bef->store_code( <<'END_OF_CODE' );
v q.2 o v# "/ved/a_file_that_probably_does_not_exist"0 <
>          ;size; 4 5   ;offset; 7 8       ;flag; 0    ^
    q.1 <
END_OF_CODE
stdout_is { $bef->run_code } '1 ', 'file output, invalid file';
$bef->store_code( <<'END_OF_CODE' );
v q o "t/foo.txt"0  0 ;flag;     <
>     ;size; 4 4   ;offset; 3 2  ^
   foo!

   ;-)
END_OF_CODE
stdout_is { $bef->run_code } '', 'file output, valid file';
{
    my $file = 't/foo.txt';
    open my $fh, '<', $file or die $!;
    local $/;
    is( <$fh>, "foo!\n    \n;-) \n    ", 'file output, valid file' );
    unlink $file;
}
$bef->store_code( <<'END_OF_CODE' );
v q o "t/foo.txt"0  1 ;flag;     <
>     ;size; 4 4   ;offset; 3 2  ^
   foo!

   ;-)
END_OF_CODE
stdout_is { $bef->run_code } '', 'file output, text flag';
{
    my $file = 't/foo.txt';
    open my $fh, '<', $file or die $!;
    local $/;
    is( <$fh>, "foo!\n\n;-)\n", 'file output, text flag' );
    unlink $file;
}

