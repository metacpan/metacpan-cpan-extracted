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
        expects => [ sort qw/ Class::Moose::ExtendsScalar /],
    },
    {
        file    => "List.pm",
        expects => [ sort qw/ Class::Moose::ExtendsList1 Class::Moose::ExtendsList2 /],
    },
    {
        file    => "QwList.pm",
        expects => [ sort qw/ Class::Moose::ExtendsQwList1 Class::Moose::ExtendsQwList2 /],
    },
);
for my $test (@tests) {
    my $file = $test->{file};
    note("Checking extends  in ($file)");
    
    my $fileOrigin = "t/data/plugin-moose/SubClass/$file";
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
