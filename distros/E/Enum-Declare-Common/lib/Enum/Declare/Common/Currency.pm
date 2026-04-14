package Enum::Declare::Common::Currency;

use 5.014;
use strict;
use warnings;

use Enum::Declare;

# ── ISO 4217 Active Currency Codes ──

enum Code :Str :Type :Export {
	AED = "United Arab Emirates Dirham",
	AFN = "Afghan Afghani",
	ALL = "Albanian Lek",
	AMD = "Armenian Dram",
	AOA = "Angolan Kwanza",
	ARS = "Argentine Peso",
	AUD = "Australian Dollar",
	AWG = "Aruban Florin",
	AZN = "Azerbaijani Manat",
	BAM = "Bosnia and Herzegovina Convertible Mark",
	BBD = "Barbados Dollar",
	BDT = "Bangladeshi Taka",
	BHD = "Bahraini Dinar",
	BIF = "Burundian Franc",
	BMD = "Bermudian Dollar",
	BND = "Brunei Dollar",
	BOB = "Boliviano",
	BOV = "Bolivian Mvdol",
	BRL = "Brazilian Real",
	BSD = "Bahamian Dollar",
	BTN = "Bhutanese Ngultrum",
	BWP = "Botswana Pula",
	BYN = "Belarusian Ruble",
	BZD = "Belize Dollar",
	CAD = "Canadian Dollar",
	CDF = "Congolese Franc",
	CHF = "Swiss Franc",
	CLF = "Chilean Unidad de Fomento",
	CLP = "Chilean Peso",
	CNY = "Chinese Yuan Renminbi",
	COP = "Colombian Peso",
	COU = "Colombian Unidad de Valor Real",
	CRC = "Costa Rican Colon",
	CUP = "Cuban Peso",
	CVE = "Cape Verdean Escudo",
	CZK = "Czech Koruna",
	DJF = "Djiboutian Franc",
	DKK = "Danish Krone",
	DOP = "Dominican Peso",
	DZD = "Algerian Dinar",
	EGP = "Egyptian Pound",
	ERN = "Eritrean Nakfa",
	ETB = "Ethiopian Birr",
	EUR = "Euro",
	FJD = "Fijian Dollar",
	FKP = "Falkland Islands Pound",
	GBP = "Pound Sterling",
	GEL = "Georgian Lari",
	GHS = "Ghanaian Cedi",
	GIP = "Gibraltar Pound",
	GMD = "Gambian Dalasi",
	GNF = "Guinean Franc",
	GTQ = "Guatemalan Quetzal",
	GYD = "Guyanese Dollar",
	HKD = "Hong Kong Dollar",
	HNL = "Honduran Lempira",
	HTG = "Haitian Gourde",
	HUF = "Hungarian Forint",
	IDR = "Indonesian Rupiah",
	ILS = "Israeli New Shekel",
	INR = "Indian Rupee",
	IQD = "Iraqi Dinar",
	IRR = "Iranian Rial",
	ISK = "Icelandic Krona",
	JMD = "Jamaican Dollar",
	JOD = "Jordanian Dinar",
	JPY = "Japanese Yen",
	KES = "Kenyan Shilling",
	KGS = "Kyrgyzstani Som",
	KHR = "Cambodian Riel",
	KMF = "Comorian Franc",
	KPW = "North Korean Won",
	KRW = "South Korean Won",
	KWD = "Kuwaiti Dinar",
	KYD = "Cayman Islands Dollar",
	KZT = "Kazakhstani Tenge",
	LAK = "Lao Kip",
	LBP = "Lebanese Pound",
	LKR = "Sri Lankan Rupee",
	LRD = "Liberian Dollar",
	LSL = "Lesotho Loti",
	LYD = "Libyan Dinar",
	MAD = "Moroccan Dirham",
	MDL = "Moldovan Leu",
	MGA = "Malagasy Ariary",
	MKD = "Macedonian Denar",
	MMK = "Myanmar Kyat",
	MNT = "Mongolian Tugrik",
	MOP = "Macanese Pataca",
	MRU = "Mauritanian Ouguiya",
	MUR = "Mauritian Rupee",
	MVR = "Maldivian Rufiyaa",
	MWK = "Malawian Kwacha",
	MXN = "Mexican Peso",
	MXV = "Mexican Unidad de Inversion",
	MYR = "Malaysian Ringgit",
	MZN = "Mozambican Metical",
	NAD = "Namibian Dollar",
	NGN = "Nigerian Naira",
	NIO = "Nicaraguan Cordoba",
	NOK = "Norwegian Krone",
	NPR = "Nepalese Rupee",
	NZD = "New Zealand Dollar",
	OMR = "Omani Rial",
	PAB = "Panamanian Balboa",
	PEN = "Peruvian Sol",
	PGK = "Papua New Guinean Kina",
	PHP = "Philippine Peso",
	PKR = "Pakistani Rupee",
	PLN = "Polish Zloty",
	PYG = "Paraguayan Guarani",
	QAR = "Qatari Riyal",
	RON = "Romanian Leu",
	RSD = "Serbian Dinar",
	RUB = "Russian Ruble",
	RWF = "Rwandan Franc",
	SAR = "Saudi Riyal",
	SBD = "Solomon Islands Dollar",
	SCR = "Seychellois Rupee",
	SDG = "Sudanese Pound",
	SEK = "Swedish Krona",
	SGD = "Singapore Dollar",
	SHP = "Saint Helena Pound",
	SLE = "Sierra Leonean Leone",
	SOS = "Somali Shilling",
	SRD = "Surinamese Dollar",
	SSP = "South Sudanese Pound",
	STN = "Sao Tome and Principe Dobra",
	SVC = "Salvadoran Colon",
	SYP = "Syrian Pound",
	SZL = "Eswatini Lilangeni",
	THB = "Thai Baht",
	TJS = "Tajikistani Somoni",
	TMT = "Turkmenistani Manat",
	TND = "Tunisian Dinar",
	TOP = "Tongan Pa'anga",
	TRY = "Turkish Lira",
	TTD = "Trinidad and Tobago Dollar",
	TWD = "New Taiwan Dollar",
	TZS = "Tanzanian Shilling",
	UAH = "Ukrainian Hryvnia",
	UGX = "Ugandan Shilling",
	USD = "United States Dollar",
	USN = "United States Dollar (Next Day)",
	UYI = "Uruguayan Peso en Unidades Indexadas",
	UYU = "Uruguayan Peso",
	UYW = "Unidad Previsional",
	UZS = "Uzbekistani Som",
	VED = "Venezuelan Digital Bolivar",
	VES = "Venezuelan Sovereign Bolivar",
	VND = "Vietnamese Dong",
	VUV = "Vanuatu Vatu",
	WST = "Samoan Tala",
	XAD = "Arab Accounting Dinar",
	XAF = "Central African CFA Franc",
	XAG = "Silver (Troy Ounce)",
	XAU = "Gold (Troy Ounce)",
	XBA = "European Composite Unit",
	XBB = "European Monetary Unit",
	XBC = "European Unit of Account 9",
	XBD = "European Unit of Account 17",
	XCD = "East Caribbean Dollar",
	XCG = "Caribbean Guilder",
	XDR = "Special Drawing Rights (IMF)",
	XOF = "West African CFA Franc",
	XPD = "Palladium (Troy Ounce)",
	XPF = "CFP Franc",
	XPT = "Platinum (Troy Ounce)",
	XSU = "Sucre",
	XTS = "Code Reserved for Testing",
	XUA = "ADB Unit of Account",
	XXX = "No Currency",
	YER = "Yemeni Rial",
	ZAR = "South African Rand",
	ZMW = "Zambian Kwacha",
	ZWG = "Zimbabwe Gold"
};

1;

=head1 NAME

Enum::Declare::Common::Currency - ISO 4217 currency codes to names

=head1 SYNOPSIS

    use Enum::Declare::Common::Currency;

    say USD;  # "United States Dollar"
    say EUR;  # "Euro"

    my $meta = Code();
    say $meta->count;  # 176

=head1 ENUMS

=head2 Code :Str :Export

176 ISO 4217 currency codes. Values are full currency names.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 LNATION. Artistic License 2.0.

=cut
