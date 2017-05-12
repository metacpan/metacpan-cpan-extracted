#!/usr/bin/perl -w
use strict;

use Test::More tests => 15;
use Test::Exception;

use Data::Dumper;
use File::Basename;
use File::Spec::Functions;

use lib "../lib";

use_ok("Devel::PerlySense");
use_ok("Devel::PerlySense::Document");
use_ok("Devel::PerlySense::Document::Meta");


BEGIN { -d "t" and chdir("t"); }


my $dirData = "data/project-lib";
my $oMeta;


{
    my $fileOrigin = "$dirData/Game/Object/Worm/Bot.pm";
    ok(my $oDocument = Devel::PerlySense::Document->new(oPerlySense => Devel::PerlySense->new()), "new ok");
    
    ok($oDocument->parse(file => $fileOrigin), "Parsed file ok");
    
    $oMeta = $oDocument->oMeta;
    is_deeply([sort @{$oMeta->raNameModuleBase}], [
        sort qw/
                Game::Object::Worm
                /], " correct used modules");
}



{
    my $fileOrigin = "$dirData/Game/Object/Worm/ShaiHulud.pm";
    ok(my $oDocument = Devel::PerlySense::Document->new(oPerlySense => Devel::PerlySense->new()), "new ok");
    
    ok($oDocument->parse(file => $fileOrigin), "Parsed file ok");
    
    $oMeta = $oDocument->oMeta;
    is_deeply([sort @{$oMeta->raNameModuleBase}], [
        sort qw/
                Game::Object::Worm
                Game::Lawn
                /], " correct used modules");
}



{
    my $fileOrigin = "$dirData/Game/Object/Worm/Shaitan.pm";
    ok(my $oDocument = Devel::PerlySense::Document->new(oPerlySense => Devel::PerlySense->new()), "new ok");
    
    ok($oDocument->parse(file => $fileOrigin), "Parsed file ok");
    
    $oMeta = $oDocument->oMeta;
    is_deeply([sort @{$oMeta->raNameModuleBase}], [
        sort qw/
                Game::Lawn
                Game::Object::Worm
                /], " correct used modules");
}




{
    my $fileOrigin = "data/inc-lib/SubClass.pm";
    ok(my $oDocument = Devel::PerlySense::Document->new(oPerlySense => Devel::PerlySense->new()), "new ok");
    
    ok($oDocument->parse(file => $fileOrigin), "Parsed file ok");
    
    $oMeta = $oDocument->oMeta;
    is_deeply([sort @{$oMeta->raNameModuleBase}], [
        sort qw/
                Class::IsaAssignmentScalar

                Class::IsaAssignmentList1
                Class::IsaAssignmentList2

                Class::IsaAssignmentQwList1
                Class::IsaAssignmentQwList2

                Class::PushIsa
                Class::PushAnotherIsa

                Class::UseBaseScalar

                Class::UseBaseBareList1
                Class::UseBaseBareList2

                Class::UseBaseList1
                Class::UseBaseList2

                Class::UseBaseQw1
                Class::UseBaseQw2

                /], " correct used modules");
}




__END__
