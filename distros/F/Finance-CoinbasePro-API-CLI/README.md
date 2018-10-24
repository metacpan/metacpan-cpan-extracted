* Finance-CoinbasePro-API-CLI

This module provides a command-line interface to operate with
Coinbase Pro.

Here's an example of Finance::CoinbasePro::API::CLI in action:

    % cat ~/.coinbasepro
    [coinbasepro]
    api_key = YOURKEYHERE
    api_secret = YOURSECRETHERE
    api_passphrase = YOURPASSPHRASEHERE

	% ./bin/coinbasepro.pl
	coinbasepro.pl (top|buy|sell|products|accounts|orders|ticker|trades|fills|cancel|cancelall)
	   [--verbose] [--dryrun] [--product=BTC-USD] [--price=N] [--size=N] [--cancel]:
	   shows data from GDAX/Coinbase Pro
		for example: coinbasepro.pl ticker --product=BTC-USD  or  coinbasepro.pl products
	coinbasepro.pl: allowed actions: (top|buy|sell|products|accounts|orders|ticker|trades|fills|cancel|cancelall)
	coinbasepro.pl: first param is action to perform

	% ./bin/coinbasepro.pl ticker
	coinbasepro.pl: ticker: BTC-USD: price: 6401.530000 (bid: 6440.57, ask 6440.58), volume 2443.32 
					(trade_id 11111111) 2018-10-20T18:36:18.288000Z

	% ./bin/coinbasepro.pl ticker --product ETH-USD
	coinbasepro.pl: ticker: ETH-USD: price: 203.230000 (bid: 204.23, ask 204.24), volume 38369.91 
					(trade_id 2222222) 2018-10-20T18:38:08.859000Z

	% ./bin/coinbasepro.pl accounts
	coinbasepro.pl: account: $556
	coinbasepro.pl: account: 0.0000ETC
	coinbasepro.pl: account: 0.1000BTC
	coinbasepro.pl: account: 0.0000LTC
	coinbasepro.pl: account: 0.0000ETH
	coinbasepro.pl: account: 0.0000BCH

	% ./bin/coinbasepro.pl products
	coinbasepro.pl: products: ETH-BTC ETH-USD LTC-BTC LTC-USD ETH-EUR LTC-EUR BCH-USD BCH-BTC BCH-EUR BTC-USD BTC-GBP BTC-EUR ETC-USD ETC-EUR ETC-BTC ZRX-EUR ZRX-USD ZRX-BTC

	% echo 'No' | ./bin/coinbasepro.pl sell -price 6401.66 -size 0.01
	coinbasepro.pl: sell: initiating limit sell of 0.01 BTC-USD at 6401.66
	Are you sure you want to sell 0.01 of BTC-USD at 6401.66? (Yes/No)
    coinbasepro.pl: Not selling

	% echo 'No' | ./bin/coinbasepro.pl buy -price 6401.66 -size 0.01
	coinbasepro.pl: buy: initiating limit buy of 0.01 BTC-USD at 6401.66
	Are you sure you want to buy 0.01 of BTC-USD at 6401.66? (Yes/No)
    coinbasepro.pl: Not selling


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

