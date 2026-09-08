# NOTE: deps/*.txt with 'make deps' is the authoritative dependency
# list. This file exists for development convenience and carton
# compatibility.
#
# Fugu itself needs core Perl only: t/fugu/coreperl.t proves that
# every module loads with a pruned @INC. Every entry below backs an
# optional feature or the test suite.

on 'test' => sub {
	requires 'Perl::Critic';
	requires 'Perl::Tidy';

	# Fugu::SSH drives libssh2 through this binding. The strict
	# mode needs check_hostkey with the 0.60 argument order.
	requires 'Net::SSH2', '0.60';

	# The Fugu::Proxy cache maps a URL to a path with URI
	requires 'URI';
};

# Optional features. Fugu::MQTT wraps Net::MQTT::Simple. Fugu::Proxy
# uses HTTP::Request and HTTP::Response, which the HTTP::Message
# distribution provides.
on 'develop' => sub {
	requires 'HTTP::Daemon';
	requires 'HTTP::Message';
	requires 'LWP::UserAgent';
	requires 'Net::MQTT::Simple';
};
