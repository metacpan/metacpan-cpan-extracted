#!/usr/bin/perl

use Lingua::Identify ':language_manipulation';
use Test::More;

my @languages = qw/pt en de bg da es it fr fi hr nl ro ru pl el
                   la sq sv tr sl hu id uk hi cy cs/;

plan tests => 23 + scalar(@languages);

for (qw/zbr xx zz/, '') {
    is(is_valid_language($_), 0);
}

is_deeply(	[ get_all_languages()                      ],
		[ get_active_languages()                   ]);

is_deeply(	[ sort ( get_all_languages() )             ],
		[ sort ( get_active_languages() )          ]);

is_deeply(	[ sort ( get_all_languages() )             ],
		[ sort @languages                          ]);

is_deeply(	[ sort ( deactivate_language('pt') )       ],
		[ sort grep {! /^pt$/ } @languages         ]);

is_deeply(	[ sort ( get_active_languages() )          ],
		[ sort grep {! /^pt$/ } @languages         ]);

is_deeply(	[ get_inactive_languages()                 ],
		[ qw/pt/                                   ]);

is(is_active('pt'), 0);

is_deeply(	[ deactivate_all_languages()               ],
		[                                          ]);

is_deeply(	[ get_inactive_languages()                 ],
		[ get_all_languages()                      ]);

is_deeply(	[ activate_language('pt')                  ],
		[ qw/pt/                                   ]);

is(is_active('pt'), 1);

is_deeply(	[ sort ( set_active_languages(qw/pt ru/) ) ],
		[ qw/pt ru/                                ]);

is_deeply(	[ sort ( get_active_languages() )          ],
		[ qw/pt ru/                                ]);

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

for (get_all_languages()) {
    is(is_valid_language($_), 1);
}
