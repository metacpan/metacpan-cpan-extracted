use strict;
use warnings;
use Test::More;
use Lingua::JA::Onbiki qw(onbiki2boin);
use utf8;

plan tests => 4;
is onbiki2boin('こーひー'), 'こおひい';
is onbiki2boin('コーヒー'), 'コオヒイ';
is onbiki2boin('あったか〜い'), 'あったかあい';
is onbiki2boin('つめた〜〜〜〜〜い'), 'つめたあああああい';
