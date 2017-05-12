#!perl -T

use Test::More tests => 10;

use Flexnet::lmutil;

my $lmutil = Flexnet::lmutil->new (testfile => "t/lmstat_all.txt");

my $data = $lmutil->lmstat ('all');

#use Data::Dumper;
#print Dumper $data;

ok ( $data->{server}->{'dabu.uni-paderborn.de'}->{ok} == 1, 'server name' );
ok ( $data->{vendor}->{'MLM'}->{ok} == 1, 'vendor name' );
ok ( $data->{feature}->{'Image_Toolbox'}->{'reservations'}->[0]->{group} eq 'fvt', 'reservation' );
ok ( $data->{feature}->{'Image_Toolbox'}->{'reservations'}->[1]->{group} eq 'sst', 'reservation' );
ok ( $data->{feature}->{'MATLAB'}->{users}->[0]->{user} eq 'hangmann', 'simple user name' );
ok ( $data->{feature}->{'MATLAB'}->{users}->[2]->{user} eq 'akshara', 'long display name' );
ok ( $data->{feature}->{'MATLAB'}->{users}->[4]->{user} eq 'sinaob', 'no display name' );
ok ( $data->{feature}->{'MATLAB'}->{users}->[5]->{user} eq 'Kurt Eschebach', 'user name with spaces' );
ok ( $data->{feature}->{'MATLAB'}->{users}->[6]->{user} eq 'mahmoud', 'display with slash' );
ok ( $data->{feature}->{'MATLAB'}->{users}->[7]->{licenses} == 4, 'multiple license usage' );

