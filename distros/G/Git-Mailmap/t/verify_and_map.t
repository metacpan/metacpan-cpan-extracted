#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

# use Log::Any::Adapter ('Stderr');    # Activate to get all log messages.

require Git::Mailmap;
my $mailmap = Git::Mailmap->new();

# This is from Git git-check-mailmap manual (with slight changes):
# http://man7.org/linux/man-pages/man1/git-check-mailmap.1.html
## no critic (ValuesAndExpressions/ProhibitImplicitNewlines)
my $given_mailmap_file = '<cto@company.xx> <cto@coompany.xx>
Some Dude <some@dude.xx> nick1 <bugs@company.xx>
Other Author <other@author.xx> nick2 <bugs@company.xx>
Other Author <other@author.xx> <nick2@company.xx>
Santa Claus <santa.claus@northpole.xx> <me@company.xx>
Me Myself              <me.myself@comp.xx>
Me Myself              <me.myself@comp.xx>                Me I Myself     <me.myself@comp.xx>
Me Myself              <me.myself@comp.xx>                me                         <me@comp.xx>
Me Myself              <me.myself@comp.xx>                me                         <me.myself@comp.xx>
Me Too Myself          <me.myself@comp.xx>
';
$mailmap->from_string( 'mailmap' => $given_mailmap_file );

#verify
my $verified = $mailmap->verify( 'proper-email' => '<santa.claus@northpole.xx>' );
is( $verified, 1, 'Proper email verified.' );
$verified = $mailmap->verify( 'proper-email' => '<Santa.Claus@northpole.xx>' );
is( $verified, 0, 'Proper email verified (not found).' );
$verified = $mailmap->verify( 'commit-email' => '<me@company.xx>' );
is( $verified, 1, 'Commit email verified.' );
$verified = $mailmap->verify( 'commit-email' => '<Me@company.xx>' );
is( $verified, 0, 'Commit email verified (not found).' );
$verified = $mailmap->verify( 'proper-email' => '<cto@company.xx>' );
is( $verified, 1, 'Proper email verified.' );
$verified = $mailmap->verify(
    'proper-name'  => 'Some Dude',
    'proper-email' => '<some@dude.xx>'
);
is( $verified, 1, 'Proper email verified.' );
$verified = $mailmap->verify(
    'proper-name'  => 'SOME Dude',
    'proper-email' => '<some@dude.xx>'
);
is( $verified, 0, 'Proper email verified (not found).' );

$verified = $mailmap->verify(
    'proper-name'  => 'Some Dude With Wrong Name',
    'proper-email' => '<some@dude.xx>',
);
is( $verified, 0, 'Proper email verified. No match when wrong name.' );
$verified = $mailmap->verify(

    'proper-email' => '<some@dude.xx>',    # No proper-name this time!
);
is( $verified, 1, 'Proper email verified. Match when no name is given.' );

# Me Myselfs
is( $mailmap->verify( 'proper-name' => 'Me Myself', 'proper-email' => '<me.myself@comp.xx>' ),
    0, 'Me Myself, old proper name with same email verified not found.' );
is( $mailmap->verify( 'proper-name' => 'Me Too Myself', 'proper-email' => '<me.myself@comp.xx>' ),
    1, 'Me Myself, newer proper name and email verified.' );
is( $mailmap->verify( 'proper-email' => '<me.myself@comp.xx>' ), 1, 'Me Myself, proper email verified.' );

is( $mailmap->verify( 'commit-name' => 'Me I Myself', 'commit-email' => '<me.myself@comp.xx>' ),
    1, 'Me I Myself, commit name and email verified.' );
is( $mailmap->verify( 'commit-name' => 'me', 'commit-email' => '<me@comp.xx>' ),
    1, 'Me I Myself, another commit name and email verified.' );
is( $mailmap->verify( 'commit-name' => 'me', 'commit-email' => '<me.myself@comp.xx>' ),
    1, 'Me I Myself, third commit name and email verified.' );
is(
    $mailmap->verify(
        'proper-name'  => 'Me Too Myself',
        'proper-email' => '<me.myself@comp.xx>',
        'commit-name'  => 'me',
        'commit-email' => '<me.myself@comp.xx>'
    ),
    1,
    'Me I Myself, proper and commit name and email verified.'
);
is(
    $mailmap->verify(
        'proper-name'  => 'Me Not Myself',
        'proper-email' => '<me.myself@comp.xx>',
        'commit-name'  => 'me',
        'commit-email' => '<me.myself@comp.xx>'
    ),
    0,
    'Me I Myself, faulty proper and commit name and email verified.'
);
is(
    $mailmap->verify(
        'proper-name'  => 'Me Myself',
        'proper-email' => '<me.myself@comp.xx>',
        'commit-name'  => 'Me Not Myself',
        'commit-email' => '<me.myself@comp.xx>'
    ),
    0,
    'Me I Myself, faulty proper and commit name and email verified.'
);

# map
# my $proper_email;
# my $proper_name;
# ($proper_email,$proper_name) =
my @proper;
@proper = $mailmap->map( 'email' => '<cto@company.xx>' );
is_deeply( \@proper, [ undef, '<cto@company.xx>' ], 'Mapped <cto@company.xx> to <cto@company.xx>.' );
@proper = $mailmap->map( 'email' => '<cto@coompany.xx>' );
is_deeply( \@proper, [ undef, '<cto@company.xx>' ], 'Mapped <cto@coompany.xx> to <cto@company.xx>.' );
@proper = $mailmap->map( 'email' => '<some@dude.xx>' );
is_deeply( \@proper, [ 'Some Dude', '<some@dude.xx>' ], 'Mapped <some@dude.xx> to Some Dude.' );
@proper = $mailmap->map( 'email' => '<bugs@company.xx>' );
is_deeply(
    \@proper,
    [ 'Some Dude', '<some@dude.xx>' ],
    'Mapped <bugs@company.xx> to Some Dude (when no name, maps to first found email).'
);
@proper = $mailmap->map( 'name' => 'nick2', 'email' => '<bugs@company.xx>' );
is_deeply(
    \@proper,
    [ 'Other Author', '<other@author.xx>' ],
    'Mapped <other@author.xx> to Other Author (with name maps to another).'
);
@proper = $mailmap->map( 'email' => '<nick2@company.xx>' );
is_deeply(
    \@proper,
    [ 'Other Author', '<other@author.xx>' ],
    'Mapped <nick2@company.xx> to Other Author (found the second alias).'
);
@proper = $mailmap->map( 'email' => '<not_mapped_address@address>' );
is_deeply( \@proper, [ undef, undef ], 'Not mapped <not_mapped_address@address>.' );
@proper = $mailmap->map( 'email' => 'faulty_email_address>' );
is_deeply( \@proper, [ undef, undef ], 'Not mapped "faulty_email_address>".' );

done_testing();
__END__
<cto@company.xx>                                <cto@coompany.xx>
Some Dude <some@dude.xx>                  nick1 <bugs@company.xx>
Other Author <other@author.xx>            nick2 <bugs@company.xx>
Other Author <other@author.xx>                  <nick2@company.xx>
Santa Claus <santa.claus@northpole.xx>          <me@company.xx>
Me Myself              <me.myself@comp.xx>
Me Myself              <me.myself@comp.xx>                Me I Myself     <me.myself@comp.xx>
Me Myself              <me.myself@comp.xx>                me                         <me@comp.xx>
Me Myself              <me.myself@comp.xx>                me                         <me.myself@comp.xx>
Me Too Myself          <me.myself@comp.xx>

