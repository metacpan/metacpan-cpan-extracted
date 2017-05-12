#!/usr/bin/perl -Tw

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 2.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

#use Test::More tests => 4;
use Test::More 'no_plan';
#BEGIN { use_ok('Lingua::SA') };

#########################
use Lingua::SA qw(vibhakti sandhi);
test_paJchamI_ekavachana_puM_vibhakti();
test_paJchamI_ekavachana_strI_vibhakti();
test_paJchamI_ekavachana_napuMsaka_vibhakti();
test_paJchamI_dvivachana_puM_vibhakti();
test_paJchamI_dvivachana_strI_vibhakti();
test_paJchamI_dvivachana_napuMsaka_vibhakti();
test_paJchamI_bahuvachana_puM_vibhakti();
test_paJchamI_bahuvachana_strI_vibhakti();
test_paJchamI_bahuvachana_napuMsaka_vibhakti();
#########################
sub test_paJchamI_ekavachana_puM_vibhakti{
# ekavachana, puMlinga
my %paJchamI_ekavachana_puM_vibhakti_of = (
	'nara'		=>	'narAt',
	'kavi'		=>	'kaveH',
	'shatru'	=>	'shatroH',
	'dhAtR'		=>	'dhAtuH',
	'nRpa'		=>	'nRpaat',
	);

for my $word (keys %paJchamI_ekavachana_puM_vibhakti_of){
    my $expected = sandhi($paJchamI_ekavachana_puM_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'paJchamI', linga=>'puM', vachana=>'ekavachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_paJchamI_ekavachana_strI_vibhakti{
# ekavachana, strIlinga
my %paJchamI_ekavachana_strI_vibhakti_of = (
	'bAlA'		=>	'bAlaayaaH',
	'mati'		=>	'matyaaH | mateH',
	'nadI'	=>	'nadyaaH',
	'dhenu'		=>	'dhenoH | dhenvaaH',
	'vadhU'		=>	'vadhvaaH',
	'mAtR'		=>	'mAtuH',
	);

for my $word (keys %paJchamI_ekavachana_strI_vibhakti_of){
    my $expected = sandhi($paJchamI_ekavachana_strI_vibhakti_of{$word});
    my $computed = sandhi(vibhakti({ naam=>$word, vibhakti=>'paJchamI', linga=>'strI', vachana=>'ekavachana'}));

    is( $computed, $expected, $expected );

#	These will fail because the + sign would not match the response
#    my $expected2 = $paJchamI_ekavachana_strI_vibhakti_of{$word};
#    my $computed2 = vibhakti({ naam=>$word, vibhakti=>'paJchamI', linga=>'strI', vachana=>'ekavachana'});
#    is( $computed2, $expected2, $expected2 );
	}
}
#########################
sub test_paJchamI_ekavachana_napuMsaka_vibhakti{
# ekavachana, napuMsakalinga
my %paJchamI_ekavachana_napuMsaka_vibhakti_of = (
	'vana'		=>	'vanaat',
	'vAri'		=>	'vAriNaH',
	'shuci'		=>	'shucinaH',
	'madhu'	=>	'madhunaH',
	'kartR'		=>	'kartuH | kartRNaH',
	'Chatra'		=>	'Chatraat',
	);

for my $word (keys %paJchamI_ekavachana_napuMsaka_vibhakti_of){
    my $expected = sandhi($paJchamI_ekavachana_napuMsaka_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'paJchamI', linga=>'napuMsaka', vachana=>'ekavachana'}));

    is( $computed, $expected, $expected );
	}
}
#############################
#sub sandhi{
#my ($in)=@_;
##$in=~s/\s+\+\s+//;
#$in=~s/ \+ ([^\[])/$1/g;
#$in=~s/aa/A/g;
#$in=~s/ii/I/g;
#$in=~s/uu/U/g;
#$in=~s/Ru/R/g;
#return $in;
#}
#########################
sub test_paJchamI_dvivachana_puM_vibhakti{
# dvivachana, puMlinga
my %paJchamI_dvivachana_puM_vibhakti_of = (
	'nara'		=>	'naraabhyaam',
	'kavi'		=>	'kavibhyaam',
	'shatru'	=>	'shatrubhyaam',
	'dhAtR'		=>	'dhAtRbhyaam',
	);

for my $word (keys %paJchamI_dvivachana_puM_vibhakti_of){
    my $expected = sandhi($paJchamI_dvivachana_puM_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'paJchamI', linga=>'puM',
vachana=>'dvivachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_paJchamI_dvivachana_strI_vibhakti{
# dvivachana, strIlinga
my %paJchamI_dvivachana_strI_vibhakti_of = (
	'bAlA'		=>	'bAlaabhyaam',
	'mati'		=>	'matibhyaam',
	'nadI'	=>	'nadIbhyaam',
	'dhenu'		=>	'dhenubhyaam',
	'vadhU'		=>	'vadhUbhyaam',
	'mAtR'		=>	'mAtRubhyaam',
	);

for my $word (keys %paJchamI_dvivachana_strI_vibhakti_of){
    my $expected = sandhi($paJchamI_dvivachana_strI_vibhakti_of{$word});
    my $computed = sandhi(vibhakti({ naam=>$word, vibhakti=>'paJchamI',
linga=>'strI', vachana=>'dvivachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_paJchamI_dvivachana_napuMsaka_vibhakti{
# dvivachana, napuMsakalinga
my %paJchamI_dvivachana_napuMsaka_vibhakti_of = (
	'vana'		=>	'vanaabhyaam',
	'vAri'		=>	'vAribhyaam',
	'madhu'	=>	'madhubhyaam',
	'kartR'		=>	'kartRubhyaam',
	);

for my $word (keys %paJchamI_dvivachana_napuMsaka_vibhakti_of){
    my $expected = sandhi($paJchamI_dvivachana_napuMsaka_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'paJchamI', linga=>'napuMsaka',
vachana=>'dvivachana'}));

    is( $computed, $expected, $expected );
	}
}
#############################
sub test_paJchamI_bahuvachana_puM_vibhakti{
# bahuvachana, puMlinga
my %paJchamI_bahuvachana_puM_vibhakti_of = (
	'nara'		=>	'narebhyaH',
	'kavi'		=>	'kavibhyaH',
	'shatru'	=>	'shatrubhyaH',
	'dhAtR'		=>	'dhAtRubhyaH',
	'graha'		=>	'grahebhyaH',
	'rAma'		=>	'rAmebhyaH',
	'dIpa'		=>	'dIpebhyaH',
	);

for my $word (keys %paJchamI_bahuvachana_puM_vibhakti_of){
    my $expected = sandhi($paJchamI_bahuvachana_puM_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'paJchamI', linga=>'puM',
vachana=>'bahuvachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_paJchamI_bahuvachana_strI_vibhakti{
# bahuvachana, strIlinga
my %paJchamI_bahuvachana_strI_vibhakti_of = (
	'bAlA'		=>	'bAlaabhyaaH',
	'mati'		=>	'matibhyaH',
	'nadI'	=>	'nadIbhyaH',
	'dhenu'		=>	'dhenubhyaH',
	'vadhU'		=>	'vadhUbhyaH',
	'mAtR'		=>	'mAtRubhyaH',
	);

for my $word (keys %paJchamI_bahuvachana_strI_vibhakti_of){
    my $expected = sandhi($paJchamI_bahuvachana_strI_vibhakti_of{$word});
    my $computed = sandhi(vibhakti({ naam=>$word, vibhakti=>'paJchamI',
linga=>'strI', vachana=>'bahuvachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_paJchamI_bahuvachana_napuMsaka_vibhakti{
# bahuvachana, napuMsakalinga
my %paJchamI_bahuvachana_napuMsaka_vibhakti_of = (
	'vana'		=>	'vanebhyaH',
	'vAri'		=>	'vAribhyaH',
	'madhu'	=>	'madhubhyaH',
	'kartR'		=>	'kartRubhyaH',
	);

for my $word (keys %paJchamI_bahuvachana_napuMsaka_vibhakti_of){
    my $expected = sandhi($paJchamI_bahuvachana_napuMsaka_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'paJchamI', linga=>'napuMsaka',
vachana=>'bahuvachana'}));

    is( $computed, $expected, $expected );
	}
}
#############################
