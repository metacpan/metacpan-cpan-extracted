# -*- perl -*-

=head1 WHATS THIS

test that AutoCategorize can be used in a program that also uses
Log::Log4perl ':easy'.  It probably should have multiple classes
which use alternate modes, but that for later.

This test needs some work; while the 2 loggers share a single config,
that config still specifies 2 separate output files, with 2 different
layouts.

So I should write several new tests; 
* several packages in single file, with (easy, standard, auto)
* same with 3 user packages in different files
* sharing one log-file.

But that said, both output files are getting the complete output, from
both loggers (:easy and AutoCategorize).  Further, each has the
correct layout, as given in respective configs.

The :easy output also demonstrates that the Log::Log4perl has most of
the capabilities of AutoCategorize; %F %M %L contain the info that
AutoCat builds the category from.  The difference is in the ability to
filter on them, cuz theyre exposed in the category.


Note that use order matters; AutoCategorize must be 1st, cuz it adds 2
custom levels, which must be done before a logger is initialized,
which is done by :easy.  Those custom levels arent central to the
module, Ill probably make them optional/configurable in the next
release.


=cut

BEGIN {
    # it seems unholy to do this, but perl Core does..
    chdir 't' if -d 't';
    use lib '../lib';
    $ENV{PERL5LIB} = '../lib';    # so children will see it too
    unlink <out.09*>;
}

use Test::More (tests => 36);

use Log::Log4perl::AutoCategorize ( alias => 'myLogger',
				    initfile => 'log-conf', # no effect here
				    );
use Log::Log4perl qw(:easy);

myLogger->easy_init ({ level => $INFO,
		       file => "out.09_coexist_easy_easyout",
		       layout   => 'F=%F{1} M=%M L=%L: Cat=%c %m%n',
		   });
# add initialization wo resetting
Log::Log4perl::Config->_init('log-conf');

########################
# start tests
{
    # define another package to verify that pkgname is logged properly
    # note that this is NOT using t/A.pm
    package Aint;
    sub truck {
	# use :easy logger
	my $logger = Log::Log4perl::get_logger();
	$logger->error("this is err");
	$logger->warn("this is warn");
	$logger->debug("this is debug");

	# borrow AutoCategorize's logger
	Log::Log4perl::AutoCategorize->info("FQPN: cool");
	myLogger->info("Alias: cool");
    }
}

foreach (1..5) {
    myLogger->warn($_);
    myLogger->info($_);
    Aint::truck();
}

#####################################
# Now, look at the output

my ($stdout,$cover,$easy);
{
    local $/ = undef;
    my $fh;
    open ($fh, "out.09_coexist_easy");
    $stdout = <$fh>;
    # cover wont be written till this test ends !
    open ($fh, "out.09_coexist_easy.cover");
    $cover = <$fh>;
    open ($fh, "out.09_coexist_easy_easyout");
    $easy = <$fh>;
}

###############

ok ($stdout, "got output from AutoCat logger");
diag "test AutoCat output content vs expected logger layout";

foreach my $i (1..5) {
    like ($stdout, qr/main.main.warn.\d+: $i/ms, "found main.main.warn: $i");
    like ($stdout, qr/main.main.info.\d+: $i/ms, "found main.main.info: $i");
}

# test output of :easy logger
like ($stdout, qr/(Aint: this is err)/ms,
      "found :easy usage of \$logger->error()");
like ($stdout, qr/(Aint: this is warn)/ms, 
      "found :easy usage of \$logger->info()");

# test output of AutoCat logger
like ($stdout, qr/Aint.truck.info.\d+: FQPN:/ms,
      "found output from borrowed AutoCategorize logger (fully qualified)");
like ($stdout, qr/Aint.truck.info.\d+: Alias:/ms,
      "found output from borrowed AutoCategorize logger (aliased)");

@found = ($stdout =~ m/(Aint: this is err)/msg);
ok(@found == 5, "found 5 occurrences of '$1'");

@found = ($stdout =~ m/(Aint: this is warn)/msg);
ok(@found == 5, "found 5 occurrences of '$1'");

@found = ($stdout =~ m/(Aint: this is debug)/msg);
ok(@found == 0, "found 0 occurrences of suppressed (by :easy config) msg");

##########
diag "test :easy output content vs expected logger layout";
ok ($easy, "got output from :easy logger");

foreach my $i (1..5) {
    like ($easy, qr/Cat=main.main.warn.\d+ $i/ms, "found Cat=main.main.warn: $i");
    like ($easy, qr/Cat=main.main.info.\d+ $i/ms, "found Cat=main.main.info: $i");
}

# test output of :easy logger
like ($easy, qr/(M=Aint::truck .* this is err)/ms,
      "found :easy logger output");
like ($easy, qr/(M=Aint::truck .* this is warn)/ms, 
      "found :easy logger output");

# test output of AutoCat logger
like ($easy, qr/Aint.truck.info.\d+ FQPN:/ms,
      "found output from borrowed AutoCategorize logger (fully qualified)");
like ($easy, qr/Aint.truck.info.\d+ Alias:/ms,
      "found output from borrowed AutoCategorize logger (aliased)");

@found = ($easy =~ m/(Aint this is err)/msg);
ok(@found == 5, "found 5 occurrences of '$1'");

@found = ($easy =~ m/(Aint this is warn)/msg);
ok(@found == 5, "found 5 occurrences of '$1'");

@found = ($easy =~ m/(Aint this is debug)/msg);
ok(@found == 0, "found 0 occurrences of suppressed (by :easy config) msg");


__END__

