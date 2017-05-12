package Dotiac::DTL::Addon::customtext;

#for testing {% load %}

sub import {
}
sub unimport {}

package Dotiac::DTL::Filter;

sub customtext {
	return Dotiac::DTL::Value->escape("BACAB");
}
1;
