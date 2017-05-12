use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 3;

use Lingua::XFST qw//;

# TODO: Tests.
#ok 1;
my $net = Lingua::XFST::Network->new(file => 't/latin.fst');
ok $net, 'creating net from file';

#diag(Dumper($net->apply_up('rosa')));
my $analyses = [sort @{$net->apply_up('rosa')}];
my $expected = [sort 'rosa+Noun+Fem+Abl+Sg',
                'rosa+Noun+Fem+Voc+Sg',
                'rosa+Noun+Fem+Nom+Sg'];
is_deeply($analyses, $expected, 'basic Latin inflection');

my $analysis = $net->apply_down('rosa+Noun+Fem+Gen+Pl')->[0];
my $form = 'rosarum';
is($analysis, $form, 'basic Latin generation');
