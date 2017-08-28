#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 8;
use Glib::IO;

my $file = Glib::IO::File::new_for_path ($0);
my $info = $file->query_info ('*', [], undef);

my $attrs = $info->list_attributes ('standard');
ok (grep { $_ eq "standard::type" } @$attrs);

SKIP: {
  skip 'get_attribute_data; not usable currently', 4;
  my ($success, $type, $memory, $status) =
    $info->get_attribute_data ('standard::type');
  ok ($success); # get rid of the boolean return?
  is ($type, 'uint32');
  is ($memory, undef); # this seems to be garbage right now
  is ($status, 'unset');
}

my $mod_time = $info->get_modification_time ();
ok (exists $mod_time->{tv_sec} && exists $mod_time->{tv_usec});
$info->set_modification_time ({
  tv_sec => $mod_time->{tv_sec} - 1,
  tv_usec => $mod_time->{tv_usec}});
my $new_mod_time = $info->get_modification_time ();
is ($new_mod_time->{tv_sec}, $mod_time->{tv_sec} - 1);

my $matcher = Glib::IO::FileAttributeMatcher->new ('standard::*');
ok ($matcher->matches ('standard::type'));
