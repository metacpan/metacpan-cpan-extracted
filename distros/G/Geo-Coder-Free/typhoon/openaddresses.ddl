/*
 * Database schema for Typhoon database.
 * See https://github.com/jonahharris/osdb-typhoon
 */
database openaddresses {
	data	file	"openaddresses.dat"	contains	addresses;
	key	file	"all.key"	contains	addresses.all;

	record addresses {
		double	lat;
		double	lon;
		ulong	number;
		char	street[33];
		char	city[33];
		char	county[33];
		char	state[33];
		char	country[3];

		primary	key all {
			number, street, city, county, state, country
		};
	}
}
