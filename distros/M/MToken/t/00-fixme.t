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
# $Id: 00-fixme.t 43 2017-07-31 13:04:58Z minus $
#
#########################################################################
use strict;
use Test::More;

eval "use Test::Fixme";
plan skip_all => "requires Test::Fixme to run" if $@;
run_tests(
    where => [qw/bin lib inc/],
    match => qr/\s+([T]ODO|[F]IX(ME|IT)?|[B]UG)\W/,
    warn => 1,
);

1;
__END__
