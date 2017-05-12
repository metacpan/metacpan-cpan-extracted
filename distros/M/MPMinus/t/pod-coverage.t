#!/usr/bin/perl -wT
#########################################################################
#
# Serz Minus (Lepenkov Sergey), <minus@mail333.com>
#
# Copyright (C) 1998-2013 D&D Corporation. All Rights Reserved
# 
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: pod-coverage.t 166 2013-06-14 10:08:15Z minus $
#
#########################################################################

use Test::More;
eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage required for testing POD coverage" if $@;
plan skip_all => "Currently a developer-only test" unless -d '.svn' || -d ".git";
plan tests => 16;

#plan skip_all => "Currently FAILS FOR MANY MODULES!";
#all_pod_coverage_ok();

pod_coverage_ok( "MPMinus", { trustme => [qr/^(new)$/] } );

# MPMinus::*
pod_coverage_ok( "MPMinus::BaseHandlers", { trustme => [qr/^[A-Z_]+$/] } );
pod_coverage_ok( "MPMinus::Configuration" );
pod_coverage_ok( "MPMinus::Dispatcher", { trustme => [qr/default/,qr/^[A-Z_]+$/] } );
pod_coverage_ok( "MPMinus::MainTools" );
pod_coverage_ok( "MPMinus::Transaction", { trustme => [qr/^[A-Z_]+$/] } );
pod_coverage_ok( "MPMinus::Util", { trustme => [qr/^(LOG_.+)$/] } );

# MPMinus::Debug::*
pod_coverage_ok( "MPMinus::Debug::Info", { trustme => [qr/^[A-Z_]+$/] } );
pod_coverage_ok( "MPMinus::Debug::System" );

# MPMinus::Helper::*
#pod_coverage_ok( "MPMinus::Helper::Handlers", { trustme => [qr/^[A-Z_]+$/] } );
#pod_coverage_ok( "MPMinus::Helper::Skel" );
pod_coverage_ok( "MPMinus::Helper::Util" );

# MPMinus::MainTools::*
pod_coverage_ok( "MPMinus::MainTools::MD5", { trustme => [qr/^(.+?md5_crypt|get_salt|to64)$/] } );
pod_coverage_ok( "MPMinus::MainTools::TCD04", { trustme => [qr/^(new)$/] } );

# MPMinus::Store::*
pod_coverage_ok( "MPMinus::Store::DBI", { trustme => [qr/^(new)$/] } );
pod_coverage_ok( "MPMinus::Store::MySQL", { trustme => [qr/^(new)$/] } );
pod_coverage_ok( "MPMinus::Store::Oracle", { trustme => [qr/^(new)$/] } );
pod_coverage_ok( "MPMinus::Store::MultiStore", { trustme => [qr/^(new)$/] } );

1;
