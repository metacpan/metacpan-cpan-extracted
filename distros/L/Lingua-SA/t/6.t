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
test_ShaShThI_ekavachana_puM_vibhakti();
test_ShaShThI_ekavachana_strI_vibhakti();
test_ShaShThI_ekavachana_napuMsaka_vibhakti();
test_ShaShThI_dvivachana_puM_vibhakti();
test_ShaShThI_dvivachana_strI_vibhakti();
test_ShaShThI_dvivachana_napuMsaka_vibhakti();
test_ShaShThI_bahuvachana_puM_vibhakti();
test_ShaShThI_bahuvachana_strI_vibhakti();
test_ShaShThI_bahuvachana_napuMsaka_vibhakti();
#########################
sub test_ShaShThI_ekavachana_puM_vibhakti{
# ekavachana, puMlinga
my %ShaShThI_ekavachana_puM_vibhakti_of = (
	'nara'		=>	'narasya',
	'kavi'		=>	'kaveH',
	'shatru'	=>	'shatroH',
	'dhAtR'		=>	'dhAtuH',
	'nRpa'		=>	'nRpasya',
	);

for my $word (keys %ShaShThI_ekavachana_puM_vibhakti_of){
    my $expected = sandhi($ShaShThI_ekavachana_puM_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'ShaShThI', linga=>'puM', vachana=>'ekavachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_ShaShThI_ekavachana_strI_vibhakti{
# ekavachana, strIlinga
my %ShaShThI_ekavachana_strI_vibhakti_of = (
	'bAlA'		=>	'bAlaayaaH',
	'mati'		=>	'matyaaH | mateH',
	'nadI'	=>	'nadyaaH',
	'dhenu'		=>	'dhenoH | dhenvaaH',
	'vadhU'		=>	'vadhvaaH',
	'mAtR'		=>	'mAtuH',
	);

for my $word (keys %ShaShThI_ekavachana_strI_vibhakti_of){
    my $expected = sandhi($ShaShThI_ekavachana_strI_vibhakti_of{$word});
    my $computed = sandhi(vibhakti({ naam=>$word, vibhakti=>'ShaShThI', linga=>'strI', vachana=>'ekavachana'}));

    is( $computed, $expected, $expected );
	}

for my $word (keys %ShaShThI_ekavachana_strI_vibhakti_of){
    my $expected = sandhi($ShaShThI_ekavachana_strI_vibhakti_of{$word});
    my $computed = sandhi(vibhakti({ naam=>$word, vibhakti=>'ShaShThI',
		linga=>'strii', vachana=>'ekavachana'}));

    is( $computed, $expected, $expected );
	}

for my $word (keys %ShaShThI_ekavachana_strI_vibhakti_of){
    my $expected = sandhi($ShaShThI_ekavachana_strI_vibhakti_of{$word});
    my $computed = sandhi(vibhakti({ naam=>$word, vibhakti=>6,
		linga=>'strii', vachana=>'ekavachana'}));

    is( $computed, $expected, $expected );
	}

for my $word (keys %ShaShThI_ekavachana_strI_vibhakti_of){
    my $expected = sandhi($ShaShThI_ekavachana_strI_vibhakti_of{$word});
    my $computed = sandhi(vibhakti({ naam=>$word, vibhakti=>6,
		linga=>2, vachana=>'ekavachana'}));

    is( $computed, $expected, $expected );
	}

for my $word (keys %ShaShThI_ekavachana_strI_vibhakti_of){
    my $expected = sandhi($ShaShThI_ekavachana_strI_vibhakti_of{$word});
    my $computed = sandhi(vibhakti({ naam=>$word, vibhakti=>6,
		linga=>2, vachana=>1}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_ShaShThI_ekavachana_napuMsaka_vibhakti{
# ekavachana, napuMsakalinga
my %ShaShThI_ekavachana_napuMsaka_vibhakti_of = (
	'vana'		=>	'vanasya',
    'vAri'      =>  'vAriNaH',
    'shuci'     =>  'shucinaH',
	'madhu'	=>	'madhunaH',
	'kartR'		=>	'kartuH | kartRNaH',
	'Chatra'		=>	'Chatrasya',
	);

for my $word (keys %ShaShThI_ekavachana_napuMsaka_vibhakti_of){
    my $expected = sandhi($ShaShThI_ekavachana_napuMsaka_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'ShaShThI', linga=>'napuMsaka', vachana=>'ekavachana'}));

    is( $computed, $expected, $expected );
	}
}
#############################
#sub sandhi{
#my ($in)=@_;
##$in=~s/\s+\+\s+//;
#$in=~s/ \+ ([^\[])/$1/g;
#return $in;
#}
#########################
sub test_ShaShThI_dvivachana_puM_vibhakti{
# dvivachana, puMlinga
my %ShaShThI_dvivachana_puM_vibhakti_of = (
	'nara'		=>	'narayoH',
	'kavi'		=>	'kavyoH',
	'shatru'	=>	'shatrvoH',
	'dhAtR'		=>	'dhAtroH',
	);

for my $word (keys %ShaShThI_dvivachana_puM_vibhakti_of){
    my $expected = sandhi($ShaShThI_dvivachana_puM_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'ShaShThI', linga=>'puM',
vachana=>'dvivachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_ShaShThI_dvivachana_strI_vibhakti{
# dvivachana, strIlinga
my %ShaShThI_dvivachana_strI_vibhakti_of = (
	'bAlA'		=>	'bAlayoH',
	'mati'		=>	'matyoH',
	'nadI'	=>	'nadyoH',
	'dhenu'		=>	'dhenvoH',
	'vadhU'		=>	'vadhvoH',
	'mAtR'		=>	'mAtroH',
	);

for my $word (keys %ShaShThI_dvivachana_strI_vibhakti_of){
    my $expected = sandhi($ShaShThI_dvivachana_strI_vibhakti_of{$word});
    my $computed = sandhi(vibhakti({ naam=>$word, vibhakti=>'ShaShThI',
linga=>'strI', vachana=>'dvivachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_ShaShThI_dvivachana_napuMsaka_vibhakti{
# dvivachana, napuMsakalinga
my %ShaShThI_dvivachana_napuMsaka_vibhakti_of = (
	'vana'		=>	'vanayoH',
	'vAri'		=>	'vAriNoH',
	'madhu'	=>	'madhunoH',
	'kartR'		=>	'kartroH | kartRNoH',
	);

for my $word (keys %ShaShThI_dvivachana_napuMsaka_vibhakti_of){
    my $expected = sandhi($ShaShThI_dvivachana_napuMsaka_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'ShaShThI', linga=>'napuMsaka',
vachana=>'dvivachana'}));

    is( $computed, $expected, $expected );
	}
}
#############################
sub test_ShaShThI_bahuvachana_puM_vibhakti{
# bahuvachana, puMlinga
my %ShaShThI_bahuvachana_puM_vibhakti_of = (
	'nara'		=>	'naraaNaam',
	'kavi'		=>	'kavInaam',
	'shatru'	=>	'shatrUNaam',
	'dhAtR'		=>	'dhAtRRNaam',
	'graha'		=>	'grahaaNaam',
	'rAma'		=>	'rAmaaNaam',
	'dIpa'		=>	'dIpaanaam',
	);

for my $word (keys %ShaShThI_bahuvachana_puM_vibhakti_of){
    my $expected = sandhi($ShaShThI_bahuvachana_puM_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'ShaShThI', linga=>'puM',
vachana=>'bahuvachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_ShaShThI_bahuvachana_strI_vibhakti{
# bahuvachana, strIlinga
my %ShaShThI_bahuvachana_strI_vibhakti_of = (
	'bAlA'		=>	'bAlaanaam',
	'mati'		=>	'matInaam',
	'nadI'	=>	'nadInaam',
	'dhenu'		=>	'dhenUnaam',
	'vadhU'		=>	'vadhUnaam',
	'mAtR'		=>	'mAtRRNaam',
	);

for my $word (keys %ShaShThI_bahuvachana_strI_vibhakti_of){
    my $expected = sandhi($ShaShThI_bahuvachana_strI_vibhakti_of{$word});
    my $computed = sandhi(vibhakti({ naam=>$word, vibhakti=>'ShaShThI',
linga=>'strI', vachana=>'bahuvachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_ShaShThI_bahuvachana_napuMsaka_vibhakti{
# bahuvachana, napuMsakalinga
my %ShaShThI_bahuvachana_napuMsaka_vibhakti_of = (
	'vana'		=>	'vanaanaam',
	'vAri'		=>	'vArINaam',
	'madhu'	=>	'madhUnaam',
	'kartR'		=>	'kartRRNaam',
	);

for my $word (keys %ShaShThI_bahuvachana_napuMsaka_vibhakti_of){
    my $expected = sandhi($ShaShThI_bahuvachana_napuMsaka_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'ShaShThI', linga=>'napuMsaka',
vachana=>'bahuvachana'}));

    is( $computed, $expected, $expected );
	}
}
#############################
