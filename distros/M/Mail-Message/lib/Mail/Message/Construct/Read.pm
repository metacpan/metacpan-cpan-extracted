# This code is part of Perl distribution Mail-Message version 3.020.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message;{
our $VERSION = '3.020';
}


use strict;
use warnings;

use Mail::Box::Parser::Lines ();

use Scalar::Util  qw/blessed/;

#--------------------

sub _scalar2lines($)
{	my $lines = [ split /^/, ${$_[0]} ];
#   pop @$lines if @$lines && ! length $lines->[-1];
	$lines;
}

sub read($@)
{	# try avoiding copy of large strings
	my ($class, undef, %args) = @_;
	my $trusted      = exists $args{trusted} ? $args{trusted} : 1;
	my $strip_status = exists $args{strip_status_fields} ? delete $args{strip_status_fields} : 1;
	my $body_type    = $args{body_type};
	my $pclass       = $args{parser_class};

	my $parser;
	my $ref     = ref $_[1];

	if($args{seekable})
	{	$parser = ($pclass // 'Mail::Box::Parser::Perl')
			->new(%args, filename => "file ($ref)", file => $_[1], trusted => $trusted);
	}
	else
	{	my ($source, $lines);
		if(!$ref)
		{	$source = 'scalar';
			$lines  = _scalar2lines \$_[1];
		}
		elsif($ref eq 'SCALAR')
		{	$source = 'ref scalar';
			$lines  = _scalar2lines $_[1];
		}
		elsif($ref eq 'ARRAY')
		{	$source = 'array of lines';
			$lines  = $_[1];
		}
		elsif($ref eq 'GLOB' || (blessed $_[1] && $_[1]->isa('IO::Handle')))
		{	$source = "file ($ref)";
			local $/ = undef;   # slurp
			$lines  = _scalar2lines \$_[1]->getline;
		}
		else
		{	$class->log(ERROR => "Cannot read message from $_[1]/$ref");
			return undef;
		}

		$parser = ($pclass // 'Mail::Box::Parser::Lines')
			->new(%args, source => $source, lines => $lines, trusted => $trusted);

		$body_type = 'Mail::Message::Body::Lines';
	}

	my $self = $class->new(%args);
	$self->readFromParser($parser, $body_type);
	$self->addReport($parser);

	$parser->stop;

	my $head = $self->head;
	$head->get('Message-ID')
		or $head->set('Message-ID' => '<'.$self->messageId.'>');

	$head->delete('Status', 'X-Status')
		if $strip_status;

	$self;
}

1;
