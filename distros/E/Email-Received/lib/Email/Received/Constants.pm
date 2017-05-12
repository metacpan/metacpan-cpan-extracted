package Email::Received::Constants;
use base qw( Exporter );

@IP_VARS = qw(
	LOCALHOST IPV4_ADDRESS IP_ADDRESS
);
our @EXPORT = @IP_VARS;

use constant LOCALHOST => qr/
		    (?:
		      # as a string
		      localhost(?:\.localdomain)?
		    |
		      \b(?<!:)	# ensure no "::" IPv4 marker before this one
		      # plain IPv4
		      127\.0\.0\.1 \b
		    |
		      # IPv6 addresses
		      # don't use \b here, it hits on :'s
		      (?:IPv6:    # with optional prefix
                        | (?<![a-f0-9:])
                      )
		      (?:
			# IPv4 mapped in IPv6
			# note the colon after the 12th byte in each here
			(?:
			  # first 6 (12 bytes) non-zero
			  (?:0{1,4}:){5}		ffff:
			  |
			  # leading zeros omitted (note {0,5} not {1,5})
			  ::(?:0{1,4}:){0,4}		ffff:
			  |
			  # trailing zeros (in the first 6) omitted
			  (?:0{1,4}:){1,4}:		ffff:
			  |
			  # 0000 in second up to (including) fifth omitted
			  0{1,4}::(?:0{1,4}:){1,3}	ffff:
			  |
			  # 0000 in third up to (including) fifth omitted
			  (?:0{1,4}:){2}:0{1,2}:	ffff:
			  |
			  # 0000 in fourth up to (including) fifth omitted
			  (?:0{1,4}:){3}:0:		ffff:
			  |
			  # 0000 in fifth omitted
			  (?:0{1,4}:){4}:		ffff:
			)
			# and the IPv4 address appended to all of the 12 bytes above
			127\.0\.0\.1	# no \b, we check later

			| # or (separately) a pure IPv6 address

			# all 8 (16 bytes) of them present
			(?:0{1,4}:){7}			0{0,3}1
			|
			# leading zeros omitted
			:(?::0{1,4}){0,6}:		0{0,3}1
			|
			# 0000 in second up to (including) seventh omitted
			0{1,4}:(?::0{1,4}){0,5}:	0{0,3}1
			|
			# 0000 in third up to (including) seventh omitted
			(?:0{1,4}:){2}(?::0{1,4}){0,4}:	0{0,3}1
			|
			# 0000 in fouth up to (including) seventh omiited
			(?:0{1,4}:){3}(?::0{1,4}){0,3}:	0{0,3}1
			|
			# 0000 in fifth up to (including) seventh omitted
			(?:0{1,4}:){4}(?::0{1,4}){0,2}:	0{0,3}1
			|
			# 0000 in sixth up to (including) seventh omitted
			(?:0{1,4}:){5}(?::0{1,4}){0,1}:	0{0,3}1
			|
			# 0000 in seventh omitted
			(?:0{1,4}:){6}:			0{0,3}1
		      )
		      (?![a-f0-9:])
		    )
		  /oxi;

use constant IPV4_ADDRESS => qr/\b
		    (?:1\d\d|2[0-4]\d|25[0-5]|\d\d|\d)\.
                    (?:1\d\d|2[0-4]\d|25[0-5]|\d\d|\d)\.
                    (?:1\d\d|2[0-4]\d|25[0-5]|\d\d|\d)\.
                    (?:1\d\d|2[0-4]\d|25[0-5]|\d\d|\d)
                  \b/ox;

use constant IP_ADDRESS => qr/
		    (?:
		      \b(?<!:)	# ensure no "::" IPv4 marker before this one
		      # plain IPv4, as above
		      (?:1\d\d|2[0-4]\d|25[0-5]|\d\d|\d)\.
		      (?:1\d\d|2[0-4]\d|25[0-5]|\d\d|\d)\.
		      (?:1\d\d|2[0-4]\d|25[0-5]|\d\d|\d)\.
		      (?:1\d\d|2[0-4]\d|25[0-5]|\d\d|\d)\b
		    |
		      # IPv6 addresses
		      # don't use \b here, it hits on :'s
		      (?:IPv6:    # with optional prefix
                        | (?<![a-f0-9:])
                      )
		      (?:
			# IPv4 mapped in IPv6
			# note the colon after the 12th byte in each here
			(?:
			  # first 6 (12 bytes) non-zero
			  (?:[a-f0-9]{1,4}:){6}
			  |
			  # leading zeros omitted (note {0,5} not {1,5})
			  ::(?:[a-f0-9]{1,4}:){0,5}
			  |
			  # trailing zeros (in the first 6) omitted
			  (?:[a-f0-9]{1,4}:){1,5}:
			  |
			  # 0000 in second up to (including) fifth omitted
			  [a-f0-9]{1,4}::(?:[a-f0-9]{1,4}:){1,4}
			  |
			  # 0000 in third up to (including) fifth omitted
			  (?:[a-f0-9]{1,4}:){2}:(?:[a-f0-9]{1,4}:){1,3}
			  |
			  # 0000 in fourth up to (including) fifth omitted
			  (?:[a-f0-9]{1,4}:){3}:(?:[a-f0-9]{1,4}:){1,2}
			  |
			  # 0000 in fifth omitted
			  (?:[a-f0-9]{1,4}:){4}:[a-f0-9]{1,4}:
			)
			# and the IPv4 address appended to all of the 12 bytes above
			(?:1\d\d|2[0-4]\d|25[0-5]|\d\d|\d)\.
			(?:1\d\d|2[0-4]\d|25[0-5]|\d\d|\d)\.
			(?:1\d\d|2[0-4]\d|25[0-5]|\d\d|\d)\.
			(?:1\d\d|2[0-4]\d|25[0-5]|\d\d|\d)   # no \b, we check later

			| # or (separately) a pure IPv6 address

			# all 8 (16 bytes) of them present
			(?:[a-f0-9]{1,4}:){7}[a-f0-9]{1,4}
			|
			# leading zeros omitted
			:(?::[a-f0-9]{1,4}){1,7}
			|
			# trailing zeros omitted
			(?:[a-f0-9]{1,4}:){1,7}:
			|
			# 0000 in second up to (including) seventh omitted
			[a-f0-9]{1,4}:(?::[a-f0-9]{1,4}){1,6}
			|
			# 0000 in third up to (including) seventh omitted
			(?:[a-f0-9]{1,4}:){2}(?::[a-f0-9]{1,4}){1,5}
			|
			# 0000 in fouth up to (including) seventh omiited
			(?:[a-f0-9]{1,4}:){3}(?::[a-f0-9]{1,4}){1,4}
			|
			# 0000 in fifth up to (including) seventh omitted
			(?:[a-f0-9]{1,4}:){4}(?::[a-f0-9]{1,4}){1,3}
			|
			# 0000 in sixth up to (including) seventh omitted
			(?:[a-f0-9]{1,4}:){5}(?::[a-f0-9]{1,4}){1,2}
			|
			# 0000 in seventh omitted
			(?:[a-f0-9]{1,4}:){6}:[a-f0-9]{1,4}
			|
			# :: (the unspecified addreess 0:0:0:0:0:0:0:0)
			# dos: I don't expect to see this address in a header, and
			# it may cause non-address strings to match, but we'll
			# include it for now since it is valid
			::
		      )
		      (?![a-f0-9:])
		    )
		  /oxi;

1;
