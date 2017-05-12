#!/usr/bin/perl

# $Id: 01distribconf.t 231445 2007-11-09 13:46:44Z nanardon $

use strict;
use Test::More;

my %testdpath = (
    'testdata/test' => undef,
    'testdata/test2' => undef,
    'testdata/test3' => undef,
    'http://server/path/' => 'testdata/test/media/media_info/media.cfg',
);

plan tests => 14 + 29 * scalar(keys %testdpath);

use_ok('MDV::Distribconf');

{
ok(my $dconf = MDV::Distribconf->new('/dev/null'), "Can get new MDV::Distribconf");
ok(!$dconf->load(), "loading wrong distrib give error");
}

foreach my $path (keys %testdpath) {
    ok(my $dconf = MDV::Distribconf->new($path), "Can get new MDV::Distribconf");
    if ($testdpath{$path}) {
        $dconf->settree('mandriva');
    } else {
        ok($dconf->load(), "Can load conf");
    }

    is($dconf->getpath(undef, 'root'), $path, "Can get root path");
    like($dconf->getpath(undef, 'media_info'), qr!^/*media/media_info/?$!, "Can get media_info path"); # vim color: */ 
    like($dconf->getpath(undef, 'infodir'), qr!^/*media/media_info/?$!, "Can get infodir"); # vim color: */ 
    like($dconf->getpath(undef, 'mediadir'), qr!^/*media/?$!, "Can get infodir"); # vim color: */ 

    if ($testdpath{$path}) {
        ok($dconf->parse_mediacfg($testdpath{$path}), "can parse media.cfg");
    }

    ok(scalar($dconf->listmedia) == 8, "Can list all media");
    ok((grep { $_ eq 'main' } $dconf->listmedia), "list properly media");

    is($dconf->getvalue(undef, 'version'), '2006.0', "Can get global value");
    is($dconf->getvalue('main', 'version'), '2006.0', "Can get global value via media");
    is($dconf->getvalue('main', 'name'), 'main', "Can get default name");
    is($dconf->getvalue('contrib', 'name'), 'Contrib', "Can get media name");
    is($dconf->getvalue('contrib', 'platform'), 'i586-mandriva-linux-gnu', "Can get media platform");

    is($dconf->getpath(undef, 'root'), $path, "Can get root path");
    like($dconf->getpath(undef, 'media_info'), qr!^/*media/media_info/?$!, "Can get media_info path"); # vim color: */ 
    like($dconf->getfullpath(undef, 'media_info'), qr!^/*$path/+media/media_info/?$!, "Can get media_info fullpath"); # vim color: */
    like($dconf->getpath('main', 'path'), qr!^/*media/+main/?$!, "Can get media path"); # vim color: */
    like($dconf->getfullpath('main', 'path'), qr!^/*$path/*media/+main/?$!, "Can get media fullpath"); # vim color: */
    like($dconf->getpath('main', 'hdlist'), qr!^/*media/+media_info/+hdlist_main.cz$!, "Can get media path"); # vim color: */
    like($dconf->getfullpath('main', 'hdlist'), qr!^/*$path/*media/+media_info/+hdlist_main.cz$!, "Can get media fullpath"); # vim color: */
    like($dconf->getmediapath('main', 'hdlist'), qr!^/*media/+main/+media_info/+hdlist.cz$!, "Can get media path"); # vim color: */
    like($dconf->getfullmediapath('main', 'hdlist'), qr!^/*$path/*media/+main/+media_info/+hdlist.cz$!, "Can get media fullpath"); # vim color: */
    like($dconf->getdpath('main', 'hdlist'), qr!^/*media/+main/+media_info/+hdlist.cz$!, "can get dpath");
    like($dconf->getfulldpath('main', 'hdlist'), qr!^/*$path/*media/+main/+media_info/+hdlist.cz$!, "can get fulldpath");
    like($dconf->getfullpath('../SRPMS/contrib', 'pubkey'),
        qr!^/*$path/*media/+media_info/+pubkey_[^ ]+$!, "can get pubkey full path");
    is($dconf->getdpath(undef, 'root'), $path, "can get fulldpath");
    is($dconf->getfulldpath(undef, 'VERSION'), "$path/VERSION", "can get fulldpath");
    is($dconf->getdpath('main', 'root'), $path, "can get fulldpath root even media is given");
    is($dconf->getdpath('main', 'description'), 'media/media_info/description', "can get fulldpath description even media is given");
}

{
ok(my $dconf = MDV::Distribconf->new('not_exists', 1), "Can get new MDV::Distribconf");
$dconf->settree();
like($dconf->getpath(undef, 'media_info'), qr!^/*media/media_info/?$!, "Can get media_info path"); # vim color: */
}
{
ok(my $dconf = MDV::Distribconf->new('not_exists', 1), "Can get new MDV::Distribconf");
$dconf->settree('manDraKE');
like($dconf->getpath(undef, 'media_info'), qr!^/*Mandrake/base/?$!, "Can get media_info path"); # vim color: */
}
{
ok(my $dconf = MDV::Distribconf->new('not_exists', 1), "Can get new MDV::Distribconf");
$dconf->settree({ 
  mediadir => 'mediadir',
  infodir => 'infodir',
});
like($dconf->getpath(undef, 'media_info'), qr!^/*infodir/?$!, "Can get media_info path"); # vim color: */
}

{
    # test for %{} ${} var
    my $dc = MDV::Distribconf->new('testdata/test3');
    $dc->load();
    is(
        $dc->_expand(undef, '${version}'),
        '2006.0',
        'expand works'
    );
    is(
        $dc->_expand('jpackage', '%{name}'),
        'jpackage',
        'expand works'
    );
    is(
        $dc->_expand('jpackage', '${version}'),
        '2006.0',
        'expand works'
    );
    is(
        $dc->_expand(undef, '%{foo}'),
        '%{foo}',
        'expand works'
    );
    is(
        $dc->getvalue('jpackage', 'hdlist'),
        'hdlist_jpackage.cz',
        'getvalue works'
    );
}
