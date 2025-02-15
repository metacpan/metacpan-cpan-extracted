package EBook::Ishmael::EBook::Skeleton;
use 5.016;
our $VERSION = '0.04';
use strict;
use warnings;

use EBook::Ishmael::EBook::Metadata;

#     ,--.
#    ([ oo]
#     `- ^\
#   _  I`-'
# ,o(`-V'
# |( `-H-'
# |(`--A-'
# |(`-/_\'\
# O `'I ``\\
# (\  I    |\,
#  \\-T-"`, |H   Ojo
#
# Skeleton module used for creating new ebook modules.

# Subroutine that takes an ebook as argument and returns a bool determining
# whether the ebook is of this package's format or not.
sub heuristic {

	my $class = shift;
	my $file  = shift;

	# ...

	return 0;

}

# Ebook object constructor. Must take ebook path as argument.
sub new {

	my $class = shift;
	my $file  = shift;

	my $self = {
		Source   => undef,
		Metadata => EBook::Ishmael::EBook::Metadata->new,
	};

	bless $self, $class;

	# ...

	return $self;

}

# Method that converts the ebook object's contents to HTML. If given a file
# path as argument, writes HTML to given file. If given no arguments, returns
# string of converted HTML.
sub html {

	my $self = shift;
	my $out  = shift;

	my $html = '';

	open my $fh, '>', $out // \$html
		or die sprintf "Failed to open %s for writing: $!\n", $out // 'in-memory scalar';

	# ...

	return $out // $html;

}

# Returns hash ref of ebook object metadata.
sub metadata {

	my $self = shift;

	return $self->{Metadata}->hash;

}

1;

=head1 NAME

EBook::Ishmael::EBook::Skeleton - Skeleton module for creating ebook modules

=head1 DESCRIPTION

B<EBook::Ishmael::EBook::Skeleton> is a skeleton module that is used to base
new ebook format modules off of. For L<ishmael> user documentation, you should
consult its manual (this is developer documentation).

This page will describe what is required of an L<ishmael> ebook format module.

New ebook modules should be located in the C<EBook::Ishmael::EBook> namespace.

=head1 METHODS

An ebook module must have the following methods:

=head2 $bool = EBook::Ishmael::EBook::???->heuristic($file)

An ebook module should have a class method that determines whether a given
file is its ebook format or not. This is so that L<EBook::Ishmael::EBook> can
use it to automatically determine whether a given file is of the module's
format or not. It should take a single file as argument.

=head2 $obj = EBook::Ishmael::EBook::???->new($file)

The constructor method should be named C<new()> and take a single file as
argument. It should return a blessed ebook object, and at the very minimum
have a C<Source> field (absolute path to C<$file>) and a C<Metadata> field
(an L<Ebook::Ishmael::EBook::Metadata> object).

=head2 $html = $obj->html()

Should return the HTML-ified contents of the ebook's text. It should not take
any arguments.

=head2 $meta = $obj->metadata()

Should have an accessor method for the C<Metadata> hash ref.

=head1 AUTHOR

Written by Samuel Young, E<lt>samyoung12788@gmail.comE<gt>.

This project's source can be found on its
L<Codeberg Page|https://codeberg.org/1-1sam/ishmael>. Comments and pull
requests are welcome!

=head1 COPYRIGHT

Copyright (C) 2025 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=head1 SEE ALSO

L<EBook::Ishmael::EBook>

=cut
