#!/usr/bin/env perl -w
use strict;
use Test::More qw(no_plan);

# by Eric Wilhelm in response to Randal Schwartz pointing out that
# CPAN.pm chokes on the VERSION >... construct
# I dare not mention it here.

use ExtUtils::MakeMaker;
use ExtUtils::Manifest qw(maniread);
use_ok('Jifty::DBI');

my $minfo = maniread();
ok($minfo) or die;

# XXX crossing my fingers against cross-platform and/or chdir issues
my @files = grep(/\.pm$/, grep(/^lib/, keys(%$minfo)));
ok(scalar(@files));
# die join "\n", '', @files, '';

foreach my $file (@files) {
        # Gah! parse_version complains on stderr!
        my ($e, @a) = error_catch(sub {MM->parse_version($file)});
        ok(($e || '') eq '', $file) or warn "$e ";
}

# runs subroutine reference, looking for error message $look in STDERR
# and runs tests based on $name
#   ($errs, @ans) = error_catch(sub {$this->test()});
#
sub error_catch {
        my ($sub) = @_;
        my $TO_ERR;
        open($TO_ERR, '<&STDERR');
        close(STDERR);
        my $catch;
        open(STDERR, '>', \$catch);
        my @ans = $sub->();
        open(STDERR, ">&", $TO_ERR);
        close($TO_ERR);
        return($catch, @ans);
} # end subroutine error_catch definition
########################################################################
