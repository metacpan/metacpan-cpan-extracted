# This code is part of Perl distribution Log-Report version 1.41.
# The POD got stripped from this file by OODoc version 3.04.
# For contributors see file ChangeLog.

# This software is copyright (c) 2007-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

package Log::Report::Message;{
our $VERSION = '1.41';
}


use warnings;
use strict;

use Log::Report 'log-report';
use POSIX             qw/locale_h/;
use List::Util        qw/first/;
use Scalar::Util      qw/blessed/;

use Log::Report::Util qw/to_html/;

# Work-around for missing LC_MESSAGES on old Perls and Windows
{	no warnings;
	eval "&LC_MESSAGES";
	*LC_MESSAGES = sub(){5} if $@;
}

#--------------------

use overload
	'""'  => 'toString',
	'&{}' => sub { my $obj = shift; sub{$obj->clone(@_)} },
	'.'   => 'concat',
	fallback => 1;

#--------------------

sub new($@)
{	my ($class, %s) = @_;

	if(ref $s{_count})
	{	my $c        = $s{_count};
		$s{_count}   = ref $c eq 'ARRAY' ? @$c : keys %$c;
	}

	defined $s{_join}
		or $s{_join} = $";

	if($s{_msgid})
	{	$s{_append}  = defined $s{_append} ? $1.$s{_append} : $1
			if $s{_msgid} =~ s/(\s+)$//s;

		$s{_prepend}.= $1
			if $s{_msgid} =~ s/^(\s+)//s;
	}
	if($s{_plural})
	{	s/\s+$//, s/^\s+// for $s{_plural};
	}

	bless \%s, $class;
}

# internal use only: to simplify __*p* functions
sub _msgctxt($) {$_[0]->{_msgctxt} = $_[1]; $_[0]}


sub clone(@)
{	my $self = shift;
	(ref $self)->new(%$self, @_);
}

#--------------------

sub prepend() { $_[0]->{_prepend}}
sub msgid()   { $_[0]->{_msgid}  }
sub append()  { $_[0]->{_append} }
sub domain()  { $_[0]->{_domain} }
sub count()   { $_[0]->{_count}  }
sub context() { $_[0]->{_context}}
sub msgctxt() { $_[0]->{_msgctxt}}


sub classes()
{	my $class = $_[0]->{_class} || $_[0]->{_classes} || [];
	ref $class ? @$class : split(/[\s,]+/, $class);
}


sub to(;$)
{	my $self = shift;
	@_ ? $self->{_to} = shift : $self->{_to};
}


sub errno(;$)
{	my $self = shift;
	@_ ? $self->{_errno} = shift : $self->{_errno};
}


sub valueOf($) { $_[0]->{$_[1]} }

#--------------------

sub inClass($)
{	my @classes = shift->classes;
	ref $_[0] eq 'Regexp' ? (first { $_ =~ $_[0] } @classes) : (first { $_ eq $_[0] } @classes);
}


sub toString(;$)
{	my ($self, $locale) = @_;

	my $count   = $self->{_count} || 0;
	$locale     = $self->{_lang} if $self->{_lang};
	my $prepend = $self->{_prepend} // '';
	my $append  = $self->{_append}  // '';

	$prepend = $prepend->isa(__PACKAGE__) ? $prepend->toString($locale) : "$prepend"
		if blessed $prepend;

	$append  = $append->isa(__PACKAGE__)  ? $append->toString($locale)  : "$append"
		if blessed $append;

	$self->{_msgid}   # no translation, constant string
		or return "$prepend$append";

	# assumed is that switching locales is expensive
	my $oldloc = setlocale(LC_MESSAGES);
	setlocale(LC_MESSAGES, $locale)
		if defined $locale && (!defined $oldloc || $locale ne $oldloc);

	# translate the msgid
	my $domain = $self->{_domain};
	blessed $domain && $domain->isa('Log::Report::Minimal::Domain')
		or $domain = textdomain $domain;

	my $format = $domain->translate($self, $locale || $oldloc);
	defined $format or return ();

	# fill-in the fields
	my $text = $self->{_expand} ? $domain->interpolate($format, $self) : "$prepend$format$append";

	setlocale(LC_MESSAGES, $oldloc)
		if defined $oldloc && (!defined $locale || $oldloc ne $locale);

	$text;
}



my %tohtml = qw/  > gt   < lt   " quot  & amp /;

sub toHTML(;$) { to_html($_[0]->toString($_[1])) }


sub untranslated()
{	my $self = shift;
	  (defined $self->{_prepend} ? $self->{_prepend} : '')
	. (defined $self->{_msgid}   ? $self->{_msgid}   : '')
	. (defined $self->{_append}  ? $self->{_append}  : '');
}


sub concat($;$)
{	my ($self, $what, $reversed) = @_;
	if($reversed)
	{	$what .= $self->{_prepend} if defined $self->{_prepend};
		return ref($self)->new(%$self, _prepend => $what);
	}

	$what = $self->{_append} . $what if defined $self->{_append};
	ref($self)->new(%$self, _append => $what);
}

#--------------------

1;
