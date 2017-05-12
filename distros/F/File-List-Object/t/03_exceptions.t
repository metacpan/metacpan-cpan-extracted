#!/usr/bin/perl

use strict;
use Test::More tests => 26;
use File::Spec::Functions qw(catfile curdir catdir rel2abs);
use File::List::Object;
BEGIN {
	$|  = 1;
	$^W = 1;
}


my @file = (
    catfile( rel2abs(curdir()), qw(t test02 file1.txt)),
    catfile( rel2abs(curdir()), qw(t test02 file2.txt)),
    catfile( rel2abs(curdir()), qw(t test02 file3.txt)),
    catfile( rel2abs(curdir()), qw(t test02 excluded file1.txt)),
    catfile( rel2abs(curdir()), qw(t test02 excluded file2.txt)),    
    catfile( rel2abs(curdir()), qw(t test02 dir2 file1.txt)),    # dir2 deliberately does not exist.
    catfile( rel2abs(curdir()), qw(t test02 dir2 file2.txt)),    
    catfile( rel2abs(curdir()), qw(t test02 dir3 file3.txt)),    
);

eval {
	File::List::Object->clone('Bad Parameter');
};

like($@, qr(invalid: source), '->clone catches no parameter' );
isa_ok($@, 'File::List::Object::Exception::Parameter', '->clone returned correct exception class.');

eval {
	File::List::Object->new->readdir(catfile( rel2abs(curdir()), qw(t test02 dir2)));
};

like($@, qr(is not a directory), '->readdir catches non-existent directory' );
isa_ok($@, 'File::List::Object::Exception::Parameter', '->readdir returned correct exception class.');

eval {
	File::List::Object->new->readdir(File::List::Object->new());
};

like($@, qr(invalid: dir), '->readdir catches non-string parameter' );
isa_ok($@, 'File::List::Object::Exception::Parameter', '->readdir returned correct exception class.');

eval {
	File::List::Object->new->load_file($file[5]);
};

like($@, qr(cannot be read), '->load_file catches non-existent file' );
isa_ok($@, 'File::List::Object::Exception::Parameter', '->load_file returned correct exception class.');

eval {
	File::List::Object->new->load_file(File::List::Object->new());
};

like($@, qr(invalid: packlist), '->load_file catches non-string parameter' );
isa_ok($@, 'File::List::Object::Exception::Parameter', '->load_file returned correct exception class.');

eval {
	File::List::Object->new->add_file($file[5]);
};

like($@, qr(is not a file), '->add_file catches non-existent file' );
isa_ok($@, 'File::List::Object::Exception::Parameter', '->add_file returned correct exception class.');

eval {
	File::List::Object->new->add_file(File::List::Object->new());
};

like($@, qr(invalid: file), '->add_file catches non-string parameter' );
isa_ok($@, 'File::List::Object::Exception::Parameter', '->add_file returned correct exception class.');

eval {
	File::List::Object->new->add('Bad Parameter');
};

like($@, qr(invalid: term), '->add catches non-object parameter' );
isa_ok($@, 'File::List::Object::Exception::Parameter', '->add returned correct exception class.');

eval {
	File::List::Object->new->subtract('Bad Parameter');
};

like($@, qr(invalid: subtrahend), '->subtract catches non-object parameter' );
isa_ok($@, 'File::List::Object::Exception::Parameter', '->subtract returned correct exception class.');

eval {
	File::List::Object->new->move(undef, '');
};

like($@, qr(invalid: from), '->move catches non-string 1st parameter' );
isa_ok($@, 'File::List::Object::Exception::Parameter', '->move returned correct exception class.');

eval {
	File::List::Object->new->move('C:', undef);
};

like($@, qr(invalid: to), '->move catches non-string 2nd parameter' );
isa_ok($@, 'File::List::Object::Exception::Parameter', '->move returned correct exception class.');

eval {
	File::List::Object->new->move_dir(undef, '');
};

like($@, qr(invalid: from), '->move_dir catches non-string 1st parameter' );
isa_ok($@, 'File::List::Object::Exception::Parameter', '->move_dir returned correct exception class.');

eval {
	File::List::Object->new->move_dir('C:', undef);
};

like($@, qr(invalid: to), '->move_dir catches non-string 2nd parameter' );
isa_ok($@, 'File::List::Object::Exception::Parameter', '->move_dir returned correct exception class.');
