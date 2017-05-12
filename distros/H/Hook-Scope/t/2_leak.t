
use strict;

use Test::More;

eval "use Devel::Leak";
if($@) {
	plan skip_all => "No Devel::Leak";
} else {
	plan tests => 5;
}
use_ok("Hook::Scope");
local($/);
close(STDERR); open(STDERR, "+>leak.out") || die;
my $handle;
Devel::Leak::NoteSV($handle);
{
    my $foo = "hi";
}
Devel::Leak::CheckSV($handle);
seek(STDERR,0,0);
is(<STDERR>, "", "Just checking so that plain scopes are safe");
close(STDERR); open(STDERR, "+>leak.out") || die;
Devel::Leak::NoteSV($handle);
{
  Hook::Scope::POST(sub { print STDERR "hi"});
}

Devel::Leak::CheckSV($handle);
seek(STDERR,0,0);
is(<STDERR>, "hi", "The scope should run, but not leak");
close(STDERR); open(STDERR, "+>leak.out") || die;



Devel::Leak::NoteSV($handle);
{
    my $bar;
    my $foo = sub { $bar = "foo"; print STDERR "hi"};
  Hook::Scope::POST($foo);
}
Devel::Leak::CheckSV($handle);
seek(STDERR,0,0);
is(<STDERR>, "hi", "Using outer declared lexicals should not leak");
close(STDERR); open(STDERR, "+>leak.out") || die;

Devel::Leak::NoteSV($handle);
{
    eval {
	{
	  Hook::Scope::POST(sub { print STDERR "hi1" });
	    die;
	}
    };
}
Devel::Leak::CheckSV($handle);
seek(STDERR,0,0);
is(<STDERR>, "hi1", "Using outer declared lexicals should not leak");
close(STDERR); open(STDERR, "+>leak.out") || die;
unlink "leak.out" while(-e "leak.out");
