# This code is part of Perl distribution Mail-Message version 4.01.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Replace::MailHeader;{
our $VERSION = '4.01';
}

use parent 'Mail::Message::Head::Complete';

use strict;
use warnings;

use Log::Report   'mail-message', import => [ qw/__x error panic/ ];

#--------------------

sub new(@)
{	my $class = shift;
	unshift @_, 'raw_data' if @_ % 2;
	$class->SUPER::new(@_);
}

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);

	$self->modify($args->{Modify} || $args->{Reformat} || 0);
	$self->fold_length($args->{FoldLength} || 79);
	$self->mail_from($args->{MailFrom} || 'KEEP');
	$self;
}

#--------------------

sub delete($;$)
{	my ($self, $tag) = (shift, shift);
	@_ or return $self->delete($tag);

	my $index   = shift;
	my @fields  = $self->get($tag);
	my ($field) = splice @fields, $index, 1;
	$self->reset($tag, @fields);
	$field;
}


sub add($$)
{	my $self  = shift;
	my $field = $self->add(shift);
	$field->unfoldedBody;
}


sub replace($$;$)
{	my ($self, $tag, $line, $index) = @_;
	$tag //= $line =~ s/^([^:]+)\:\s*// ? $1 : 'MISSING';

	my $field  = Mail::Message::Field::Fast->new($tag, $line);
	my @fields = $self->get($tag);
	$fields[ $index||0 ] = $field;
	$self->reset($tag, @fields);

	$field;
}

#--------------------

sub get($;$)
{	my $head = shift->head;
	my @ret  = map $head->get(@_), @_;

	  wantarray ? (map $_->unfoldedBody, @ret)
	: @ret      ? $ret[0]->unfoldedBody
	:    undef;
}

#--------------------

sub modify(;$)
{	my $self = shift;
	@_ ? ($self->{MH_refold} = shift) : $self->{MH_refold};
}


sub mail_from(;$)
{	my $self = shift;
	@_ or return $self->{MH_mail_from};

	my $choice = uc(shift);
	$choice =~ /^(IGNORE|ERROR|COERCE|KEEP)$/
		or error __x"bad Mail-From choice: '{pick}'.", pick => $choice;

	$self->{MH_mail_from} = $choice;
}


sub fold(;$)
{	my $self = shift;
	my $wrap = @_ ? shift : $self->fold_length;
	$_->setWrapLength($wrap) for $self->orderedFields;
	$self;
}


sub unfold(;$)
{	my $self = shift;
	my @fields = @_ ? $self->get(shift) : $self->orderedFields;
	$_->setWrapLength(100_000) for @fields;  # blunt approach
	$self;
}


sub extract($)
{	my ($self, $lines) = @_;

	my $parser = Mail::Box::Parser::Perl->new(filename => 'extract from array', data => $lines, trusted => 1);
	$self->read($parser);
	$parser->close;

	# Remove header from array
	shift @$lines while @$lines && $lines->[0] != m/^[\r\n]+/;
	shift @$lines if @$lines;
	$self;
}


sub read($)
{	my ($self, $file) = @_;
	my $parser = Mail::Box::Parser::Perl->new(filename => ('from file-handle '.ref $file), file => $file, trusted => 1);
	$self->read($parser);
	$parser->close;
	$self;
}


sub empty() { $_[0]->removeFields( m/^/ ) }


sub header(;$)
{	my $self = shift;
	$self->extract(shift) if @_;
	$self->fold if $self->modify;
	[ $self->orderedFields ];
}


sub header_hashref($) { panic "Don't use header_hashref!!!" }


sub combine($;$) { panic "Don't use combine()!!!" }


sub exists() { $_[0]->count }


sub as_string() { $_[0]->string }


sub fold_length(;$$)
{	my $self = shift;
	@_ or return $self->{MH_wrap};

	my $old  = $self->{MH_wrap};
	my $wrap = $self->{MH_wrap} = shift;
	$self->fold($wrap) if $self->modify;
	$old;
}


sub tags() { $_[0]->names }


sub dup() { $_[0]->clone }


sub cleanup() { $_[0] }

#--------------------

BEGIN
{	no warnings;
	*Mail::Header::new = sub {
		my $class = shift;
		Mail::Message::Replace::MailHeader->new(@_);
	};
}



sub isa($)
{	my ($thing, $class) = @_;
	$class eq 'Mail::Mailer' ? 1 : $thing->SUPER::isa($class);
}


1;
