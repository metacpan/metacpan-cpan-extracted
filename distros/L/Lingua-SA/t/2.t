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
test_dvitIyA_ekavachana_puM_vibhakti();
test_dvitIyA_ekavachana_strI_vibhakti();
test_dvitIyA_ekavachana_napuMsaka_vibhakti();
test_dvitIyA_dvivachana_puM_vibhakti();
test_dvitIyA_dvivachana_strI_vibhakti();
test_dvitIyA_dvivachana_napuMsaka_vibhakti();
test_dvitIyA_bahuvachana_puM_vibhakti();
test_dvitIyA_bahuvachana_strI_vibhakti();
test_dvitIyA_bahuvachana_napuMsaka_vibhakti();
#########################
sub test_dvitIyA_ekavachana_puM_vibhakti{
# ekavachana, puMlinga
my %dvitIyA_ekavachana_puM_vibhakti_of = (
	'nara'		=>	'naram',
	'kavi'		=>	'kavim',
	'shatru'	=>	'shatrum',
	'dhAtR'		=>	'dhAtAram',
	'nRpa'		=>	'nRpam',
	);

for my $word (keys %dvitIyA_ekavachana_puM_vibhakti_of){
    my $expected = sandhi($dvitIyA_ekavachana_puM_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'dvitIyaa', linga=>'puM', vachana=>'ekavachana'}));

    is( $computed, $expected, $expected );
	}

for my $word (keys %dvitIyA_ekavachana_puM_vibhakti_of){
    my $expected = sandhi($dvitIyA_ekavachana_puM_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'dvitiiyA', linga=>'puM', vachana=>'ekavachana'}));

    is( $computed, $expected, $expected );
	}

for my $word (keys %dvitIyA_ekavachana_puM_vibhakti_of){
    my $expected = sandhi($dvitIyA_ekavachana_puM_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'dvitiiyaa', linga=>'puM', vachana=>'ekavachana'}));

    is( $computed, $expected, $expected );
	}

for my $word (keys %dvitIyA_ekavachana_puM_vibhakti_of){
    my $expected = sandhi($dvitIyA_ekavachana_puM_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'dvitIyA', linga=>'puM', vachana=>'ekavachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_dvitIyA_ekavachana_strI_vibhakti{
# ekavachana, strIlinga
my %dvitIyA_ekavachana_strI_vibhakti_of = (
	'bAlA'		=>	'bAlaam',
	'mati'		=>	'matim',
	'nadI'	=>	'nadIm',
	'dhenu'		=>	'dhenum',
	'vadhU'		=>	'vadhUm',
	'mAtR'		=>	'mAtaram',
	);

for my $word (keys %dvitIyA_ekavachana_strI_vibhakti_of){
    my $expected = sandhi($dvitIyA_ekavachana_strI_vibhakti_of{$word});
    my $computed = sandhi(vibhakti({ naam=>$word, vibhakti=>'dvitIyA', linga=>'strI', vachana=>'ekavachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_dvitIyA_ekavachana_napuMsaka_vibhakti{
# ekavachana, napuMsakalinga
my %dvitIyA_ekavachana_napuMsaka_vibhakti_of = (
	'vana'		=>	'vanam',
	'vAri'		=>	'vAri',
	'madhu'	=>	'madhu',
	'kartR'		=>	'kartR',
	'Chatra'		=>	'Chatram',
	);

for my $word (keys %dvitIyA_ekavachana_napuMsaka_vibhakti_of){
    my $expected = sandhi($dvitIyA_ekavachana_napuMsaka_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'dvitIyA', linga=>'napuMsaka', vachana=>'ekavachana'}));

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
sub test_dvitIyA_dvivachana_puM_vibhakti{
# dvivachana, puMlinga
my %dvitIyA_dvivachana_puM_vibhakti_of = (
	'nara'		=>	'narau',
	'kavi'		=>	'kavI',
	'shatru'	=>	'shatrU',
	'dhAtR'		=>	'dhAtArau',
	);

for my $word (keys %dvitIyA_dvivachana_puM_vibhakti_of){
    my $expected = sandhi($dvitIyA_dvivachana_puM_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'dvitIyA', linga=>'puM',
vachana=>'dvivachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_dvitIyA_dvivachana_strI_vibhakti{
# dvivachana, strIlinga
my %dvitIyA_dvivachana_strI_vibhakti_of = (
	'bAlA'		=>	'bAle',
	'mati'		=>	'matI',
	'nadI'	=>	'nadyau',
	'dhenu'		=>	'dhenU',
	'vadhU'		=>	'vadhvau',
	'mAtR'		=>	'mAtarau',
	);

for my $word (keys %dvitIyA_dvivachana_strI_vibhakti_of){
    my $expected = sandhi($dvitIyA_dvivachana_strI_vibhakti_of{$word});
    my $computed = sandhi(vibhakti({ naam=>$word, vibhakti=>'dvitIyA',
linga=>'strI', vachana=>'dvivachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_dvitIyA_dvivachana_napuMsaka_vibhakti{
# dvivachana, napuMsakalinga
my %dvitIyA_dvivachana_napuMsaka_vibhakti_of = (
	'vana'		=>	'vane',
	'vAri'		=>	'vAriNI',
	'madhu'	=>	'madhunI',
	'kartR'		=>	'kartRNI',
	);

for my $word (keys %dvitIyA_dvivachana_napuMsaka_vibhakti_of){
    my $expected = sandhi($dvitIyA_dvivachana_napuMsaka_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'dvitIyA', linga=>'napuMsaka',
vachana=>'dvivachana'}));

    is( $computed, $expected, $expected );
	}
}
#############################
sub test_dvitIyA_bahuvachana_puM_vibhakti{
# bahuvachana, puMlinga
my %dvitIyA_bahuvachana_puM_vibhakti_of = (
	'nara'		=>	'naraan',
	'kavi'		=>	'kavIn',
	'shatru'	=>	'shatrUn',
	'dhAtR'		=>	'dhAtRRn',
	);

for my $word (keys %dvitIyA_bahuvachana_puM_vibhakti_of){
    my $expected = sandhi($dvitIyA_bahuvachana_puM_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'dvitIyA', linga=>'puM',
vachana=>'bahuvachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_dvitIyA_bahuvachana_strI_vibhakti{
# bahuvachana, strIlinga
my %dvitIyA_bahuvachana_strI_vibhakti_of = (
	'bAlA'		=>	'bAlaaH',
	'mati'		=>	'matIH',
	'nadI'	=>	'nadIH',
	'dhenu'		=>	'dhenUH',
	'vadhU'		=>	'vadhUH',
	'mAtR'		=>	'mAtRRH',
	);

for my $word (keys %dvitIyA_bahuvachana_strI_vibhakti_of){
    my $expected = sandhi($dvitIyA_bahuvachana_strI_vibhakti_of{$word});
    my $computed = sandhi(vibhakti({ naam=>$word, vibhakti=>'dvitIyA',
linga=>'strI', vachana=>'bahuvachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_dvitIyA_bahuvachana_napuMsaka_vibhakti{
# bahuvachana, napuMsakalinga
my %dvitIyA_bahuvachana_napuMsaka_vibhakti_of = (
	'vana'		=>	'vanaani',
	'vAri'		=>	'vArINi',
	'madhu'	=>	'madhUni',
	'kartR'		=>	'kartRRNi',
	);

for my $word (keys %dvitIyA_bahuvachana_napuMsaka_vibhakti_of){
    my $expected = sandhi($dvitIyA_bahuvachana_napuMsaka_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'dvitIyA', linga=>'napuMsaka',
vachana=>'bahuvachana'}));

    is( $computed, $expected, $expected );
	}
}
#############################
