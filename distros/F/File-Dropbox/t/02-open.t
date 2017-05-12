use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 15;
use File::Dropbox;
use Test::Common ':all';

my $app     = conf();
my $dropbox = File::Dropbox->new(%$app);
my $path    = base();
my $file    = $path. '/'. time;

sub is_closed {
	subtest Closed => sub {
		no warnings 'void';

		eval { tell $dropbox };

		like $@, qr{Tell is not supported on this handle},
			'Tell failed on unopened handle';

		eval { seek $dropbox, 0, SEEK_CUR };

		like $@, qr{Seek is not supported on this handle},
			'Seek failed on unopened handle';

		eval { read $dropbox, $_, 16 };

		like $@, qr{Read is not supported on this handle},
			'Read failed on unopened handle';

		eval { readline $dropbox };

		like $@, qr{Readline is not supported on this handle},
			'Readline failed on unopened handle';

		eval { print $dropbox 'test' };

		like $@, qr{Write is not supported on this handle},
			'Write failed on unopened handle';

		eval { eof $dropbox };

		like $@, qr{Eof is not supported on this handle},
			'Eof failed on unopened handle';

		my $self = *$dropbox{'HASH'};
		ok !$self->{'mode'},     'Mode is not set';
		ok !$self->{'buffer'},   'Buffer is empty';
		ok !$self->{'length'},   'Length is not set';
		ok !$self->{'position'}, 'Position is not set';
		ok $self->{'closed'},    'Closed flag is set';
	};
} # is_closed

SKIP: {

skip 'DROPBOX_AUTH is not set or has wrong value', 14
	unless keys %$app;

is_closed();

# Try to open not existing file for reading
errn { open $dropbox, '<', $file } ENOENT, 'Failed to open not existing file';

is_closed();

# Try to open it for writing
okay { open  $dropbox, '>', $file } 'File opened for writing';

# Try to open directory for reading
errn { open  $dropbox, '<', $path } EISDIR, 'Failed to read directory';

# Open file for reading again
okay { open  $dropbox, '<', $file } 'Empty file created';

# Check end and close
okay { eof   $dropbox } 'File is empty';
okay { close $dropbox } 'File is closed';

} # SKIP

is_closed();
