=head1 stable test

ok

=cut

use strict;
use warnings;
use utf8;

use Test::Deep;
use Test::More;
use Test::More::UTF8;
use lib::abs ();
use Data::Dumper;

use_ok( 'Locale::Babelfish' ) or exit;

my $dir = lib::abs::path('locales');

my $cfg = {
    dirs         => [ $dir ],
    default_lang => 'ru_RU',
    langs        => [ 'ru_RU', 'en_US', ],
    langs_short  => {
        RU => 'ru_RU',
        EN => 'en_US',
    },
};

my $l10n = Locale::Babelfish->new( $cfg );

is(
    $l10n->set_fallback( 'ru_RU', 'en_US' ),
    1,
    'set_fallback',
);


$l10n->locale('ru');

# Вложенные в списки словари с параметрами, повторные вызовы не должны кэшировать параметры

my @nested_items_with_params = @{ $l10n->t( 'test.nested.users_with_params', { user_id => 26532 } ) };
is scalar( @nested_items_with_params ), 2;
is_deeply $nested_items_with_params[0], { username => 'Ivan Petrov #26532' }, 'nested hash with params';
is_deeply $nested_items_with_params[1], { username => 'Sergey Ivanov #26532' }, 'nested hash with params';


@nested_items_with_params = @{ $l10n->t( 'test.nested.users_with_params', { user_id => 26533 } ) };
is scalar( @nested_items_with_params ), 2;
is_deeply $nested_items_with_params[0], { username => 'Ivan Petrov #26533' }, 'nested hash with params';
is_deeply $nested_items_with_params[1], { username => 'Sergey Ivanov #26533' }, 'nested hash with params';


done_testing;
