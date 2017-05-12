#!/usr/bin/perl -w
use strict;

use Test::More tests => 28;
use Test::Exception;

use Data::Dumper;
use File::Basename;
use File::Spec::Functions;

use lib "../lib";

use_ok("Devel::PerlySense");
use_ok("Devel::PerlySense::Document");
use_ok("Devel::PerlySense::Document::Meta");


BEGIN { -d "t" and chdir("t"); }


ok(my $oDocument = Devel::PerlySense::Document->new(oPerlySense => Devel::PerlySense->new()), "new ok");


my $dirData = "data/project-lib";
my $fileOrigin = "$dirData/Game/Object/Worm.pm";

ok($oDocument->parse(file => $fileOrigin), "Parsed file ok");

my $oMeta = $oDocument->oMeta;

is(scalar(keys %{$oMeta->rhRowColModule}), 18, " found correct number of modules");

is($oMeta->rhRowColModule->{23}->{5}->{oNode} . "", "Data::Dumper", " got module node");
is($oMeta->rhRowColModule->{23}->{5}->{module} . "", "Data::Dumper", " got module");
is($oMeta->rhRowColModule->{24}->{5}->{oNode} . "", "Game::Location", " got module node");
is($oMeta->rhRowColModule->{41}->{5}->{oNode} . "", "Exception::Class", " got module node");
is($oMeta->rhRowColModule->{152}->{24}->{oNode} . "", "Game::Event::Timed", " got module node");
is($oMeta->rhRowColModule->{318}->{13}->{oNode} . "", "ExceptionCouldNotMoveForward", " got module node");

is($oMeta->rhRowColModule->{156}->{17}->{oNode} . "", q{"Carp"}, " got module node, looks somewhat like module, and exists");
is($oMeta->rhRowColModule->{156}->{17}->{module} . "", "Carp", " got module node, looks somewhat like module, and exists");
is($oMeta->rhRowColModule->{157}->{14}->{oNode} . "", q{"File::Spec"}, " got module node, looks like module, good enough");
is($oMeta->rhRowColModule->{157}->{14}->{module} . "", "File::Spec", " got module node, looks like module, good enough");
is($oMeta->rhRowColModule->{171}->{14}->{module} . "", "None::Exsistent::Module", " got module, looks like module, good enough");



#print Dumper($oMeta->rhRowColModule->{42});

sub _check_no_module {
    my ($oMeta, $line, $col, $message) = @_;
    my $oModule = $oMeta->rhRowColModule->{$line}->{$col};
    is($oModule, undef, " no module at ($line, $col) $message")
        or diag("Details: " . Dumper($oModule));
}

_check_no_module($oMeta, 341, 5 , "sub declaration");
_check_no_module($oMeta, 341, 28, "variable name");
_check_no_module($oMeta, 341, 27, "variable sigil");
_check_no_module($oMeta, 332, 1 , "nothing");
_check_no_module($oMeta, 363, 16, "string literal");
_check_no_module($oMeta, 365, 5 , "keyword return");
_check_no_module($oMeta, 161, 47, "method call");
_check_no_module($oMeta, 145, 29, "numeric literal");

_check_no_module($oMeta, 42 , 5 , "string literal 'Exception'");
_check_no_module($oMeta, 159, 16, 'string literal "O"');
_check_no_module($oMeta, 151, 18, 'string literal "white"');


__END__
