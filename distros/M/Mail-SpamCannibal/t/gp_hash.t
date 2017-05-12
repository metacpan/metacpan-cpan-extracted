# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}

use Mail::SpamCannibal::GoodPrivacy;

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

umask 027;
foreach my $dir (qw(tmp pgptmpdir)) {
  if (-d $dir) {         # clean up previous test runs
    opendir(T,$dir);
    @_ = grep(!/^\./, readdir(T));
    closedir T;
    foreach(@_) {
      unlink "$dir/$_";
    }
    rmdir $dir or die "COULD NOT REMOVE $dir DIRECTORY\n";
  }
  unlink $dir if -e $dir;	# remove files of this name as well
}

sub ok {
  print "ok $test\n";
  ++$test;
}

sub _testme {
  goto &Mail::SpamCannibal::GoodPrivacy::_testme;
}

my %hash = (
        Data      => 'my data test string',
        ExeFile   => './tlib/nop.sh',
        KeyPath   => './',
        Password  => 'TEST',
        TmpDir    => './tmp',
        Version   => '2.62',    # unused
);

my $copy = {};

sub copy {
  %$copy = %hash;
}

sub crash {
  my $exp = shift;
  eval { _testme($copy); };
  print "failed to die and make error:\n$exp\ngot:\n$@\nnot "
	unless $@ && $@ =~ /$exp/;
  &ok;
}

# check DIE
## test 2 -- clean, no death
eval {_testme(\%hash);};
print "not clean\n@_\nnot "
	if @_;
&ok;

## test 3 -- Data missing
copy;
delete $copy->{Data};
crash('No data present');

## test 4 -- Data empty
$copy->{Data} = '';
crash('No data present');

## test 5 -- ExeFile missing
copy;
delete $copy->{ExeFile};
crash('PGP exe file missing or not executable by effective UID');

## test 6 -- ExeFile file empty
$copy->{ExeFile} = '';
crash('PGP exe file missing or not executable by effective UID');

## test 7 -- ExeFile non-existent
$copy->{ExeFile} = 'tlib/not_there';
crash('PGP exe file missing or not executable by effective UID');

chmod 0644, 'tlib/exists_but_dead';

## test 8 -- ExeFile not executable
$copy->{ExeFile} = 'tlib/exists_but_dead';
crash('PGP exe file missing or not executable by effective UID');

## test 9 -- KeyPath really not there
copy;
$copy->{KeyPath} = './__no__such__directory';
crash('Key path ./__no__such__directory does not exist');
