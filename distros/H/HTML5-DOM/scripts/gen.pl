#!/user/bin/perl
use warnings;
use strict;

use File::Slurp qw|read_file write_file|;
use File::Basename qw|dirname|;
use POSIX;
use Pod::Markdown::Github;

genReadmeMd();
genTagsDisplayProp();
genErrorCodes();
getConstants();

sub genReadmeMd {
	my $pod = read_file(dirname(__FILE__)."/../lib/HTML5/DOM.pod");
	my $markdown;
	my $parser = Pod::Markdown::Github->new;
	$parser->output_string(\$markdown);
	$parser->parse_string_document($pod);
	
	my $fix = sub {
		my $value = shift;
		$value =~ s/-//g;
		return $value;
	};
	
	$markdown =~ s/(\(#html5-dom[\w\d_-]*\))/$fix->($1)/ge;
	
	write_file(dirname(__FILE__)."/../README.md", {binmode => ':utf8'}, $markdown);
}

sub genTagsDisplayProp {
	my $text = read_file(dirname(__FILE__).'/tags.txt');
	my $tmp = "";
	while ($text =~ /([\w\d_-]+)\s+([\w\d_-]+)/gi) {
		my ($tag, $display) = ($1, $2);
		
		$display = uc($display);
		$display =~ s/-/_/g;
		$display = "TAG_UA_STYLE_$display";
		
		$tag = uc($tag);
		$tag =~ s/-/_/g;
		$tag = "MyHTML_TAG_$tag";
		
		$tmp .= "case $tag:\n\treturn $display;\n";
		
		print "$tag -> $display\n";
	}
	write_file(dirname(__FILE__)."/../gen/tags_ua_style.c", $tmp);
}

sub genErrorCodes {
	# errors codes
	my $files = [
		{
			file	=> dirname(__FILE__).'/../third_party/modest/source/modest/myosi.h', 
			prefix	=> 'MODEST_STATUS_'
		}, 
		{
			file	=> dirname(__FILE__).'/../third_party/modest/source/mycss/api.h', 
			prefix	=> 'MyCSS_STATUS_'
		}, 
		{
			file	=> dirname(__FILE__).'/../third_party/modest/source/myhtml/myosi.h', 
			prefix	=> 'MyHTML_STATUS_'
		}
	];

	my $tmp = "";
	for my $cfg (@$files) {
		my $source = read_file($cfg->{file});
		my $prefix = $cfg->{prefix};
		while ($source =~ /($prefix[\w\d_-]+)\s*=\s*([a-fx\d]+)/gim) {
			my ($key, $value) = ($1, eval $2);
			next if ($key eq $prefix."OK");
			$tmp .= "case $key:\n\treturn \"$key\";\n";
		}
		
		print $cfg->{file}." - error names ok\n";
	}
	
	write_file(dirname(__FILE__)."/../gen/modest_errors.c", $tmp);
}

sub getConstants {
	my $files = [
		{
			header		=> dirname(__FILE__).'/../third_party/modest/include/myencoding/myosi.h', 
			lib			=> dirname(__FILE__).'/../lib/HTML5/DOM/Encoding.pm', 
			macro		=> 'MyENCODING_const', 
			prefix		=> 'MyENCODING_', 
			prefix_new	=> ''
		}, 
		{
			header		=> dirname(__FILE__).'/../third_party/modest/include/myhtml/tag_const.h', 
			lib			=> dirname(__FILE__).'/../lib/HTML5/DOM.pm', 
			macro		=> 'MyHTML_tags', 
			prefix		=> 'MyHTML_TAG_', 
			prefix_new	=> 'TAG_'
		}, 
		{
			header		=> dirname(__FILE__).'/../third_party/modest/include/myhtml/myosi.h', 
			lib			=> dirname(__FILE__).'/../lib/HTML5/DOM.pm', 
			macro		=> 'MyHTML_ns', 
			prefix		=> 'MyHTML_NAMESPACE_', 
			prefix_new	=> 'NS_'
		}
	];
	
	for my $cfg (@$files) {
		my $header = read_file($cfg->{header});
		my $lib = read_file($cfg->{lib});
		my $macro = $cfg->{macro};
		my $prefix = $cfg->{prefix};
		
		my @tmp;
		while ($header =~ /($prefix([\w\d_-]+))\s*=\s*([a-fx\d]+)/gim) {
			my ($key, $value) = ($cfg->{prefix_new}.$2, eval $3);
			next if ($key =~ /_STATUS_/);
			
			my $tabs = ceil(((6 * 4) - length($key)) / 4);
			
			push @tmp, "use constant\t$key".("\t" x $tabs)."=> ".sprintf("0x%x", $value).";";
		}
		
		my $txt = join("\n", @tmp);
		$lib =~ s/(<$macro>)(.*?)(#\s*<\/$macro>)/$1\n$txt\n$3/gims;
		
		write_file($cfg->{lib}, $lib);
		
		print $cfg->{lib}." - consts `".$cfg->{prefix}."` from ".$cfg->{header}."\n";
	}
}

# encodings

