#!/usr/bin/perl

use Test::More tests => 14;

BEGIN {
    use_ok('Lingua::Identify', qw/:language_manipulation :language_identification/)
};

# Check language of undef or space...
is(langof(), undef, "Language of nothing is undefined");

my @undef = langof();
is_deeply( [ @undef ] , [ ] , "Language of nothing is nothing");

is(langof( { method => 'smallwords' }, ' '), undef, "Language of space is undefined");



# Check language for word 'melhor'
# my @pt = langof( { method => 'suffixes4' }, 'melhor');
# is_deeply( [ @pt ], [ 'pt', 1 ],
#            "list of possible languages with 'melhor' word, using 'suffixes4' method.");
# is_deeply(confidence(@pt), 1,
#            "Confidence for 'melhor' being portuguese using 'suffixes4' method.");



my @xx = langof( { method => 'suffixes4' }, 'z');

is_deeply( [ @xx ], [ ]);
is_deeply(confidence(@xx), 0 );


is_deeply(	[ deactivate_all_languages()               ],
		[                                          ]);

is_deeply(	[ get_active_languages()                   ],
		[                                          ]);

my @pt = langof( { method => 'suffixes4' }, 'melhor');

is_deeply( [ @pt ], [  ]);
is_deeply(confidence(@pt), 0 );


is_deeply(	[ sort ( set_active_languages(qw/pt/) )    ],
		[ qw/pt/                                   ]);


is_deeply(	[ get_active_languages()                   ],
		[ qw/pt/                                   ]);


@pt = langof( { method => 'suffixes4' }, 'zzzzzz');

is_deeply( [ @pt ], [ ]);
is_deeply(confidence(@pt), 0 );

__END__




is_deeply(	[ sort ( get_active_languages() )          ],
		[ qw/fr it/                                ]);

is_deeply(	[ activate_all_languages()                 ],
		[ get_all_languages()                      ]);

is(name_of('pt'), 'portuguese');

deactivate_all_languages();

is_deeply(	[ get_active_languages()                   ],
		[                                          ]);

is_deeply(      [ activate_all_languages()                 ],
                [ get_all_languages                        ]);

is_deeply(	[ sort ( get_all_languages() )             ],
		[ sort @languages                          ]);

is_deeply(	[ sort ( get_active_languages() )          ],
		[ sort @languages                          ]);
