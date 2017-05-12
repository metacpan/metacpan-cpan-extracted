package t::Constants;

##################################################################
# some backend-specific constants that must be
# set before those backends can be used for
# testing. See the variable assignments at the
# bottom of this file and change them if you want
# to run tests with those backends.
##################################################################

sub skip_remaining_tests {
    warn q@

*******************************************************
***     live translation tests not configured!      ***
*******************************************************
*                                                     *
* If you want to enable live translation tests for    *
* the Google and Microsoft backends, edit the         *
* variable definitions at the bottom of the file      *
*                                                     *
*     t/Constants.pm                                  *
*                                                     *
* Also, set  $t::Constants::CONFIGURED  to  1         *
* instead of  0 .                                     *
*******************************************************


@;
    Test::More::done_testing();
    exit;
}

# consistent, DRY configuration across all tests
sub basic_config {
  I22r::Translate->config(
      'I22r::Translate::Microsoft' => {
	  ENABLED => 1,
	  CLIENT_ID => $t::Constants::BING_CLIENT_ID,
	  SECRET => $t::Constants::BING_SECRET,
	  @_
      } );
}


# t/Constants.pmx is a separate file, not included in
# the released distribution, that contains my personal
# API keys for testing and development.

if (-f "t/Constants.pmx" && !$ENV{RELEASE}) {
    # t/Constants.pmx is a file, not included in this distribution,
    # that resides on the author's system and includes his credentials
    # for Microsoft data services.
    require "t/Constants.pmx";
} else {
    $t::Constants::BING_CLIENT_ID = "not used yet";
    $t::Constants::BING_SECRET = "not_used_until_we_add_MS_backend";
    $t::Constants::CONFIGURED = 0;
}

1;
