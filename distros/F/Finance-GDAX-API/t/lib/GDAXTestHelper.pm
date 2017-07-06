package GDAXTestHelper;
use v5.20;
use warnings;
use Exporter qw(import);

our @EXPORT = qw(GDAX_environment_vars);

sub GDAX_environment_vars {
    return unless (($ENV{GDAX_EXTERNAL_SECRET} || $ENV{GDAX_EXTERNAL_SECRET_FORK}) ||
		   ($ENV{GDAX_API_KEY} && $ENV{GDAX_API_SECRET} && $ENV{GDAX_API_PASSPHRASE})
	);
    if ($ENV{GDAX_EXTERNAL_SECRET_FORK}) {
	warn "GDAX external_secret forking here - stdout will not be visible, if you have to enter in passphrases\n";
	return [$ENV{GDAX_EXTERNAL_SECRET_FORK}, 1];
    } elsif ($ENV{GDAX_EXTERNAL_SECRET}) {
	return [$ENV{GDAX_EXTERNAL_SECRET}, 0];
    }
    else {
	return 'RAW ENVARS';
    }
}

1;
