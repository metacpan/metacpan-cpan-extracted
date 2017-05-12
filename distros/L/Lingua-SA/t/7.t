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
test_saptamI_ekavachana_puM_vibhakti();
test_saptamI_ekavachana_strI_vibhakti();
test_saptamI_ekavachana_napuMsaka_vibhakti();
test_saptamI_dvivachana_puM_vibhakti();
test_saptamI_dvivachana_strI_vibhakti();
test_saptamI_dvivachana_napuMsaka_vibhakti();
test_saptamI_bahuvachana_puM_vibhakti();
test_saptamI_bahuvachana_strI_vibhakti();
test_saptamI_bahuvachana_napuMsaka_vibhakti();
#########################
sub test_saptamI_ekavachana_puM_vibhakti{
# ekavachana, puMlinga
my %saptamI_ekavachana_puM_vibhakti_of = (
	'nara'		=>	'nare',
	'kavi'		=>	'kavau',
	'shatru'	=>	'shatrau',
	'dhAtR'		=>	'dhAtari',
	'nRpa'		=>	'nRpe',
	);

for my $word (keys %saptamI_ekavachana_puM_vibhakti_of){
    my $expected = sandhi($saptamI_ekavachana_puM_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'saptamI', linga=>'puM', vachana=>'ekavachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_saptamI_ekavachana_strI_vibhakti{
# ekavachana, strIlinga
my %saptamI_ekavachana_strI_vibhakti_of = (
	'bAlA'		=>	'bAlaayaam',
	'mati'		=>	'matyaam | matau',
	'nadI'		=>	'nadyaam',
	'dhenu'		=>	'dhenau | dhenvaam',
	'vadhU'		=>	'vadhvaam',
	'mAtR'		=>	'mAtari',
	);

for my $word (keys %saptamI_ekavachana_strI_vibhakti_of){
    my $expected = sandhi($saptamI_ekavachana_strI_vibhakti_of{$word});
    my $computed = sandhi(vibhakti({ naam=>$word, vibhakti=>'saptamI', linga=>'strI', vachana=>'ekavachana'}));

    is( $computed, $expected, $expected );
	}

for my $word (keys %saptamI_ekavachana_strI_vibhakti_of){
    my $expected = sandhi($saptamI_ekavachana_strI_vibhakti_of{$word});
    my $computed = sandhi(vibhakti({ naam=>$word, vibhakti=>'saptamI',
		linga=>'strii', vachana=>'ekavachana'}));

    is( $computed, $expected, $expected );
	}

for my $word (keys %saptamI_ekavachana_strI_vibhakti_of){
    my $expected = sandhi($saptamI_ekavachana_strI_vibhakti_of{$word});
    my $computed = sandhi(vibhakti({ naam=>$word, vibhakti=>7,
		linga=>'strii', vachana=>'ekavachana'}));

    is( $computed, $expected, $expected );
	}

for my $word (keys %saptamI_ekavachana_strI_vibhakti_of){
    my $expected = sandhi($saptamI_ekavachana_strI_vibhakti_of{$word});
    my $computed = sandhi(vibhakti({ naam=>$word, vibhakti=>7,
		linga=>2, vachana=>'ekavachana'}));

    is( $computed, $expected, $expected );
	}

for my $word (keys %saptamI_ekavachana_strI_vibhakti_of){
    my $expected = sandhi($saptamI_ekavachana_strI_vibhakti_of{$word});
    my $computed = sandhi(vibhakti({ naam=>$word, vibhakti=>7,
		linga=>2, vachana=>1}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_saptamI_ekavachana_napuMsaka_vibhakti{
# ekavachana, napuMsakalinga
my %saptamI_ekavachana_napuMsaka_vibhakti_of = (
	'vana'		=>	'vane',
	'viSa'		=>	'viSe',
	'viSha'		=>	'viShe',
    'vAri'      =>  'vAriNi',
    'shuci'     =>  'shucini',
	'madhu'		=>	'madhuni',
	'kartR'		=>	'kartari | kartRNi',
	'Chatra'	=>	'Chatre',
	);

for my $word (keys %saptamI_ekavachana_napuMsaka_vibhakti_of){
    my $expected = sandhi($saptamI_ekavachana_napuMsaka_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'saptamI', linga=>'napuMsaka', vachana=>'ekavachana'}));

    is( $computed, $expected, $expected );
	}
}
#############################
sub test_saptamI_dvivachana_puM_vibhakti{
# dvivachana, puMlinga
my %saptamI_dvivachana_puM_vibhakti_of = (
	'nara'		=>	'narayoH',
	'kavi'		=>	'kavyoH',
	'shatru'	=>	'shatrvoH',
	'dhAtR'		=>	'dhAtroH',
	);

for my $word (keys %saptamI_dvivachana_puM_vibhakti_of){
    my $expected = sandhi($saptamI_dvivachana_puM_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'saptamI', linga=>'puM',
vachana=>'dvivachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_saptamI_dvivachana_strI_vibhakti{
# dvivachana, strIlinga
my %saptamI_dvivachana_strI_vibhakti_of = (
	'bAlA'		=>	'bAlayoH',
	'mati'		=>	'matyoH',
	'nadI'		=>	'nadyoH',
	'dhenu'		=>	'dhenvoH',
	'vadhU'		=>	'vadhvoH',
	'mAtR'		=>	'mAtroH',
	);

for my $word (keys %saptamI_dvivachana_strI_vibhakti_of){
    my $expected = sandhi($saptamI_dvivachana_strI_vibhakti_of{$word});
    my $computed = sandhi(vibhakti({ naam=>$word, vibhakti=>'saptamI',
linga=>'strI', vachana=>'dvivachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_saptamI_dvivachana_napuMsaka_vibhakti{
# dvivachana, napuMsakalinga
my %saptamI_dvivachana_napuMsaka_vibhakti_of = (
	'vana'		=>	'vanayoH',
	'vAri'		=>	'vAriNoH',
	'madhu'		=>	'madhunoH',
	'kartR'		=>	'kartroH | kartRNoH',
	);

for my $word (keys %saptamI_dvivachana_napuMsaka_vibhakti_of){
    my $expected = sandhi($saptamI_dvivachana_napuMsaka_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'saptamI', linga=>'napuMsaka',
vachana=>'dvivachana'}));

    is( $computed, $expected, $expected );
	}
}
#############################
sub test_saptamI_bahuvachana_puM_vibhakti{
# bahuvachana, puMlinga
my %saptamI_bahuvachana_puM_vibhakti_of = (
	'nara'		=>	'nareSu',
	'nara'		=>	'nareSu',
	'kavi'		=>	'kaviSu',
	'shatru'	=>	'shatruSu',
	'dhAtR'		=>	'dhAtRSu',
	'graha'		=>	'graheSu',
	'rAma'		=>	'rAmeSu',
	'dIpa'		=>	'dIpeSu',
	);

for my $word (keys %saptamI_bahuvachana_puM_vibhakti_of){
    my $expected = sandhi($saptamI_bahuvachana_puM_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'saptamI', linga=>'puM',
vachana=>'bahuvachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_saptamI_bahuvachana_strI_vibhakti{
# bahuvachana, strIlinga
my %saptamI_bahuvachana_strI_vibhakti_of = (
	'bAlA'		=>	'bAlaasu',
	'mati'		=>	'matiSu',
	'nadI'		=>	'nadISu',
	'dhenu'		=>	'dhenuSu',
	'vadhU'		=>	'vadhUSu',
	'mAtR'		=>	'mAtRSu',
	);

for my $word (keys %saptamI_bahuvachana_strI_vibhakti_of){
    my $expected = sandhi($saptamI_bahuvachana_strI_vibhakti_of{$word});
    my $computed = sandhi(vibhakti({ naam=>$word, vibhakti=>'saptamI',
linga=>'strI', vachana=>'bahuvachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_saptamI_bahuvachana_napuMsaka_vibhakti{
# bahuvachana, napuMsakalinga
my %saptamI_bahuvachana_napuMsaka_vibhakti_of = (
	'vana'		=>	'vaneSu',
	'vAri'		=>	'vAriSu',
	'madhu'		=>	'madhuSu',
	'kartR'		=>	'kartRSu',
	);

for my $word (keys %saptamI_bahuvachana_napuMsaka_vibhakti_of){
    my $expected = sandhi($saptamI_bahuvachana_napuMsaka_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'saptamI', linga=>'napuMsaka',
vachana=>'bahuvachana'}));

    is( $computed, $expected, $expected );
	}
}
#############################
