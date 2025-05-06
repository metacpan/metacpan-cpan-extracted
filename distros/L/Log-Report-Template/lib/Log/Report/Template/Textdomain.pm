# Copyrights 2017-2025 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Log-Report-Template. Meta-POD processed
# with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Log::Report::Template::Textdomain;{
our $VERSION = '1.00';
}

use base 'Log::Report::Domain';

use warnings;
use strict;

use Log::Report 'log-report-template';

use Log::Report::Message ();
use Scalar::Util qw(weaken);


sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);

	if(my $only =  $args->{only_in_directory})
	{	my @only = ref $only eq 'ARRAY' ? @$only : $only;
		my $dirs = join '|', map "\Q$_\E", @only;
		$self->{LRTT_only_in} = qr!^(?:$dirs)(?:$|/)!;
	}

	$self->{LRTT_function} = $args->{translation_function} || 'loc';
	$self->{LRTT_lexicon}  = $args->{lexicon};

	$self->{LRTT_templ}    = $args->{templater} or panic;
	weaken $self->{LRTT_templ};

	$self;
}

#----------------

sub templater() { $_[0]->{LRTT_templ} }


sub function() { $_[0]->{LRTT_function} }


sub lexicon() { $_[0]->{LRTT_lexicon} }


sub expectedIn($)
{	my ($self, $fn) = @_;
	my $only = $self->{LRTT_only_in} or return 1;
	$fn =~ $only;
}


sub lang() { $_[0]->{LRTT_lang} }

#----------------

sub translateTo($)
{	my ($self, $lang) = @_;
	$self->{LRTT_lang} = $lang;
}


sub translationFunction($)
{	my ($self, $service) = @_;

	# Prepare as much and fast as possible, because it gets called often!
	sub { # called with ($msgid, \%params)
		$_[1]->{_stash} = $service->{CONTEXT}{STASH};
		Log::Report::Message->fromTemplateToolkit($self, @_)->toString($self->lang);
	};
}

sub translationFilter()
{	my $self   = shift;
	my $domain = $self->name;

	# Prepare as much and fast as possible, because it gets called often!
	# A TT filter can be either static or dynamic.  Dynamic filters need to
	# implement a "a factory for static filters": a sub which produces a
	# sub which does the real work.
	sub {
		my $context = shift;
		my $pairs   = pop if @_ && ref $_[-1] eq 'HASH';
		sub { # called with $msgid (template container content) only, the
			  # parameters are caught when the factory produces this sub.
			$pairs->{_stash}  = $context->{STASH};
			Log::Report::Message->fromTemplateToolkit($self, $_[0], $pairs)->toString($self->lang);
		}
	};
}

sub _reportMissingKey($$)
{	my ($self, $sp, $key, $args) = @_;

	# Try to grab the value from the stash.  That's a major advantange
	# of TT over plain Perl: we have access to the variable namespace.

	my $stash = $args->{_stash};
	if($stash)
	{	my $value = $stash->get($key);
		return $value if defined $value && length $value;
	}

	warning __x"Missing key '{key}' in format '{format}', in {use //template}",
		key => $key, format => $args->{_format},
		use => $stash->{template}{name};

	undef;
}

1;
