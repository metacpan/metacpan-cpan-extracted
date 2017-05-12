#!/usr/local/bin/perl -w
use strict;
use Test::More tests => 6;
sub findVersion {
  my $pv = `perl -v`;
  my ($v) = $pv =~ /v(\d+\.\d+)\.\d+/;

  $v ? $v : 0;
}
BEGIN { use_ok('GRID::Machine', 'is_operative') };

my $host = $ENV{GRID_REMOTE_MACHINE} || '';

SKIP: {
    skip "Remote not operative", 5 unless  $host && is_operative('ssh', $host);

    my $m = GRID::Machine->new( host => $host );

    my $f = $m->open('> tutu.txt');
    $f->print("Hola Mundo!\n");
    $f->print("Hello World!\n");
    $f->printf("%s %d %4d\n","Bona Sera Signorina", 44, 77);
    $f->close();

    $f = $m->open('tutu.txt');
    my $x = <$f>;
    is($x, "Hola Mundo!\n", "remote 1st line"); 
    
    $x = <$f>;
    is($x, "Hello World!\n", "remote 2nd line"); 

    $x = <$f>;
    is($x, "Bona Sera Signorina 44   77\n", "remote 3rd line"); 

    $f->close();

    $f = $m->open('tutu.txt');
    my $old = $m->input_record_separator(undef);
    $x = <$f>;
    $f->close();
    $old = $m->input_record_separator($old);
    like($x,qr{Hola Mundo!.*Bona Sera Signorina}s, "undef input_record_separator");

    my $r = $m->unlink('tutu.txt');

    ok($r->ok,'Remote file removed');

} # end SKIP block

