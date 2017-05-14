# envy -*-perl-*-
use strict;
use Test; plan test => 9;
%ENV = (REGRESSION_ENVY_PATH => "./example/area1/etc/envy");
require Envy::DB;

-d 't' or die "Can't find ./t directory";

my $db = Envy::DB->new(\%ENV);

my %got;
my @w;
sub envy {
    $db->warnlevel(2);
    $db->begin;
    $db->envy(@_);
    $db->commit;
    for ( $db->to_sync()) {
	if (defined $_->[1]) {
	    $got{$_->[0]} = $_->[1]
	} else {
	    delete $got{$_->[0]};
	}
    }
    @w = $db->warnings;
}

envy(0, 'area1');
ok @w, 0, join("\n",@w);
my @P = split(/:+/, $got{ENVY_PATH});
ok @P, 1;
my $always = $P[0];

envy(0, 'pathtest');
ok @w, 1, join("\n",@w);
ok $w[0], '/readable/';
@P = split(/:+/, $got{ENVY_PATH});
ok @P, 2;
ok $P[0], $always;

envy(1, 'pathtest');
ok @w, 0, join("\n",@w);
@P = split(/:+/, $got{ENVY_PATH});
ok @P, 1;
ok $P[0], $always;


