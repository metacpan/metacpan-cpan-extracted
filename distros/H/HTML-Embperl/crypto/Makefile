
SSL_BASE=/usr/local/ssl

epcrypto: epcrypto.c epcrypto_config.h epcrypto.h
	gcc  -Wall   -I$(SSL_BASE)/include -L$(SSL_BASE)/lib  -o epcrypto epcrypto.c   -lcrypto
