#################################################################
#
#   $Id: test-all.t,v 1.3 2006/07/18 12:40:06 erwan Exp $
#

use strict;
use warnings;
use Test::More;
use lib "../lib";
use lib "lib";
use Data::Dumper;

BEGIN {
    eval "use IPC::Open3"; plan skip_all => "IPC::Open3 is required for testing IPC::Open3::Simple" if $@;
    eval "use IO::Select"; plan skip_all => "IO::Select is required for testing IPC::Open3::Simple" if $@;
    eval "use IO::Handle"; plan skip_all => "IO::Handle is required for testing IPC::Open3::Simple" if $@;

    plan tests => 14;

    use_ok('IPC::Open3::Simple');
};

{
    # test running command
    my $runner = new IPC::Open3::Simple();
    $runner->run('touch /tmp/IPC-Open3-Simple-test1');
    ok(-e '/tmp/IPC-Open3-Simple-test1',"ran process (1 arg)");
    unlink '/tmp/IPC-Open3-Simple-test1';
    $runner->run('touch','/tmp/IPC-Open3-Simple-test2');
    ok(-e '/tmp/IPC-Open3-Simple-test2',"ran process (multiple args)");
    unlink '/tmp/IPC-Open3-Simple-test2';
}

{
    # test catching stdout
    my @lines;
    my $runner = new IPC::Open3::Simple(out => sub { push @lines, $_[0]; });
    $runner->run('echo foo; echo bar');
    is_deeply(\@lines,["foo","bar"],"out properly intercepted");
}

{
    # test catching stderr
    my @lines;
    my $cmd = 'perl -e "print STDERR \"foo\nbar\n\";"';
    IPC::Open3::Simple->new(err => sub { push @lines, $_[0]; })->run($cmd);
    is_deeply(\@lines,["foo","bar"],"err properly intercepted");
}

{
    # test feeding stdin
    my $fnc = sub {
	my $fh = shift;
	print $fh "foo\n";
	print $fh "bar\n";
	$fh->close();
    };

    IPC::Open3::Simple->new(in => $fnc)->run('cat > /tmp/IPC-Open3-Simple-test3');
    ok(-e '/tmp/IPC-Open3-Simple-test3',"cat created file");    
    my $content = `cat /tmp/IPC-Open3-Simple-test3`;
    is($content,"foo\nbar\n","file has right content");
}

{
    # test combined actions
    my $cnt = 0;
    my $fh_in;
    my $value = 11;

    my $auto = sub {
	my @args = @_;
	$cnt++;
	
	if ($cnt == 1) {
	    is($args[0],'in',"in sub called with stdin");
	    $fh_in = $args[1];
	    print $fh_in "$value\n";
	    $fh_in->close();
	} elsif ($cnt == 2 or $cnt == 3) {
	    if ($args[0] eq 'out') {
		if ($value =~ /1/) {
		    is($args[1],'match',"stdout says match");
		} else {
		    is($args[1],'no match',"stdout says no match");
		}
	    } elsif ($args[0] eq 'err') {
		is($args[1],'end',"right text on stderr");
	    } else {
		die "unexpected args: ".Dumper(@args);
	    }
	} else {
	    die "called sub once too much\n";
	}
    };

    my $cmd = 'perl -e "while (<>) { if (/1/) { print STDOUT \"match\";} else { print STDOUT \"no match\"; } } print STDERR\"end\";"';

    my $runner = IPC::Open3::Simple->new(in  => sub { &$auto('in',$_[0]); }, 
					 out => sub { &$auto('out',$_[0]); },
					 err => sub { &$auto('err',$_[0]); },
					 );
    $runner->run($cmd);

    $value = 0;
    $cnt = 0;

    $runner->run($cmd);
}

{
    # test errors
    eval {
	my $runner = new IPC::Open3::Simple(out => 'bob');
    };
    ok(defined $@ && $@ =~ /expects coderefs/,"argument validation in new()");
}
