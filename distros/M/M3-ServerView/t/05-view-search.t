#!/usr/bin/perl

use strict;
use warnings;

{
    package M3::ServerView::View::MockEntry;
    
    sub DESTROY {}
    
    our $AUTOLOAD;
    sub AUTOLOAD {
        my ($key) = $AUTOLOAD =~ /::(\w+)$/;
        my $method = sub {
            my ($self) = @_;
            return $self->{$key};
        };
        
        no strict "refs";
        *{$key} = $method;
        goto &$method;
    }
}

use Test::More tests => 40;
use Test::Exception;

BEGIN { use_ok("M3::ServerView::View"); }

my $view = M3::ServerView::View->new();

my $count = 0;
while(<DATA>) {
    chomp;
    my @fields = split/;/,$_;
    @fields = map { split/=/,$_,2 } @fields;
    my $entry = bless { @fields }, "M3::ServerView::View::MockEntry";
    use Data::Dumper qw(Dumper);
    $view->_add_entry($entry);
    $count++;
}

my $entries = $view->_entries;
ok(defined $entries);
is(ref $entries, "ARRAY");
is(@$entries, $count);

my $rs = $view->search();
isa_ok($rs, "M3::ServerView::ResultSet");
is($rs->count, $count);

$rs = $view->search({ foo => 1 });
is($rs->count, 1);

$rs = $view->search({ foo => [ "<" => 3 ] });
is($rs->count, 2);

$rs = $view->search({ foo => 3, bar => 20 });
is($rs->count, 1);

$rs = $view->search({ baz => "a" });
is($rs->count, 2);

$rs = $view->search({ baz => "a" }, { case_sensitive => 1 });
is($rs->count, 1);

$rs = $view->search({}, { order_by => "x" });
is($rs->count, 6);
is($rs->next->{x}, 1);
is($rs->next->{x}, 2);
is($rs->next->{x}, 3);
is($rs->next->{x}, 4);
is($rs->next->{x}, 5);
is($rs->next->{x}, 6);

$rs = $view->search({}, { order_by => "x", sort_order => "desc" });
is($rs->count, 6);
is($rs->next->{x}, 6);
is($rs->next->{x}, 5);
is($rs->next->{x}, 4);
is($rs->next->{x}, 3);
is($rs->next->{x}, 2);
is($rs->next->{x}, 1);

$rs = $view->search({}, { order_by => "y", sort_as => "text" });
is($rs->count, 6);
is($rs->next->{x}, 1);
is($rs->next->{x}, 2);
is($rs->next->{x}, 3);
is($rs->next->{x}, 4);
is($rs->next->{x}, 5);
is($rs->next->{x}, 6);

$rs = $view->search({}, { order_by => "y", sort_as => "text", sort_order => "desc" });
is($rs->count, 6);
is($rs->next->{x}, 6);
is($rs->next->{x}, 5);
is($rs->next->{x}, 4);
is($rs->next->{x}, 3);
is($rs->next->{x}, 2);
is($rs->next->{x}, 1);


throws_ok {
    $view->search({}, { order_by => 'x', sort_order => "foo" });
} qr/Sort order must be either 'asc' or 'desc'/;

__DATA__
foo=1;bar=20;x=4;y=D
foo=2;x=3;y=C
foo=3;bar=20;x=6;y=F
foo=3;bar=15;x=5;y=E
baz=A;x=1;y=A
baz=a;x=2;y=B