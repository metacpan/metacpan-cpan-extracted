#!/usr/bin/perl
BEGIN{unshift @INC, "./blib/lib"}

use MARC::Descriptions;

my $td = MARC::Descriptions->new;

#
# Strings
#
print "String:\n";
# Can we get it?
print "Get....\n";
$s = $td->get("245","description");
print "245: $s\n";
# Can we reset it?  (We shouldn't be able to!)
print "\nReset....\n";
$s = "Hmm.";
$s = $td->get("245","description");
print "245: $s\n";
print "\n";
#
# Strings 2
#
print "Strings 2:\n";
# Can we get it?
print "Get....\n";
$s = $td->get("245","subfield","b","description");
print "245: $s\n";
# Can we reset it?  (We shouldn't be able to!)
print "\nReset....\n";
$s = "Hmm.";
$s = $td->get("245","subfield","b","description");
print "245: $s\n";
print "\n";
#
# Returned hashes
#
print "Returned hash:\n";
# Can we get it?
print "Get....\n";
$href = $td->get("245");
foreach $key (sort keys %$href) {
    if (ref($href->{$key}) eq "HASH") {
	print "$key =>\n";
	$href1 = $href->{$key};
	foreach $key1 (sort keys %$href1) {
	    if (ref($href1->{$key1}) eq "HASH") {
		print "  $key1 =>\n";
		$href2 = $href1->{$key1};
		foreach $key2 (sort keys %$href2) {
		    print "    $key2 => $href2->{$key2}\n";
		}
	    } else {
		print "  $key1 => $href1->{$key1}\n";
	    }
	}
    } else {
	print "$key => $href->{$key}\n";
    }
}

# Can we reset it?  (We shouldn't be able to!)
print "\nReset....\n";
$href->{flags} = "Hmm.";
$href = $td->get("245");
foreach $key (sort keys %$href) {
    if (ref($href->{$key}) eq "HASH") {
	print "$key =>\n";
	$href1 = $href->{$key};
	foreach $key1 (sort keys %$href1) {
	    if (ref($href1->{$key1}) eq "HASH") {
		print "  $key1 =>\n";
		$href2 = $href1->{$key1};
		foreach $key2 (sort keys %$href2) {
		    print "    $key2 => $href2->{$key2}\n";
		}
	    } else {
		print "  $key1 => $href1->{$key1}\n";
	    }
	}
    } else {
	print "$key => $href->{$key}\n";
    }
}
print "\n";


#
# Returned hashes 2
#
print "Returned hashes 2:\n";
# Can we get it?
print "Get....\n";
$href = $td->get("210","subfield");
foreach $key (sort keys %$href) {
    if (ref($href->{$key}) eq "HASH") {
	print "$key =>\n";
	$href1 = $href->{$key};
	foreach $key1 (sort keys %$href1) {
	    if (ref($href1->{$key1}) eq "HASH") {
		print "  $key1 =>\n";
		$href2 = $href1->{$key1};
		foreach $key2 (sort keys %$href2) {
		    print "    $key2 => $href2->{$key2}\n";
		}
	    } else {
		print "  $key1 => $href1->{$key1}\n";
	    }
	}
    } else {
	print "$key => $href->{$key}\n";
    }
}

# Can we reset it?  (We shouldn't be able to!)
print "\nReset....\n";
$href->{"a"}->{description} = "Hmm.";
$href = $td->get("210","subfield");
foreach $key (sort keys %$href) {
    if (ref($href->{$key}) eq "HASH") {
	print "$key =>\n";
	$href1 = $href->{$key};
	foreach $key1 (sort keys %$href1) {
	    if (ref($href1->{$key1}) eq "HASH") {
		print "  $key1 =>\n";
		$href2 = $href1->{$key1};
		foreach $key2 (sort keys %$href2) {
		    print "    $key2 => $href2->{$key2}\n";
		}
	    } else {
		print "  $key1 => $href1->{$key1}\n";
	    }
	}
    } else {
	print "$key => $href->{$key}\n";
    }
}
print "\n";

$href = $td->get("210","subfields");
print "210 subfield 'a' description: " . $href->{"a"}->{description} . "\n";
