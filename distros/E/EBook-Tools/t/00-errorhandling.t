# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl EBook-Tools.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 32;

# Add blib/scripts to the path to find the executables

BEGIN {
    use_ok('EBook::Tools');
    use_ok('EBook::Tools::BISG');

    if(not $ENV{'AUTOMATED_TESTING'})
    {
        # We have to ensure that the BISAC codes have been cached
        # locally as early as possible before we begin, or the subject
        # cleanup tests will fail in 20-Unpack.  Unfortunately, this
        # fails on some automated test environments, so we have to
        # skip it in both places.

        my $bisg = EBook::Tools::BISG->new();
        if(! $bisg->bisac() ) {
            $bisg->download_bisac;
            $bisg->save_bisac;
        }
    }
};
# $EBook::Tools::debug = 2;
my $ebook;
my ($meta1,$meta2);
my $thirdwarning = 'add_warning(): handling item for an <example> of a $very_long_warning with some Perl symbols thrown in';

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

$ebook = EBook::Tools->new();
isa_ok($ebook,'EBook::Tools', 'EBook::Tools->new()');
is($ebook->opffile,undef, 'new() has undefined opffile');
is($ebook->warnings,undef,'new(): no warnings');
is($ebook->errors,undef,'new(): no errors');

ok($ebook->add_warning('test warning'),'adding a single warning');
is(scalar(@{$ebook->warnings}),1,'a single warning found');
is(@{$ebook->warnings}[0],'test warning','warning has correct text');
@strings = ('second',' warning');
ok($ebook->add_warning(@strings),'adding a warning in array form');
is(scalar(@{$ebook->warnings}),2,'two warnings found');
is(@{$ebook->warnings}[1],'second warning','second warning has correct text');
ok($ebook->add_warning($thirdwarning),
    'adding a third long warning with odd text');
is(@{$ebook->warnings}[2],$thirdwarning,'third warning has correct text');
ok($ebook->clear_warnings(),'clearing warnings');
is($ebook->warnings,undef,'no warnings found');

ok($ebook->add_error('test error'),'adding a single error');
is(scalar(@{$ebook->errors}),1,'a single error found');
is(@{$ebook->errors}[0],'test error','error has correct text');
@strings = ('second',' error');
ok($ebook->add_error(@strings),'adding an error in array form');
is(scalar(@{$ebook->errors}),2,'second error found');
is(@{$ebook->errors}[1],'second error','second error has correct text');
ok($ebook->add_error($thirdwarning),
   'adding a third long error with odd text');
is(scalar(@{$ebook->errors}),3,'all errors found');
is(@{$ebook->errors}[2],$thirdwarning,'third error has correct text');
ok($ebook->clear_errors(),'clearing errors');
is($ebook->errors,undef,'no errors found');

$ebook->add_warning('another warning');
$ebook->add_error('another error');
is(scalar(@{$ebook->errors}),1,'added new error');
is(scalar(@{$ebook->warnings}),1,'added new warning');
ok($ebook->clear_warnerr(),'clearing errors and warnings');
is($ebook->errors,undef,'errors cleared');
is($ebook->warnings,undef,'warnings cleared');
