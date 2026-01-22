# This code is part of Perl distribution Mail-Message version 4.02.
# The POD got stripped from this file by OODoc version 3.06.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2026 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message;{
our $VERSION = '4.02';
}


use strict;
use warnings;

use Log::Report   'mail-message', import => [ qw/__x error warning/ ];

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
		{	error __x"cannot read message from a {source}.", source => $_[1]/$ref;
			return undef;
		}

		$parser = ($pclass // 'Mail::Box::Parser::Lines')
			->new(%args, source => $source, lines => $lines, trusted => $trusted);

		$body_type = 'Mail::Message::Body::Lines';
	}

	my $self = $class->new(%args);
	$self->readFromParser($parser, $body_type);
	$parser->stop;

	my $head = $self->head;
	$head->set('Message-ID' => '<'.$self->messageId.'>') unless $head->get('Message-ID');

	$head->delete('Status', 'X-Status')
		if $strip_status;

	$self;
}

1;
