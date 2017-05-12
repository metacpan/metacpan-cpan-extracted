# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl use.t'

#########################

use Test::More tests => 16;
use File::Append::TempFile;
pass 'Test::More loaded';

sub testf($ $)
{
	my ($f, $expr) = @_;

	print STDERR "A test failed: ".$f->err()."\n" unless $expr;
	return $expr;
}

open SF, '>', 'testfile.txt' or die "Could not open testfile.txt: $!\n";
print SF "This is a test.\nThis is only a test.\n";
close SF;
pass 'Test file created';

my $f = new File::Append::TempFile();
ok $f, 'File::Append::TempFile object created';
$f->diag(1) if defined $ENV{TEMPFILE_DEBUG};
ok testf($f, $f->begin_work('testfile.txt')), 'begin_work()';
ok testf($f, $f->add_line("Huh?\n")), 'add_line() 1';
ok testf($f, $f->rollback()), 'rollback()';
ok testf($f, $f->begin_work('testfile.txt')), 'begin_work() again';
ok testf($f, $f->add_line("If this were an actual emergency, do you think\n")), 'add_line() 2';
ok testf($f, $f->add_line("we'd have bothered to tell you?\n")), 'add_line() 3';
ok testf($f, $f->commit()), 'commit()';
ok testf($f, $f->begin_work('testfile.txt')), 'begin_work() yet again';
ok testf($f, $f->add_line("This ought to be rolled back\n")), 'add_line() 4';
if (open SF, '<', 'testfile.txt') {
	pass 'The test file still exists';
} else {
	warn "Could not open testfile.txt: $!\n";
	fail 'The test file still exists';
}
my $contents;
{ local $/; $contents = <SF>; }
is $contents, "This is a test.\n".
    "This is only a test.\n".
    "If this were an actual emergency, do you think\n".
    "we'd have bothered to tell you?\n", 'Lines added successfully';
close SF;

if (defined $ENV{TEMPFILE_DEBUG}) {
	is $f->diag(), 1, 'The diagnostics flag is still set';
	$f->diag(undef);
} else {
	ok !defined($f->diag()), 'The diagnostics flag is not set';
	$f->diag(0);
}
ok !$f->diag(), 'The diagnostics flag is not set';
