# envy -*-perl-*-
use strict;
BEGIN { %ENV = (REGRESSION_ENVY_PATH => "./example/area1/etc/envy"); }
use Envy::DB;
use Test; plan test => 8;
$Envy::DB::MAX_VAR_LENGTH = 1;

my $db = Envy::DB->new(\%ENV);

my %got;
sub envy {
    $db->warnlevel(2);
    $db->begin;
    $db->envy(@_);
    $db->commit;
    for ( $db->to_sync()) {
	if (defined $_->[1]) {
	    $got{$_->[0]} = $_->[1];
	} else {
	    #warn "nuke $_->[0]\n";
	    delete $got{$_->[0]};
	}
    }
}

envy(0, 'area1');

#while (my($k,$v)=each %got) { warn "$k $v\n" }

envy(0, 'insure');
my @s = grep /ENVY_STATE/, keys %got;
my @d = grep /ENVY_DIMENSION/, keys %got;
ok @s > 1;
ok @d > 1;

my %state;
for my $k (@s) {
    my ($e,$by) = split m/,/, $got{$k};
    die "dup $e" if exists $state{$e};
    $state{$e} = $by;
}
ok $state{area1}, '0';
ok $state{insure}, '1';
ok $state{'cc-tools'}, 'SUNWspro-4.2';

my %dim;
for my $k (@d) {
    my ($d,$e) = split m/,/, $got{$k};
    die "dup $d" if exists $dim{$d};
    $dim{$d} = $e;
}
ok $dim{First}, 'area1';
ok $dim{sunpro}, 'SUNWspro-4.2';

envy(1, 'area1');

# expecting no warnings
my @w = $db->warnings;
ok @w, 0;

#while (my($k,$v)=each %got) { warn "$k $v\n" }
