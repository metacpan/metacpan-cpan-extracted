package HTML::HTML5::Parser::Error;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.301';

use overload '""' => \&to_string;

sub new
{
	my ($class, %args) = @_;
	bless \%args, $class;
}

sub level
{
	my $self = shift;
	return {
		m     => 'MUST',
		s     => 'SHOULD',
		w     => 'WARN',
		i     => 'INFO',
		u     => undef,
		}->{$self->{level}} || undef;
}

sub layer
{
	my $self = shift;
	return $self->{layer} || undef;
}

sub type
{
	my $self = shift;
	return $self->{type}||undef;
}

sub tag_name
{
	my $self = shift;
	return undef unless $self->{token} && exists $self->{token}{tag_name};
	return $self->{token}{tag_name};
}

sub source_line
{
	my $self = shift;
	
	if (wantarray)
	{
		return ($self->{line}, $self->{column});
	}
	else
	{
		return $self->{line};
	}
}

sub to_string
{
	my $self = shift;
	
	my $msg     = $self->type;
	my $level   = $self->level;
	my $tag     = $self->tag_name;
	my ($l, $c) = $self->source_line;

	my @details;
	push @details, sprintf('complicance: %s', $level) if defined $level;
	push @details, sprintf('line: %d', $l) if defined $l;
	push @details, sprintf('column: %d', $c) if defined $c;
	push @details, sprintf('tag: %s', $tag) if defined $tag;

	if (@details)
	{
		$msg .= " [";
		$msg .= join '; ', @details;
		$msg .= "]";
	}
	
	return $msg;
}

1;

=head1 NAME

HTML::HTML5::Parser::Error - an error that occurred during parsing

=head1 DESCRIPTION

The C<error_handler> and C<errors> methods of C<HTML::HTML5::Parser> generate
C<HTML::HTML5::Parser::Error> objects.

C<HTML::HTML5::Parser::Error> overloads stringification, so can be printed,
matched against regular expressions, etc.

Note that L<HTML::HTML5::Parser> is not a validation tool, and there are many
classes of error that it does not care about, so will not raise.

=head2 Constructor

=over

=item C<< new(level=>$level, type=>$type, token=>$token, ...) >>

Constructs a new C<HTML::HTML5::Parser::Error> object.

=back

=head2 Methods

=over

=item C<level>

Returns the level of error. ('MUST', 'SHOULD', 'WARN', 'INFO' or undef.)

=item C<layer>

Returns the parsing layer involved, often undef. e.g. 'encode'.

=item C<type>

Returns the type of error as a string.

=item C<tag_name>

Returns the tag name (if any).

=item C<source_line>

  ($line, $col) = $error->source_line();
  $line = $error->source_line;
  
In scalar context, C<source_line> returns the line number of the
source code that triggered the error.

In list context, returns a line/column pair. (Tab characters count as
one column, not eight.)

=item C<to_string>

Returns a friendly error string.

=back

=head1 SEE ALSO

L<HTML::HTML5::Parser>.

=head1 AUTHOR

Toby Inkster, E<lt>tobyink@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2012 by Toby Inkster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

