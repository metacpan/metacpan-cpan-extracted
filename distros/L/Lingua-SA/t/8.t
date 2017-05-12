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
test_sambodhan_ekavachana_puM_vibhakti();
test_sambodhan_ekavachana_strI_vibhakti();
test_sambodhan_ekavachana_napuMsaka_vibhakti();
test_sambodhan_dvivachana_puM_vibhakti();
test_sambodhan_dvivachana_strI_vibhakti();
test_sambodhan_dvivachana_napuMsaka_vibhakti();
test_sambodhan_bahuvachana_puM_vibhakti();
test_sambodhan_bahuvachana_strI_vibhakti();
test_sambodhan_bahuvachana_napuMsaka_vibhakti();
#########################
sub test_sambodhan_ekavachana_puM_vibhakti{
# ekavachana, puMlinga
my %sambodhan_ekavachana_puM_vibhakti_of = (
	'nara'		=>	'he nara',
	'kavi'		=>	'he kave',
	'shatru'	=>	'he shatro',
	'dhAtR'		=>	'he [ dhaataH | dhaatar ]',
	'nRpa'		=>	'he nRpa',
	);

for my $word (keys %sambodhan_ekavachana_puM_vibhakti_of){
    my $expected = sandhi($sambodhan_ekavachana_puM_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'sambodhana', linga=>'puM', vachana=>'ekavachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_sambodhan_ekavachana_strI_vibhakti{
# ekavachana, strIlinga
my %sambodhan_ekavachana_strI_vibhakti_of = (
	'bAlA'		=>	'he bAle',
	'mati'		=>	'he mate',
	'nadI'	=>	'he nadi',
	'dhenu'		=>	'he dheno',
	'vadhU'		=>	'he vadhu',
	'mAtR'		=>	'he [ maataH | maatar ]',
	'akkaa'		=>	'he akka',
	'ambaa'		=>	'he amba',
	'allaa'		=>	'he alla',
	);

for my $word (keys %sambodhan_ekavachana_strI_vibhakti_of){
    my $expected = sandhi($sambodhan_ekavachana_strI_vibhakti_of{$word});
    my $computed = sandhi(vibhakti({ naam=>$word, vibhakti=>'sambodhana', linga=>'strI', vachana=>'ekavachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_sambodhan_ekavachana_napuMsaka_vibhakti{
# ekavachana, napuMsakalinga
my %sambodhan_ekavachana_napuMsaka_vibhakti_of = (
	'vana'		=>	'he vana',
	'vAri'		=>	'he [ vaari | vaare ]',
	'madhu'		=>	'he [ madho | madhu ]',
	'kartR'		=>	'he [ kartaH | kartR ]',
	'Chatra'	=>	'he Chatra',
	);

for my $word (keys %sambodhan_ekavachana_napuMsaka_vibhakti_of){
    my $expected = sandhi($sambodhan_ekavachana_napuMsaka_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'sambodhana', linga=>'napuMsaka', vachana=>'ekavachana'}));

    is( $computed, $expected, $expected );
	}
}
#############################
#sub sandhi{
#my ($in)=@_;
#$in=~s/\s+\+\s+//;
#return $in;
#}
#########################
sub test_sambodhan_dvivachana_puM_vibhakti{
# dvivachana, puMlinga
my %sambodhan_dvivachana_puM_vibhakti_of = (
	'nara'		=>	'he narau',
	'kavi'		=>	'he kavI',
	'shatru'	=>	'he shatrU',
	'dhAtR'		=>	'he dhAtArau',
	);

for my $word (keys %sambodhan_dvivachana_puM_vibhakti_of){
    my $expected = sandhi($sambodhan_dvivachana_puM_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'sambodhana', linga=>'puM',
vachana=>'dvivachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_sambodhan_dvivachana_strI_vibhakti{
# dvivachana, strIlinga
my %sambodhan_dvivachana_strI_vibhakti_of = (
	'bAlA'		=>	'he bAle',
	'mati'		=>	'he matI',
	'nadI'		=>	'he nadyau',
	'dhenu'		=>	'he dhenU',
	'vadhU'		=>	'he vadhvau',
	'mAtR'		=>	'he mAtarau',
	);

for my $word (keys %sambodhan_dvivachana_strI_vibhakti_of){
    my $expected = sandhi($sambodhan_dvivachana_strI_vibhakti_of{$word});
    my $computed = sandhi(vibhakti({ naam=>$word, vibhakti=>'sambodhana',
linga=>'strI', vachana=>'dvivachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_sambodhan_dvivachana_napuMsaka_vibhakti{
# dvivachana, napuMsakalinga
my %sambodhan_dvivachana_napuMsaka_vibhakti_of = (
	'vana'		=>	'he vane',
	'vAri'		=>	'he vAriNI',
	'madhu'		=>	'he madhunI',
	'kartR'		=>	'he kartRNI',
	);

for my $word (keys %sambodhan_dvivachana_napuMsaka_vibhakti_of){
    my $expected = sandhi($sambodhan_dvivachana_napuMsaka_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'sambodhana', linga=>'napuMsaka',
vachana=>'dvivachana'}));

    is( $computed, $expected, $expected );
	}
}
#############################
sub test_sambodhan_bahuvachana_puM_vibhakti{
# bahuvachana, puMlinga
my %sambodhan_bahuvachana_puM_vibhakti_of = (
	'nara'		=>	'he naraaH',
	'kavi'		=>	'he kavayaH',
	'shatru'	=>	'he shatravaH',
	'dhAtR'		=>	'he dhAtaaraH',
	);

for my $word (keys %sambodhan_bahuvachana_puM_vibhakti_of){
    my $expected = sandhi($sambodhan_bahuvachana_puM_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'sambodhana', linga=>'puM',
vachana=>'bahuvachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_sambodhan_bahuvachana_strI_vibhakti{
# bahuvachana, strIlinga
my %sambodhan_bahuvachana_strI_vibhakti_of = (
	'bAlA'		=>	'he bAlaaH',
	'mati'		=>	'he matayaH',
	'nadI'		=>	'he nadyaH',
	'dhenu'		=>	'he dhenavaH',
	'vadhU'		=>	'he vadhvaH',
	'mAtR'		=>	'he mAtaraH',
	);

for my $word (keys %sambodhan_bahuvachana_strI_vibhakti_of){
    my $expected = sandhi($sambodhan_bahuvachana_strI_vibhakti_of{$word});
    my $computed = sandhi(vibhakti({ naam=>$word, vibhakti=>'sambodhana',
linga=>'strI', vachana=>'bahuvachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_sambodhan_bahuvachana_napuMsaka_vibhakti{
# bahuvachana, napuMsakalinga
my %sambodhan_bahuvachana_napuMsaka_vibhakti_of = (
	'vana'		=>	'he vanaani',
	'vAri'		=>	'he vArINi',
	'madhu'		=>	'he madhUni',
	'kartR'		=>	'he kartRRNi',
	);

for my $word (keys %sambodhan_bahuvachana_napuMsaka_vibhakti_of){
    my $expected = sandhi($sambodhan_bahuvachana_napuMsaka_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'sambodhana', linga=>'napuMsaka',
vachana=>'bahuvachana'}));

    is( $computed, $expected, $expected );
	}
}
#############################
