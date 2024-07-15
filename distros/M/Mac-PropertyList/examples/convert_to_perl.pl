#!/usr/local/bin/perl
use warnings;
use strict;

use Data::Dumper;
use Mac::PropertyList qw(parse_plist);

my $data = do { local $/; <DATA> };
my $plist = parse_plist( $data );

open my( $fh ), ">", \ my $hashstring;
print $fh "\$VAR = $plist";
close $fh;


my $ds;
{
no strict 'vars';
$ds = eval $hashstring;
print "Error! $@" if $@;
}

print Dumper( $ds );


BEGIN {
	package Mac::PropertyList::dict;

	use overload
		'""' => sub {
			my $s = "{\n";
			foreach my $key ( $_[0]->keys )
				{
				my $v = $_[0]->{$key};
				$s .= "\t$key => $v,\n";
				}
			$s .= "\t}";
			$s;
			};

	package Mac::PropertyList::array;

	use overload
		'""' => sub {
			my $s = "[\n";
			foreach my $value ( $_[0]->value )
				{
				$s .= "\t$value,\n";
				}
			$s .= "\t]";
			$s;
			};

	package Mac::PropertyList::Scalar;

	use overload
		'""' => sub {
			"'" . $_[0]->value . "'";
			};

	}

__END__
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>ABPersonFlags</key>
	<integer>0</integer>
	<key>ABPropertyTypes</key>
	<dict>
		<key>ABDate</key>
		<integer>260</integer>
		<key>ABDepartment</key>
		<integer>1</integer>
		<key>ABPersonFlags</key>
		<integer>2</integer>
		<key>ABRelatedNames</key>
		<integer>257</integer>
		<key>AIMInstant</key>
		<integer>257</integer>
		<key>Address</key>
		<integer>262</integer>
		<key>Birthday</key>
		<integer>4</integer>
		<key>Creation</key>
		<integer>4</integer>
		<key>Email</key>
		<integer>257</integer>
		<key>First</key>
		<integer>1</integer>
		<key>FirstPhonetic</key>
		<integer>1</integer>
		<key>HomePage</key>
		<integer>1</integer>
		<key>ICQInstant</key>
		<integer>257</integer>
		<key>JabberInstant</key>
		<integer>257</integer>
		<key>JobTitle</key>
		<integer>1</integer>
		<key>Last</key>
		<integer>1</integer>
		<key>LastPhonetic</key>
		<integer>1</integer>
		<key>MSNInstant</key>
		<integer>257</integer>
		<key>MaidenName</key>
		<integer>1</integer>
		<key>Middle</key>
		<integer>1</integer>
		<key>MiddlePhonetic</key>
		<integer>1</integer>
		<key>Modification</key>
		<integer>4</integer>
		<key>Nickname</key>
		<integer>1</integer>
		<key>Note</key>
		<integer>1</integer>
		<key>Organization</key>
		<integer>1</integer>
		<key>Phone</key>
		<integer>257</integer>
		<key>RemoteLocation</key>
		<integer>257</integer>
		<key>Suffix</key>
		<integer>1</integer>
		<key>Title</key>
		<integer>1</integer>
		<key>UID</key>
		<integer>1</integer>
		<key>URLs</key>
		<integer>257</integer>
		<key>YahooInstant</key>
		<integer>257</integer>
		<key>calendarURIs</key>
		<integer>257</integer>
	</dict>
	<key>Address</key>
	<dict>
		<key>identifiers</key>
		<array>
			<string>C34F35BC-ED5D-48DC-87AC-181FEFCFAA84</string>
		</array>
		<key>labels</key>
		<array>
			<string>_$!&lt;Home&gt;!$_</string>
		</array>
		<key>primary</key>
		<string>C34F35BC-ED5D-48DC-87AC-181FEFCFAA84</string>
		<key>values</key>
		<array>
			<dict>
				<key>City</key>
				<string>Troy</string>
				<key>State</key>
				<string>NJ</string>
				<key>Street</key>
				<string>C/o Acacia
4 Sunset Terrace</string>
				<key>ZIP</key>
				<string>12180</string>
			</dict>
		</array>
	</dict>
	<key>Creation</key>
	<date>2007-11-14T02:19:02Z</date>
	<key>Email</key>
	<dict>
		<key>identifiers</key>
		<array>
			<string>FD55B9B6-EBB4-4A17-B272-5CED1CDCA2CD</string>
		</array>
		<key>labels</key>
		<array>
			<string>_$!&lt;Home&gt;!$_</string>
		</array>
		<key>primary</key>
		<string>FD55B9B6-EBB4-4A17-B272-5CED1CDCA2CD</string>
		<key>values</key>
		<array>
			<string>japhy@pobox.com</string>
		</array>
	</dict>
	<key>First</key>
	<string>Jeff</string>
	<key>Last</key>
	<string>Pinyan</string>
	<key>Modification</key>
	<date>2007-11-14T02:19:02Z</date>
	<key>Note</key>
	<string>X-Palm-Category1: Perl Mongers</string>
	<key>Phone</key>
	<dict>
		<key>identifiers</key>
		<array>
			<string>33DC969F-1CED-4DB5-9088-34E2DF74CD31</string>
		</array>
		<key>labels</key>
		<array>
			<string>_$!&lt;Home&gt;!$_</string>
		</array>
		<key>primary</key>
		<string>33DC969F-1CED-4DB5-9088-34E2DF74CD31</string>
		<key>values</key>
		<array>
			<string>201-652-5489</string>
		</array>
	</dict>
	<key>UID</key>
	<string>0A4DB366-0737-4BB8-8FDF-A9351CCE41C7:ABPerson</string>
</dict>
</plist>
