use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 5;

BEGIN {
	use_ok 'File::Dropbox';
	use_ok 'Test::Common';
}

my $dropbox;

eval { $dropbox = File::Dropbox->new(root => 'frfrbox') };

like $@, qr{Unexpected root value}, 'Root parameter validation';

$dropbox = File::Dropbox->new();

subtest Constructor => sub {
	is ref $dropbox, 'GLOB',
		'Constructor returned GLOB reference';

	isa_ok *$dropbox{'IO'}, 'IO::Handle',
		'GLOB contains IO handle';

	isa_ok *$dropbox{'HASH'}, 'File::Dropbox',
		'GLOB contais tied object';

	is binmode($dropbox), 1, 'Binmode works';
};

subtest Self => sub {
	my $self = *$dropbox{'HASH'};

	isa_ok $self, 'Tie::Handle',
		'Tied object inherits Tie::Handle';

	isa_ok $self, 'Exporter',
		'Tied object inherits Exporter';

	is $self->{'chunk'}, 4 * 1024 * 1024,
		'Chunk size is set';

	is $self->{'root'}, 'sandbox',
		'Root is set';

	is $self->{'mode'}, '',
		'Mode is not set';

	is $self->{'closed'}, 1,
		'Handle is not opened';

	is $self->{'position'}, 0,
		'Handle position is 0';

	is $self->{'length'}, 0,
		'Buffer length is 0';

	is $self->{'buffer'}, '',
		'Buffer is empty';

	can_ok $self, qw{ READ WRITE READLINE SEEK TELL OPEN CLOSE EOF BINMODE contents putfile metadata movefile deletefile createfolder copyfile };

	is_deeply \@File::Dropbox::EXPORT_OK, [qw{ contents metadata putfile movefile copyfile createfolder deletefile }],
		'@EXPORT_OK is set';
};
