package Enum::Declare::Common::CurrencyISO;

use 5.014;
use strict;
use warnings;

use Enum::Declare;

# ── ISO 4217 Currency Codes (code → code for DB storage) ──

enum Code :Str :Type :Export {
	AED = "AED",
	AFN = "AFN",
	ALL = "ALL",
	AMD = "AMD",
	AOA = "AOA",
	ARS = "ARS",
	AUD = "AUD",
	AWG = "AWG",
	AZN = "AZN",
	BAM = "BAM",
	BBD = "BBD",
	BDT = "BDT",
	BHD = "BHD",
	BIF = "BIF",
	BMD = "BMD",
	BND = "BND",
	BOB = "BOB",
	BOV = "BOV",
	BRL = "BRL",
	BSD = "BSD",
	BTN = "BTN",
	BWP = "BWP",
	BYN = "BYN",
	BZD = "BZD",
	CAD = "CAD",
	CDF = "CDF",
	CHF = "CHF",
	CLF = "CLF",
	CLP = "CLP",
	CNY = "CNY",
	COP = "COP",
	COU = "COU",
	CRC = "CRC",
	CUP = "CUP",
	CVE = "CVE",
	CZK = "CZK",
	DJF = "DJF",
	DKK = "DKK",
	DOP = "DOP",
	DZD = "DZD",
	EGP = "EGP",
	ERN = "ERN",
	ETB = "ETB",
	EUR = "EUR",
	FJD = "FJD",
	FKP = "FKP",
	GBP = "GBP",
	GEL = "GEL",
	GHS = "GHS",
	GIP = "GIP",
	GMD = "GMD",
	GNF = "GNF",
	GTQ = "GTQ",
	GYD = "GYD",
	HKD = "HKD",
	HNL = "HNL",
	HTG = "HTG",
	HUF = "HUF",
	IDR = "IDR",
	ILS = "ILS",
	INR = "INR",
	IQD = "IQD",
	IRR = "IRR",
	ISK = "ISK",
	JMD = "JMD",
	JOD = "JOD",
	JPY = "JPY",
	KES = "KES",
	KGS = "KGS",
	KHR = "KHR",
	KMF = "KMF",
	KPW = "KPW",
	KRW = "KRW",
	KWD = "KWD",
	KYD = "KYD",
	KZT = "KZT",
	LAK = "LAK",
	LBP = "LBP",
	LKR = "LKR",
	LRD = "LRD",
	LSL = "LSL",
	LYD = "LYD",
	MAD = "MAD",
	MDL = "MDL",
	MGA = "MGA",
	MKD = "MKD",
	MMK = "MMK",
	MNT = "MNT",
	MOP = "MOP",
	MRU = "MRU",
	MUR = "MUR",
	MVR = "MVR",
	MWK = "MWK",
	MXN = "MXN",
	MXV = "MXV",
	MYR = "MYR",
	MZN = "MZN",
	NAD = "NAD",
	NGN = "NGN",
	NIO = "NIO",
	NOK = "NOK",
	NPR = "NPR",
	NZD = "NZD",
	OMR = "OMR",
	PAB = "PAB",
	PEN = "PEN",
	PGK = "PGK",
	PHP = "PHP",
	PKR = "PKR",
	PLN = "PLN",
	PYG = "PYG",
	QAR = "QAR",
	RON = "RON",
	RSD = "RSD",
	RUB = "RUB",
	RWF = "RWF",
	SAR = "SAR",
	SBD = "SBD",
	SCR = "SCR",
	SDG = "SDG",
	SEK = "SEK",
	SGD = "SGD",
	SHP = "SHP",
	SLE = "SLE",
	SOS = "SOS",
	SRD = "SRD",
	SSP = "SSP",
	STN = "STN",
	SVC = "SVC",
	SYP = "SYP",
	SZL = "SZL",
	THB = "THB",
	TJS = "TJS",
	TMT = "TMT",
	TND = "TND",
	TOP = "TOP",
	TRY = "TRY",
	TTD = "TTD",
	TWD = "TWD",
	TZS = "TZS",
	UAH = "UAH",
	UGX = "UGX",
	USD = "USD",
	USN = "USN",
	UYI = "UYI",
	UYU = "UYU",
	UYW = "UYW",
	UZS = "UZS",
	VED = "VED",
	VES = "VES",
	VND = "VND",
	VUV = "VUV",
	WST = "WST",
	XAD = "XAD",
	XAF = "XAF",
	XAG = "XAG",
	XAU = "XAU",
	XBA = "XBA",
	XBB = "XBB",
	XBC = "XBC",
	XBD = "XBD",
	XCD = "XCD",
	XCG = "XCG",
	XDR = "XDR",
	XOF = "XOF",
	XPD = "XPD",
	XPF = "XPF",
	XPT = "XPT",
	XSU = "XSU",
	XTS = "XTS",
	XUA = "XUA",
	XXX = "XXX",
	YER = "YER",
	ZAR = "ZAR",
	ZMW = "ZMW",
	ZWG = "ZWG"
};

1;

=head1 NAME

Enum::Declare::Common::CurrencyISO - ISO 4217 code-to-code constants

=head1 SYNOPSIS

    use Enum::Declare::Common::CurrencyISO;

    say USD;  # "USD"
    say EUR;  # "EUR"

    # Type-safe currency code for DB columns
    $row->{currency} = GBP;

=head1 ENUMS

=head2 Code :Str :Export

176 ISO 4217 constants. Each returns its own code as a string.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 LNATION. Artistic License 2.0.

=cut
