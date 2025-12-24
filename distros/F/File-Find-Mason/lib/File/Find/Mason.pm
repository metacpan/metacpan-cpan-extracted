package File::Find::Mason;

use strict;
use warnings;
use File::Find qw//;

our $VERSION='0.0.7';

my %default=(
	verbose    =>0,
	shebang    =>1,
	args       =>1,
	once       =>1,
	perl       =>1,
	call       =>1,
	modeline   =>1,
);

my %pattern=(
	shebang    =>qr/^#!.*\w/,
	args       =>qr/^<%args>/,
	once       =>qr/^<%once>/,
	perl       =>qr/^<%perl>/,
	call       =>qr/^<&.*&>/,
	modeline   =>qr/^% *#.*mason/,
);

my $optpattern=join('|',keys %default);

sub find {
	my ($options,@dirs)=@_;
	my %findopt;
	foreach my $k (grep {!/^(?:$optpattern)$/} keys(%$options)) { $findopt{$k}=$$options{$k} }
	if($$options{wanted}) {
		my $cb=$$options{wanted};
		File::Find::find({%findopt, no_chdir=>1, wanted=>sub {
			if(-d $File::Find::name) { return }
			if(wanted($options,$File::Find::name)) { &$cb() }
		} },@dirs);
	}
	else {
		my @res;
		File::Find::find({%findopt, no_chdir=>1, wanted=>sub {
			if(-d $File::Find::name) { return }
			if(wanted($options,$File::Find::name)) { push @res,$File::Find::name }
		} },@dirs);
		return @res;
	}
}

sub wanted {
	my ($options,$fn)=@_;
	my %opt=(%default,%$options);
	if(!-e $fn) { if($opt{verbose}) { print STDERR "File not found:  $fn\n" }; return }
	if(!-r $fn) { if($opt{verbose}) { print STDERR "Unable to read:  $fn\n" }; return }
	my ($fh,$txt);
	if(!open($fh,'<',$fn)) { if($opt{verbose}) { print STDERR "Unable to read:  $fn\n" }; return }
	{local($/); $txt=<$fh>}
	close($fh);
	if(!$txt) {
		if($opt{verbose}) { print STDERR "No content for $fn\n" }
		return 0;
	}
	foreach my $k (grep {$opt{$_}&&$pattern{$_}} keys(%default)) {
		if($k eq 'shebang') { if($txt=~$pattern{$k}) { return 0 } }
		if($txt=~$pattern{$k}) {
			if($opt{wanted}) { return &{$opt{wanted}}($fn) }
			else             { return 1 }
		}
	}
	return 0;
}

1;

__END__

=pod

=head1 NAME

File::Find::Mason - Find files that contain Mason components

=head1 VERSION

Version 0.0.7

=head1 SYNOPSIS

	use File::Find::Mason;
	
	my @files = File::Find::Mason::find(\%options, @directories);
	my $is_mason = File::Find::Mason::wanted(\%options, $filename);

=head1 DESCRIPTION

Mason templates may have multiple extensions depending on their use, particularly for HTTP APIs.  Some Mason templates may be very brief and contain only static HTML, whereas others may contain only a single Mason component or comment indicating their purpose.  This module should aide quickly finding all or some such Mason file.

=head2 Basic usage

Usage follows the patterns of L<File::Find>.

=over

=item C<File::Find::Mason::find(\%options, @directories)>

When provided with no C<wanted> option, C<find()> searches the given C<directories> using C<File::Find::find> for Mason-like files and I<returns them> as a list.  If a C<wanted> callback is provided in C<%options>, it is invoked for every matching file.

The C<%options> are passed directly to C<File::Find::find> except for the C<wanted> handler.

=item C<File::Find::Mason::wanted(\%options, $filename)>

When provided with no C<$options{wanted}>, the function will return true when C<$filename> is a Mason file, based on the options passed for detection.  If a C<wanted> function is passed with the options, it will be invoked as a callback for every matching filename.

=back

=head2 Mason file identification

A file is consider a valid Mason file when:

=over

=item * There is no shebang line.

=item * The file contains one of the configured Mason components (default C<%args, %once, %perl>).

=item * The file contains a balanced component call line of the form C<E<lt>&.*&E<gt>>.

=item * The file contains a terminal modeline of the form C<%#.*mason>.

=back

=head2 Options

The following options are supported.

=over

=item wanted

When provided to C<wanted>, this should be a callback of the form C<function(filename)>.

When provided to C<find>, this can be a standard L<File::Find> wanted function using C<$File::Find::name> and other variables as provided.

=item args

=item once

=item perl

=item call

Enabled by default, any of these can be set to false to prevent matching a file with the equivalent Mason component, of the form C<E<lt>%argsE<gt>> etcetera.

=item shebang

By default, C<shebang> matching skips any file with a shebang line.  If false, shebang skipping is disabled.

=item modeline

When true, C<modeline> enables matching of a vim-style modeline, namely a Mason-comment line containing a Perl comment character (#) and the string C<mason>.  The line can appear anywhere in the file.

=item verbose

If files are not found or not readable, an error will be given when C<verbose> is true.

=back

=head1 BUGS

=over

=item * Shebangs/modelines match the beginning of the line anywhere in the file.

=back

=head1 COPYRIGHT

Copyright (C) 2025 by MediaAlpha.  All rights reserved.

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

=head1 DISCLAIMER

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

=cut
