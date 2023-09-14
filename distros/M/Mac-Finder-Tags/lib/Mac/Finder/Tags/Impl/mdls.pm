use v5.26;
use warnings;

package Mac::Finder::Tags::Impl::mdls;
# ABSTRACT: Provides get_tags based on the mdls tool
$Mac::Finder::Tags::Impl::mdls::VERSION = '0.02';

use Object::Pad 0.57;

use Mac::Finder::Tags::Tag;


class Mac::Finder::Tags::Impl::mdls
	:does(Mac::Finder::Tags::Impl)
	:strict(params)
{
	
	method get_tags ($path) {
		return my @empty if not stat $path;  # dangling symlinks etc.
		$path =~ s/([\\"])/\\$1/g;
		my $md = `mdls -name kMDItemFSLabel -name kMDItemUserTags -raw "$path"`;
		my @md = split m/,?\n\s*/, decode_cesu8($md);
		my $label = substr shift(@md), 0, 1;
		pop @md;
		my @tags;
		if (@md == 1) {
			@tags = ( Mac::Finder::Tags::Tag->new( name => trim($md[0]), color => $label ) );
		}
		else {
			@tags = map { Mac::Finder::Tags::Tag->new( name => trim($_), color_guessed => !!1 ) } @md;
		}
		if (! @tags && $label) {
			@tags = Mac::Finder::Tags::Tag->new( name => undef, color => $label, legacy_label => !!1 );
		}
		return @tags;
	}
	
	my $SURROGATE_OFFSET = 0x10000 - (0xD800 << 10) - 0xDC00;  # for decoding CESU-8 surrogate pairs
	
	sub decode_cesu8 ($data) {
		# decode escaped Unicode sequences (CESU-8 encoded)
		# https://unicode.org/faq/utf_bom.html#utf16-4
		$data =~ s{
			\\U([dD][89abAB][0-9a-fA-F]{2})
			\\U([dD][c-fC-F][0-9a-fA-F]{2})
		}{
			my ($hi, $lo) = (hex $1, hex $2);
			my $codepoint = ($hi << 10) + $lo + $SURROGATE_OFFSET;
			chr $codepoint;
		}exg;
		$data =~ s{\\U([0-9a-fA-F]{4})}{chr hex $1}eg;
		return $data;
	}
	
	# trim whitespace and remove any quotes
	sub trim ($s) {
		$s =~ s/\A\s+//;
		$s =~ s/,?\s+\z//;
		$s =~ s/\A"(.*)"\Z/$1/;
		$s =~ s{\\"}{"}g;
		$s;
	}
	
}


1;
