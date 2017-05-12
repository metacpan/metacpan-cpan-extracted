# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2012-12-17 11:12:34 +0000 (Mon, 17 Dec 2012) $
# Id:            $Id: 00-pod.t 15 2012-12-17 11:12:34Z rmp $
# $HeadURL: svn+ssh://psyphi.net/repository/svn/iotamarathon/trunk/t/00-pod.t $
#
use strict;
use warnings;
use Test::More;

eval {
  require Test::Pod;
  Test::Pod->import();
};

plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();

