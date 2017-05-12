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
test_prathama_ekavachana_puM_vibhakti();
test_prathama_ekavachana_strI_vibhakti();
test_prathama_ekavachana_napuMsaka_vibhakti();
test_prathama_dvivachana_puM_vibhakti();
test_prathama_dvivachana_strI_vibhakti();
test_prathama_dvivachana_napuMsaka_vibhakti();
test_prathama_bahuvachana_puM_vibhakti();
test_prathama_bahuvachana_strI_vibhakti();
test_prathama_bahuvachana_napuMsaka_vibhakti();
#########################
sub test_prathama_ekavachana_puM_vibhakti{
# ekavachana, puMlinga
my %prathama_ekavachana_puM_vibhakti_of = (
	'nara'		=>	'naraH',
	'kavi'		=>	'kaviH',
	'shatru'	=>	'shatruH',
	'dhAtR'		=>	'dhAtA',
	'nRpa'		=>	'nRpaH',
	);

for my $word (keys %prathama_ekavachana_puM_vibhakti_of){
    my $expected = sandhi($prathama_ekavachana_puM_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'prathamaa', linga=>'puM', vachana=>'ekavachana'}));

    is( $computed, $expected, $expected );
	}

for my $word (keys %prathama_ekavachana_puM_vibhakti_of){
    my $expected = sandhi($prathama_ekavachana_puM_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'prathamA', linga=>'puM', vachana=>'ekavachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_prathama_ekavachana_strI_vibhakti{
# ekavachana, strIlinga
my %prathama_ekavachana_strI_vibhakti_of = (
	'bAlA'		=>	'bAlaa',
	'bAlaa'		=>	'bAlaa',
	'mati'		=>	'matiH',
	'nadI'	=>	'nadI',
	'dhenu'		=>	'dhenuH',
	'vadhU'		=>	'vadhUH',
	'mAtR'		=>	'mAtA',
	);

for my $word (keys %prathama_ekavachana_strI_vibhakti_of){
    my $expected = sandhi($prathama_ekavachana_strI_vibhakti_of{$word});
    my $computed = sandhi(vibhakti({ naam=>$word, vibhakti=>'prathamaa', linga=>'strI', vachana=>'ekavachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_prathama_ekavachana_napuMsaka_vibhakti{
# ekavachana, napuMsakalinga
my %prathama_ekavachana_napuMsaka_vibhakti_of = (
	'vana'		=>	'vanam',
	'vAri'		=>	'vAri',
	'madhu'	=>	'madhu',
	'kartR'		=>	'kartR',
	'Chatra'		=>	'Chatram',
	);

for my $word (keys %prathama_ekavachana_napuMsaka_vibhakti_of){
    my $expected = sandhi($prathama_ekavachana_napuMsaka_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'prathamaa', linga=>'napuMsaka', vachana=>'ekavachana'}));

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
sub test_prathama_dvivachana_puM_vibhakti{
# dvivachana, puMlinga
my %prathama_dvivachana_puM_vibhakti_of = (
	'nara'		=>	'narau',
	'kavi'		=>	'kavI',
	'shatru'	=>	'shatrU',
	'dhAtR'		=>	'dhAtArau',
	);

for my $word (keys %prathama_dvivachana_puM_vibhakti_of){
    my $expected = sandhi($prathama_dvivachana_puM_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'prathamaa', linga=>'puM',
vachana=>'dvivachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_prathama_dvivachana_strI_vibhakti{
# dvivachana, strIlinga
my %prathama_dvivachana_strI_vibhakti_of = (
	'bAlA'		=>	'bAle',
	'mati'		=>	'matI',
	'nadI'	=>	'nadyau',
	'dhenu'		=>	'dhenU',
	'vadhU'		=>	'vadhvau',
	'mAtR'		=>	'mAtarau',
	);

for my $word (keys %prathama_dvivachana_strI_vibhakti_of){
    my $expected = sandhi($prathama_dvivachana_strI_vibhakti_of{$word});
    my $computed = sandhi(vibhakti({ naam=>$word, vibhakti=>'prathamaa',
linga=>'strI', vachana=>'dvivachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_prathama_dvivachana_napuMsaka_vibhakti{
# dvivachana, napuMsakalinga
my %prathama_dvivachana_napuMsaka_vibhakti_of = (
	'vana'		=>	'vane',
	'vAri'		=>	'vAriNI',
	'madhu'	=>	'madhunI',
	'kartR'		=>	'kartRNI',
	);

for my $word (keys %prathama_dvivachana_napuMsaka_vibhakti_of){
    my $expected = sandhi($prathama_dvivachana_napuMsaka_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'prathamaa', linga=>'napuMsaka',
vachana=>'dvivachana'}));

    is( $computed, $expected, $expected );
	}
}
#############################
sub test_prathama_bahuvachana_puM_vibhakti{
# bahuvachana, puMlinga
my %prathama_bahuvachana_puM_vibhakti_of = (
	'nara'		=>	'naraaH',
	'kavi'		=>	'kavayaH',
	'shatru'	=>	'shatravaH',
	'dhAtR'		=>	'dhAtaaraH',
	);

for my $word (keys %prathama_bahuvachana_puM_vibhakti_of){
    my $expected = sandhi($prathama_bahuvachana_puM_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'prathamaa', linga=>'puM',
vachana=>'bahuvachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_prathama_bahuvachana_strI_vibhakti{
# bahuvachana, strIlinga
my %prathama_bahuvachana_strI_vibhakti_of = (
	'bAlA'		=>	'bAlaaH',
	'mati'		=>	'matayaH',
	'nadI'	=>	'nadyaH',
	'dhenu'		=>	'dhenavaH',
	'vadhU'		=>	'vadhvaH',
	'mAtR'		=>	'mAtaraH',
	);

for my $word (keys %prathama_bahuvachana_strI_vibhakti_of){
    my $expected = sandhi($prathama_bahuvachana_strI_vibhakti_of{$word});
    my $computed = sandhi(vibhakti({ naam=>$word, vibhakti=>'prathamaa',
linga=>'strI', vachana=>'bahuvachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_prathama_bahuvachana_napuMsaka_vibhakti{
# bahuvachana, napuMsakalinga
my %prathama_bahuvachana_napuMsaka_vibhakti_of = (
	'vana'		=>	'vanaani',
	'vAri'		=>	'vArINi',
	'madhu'	=>	'madhUni',
	'kartR'		=>	'kartRRNi',
	);

for my $word (keys %prathama_bahuvachana_napuMsaka_vibhakti_of){
    my $expected = sandhi($prathama_bahuvachana_napuMsaka_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'prathamaa', linga=>'napuMsaka',
vachana=>'bahuvachana'}));

    is( $computed, $expected, $expected );
	}
}
#############################
