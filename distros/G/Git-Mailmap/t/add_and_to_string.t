#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

#  use Log::Any::Adapter ('Stderr'); # Activate to get all log messages.

require Git::Mailmap;
my $mailmap = Git::Mailmap->new();

my %expected_mailmap = ( 'committers' => [] );
is_deeply( $mailmap, \%expected_mailmap, 'Object internal data is empty.' );

$mailmap->add(
    'proper-email' => '<cto@company.xx>',
    'commit-email' => '<cto@coompany.xx>',
);
push @{ $expected_mailmap{'committers'} },
  {
    'proper-email' => '<cto@company.xx>',
    'aliases'      => [
        {
            'commit-email' => '<cto@coompany.xx>',
        }
    ],
  };
is_deeply( $mailmap, \%expected_mailmap, 'Object has one committer.' );

$mailmap->add(
    'proper-email' => '<some@dude.xx>',
    'proper-name'  => 'Some Dude',
    'commit-email' => '<bugs@company.xx>',
    'commit-name'  => 'nick1',
);
push @{ $expected_mailmap{'committers'} },
  {
    'proper-email' => '<some@dude.xx>',
    'proper-name'  => 'Some Dude',
    'aliases'      => [
        {
            'commit-email' => '<bugs@company.xx>',
            'commit-name'  => 'nick1',
        },
    ],
  };
is_deeply( $mailmap, \%expected_mailmap, 'Object has two committers.' );

$mailmap->add(
    'proper-email' => '<other@author.xx>',
    'proper-name'  => 'Other Author',
    'commit-email' => '<bugs@company.xx>',
    'commit-name'  => 'nick2',
);
$mailmap->add(
    'proper-email' => '<other@author.xx>',
    'proper-name'  => 'Other Author',
    'commit-email' => '<nick2@company.xx>',
);
push @{ $expected_mailmap{'committers'} },
  {
    'proper-email' => '<other@author.xx>',
    'proper-name'  => 'Other Author',
    'aliases'      => [
        {
            'commit-email' => '<bugs@company.xx>',
            'commit-name'  => 'nick2',
        },
        {
            'commit-email' => '<nick2@company.xx>',
        },
    ],
  };
is_deeply( $mailmap, \%expected_mailmap, 'Object has three committers, one has two emails.' );

$mailmap->add(
    'proper-email' => '<santa.claus@northpole.xx>',
    'proper-name'  => 'Santa Claus',
    'commit-email' => '<me@company.xx>',
);
push @{ $expected_mailmap{'committers'} },
  {
    'proper-email' => '<santa.claus@northpole.xx>',
    'proper-name'  => 'Santa Claus',
    'aliases'      => [
        {
            'commit-email' => '<me@company.xx>',
        },
    ],
  };
is_deeply( $mailmap, \%expected_mailmap, 'Object has four committers, one has two emails.' );

$mailmap->add(
    'proper-email' => '<me.myself@comp.xx>',
    'proper-name'  => 'Me Myself',
    'commit-email' => '<me.myself@comp.xx>',
    'commit-name'  => 'Me I Myself',
);
$mailmap->add(
    'proper-email' => '<me.myself@comp.xx>',
    'commit-email' => '<me@comp.xx>',
    'commit-name'  => 'me',
);
$mailmap->add(
    'proper-email' => '<me.myself@comp.xx>',
    'commit-email' => '<me.myself@comp.xx>',
    'commit-name'  => 'me',
);
$mailmap->add(
    'proper-email' => '<me.myself@comp.xx>',
    'proper-name'  => 'Me Too Myself',
);
push @{ $expected_mailmap{'committers'} },
  {
    'proper-email' => '<me.myself@comp.xx>',
    'proper-name'  => 'Me Too Myself',
    'aliases'      => [
        {
            'commit-email' => '<me.myself@comp.xx>',
            'commit-name'  => 'Me I Myself',
        },
        {
            'commit-email' => '<me@comp.xx>',
            'commit-name'  => 'me',
        },
        {
            'commit-email' => '<me.myself@comp.xx>',
            'commit-name'  => 'me',
        },
    ],
  };
is_deeply( $mailmap, \%expected_mailmap, 'Object has five committers, one has three emails.' );

my $mailmap_file = $mailmap->to_string();

## no critic (ValuesAndExpressions/ProhibitImplicitNewlines)
my $expected_mailmap_file = '<cto@company.xx> <cto@coompany.xx>
Some Dude <some@dude.xx> nick1 <bugs@company.xx>
Other Author <other@author.xx> nick2 <bugs@company.xx>
Other Author <other@author.xx> <nick2@company.xx>
Santa Claus <santa.claus@northpole.xx> <me@company.xx>
Me Too Myself <me.myself@comp.xx> Me I Myself <me.myself@comp.xx>
Me Too Myself <me.myself@comp.xx> me <me@comp.xx>
Me Too Myself <me.myself@comp.xx> me <me.myself@comp.xx>
';
is( $mailmap_file, $expected_mailmap_file, 'Printed out exactly as expected.' );

# This is from Git git-check-mailmap manual:
# http://man7.org/linux/man-pages/man1/git-check-mailmap.1.html
# my $expected_mailmap_file =
# '<cto@company.xx>                       <cto@coompany.xx>
# Some Dude <some@dude.xx>         nick1 <bugs@company.xx>
# Other Author <other@author.xx>   nick2 <bugs@company.xx>
# Other Author <other@author.xx>         <nick2@company.xx>
# Santa Claus <santa.claus@northpole.xx> <me@company.xx>
# ';

done_testing();

