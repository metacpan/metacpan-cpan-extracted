package File::Tudo;
use 5.016;
our $VERSION = '0.02';
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(default_todo tudo);

use Carp;
use File::Spec;

use File::HomeDir;

sub default_todo {
	$ENV{TODO_FILE} // File::Spec->catfile(File::HomeDir->my_home, 'TODO');
}

sub new {

	my $class = shift;
	my $path  = shift // default_todo;
	my $param = shift // {};

	my $read = $param->{read} // 1;

	my $self = {
		Path => $path,
		Todo => [],
	};

	bless $self, $class;

	if ($read and -s $self->{Path}) {
		$self->read($self->{Path});
	}

	return $self;

}

sub path {

	my $self = shift;
	my $path = shift;

	unless (defined $path) {
		return $self->{Path};
	}

	$self->{Path} = $path;

}

sub todo {

	my $self = shift;
	my $todo = shift;

	unless (defined $todo) {
		return $self->{Todo};
	}

	unless (ref $todo eq 'ARRAY') {
		croak "todo() expects an array reference as argument";
	}

	$self->{Todo} = $todo;

}

sub read {

	my $self = shift;
	my $path = shift;

	my @todo;
	my $str = '';

	open my $fh, '<', $path
		or croak "Failed to open $path for reading: $!";

	while (my $l = readline $fh) {

		chomp $l;

		if ($l eq '--') {
			chomp $str;
			push @todo, $str;
			$str = '';
		} else {
			$str .= $l . "\n";
		}

	}

	close $fh;

	$self->{Todo} = \@todo;

}

sub write {

	my $self = shift;
	my $path = shift // $self->{Path};

	open my $fh, '>', $path
		or croak "Failed to open $path for writing: $!";

	for my $i (0 .. $#{$self->{Todo}}) {

		my $todo = $self->{Todo}->[$i];

		if ($todo =~ /(^|\n)--($|\n)/) {
			croak "todo[$i] cannot contain a '--' line";
		}

		say { $fh } $todo;
		say { $fh } '--';

	}

	return 1;

}

sub tudo {

	my $str  = shift;
	my $path = shift // default_todo;

	my $tudo = File::Tudo->new($path);

	my @new = @{$tudo->todo};

	push @new, $str;

	$tudo->todo(\@new);

	$tudo->write;

}

1;

=head1 NAME

File::Tudo - Tudo TODO file interface

=head1 SYNOPSIS

  use File::Tudo qw(tudo);

  # Simple convenience wrapper, useful for quick scripts
  tudo("Fix that one issue");

  # OO interface
  my $tudo = File::Tudo.new('/path/to/TODO');
  $tudo->todo([ 'New TODO list' ]);
  $tudo->write;

=head1 DESCRIPTION

File::Tudo is a Perl module for reading/writing simple TODO files. It is a port
of a Raku (Perl 6) module of the same name.

=head2 Subroutines

The following subroutines can be imported.

=head3 tudo($str, [ $path ])

C<tudo()> is a simple convenience wrapper for File::Tudo that appends an
additional entry to the end of your TODO file. This can make it useful for
reporting TODOs from your Perl scripts.

  my @updates = get_package_updates(@pkgs);

  tudo("There are updates that need taken care of!") if @updates;

C<$str> is the string you would like to add as an entry to your TODO file.

C<$path> is an optional argument that lets you specify the path to your TODO
file. If C<$path> is not given, defaults to the return value of
C<default_todo()>.

=head3 default_todo()

C<default_todo()> returns the default path for your TODO file. It will either be
the path specified by the C<TODO_FILE> environment variable if set, or
C<~/TODO> otherwise.

=head2 Object-Oriented Interface

=head3 Methods

=head4 new([ $path, [ $params ] ])

Returns a blessed File::Tudo object.

C<$path> is the path to the TODO file. If not specified, defaults to the
return value of C<default_todo()>.

C<$params> is a hash ref of various parameters.

=over 4

=item read

Boolean determining whether C<new()> will initialize its C<todo> array from the
TODO entries found in the C<$path>, or ignore them and initialize C<todo> with
an empty array.

Defaults to true.

=back

=head4 path([ $path ])

Setter/getter method for the object's path attribute. The path will be the path
that C<write()> will write to by default. Is intially set by the C<$path>
supplied in C<new()>.

=head4 todo([ $todo ])

Setter/getter method for the object's C<todo> attribute. C<todo> is an array
ref of TODOs.

=head4 read($path)

Reads a list of TODOs from C<$path>, overwriting the current array in C<todo>.

=head4 write([ $path ])

Write list of TODOs in C<todo> to C<$path>, if specified, or the path in the
C<path> attribute otherwise.

=head1 ENVIRONMENT

=over 4

=item TODO_FILE

Default path to TODO file.

=back

=head1 AUTHOR

Written by Samuel Young, E<lt>samyoung12788@gmail.comE<gt>.

=head1 BUGS

Don't be ridiculous...

Report bugs on my Codeberg, L<https://codeberg.org/1-1sam>.

=head1 COPYRIGHT

Copyright 2025, Samuel Young

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

=head1 SEE ALSO

L<perl-tudo>

=cut
