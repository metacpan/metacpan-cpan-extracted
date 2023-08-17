# Copyright (C) 2016-2023 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This file is distributed under the same terms and conditions as
# Perl itself.

# This next lines is here to make Dist::Zilla happy.
# ABSTRACT: Perl Globstar (double asterisk globbing) and utils

package File::Globstar::Tester;

use strict;

use Test::More;
use File::Temp;
use File::Spec;
use File::Path qw(make_path);

sub new {
	my ($class) = @_;

	my $directory = File::Temp::tempdir(CLEANUP => 1);
	ok chdir $directory, 'chdir temporary directory';

	bless {
		__directory => $directory,
	}, $class;
}

sub directory {
	shift->{__directory};
}

sub createFiles {
	my ($self, @files) = @_;

	foreach my $file (@files) {
		my $path = File::Spec->catfile($self->directory, $file);
		my ($volume, $directory, $filename) = File::Spec->splitpath($path);
		my $dirname = File::Spec->catpath($volume, $directory);
		unless (-e $dirname) {
			make_path(File::Spec->catpath($volume, $directory))
				or ok 0, "created directory part of '$file'";
		}
		open my $fh, '>', $path
			or ok 0, "created file '$file";
	}

	return $self;
}

1;
