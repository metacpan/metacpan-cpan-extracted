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

use lib qw( /Users/tkach/regru/github/Locale-Babelfish/lib/  );
use Locale::Babelfish;


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
$l10n->set_fallback( 'ru_RU', 'en_US' );

$l10n->locale('ru');

#print Dumper($l10n);

# Глубоко вложенные в списки словари
my @deeply_nested_items = @{ $l10n->t('test.deeply_nested.company' ) };

print Dumper(\@deeply_nested_items);

# Глубоко вложенные в списки словари
my @nested_items = @{ $l10n->t('test.nested.users_with_params', { user_id => 26532 } ) };

print Dumper(\@nested_items);