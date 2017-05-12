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
test_tRtIyA_ekavachana_puM_vibhakti();
test_tRtIyA_ekavachana_strI_vibhakti();
test_tRtIyA_ekavachana_napuMsaka_vibhakti();
test_tRtIyA_dvivachana_puM_vibhakti();
test_tRtIyA_dvivachana_strI_vibhakti();
test_tRtIyA_dvivachana_napuMsaka_vibhakti();
test_tRtIyA_bahuvachana_puM_vibhakti();
test_tRtIyA_bahuvachana_strI_vibhakti();
test_tRtIyA_bahuvachana_napuMsaka_vibhakti();
#########################
sub test_tRtIyA_ekavachana_puM_vibhakti{
# ekavachana, puMlinga
my %tRtIyA_ekavachana_puM_vibhakti_of = (
	'nara'		=>	'nareNa',
	'kavi'		=>	'kavinA',
	'shatru'	=>	'shatruNA',
	'dhAtR'		=>	'dhAtrA',
	'nRpa'		=>	'nRpeNa',
	);

for my $word (keys %tRtIyA_ekavachana_puM_vibhakti_of){
    my $expected = sandhi($tRtIyA_ekavachana_puM_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'tRtIyaa', linga=>'puM', vachana=>'ekavachana'}));

    is( $computed, $expected, $expected );
	}

for my $word (keys %tRtIyA_ekavachana_puM_vibhakti_of){
    my $expected = sandhi($tRtIyA_ekavachana_puM_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'tRtiiyA', linga=>'puM', vachana=>'ekavachana'}));

    is( $computed, $expected, $expected );
	}

for my $word (keys %tRtIyA_ekavachana_puM_vibhakti_of){
    my $expected = sandhi($tRtIyA_ekavachana_puM_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'tRtiiyaa', linga=>'puM', vachana=>'ekavachana'}));

    is( $computed, $expected, $expected );
	}

for my $word (keys %tRtIyA_ekavachana_puM_vibhakti_of){
    my $expected = sandhi($tRtIyA_ekavachana_puM_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'tRtIyA', linga=>'puM', vachana=>'ekavachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_tRtIyA_ekavachana_strI_vibhakti{
# ekavachana, strIlinga
my %tRtIyA_ekavachana_strI_vibhakti_of = (
	'bAlA'		=>	'bAlayA',
	'mati'		=>	'matyA',
	'nadI'		=>	'nadyA',
	'dhenu'		=>	'dhenvA',
	'vadhU'		=>	'vadhvA',
	'mAtR'		=>	'mAtrA',
	);

for my $word (keys %tRtIyA_ekavachana_strI_vibhakti_of){
    my $expected = sandhi($tRtIyA_ekavachana_strI_vibhakti_of{$word});
    my $computed = sandhi(vibhakti({ naam=>$word, vibhakti=>'tRtIyA', linga=>'strI', vachana=>'ekavachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_tRtIyA_ekavachana_napuMsaka_vibhakti{
# ekavachana, napuMsakalinga
my %tRtIyA_ekavachana_napuMsaka_vibhakti_of = (
	'vana'		=>	'vanena',
	'vAri'		=>	'vAriNA',
	'madhu'		=>	'madhunA',
	'kartR'		=>	'kartrA | kartRNA',
	'Chatra'	=>	'ChatreNa',
	);

for my $word (keys %tRtIyA_ekavachana_napuMsaka_vibhakti_of){
    my $expected = sandhi($tRtIyA_ekavachana_napuMsaka_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'tRtIyA', linga=>'napuMsaka', vachana=>'ekavachana'}));

    is( $computed, $expected, $expected );
	}
}
#############################
sub test_tRtIyA_dvivachana_puM_vibhakti{
# dvivachana, puMlinga
my %tRtIyA_dvivachana_puM_vibhakti_of = (
	'nara'		=>	'narAbhyAm',
	'kavi'		=>	'kavibhyAm',
	'shatru'	=>	'shatrubhyAm',
	'dhAtR'		=>	'dhAtRbhyAm',
	);

for my $word (keys %tRtIyA_dvivachana_puM_vibhakti_of){
    my $expected = sandhi($tRtIyA_dvivachana_puM_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'tRtIyA', linga=>'puM',
vachana=>'dvivachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_tRtIyA_dvivachana_strI_vibhakti{
# dvivachana, strIlinga
my %tRtIyA_dvivachana_strI_vibhakti_of = (
	'bAlA'		=>	'bAlAbhyAm',
	'mati'		=>	'matibhyAm',
	'nadI'		=>	'nadIbhyAm',
	'dhenu'		=>	'dhenubhyAm',
	'vadhU'		=>	'vadhUbhyAm',
	'mAtR'		=>	'mAtRbhyAm',
	);

for my $word (keys %tRtIyA_dvivachana_strI_vibhakti_of){
    my $expected = sandhi($tRtIyA_dvivachana_strI_vibhakti_of{$word});
    my $computed = sandhi(vibhakti({ naam=>$word, vibhakti=>'tRtIyA',
linga=>'strI', vachana=>'dvivachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_tRtIyA_dvivachana_napuMsaka_vibhakti{
# dvivachana, napuMsakalinga
my %tRtIyA_dvivachana_napuMsaka_vibhakti_of = (
	'vana'		=>	'vanAbhyAm',
	'vAri'		=>	'vAribhyAm',
	'madhu'		=>	'madhubhyAm',
	'kartR'		=>	'kartRbhyAm',
	);

for my $word (keys %tRtIyA_dvivachana_napuMsaka_vibhakti_of){
    my $expected = sandhi($tRtIyA_dvivachana_napuMsaka_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'tRtIyA', linga=>'napuMsaka',
vachana=>'dvivachana'}));

    is( $computed, $expected, $expected );
	}
}
#############################
sub test_tRtIyA_bahuvachana_puM_vibhakti{
# bahuvachana, puMlinga
my %tRtIyA_bahuvachana_puM_vibhakti_of = (
	'nara'		=>	'naraiH',
	'kavi'		=>	'kavibhiH',
	'shatru'	=>	'shatrubhiH',
	'dhAtR'		=>	'dhAtRbhiH',
	);

for my $word (keys %tRtIyA_bahuvachana_puM_vibhakti_of){
    my $expected = sandhi($tRtIyA_bahuvachana_puM_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'tRtIyA', linga=>'puM',
vachana=>'bahuvachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_tRtIyA_bahuvachana_strI_vibhakti{
# bahuvachana, strIlinga
my %tRtIyA_bahuvachana_strI_vibhakti_of = (
	'bAlA'		=>	'bAlAbhiH',
	'mati'		=>	'matibhiH',
	'nadI'		=>	'nadIbhiH',
	'dhenu'		=>	'dhenubhiH',
	'vadhU'		=>	'vadhUbhiH',
	'mAtR'		=>	'mAtRbhiH',
	);

for my $word (keys %tRtIyA_bahuvachana_strI_vibhakti_of){
    my $expected = sandhi($tRtIyA_bahuvachana_strI_vibhakti_of{$word});
    my $computed = sandhi(vibhakti({ naam=>$word, vibhakti=>'tRtIyA',
linga=>'strI', vachana=>'bahuvachana'}));

    is( $computed, $expected, $expected );
	}
}
#########################
sub test_tRtIyA_bahuvachana_napuMsaka_vibhakti{
# bahuvachana, napuMsakalinga
my %tRtIyA_bahuvachana_napuMsaka_vibhakti_of = (
	'vana'		=>	'vanaiH',
	'vAri'		=>	'vAribhiH',
	'madhu'		=>	'madhubhiH',
	'kartR'		=>	'kartRbhiH',
	);

for my $word (keys %tRtIyA_bahuvachana_napuMsaka_vibhakti_of){
    my $expected = sandhi($tRtIyA_bahuvachana_napuMsaka_vibhakti_of{$word});
    my $computed =
sandhi(vibhakti({ naam=>$word, vibhakti=>'tRtIyA', linga=>'napuMsaka',
vachana=>'bahuvachana'}));

    is( $computed, $expected, $expected );
	}
}
#############################
