# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 22 };
use Image::IPTCInfo::TemplateFile;
ok(1);

my $self;

local *FILE;
open FILE,"TemplateTest1.ipt" or die "Missing file TemplateTest1.ipt";
$self = Image::IPTCInfo::TemplateFile->new(FILE=>*FILE);
ok( Image::IPTCInfo::TemplateFile, ref $self);
ok (5, scalar keys %$self);
ok ($self->{"caption/abstract"}, 'This is the caption.');
ok ($self->{"date created"}, '20030513');
ok ($self->{"credit"}, "Here's the credit.");
ok ($self->{"originating program"}, 'photowebserver');
ok ($self->{"keywords"}->[0], "keyword1");
ok ($self->{"keywords"}->[1], "keyword2");

undef $self;

$self = Image::IPTCInfo::TemplateFile->new(filepath=>'TemplateTest1.ipt');
ok( Image::IPTCInfo::TemplateFile, ref $self);
ok (5, scalar keys %$self);
ok ($self->{"caption/abstract"}, 'This is the caption.');
ok ($self->{"date created"}, '20030513');
ok ($self->{"credit"}, "Here's the credit.");
ok ($self->{"originating program"}, 'photowebserver');
ok ($self->{"keywords"}->[0], "keyword1");
ok ($self->{"keywords"}->[1], "keyword2");

undef $self;

$self = Image::IPTCInfo::TemplateFile->new(filepath=>'TemplateBlank.ipt');
ok( Image::IPTCInfo::TemplateFile, ref $self);
ok (0, scalar keys %$self);

$self = Image::IPTCInfo::TemplateFile->new(
	'caption/abstract' => 'This is the caption',
);

{
	local *IN;
	ok(1,open IN, "ThisIsTheCaption.ipt");
	my $fileblob;
	read IN,$fileblob, -s IN;
	close IN;
	ok (length $fileblob, 31);
	my $blob = $self->as_blob;
	ok($blob,$fileblob);
}


exit;