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
test_chaturthI_ekavachana_puM_vibhakti();
test_chaturthI_ekavachana_strI_vibhakti();
test_chaturthI_ekavachana_napuMsaka_vibhakti();
test_chaturthI_dvivachana_puM_vibhakti();
test_chaturthI_dvivachana_strI_vibhakti();
test_chaturthI_dvivachana_napuMsaka_vibhakti();
test_chaturthI_bahuvachana_puM_vibhakti();
test_chaturthI_bahuvachana_strI_vibhakti();
test_chaturthI_bahuvachana_napuMsaka_vibhakti();
#########################
sub test_chaturthI_ekavachana_puM_vibhakti{
# ekavachana, puMlinga
my %chaturthI_ekavachana_puM_vibhakti_of = (
	'nara'		=>	'narAya',
	'kavi'		=>	'kavaye',
	'shatru'	=>	'shatrave',
	'dhAtR'		=>	'dhAtre',
	'nRpa'		=>	'nRpAya',
	);

for my $word (keys %chaturthI_ekavachana_puM_vibhakti_of){
    my $expected = sandhi($chaturthI_ekavachana_puM_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'chaturthI', linga=>'puM', vachana=>'ekavachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_chaturthI_ekavachana_strI_vibhakti{
# ekavachana, strIlinga
my %chaturthI_ekavachana_strI_vibhakti_of = (
	'bAlA'		=>	'bAlAyai',
	'mati'		=>	'matyai | mataye',
	'nadI'		=>	'nadyai',
	'dhenu'		=>	'dhenave | dhenvai',
	'vadhU'		=>	'vadhvai',
	'mAtR'		=>	'mAtre',
	);

for my $word (keys %chaturthI_ekavachana_strI_vibhakti_of){
    my $expected = sandhi($chaturthI_ekavachana_strI_vibhakti_of{$word});
    my $computed = sandhi(vibhakti({ naam=>$word, vibhakti=>'chaturthI', linga=>'strI', vachana=>'ekavachana'}));

    is( $computed, $expected, $expected );

#	These will fail because the + sign would not match the response
#    my $expected2 = $chaturthI_ekavachana_strI_vibhakti_of{$word};
#    my $computed2 = vibhakti({ naam=>$word, vibhakti=>'chaturthI', linga=>'strI', vachana=>'ekavachana'});
#    is( $computed2, $expected2, $expected2 );
	}
}
#########################
sub test_chaturthI_ekavachana_napuMsaka_vibhakti{
# ekavachana, napuMsakalinga
my %chaturthI_ekavachana_napuMsaka_vibhakti_of = (
	'vana'		=>	'vanAya',
	'vAri'		=>	'vAriNe',
	'shuci'		=>	'shucine',
	'madhu'		=>	'madhune',
	'kartR'		=>	'kartre | kartRNe',
	'Chatra'	=>	'ChatrAya',
	);

for my $word (keys %chaturthI_ekavachana_napuMsaka_vibhakti_of){
    my $expected = sandhi($chaturthI_ekavachana_napuMsaka_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'chaturthI', linga=>'napuMsaka', vachana=>'ekavachana'}));

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
sub test_chaturthI_dvivachana_puM_vibhakti{
# dvivachana, puMlinga
my %chaturthI_dvivachana_puM_vibhakti_of = (
	'nara'		=>	'naraabhyaam',
	'kavi'		=>	'kavibhyaam',
	'shatru'	=>	'shatrubhyaam',
	'dhAtR'		=>	'dhAtRbhyaam',
	);

for my $word (keys %chaturthI_dvivachana_puM_vibhakti_of){
    my $expected = sandhi($chaturthI_dvivachana_puM_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'chaturthI', linga=>'puM',
vachana=>'dvivachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_chaturthI_dvivachana_strI_vibhakti{
# dvivachana, strIlinga
my %chaturthI_dvivachana_strI_vibhakti_of = (
	'bAlA'		=>	'bAlaabhyaam',
	'mati'		=>	'matibhyaam',
	'nadI'	=>	'nadIbhyaam',
	'dhenu'		=>	'dhenubhyaam',
	'vadhU'		=>	'vadhUbhyaam',
	'mAtR'		=>	'mAtRubhyaam',
	);

for my $word (keys %chaturthI_dvivachana_strI_vibhakti_of){
    my $expected = sandhi($chaturthI_dvivachana_strI_vibhakti_of{$word});
    my $computed = sandhi(vibhakti({ naam=>$word, vibhakti=>'chaturthI',
linga=>'strI', vachana=>'dvivachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_chaturthI_dvivachana_napuMsaka_vibhakti{
# dvivachana, napuMsakalinga
my %chaturthI_dvivachana_napuMsaka_vibhakti_of = (
	'vana'		=>	'vanaabhyaam',
	'vAri'		=>	'vAribhyaam',
	'madhu'	=>	'madhubhyaam',
	'kartR'		=>	'kartRubhyaam',
	);

for my $word (keys %chaturthI_dvivachana_napuMsaka_vibhakti_of){
    my $expected = sandhi($chaturthI_dvivachana_napuMsaka_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'chaturthI', linga=>'napuMsaka',
vachana=>'dvivachana'}));

    is( $computed, $expected, $expected );
	}
}
#############################
sub test_chaturthI_bahuvachana_puM_vibhakti{
# bahuvachana, puMlinga
my %chaturthI_bahuvachana_puM_vibhakti_of = (
	'nara'		=>	'narebhyaH',
	'kavi'		=>	'kavibhyaH',
	'shatru'	=>	'shatrubhyaH',
	'dhAtR'		=>	'dhAtRubhyaH',
	'graha'		=>	'grahebhyaH',
	'rAma'		=>	'rAmebhyaH',
	'dIpa'		=>	'dIpebhyaH',
	);

for my $word (keys %chaturthI_bahuvachana_puM_vibhakti_of){
    my $expected = sandhi($chaturthI_bahuvachana_puM_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'chaturthI', linga=>'puM',
vachana=>'bahuvachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_chaturthI_bahuvachana_strI_vibhakti{
# bahuvachana, strIlinga
my %chaturthI_bahuvachana_strI_vibhakti_of = (
	'bAlA'		=>	'bAlaabhyaaH',
	'mati'		=>	'matibhyaH',
	'nadI'	=>	'nadIbhyaH',
	'dhenu'		=>	'dhenubhyaH',
	'vadhU'		=>	'vadhUbhyaH',
	'mAtR'		=>	'mAtRubhyaH',
	);

for my $word (keys %chaturthI_bahuvachana_strI_vibhakti_of){
    my $expected = sandhi($chaturthI_bahuvachana_strI_vibhakti_of{$word});
    my $computed = sandhi(vibhakti({ naam=>$word, vibhakti=>'chaturthI',
linga=>'strI', vachana=>'bahuvachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_chaturthI_bahuvachana_napuMsaka_vibhakti{
# bahuvachana, napuMsakalinga
my %chaturthI_bahuvachana_napuMsaka_vibhakti_of = (
	'vana'		=>	'vanebhyaH',
	'vAri'		=>	'vAribhyaH',
	'madhu'	=>	'madhubhyaH',
	'kartR'		=>	'kartRubhyaH',
	);

for my $word (keys %chaturthI_bahuvachana_napuMsaka_vibhakti_of){
    my $expected = sandhi($chaturthI_bahuvachana_napuMsaka_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'chaturthI', linga=>'napuMsaka',
vachana=>'bahuvachana'}));

    is( $computed, $expected, $expected );
	}
}
#############################
