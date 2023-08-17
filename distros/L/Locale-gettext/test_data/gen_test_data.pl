use strict;

sub gen {
	my ($domain) = @_;

	my $messages;
	my $language;
	unless (open(LOCALE, "locale|")) {
		doskip();
	}
	while (<LOCALE>) {
		if (/^LC_MESSAGES=\"(.*)\"$/) {
			$messages = $1;
		} elsif (/^LC_MESSAGES=(.*)$/) {
			$messages = $1;
		} elsif (/^LANGUAGE=\"(.*)\"$/) {
			$language = $1;
		} elsif (/^LANGUAGE=(.*)$/) {
			$language = $1;
		}
	}
	close LOCALE;
	if ($? != 0) {
		doskip();
	}

	if (!defined($messages)) {
		skip("cannot run test without a locale set", 0);
		exit 0;
	}
	if ($messages eq 'C') {
		skip("cannot run test in the C locale", 0);
		exit 0;
	}
	if ($messages eq 'POSIX') {
		skip("cannot run test in the POSIX locale", 0);
		exit 0;
	}
	if (defined($language) && $language) {
		# In GNU gettext, $LANGUAGE overrides
		# all the other environment variables,
		# for message translations only.
		# https://www.gnu.org/software/gettext/manual/html_node/The-LANGUAGE-variable.html#The-LANGUAGE-variable
		# The library will look first for the first entry in
		# that list, so give it what it wants.
		$messages = (split(':', $language))[0];
	}

	mkdir "test_data/" . $messages, 0755 unless (-d "test_data/" . $messages);
	mkdir "test_data/" . $messages . "/LC_MESSAGES", 0755
		unless (-d "test_data/" . $messages . "/LC_MESSAGES");
	unless (-r ("test_data/" . $messages . "/LC_MESSAGES/" . $domain . ".mo")) {
		system "msgfmt", "-o", "test_data/" . $messages . "/LC_MESSAGES/" .
			$domain . ".mo",
			"test_data/" . $domain . ".po";
		if ($? != 0) {
			doskip();
		}
	}
}

sub doskip {
	skip("could not generate test data, skipping test", 0);
	exit 0;
}

1;
