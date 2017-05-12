#!/usr/local/bin/perl

use strict;
use warnings;

use Test::More;

use HTML::FillInForm;
use HTML::TokeParser;

my $html = qq[<form><input type="text" name="one" value="all wrong"><input type="text" name="two" class="existing" value="worse"><input type="text" name="three" class="invalid" value="already bad"><select name="four"><option value="1">Foo</option><option value="2">Boo</option></select><textarea name="five"></textarea></form>];

{
    my $result =
      HTML::FillInForm->new->fill(scalarref      => \$html,
                                  fdat           => {two => "new val 2"},
                                  invalid_fields => ['one']);
    my $p = HTML::TokeParser->new(\$result);

    my $one = $p->get_tag('input')->[1];

    is($one->{name}, 'one');
    is($one->{class}, 'invalid');

    my $two       = $p->get_token->[2];
    is($two->{name}, 'two');
    isnt($two->{class},'invalid');
}
{
    my $result = HTML::FillInForm->new->fill(scalarref      => \$html,
                                          fdat           => {two => "new val 2"},
                                          invalid_fields => ['one', 'two', 'three', 'four', 'five']);
    my $p = HTML::TokeParser->new(\$result);

    my $one       = $p->get_tag('input')->[1];
    is($one->{name}, 'one');
    is($one->{class}, 'invalid');

    my $two       = $p->get_token->[2];
    is($two->{name}, 'two');
    is($two->{class},'existing invalid');

    my $three     = $p->get_token->[2];
    is($three->{name},'three');
    is($three->{class},'invalid');

    my $four      = $p->get_token->[2];
    is($four->{name},  'four');
    is($four->{class}, 'invalid');

    my $five = $p->get_tag('textarea')->[1];

    is($five->{name},'five');
    is($five->{class},'invalid');
}
{
    my $result = HTML::FillInForm->new->fill(scalarref      => \$html,
                                          fdat           => {two => "new val 2"},
                                          invalid_fields => ['one', 'three'],
                                          invalid_class  => "funky");
    my $p = HTML::TokeParser->new(\$result);

    my $one       = $p->get_tag('input')->[1];
    is($one->{name}, 'one');
    is($one->{class}, 'funky');

    my $two       = $p->get_token->[2];
    is($two->{name}, 'two');
    is($two->{class},'existing');

    my $three     = $p->get_token->[2];
    is($three->{name},'three');
    is($three->{class},'invalid funky');
}

done_testing();
