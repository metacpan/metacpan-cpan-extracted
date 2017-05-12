package Decode::Source;

use 5.008;
use strict;
use Filter::Util::Call;
use Encode;

our $VERSION = '1.01';

our $filter_is_on = 0;

sub import {
	my $pkg = shift;
	my $enc = "utf8";
	$enc = shift if @_;
	filter_del() if $filter_is_on++;
	filter_add({_encoding => $enc});
	return 1;
}

sub unimport {
	filter_del(); 
	$filter_is_on = 0;
}

sub filter {
	my $obj = shift;
	my $ok = filter_read();
	$_ = decode $obj->{_encoding}, $_ if $ok > 0;
	$_ = "use utf8;$_" unless $obj->{_lines}++;
	$obj->{_lines} = 0 if s/(no\s+Decode::Source)/no utf8;$1/go;
	return $ok;
}

1;

=head1 NAME

Decode::Source - Run scripts written in encodings other than utf-8

=head1 SYNOPSIS

    use Decode::Source "iso-8859-1";
       ... code written in ISO-8859-1 ...
    use Decode::Source "cp-850";
       ... code written in DOS codepage 850 ...
    no Decode::Source;
        ... code written in US-ASCII ...

=head1 ABSTRACT

Use alternative encodings/charsets for your program code.
Perl 5.8 or higher is required for use of this module.

=head1 DESCRIPTION

B<This code is so far only tested on Win32 platforms!>

Decode::Source makes it possible to write perl programs in any script or
encoding supported by the C<Encode> module. Variable names can contain
non-ASCII characters, just as when you use the C<use utf8> pragma. All
theese characters, both in identifiers and string literals, will be
decoded to perl's internal utf-8 form, before execution.

The syntax are similar to C<use utf8> and C<no utf8>, but Decode::Source
also takes an optional argument with source encoding. This argument can be 
any argument that C<Encode>'s C<decode> function accept as a valid
encoding. See also L<Encode>.

=head1 EXAMPLE

  use Decode::Source "windows-1252";
  
  $åke   = ["Åke Braun", "08-555 55 55"];
  $örjan = ["Örjan Älg", "08-555 55 54"];

  binmode STDOUT, ":encodings(cp850)";
  
  printf "Name: %-20s   Phone: %12s\n", @$_ for $åke, $örjan;

=head1 SEE ALSO

L<Encode>, L<Encode::Supported>, L<utf8>

=head1 AUTHOR

Magnus HE<aring>kansson, E<lt>mailto:magnus@mbox604.swipnet.seE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Magnus HE<aring>kansson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
