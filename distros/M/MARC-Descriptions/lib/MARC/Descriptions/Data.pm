package MARC::Descriptions::Data;

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(%MARC_tag_data);

our $VERSION = "0.6";

#-----------------------------------------------------------------------------------------
# Mods:
# 2004.01.16 - Added tags < 010
# 2003.12.09 - Renamed from MARC::tagdata to MARC::Descriptions::Data
# 2003.12.08 - Note that all text with '$' chars must have that char escaped.
# 2003.12.07 - Replaced all double-quote chars in text with single quote.
#            - Original version auto-built from CSV files.
#-----------------------------------------------------------------------------------------
%MARC_tag_data = (
        "001" => {
	        flags => "m",
                shortname => "Control",
                description => "Control Number",
	      },
        "003" => {
	        flags => "m",
                shortname => "",
                description => "Control Number Identifier",
	      },
        "005" => {
	        flags => "m",
                shortname => "",
                description => "Date and Time of Latest Transaction",
	      },
        "006" => {
	        flags => "R",
                shortname => "",
                description => "Fixed-length Data Elements - Additional Material Characteristics",
	      },
        "007" => {
	        flags => "R",
                shortname => "",
                description => "Physical Description Fixed Field",
	      },
        "008" => {
	        flags => "m",
                shortname => "",
                description => "Fixed-length Data Elements",
	      },
        "009" => {
	        flags => "",
                shortname => "",
                description => "OBSOLETE - Physical Description Fixed-Field for Archival Collection",
	      },
	"010" => {
		flags => "",
		shortname => "LCCN",
		description => "Library of Congress Control Number",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "LC control number",
				},
			"b" => {
				flags => "aR",
				description => "National Union Catalog of Manuscript Collections Control Number",
				},
			"z" => {
				flags => "R",
				description => "Canceled/invalid LC control number",
				},
			},
		},
	"015" => {
		flags => "",
		shortname => "",
		description => "National Bibliography Number",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "National bibliography number",
				},
			},
		},
	"016" => {
		flags => "",
		shortname => "NLCN",
		description => "National Library of Canada Bibliographic Record Control Number",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "NLC bibliographic record control number",
				},
			"z" => {
				flags => "R",
				description => "Canceled/invalid NLC bibliographic record control number",
				},
			},
		},
	"017" => {
		flags => "bvmcfR",
		shortname => "",
		description => "Copyright number",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "Copyright number",
				},
			"b" => {
				flags => "",
				description => "Source (agency assigning number)",
				},
			},
		},
	"018" => {
		flags => "sb",
		shortname => "",
		description => "Copyright Article-Fee Code",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Copyright article-fee code.",
				},
			},
		},
	"020" => {
		flags => "bavmcfR",
		shortname => "ISBN",
		description => "International Standard Book Number",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "ISBN",
				},
			"b" => {
				flags => "",
				description => "Binding (OBSOLETE)",
				},
			"c" => {
				flags => "",
				description => "Terms of availablility",
				},
			"z" => {
				flags => "R",
				description => "Canceled/invalid ISBN",
				},
			},
		},
	"022" => {
		flags => "sfR",
		shortname => "ISSN",
		description => "International Standard Serial Number",
		ind1 => {
			"#" => {
				flags => "",
				description => "Information not available",
				},
			"0" => {
				flags => "",
				description => "Full record registered with ISDS/IC",
				},
			"1" => {
				flags => "",
				description => "Abbreviated record registered with ISDS/IC",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "ISSN",
				},
			"b" => {
				flags => "",
				description => "Form of issue",
				},
			"c" => {
				flags => "",
				description => "Price",
				},
			"y" => {
				flags => "R",
				description => "Canceled ISSN",
				},
			"z" => {
				flags => "R",
				description => "Incorrect ISSN",
				},
			},
		},
	"023" => {
		flags => "v",
		shortname => "",
		description => "Standard Film Number",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Standard film number",
				},
			},
		},
	"024" => {
		flags => "mR",
		shortname => "",
		description => "Standard Recording Number",
		ind1 => {
			"0" => {
				flags => "",
				description => "International Standard Recording Code",
				},
			"1" => {
				flags => "",
				description => "U.S. Universal Product Code for sound recording",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Standard recording code",
				},
			"b" => {
				flags => "",
				description => "Additional digits following the standard number",
				},
			"d" => {
				flags => "",
				description => "Additional codes folling the standard code",
				},
			"z" => {
				flags => "R",
				description => "Canceled/invalid standard number",
				},
			},
		},
	"025" => {
		flags => "",
		shortname => "",
		description => "Overseas Acquisitions Number",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "Overseas acquisitions number",
				},
			},
		},
	"027" => {
		flags => "sbc",
		shortname => "STRN",
		description => "Standard Technical Report Number",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Standard Technical Report Number (STRN)",
				},
			"z" => {
				flags => "R",
				description => "Canceled/invalid STRN",
				},
			},
		},
	"028" => {
		flags => "mR",
		shortname => "",
		description => "Publisher's Number (Music)",
		ind1 => {
			"0" => {
				flags => "",
				description => "Issue number",
				},
			"1" => {
				flags => "",
				description => "Matrix number",
				},
			"2" => {
				flags => "",
				description => "Plate number",
				},
			"3" => {
				flags => "",
				description => "Other publisher's number",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "Print a note",
				},
			"1" => {
				flags => "",
				description => "Do not print a note",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Number",
				},
			"b" => {
				flags => "",
				description => "Source",
				},
			},
		},
	"030" => {
		flags => "sR",
		shortname => "",
		description => "CODE Designation",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "CODE",
				},
			"z" => {
				flags => "R",
				description => "Canceled/invalid CODE",
				},
			},
		},
	"032" => {
		flags => "sR",
		shortname => "",
		description => "Postal Registration Number",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Postal registration number",
				},
			"b" => {
				flags => "",
				description => "Source (agency assigning number)",
				},
			},
		},
	"033" => {
		flags => "bavmR",
		shortname => "",
		description => "Date/Time and Place of an Event",
		ind1 => {
			"#" => {
				flags => "",
				description => "No date recorded",
				},
			"0" => {
				flags => "",
				description => "Single date",
				},
			"1" => {
				flags => "",
				description => "Multiple single dates",
				},
			"2" => {
				flags => "",
				description => "Range of dates",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Information not provided",
				},
			"0" => {
				flags => "",
				description => "Capture",
				},
			"1" => {
				flags => "",
				description => "Broadcast",
				},
			"2" => {
				flags => "",
				description => "Finding",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "Formatted date/time",
				},
			"b" => {
				flags => "R",
				description => "Geographic classification area code",
				},
			"c" => {
				flags => "R",
				description => "Geographic classification sub-area code",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"034" => {
		flags => "sbcR",
		shortname => "",
		description => "Scale and Coordinates",
		ind1 => {
			"0" => {
				flags => "",
				description => "Scale indeterminable/no scale recorded",
				},
			"1" => {
				flags => "",
				description => "Single scale",
				},
			"2" => {
				flags => "",
				description => "Multiple scales (OBSOLETE)",
				},
			"3" => {
				flags => "",
				description => "Range of scales",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Type of scale",
				},
			"b" => {
				flags => "R",
				description => "Constant ratio linear horizontal scale",
				},
			"c" => {
				flags => "R",
				description => "Constant ration linear vertical scale",
				},
			"d" => {
				flags => "",
				description => "Coordinates - westernmost longitude",
				},
			"e" => {
				flags => "",
				description => "Coordinates - easternmost longitude",
				},
			"f" => {
				flags => "",
				description => "Coordinates - northernmost latitude",
				},
			"g" => {
				flags => "",
				description => "Coordinates - southernmost latitude",
				},
			"h" => {
				flags => "R",
				description => "Angular scale",
				},
			"j" => {
				flags => "",
				description => "Declination - northern limit",
				},
			"k" => {
				flags => "",
				description => "Declination - southern limit",
				},
			"m" => {
				flags => "",
				description => "Right ascension - eastern limits",
				},
			"n" => {
				flags => "",
				description => "Right ascension - western limits",
				},
			"p" => {
				flags => "",
				description => "Equinox",
				},
			},
		},
	"035" => {
		flags => "R",
		shortname => "",
		description => "System Control Number",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "System control number",
				},
			"z" => {
				flags => "R",
				description => "Canceled/invalid system control number",
				},
			},
		},
	"036" => {
		flags => "f",
		shortname => "",
		description => "Original Study Number for Computer Data Files",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Original study number",
				},
			"b" => {
				flags => "",
				description => "Source (agency assigning number)",
				},
			},
		},
	"037" => {
		flags => "sbvmcfR",
		shortname => "",
		description => "Source of Acquisition",
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Stock number",
				},
			"b" => {
				flags => "",
				description => "Source",
				},
			"c" => {
				flags => "bvfR",
				description => "Terms of availability",
				},
			"f" => {
				flags => "bvfR",
				description => "Form of issue",
				},
			},
		},
	"039" => {
		flags => "sbvmc",
		shortname => "",
		description => "Level of Bibliographic Control and Coding Detail (OBSOLETE)",
		ind1 => {
			"0" => {
				flags => "",
				description => "National level bibliographic record - U.S.",
				},
			"8" => {
				flags => "",
				description => "Other",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Bibliographic description - level of rules used",
				},
			"b" => {
				flags => "",
				description => "Access points excluding subject access - level of effort used to assign access",
				},
			"c" => {
				flags => "",
				description => "Subject headings - level of effort used to assign",
				},
			"d" => {
				flags => "",
				description => "Classification - level of effort used to assign",
				},
			"e" => {
				flags => "",
				description => "Fixed fields - number of positions coded",
				},
			},
		},
	"040" => {
		flags => "",
		shortname => "",
		description => "Cataloguing Source",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Original cataloguing agency",
				},
			"b" => {
				flags => "",
				description => "Code for language of cataloguing",
				},
			"c" => {
				flags => "",
				description => "Transcribing agency",
				},
			"d" => {
				flags => "R",
				description => "Modifying agency",
				},
			"e" => {
				flags => "",
				description => "Description convention",
				},
			},
		},
	"041" => {
		flags => "",
		shortname => "",
		description => "Language Code",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "Language code of text/soundtrack or separate title",
				},
			"b" => {
				flags => "sbmR",
				description => "Language code of summaries or abstracts",
				},
			"d" => {
				flags => "mR",
				description => "Language code of sung or spoken text",
				},
			"e" => {
				flags => "mR",
				description => "Language code of librettos",
				},
			"f" => {
				flags => "R",
				description => "Lanuage code of table of contents that differs from the language of the text",
				},
			"g" => {
				flags => "vmR",
				description => "The language of significant accompanying material other than summaries (subfield \$b) or librettos (subfield \$e)",
				},
			"h" => {
				flags => "R",
				description => "Language code of original and/or intermediate translations of text",
				},
			},
		},
	"042" => {
		flags => "sbvmcf",
		shortname => "",
		description => "Authentication Center",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "Authentication code",
				},
			},
		},
	"043" => {
		flags => "",
		shortname => "",
		description => "Geographic Area Code",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "Geographic area code",
				},
			},
		},
	"044" => {
		flags => "vmc",
		shortname => "",
		description => "Country of Producer Code",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "Country of producer code",
				},
			},
		},
	"045" => {
		flags => "",
		shortname => "",
		description => "Time Period of Content",
		ind1 => {
			"#" => {
				flags => "",
				description => "No dates/times recorded (i.e. no subfield \$b or \$c)",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "Time period code",
				},
			"b" => {
				flags => "R",
				description => "Formatted 9999 B.C. through C.E. time period",
				},
			"c" => {
				flags => "R",
				description => "Formatted pre-9999 B.C. time period",
				},
			},
		},
	"046" => {
		flags => "bavmc",
		shortname => "",
		description => "Type of Date Code (B.C. Dates)",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Type of date code",
				},
			"b" => {
				flags => "",
				description => "Date 1 (B.C. date)",
				},
			"c" => {
				flags => "",
				description => "Date 1 (C.E. date)",
				},
			"d" => {
				flags => "",
				description => "Date 2 (B.C. date)",
				},
			"e" => {
				flags => "",
				description => "Date 2 (C.E. date)",
				},
			},
		},
	"047" => {
		flags => "m",
		shortname => "",
		description => "Form or Type of Music",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "Form of musicical composition",
				},
			},
		},
	"048" => {
		flags => "mR",
		shortname => "",
		description => "Number of Instruments or Voices",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "Performer or ensemble",
				},
			"b" => {
				flags => "R",
				description => "Soloist",
				},
			},
		},
	"050" => {
		flags => "R",
		shortname => "LCCN",
		description => "Library of Congress Call Number",
		ind1 => {
			"#" => {
				flags => "",
				description => "Information not provided",
				},
			"0" => {
				flags => "",
				description => "In LC",
				},
			"1" => {
				flags => "",
				description => "Not in LC",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Information not provided",
				},
			"0" => {
				flags => "",
				description => "Assinged by LC",
				},
			"4" => {
				flags => "",
				description => "Assigned by agency other than LC",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "LC classification number",
				},
			"b" => {
				flags => "",
				description => "Item number",
				},
			"d" => {
				flags => "mR",
				description => "Supplementary class number (OBSOLETE)",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"051" => {
		flags => "sbvmfR",
		shortname => "",
		description => "Library of Congress Copy Issue Offprint Statement",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "LC classification number",
				},
			"b" => {
				flags => "",
				description => "Item number",
				},
			"c" => {
				flags => "",
				description => "Copy information",
				},
			},
		},
	"052" => {
		flags => "R",
		shortname => "",
		description => "Geographic Classification Code",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Geographic classification area code",
				},
			"b" => {
				flags => "R",
				description => "Geographic classification sub-area code",
				},
			"d" => {
				flags => "R",
				description => "Populated place name",
				},
			"2" => {
				flags => "",
				description => "Code source",
				},
			},
		},
	"055" => {
		flags => "R",
		shortname => "",
		description => "Call Numbers/Class Numbers Assigned in Canada",
		ind1 => {
			"#" => {
				flags => "",
				description => "Information not provided",
				},
			"0" => {
				flags => "",
				description => "Work held by NLC",
				},
			"1" => {
				flags => "",
				description => "Work not held by NLC",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "LC-based call numbers assigned by NLC",
				},
			"1" => {
				flags => "",
				description => "Complete LC class number assigned by NLC",
				},
			"2" => {
				flags => "",
				description => "Incomplete LC class number assigned by NLC",
				},
			"3" => {
				flags => "",
				description => "LC-based call number assigned by the contributing library",
				},
			"4" => {
				flags => "",
				description => "Complete LC class number assigned by the contributing library",
				},
			"5" => {
				flags => "",
				description => "Incomplete LC class number assigned by the contrinbuting library",
				},
			"6" => {
				flags => "",
				description => "Other call number asigned by NLC",
				},
			"7" => {
				flags => "",
				description => "Other class number assigned by NLC",
				},
			"8" => {
				flags => "",
				description => "Other call number assigned by the contributing library",
				},
			"9" => {
				flags => "",
				description => "Other class number assigned by the contributing library",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Classification number",
				},
			"b" => {
				flags => "",
				description => "Item number",
				},
			"2" => {
				flags => "",
				description => "Source of call/class number",
				},
			},
		},
	"056" => {
		flags => "R",
		shortname => "",
		description => "National Library Copy Issue Offprint Statement",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "LC classification number",
				},
			"b" => {
				flags => "",
				description => "Item number",
				},
			"c" => {
				flags => "",
				description => "Copy informatoin",
				},
			},
		},
	"060" => {
		flags => "R",
		shortname => "",
		description => "National Library of Medicine Call Number",
		ind1 => {
			"#" => {
				flags => "",
				description => "Information not provided",
				},
			"0" => {
				flags => "",
				description => "Work held by NLM",
				},
			"1" => {
				flags => "",
				description => "Work not held by NLM",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Information not provided",
				},
			"0" => {
				flags => "",
				description => "Assigned by NLM",
				},
			"4" => {
				flags => "",
				description => "Assigned by agency other than NLM",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "NLM classification number",
				},
			"b" => {
				flags => "",
				description => "Item number",
				},
			},
		},
	"061" => {
		flags => "sR",
		shortname => "",
		description => "National Library of Medicine Copy Statement",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "NLM classification number",
				},
			"b" => {
				flags => "",
				description => "Item number",
				},
			"c" => {
				flags => "",
				description => "Copy information",
				},
			},
		},
	"070" => {
		flags => "R",
		shortname => "",
		description => "National Agricultural Library Call Number",
		ind1 => {
			"0" => {
				flags => "",
				description => "Work held by NAL",
				},
			"1" => {
				flags => "",
				description => "Work not held by NAL",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		},
	"071" => {
		flags => "sbR",
		shortname => "",
		description => "National Agricultural Library Copy Statement",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "NAL classification number",
				},
			"b" => {
				flags => "",
				description => "Item number",
				},
			"c" => {
				flags => "",
				description => "Copy information",
				},
			},
		},
	"072" => {
		flags => "R",
		shortname => "",
		description => "Subject Category Code",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "National Agricultural Library subject category",
				},
			"7" => {
				flags => "",
				description => "Code source is pecified in subfield \$2",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Subject category code",
				},
			"x" => {
				flags => "R",
				description => "Subject category code subdivision",
				},
			"2" => {
				flags => "Code source",
				description => "",
				},
			},
		},
	"074" => {
		flags => "sbvmcf",
		shortname => "GPO",
		description => "United States Government Printing Office Item Number",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "GPO item number",
				},
			},
		},
	"080" => {
		flags => "",
		shortname => "",
		description => "Universal Decimal Classification Number",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "Universal decimal classification number",
				},
			},
		},
	"082" => {
		flags => "R",
		shortname => "Dewey",
		description => "Dewey Decimal Call Number/Classification Number",
		ind1 => {
			"#" => {
				flags => "",
				description => "No edition information recorded (OBSOLETE)",
				},
			"0" => {
				flags => "",
				description => "Full edition",
				},
			"1" => {
				flags => "",
				description => "Abridged edition",
				},
			"2" => {
				flags => "",
				description => "Abridged NST version (OBSOLETE)",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "Dewey number",
				},
			"b" => {
				flags => "",
				description => "Item number",
				},
			"2" => {
				flags => "",
				description => "Edition number",
				},
			},
		},
	"086" => {
		flags => "sbvmcfR",
		shortname => "",
		description => "Government Document Classification Number",
		ind1 => {
			"#" => {
				flags => "",
				description => "Source specified in subfield \$2",
				},
			"0" => {
				flags => "",
				description => "U.S. Superintendent of Documents Classification System",
				},
			"1" => {
				flags => "",
				description => "Government of Canada Publications: Outline of Classification",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Only if first indicator is NOT '1'",
				},
			"0" => {
				flags => "",
				description => "IC cat. no.",
				},
			"1" => {
				flags => "",
				description => "Cat. IC",
				},
			"2" => {
				flags => "",
				description => "QP cat. no.",
				},
			"3" => {
				flags => "",
				description => "Cat. IR",
				},
			"4" => {
				flags => "",
				description => "DSS cat. no.",
				},
			"5" => {
				flags => "",
				description => "Cat. MAS",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Government document classification number",
				},
			"z" => {
				flags => "R",
				description => "Canceled/invalid government document classification number",
				},
			"2" => {
				flags => "",
				description => "Number source",
				},
			},
		},
	"087" => {
		flags => "sbcR",
		shortname => "",
		description => "Report Number",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Report number",
				},
			},
		},
	"088" => {
		flags => "",
		shortname => "CODOC",
		description => "Document Shelving Number",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Document shelving number (CODOC)",
				},
			},
		},
	"090" => {
		flags => "",
		shortname => "LCN",
		description => "Local Call Number",
		},
	"100" => {
		flags => "",
		shortname => "Author",
		description => "Main Entry Heading - Personal Name",
		ind1 => {
			"0" => {
				flags => "",
				description => "Forenames",
				},
			"1" => {
				flags => "",
				description => "Single surname",
				},
			"2" => {
				flags => "",
				description => "Multiple surname",
				},
			"3" => {
				flags => "",
				description => "Name of family",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Information not provided",
				},
			"0" => {
				flags => "sbm",
				description => "Main entry/subject relationship irrelevant (OBSOLETE)",
				},
			"1" => {
				flags => "sbm",
				description => "Main entry is subject of the work (OBSOLETE)",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Personal name",
				},
			"b" => {
				flags => "",
				description => "Numeration (Roman numerals which may follow a forename)",
				},
			"c" => {
				flags => "R",
				description => "Title and other words associated with a name",
				},
			"d" => {
				flags => "",
				description => "Dates associated with a name",
				},
			"e" => {
				flags => "R",
				description => "Relator term (Describes the relationship between a name and a work)",
				},
			"f" => {
				flags => "",
				description => "Date of a work",
				},
			"g" => {
				flags => "",
				description => "Miscellaneous information",
				},
			"j" => {
				flags => "R",
				description => "Attribution qualifier",
				},
			"k" => {
				flags => "R",
				description => "Form subheading",
				},
			"l" => {
				flags => "",
				description => "Language of a work",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section of a work",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section of a work",
				},
			"q" => {
				flags => "",
				description => "Fuller form of name",
				},
			"t" => {
				flags => "",
				description => "Title of a work",
				},
			"u" => {
				flags => "",
				description => "Affiliation",
				},
			"4" => {
				flags => "R",
				description => "Relator code",
				},
			},
		},
	"110" => {
		flags => "",
		shortname => "Author (Corporate)",
		description => "Main Entry Heading - Corporate Name",
		ind1 => {
			"0" => {
				flags => "",
				description => "Surname (inverted)",
				},
			"1" => {
				flags => "",
				description => "Place or place and name",
				},
			"2" => {
				flags => "",
				description => "Name (direct order)",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			"0" => {
				flags => "sbm",
				description => "Main entry/subject relationship irrelevant (OBSOLETE)",
				},
			"1" => {
				flags => "sbm",
				description => "Main entry is subject of the work (OBSOLETE)",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Corporate name or jurisdiction name as entry element",
				},
			"b" => {
				flags => "R",
				description => "Subordinate unit",
				},
			"c" => {
				flags => "",
				description => "Location of meeting",
				},
			"d" => {
				flags => "R",
				description => "Date of meting or treaty signing",
				},
			"e" => {
				flags => "R",
				description => "Relator term (Describes the relationship between a name and a work)",
				},
			"f" => {
				flags => "",
				description => "Date",
				},
			"g" => {
				flags => "",
				description => "Miscellaneous information",
				},
			"k" => {
				flags => "R",
				description => "Form subheading",
				},
			"l" => {
				flags => "",
				description => "Language",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section/meeting",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"t" => {
				flags => "",
				description => "Title of a work",
				},
			"u" => {
				flags => "",
				description => "Affiliation",
				},
			"4" => {
				flags => "R",
				description => "Relator code",
				},
			},
		},
	"111" => {
		flags => "",
		shortname => "Author (Conference)",
		description => "Main Entry Heading - Meeting or Conference",
		ind1 => {
			"0" => {
				flags => "",
				description => "Surname (inverted)",
				},
			"1" => {
				flags => "",
				description => "Place or place and name",
				},
			"2" => {
				flags => "",
				description => "Name (direct order)",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			"0" => {
				flags => "sbm",
				description => "Main entry/subject relationship irrelevant (OBSOLETE)",
				},
			"1" => {
				flags => "sbm",
				description => "Main entry is subject of the work (OBSOLETE)",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Meeting name or jurisdiction name as entry element",
				},
			"c" => {
				flags => "",
				description => "Location of meeting",
				},
			"d" => {
				flags => "",
				description => "Date of meeting",
				},
			"e" => {
				flags => "R",
				description => "Subordinate unit",
				},
			"f" => {
				flags => "",
				description => "Date of a work",
				},
			"g" => {
				flags => "",
				description => "Miscellaneous information",
				},
			"k" => {
				flags => "R",
				description => "Form subheading",
				},
			"l" => {
				flags => "",
				description => "Language",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section/meeting",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"q" => {
				flags => "",
				description => "Name of meeting following jurisdiction name entry element",
				},
			"t" => {
				flags => "",
				description => "Title",
				},
			"u" => {
				flags => "",
				description => "Affiliation",
				},
			"4" => {
				flags => "R",
				description => "Relator code",
				},
			},
		},
	"130" => {
		flags => "",
		shortname => "",
		description => "Main Entry Heading - Uniform Title",
		ind1 => {
			"0" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"1" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"2" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"3" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"4" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"5" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"6" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"7" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"8" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"9" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			"0" => {
				flags => "sbm",
				description => "Main entry/subject relationship irrelevant (OBSOLETE)",
				},
			"1" => {
				flags => "sbm",
				description => "Main entry is subject of the work (OBSOLETE)",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Uniform title",
				},
			"d" => {
				flags => "R",
				description => "Date of treaty signing",
				},
			"f" => {
				flags => "",
				description => "Date of work",
				},
			"g" => {
				flags => "",
				description => "Miscellaneous information",
				},
			"h" => {
				flags => "",
				description => "Medium",
				},
			"k" => {
				flags => "R",
				description => "Form subheading",
				},
			"l" => {
				flags => "",
				description => "Language",
				},
			"m" => {
				flags => "R",
				description => "Medium of performance for music",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section",
				},
			"o" => {
				flags => "",
				description => "Arranged statement for music",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"r" => {
				flags => "",
				description => "Key for music",
				},
			"s" => {
				flags => "",
				description => "Version",
				},
			"t" => {
				flags => "",
				description => "Title",
				},
			},
		},
	"210" => {
		flags => "s",
		shortname => "",
		description => "Abbreviated Title",
		ind1 => {
			"0" => {
				flags => "",
				description => "No title added entry",
				},
			"1" => {
				flags => "",
				description => "Title added entry",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Abbreviated title",
				},
			"b" => {
				flags => "",
				description => "Qualifying information",
				},
			"2" => {
				flags => "R",
				description => "Source",
				},
			},
		},
	"211" => {
		flags => "fR",
		shortname => "",
		description => "Acronym or Shortened Title",
		ind1 => {
			"0" => {
				flags => "",
				description => "No title added entry",
				},
			"1" => {
				flags => "",
				description => "Title added entry",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"1" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"2" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"3" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"4" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"5" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"6" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"7" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"8" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"9" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Acronym or shortened title",
				},
			},
		},
	"212" => {
		flags => "sR",
		shortname => "",
		description => "Variant Access Title",
		ind1 => {
			"0" => {
				flags => "",
				description => "No title added entry",
				},
			"1" => {
				flags => "",
				description => "Title added entry",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Variant access title",
				},
			},
		},
	"214" => {
		flags => "bfR",
		shortname => "",
		description => "Augmented Title",
		ind1 => {
			"0" => {
				flags => "",
				description => "No title added entry",
				},
			"1" => {
				flags => "",
				description => "Title added entry",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"1" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"2" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"3" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"4" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"5" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"6" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"7" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"8" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"9" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Augmented title",
				},
			},
		},
	"222" => {
		flags => "sfR",
		shortname => "",
		description => "Key Title",
		ind1 => {
			"#" => {
				flags => "",
				description => "Information not provided",
				},
			"0" => {
				flags => "",
				description => "Field 245 NOT REQUIRED for ISDS variant title and field 222 NOT REQUIRED for added entry (OBSOLETE)",
				},
			"1" => {
				flags => "",
				description => "Field 245 REQUIRED for ISDS variant title and field 222 REQUIRED for added entry (OBSOLETE)",
				},
			"2" => {
				flags => "",
				description => "Field 245 NOTE REQUIRED for ISDS variant title and field 222 REQUIRED for added entry (OBSOLETE)",
				},
			"3" => {
				flags => "",
				description => "Field 245 REQUIRED for ISDS variant title and field 222 NOT REQUIRED for added entry (OBSOLETE)",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"1" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"2" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"3" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"4" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"5" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"6" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"7" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"8" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"9" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Key title",
				},
			"b" => {
				flags => "",
				description => "Qualifying information",
				},
			},
		},
	"240" => {
		flags => "",
		shortname => "",
		description => "Uniform Title",
		ind1 => {
			"0" => {
				flags => "",
				description => "Local usage only; NO title added entry",
				},
			"1" => {
				flags => "",
				description => "Conventional uniform title; NO title added entry",
				},
			"2" => {
				flags => "",
				description => "Local usage only; title added entry",
				},
			"3" => {
				flags => "",
				description => "Conventional uniform title; title added entry",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"1" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"2" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"3" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"4" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"5" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"6" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"7" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"8" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"9" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Uniform title",
				},
			"d" => {
				flags => "R",
				description => "Date of treaty signing",
				},
			"f" => {
				flags => "",
				description => "Date of work",
				},
			"g" => {
				flags => "",
				description => "Miscellaneous information",
				},
			"h" => {
				flags => "",
				description => "Medium",
				},
			"k" => {
				flags => "R",
				description => "Form subheading",
				},
			"l" => {
				flags => "",
				description => "Language",
				},
			"m" => {
				flags => "R",
				description => "Medium of performance for music",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section",
				},
			"o" => {
				flags => "",
				description => "Arranged statement for music",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"r" => {
				flags => "",
				description => "Key for music",
				},
			"s" => {
				flags => "",
				description => "Version",
				},
			},
		},
	"241" => {
		flags => "bavmcf",
		shortname => "",
		description => "Romanized Title",
		ind1 => {
			"0" => {
				flags => "",
				description => "No title added entry",
				},
			"1" => {
				flags => "",
				description => "Title added entry",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"1" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"2" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"3" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"4" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"5" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"6" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"7" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"8" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"9" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Romanized title",
				},
			},
		},
	"242" => {
		flags => "R",
		shortname => "",
		description => "Translation of Title by Cataloguing Agency",
		ind2 => {
			"0" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"1" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"2" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"3" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"4" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"5" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"6" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"7" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"8" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"9" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Title",
				},
			"b" => {
				flags => "",
				description => "Remainder of title",
				},
			"c" => {
				flags => "",
				description => "Statement of responsibility",
				},
			"h" => {
				flags => "",
				description => "Medium",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"y" => {
				flags => "",
				description => "Language code of translated title",
				},
			},
		},
	"243" => {
		flags => "bavm",
		shortname => "",
		description => "Collective Title",
		ind1 => {
			"0" => {
				flags => "",
				description => "Works",
				},
			"1" => {
				flags => "",
				description => "Selected works (complete works published together)",
				},
			"2" => {
				flags => "",
				description => "Selections (extracts)",
				},
			"3" => {
				flags => "",
				description => "Other collective titles",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"1" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"2" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"3" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"4" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"5" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"6" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"7" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"8" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"9" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Uniform title",
				},
			"d" => {
				flags => "R",
				description => "Date of treaty signing",
				},
			"f" => {
				flags => "",
				description => "Date of work",
				},
			"g" => {
				flags => "",
				description => "Miscellaneous information",
				},
			"h" => {
				flags => "",
				description => "Medium",
				},
			"k" => {
				flags => "R",
				description => "Form subheading",
				},
			"l" => {
				flags => "",
				description => "Language",
				},
			"m" => {
				flags => "",
				description => "Medium of performance for music",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section",
				},
			"o" => {
				flags => "",
				description => "Arranged statement for music",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"r" => {
				flags => "",
				description => "Key for music",
				},
			"s" => {
				flags => "",
				description => "Version",
				},
			},
		},
	"245" => {
		flags => "",
		shortname => "",
		description => "Title Statement",
		ind1 => {
			"0" => {
				flags => "",
				description => "No title added entry",
				},
			"1" => {
				flags => "",
				description => "Title added entry",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"1" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"2" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"3" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"4" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"5" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"6" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"7" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"8" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"9" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Title",
				},
			"b" => {
				flags => "",
				description => "Remainder of title",
				},
			"c" => {
				flags => "",
				description => "Statement of responsibility",
				},
			"f" => {
				flags => "",
				description => "Inclusive dates",
				},
			"g" => {
				flags => "",
				description => "Bulk dates",
				},
			"h" => {
				flags => "",
				description => "Medium",
				},
			"k" => {
				flags => "R",
				description => "Form",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"s" => {
				flags => "",
				description => "Version",
				},
			},
		},
	"246" => {
		flags => "sfR",
		shortname => "",
		description => "Varying forms of Title",
		ind1 => {
			"0" => {
				flags => "",
				description => "No title added entry",
				},
			"1" => {
				flags => "",
				description => "Title added entry",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "Access for portions of title",
				},
			"1" => {
				flags => "",
				description => "Parallel title",
				},
			"2" => {
				flags => "",
				description => "Distinctive title",
				},
			"3" => {
				flags => "",
				description => "Other title",
				},
			"4" => {
				flags => "",
				description => "Cover title",
				},
			"5" => {
				flags => "",
				description => "Added title page title",
				},
			"6" => {
				flags => "",
				description => "Caption title",
				},
			"7" => {
				flags => "",
				description => "Running title",
				},
			"8" => {
				flags => "",
				description => "Spine title",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Title proper/short title",
				},
			"b" => {
				flags => "",
				description => "Remainder of title",
				},
			"f" => {
				flags => "",
				description => "Date or sequential designation",
				},
			"g" => {
				flags => "",
				description => "Miscellaneous information",
				},
			"i" => {
				flags => "",
				description => "Display text",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"5" => {
				flags => "",
				description => "Institution to which field applies",
				},
			},
		},
	"247" => {
		flags => "sR",
		shortname => "",
		description => "Former Title or Title Variations",
		ind1 => {
			"0" => {
				flags => "",
				description => "No title added entry",
				},
			"1" => {
				flags => "",
				description => "Title added entry",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "Generate a note",
				},
			"1" => {
				flags => "",
				description => "Do not generate a note",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Title proper/short title",
				},
			"b" => {
				flags => "",
				description => "Remainder of title",
				},
			"f" => {
				flags => "",
				description => "Date or sequential designation",
				},
			"g" => {
				flags => "",
				description => "Miscellaneous information",
				},
			"h" => {
				flags => "",
				description => "Medium",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"x" => {
				flags => "",
				description => "International Standard Serial Number",
				},
			},
		},
	"250" => {
		flags => "",
		shortname => "",
		description => "Edition Statement",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Edition statement",
				},
			"b" => {
				flags => "",
				description => "Remainder of edition statement",
				},
			},
		},
	"254" => {
		flags => "m",
		shortname => "",
		description => "Musical Presentation Statement",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Musical presentation statement",
				},
			},
		},
	"255" => {
		flags => "bcR",
		shortname => "",
		description => "Mathematical Data Area",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Statement of scale",
				},
			"b" => {
				flags => "",
				description => "Statement of projection",
				},
			"c" => {
				flags => "",
				description => "Statement of coordinates",
				},
			"d" => {
				flags => "",
				description => "Statement of zone (celestial charts)",
				},
			"e" => {
				flags => "",
				description => "Statement of equinox",
				},
			"f" => {
				flags => "",
				description => "Outer G-ring coordinate pairs",
				},
			"g" => {
				flags => "",
				description => "Exclusion G-ring coordinate pairs",
				},
			},
		},
	"256" => {
		flags => "f",
		shortname => "",
		description => "Computer File Characteristics",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Computer file characteristics",
				},
			},
		},
	"257" => {
		flags => "v",
		shortname => "",
		description => "Country of Producing Entity",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Country of producing entity",
				},
			},
		},
	"260" => {
		flags => "",
		shortname => "Imprint",
		description => "Publication Distribution etc",
		ind1 => {
			"#" => {
				flags => "",
				description => "Information not provided",
				},
			"0" => {
				flags => "sbmc",
				description => "Publisher distributor etc statement is present (OBSOLETE)",
				},
			"1" => {
				flags => "sbmc",
				description => "Publisher distributor etc statement is absent (OBSOLETE)",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			"0" => {
				flags => "s",
				description => "Publisher distributor etc is not same as issuing body transcribed in added entry (OBSOLETE)",
				},
			"1" => {
				flags => "s",
				description => "Publisher distributor etc is same as issuing body transcribed in added entry (OBSOLETE)",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "Place of publication/distribution",
				},
			"b" => {
				flags => "R",
				description => "Name of publisher/distributor",
				},
			"c" => {
				flags => "R",
				description => "Date of publication/distribution",
				},
			"d" => {
				flags => "",
				description => "Plate or publisher's number (OBSOLETE)",
				},
			"e" => {
				flags => "",
				description => "Place of manufacture",
				},
			"f" => {
				flags => "",
				description => "Manufacturer",
				},
			"k" => {
				flags => "",
				description => "Identification/manufacturer number (OBSOLETE)",
				},
			"l" => {
				flags => "",
				description => "Matrix and/or take number (OBSOLETE)",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"261" => {
		flags => "v",
		shortname => "",
		description => "Production Statement (OBSOLETE)",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		},
	"263" => {
		flags => "sbvmf",
		shortname => "",
		description => "Projected Publication Date",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Projected publication date",
				},
			},
		},
	"265" => {
		flags => "sbvmcf",
		shortname => "",
		description => "Source for Acquisition/Subscription Address",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		},
	"300" => {
		flags => "R",
		shortname => "",
		description => "Physical Description",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "Extent (number of pages/volumes/cassettes/total playing time)",
				},
			"b" => {
				flags => "",
				description => "Other physical details",
				},
			"c" => {
				flags => "R",
				description => "Dimensions",
				},
			"e" => {
				flags => "",
				description => "Accompanying material",
				},
			"f" => {
				flags => "R",
				description => "Type of unit (eg: page/volumes/boxes/cu. ft.)",
				},
			"g" => {
				flags => "R",
				description => "Size of unit",
				},
			"k" => {
				flags => "",
				description => "Speed (OBSOLETE)",
				},
			"3" => {
				flags => "",
				description => "Material specified",
				},
			},
		},
	"302" => {
		flags => "bR",
		shortname => "",
		description => "Page count (OBSOLETE)",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Page count (OBSOLETE)",
				},
			},
		},
	"306" => {
		flags => "m",
		shortname => "",
		description => "Duration for Music Scores and Sound Recordings",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "Playing time",
				},
			},
		},
	"308" => {
		flags => "vR",
		shortname => "",
		description => "Physical Description for Archival Film Collections",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Number of reels (OBSOLETE)",
				},
			"b" => {
				flags => "",
				description => "Footage (OBSOLETE)",
				},
			"c" => {
				flags => "",
				description => "Sound (OBSOLETE)",
				},
			"d" => {
				flags => "",
				description => "Color (OBSOLETE)",
				},
			"e" => {
				flags => "",
				description => "Width (OBSOLETE)",
				},
			"f" => {
				flags => "",
				description => "Presentation format (OBSOLETE)",
				},
			},
		},
	"310" => {
		flags => "s",
		shortname => "",
		description => "Current Frequency",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Current publication frequency",
				},
			"b" => {
				flags => "",
				description => "Date of current publication frequency",
				},
			},
		},
	"315" => {
		flags => "cf",
		shortname => "",
		description => "Frequency",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "Frequency",
				},
			"b" => {
				flags => "R",
				description => "Date of frequency",
				},
			},
		},
	"320" => {
		flags => "s",
		shortname => "",
		description => "Current Frequency Control Information",
		},
	"321" => {
		flags => "sR",
		shortname => "",
		description => "Former Frequency",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Former publication frequency",
				},
			"b" => {
				flags => "",
				description => "Dates of former publication frequency",
				},
			},
		},
	"330" => {
		flags => "s",
		shortname => "",
		description => "Publication Pattern",
		},
	"331" => {
		flags => "sR",
		shortname => "",
		description => "Former Publication Pattern",
		},
	"340" => {
		flags => "avR",
		shortname => "",
		description => "Medium",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "Material base and configuration",
				},
			"b" => {
				flags => "R",
				description => "Dimensions",
				},
			"c" => {
				flags => "R",
				description => "Materials applied to surface",
				},
			"d" => {
				flags => "R",
				description => "Information recording technique",
				},
			"e" => {
				flags => "R",
				description => "Support",
				},
			"f" => {
				flags => "R",
				description => "Production rate/ratio",
				},
			"h" => {
				flags => "R",
				description => "Location within medium",
				},
			"i" => {
				flags => "R",
				description => "Technical specifications of medium",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"350" => {
		flags => "sf",
		shortname => "",
		description => "Subscription Price",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "Subscription price",
				},
			"b" => {
				flags => "R",
				description => "Form of issue",
				},
			},
		},
	"351" => {
		flags => "avfR",
		shortname => "",
		description => "Organization and Arrangement of Materials",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "Organization of materials",
				},
			"b" => {
				flags => "R",
				description => "Arrangement of materials",
				},
			"c" => {
				flags => "",
				description => "Hierarchical level",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"359" => {
		flags => "v",
		shortname => "",
		description => "Rental Price (OBSOLETE)",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "Rental price",
				},
			"b" => {
				flags => "R",
				description => "Vendor's name",
				},
			},
		},
	"362" => {
		flags => "sfR",
		shortname => "",
		description => "Dates of Publication and Volume Designations",
		ind1 => {
			"0" => {
				flags => "",
				description => "Formatted style",
				},
			"1" => {
				flags => "",
				description => "Unformatted note",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Dates of publication and/or sequential designation",
				},
			"z" => {
				flags => "",
				description => "Source of information",
				},
			},
		},
	"400" => {
		flags => "sbvmcfR",
		shortname => "",
		description => "Series Statement - PersonalName/Title (Traced) (Pre-AACR2 only) (OBSOLETE)",
		ind1 => {
			"0" => {
				flags => "",
				description => "Forename",
				},
			"1" => {
				flags => "",
				description => "Single surname",
				},
			"2" => {
				flags => "",
				description => "Multiple surname",
				},
			"3" => {
				flags => "",
				description => "Name of family",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "Main entry for series is not represented by a pronoun",
				},
			"1" => {
				flags => "",
				description => "Main entry for series is represented by a pronoun",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Name (surname and forenames)",
				},
			"b" => {
				flags => "",
				description => "Numeration (Roman numerals which may follow a forename)",
				},
			"c" => {
				flags => "R",
				description => "Titles and other words associated with the name",
				},
			"d" => {
				flags => "",
				description => "Dates assosciated with the name",
				},
			"e" => {
				flags => "R",
				description => "Relator",
				},
			"t" => {
				flags => "",
				description => "Title of series",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"l" => {
				flags => "",
				description => "Language",
				},
			"k" => {
				flags => "R",
				description => "Form subheading",
				},
			"f" => {
				flags => "",
				description => "Date of work",
				},
			"g" => {
				flags => "",
				description => "Miscellaneous information",
				},
			"h" => {
				flags => "",
				description => "General material designation",
				},
			"q" => {
				flags => "",
				description => "Fuller form of name",
				},
			"v" => {
				flags => "",
				description => "Volume or number (after the title)",
				},
			"x" => {
				flags => "",
				description => "International Standard Serial Number",
				},
			"4" => {
				flags => "R",
				description => "Relator code",
				},
			},
		},
	"410" => {
		flags => "sbvmcfR",
		shortname => "",
		description => "Series Statement - Corporate Name/Title (Traced) (Pre-AACR2 only) (OBSOLETE)",
		ind1 => {
			"0" => {
				flags => "",
				description => "Surname (inverted)",
				},
			"1" => {
				flags => "",
				description => "Place or place and name",
				},
			"2" => {
				flags => "",
				description => "Name (direct order)",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "Main entry for series is not represented by a pronoun",
				},
			"1" => {
				flags => "",
				description => "Main entry for series is represented by a pronoun",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Name",
				},
			"b" => {
				flags => "R",
				description => "Subheading",
				},
			"c" => {
				flags => "",
				description => "Place of conference or meeting",
				},
			"d" => {
				flags => "R",
				description => "Date of conference/meeting/treaty",
				},
			"e" => {
				flags => "R",
				description => "Relator",
				},
			"f" => {
				flags => "",
				description => "Date of work",
				},
			"g" => {
				flags => "",
				description => "Miscellaneous information",
				},
			"h" => {
				flags => "",
				description => "General material designation",
				},
			"l" => {
				flags => "",
				description => "Language",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"t" => {
				flags => "",
				description => "Title of series",
				},
			"v" => {
				flags => "",
				description => "Volume or number (after the title)",
				},
			"x" => {
				flags => "",
				description => "International Standard Serial Number",
				},
			"4" => {
				flags => "R",
				description => "Relator code",
				},
			},
		},
	"411" => {
		flags => "sbvmcfR",
		shortname => "",
		description => "Series Statement - Conference or Meeting Title (Traced) (Pre-AACR2 only) (OBSOLETE)",
		ind1 => {
			"0" => {
				flags => "",
				description => "Surname (inverted)",
				},
			"1" => {
				flags => "",
				description => "Place or place and name",
				},
			"2" => {
				flags => "",
				description => "Name (direct order)",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "Main entry for series is not represented by a pronoun",
				},
			"1" => {
				flags => "",
				description => "Main entry for series is represented by a pronoun",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Name of meeting or place element",
				},
			"c" => {
				flags => "",
				description => "Place where conference or meeting was held",
				},
			"d" => {
				flags => "",
				description => "Date of conference or meeting",
				},
			"e" => {
				flags => "R",
				description => "Subordinate unit",
				},
			"f" => {
				flags => "",
				description => "Date of work",
				},
			"g" => {
				flags => "",
				description => "Miscellaneous information",
				},
			"h" => {
				flags => "",
				description => "General material designation",
				},
			"l" => {
				flags => "",
				description => "Language",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"q" => {
				flags => "",
				description => "Name of meeting following place element",
				},
			"s" => {
				flags => "",
				description => "Version",
				},
			"t" => {
				flags => "",
				description => "Title of series",
				},
			"v" => {
				flags => "",
				description => "Volume or number (after the title)",
				},
			"x" => {
				flags => "",
				description => "Internation Standard Serial Number",
				},
			},
		},
	"440" => {
		flags => "sbvmcfR",
		shortname => "",
		description => "Series Statement - Title (Traced)",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"1" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"2" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"3" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"4" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"5" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"6" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"7" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"8" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			"9" => {
				flags => "",
				description => "Number of characters ignored in filing",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Title",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"v" => {
				flags => "",
				description => "Volume number/sequential designation",
				},
			"x" => {
				flags => "",
				description => "International Standard Serial Number",
				},
			},
		},
	"490" => {
		flags => "sbvmcfR",
		shortname => "",
		description => "Series Untraced or Traced Differently",
		ind1 => {
			"0" => {
				flags => "",
				description => "Series is not traced",
				},
			"1" => {
				flags => "",
				description => "Series is traced in a different form",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "Series statement",
				},
			"l" => {
				flags => "",
				description => "LC call number",
				},
			"v" => {
				flags => "",
				description => "Volume number/sequential designation",
				},
			"x" => {
				flags => "",
				description => "International Standard Serial Number",
				},
			},
		},
	"500" => {
		flags => "R",
		shortname => "",
		description => "General Notes",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "General note",
				},
			},
		},
	"501" => {
		flags => "bvmcfR",
		shortname => "",
		description => "Note for 'Bound with' or 'On reel with' etc",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "With note",
				},
			},
		},
	"502" => {
		flags => "bavmcfR",
		shortname => "",
		description => "Dissertation Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Dissertation note",
				},
			},
		},
	"503" => {
		flags => "bvmcfR",
		shortname => "",
		description => "Bibliographic History Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Bibliographic history note",
				},
			},
		},
	"504" => {
		flags => "sbmcfR",
		shortname => "",
		description => "Bibliographic/Discography Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Bibliography etc note",
				},
			"b" => {
				flags => "",
				description => "Number of references",
				},
			},
		},
	"505" => {
		flags => "bavmcf",
		shortname => "",
		description => "Contents Note (Formatted)",
		ind1 => {
			"0" => {
				flags => "",
				description => "Contents (complete)",
				},
			"1" => {
				flags => "",
				description => "Contents (incomplete)",
				},
			"2" => {
				flags => "",
				description => "Partial contents",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Formatted contents note",
				},
			"g" => {
				flags => "R",
				description => "Miscellaneous information",
				},
			"r" => {
				flags => "R",
				description => "Statement of responsibility",
				},
			"t" => {
				flags => "R",
				description => "Title",
				},
			"u" => {
				flags => "R",
				description => "Uniform Resource Identifier (URI)",
				},
			},
		},
	"506" => {
		flags => "R",
		shortname => "",
		description => "Restrictions on Access Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Terms governing access",
				},
			"b" => {
				flags => "R",
				description => "Jurisdiction",
				},
			"c" => {
				flags => "R",
				description => "Physical access provisions",
				},
			"d" => {
				flags => "R",
				description => "Authorized users",
				},
			"e" => {
				flags => "R",
				description => "Authorization",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"507" => {
		flags => "vc",
		shortname => "",
		description => "Scale Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Representative fraction of scale note",
				},
			"b" => {
				flags => "",
				description => "Remainder of scale note",
				},
			},
		},
	"508" => {
		flags => "vc",
		shortname => "",
		description => "Credits Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Creation/production credits note",
				},
			},
		},
	"510" => {
		flags => "R",
		shortname => "",
		description => "Citation/Reference Note",
		ind1 => {
			"0" => {
				flags => "s",
				description => "Coverage for item in indexing/abstracting source is unknown",
				},
			"1" => {
				flags => "sf",
				description => "Coverate for item in indexing/abstracting source is complete",
				},
			"2" => {
				flags => "sf",
				description => "Coverage for item in indexing/abstracting source is selective",
				},
			"3" => {
				flags => "",
				description => "Special location in source cited is not given",
				},
			"4" => {
				flags => "",
				description => "Special location in source cited is given",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Name of source",
				},
			"b" => {
				flags => "",
				description => "Dates of coverage",
				},
			"c" => {
				flags => "",
				description => "Location within source",
				},
			"x" => {
				flags => "",
				description => "Internation Standard Serial Number",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"511" => {
		flags => "vmR",
		shortname => "",
		description => "Participant or Performer Note",
		ind1 => {
			"0" => {
				flags => "",
				description => "General",
				},
			"1" => {
				flags => "",
				description => "Cast",
				},
			"2" => {
				flags => "",
				description => "Presenter",
				},
			"3" => {
				flags => "",
				description => "Narrator",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Participant or performer note",
				},
			},
		},
	"512" => {
		flags => "sR",
		shortname => "",
		description => "Earlier or Later Volumes Separately Catalogued (OBSOLETE)",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Earlier or later volumes separately catalogued note",
				},
			},
		},
	"513" => {
		flags => "sbcR",
		shortname => "",
		description => "Type of Report and Period Covered Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Type of report",
				},
			"b" => {
				flags => "",
				description => "Period covered",
				},
			},
		},
	"515" => {
		flags => "sR",
		shortname => "",
		description => "Numbering Peculiarities Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Numbering peculiarities note",
				},
			"z" => {
				flags => "",
				description => "Source of note (OBSOLETE)",
				},
			},
		},
	"516" => {
		flags => "fR",
		shortname => "",
		description => "Type of Computer File or Data Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "No information provided",
				},
			"8" => {
				flags => "",
				description => "No display constant generated",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Type of computer file or data note",
				},
			},
		},
	"517" => {
		flags => "v",
		shortname => "",
		description => "Categories of Films for Collections (Archival) (OBSOLETE)",
		ind1 => {
			"0" => {
				flags => "",
				description => "Non fiction",
				},
			"1" => {
				flags => "",
				description => "Fiction",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "Different formats",
				},
			"b" => {
				flags => "R",
				description => "Content descriptors",
				},
			"c" => {
				flags => "R",
				description => "Additional animation techniques",
				},
			},
		},
	"518" => {
		flags => "avmR",
		shortname => "",
		description => "Date/Time and Place of Event Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Date/time and place of an event note",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"520" => {
		flags => "R",
		shortname => "",
		description => "Summary Abstract Annotations Scope etc Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Information not provided",
				},
			"0" => {
				flags => "",
				description => "Subject",
				},
			"8" => {
				flags => "",
				description => "No display constant generated",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Summary etc note",
				},
			"b" => {
				flags => "",
				description => "Expansion of summary note",
				},
			"u" => {
				flags => "R",
				description => "Uniform Resource Identifier (URI)",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"521" => {
		flags => "R",
		shortname => "",
		description => "Target Audience Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Information not provided",
				},
			"0" => {
				flags => "",
				description => "Reading grade level",
				},
			"1" => {
				flags => "",
				description => "Interest age level",
				},
			"2" => {
				flags => "",
				description => "Interest grade level",
				},
			"8" => {
				flags => "",
				description => "No display constant generated",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "Target audience note",
				},
			"b" => {
				flags => "",
				description => "Source",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"522" => {
		flags => "R",
		shortname => "",
		description => "Geographic Coverage Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "No information provided",
				},
			"8" => {
				flags => "",
				description => "No display constant generated",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Geographic coverage note",
				},
			},
		},
	"523" => {
		flags => "f",
		shortname => "",
		description => "Time Period of Content Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Time period of content note",
				},
			"b" => {
				flags => "",
				description => "Dates of data collection note",
				},
			},
		},
	"524" => {
		flags => "avf",
		shortname => "",
		description => "Preferred Citation of Described Materials",
		ind1 => {
			"#" => {
				flags => "",
				description => "Information not provided",
				},
			"8" => {
				flags => "",
				description => "No display constant generated",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Preferred citation of described materials note",
				},
			"2" => {
				flags => "",
				description => "Source of schema used",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"525" => {
		flags => "sR",
		shortname => "",
		description => "Supplement Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Supplement note",
				},
			"z" => {
				flags => "",
				description => "Source of note (OBSOLETE)",
				},
			},
		},
	"526" => {
		flags => "R",
		shortname => "",
		description => "Study Program Information Note",
		ind1 => {
			"0" => {
				flags => "",
				description => "Reading program",
				},
			"8" => {
				flags => "",
				description => "No display constant generated",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Program name",
				},
			"b" => {
				flags => "",
				description => "Interest level",
				},
			"c" => {
				flags => "",
				description => "Reading level",
				},
			"d" => {
				flags => "",
				description => "Title point value",
				},
			"i" => {
				flags => "",
				description => "Display text",
				},
			"x" => {
				flags => "R",
				description => "Nonpublic note",
				},
			"z" => {
				flags => "R",
				description => "Public note",
				},
			},
		},
	"527" => {
		flags => "vR",
		shortname => "",
		description => "Censorship Note (Archival) (OBSOLETE)",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Censorship note (archival)",
				},
			},
		},
	"530" => {
		flags => "savfR",
		shortname => "",
		description => "Additional Physical Forms Available Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Additional physical form available note",
				},
			"b" => {
				flags => "",
				description => "Availability source",
				},
			"c" => {
				flags => "",
				description => "Availability conditions",
				},
			"d" => {
				flags => "",
				description => "Order number",
				},
			"u" => {
				flags => "",
				description => "Uniform Resource Identifier (URI)",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"533" => {
		flags => "sbavmcR",
		shortname => "",
		description => "Reproduction Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Type of reproduction",
				},
			"b" => {
				flags => "R",
				description => "Place of reproduction",
				},
			"c" => {
				flags => "R",
				description => "Agency responsible for reproduction",
				},
			"d" => {
				flags => "",
				description => "Date of reproduction",
				},
			"e" => {
				flags => "",
				description => "Physical description of reproduction",
				},
			"f" => {
				flags => "R",
				description => "Series statement of reproduction",
				},
			"m" => {
				flags => "R",
				description => "Dates and/or sequential designation of issues reproduced",
				},
			"n" => {
				flags => "R",
				description => "Note about reproduction",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			"7" => {
				flags => "",
				description => "Fixed-length data elements of reproduction",
				},
			},
		},
	"534" => {
		flags => "sbavmcR",
		shortname => "",
		description => "Original Version Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Information not provided",
				},
			"0" => {
				flags => "",
				description => "Note excludes series of original (OBSOLETE)",
				},
			"1" => {
				flags => "",
				description => "Note includes series of original (OBSOLETE)",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Main entry of original",
				},
			"b" => {
				flags => "",
				description => "Edition statement of original",
				},
			"c" => {
				flags => "",
				description => "Publication/distribution of original",
				},
			"e" => {
				flags => "",
				description => "Physical description of original",
				},
			"f" => {
				flags => "R",
				description => "Series statement of original",
				},
			"k" => {
				flags => "R",
				description => "Key title of original",
				},
			"l" => {
				flags => "",
				description => "Location of original",
				},
			"m" => {
				flags => "",
				description => "Material specific details",
				},
			"n" => {
				flags => "R",
				description => "Note about original",
				},
			"p" => {
				flags => "",
				description => "Introductory phrase",
				},
			"t" => {
				flags => "",
				description => "Title statement of original",
				},
			"x" => {
				flags => "R",
				description => "International Standard Serial Number",
				},
			"z" => {
				flags => "R",
				description => "International Standard Book Number",
				},
			},
		},
	"535" => {
		flags => "R",
		shortname => "",
		description => "Location of Originals/Duplicates",
		ind1 => {
			"1" => {
				flags => "",
				description => "Holder of originals",
				},
			"2" => {
				flags => "",
				description => "Holder of duplicates",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Custodian (repository)",
				},
			"b" => {
				flags => "R",
				description => "Postal address",
				},
			"c" => {
				flags => "R",
				description => "Country",
				},
			"d" => {
				flags => "R",
				description => "Telecommunications address",
				},
			"g" => {
				flags => "",
				description => "Repository location code",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"536" => {
		flags => "sbcfR",
		shortname => "",
		description => "Funding Information Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Text of note",
				},
			"b" => {
				flags => "R",
				description => "Contract number",
				},
			"c" => {
				flags => "R",
				description => "Grant number",
				},
			"d" => {
				flags => "R",
				description => "Undifferentiated number",
				},
			"e" => {
				flags => "R",
				description => "Program element number",
				},
			"f" => {
				flags => "R",
				description => "Project number",
				},
			"g" => {
				flags => "R",
				description => "Task number",
				},
			"h" => {
				flags => "R",
				description => "Work unit number",
				},
			},
		},
	"537" => {
		flags => "f",
		shortname => "",
		description => "Source of Data Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Information not provided",
				},
			"8" => {
				flags => "",
				description => "No display constant generated",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		},
	"538" => {
		flags => "vfR",
		shortname => "",
		description => "System Details Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "System details note",
				},
			},
		},
	"540" => {
		flags => "avR",
		shortname => "",
		description => "Terms Governing Use and Reproduction",
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Terms governing use and reproduction",
				},
			"b" => {
				flags => "",
				description => "Jurisdiction",
				},
			"c" => {
				flags => "",
				description => "Authorization",
				},
			"d" => {
				flags => "",
				description => "Authorized users",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"541" => {
		flags => "avmR",
		shortname => "",
		description => "Immediate Source of Acquisition",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Source of acquisition",
				},
			"b" => {
				flags => "",
				description => "Address",
				},
			"c" => {
				flags => "",
				description => "Method of acquisition",
				},
			"d" => {
				flags => "",
				description => "Date of acquisition",
				},
			"e" => {
				flags => "",
				description => "Accession number",
				},
			"f" => {
				flags => "",
				description => "Owner",
				},
			"h" => {
				flags => "",
				description => "Purchase price",
				},
			"n" => {
				flags => "R",
				description => "Extent",
				},
			"o" => {
				flags => "R",
				description => "Type of unit",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"544" => {
		flags => "aR",
		shortname => "",
		description => "Location of Associated Materials",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "Custodian",
				},
			"b" => {
				flags => "R",
				description => "Address",
				},
			"c" => {
				flags => "R",
				description => "Country",
				},
			"d" => {
				flags => "R",
				description => "Title",
				},
			"e" => {
				flags => "R",
				description => "Provenance",
				},
			"n" => {
				flags => "R",
				description => "Note",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"545" => {
		flags => "avR",
		shortname => "",
		description => "Biographical of Historical Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Biographical or historical note",
				},
			"b" => {
				flags => "",
				description => "Expansion",
				},
			"u" => {
				flags => "R",
				description => "Uniform Resource Identifier (URI)",
				},
			},
		},
	"546" => {
		flags => "saR",
		shortname => "",
		description => "Language Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Language note",
				},
			"b" => {
				flags => "R",
				description => "Information code or alphabet",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"547" => {
		flags => "sR",
		shortname => "",
		description => "Former Title Complexity Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Former title complexity note",
				},
			},
		},
	"550" => {
		flags => "sR",
		shortname => "",
		description => "Issuing Bodies Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Information not provided",
				},
			"0" => {
				flags => "",
				description => "Repetitious note (OBSOLETE)",
				},
			"1" => {
				flags => "",
				description => "Not repetitios (OBSOLETE)",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Issuing body note",
				},
			},
		},
	"555" => {
		flags => "savR",
		shortname => "",
		description => "Cumulative Index/Finding Aids Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Information not provided",
				},
			"0" => {
				flags => "av",
				description => "Finding aids",
				},
			"8" => {
				flags => "",
				description => "No print constant generated",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Cumulative index/finding aids note",
				},
			"b" => {
				flags => "R",
				description => "Availablility source",
				},
			"c" => {
				flags => "",
				description => "Degree of control",
				},
			"d" => {
				flags => "",
				description => "Bibliographic reference",
				},
			"u" => {
				flags => "R",
				description => "Uniform Resource Identifier (URI)",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"556" => {
		flags => "fR",
		shortname => "",
		description => "Information about Documentation Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Information not provided",
				},
			"8" => {
				flags => "",
				description => "No display constant generated",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Information about documentation note",
				},
			"z" => {
				flags => "R",
				description => "International Standard Book Number",
				},
			},
		},
	"561" => {
		flags => "avR",
		shortname => "",
		description => "Provenance Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Provenance note",
				},
			"b" => {
				flags => "",
				description => "Time of collation",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"562" => {
		flags => "aR",
		shortname => "",
		description => "Copy and Version Identification Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "Identifying markings",
				},
			"b" => {
				flags => "R",
				description => "Copy identification",
				},
			"c" => {
				flags => "R",
				description => "Version identification",
				},
			"d" => {
				flags => "R",
				description => "Presentation format",
				},
			"e" => {
				flags => "R",
				description => "Number of copies",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"565" => {
		flags => "afR",
		shortname => "",
		description => "Case File Characteristics Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Information not provided",
				},
			"0" => {
				flags => "a",
				description => "Case file characteristics",
				},
			"8" => {
				flags => "",
				description => "No display constant generated",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Number of cases/variables",
				},
			"b" => {
				flags => "R",
				description => "Name of variable",
				},
			"c" => {
				flags => "R",
				description => "Unit of analysis",
				},
			"d" => {
				flags => "R",
				description => "Universe of data",
				},
			"e" => {
				flags => "R",
				description => "Filing scheme or code",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"567" => {
		flags => "fR",
		shortname => "",
		description => "Methodology Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Information not provided",
				},
			"8" => {
				flags => "",
				description => "No display constant generated",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Methodology note",
				},
			},
		},
	"570" => {
		flags => "sR",
		shortname => "",
		description => "Editor Note (OBSOLETE)",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Editor note",
				},
			"z" => {
				flags => "",
				description => "Source of note",
				},
			},
		},
	"580" => {
		flags => "R",
		shortname => "",
		description => "Linking Entry Complexity Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Linking entry complexity note",
				},
			"z" => {
				flags => "",
				description => "Source of note (OBSOLETE)",
				},
			},
		},
	"581" => {
		flags => "avfR",
		shortname => "",
		description => "Publications Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Information not provided",
				},
			"8" => {
				flags => "",
				description => "No display constant generated",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Publications about described materials note",
				},
			"z" => {
				flags => "R",
				description => "International Standard Book Number",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"582" => {
		flags => "fR",
		shortname => "",
		description => "Related Computer Files Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Information not provided",
				},
			"8" => {
				flags => "",
				description => "No display constant generated",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Related computer files note",
				},
			},
		},
	"583" => {
		flags => "R",
		shortname => "",
		description => "Actions Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Action",
				},
			"b" => {
				flags => "R",
				description => "Action identification",
				},
			"c" => {
				flags => "R",
				description => "Time/date of action",
				},
			"d" => {
				flags => "R",
				description => "Action interval",
				},
			"e" => {
				flags => "R",
				description => "Contingency for action",
				},
			"f" => {
				flags => "R",
				description => "Authorization",
				},
			"h" => {
				flags => "R",
				description => "Jurisdiction",
				},
			"i" => {
				flags => "R",
				description => "Method of action",
				},
			"j" => {
				flags => "R",
				description => "Site of action",
				},
			"k" => {
				flags => "R",
				description => "Action agent",
				},
			"l" => {
				flags => "R",
				description => "Status",
				},
			"n" => {
				flags => "R",
				description => "Extent",
				},
			"o" => {
				flags => "R",
				description => "Type of unit",
				},
			"u" => {
				flags => "R",
				description => "Uniform Resource Identifier (URI)",
				},
			"x" => {
				flags => "R",
				description => "Nonpublic note",
				},
			"z" => {
				flags => "R",
				description => "Public note",
				},
			"2" => {
				flags => "",
				description => "Source of term",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"584" => {
		flags => "aR",
		shortname => "",
		description => "Accumulation and Frequency of Use",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "Accumulation",
				},
			"b" => {
				flags => "R",
				description => "Frequency of use",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"585" => {
		flags => "vR",
		shortname => "",
		description => "Exhibitions Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Exhibitions note",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"586" => {
		flags => "R",
		shortname => "",
		description => "Award or Price Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Information not provided",
				},
			"8" => {
				flags => "",
				description => "No display constant generated",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Awards note",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"590" => {
		flags => "R",
		shortname => "",
		description => "Local Note",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Local note",
				},
			},
		},
	"600" => {
		flags => "R",
		shortname => "",
		description => "Subject Heading - Personal Name",
		ind1 => {
			"0" => {
				flags => "",
				description => "Forename",
				},
			"1" => {
				flags => "",
				description => "Single surname",
				},
			"2" => {
				flags => "",
				description => "Multiple surname",
				},
			"3" => {
				flags => "",
				description => "Name of family",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "Library of Congress subject heading",
				},
			"1" => {
				flags => "",
				description => "Annotated Card Program subject heading",
				},
			"2" => {
				flags => "",
				description => "National Library of Medicine subject heading",
				},
			"3" => {
				flags => "",
				description => "National Agricultural Library subject heading",
				},
			"4" => {
				flags => "",
				description => "Other subject heading",
				},
			"5" => {
				flags => "",
				description => "National Library of Canada - English subject heading",
				},
			"6" => {
				flags => "",
				description => "National Library of Canada - French subject heading",
				},
			"7" => {
				flags => "",
				description => "Subject heading or term (source specified in subfield \$2)",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Personal name",
				},
			"b" => {
				flags => "",
				description => "Numeration",
				},
			"c" => {
				flags => "R",
				description => "Titles and other words associated with a name",
				},
			"d" => {
				flags => "",
				description => "Dates associated with a name",
				},
			"e" => {
				flags => "R",
				description => "Relator term",
				},
			"f" => {
				flags => "",
				description => "Date of work",
				},
			"g" => {
				flags => "",
				description => "Miscellaneous information",
				},
			"h" => {
				flags => "",
				description => "Medium",
				},
			"k" => {
				flags => "R",
				description => "Form subheading",
				},
			"j" => {
				flags => "R",
				description => "Attribution qualifier",
				},
			"l" => {
				flags => "",
				description => "Language",
				},
			"m" => {
				flags => "R",
				description => "Medium of performance for music",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section",
				},
			"o" => {
				flags => "",
				description => "Arranged statement for music",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"q" => {
				flags => "",
				description => "Fuller form of name",
				},
			"r" => {
				flags => "",
				description => "Key for music",
				},
			"s" => {
				flags => "",
				description => "Version",
				},
			"t" => {
				flags => "",
				description => "Title of work",
				},
			"u" => {
				flags => "",
				description => "Affiliation",
				},
			"v" => {
				flags => "R",
				description => "Form subdivision",
				},
			"x" => {
				flags => "R",
				description => "General subdivision",
				},
			"y" => {
				flags => "R",
				description => "Chronological subdivision",
				},
			"z" => {
				flags => "R",
				description => "Geographic subdivision",
				},
			"2" => {
				flags => "",
				description => "Source of heading or term",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			"4" => {
				flags => "R",
				description => "Relator code",
				},
			},
		},
	"610" => {
		flags => "R",
		shortname => "",
		description => "Subject Heading - Corporate Name",
		ind1 => {
			"0" => {
				flags => "",
				description => "Surname (inverted)",
				},
			"1" => {
				flags => "",
				description => "Place or place and name",
				},
			"2" => {
				flags => "",
				description => "Name (direct order)",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "Library of Congress subject heading",
				},
			"1" => {
				flags => "",
				description => "Annotated Card Program subject heading",
				},
			"2" => {
				flags => "",
				description => "National Library of Medicine subject heading",
				},
			"3" => {
				flags => "",
				description => "National Agricultural Library subject heading",
				},
			"4" => {
				flags => "",
				description => "Other subject heading",
				},
			"5" => {
				flags => "",
				description => "National Library of Canada - English subject heading",
				},
			"6" => {
				flags => "",
				description => "National Library of Canada - French subject heading",
				},
			"7" => {
				flags => "",
				description => "Subject heading or term (source specified in subfield \$2)",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Corporate name or jurisdiction name as entry element",
				},
			"b" => {
				flags => "R",
				description => "Subordinate unit",
				},
			"c" => {
				flags => "",
				description => "Location of meeting",
				},
			"d" => {
				flags => "R",
				description => "Date of meeting or treaty signing",
				},
			"e" => {
				flags => "R",
				description => "Relator term",
				},
			"f" => {
				flags => "",
				description => "Date of work",
				},
			"g" => {
				flags => "",
				description => "Miscellaneous information",
				},
			"h" => {
				flags => "",
				description => "Medium",
				},
			"k" => {
				flags => "R",
				description => "Form subheading",
				},
			"l" => {
				flags => "",
				description => "Language",
				},
			"m" => {
				flags => "R",
				description => "Medium of performance for music",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section",
				},
			"o" => {
				flags => "",
				description => "Arranged statement for music",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"r" => {
				flags => "",
				description => "Key for music",
				},
			"s" => {
				flags => "",
				description => "Version",
				},
			"t" => {
				flags => "",
				description => "Title",
				},
			"u" => {
				flags => "",
				description => "Affiliation",
				},
			"v" => {
				flags => "R",
				description => "Form subdivision",
				},
			"y" => {
				flags => "R",
				description => "Chronological subdivision",
				},
			"z" => {
				flags => "R",
				description => "Geographic subdivision",
				},
			"2" => {
				flags => "",
				description => "Source of heading or term",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			"4" => {
				flags => "R",
				description => "Relator code",
				},
			},
		},
	"611" => {
		flags => "R",
		shortname => "",
		description => "Subject Heading - Conference or Meeting",
		ind1 => {
			"0" => {
				flags => "",
				description => "Surname (inverted)",
				},
			"1" => {
				flags => "",
				description => "Place or place and name",
				},
			"2" => {
				flags => "",
				description => "Name (direct order)",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "Library of Congress subject heading",
				},
			"1" => {
				flags => "",
				description => "Annotated Card Program subject heading",
				},
			"2" => {
				flags => "",
				description => "National Library of Medicine subject heading",
				},
			"3" => {
				flags => "",
				description => "National Agricultural Library subject heading",
				},
			"4" => {
				flags => "",
				description => "Other subject heading",
				},
			"5" => {
				flags => "",
				description => "National Library of Canada - English subject heading",
				},
			"6" => {
				flags => "",
				description => "National Library of Canada - French subject heading",
				},
			"7" => {
				flags => "",
				description => "Subject heading or term (source specified in subfield \$2)",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Meeting name or jurisdiction name as entry element",
				},
			"c" => {
				flags => "",
				description => "Location of meeting",
				},
			"d" => {
				flags => "",
				description => "Date of meeting",
				},
			"e" => {
				flags => "R",
				description => "Subordinate unit",
				},
			"f" => {
				flags => "",
				description => "Date of work",
				},
			"g" => {
				flags => "",
				description => "Miscellaneous information",
				},
			"h" => {
				flags => "",
				description => "Medium",
				},
			"k" => {
				flags => "R",
				description => "Form subheading",
				},
			"l" => {
				flags => "",
				description => "Language",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"q" => {
				flags => "",
				description => "Name of meeting following jurisdiction name entry element",
				},
			"s" => {
				flags => "",
				description => "Version",
				},
			"t" => {
				flags => "",
				description => "Title",
				},
			"u" => {
				flags => "",
				description => "Affiliation",
				},
			"v" => {
				flags => "R",
				description => "Form subdivision",
				},
			"x" => {
				flags => "R",
				description => "General subdivision",
				},
			"y" => {
				flags => "R",
				description => "Chronological subdivision",
				},
			"z" => {
				flags => "R",
				description => "Geographic subdivision",
				},
			"2" => {
				flags => "",
				description => "Source of heading or term",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			"4" => {
				flags => "",
				description => "Relator code",
				},
			},
		},
	"630" => {
		flags => "R",
		shortname => "",
		description => "Subject Heading - Uniform Title Heading",
		ind1 => {
			"0" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"1" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"2" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"3" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"4" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"5" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"6" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"7" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"8" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"9" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "Library of Congress subject heading",
				},
			"1" => {
				flags => "",
				description => "Annotated Card Program subject heading",
				},
			"2" => {
				flags => "",
				description => "National Library of Medicine subject heading",
				},
			"3" => {
				flags => "",
				description => "National Agricultural Library subject heading",
				},
			"4" => {
				flags => "",
				description => "Other subject heading",
				},
			"5" => {
				flags => "",
				description => "National Library of Canada - English subject heading",
				},
			"6" => {
				flags => "",
				description => "National Library of Canada - French subject heading",
				},
			"7" => {
				flags => "",
				description => "Subject heading or term (source specified in subfield \$2)",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Uniform title",
				},
			"d" => {
				flags => "R",
				description => "Date of treaty signing",
				},
			"f" => {
				flags => "",
				description => "Date of work",
				},
			"g" => {
				flags => "",
				description => "Miscellaneous information",
				},
			"h" => {
				flags => "",
				description => "Medium",
				},
			"k" => {
				flags => "R",
				description => "Form subheading",
				},
			"l" => {
				flags => "",
				description => "Language",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"q" => {
				flags => "",
				description => "Name of meeting following jurisdiction name entry element",
				},
			"s" => {
				flags => "",
				description => "Version",
				},
			"t" => {
				flags => "",
				description => "Title",
				},
			"u" => {
				flags => "",
				description => "Affiliation",
				},
			"v" => {
				flags => "R",
				description => "Form subdivision",
				},
			"x" => {
				flags => "R",
				description => "General subdivision",
				},
			"y" => {
				flags => "R",
				description => "Chronological subdivision",
				},
			"z" => {
				flags => "R",
				description => "Geographic subdivision",
				},
			"2" => {
				flags => "",
				description => "Source of heading or term",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			"4" => {
				flags => "",
				description => "Relator code",
				},
			},
		},
	"650" => {
		flags => "R",
		shortname => "",
		description => "Subject Heading - Topical",
		ind1 => {
			"#" => {
				flags => "bf",
				description => "Information not provided",
				},
			"0" => {
				flags => "bf",
				description => "No level specified",
				},
			"1" => {
				flags => "bf",
				description => "Primary subject",
				},
			"2" => {
				flags => "bf",
				description => "Secondary subject",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "Library of Congress subject heading",
				},
			"1" => {
				flags => "",
				description => "Annotated Card Program subject heading",
				},
			"2" => {
				flags => "",
				description => "National Library of Medicine subject heading",
				},
			"3" => {
				flags => "",
				description => "National Agricultural Library subject heading",
				},
			"4" => {
				flags => "",
				description => "Other subject heading",
				},
			"5" => {
				flags => "",
				description => "National Library of Canada - English subject heading",
				},
			"6" => {
				flags => "",
				description => "National Library of Canada - French subject heading",
				},
			"7" => {
				flags => "",
				description => "Subject heading or term (source specified in subfield \$2)",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Topical term or geographic name as entry element",
				},
			"b" => {
				flags => "",
				description => "Topical term following geographic name as entry element",
				},
			"c" => {
				flags => "",
				description => "Location of event",
				},
			"d" => {
				flags => "",
				description => "Active dates",
				},
			"e" => {
				flags => "",
				description => "Relator term",
				},
			"v" => {
				flags => "R",
				description => "Form subdivision",
				},
			"x" => {
				flags => "R",
				description => "General subdivision",
				},
			"y" => {
				flags => "R",
				description => "Chronological subdivision",
				},
			"z" => {
				flags => "R",
				description => "Geographic subdivision",
				},
			"2" => {
				flags => "",
				description => "Source of heading or term",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"651" => {
		flags => "R",
		shortname => "",
		description => "Subject Heading - Geographic Name",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "Library of Congress subject heading",
				},
			"1" => {
				flags => "",
				description => "Annotated Card Program subject heading",
				},
			"2" => {
				flags => "",
				description => "National Library of Medicine subject heading",
				},
			"3" => {
				flags => "",
				description => "National Agricultural Library subject heading",
				},
			"4" => {
				flags => "",
				description => "Other subject heading",
				},
			"5" => {
				flags => "",
				description => "National Library of Canada - English subject heading",
				},
			"6" => {
				flags => "",
				description => "National Library of Canada - French subject heading",
				},
			"7" => {
				flags => "",
				description => "Subject heading or term (source specified in subfield \$2)",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Geographic name",
				},
			"v" => {
				flags => "R",
				description => "Form subdivision",
				},
			"x" => {
				flags => "R",
				description => "General subdivision",
				},
			"y" => {
				flags => "R",
				description => "Chronological subdivision",
				},
			"z" => {
				flags => "R",
				description => "Geographic subdivision",
				},
			"2" => {
				flags => "",
				description => "Source of heading or term",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"652" => {
		flags => "sbcR",
		shortname => "",
		description => "Reversed Geographic Subject Heading (OBSOLETE)",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Geohraphic name or place element",
				},
			"x" => {
				flags => "R",
				description => "General subdivision",
				},
			"y" => {
				flags => "R",
				description => "Chronological subdivision",
				},
			"z" => {
				flags => "R",
				description => "Geographic subdivision",
				},
			},
		},
	"653" => {
		flags => "sbvmcfR",
		shortname => "",
		description => "Index Term - Uncontrolled Heading",
		ind1 => {
			"#" => {
				flags => "",
				description => "Information not available",
				},
			"0" => {
				flags => "",
				description => "No level specified",
				},
			"1" => {
				flags => "",
				description => "Primary term",
				},
			"2" => {
				flags => "",
				description => "Secondary term",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "Uncontrolled term",
				},
			},
		},
	"654" => {
		flags => "R",
		shortname => "",
		description => "Subject Heading - Faceted Topical Terms",
		ind1 => {
			"#" => {
				flags => "",
				description => "Information not available",
				},
			"0" => {
				flags => "",
				description => "No level specified",
				},
			"1" => {
				flags => "",
				description => "Primary heading",
				},
			"2" => {
				flags => "",
				description => "Secondary heading",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Focus term",
				},
			"b" => {
				flags => "R",
				description => "Non-focus term",
				},
			"c" => {
				flags => "R",
				description => "Facet/hierarch designation",
				},
			"v" => {
				flags => "R",
				description => "Form subdivision",
				},
			"y" => {
				flags => "R",
				description => "Chronological subdivision",
				},
			"z" => {
				flags => "R",
				description => "Geographic subdivision",
				},
			"2" => {
				flags => "",
				description => "Source of heading or term",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"655" => {
		flags => "sbavmcR",
		shortname => "",
		description => "Genre/form heading",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Basic heading",
				},
			"0" => {
				flags => "",
				description => "Faceted heading",
				},
			"7" => {
				flags => "",
				description => "Genre/form heading (source specified in subfield \$2)",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Genre/form data or focus term",
				},
			"b" => {
				flags => "R",
				description => "Non-focus term",
				},
			"c" => {
				flags => "R",
				description => "Facet/hierarch designation",
				},
			"v" => {
				flags => "R",
				description => "Form subdivision",
				},
			"x" => {
				flags => "R",
				description => "General subdivision",
				},
			"y" => {
				flags => "R",
				description => "Chronological subdivision",
				},
			"z" => {
				flags => "R",
				description => "Geographic subdivision",
				},
			"2" => {
				flags => "",
				description => "Source of term",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"656" => {
		flags => "aR",
		shortname => "",
		description => "Index Term - Occupation",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"7" => {
				flags => "",
				description => "Genre/form heading (source specified in subfield \$2)",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Occupation",
				},
			"k" => {
				flags => "",
				description => "Form",
				},
			"v" => {
				flags => "R",
				description => "Form subdivision",
				},
			"x" => {
				flags => "R",
				description => "General subdivision",
				},
			"y" => {
				flags => "R",
				description => "Chronological subdivision",
				},
			"z" => {
				flags => "R",
				description => "Geographic subdivision",
				},
			"2" => {
				flags => "",
				description => "Source of term",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"657" => {
		flags => "aR",
		shortname => "",
		description => "Index Term - Function",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"7" => {
				flags => "",
				description => "Genre/form heading (source specified in subfield \$2)",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Function",
				},
			"v" => {
				flags => "R",
				description => "Form subdivision",
				},
			"x" => {
				flags => "R",
				description => "General subdivision",
				},
			"y" => {
				flags => "R",
				description => "Chronological subdivision",
				},
			"z" => {
				flags => "R",
				description => "Geographic subdivision",
				},
			"2" => {
				flags => "",
				description => "Source of term",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"680" => {
		flags => "R",
		shortname => "",
		description => "PRECIS Descriptor String (OBSOLETE)",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "Links alternative subject statements to the corresonding Dewey classification number",
				},
			"1" => {
				flags => "",
				description => "Links alternative subject statements to the corresonding Dewey classification number",
				},
			"2" => {
				flags => "",
				description => "Links alternative subject statements to the corresonding Dewey classification number",
				},
			"3" => {
				flags => "",
				description => "Links alternative subject statements to the corresonding Dewey classification number",
				},
			"4" => {
				flags => "",
				description => "Links alternative subject statements to the corresonding Dewey classification number",
				},
			"5" => {
				flags => "",
				description => "Links alternative subject statements to the corresonding Dewey classification number",
				},
			"6" => {
				flags => "",
				description => "Links alternative subject statements to the corresonding Dewey classification number",
				},
			"7" => {
				flags => "",
				description => "Links alternative subject statements to the corresonding Dewey classification number",
				},
			"8" => {
				flags => "",
				description => "Links alternative subject statements to the corresonding Dewey classification number",
				},
			"9" => {
				flags => "",
				description => "Links alternative subject statements to the corresonding Dewey classification number",
				},
			},
		},
	"681" => {
		flags => "R",
		shortname => "",
		description => "PRECIS Subject Indicator Number (OBSOLETE)",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "Links the indicator to the corresponding PRECIS string and other associated subject data",
				},
			"1" => {
				flags => "",
				description => "Links the indicator to the corresponding PRECIS string and other associated subject data",
				},
			"2" => {
				flags => "",
				description => "Links the indicator to the corresponding PRECIS string and other associated subject data",
				},
			"3" => {
				flags => "",
				description => "Links the indicator to the corresponding PRECIS string and other associated subject data",
				},
			"4" => {
				flags => "",
				description => "Links the indicator to the corresponding PRECIS string and other associated subject data",
				},
			"5" => {
				flags => "",
				description => "Links the indicator to the corresponding PRECIS string and other associated subject data",
				},
			"6" => {
				flags => "",
				description => "Links the indicator to the corresponding PRECIS string and other associated subject data",
				},
			"7" => {
				flags => "",
				description => "Links the indicator to the corresponding PRECIS string and other associated subject data",
				},
			"8" => {
				flags => "",
				description => "Links the indicator to the corresponding PRECIS string and other associated subject data",
				},
			"9" => {
				flags => "",
				description => "Links the indicator to the corresponding PRECIS string and other associated subject data",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "PRECIS subject indicator number",
				},
			},
		},
	"683" => {
		flags => "R",
		shortname => "",
		description => "PRECIS Reference Indicator Number (OBSOLETE)",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Reference indicator number",
				},
			},
		},
	"700" => {
		flags => "R",
		shortname => "",
		description => "Added Entry - Personal Name",
		ind1 => {
			"0" => {
				flags => "",
				description => "Forename",
				},
			"1" => {
				flags => "",
				description => "Single surname",
				},
			"2" => {
				flags => "",
				description => "Multiple surname",
				},
			"3" => {
				flags => "",
				description => "Name of family",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "Alternative entry",
				},
			"1" => {
				flags => "",
				description => "Secondary entry",
				},
			"2" => {
				flags => "",
				description => "Analytical entry",
				},
			"3" => {
				flags => "vmc",
				description => "Supplementary secondary entry",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Personal name",
				},
			"b" => {
				flags => "",
				description => "Numeration",
				},
			"c" => {
				flags => "R",
				description => "Titles and other words associated with name",
				},
			"d" => {
				flags => "",
				description => "Dates associated with name",
				},
			"e" => {
				flags => "R",
				description => "Relator term",
				},
			"f" => {
				flags => "",
				description => "Date of work",
				},
			"g" => {
				flags => "",
				description => "Miscellaneous information",
				},
			"h" => {
				flags => "",
				description => "Medium",
				},
			"j" => {
				flags => "R",
				description => "Attribution qualifier",
				},
			"k" => {
				flags => "R",
				description => "Form subheading",
				},
			"l" => {
				flags => "",
				description => "Language",
				},
			"m" => {
				flags => "R",
				description => "Medium of performance for music",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section",
				},
			"o" => {
				flags => "",
				description => "Arranged statement for music",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"q" => {
				flags => "",
				description => "Fuller form of name",
				},
			"r" => {
				flags => "",
				description => "Key for music",
				},
			"s" => {
				flags => "",
				description => "Version",
				},
			"t" => {
				flags => "",
				description => "Title",
				},
			"u" => {
				flags => "",
				description => "Affiliation",
				},
			"x" => {
				flags => "",
				description => "International Standard Serial Number",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			"4" => {
				flags => "R",
				description => "Relator code",
				},
			},
		},
	"710" => {
		flags => "R",
		shortname => "",
		description => "Added Entry - Corporate Name",
		ind1 => {
			"0" => {
				flags => "",
				description => "Surname (inverted)",
				},
			"1" => {
				flags => "",
				description => "Place or place and name",
				},
			"2" => {
				flags => "",
				description => "Name (direct order)",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "Alternative entry",
				},
			"1" => {
				flags => "",
				description => "Secondary entry",
				},
			"2" => {
				flags => "",
				description => "Analytical entry",
				},
			"3" => {
				flags => "vmc",
				description => "Supplementary secondary entry",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Corporate name or jurisdiction name as entry element",
				},
			"b" => {
				flags => "R",
				description => "Subordinate unit",
				},
			"c" => {
				flags => "",
				description => "Location of meeting",
				},
			"d" => {
				flags => "R",
				description => "Date of meeting or treaty signing",
				},
			"e" => {
				flags => "R",
				description => "Relator term",
				},
			"f" => {
				flags => "",
				description => "Date of work",
				},
			"g" => {
				flags => "",
				description => "Miscellaneous information",
				},
			"h" => {
				flags => "",
				description => "Medium",
				},
			"k" => {
				flags => "R",
				description => "Form subheading",
				},
			"l" => {
				flags => "",
				description => "Language",
				},
			"m" => {
				flags => "R",
				description => "Medium of performance for music",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section",
				},
			"o" => {
				flags => "",
				description => "Arranged statement for music",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"q" => {
				flags => "",
				description => "Fuller form of name",
				},
			"r" => {
				flags => "",
				description => "Key for music",
				},
			"s" => {
				flags => "",
				description => "Version",
				},
			"t" => {
				flags => "",
				description => "Title",
				},
			"u" => {
				flags => "",
				description => "Affiliation",
				},
			"x" => {
				flags => "",
				description => "International Standard Serial Number",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			"4" => {
				flags => "R",
				description => "Relator code",
				},
			},
		},
	"711" => {
		flags => "R",
		shortname => "",
		description => "Added Entry - Conference or Meeting",
		ind1 => {
			"0" => {
				flags => "",
				description => "Surname (inverted)",
				},
			"1" => {
				flags => "",
				description => "Place or place and name",
				},
			"2" => {
				flags => "",
				description => "Name (direct order)",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "Alternative entry",
				},
			"1" => {
				flags => "",
				description => "Secondary entry",
				},
			"2" => {
				flags => "",
				description => "Analytical entry",
				},
			"3" => {
				flags => "vmc",
				description => "Supplementary secondary entry",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Meeting name or jurisdiction name as entry element",
				},
			"b" => {
				flags => "",
				description => "Location of meeting",
				},
			"c" => {
				flags => "",
				description => "Location of meeting",
				},
			"d" => {
				flags => "R",
				description => "Date of meeting or treaty signing",
				},
			"e" => {
				flags => "R",
				description => "Relator term",
				},
			"f" => {
				flags => "",
				description => "Date of work",
				},
			"g" => {
				flags => "",
				description => "Miscellaneous information",
				},
			"h" => {
				flags => "",
				description => "Medium",
				},
			"k" => {
				flags => "R",
				description => "Form subheading",
				},
			"l" => {
				flags => "",
				description => "Language",
				},
			"m" => {
				flags => "R",
				description => "Medium of performance for music",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section",
				},
			"o" => {
				flags => "",
				description => "Arranged statement for music",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"q" => {
				flags => "",
				description => "Fuller form of name",
				},
			"r" => {
				flags => "",
				description => "Key for music",
				},
			"s" => {
				flags => "",
				description => "Version",
				},
			"t" => {
				flags => "",
				description => "Title",
				},
			"u" => {
				flags => "",
				description => "Affiliation",
				},
			"x" => {
				flags => "",
				description => "International Standard Serial Number",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			"4" => {
				flags => "R",
				description => "Relator code",
				},
			},
		},
	"720" => {
		flags => "R",
		shortname => "",
		description => "Added Entry - Uncontrolled Name",
		ind1 => {
			"#" => {
				flags => "",
				description => "Not specified",
				},
			"1" => {
				flags => "",
				description => "Personal",
				},
			"2" => {
				flags => "",
				description => "Other",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Name",
				},
			"e" => {
				flags => "R",
				description => "Relator term",
				},
			"4" => {
				flags => "R",
				description => "Relator code",
				},
			},
		},
	"730" => {
		flags => "R",
		shortname => "",
		description => "Added Entry - Uniform Title Heading",
		ind1 => {
			"0" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"1" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"2" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"3" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"4" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"5" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"6" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"7" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"8" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"9" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "Alternative entry",
				},
			"1" => {
				flags => "",
				description => "Secondary entry",
				},
			"2" => {
				flags => "",
				description => "Analytical entry",
				},
			"3" => {
				flags => "vmc",
				description => "Supplementary secondary entry",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Uniform title",
				},
			"d" => {
				flags => "R",
				description => "Date of treaty signing",
				},
			"f" => {
				flags => "",
				description => "Date of work",
				},
			"g" => {
				flags => "",
				description => "Miscellaneous information",
				},
			"h" => {
				flags => "",
				description => "Medium",
				},
			"k" => {
				flags => "R",
				description => "Form subheading",
				},
			"l" => {
				flags => "",
				description => "Language",
				},
			"m" => {
				flags => "R",
				description => "Medium of performance for music",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section",
				},
			"o" => {
				flags => "",
				description => "Arranged statement for music",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"r" => {
				flags => "",
				description => "Key for music",
				},
			"s" => {
				flags => "",
				description => "Version",
				},
			"t" => {
				flags => "",
				description => "Title",
				},
			"x" => {
				flags => "",
				description => "International Standard Serial Number",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"751" => {
		flags => "c",
		shortname => "",
		description => "Geographic Name/Area Name Entry",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "Primary Geographic/area entry",
				},
			"1" => {
				flags => "",
				description => "Secondary Geographic/area entry",
				},
			"2" => {
				flags => "",
				description => "Analytical geographic/area entry",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Geographic name or area element",
				},
			"b" => {
				flags => "",
				description => "Element following entry element",
				},
			},
		},
	"752" => {
		flags => "sbavmcR",
		shortname => "",
		description => "Hierarchical Place Name Access",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Country",
				},
			"b" => {
				flags => "",
				description => "State/province/territory",
				},
			"c" => {
				flags => "",
				description => "County/region/islands area",
				},
			"d" => {
				flags => "",
				description => "City",
				},
			},
		},
	"753" => {
		flags => "fR",
		shortname => "",
		description => "System Details Access to Computer Files",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Make and model of machine",
				},
			"b" => {
				flags => "",
				description => "Programming language",
				},
			"c" => {
				flags => "",
				description => "Operating system",
				},
			},
		},
	"754" => {
		flags => "vR",
		shortname => "",
		description => "Taxonomic Identification",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "Taxonomic name",
				},
			"c" => {
				flags => "R",
				description => "Taxonomic category",
				},
			"d" => {
				flags => "R",
				description => "Common or alternative name",
				},
			"x" => {
				flags => "R",
				description => "Non-public note",
				},
			"z" => {
				flags => "R",
				description => "Public note",
				},
			"2" => {
				flags => "",
				description => "Source of taxonomic identification",
				},
			},
		},
	"755" => {
		flags => "R",
		shortname => "",
		description => "Physical Characteristics Access",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		},
	"760" => {
		flags => "sfR",
		shortname => "",
		description => "Main Series Entry",
		ind1 => {
			"0" => {
				flags => "",
				description => "Print a note",
				},
			"1" => {
				flags => "",
				description => "Do not print a note",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Main entry heading",
				},
			"b" => {
				flags => "",
				description => "Edition",
				},
			"c" => {
				flags => "",
				description => "Qualifying information",
				},
			"d" => {
				flags => "",
				description => "Place/publisher/date of publication",
				},
			"g" => {
				flags => "R",
				description => "Relationship information",
				},
			"h" => {
				flags => "",
				description => "Physical description",
				},
			"i" => {
				flags => "",
				description => "Display text",
				},
			"k" => {
				flags => "R",
				description => "Series data (from 4XX or 8XX of record referred to)",
				},
			"m" => {
				flags => "",
				description => "Material-specific details",
				},
			"n" => {
				flags => "R",
				description => "Note",
				},
			"o" => {
				flags => "R",
				description => "Other item identifier",
				},
			"s" => {
				flags => "",
				description => "Uniform title",
				},
			"t" => {
				flags => "",
				description => "Title",
				},
			"w" => {
				flags => "R",
				description => "Record control number",
				},
			"x" => {
				flags => "",
				description => "International Standard Serial Number",
				},
			"y" => {
				flags => "",
				description => "CODEN designation",
				},
			"7" => {
				flags => "",
				description => "Control subfield",
				},
			},
		},
	"762" => {
		flags => "sfR",
		shortname => "",
		description => "Subseries Entry",
		ind1 => {
			"0" => {
				flags => "",
				description => "Print a note",
				},
			"1" => {
				flags => "",
				description => "Do not print a note",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Main entry heading",
				},
			"b" => {
				flags => "",
				description => "Edition",
				},
			"c" => {
				flags => "",
				description => "Qualifying information",
				},
			"d" => {
				flags => "",
				description => "Place/publisher/date of publication",
				},
			},
		},
	"765" => {
		flags => "sbvmcfR",
		shortname => "",
		description => "Original Language Entry",
		ind1 => {
			"0" => {
				flags => "",
				description => "Print a note",
				},
			"1" => {
				flags => "",
				description => "Do not print a note",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Main entry heading",
				},
			"b" => {
				flags => "",
				description => "Edition",
				},
			"c" => {
				flags => "",
				description => "Qualifying information",
				},
			"d" => {
				flags => "",
				description => "Place/publisher/date of publication",
				},
			"g" => {
				flags => "R",
				description => "Relationship information",
				},
			"h" => {
				flags => "",
				description => "Physical description",
				},
			"i" => {
				flags => "",
				description => "Display text",
				},
			"k" => {
				flags => "R",
				description => "Series data (from 4XX or 8XX of related record)",
				},
			"m" => {
				flags => "",
				description => "Material-specific details",
				},
			"n" => {
				flags => "R",
				description => "Note",
				},
			"o" => {
				flags => "R",
				description => "Other item identifier",
				},
			"r" => {
				flags => "R",
				description => "Report number (from 088 of related record)",
				},
			"s" => {
				flags => "",
				description => "Uniform title",
				},
			"t" => {
				flags => "",
				description => "Title",
				},
			"u" => {
				flags => "",
				description => "Standard Technical Report Number",
				},
			"w" => {
				flags => "R",
				description => "Record control number",
				},
			"x" => {
				flags => "",
				description => "International Standard Serial Number",
				},
			"y" => {
				flags => "",
				description => "CODEN designation",
				},
			"7" => {
				flags => "",
				description => "Control subfield",
				},
			},
		},
	"767" => {
		flags => "sbvmcfR",
		shortname => "",
		description => "Translation Entry",
		ind1 => {
			"0" => {
				flags => "",
				description => "Print a note",
				},
			"1" => {
				flags => "",
				description => "Do not print a note",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Main entry heading",
				},
			"b" => {
				flags => "",
				description => "Edition",
				},
			"c" => {
				flags => "",
				description => "Qualifying information",
				},
			"d" => {
				flags => "",
				description => "Place/publisher/date of publication",
				},
			"g" => {
				flags => "R",
				description => "Relationship information",
				},
			"h" => {
				flags => "",
				description => "Physical description",
				},
			"i" => {
				flags => "",
				description => "Display text",
				},
			"k" => {
				flags => "R",
				description => "Series data (from 4XX or 8XX of related record)",
				},
			"m" => {
				flags => "",
				description => "Material-specific details",
				},
			"n" => {
				flags => "R",
				description => "Note",
				},
			"o" => {
				flags => "R",
				description => "Other item identifier",
				},
			"r" => {
				flags => "R",
				description => "Report number (from 088 of related record)",
				},
			"s" => {
				flags => "",
				description => "Uniform title",
				},
			"t" => {
				flags => "",
				description => "Title",
				},
			"u" => {
				flags => "",
				description => "Standard Technical Report Number",
				},
			"w" => {
				flags => "R",
				description => "Record control number",
				},
			"x" => {
				flags => "",
				description => "International Standard Serial Number",
				},
			"y" => {
				flags => "",
				description => "CODEN designation",
				},
			"z" => {
				flags => "R",
				description => "International Standard Book Number",
				},
			"7" => {
				flags => "",
				description => "Control subfield",
				},
			},
		},
	"770" => {
		flags => "sbvmcfR",
		shortname => "",
		description => "Supplement/Special Issue Entry",
		ind1 => {
			"0" => {
				flags => "",
				description => "Print a note",
				},
			"1" => {
				flags => "",
				description => "Do not print a note",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Main entry heading",
				},
			"b" => {
				flags => "",
				description => "Edition",
				},
			"c" => {
				flags => "",
				description => "Qualifying information",
				},
			"d" => {
				flags => "",
				description => "Place/publisher/date of publication",
				},
			"g" => {
				flags => "R",
				description => "Relationship information",
				},
			"h" => {
				flags => "",
				description => "Physical description",
				},
			"i" => {
				flags => "",
				description => "Display text",
				},
			"k" => {
				flags => "R",
				description => "Series data for related item (from 4XX or 8XX of related record)",
				},
			"m" => {
				flags => "",
				description => "Material-specific details",
				},
			"n" => {
				flags => "R",
				description => "Note",
				},
			"o" => {
				flags => "R",
				description => "Other item identifier",
				},
			"r" => {
				flags => "R",
				description => "Report number (from 088 of related record)",
				},
			"s" => {
				flags => "",
				description => "Uniform title",
				},
			"t" => {
				flags => "",
				description => "Title",
				},
			"u" => {
				flags => "",
				description => "Standard Technical Report Number",
				},
			"w" => {
				flags => "R",
				description => "Record control number",
				},
			"x" => {
				flags => "",
				description => "International Standard Serial Number",
				},
			"y" => {
				flags => "",
				description => "CODEN designation",
				},
			"z" => {
				flags => "R",
				description => "International Standard Book Number",
				},
			"7" => {
				flags => "",
				description => "Control subfield",
				},
			},
		},
	"772" => {
		flags => "sbvmcfR",
		shortname => "",
		description => "Parent Record Entry",
		ind1 => {
			"0" => {
				flags => "",
				description => "Print a note",
				},
			"1" => {
				flags => "",
				description => "Do not print a note",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Main entry heading",
				},
			"b" => {
				flags => "",
				description => "Edition",
				},
			"c" => {
				flags => "",
				description => "Qualifying information",
				},
			"d" => {
				flags => "",
				description => "Place/publisher/date of publication",
				},
			"g" => {
				flags => "R",
				description => "Relationship information",
				},
			"h" => {
				flags => "",
				description => "Physical description",
				},
			"i" => {
				flags => "",
				description => "Display text",
				},
			"k" => {
				flags => "R",
				description => "Series data for related item (from 4XX or 8XX of related record)",
				},
			"m" => {
				flags => "",
				description => "Material-specific details",
				},
			"n" => {
				flags => "R",
				description => "Note",
				},
			"o" => {
				flags => "R",
				description => "Other item identifier",
				},
			"r" => {
				flags => "R",
				description => "Report number (from 088 of related record)",
				},
			"s" => {
				flags => "",
				description => "Uniform title",
				},
			"t" => {
				flags => "",
				description => "Title",
				},
			"u" => {
				flags => "",
				description => "Standard Technical Report Number",
				},
			"w" => {
				flags => "R",
				description => "Record control number",
				},
			"x" => {
				flags => "",
				description => "International Standard Serial Number",
				},
			"y" => {
				flags => "",
				description => "CODEN designation",
				},
			"z" => {
				flags => "R",
				description => "International Standard Book Number",
				},
			"7" => {
				flags => "",
				description => "Control subfield",
				},
			},
		},
	"773" => {
		flags => "R",
		shortname => "",
		description => "Host Item Entry",
		ind1 => {
			"0" => {
				flags => "",
				description => "Print a note",
				},
			"1" => {
				flags => "",
				description => "Do not print a note",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Main entry heading",
				},
			"b" => {
				flags => "",
				description => "Edition",
				},
			"c" => {
				flags => "",
				description => "Qualifying information",
				},
			"d" => {
				flags => "",
				description => "Place/publisher/date of publication",
				},
			"g" => {
				flags => "R",
				description => "Relationship information",
				},
			"h" => {
				flags => "",
				description => "Physical description",
				},
			"i" => {
				flags => "",
				description => "Display text",
				},
			"k" => {
				flags => "R",
				description => "Series data for related item (from 4XX or 8XX of related record)",
				},
			"m" => {
				flags => "",
				description => "Material-specific details",
				},
			"n" => {
				flags => "R",
				description => "Note",
				},
			"o" => {
				flags => "R",
				description => "Other item identifier",
				},
			"r" => {
				flags => "R",
				description => "Report number (from 088 of related record)",
				},
			"s" => {
				flags => "",
				description => "Uniform title",
				},
			"t" => {
				flags => "",
				description => "Title",
				},
			"u" => {
				flags => "",
				description => "Standard Technical Report Number",
				},
			"w" => {
				flags => "R",
				description => "Record control number",
				},
			"x" => {
				flags => "",
				description => "International Standard Serial Number",
				},
			"y" => {
				flags => "",
				description => "CODEN designation",
				},
			"z" => {
				flags => "R",
				description => "International Standard Book Number",
				},
			"7" => {
				flags => "",
				description => "Control subfield",
				},
			},
		},
	"775" => {
		flags => "sbvmcfR",
		shortname => "",
		description => "Other Editions Available Entry",
		ind1 => {
			"0" => {
				flags => "",
				description => "Print a note",
				},
			"1" => {
				flags => "",
				description => "Do not print a note",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Main entry heading",
				},
			"b" => {
				flags => "",
				description => "Edition",
				},
			"c" => {
				flags => "",
				description => "Qualifying information",
				},
			"d" => {
				flags => "",
				description => "Place/publisher/date of publication",
				},
			"e" => {
				flags => "",
				description => "Language code",
				},
			"g" => {
				flags => "R",
				description => "Relationship information",
				},
			"h" => {
				flags => "",
				description => "Physical description",
				},
			"i" => {
				flags => "",
				description => "Display text",
				},
			"k" => {
				flags => "R",
				description => "Series data for related item (from 4XX or 8XX of related record)",
				},
			"m" => {
				flags => "",
				description => "Material-specific details",
				},
			"n" => {
				flags => "R",
				description => "Note",
				},
			"o" => {
				flags => "R",
				description => "Other item identifier",
				},
			"r" => {
				flags => "R",
				description => "Report number (from 088 of related record)",
				},
			"s" => {
				flags => "",
				description => "Uniform title",
				},
			"t" => {
				flags => "",
				description => "Title",
				},
			"u" => {
				flags => "",
				description => "Standard Technical Report Number",
				},
			"w" => {
				flags => "R",
				description => "Record control number",
				},
			"x" => {
				flags => "",
				description => "International Standard Serial Number",
				},
			"y" => {
				flags => "",
				description => "CODEN designation",
				},
			"z" => {
				flags => "R",
				description => "International Standard Book Number",
				},
			"7" => {
				flags => "",
				description => "Control subfield",
				},
			},
		},
	"776" => {
		flags => "R",
		shortname => "",
		description => "Additional Physical Forms Available Entry",
		ind1 => {
			"0" => {
				flags => "",
				description => "Print a note",
				},
			"1" => {
				flags => "",
				description => "Do not print a note",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Main entry heading",
				},
			"b" => {
				flags => "",
				description => "Edition",
				},
			"c" => {
				flags => "",
				description => "Qualifying information",
				},
			"d" => {
				flags => "",
				description => "Place/publisher/date of publication",
				},
			"g" => {
				flags => "R",
				description => "Relationship information",
				},
			"h" => {
				flags => "",
				description => "Physical description",
				},
			"i" => {
				flags => "",
				description => "Display text",
				},
			"k" => {
				flags => "R",
				description => "Series data for related item (from 4XX or 8XX of related record)",
				},
			"m" => {
				flags => "",
				description => "Material-specific details",
				},
			"n" => {
				flags => "R",
				description => "Note",
				},
			"o" => {
				flags => "R",
				description => "Other item identifier",
				},
			"r" => {
				flags => "R",
				description => "Report number (from 088 of related record)",
				},
			"s" => {
				flags => "",
				description => "Uniform title",
				},
			"t" => {
				flags => "",
				description => "Title",
				},
			"u" => {
				flags => "",
				description => "Standard Technical Report Number",
				},
			"w" => {
				flags => "R",
				description => "Record control number",
				},
			"x" => {
				flags => "",
				description => "International Standard Serial Number",
				},
			"y" => {
				flags => "",
				description => "CODEN designation",
				},
			"z" => {
				flags => "R",
				description => "International Standard Book Number",
				},
			"7" => {
				flags => "",
				description => "Control subfield",
				},
			},
		},
	"777" => {
		flags => "sbvmcfR",
		shortname => "",
		description => "'Issued with' Entry",
		ind1 => {
			"0" => {
				flags => "",
				description => "Print a note",
				},
			"1" => {
				flags => "",
				description => "Do not print a note",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Main entry heading",
				},
			"b" => {
				flags => "",
				description => "Edition",
				},
			"c" => {
				flags => "",
				description => "Qualifying information",
				},
			"d" => {
				flags => "",
				description => "Place/publisher/date of publication",
				},
			"g" => {
				flags => "R",
				description => "Relationship information",
				},
			"h" => {
				flags => "",
				description => "Physical description",
				},
			"i" => {
				flags => "",
				description => "Display text",
				},
			"k" => {
				flags => "R",
				description => "Series data for related item (from 4XX or 8XX of related record)",
				},
			"m" => {
				flags => "",
				description => "Material-specific details",
				},
			"n" => {
				flags => "R",
				description => "Note",
				},
			"o" => {
				flags => "R",
				description => "Other item identifier",
				},
			"r" => {
				flags => "R",
				description => "Report number (from 088 of related record)",
				},
			"s" => {
				flags => "",
				description => "Uniform title",
				},
			"t" => {
				flags => "",
				description => "Title",
				},
			"u" => {
				flags => "",
				description => "Standard Technical Report Number",
				},
			"w" => {
				flags => "R",
				description => "Record control number",
				},
			"x" => {
				flags => "",
				description => "International Standard Serial Number",
				},
			"y" => {
				flags => "",
				description => "CODEN designation",
				},
			"z" => {
				flags => "R",
				description => "International Standard Book Number",
				},
			"7" => {
				flags => "",
				description => "Control subfield",
				},
			},
		},
	"780" => {
		flags => "sbvmcfR",
		shortname => "",
		description => "Preceding Entry",
		ind1 => {
			"0" => {
				flags => "",
				description => "Print a note",
				},
			"1" => {
				flags => "",
				description => "Do not print a note",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "Continues",
				},
			"1" => {
				flags => "",
				description => "Continues in part",
				},
			"2" => {
				flags => "",
				description => "Supersedes",
				},
			"3" => {
				flags => "",
				description => "Supersedes in part",
				},
			"4" => {
				flags => "",
				description => "Merger of",
				},
			"5" => {
				flags => "",
				description => "Absorbed",
				},
			"6" => {
				flags => "",
				description => "Absorbed in part",
				},
			"7" => {
				flags => "",
				description => "Separated from",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Main entry heading",
				},
			"b" => {
				flags => "",
				description => "Edition",
				},
			"c" => {
				flags => "",
				description => "Qualifying information",
				},
			"d" => {
				flags => "",
				description => "Place/publisher/date of publication",
				},
			"g" => {
				flags => "R",
				description => "Relationship information",
				},
			"h" => {
				flags => "",
				description => "Physical description",
				},
			"i" => {
				flags => "",
				description => "Display text",
				},
			"k" => {
				flags => "R",
				description => "Series data for related item (from 4XX or 8XX of related record)",
				},
			"m" => {
				flags => "",
				description => "Material-specific details",
				},
			"n" => {
				flags => "R",
				description => "Note",
				},
			"o" => {
				flags => "R",
				description => "Other item identifier",
				},
			"r" => {
				flags => "R",
				description => "Report number (from 088 of related record)",
				},
			"s" => {
				flags => "",
				description => "Uniform title",
				},
			"t" => {
				flags => "",
				description => "Title",
				},
			"u" => {
				flags => "",
				description => "Standard Technical Report Number",
				},
			"w" => {
				flags => "R",
				description => "Record control number",
				},
			"x" => {
				flags => "",
				description => "International Standard Serial Number",
				},
			"y" => {
				flags => "",
				description => "CODEN designation",
				},
			"z" => {
				flags => "R",
				description => "International Standard Book Number",
				},
			"7" => {
				flags => "",
				description => "Control subfield",
				},
			},
		},
	"785" => {
		flags => "sbvmcfR",
		shortname => "",
		description => "Succeeding Entry",
		ind1 => {
			"0" => {
				flags => "",
				description => "Print a note",
				},
			"1" => {
				flags => "",
				description => "Do not print a note",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "Continued by",
				},
			"1" => {
				flags => "",
				description => "Continued in part by",
				},
			"2" => {
				flags => "",
				description => "Superseded by",
				},
			"3" => {
				flags => "",
				description => "Superseded in part by",
				},
			"4" => {
				flags => "",
				description => "Absorbed by",
				},
			"5" => {
				flags => "",
				description => "Absorbed in part by",
				},
			"6" => {
				flags => "",
				description => "Split into - and -",
				},
			"7" => {
				flags => "",
				description => "Merged with - to form",
				},
			"8" => {
				flags => "",
				description => "Resumed as",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Main entry heading",
				},
			"b" => {
				flags => "",
				description => "Edition",
				},
			"c" => {
				flags => "",
				description => "Qualifying information",
				},
			"d" => {
				flags => "",
				description => "Place/publisher/date of publication",
				},
			"g" => {
				flags => "R",
				description => "Relationship information",
				},
			"h" => {
				flags => "",
				description => "Physical description",
				},
			"i" => {
				flags => "",
				description => "Display text",
				},
			"k" => {
				flags => "R",
				description => "Series data for related item (from 4XX or 8XX of related record)",
				},
			"m" => {
				flags => "",
				description => "Material-specific details",
				},
			"n" => {
				flags => "R",
				description => "Note",
				},
			"o" => {
				flags => "R",
				description => "Other item identifier",
				},
			"r" => {
				flags => "R",
				description => "Report number (from 088 of related record)",
				},
			"s" => {
				flags => "",
				description => "Uniform title",
				},
			"t" => {
				flags => "",
				description => "Title",
				},
			"u" => {
				flags => "",
				description => "Standard Technical Report Number",
				},
			"w" => {
				flags => "R",
				description => "Record control number",
				},
			"x" => {
				flags => "",
				description => "International Standard Serial Number",
				},
			"y" => {
				flags => "",
				description => "CODEN designation",
				},
			"z" => {
				flags => "R",
				description => "International Standard Book Number",
				},
			"7" => {
				flags => "",
				description => "Control subfield",
				},
			},
		},
	"787" => {
		flags => "sbvmcfR",
		shortname => "",
		description => "Non-specific Relationship Entry",
		ind1 => {
			"0" => {
				flags => "",
				description => "Print a note",
				},
			"1" => {
				flags => "",
				description => "Do not print a note",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Main entry heading",
				},
			"b" => {
				flags => "",
				description => "Edition",
				},
			"c" => {
				flags => "",
				description => "Qualifying information",
				},
			"d" => {
				flags => "",
				description => "Place/publisher/date of publication",
				},
			"g" => {
				flags => "R",
				description => "Relationship information",
				},
			"h" => {
				flags => "",
				description => "Physical description",
				},
			"i" => {
				flags => "",
				description => "Display text",
				},
			"k" => {
				flags => "R",
				description => "Series data for related item (from 4XX or 8XX of related record)",
				},
			"m" => {
				flags => "",
				description => "Material-specific details",
				},
			"n" => {
				flags => "R",
				description => "Note",
				},
			"o" => {
				flags => "R",
				description => "Other item identifier",
				},
			"r" => {
				flags => "R",
				description => "Report number (from 088 of related record)",
				},
			"s" => {
				flags => "",
				description => "Uniform title",
				},
			"t" => {
				flags => "",
				description => "Title",
				},
			"u" => {
				flags => "",
				description => "Standard Technical Report Number",
				},
			"w" => {
				flags => "R",
				description => "Record control number",
				},
			"x" => {
				flags => "",
				description => "International Standard Serial Number",
				},
			"y" => {
				flags => "",
				description => "CODEN designation",
				},
			"z" => {
				flags => "R",
				description => "International Standard Book Number",
				},
			"7" => {
				flags => "",
				description => "Control subfield",
				},
			},
		},
	"800" => {
		flags => "sbvmcfR",
		shortname => "",
		description => "Series Added Entry - Personal Name/Title",
		ind1 => {
			"0" => {
				flags => "",
				description => "Forename",
				},
			"1" => {
				flags => "",
				description => "Single surname",
				},
			"2" => {
				flags => "",
				description => "Multiple surname",
				},
			"3" => {
				flags => "",
				description => "Name of family",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Personal name",
				},
			"b" => {
				flags => "",
				description => "Numeration",
				},
			"c" => {
				flags => "R",
				description => "Titles and other words associated with name",
				},
			"d" => {
				flags => "",
				description => "Dates associated with name",
				},
			"e" => {
				flags => "R",
				description => "Relator term",
				},
			"f" => {
				flags => "",
				description => "Date of work",
				},
			"g" => {
				flags => "",
				description => "Miscellaneous information",
				},
			"h" => {
				flags => "",
				description => "Medium",
				},
			"j" => {
				flags => "R",
				description => "Attribution qualifier",
				},
			"k" => {
				flags => "R",
				description => "Form subheading",
				},
			"l" => {
				flags => "",
				description => "Language of work",
				},
			"m" => {
				flags => "R",
				description => "Medium of performance for music",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section of",
				},
			"o" => {
				flags => "",
				description => "Arranged statement for music",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"q" => {
				flags => "",
				description => "Fuller form of name",
				},
			"r" => {
				flags => "",
				description => "Key for music",
				},
			"s" => {
				flags => "",
				description => "Version",
				},
			"t" => {
				flags => "",
				description => "Title",
				},
			"u" => {
				flags => "",
				description => "Affiliation",
				},
			"v" => {
				flags => "",
				description => "Volume/sequential designation",
				},
			"4" => {
				flags => "R",
				description => "Relator code",
				},
			},
		},
	"810" => {
		flags => "sbvmcfR",
		shortname => "",
		description => "Series Added Entry - Corporate Name/Title",
		ind1 => {
			"0" => {
				flags => "",
				description => "Surname (inverted)",
				},
			"1" => {
				flags => "",
				description => "Place or place and name",
				},
			"2" => {
				flags => "",
				description => "Name (direct order)",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Corporate name or jurisdiction name as entry element",
				},
			"b" => {
				flags => "R",
				description => "Subordinate unit",
				},
			"c" => {
				flags => "",
				description => "Location of meeting",
				},
			"d" => {
				flags => "",
				description => "Date of meeting or treaty signing",
				},
			"e" => {
				flags => "R",
				description => "Relator term",
				},
			"f" => {
				flags => "",
				description => "Date of work",
				},
			"g" => {
				flags => "",
				description => "Miscellaneous information",
				},
			"h" => {
				flags => "",
				description => "Medium",
				},
			"j" => {
				flags => "R",
				description => "Attribution qualifier",
				},
			"k" => {
				flags => "R",
				description => "Form subheading",
				},
			"l" => {
				flags => "",
				description => "Language of work",
				},
			"m" => {
				flags => "R",
				description => "Medium of performance for music",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section of",
				},
			"o" => {
				flags => "",
				description => "Arranged statement for music",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"q" => {
				flags => "",
				description => "Fuller form of name",
				},
			"r" => {
				flags => "",
				description => "Key for music",
				},
			"s" => {
				flags => "",
				description => "Version",
				},
			"t" => {
				flags => "",
				description => "Title",
				},
			"u" => {
				flags => "",
				description => "Affiliation",
				},
			"v" => {
				flags => "",
				description => "Volume/sequential designation",
				},
			"4" => {
				flags => "R",
				description => "Relator code",
				},
			},
		},
	"811" => {
		flags => "sbvmcfR",
		shortname => "",
		description => "Series Added Entry - Conference or Meeting/Title",
		ind1 => {
			"0" => {
				flags => "",
				description => "Surname (inverted)",
				},
			"1" => {
				flags => "",
				description => "Place or place and name",
				},
			"2" => {
				flags => "",
				description => "Name (direct order)",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Meeting name or jurisdiction name as entry element",
				},
			"c" => {
				flags => "",
				description => "Location of meeting",
				},
			"d" => {
				flags => "",
				description => "Date of meeting",
				},
			"e" => {
				flags => "R",
				description => "Subordinate unite",
				},
			"f" => {
				flags => "",
				description => "Date of work",
				},
			"g" => {
				flags => "",
				description => "Miscellaneous information",
				},
			"h" => {
				flags => "",
				description => "Medium",
				},
			"k" => {
				flags => "R",
				description => "Form subheading",
				},
			"l" => {
				flags => "",
				description => "Language",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"q" => {
				flags => "",
				description => "Name of meeting following jurisdiction name entry element",
				},
			"s" => {
				flags => "",
				description => "Version",
				},
			"t" => {
				flags => "",
				description => "Title",
				},
			"u" => {
				flags => "",
				description => "Affiliation",
				},
			"v" => {
				flags => "",
				description => "Volume/sequential designation",
				},
			"4" => {
				flags => "R",
				description => "Relator code",
				},
			},
		},
	"830" => {
		flags => "sbvmcfR",
		shortname => "",
		description => "Series Added Entry - Title/Uniform Title",
		ind1 => {
			"0" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"1" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"2" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"3" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"4" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"5" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"6" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"7" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"8" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"9" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Uniform title",
				},
			"d" => {
				flags => "R",
				description => "Date of treaty signing",
				},
			"f" => {
				flags => "",
				description => "Date of work",
				},
			"g" => {
				flags => "",
				description => "Miscellaneous information",
				},
			"h" => {
				flags => "",
				description => "Medium",
				},
			"k" => {
				flags => "R",
				description => "Form subheading",
				},
			"l" => {
				flags => "",
				description => "Language",
				},
			"m" => {
				flags => "R",
				description => "Medium of performance for music",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section",
				},
			"o" => {
				flags => "",
				description => "Arranged statement for music",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"r" => {
				flags => "",
				description => "Key for music",
				},
			"s" => {
				flags => "",
				description => "Version",
				},
			"t" => {
				flags => "",
				description => "Title",
				},
			"v" => {
				flags => "",
				description => "Volume/sequential designation",
				},
			},
		},
	"850" => {
		flags => "R",
		shortname => "",
		description => "Holding Institution",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "Holding institution",
				},
			"b" => {
				flags => "",
				description => "Holdings (OBSOLETE)",
				},
			"d" => {
				flags => "",
				description => "Inclusive dates (OBSOLETE)",
				},
			"e" => {
				flags => "",
				description => "Retention statement (OBSOLETE)",
				},
			},
		},
	"851" => {
		flags => "avR",
		shortname => "",
		description => "Location",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Custodian",
				},
			"b" => {
				flags => "",
				description => "Institutional division",
				},
			"c" => {
				flags => "",
				description => "Postal address",
				},
			"d" => {
				flags => "",
				description => "Country",
				},
			"e" => {
				flags => "",
				description => "Location of units",
				},
			"f" => {
				flags => "",
				description => "Item number",
				},
			"g" => {
				flags => "",
				description => "Repository location code",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"852" => {
		flags => "sbvmcfR",
		shortname => "",
		description => "Location",
		ind1 => {
			"#" => {
				flags => "",
				description => "No information provided",
				},
			"0" => {
				flags => "",
				description => "Library of Congress classification",
				},
			"1" => {
				flags => "",
				description => "Dewey Decimal classification",
				},
			"2" => {
				flags => "",
				description => "National Library of Medicine classification",
				},
			"3" => {
				flags => "",
				description => "Superintendent of Documents classification",
				},
			"4" => {
				flags => "",
				description => "Shelving control number",
				},
			"5" => {
				flags => "",
				description => "Title",
				},
			"6" => {
				flags => "",
				description => "Shelved separately",
				},
			"7" => {
				flags => "",
				description => "Source specified in subfield \$2",
				},
			"8" => {
				flags => "",
				description => "Other scheme ",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "No information provided",
				},
			"0" => {
				flags => "",
				description => "Not enumeration",
				},
			"1" => {
				flags => "",
				description => "Primary enumeration",
				},
			"2" => {
				flags => "",
				description => "Alternative enumeration",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Location",
				},
			"b" => {
				flags => "R",
				description => "Sublocation or collection",
				},
			"c" => {
				flags => "R",
				description => "Shelving location",
				},
			"e" => {
				flags => "R",
				description => "Address",
				},
			"f" => {
				flags => "R",
				description => "Coded location qualifier",
				},
			"g" => {
				flags => "R",
				description => "Non-coded location qualifier",
				},
			"h" => {
				flags => "",
				description => "Classification part",
				},
			"i" => {
				flags => "R",
				description => "Item part",
				},
			"j" => {
				flags => "",
				description => "Shelving control number",
				},
			"k" => {
				flags => "",
				description => "Call number prefix",
				},
			"l" => {
				flags => "",
				description => "Shelving form of title",
				},
			"m" => {
				flags => "",
				description => "Call number suffix",
				},
			"n" => {
				flags => "",
				description => "Country code",
				},
			"p" => {
				flags => "",
				description => "Piece designation",
				},
			"q" => {
				flags => "",
				description => "Piece physical condition",
				},
			"s" => {
				flags => "R",
				description => "Copyright article-fee code",
				},
			"t" => {
				flags => "",
				description => "Copy number",
				},
			"x" => {
				flags => "R",
				description => "Non-public note",
				},
			"z" => {
				flags => "R",
				description => "Public note",
				},
			"2" => {
				flags => "",
				description => "Source of classification or shelving scheme",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"856" => {
		flags => "sbvmcfR",
		shortname => "",
		description => "Electronic location and access",
		ind1 => {
			"#" => {
				flags => "",
				description => "No information provided",
				},
			"0" => {
				flags => "",
				description => "Email",
				},
			"1" => {
				flags => "",
				description => "FTP",
				},
			"2" => {
				flags => "",
				description => "Remote login (Telnet)",
				},
			"3" => {
				flags => "",
				description => "Dial-up",
				},
			"4" => {
				flags => "",
				description => "HTTP",
				},
			"7" => {
				flags => "",
				description => "Method specified in subfield \$2",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "No information provided",
				},
			"0" => {
				flags => "",
				description => "Resource",
				},
			"1" => {
				flags => "",
				description => "Version of resource",
				},
			"2" => {
				flags => "",
				description => "Related resource",
				},
			"8" => {
				flags => "",
				description => "No display constant genereated",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "Host name",
				},
			"b" => {
				flags => "R",
				description => "Access number",
				},
			"c" => {
				flags => "R",
				description => "Compression information",
				},
			"d" => {
				flags => "R",
				description => "Path",
				},
			"f" => {
				flags => "R",
				description => "Electronic name",
				},
			"h" => {
				flags => "",
				description => "Processor of request",
				},
			"i" => {
				flags => "R",
				description => "Instruction",
				},
			"j" => {
				flags => "",
				description => "Bits per second",
				},
			"k" => {
				flags => "",
				description => "Password",
				},
			"l" => {
				flags => "",
				description => "Logon",
				},
			"m" => {
				flags => "R",
				description => "Contact for assistance",
				},
			"n" => {
				flags => "",
				description => "Name of location of host",
				},
			"o" => {
				flags => "",
				description => "Operating system",
				},
			"p" => {
				flags => "",
				description => "Port",
				},
			"q" => {
				flags => "",
				description => "Electronic format type",
				},
			"r" => {
				flags => "",
				description => "Settings",
				},
			"s" => {
				flags => "R",
				description => "File size",
				},
			"t" => {
				flags => "R",
				description => "Terminal emulation",
				},
			"u" => {
				flags => "R",
				description => "Uniform Resource Identifier (URI)",
				},
			"v" => {
				flags => "R",
				description => "Hours access method available",
				},
			"w" => {
				flags => "R",
				description => "Record control number",
				},
			"x" => {
				flags => "R",
				description => "Non-public note",
				},
			"y" => {
				flags => "R",
				description => "Link text",
				},
			"z" => {
				flags => "R",
				description => "Public note",
				},
			"2" => {
				flags => "",
				description => "Access method",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"886" => {
		flags => "R",
		shortname => "",
		description => "Foreign MARC Information field",
		ind1 => {
			"0" => {
				flags => "",
				description => "Leader",
				},
			"1" => {
				flags => "",
				description => "Variable control fields (002-009)",
				},
			"2" => {
				flags => "",
				description => "Variable data fields (010-999)",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"2" => {
				flags => "",
				description => "Source of data",
				},
			"a" => {
				flags => "",
				description => "Tag of the foreign MARC field",
				},
			"b" => {
				flags => "",
				description => "Content of the foreign MARC field",
				},
			},
		},
	"900" => {
		flags => "R",
		shortname => "",
		description => "Personal Name Equivalence or Cross-reference",
		ind1 => {
			"0" => {
				flags => "",
				description => "Forename",
				},
			"1" => {
				flags => "",
				description => "Single surname",
				},
			"2" => {
				flags => "",
				description => "Multiple surname",
				},
			"3" => {
				flags => "",
				description => "Name of family",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Name (surnames and forenames)",
				},
			"b" => {
				flags => "",
				description => "Numeration (Roman numerals which may follow a forename)",
				},
			"c" => {
				flags => "R",
				description => "Titles and other words associated with name",
				},
			"d" => {
				flags => "",
				description => "Dates associated with name",
				},
			"e" => {
				flags => "R",
				description => "Relator",
				},
			"f" => {
				flags => "",
				description => "Date of work",
				},
			"g" => {
				flags => "",
				description => "Miscellaneous information",
				},
			"h" => {
				flags => "",
				description => "Medium",
				},
			"k" => {
				flags => "R",
				description => "Form subheading",
				},
			"l" => {
				flags => "",
				description => "Language",
				},
			"m" => {
				flags => "R",
				description => "Medium of performance for music",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section",
				},
			"o" => {
				flags => "",
				description => "Arranged statement for music",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"q" => {
				flags => "",
				description => "Fuller form of name",
				},
			"r" => {
				flags => "",
				description => "Key for music",
				},
			"s" => {
				flags => "",
				description => "Version",
				},
			"t" => {
				flags => "",
				description => "Title",
				},
			"u" => {
				flags => "",
				description => "Affiliation",
				},
			"x" => {
				flags => "",
				description => "International Standard Serial Number",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			"4" => {
				flags => "R",
				description => "Relator code",
				},
			},
		},
	"910" => {
		flags => "R",
		shortname => "",
		description => "Corporate Name Equivalence Cross-reference or History note",
		ind1 => {
			"0" => {
				flags => "",
				description => "Surname (inverted)",
				},
			"1" => {
				flags => "",
				description => "Place or place and name",
				},
			"2" => {
				flags => "",
				description => "Name (direct order)",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Name",
				},
			"b" => {
				flags => "R",
				description => "Subheading",
				},
			"c" => {
				flags => "",
				description => "Location of conference/meeting/treaty",
				},
			"d" => {
				flags => "R",
				description => "Date of conference/meeting/treaty",
				},
			"e" => {
				flags => "R",
				description => "Relator",
				},
			"f" => {
				flags => "",
				description => "Date of work",
				},
			"g" => {
				flags => "",
				description => "Miscellaneous information",
				},
			"h" => {
				flags => "",
				description => "Medium",
				},
			"k" => {
				flags => "R",
				description => "Form subheading",
				},
			"l" => {
				flags => "",
				description => "Language",
				},
			"m" => {
				flags => "R",
				description => "Medium of performance for music",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section",
				},
			"o" => {
				flags => "",
				description => "Arranged statement for music",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"q" => {
				flags => "",
				description => "Fuller form of name",
				},
			"r" => {
				flags => "",
				description => "Key for music",
				},
			"s" => {
				flags => "",
				description => "Version",
				},
			"t" => {
				flags => "",
				description => "Title",
				},
			"u" => {
				flags => "",
				description => "Affiliation",
				},
			"x" => {
				flags => "",
				description => "International Standard Serial Number",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			"4" => {
				flags => "R",
				description => "Relator code",
				},
			},
		},
	"911" => {
		flags => "R",
		shortname => "",
		description => "Conference or Meeting Name Equivalence Cross-reference or History note",
		ind1 => {
			"0" => {
				flags => "",
				description => "Surname (inverted)",
				},
			"1" => {
				flags => "",
				description => "Place or place and name",
				},
			"2" => {
				flags => "",
				description => "Name (direct order)",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Name of meeting or place element",
				},
			"c" => {
				flags => "",
				description => "Location of conference/meeting/treaty",
				},
			"d" => {
				flags => "R",
				description => "Date of conference/meeting/treaty",
				},
			"e" => {
				flags => "R",
				description => "Subordinate unit in name",
				},
			"f" => {
				flags => "",
				description => "Date of work",
				},
			"g" => {
				flags => "",
				description => "Miscellaneous information",
				},
			"h" => {
				flags => "",
				description => "Medium",
				},
			"k" => {
				flags => "R",
				description => "Form subheading",
				},
			"l" => {
				flags => "",
				description => "Language",
				},
			"m" => {
				flags => "R",
				description => "Medium of performance for music",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section",
				},
			"o" => {
				flags => "",
				description => "Arranged statement for music",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"q" => {
				flags => "",
				description => "Name of meeting following place element",
				},
			"r" => {
				flags => "",
				description => "Key for music",
				},
			"s" => {
				flags => "",
				description => "Version",
				},
			"t" => {
				flags => "",
				description => "Title",
				},
			"u" => {
				flags => "",
				description => "Affiliation",
				},
			"x" => {
				flags => "",
				description => "International Standard Serial Number",
				},
			"z" => {
				flags => "",
				description => "Text of a history note",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			"4" => {
				flags => "R",
				description => "Relator code",
				},
			},
		},
	"930" => {
		flags => "R",
		shortname => "",
		description => "Uniform TitleHeading Equivalence or Cross-reference",
		ind1 => {
			"0" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"1" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"2" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"3" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"4" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"5" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"6" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"7" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"8" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"9" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Uniform title heading",
				},
			"t" => {
				flags => "",
				description => "Title (title of a work usid in conjunction with a uniform title heading)",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"l" => {
				flags => "",
				description => "Language",
				},
			"s" => {
				flags => "",
				description => "Version",
				},
			"k" => {
				flags => "R",
				description => "Form subheading",
				},
			"f" => {
				flags => "",
				description => "Date of work",
				},
			"g" => {
				flags => "",
				description => "Miscellaneous information",
				},
			"d" => {
				flags => "R",
				description => "Date of treaty",
				},
			"m" => {
				flags => "R",
				description => "Medium of performance for music",
				},
			"o" => {
				flags => "",
				description => "Arranged statement for music",
				},
			"r" => {
				flags => "",
				description => "Key for music",
				},
			"h" => {
				flags => "",
				description => "Medium",
				},
			"x" => {
				flags => "",
				description => "International Standard Serial Number",
				},
			"3" => {
				flags => "",
				description => "Materials specified",
				},
			},
		},
	"940" => {
		flags => "R",
		shortname => "",
		description => "Uniform Title Equivalence or Cross-reference",
		ind1 => {
			"0" => {
				flags => "",
				description => "Local usage only; NO title added entry",
				},
			"1" => {
				flags => "",
				description => "Conventional uniform title; NO title added entry",
				},
			"2" => {
				flags => "",
				description => "Local usage only; title added entry",
				},
			"3" => {
				flags => "",
				description => "Conventional uniform title; title added entry",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"1" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"2" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"3" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"4" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"5" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"6" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"7" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"8" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"9" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Uniform title",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"l" => {
				flags => "",
				description => "Language",
				},
			"s" => {
				flags => "",
				description => "Version",
				},
			"k" => {
				flags => "R",
				description => "Form subheading",
				},
			"f" => {
				flags => "",
				description => "Date of work",
				},
			"g" => {
				flags => "",
				description => "Miscellaneous information",
				},
			"d" => {
				flags => "R",
				description => "Date of treaty",
				},
			"m" => {
				flags => "R",
				description => "Medium of performance for music",
				},
			"o" => {
				flags => "",
				description => "Arranged statement for music",
				},
			"r" => {
				flags => "",
				description => "Key for music",
				},
			"h" => {
				flags => "",
				description => "Medium",
				},
			"x" => {
				flags => "",
				description => "International Standard Serial Number",
				},
			},
		},
	"941" => {
		flags => "bavmcfR",
		shortname => "",
		description => "Romanized Title Equivalence or Cross-reference",
		ind1 => {
			"0" => {
				flags => "",
				description => "No title added entry",
				},
			"1" => {
				flags => "",
				description => "Title added entry",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"1" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"2" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"3" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"4" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"5" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"6" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"7" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"8" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"9" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Romanized title",
				},
			"h" => {
				flags => "",
				description => "General material designation",
				},
			},
		},
	"943" => {
		flags => "bavmcfR",
		shortname => "",
		description => "Collective Title Equivalence or Cross-reference",
		ind1 => {
			"0" => {
				flags => "",
				description => "Works",
				},
			"1" => {
				flags => "",
				description => "Selected works (complete works together)",
				},
			"2" => {
				flags => "",
				description => "Selections (extracts)",
				},
			"3" => {
				flags => "",
				description => "Other collective titles",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"1" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"2" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"3" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"4" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"5" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"6" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"7" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"8" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"9" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Collective title",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"l" => {
				flags => "",
				description => "Language",
				},
			"s" => {
				flags => "",
				description => "Version",
				},
			"k" => {
				flags => "R",
				description => "Form subheading",
				},
			"f" => {
				flags => "",
				description => "Date of work",
				},
			"g" => {
				flags => "",
				description => "Miscellaneous information",
				},
			"d" => {
				flags => "R",
				description => "Date of treaty",
				},
			"m" => {
				flags => "R",
				description => "Medium of performance for music",
				},
			"o" => {
				flags => "",
				description => "Arranged statement for music",
				},
			"r" => {
				flags => "",
				description => "Key for music",
				},
			"h" => {
				flags => "",
				description => "Medium",
				},
			},
		},
	"945" => {
		flags => "R",
		shortname => "",
		description => "Title Equivalence or Cross-reference",
		ind1 => {
			"0" => {
				flags => "",
				description => "No title added entry",
				},
			"1" => {
				flags => "",
				description => "Title added entry",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"1" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"2" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"3" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"4" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"5" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"6" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"7" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"8" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"9" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Short title/title proper",
				},
			"b" => {
				flags => "",
				description => "Remainder of title",
				},
			"c" => {
				flags => "",
				description => "Remainder of title are transcription/statement of responsibility",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"h" => {
				flags => "",
				description => "General material designation",
				},
			"f" => {
				flags => "",
				description => "Inclusive dates",
				},
			"g" => {
				flags => "",
				description => "Bulk dates",
				},
			"k" => {
				flags => "R",
				description => "Form",
				},
			"s" => {
				flags => "",
				description => "Version",
				},
			},
		},
	"951" => {
		flags => "cR",
		shortname => "",
		description => "Geographic Name/Area Name Equivalence or Cross-reference",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"0" => {
				flags => "",
				description => "Primary geographic/area entry",
				},
			"1" => {
				flags => "",
				description => "Secondary geographic/area entry",
				},
			"2" => {
				flags => "",
				description => "Analytical geographic/area entry",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Geographic name or area element",
				},
			"b" => {
				flags => "",
				description => "Element following entry element",
				},
			},
		},
	"952" => {
		flags => "R",
		shortname => "",
		description => "Equivalence or Cross-reference to Hierarchical Place",
		ind1 => {
			"#" => {
				flags => "",
				description => "Unused",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Country",
				},
			"b" => {
				flags => "",
				description => "State/province/territory",
				},
			"c" => {
				flags => "",
				description => "County/region/islands area",
				},
			"d" => {
				flags => "",
				description => "City",
				},
			},
		},
	"980" => {
		flags => "sbvmcfR",
		shortname => "",
		description => "Series (Personal Name) Equivalence or Cross-reference",
		ind1 => {
			"0" => {
				flags => "",
				description => "Forename",
				},
			"1" => {
				flags => "",
				description => "Single surname",
				},
			"2" => {
				flags => "",
				description => "Multiple surname",
				},
			"3" => {
				flags => "",
				description => "Name of family",
				},
			},
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			"0" => {
				flags => "",
				description => "Main entry for series is not represented by a pronoun (OBSOLETE)",
				},
			"1" => {
				flags => "",
				description => "Main entry for series is represented by a pronoun (OBSOLETE)",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Name (surname and forenames)",
				},
			"b" => {
				flags => "",
				description => "Numeration (Roman numerals which may follow a forename)",
				},
			"c" => {
				flags => "R",
				description => "Titles and other words associated with the name",
				},
			"d" => {
				flags => "",
				description => "Dates assosciated with the name",
				},
			"e" => {
				flags => "R",
				description => "Relator",
				},
			"t" => {
				flags => "",
				description => "Title of series",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"l" => {
				flags => "",
				description => "Language",
				},
			"k" => {
				flags => "R",
				description => "Form subheading",
				},
			"f" => {
				flags => "",
				description => "Date of work",
				},
			"g" => {
				flags => "",
				description => "Miscellaneous information",
				},
			"h" => {
				flags => "",
				description => "General material designation",
				},
			"q" => {
				flags => "",
				description => "Fuller form of name",
				},
			"v" => {
				flags => "",
				description => "Volume or number (after the title)",
				},
			"x" => {
				flags => "",
				description => "International Standard Serial Number",
				},
			"4" => {
				flags => "R",
				description => "Relator code",
				},
			},
		},
	"981" => {
		flags => "sbvmcfR",
		shortname => "",
		description => "Series (Corporate Name) Equivalence or Cross-reference",
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			"0" => {
				flags => "",
				description => "Main entry for series is not represented by a pronoun (OBSOLETE)",
				},
			"1" => {
				flags => "",
				description => "Main entry for series is represented by a pronoun (OBSOLETE)",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Name",
				},
			"b" => {
				flags => "R",
				description => "Subheading",
				},
			"c" => {
				flags => "",
				description => "Location of conference or meeting",
				},
			"d" => {
				flags => "R",
				description => "Date of conference or meeting",
				},
			"e" => {
				flags => "R",
				description => "Relator",
				},
			"t" => {
				flags => "",
				description => "Title of series",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"l" => {
				flags => "",
				description => "Language",
				},
			"k" => {
				flags => "R",
				description => "Form subheading",
				},
			"f" => {
				flags => "",
				description => "Date of work",
				},
			"g" => {
				flags => "",
				description => "Miscellaneous information",
				},
			"h" => {
				flags => "",
				description => "General material designation",
				},
			"q" => {
				flags => "",
				description => "Fuller form of name",
				},
			"v" => {
				flags => "",
				description => "Volume or number (after the title)",
				},
			"x" => {
				flags => "",
				description => "International Standard Serial Number",
				},
			"4" => {
				flags => "R",
				description => "Relator code",
				},
			},
		},
	"982" => {
		flags => "sbvmcfR",
		shortname => "",
		description => "Series (Conference or Meeting Name) Equivalence or Cross-reference",
		ind2 => {
			"#" => {
				flags => "",
				description => "Blank",
				},
			"0" => {
				flags => "",
				description => "Main entry for series is not represented by a pronoun (OBSOLETE)",
				},
			"1" => {
				flags => "",
				description => "Main entry for series is represented by a pronoun (OBSOLETE)",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Name of meeting or place element",
				},
			"b" => {
				flags => "R",
				description => "Subheading",
				},
			"c" => {
				flags => "",
				description => "Location of conference or meeting",
				},
			"d" => {
				flags => "R",
				description => "Date of conference or meeting",
				},
			"e" => {
				flags => "R",
				description => "Relator",
				},
			"t" => {
				flags => "",
				description => "Title of series",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"q" => {
				flags => "",
				description => "Name of meeting following place element",
				},
			"l" => {
				flags => "",
				description => "Language",
				},
			"k" => {
				flags => "R",
				description => "Form subheading",
				},
			"f" => {
				flags => "",
				description => "Date of work",
				},
			"g" => {
				flags => "",
				description => "Miscellaneous information",
				},
			"h" => {
				flags => "",
				description => "General material designation",
				},
			"q" => {
				flags => "",
				description => "Fuller form of name",
				},
			"v" => {
				flags => "",
				description => "Volume or number (after the title)",
				},
			"x" => {
				flags => "",
				description => "International Standard Serial Number",
				},
			"4" => {
				flags => "R",
				description => "Relator code",
				},
			},
		},
	"983" => {
		flags => "sbvmcfR",
		shortname => "",
		description => "Series (Title/Uniform title) Equivalence or Cross-reference",
		ind2 => {
			"0" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"1" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"2" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"3" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"4" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"5" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"6" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"7" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"8" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			"9" => {
				flags => "",
				description => "Number of characters to ignore in filing",
				},
			},
		subfield => {
			"a" => {
				flags => "",
				description => "Title/Uniform title",
				},
			"b" => {
				flags => "R",
				description => "Subheading",
				},
			"c" => {
				flags => "",
				description => "Location of conference or meeting",
				},
			"d" => {
				flags => "R",
				description => "Date of conference or meeting",
				},
			"e" => {
				flags => "R",
				description => "Relator",
				},
			"t" => {
				flags => "",
				description => "Title of series",
				},
			"n" => {
				flags => "R",
				description => "Number of part/section",
				},
			"p" => {
				flags => "R",
				description => "Name of part/section",
				},
			"l" => {
				flags => "",
				description => "Language",
				},
			"k" => {
				flags => "R",
				description => "Form subheading",
				},
			"f" => {
				flags => "",
				description => "Date of work",
				},
			"g" => {
				flags => "",
				description => "Miscellaneous information",
				},
			"h" => {
				flags => "",
				description => "General material designation",
				},
			"q" => {
				flags => "",
				description => "Fuller form of name",
				},
			"v" => {
				flags => "",
				description => "Volume or number (after the title)",
				},
			"x" => {
				flags => "",
				description => "International Standard Serial Number",
				},
			"4" => {
				flags => "R",
				description => "Relator code",
				},
			},
		},
	"990" => {
		flags => "R",
		shortname => "",
		description => "Link to Equivalencies Cross-references and History Notes",
		ind2 => {
			"0" => {
				flags => "",
				description => "English equivalence cross-reference or history note",
				},
			"1" => {
				flags => "",
				description => "French equivalence cross-reference or history note",
				},
			"4" => {
				flags => "s",
				description => "Cross-reference in ALA form (authenticated by LC)",
				},
			"5" => {
				flags => "s",
				description => "Cross-reference in AACR1 form (authenticated by LC)",
				},
			"6" => {
				flags => "s",
				description => "Cross-reference in ALA form (input by other than LC)",
				},
			"7" => {
				flags => "s",
				description => "Cross-reference in AACR1 form (not yet authenticated by LC)",
				},
			},
		subfield => {
			"a" => {
				flags => "R",
				description => "Tag/Level-number/subfield codes of the subject field(s)",
				},
			"b" => {
				flags => "R",
				description => "Tag/Level-number/subfield codes of the object field(s)",
				},
			},
		},
);
#print $MARC_tag_data{"245"}{description} . $/;

1;
