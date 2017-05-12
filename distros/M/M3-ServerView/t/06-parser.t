#!/usr/bin/perl

use strict;
use warnings;

{
    package Test::M3::ServerView::MockEntry;

    use base qw(M3::ServerView::Entry);
    
    our $called_new = 0;
    sub new {
        my ($pkg) = @_;
        $called_new++;
        return $pkg->SUPER::new(@_);
    }    
}

{
    package Test::M3::ServerView::MockView;

    use base qw(M3::ServerView::View);
    
    our $called_entry_class = 0;
    sub _entry_class { 
        $called_entry_class++;
        "Test::M3::ServerView::MockEntry"; 
    }
    
    our $called_entry_columns;
    sub _entry_columns {
        $called_entry_columns++;
        return (
            no      => [ no => "text" ],
            type    => [ type => "text" ],
            address => sub { 
                my ($entry, $v) = @_;
                return unless ref $v && $v->isa("URI");
                if ($v->path eq "/super") {
                    $entry->{super} = $v;
                }
            },
            num     => [ num => "numeric" ],
        )
    }
    
    our @entries;
    our $called_add_entry = 0;
    sub _add_entry {
        my ($self, $entry) = @_;        
        $called_add_entry++;
        push @entries, $entry;
    }
}

use Test::More tests => 10;

BEGIN { use_ok("M3::ServerView::Parser"); }

my $v = Test::M3::ServerView::MockView->new();
my $parser = M3::ServerView::Parser->new($v);

is($Test::M3::ServerView::MockView::called_entry_class, 1);
is($Test::M3::ServerView::MockView::called_entry_columns, 1);
is($Test::M3::ServerView::MockView::called_add_entry, 0);

$parser->parse(qq{
<h3><b><td align "center">Movex 12.4.3 AMO PROD ServerView: linas1.linserv.se/194.17.14.105:6666</td></b></h3>
<table cellpadding="1" cellspacing="1" BORDER="0"><tr><td><a href="http://linas1.linserv.se:6666/">Home</a></td><td><a href="http://linas1.linserv.se:6666/threads?addr=194.17.14.105&port=6500">Threads</a></td><td><a href="http://linas1.linserv.se:6666/counters?addr=194.17.14.105&port=6500">Counters</a></td><td><a href="http://linas1.linserv.se:6666/runjob">Run</a></td><td><a href="http://linas1.linserv.se:6666/findjob">Find job</a></td><td><a href="http://linas1.linserv.se:6666/findclass?addr=194.17.14.105&port=6500">Find class</a></td><td><a href="http://linas1.linserv.se:6666/jvminfo?addr=194.17.14.105&port=6500">JVM info</a></td><td><a href="http://linas1.linserv.se:6666/properties?addr=194.17.14.105&port=6500">Properties</a></td><td><a href="http://linas1.linserv.se:6666/showlog?addr=194.17.14.105&port=6500">Log</a></td><td><a href="http://linas1.linserv.se:6666/tools">Tools</a></td><td><a href="http://linas1.linserv.se:6666/prefs">Customize</a></td><td><a href="http://linas1.linserv.se:6666/news">News</a></td></tr>
</table>
});

is($Test::M3::ServerView::MockView::called_add_entry, 0);
is($parser->{table_is_data}, 0);

$v = Test::M3::ServerView::MockView->new();
$parser = M3::ServerView::Parser->new($v);

$parser->parse(qq{
<h3><b><td align "center">Movex 12.4.3 AMO PROD ServerView: linas1.linserv.se/194.17.14.105:6666</td></b></h3>
<table cellpadding="1" cellspacing="1" BORDER="0"><tr><td><a href="http://linas1.linserv.se:6666/">Home</a></td><td><a href="http://linas1.linserv.se:6666/threads?addr=194.17.14.105&port=6500">Threads</a></td><td><a href="http://linas1.linserv.se:6666/counters?addr=194.17.14.105&port=6500">Counters</a></td><td><a href="http://linas1.linserv.se:6666/runjob">Run</a></td><td><a href="http://linas1.linserv.se:6666/findjob">Find job</a></td><td><a href="http://linas1.linserv.se:6666/findclass?addr=194.17.14.105&port=6500">Find class</a></td><td><a href="http://linas1.linserv.se:6666/jvminfo?addr=194.17.14.105&port=6500">JVM info</a></td><td><a href="http://linas1.linserv.se:6666/properties?addr=194.17.14.105&port=6500">Properties</a></td><td><a href="http://linas1.linserv.se:6666/showlog?addr=194.17.14.105&port=6500">Log</a></td><td><a href="http://linas1.linserv.se:6666/tools">Tools</a></td><td><a href="http://linas1.linserv.se:6666/prefs">Customize</a></td><td><a href="http://linas1.linserv.se:6666/news">News</a></td></tr>
</table>
<hr WIDTH="100%"<p>
<table cellpadding="1" cellspacing="1" WIDTH="100%" BORDER="0"><tr bgcolor="#333333"><th align="left">No</th><th align="left">Type</th><th align="left">Address</th></tr></table>
});

is($Test::M3::ServerView::MockView::called_add_entry, 0);
is($parser->{table_is_data}, 1);

$v = Test::M3::ServerView::MockView->new();
$parser = M3::ServerView::Parser->new($v);

$parser->parse(qq{
<h3><b><td align "center">Movex 12.4.3 AMO PROD ServerView: linas1.linserv.se/194.17.14.105:6666</td></b></h3>
<table cellpadding="1" cellspacing="1" BORDER="0"><tr><td><a href="http://linas1.linserv.se:6666/">Home</a></td><td><a href="http://linas1.linserv.se:6666/threads?addr=194.17.14.105&port=6500">Threads</a></td><td><a href="http://linas1.linserv.se:6666/counters?addr=194.17.14.105&port=6500">Counters</a></td><td><a href="http://linas1.linserv.se:6666/runjob">Run</a></td><td><a href="http://linas1.linserv.se:6666/findjob">Find job</a></td><td><a href="http://linas1.linserv.se:6666/findclass?addr=194.17.14.105&port=6500">Find class</a></td><td><a href="http://linas1.linserv.se:6666/jvminfo?addr=194.17.14.105&port=6500">JVM info</a></td><td><a href="http://linas1.linserv.se:6666/properties?addr=194.17.14.105&port=6500">Properties</a></td><td><a href="http://linas1.linserv.se:6666/showlog?addr=194.17.14.105&port=6500">Log</a></td><td><a href="http://linas1.linserv.se:6666/tools">Tools</a></td><td><a href="http://linas1.linserv.se:6666/prefs">Customize</a></td><td><a href="http://linas1.linserv.se:6666/news">News</a></td></tr>
</table>
<hr WIDTH="100%"<p>
<table cellpadding="1" cellspacing="1" WIDTH="100%" BORDER="0"><tr bgcolor="#333333"><th align="left">No</th><th align="left">Type</th><th align="left">Address</th><th>Num</th></tr>
<tr bgcolor="#232323"><td>1</td><td>Supervisor</td><td><a href="http://linas1.linserv.se:6666/super?addr=194.17.14.105&port=6500">linas1.linserv.se:6500</a></td><td>-</td></tr>
<tr bgcolor="#232323"><td>2</td><td>Sub:A</td><td></td><td>1</td></tr></table>
});

is($Test::M3::ServerView::MockView::called_add_entry, 2);

is_deeply(\@Test::M3::ServerView::MockView::entries, [ { 
    num => undef, type => "Supervisor", no => 1
}, {
    num => 1, type => "Sub:A", no => 2
}]);
