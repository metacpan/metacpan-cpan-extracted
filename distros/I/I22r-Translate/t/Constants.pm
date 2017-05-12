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

# consistent, DRY configuration to use for most tests
sub basic_config {
    I22r::Translate->config(
	'I22r::Translate::Google' => {
	    ENABLED => 1,
	    API_KEY => $t::Constants::GOOGLE_API_KEY, # Google
	    REFERER => 'http://just.doing.some.testing/',
	    @_ } );
}


# t/Constants.pmx is a separate file, not included in
# the released distribution, that contains my personal
# API keys for testing and development.

if (-f "t/Constants.pmx" && !$ENV{RELEASE}) {
    # t/Constants.pmx is a file, not included with the I22r-Translate
    # distribution, that resides on the author's system and contains
    # his Google and Microsoft credentials.
    require "t/Constants.pmx";
} else {
    $t::Constants::GOOGLE_API_KEY = "get_a_Google_API_key_and_set_this_value";
    $t::Constants::CONFIGURED = 0;
}

1;
