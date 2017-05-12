package Dotiac::DTL::Addon::unparsed;
require Dotiac::DTL::Tag::unparsed;
#for testing {% unparsed %}
sub import {
	$Dotiac::DTL::Addon::NOCOMPILE{'Dotiac::DTL::Addon::unparsed'}=1;
}
sub unimport {}
1;
