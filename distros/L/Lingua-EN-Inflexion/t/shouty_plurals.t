use Test::More;
use Lingua::EN::Inflexion;

ok noun(q{DOGS})->is_plural     => q{is_plural: 'DOGS'};
ok noun(q{CATS})->is_plural     => q{is_plural: 'CATS'};
ok noun(q{PAPYRI})->is_plural   => q{is_plural: 'PAPYRI'};
ok noun(q{CHILDREN})->is_plural => q{is_plural: 'CHILDREN'};

ok !noun(q{DOGS})->is_singular     => q{!is_singular: 'DOGS'};
ok !noun(q{CATS})->is_singular     => q{!is_singular: 'CATS'};
ok !noun(q{PAPYRI})->is_singular   => q{!is_singular: 'PAPYRI'};
ok !noun(q{CHILDREN})->is_singular => q{!is_singular: 'CHILDREN'};

done_testing();

