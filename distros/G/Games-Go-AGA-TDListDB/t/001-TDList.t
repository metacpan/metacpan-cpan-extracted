#!/usr/bin/perl -w
#===============================================================================
#
#     ABSTRACT:  test script for Games::Go::AGA::TDListDB
#
#       AUTHOR:  Reid Augustin (REID), <reid@hellosix.com>
#      CREATED:  Fri Dec  3 10:55:46 PST 2010
#===============================================================================

use strict;
use warnings;

use Test::More;
use Carp;
use File::Slurp qw( read_file );
use Try::Tiny;
# define mocked module in BEGIN to prevent loading of the real module
BEGIN {
    use lib 'extra';    # find Mocked module in extra subdir
#   use Mocked_LWP;
}


eval { require DBD::SQLite };
if ($@) {
    plan(skip_all => "DBD::SQLite not installed: $@");
}
plan (tests => 17);

my $db_fname = '__test_tdlistdb.sqlite';
unlink $db_fname;   # make sure nothing left over from previous run

use_ok('Games::Go::AGA::TDListDB');

my $tdlistdb = new_ok(
    'Games::Go::AGA::TDListDB' => [
        dbdname => $db_fname,
        table_name => '__test_tdlistn',
        extra_columns => [
            { extra_1 => 'VARCAHR(128)' },
            { extra_2 => 'VARCAHR(128)' },
        ],
        extra_columns_callback => sub {
            my ($self, $columns) = @_;

            $self->{incr}++;
            return ($self->{incr} - 1, "$columns->[0], $columns->[1]");
        }
    ],
);
$tdlistdb->db->do('DELETE from __test_tdlistn');

# some sample TDListN data
my $data = <<'EO_DATA'

Augustin, Reid   USA2122 Full   5.1  4/23/2009 PALO CA
Xxx, Reid                Full   -20  4/24/1901 CO
Augustin, Yyx    usa002  Comp   1.1  4/25/1929 SFGC MI
Augustin, Yyy    Usa3    Comp   1.2  4/26/1929 Berk MI
Augustin, Yyz            Comp   1.3  4/27/1929 AbCd MI

EO_DATA
;

update_from_string(\$data);
ok (abs (time - $tdlistdb->update_time) < 5, 'time after DB initialized');

my $player = fetch_player('Augustin', 'Yyy');
is ($player->[2], 'USA3', 'ID');
is ($player->[4], '1.2', 'rank');

my $new_tdline = 'Augustin, Yzz            Comp   5.5  4/27/1929 AbCd MI';
$data =~ s/(Yyx.*1\.1.*?$)/$1\n$new_tdline\n/m; # add a line
$data =~ s/(Yyy.*)1\.2/${1}2.4/s;               # change his rank

$tdlistdb->{incr} = 0;  # restart counter
update_from_string(\$data);

ok (abs (time - $tdlistdb->update_time) < 5, 'time after update');

$player = fetch_player('Augustin', 'Yyy');
is ($player->[2], 'USA3', 'ID after update');
is ($player->[4], '2.4', 'rank after update');

$player = $tdlistdb->select_id('TMP3');
is ($player->[0], 'Augustin', 'last name of new player');
is ($player->[1], 'Yzz', 'first name of new player');
is ($player->[2], 'TMP3', 'ID of new player');
is ($player->[4], '5.5', 'rank of new player');

my $thrown = 0;
try {
    update_from_string('Augustin, Reid   2122    Comp   4.2  4/27/1929 AbCd MI');
}
catch {
    my $error = $_;
    fail "Oops: $error";
    $thrown = 1;
};
ok ($thrown == 0, 'exception not thrown for rank change');

$thrown = 0;
try {
    update_from_string('Augustin, Yyx   2122    Youth   1.1  4/27/1929 SFGC MI');
}
catch {
    my $error = $_;
    fail "Oops: $error";
    $thrown = 1;
};
ok ($thrown == 0, 'exception not thrown for valid ID change');

is ($tdlistdb->next_tmp_id(1), 'TMP4',     'next_tmp_id is TMP4');
is ($tdlistdb->next_tmp_id(1), 'TMP5',     'next_tmp_id is TMP5');

$tdlistdb->background(0);   # run update in the background
is ($tdlistdb->background, 0,  'net update in background (takes a few seconds)');
print 'start update at ', scalar localtime, "\n";
# $tdlistdb->update_from_AGA;
# while ($tdlistdb->reap == 0) {
#     print 'not yet, ';
#     sleep 1;
# }
# print 'update done at ', scalar localtime, "\n";
# 
# $player = $tdlistdb->select_id('USA7206');
# is ($player->[0], 'Aaron', 'W. Aaron was added');

#$tdlistdb->db->disconnect;

# clean up
if (not defined $DB::single or not defined $DB::single) {
    unlink $db_fname;
}



sub fetch_player {
    my ($last_name, $first_name) = @_;

    $tdlistdb->sth('select_by_name')->execute($last_name, $first_name);
    my $found = $tdlistdb->sth('select_by_name')->fetchall_arrayref;
    croak("Too many copies of $last_name, $first_name\n") if (@{$found} > 1);
    return $found->[0];
}

sub update_from_string {
    my ($string) = @_;

    my $ref = ref $string ? $string : \$string;
    my $fh;
    open($fh, '<', $ref)
        or croak("Error opening \$string for reading: $!\n");
    $tdlistdb->update_from_file($fh);
}

__END__
