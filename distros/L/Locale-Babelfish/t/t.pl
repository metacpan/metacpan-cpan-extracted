=head1 stable test

ok

=cut

use strict;
use warnings;
use utf8;


use lib::abs ();
use Data::Dumper;

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


$l10n->locale('ru_RU');

# Вложенные в списки словари с параметрами

print "first call\n";
print Dumper( $l10n->t_or_undef( 'test.nested.users_with_params', { user_id => 26532 }) );
#$l10n->load_dictionaries();

print "second call\n";
print Dumper( $l10n->t_or_undef( 'test.nested.users_with_params', { user_id => 26533 }) );
1;
1;
