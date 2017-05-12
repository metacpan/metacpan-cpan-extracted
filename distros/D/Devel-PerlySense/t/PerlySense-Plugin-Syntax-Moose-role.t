#!/usr/bin/perl -w
use strict;

use Test::More tests => 12;

use Data::Dumper;

use lib "../lib";

use_ok("Devel::PerlySense");
use_ok("Devel::PerlySense::Document");
use_ok("Devel::PerlySense::Document::Meta");

#use Carp::Always;

my $dirData = "t/data/plugin-moose";
my $oMeta;



my @tests = (
    {
        file    => "Scalar.pm",
        expects => [ sort qw/ Class::Moose::RoleScalar /],
    },
    {
        file    => "List.pm",
        expects => [ sort qw/ Class::Moose::RoleList1 Class::Moose::RoleList2 /],
    },
    {
        file    => "QwList.pm",
        expects => [ sort qw/ Class::Moose::RoleQwList1 Class::Moose::RoleQwList2 /],
    },
);
for my $test (@tests) {
    my $file = $test->{file};
    note("Checking role in ($file)");
    
    my $fileOrigin = "t/data/plugin-moose/Role/$file";
    ok(my $oDocument = Devel::PerlySense::Document->new(oPerlySense => Devel::PerlySense->new()), "new ok");
    
    ok($oDocument->parse(file => $fileOrigin), "Parsed file ok");
    
    $oMeta = $oDocument->oMeta;
    is_deeply(
        [ sort @{$oMeta->raNameModuleBase} ],
        $test->{expects},
        " correct used modules",
    );
}




__END__
