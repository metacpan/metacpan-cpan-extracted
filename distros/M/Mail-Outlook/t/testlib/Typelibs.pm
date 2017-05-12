package Typelibs;

use warnings;
use strict;

use Win32::OLE::Const;

# list of all registered type libraries
my %Library;

sub ExistsTypeLib {
	my $typelib = shift;
	return $Library{$typelib}	if(exists $Library{$typelib});
	for my $lib (keys %Library) {
		return $Library{$lib}	if($lib =~ /^$typelib/);
	}
	return undef;
}

Win32::OLE::Const->EnumTypeLibs(sub {
    my ($clsid,$title,$version) = @_;
    return unless $version =~ /^([0-9a-fA-F]+)\.([0-9a-fA-F]+)$/;
    my ($maj,$min) = (hex($1), hex($2));
    $Library{$title} = "$maj.$min";
});

1;
