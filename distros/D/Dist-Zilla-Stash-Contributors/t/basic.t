use strict;
use warnings;

use Dist::Zilla::Stash::Contributors;

use Test::More tests => 7;

my $stash = Dist::Zilla::Stash::Contributors->new;

$stash->add_contributors( 
    'Yanick Champoux <yanick@cpan.org>',
    'Ann Contributor <zann@foo.bar>',
    'Yanick Champoux <yanick@cpan.org>',
);

is_deeply [ $stash->all_contributors ], [
    'Ann Contributor <zann@foo.bar>',
    'Yanick Champoux <yanick@cpan.org>',
], "all_contributors()";

is $stash->nbr_contributors => 2, 'nbr_contributors';
    
my ( $cont ) = $stash->all_contributors;

isa_ok $cont => 'Dist::Zilla::Stash::Contributors::Contributor';

is $cont->name => 'Ann Contributor', "name";
is $cont->email => 'zann@foo.bar', "email";
is $cont->stringify => 'Ann Contributor <zann@foo.bar>', "stringify";

is "".$cont => 'Ann Contributor <zann@foo.bar>', "string overloading";

