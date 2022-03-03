use v5.26;
use warnings;

package Mac::Finder::Tags::Impl::xattr;
# ABSTRACT: Provides get_tags based on the xattr tool
$Mac::Finder::Tags::Impl::xattr::VERSION = '0.01';

use Mac::PropertyList 'parse_plist';
use Object::Pad 0.57;

use Mac::Finder::Tags::Tag;


class Mac::Finder::Tags::Impl::xattr
	:does(Mac::Finder::Tags::Impl)
	:strict(params)
{
	
	method get_tags ($path) {
		$path =~ s/([\\"])/\\$1/g;
		my @tags = eval {
			my $hex = `xattr -xp com.apple.metadata:_kMDItemUserTags "$path" 2> /dev/null` or return;
			$hex =~ s/\s+//g;
			my $bplist = pack "H*", $hex;
			my $tags = parse_plist($bplist)->as_perl or return;
			return map {
				my ($name, $color) = split m/\n/;
				Mac::Finder::Tags::Tag->new( name => $name // '', color => $color || 0 );
			} @$tags;
		};
		
		if (! @tags) {
			my $color = eval {
				my $hex = `xattr -xp com.apple.FinderInfo "$path" 2> /dev/null` or return;
				$hex = substr $hex, 9*3, 2;
				return (ord(pack "H*", $hex) & 0x0e) >> 1;
			};
			if ($color) {
				@tags = Mac::Finder::Tags::Tag->new( name => undef, color => $color, legacy_label => !!1 );
			}
		}
		
		return @tags;
	}
	
}


1;
