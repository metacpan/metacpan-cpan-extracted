#!/usr/bin/perl -w
#########################################################################
#
# Sergey Lepenkov (Serz Minus), <abalama@cpan.org>
#
# Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 00-trailingspace.t 43 2017-07-31 13:04:58Z minus $
#
# For Notapad++: [ \t]+\r\n -> \r\n
#
#########################################################################
use strict;
use Test::More;

eval "use Test::TrailingSpace";
plan skip_all => "Test::TrailingSpace required for trailing space test" if $@;

plan tests => 1;

my $finder = Test::TrailingSpace->new({
       root => '.',
       filename_regex => qr/(?:\.(?:t|pm|pl|cgi|xs|c|h|pod|PL|conf)|README|CHANGES|TODO|LICENSE|mdscore)\z/,
   });

# TEST
$finder->no_trailing_space("No trailing space was found");

1;
__END__
