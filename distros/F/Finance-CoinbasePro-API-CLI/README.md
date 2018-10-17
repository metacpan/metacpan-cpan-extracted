* Finance-CoinbasePro-API-CLI

This module provides a command-line interface to operate with
Coinbase Pro.

Here's an example of Finance::CoinbasePro::API::CLI in action:

    % cat ~/.coinbasepro
    [coinbasepro]
    api_key = YOURKEYHERE
    api_secret = YOURSECRETHERE
    api_passphrase = YOURPASSPHRASEHERE

    % bin/coinbasepro.pl quotes
    coinbasepro.pl: quotes: {
      ask      => 6235,
      bid      => 6200.38,
      price    => "6235.00000000",
      size     => "2.00000000",
      time     => "2018-10-15T22:25:18.561000Z",
      trade_id => 2164766,
      volume   => 58.52494937,
    }

    (TODO- rewrite output above)



INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Finance::CoinbasePro::API::CLI


LICENSE AND COPYRIGHT

Copyright (C) 2018 Josh Rabinowitz

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

