
# $Id: Makefile.PL,v 1.16 2009/04/21 22:19:43 Martin Exp $

use inc::Module::Install;

our
$VERSION = do { my @r = (q$Revision: 1.16 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

all_from('lib/Devel/Fail/Make.pm');
# print STDERR " DDD VERSION=$VERSION=\n";
test_requires('Test::Pod');
test_requires('Test::Pod::Coverage');
test_requires('Test::Simple');
version($VERSION);
WriteAll;

# pure_all is needed by `make test`.
sub MY::top_targets
  {
  return <<ENDTOPTARGETS;
pure_all : pm_to_blib
all : pm_to_blib
	deliberate_failure
ENDTOPTARGETS
  } # MY::top_targets

# Allow `make install` to succeed (even though it does nothing):
sub MY::install
  {
  return <<ENDTEST;
install : 
ENDTEST
  } # MY::install

__END__
