# Copyrights 2017-2025 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Log-Report-Template. Meta-POD processed
# with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Log::Report::Template::Textdomain;
use vars '$VERSION';
$VERSION = '1.02';

use base 'Log::Report::Domain';

use warnings;
use strict;

use Log::Report 'log-report-template';

use Log::Report::Message ();

use Scalar::Util         qw(weaken);


sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args)->_initMe($args);
}

sub _initMe($)
{	my ($self, $args) = @_;

	if(my $only =  $args->{only_in_directory})
	{	my @only = ref $only eq 'ARRAY' ? @$only : $only;
		my $dirs = join '|', map "\Q$_\E", @only;
		$self->{LRTT_only_in} = qr!^(?:$dirs)(?:$|/)!;
	}

	$self->{LRTT_function} = $args->{translation_function} || 'loc';
	$self->{LRTT_lexicon}  = $args->{lexicon};
	$self->{LRTT_lang}     = $args->{lang};

	$self->{LRTT_templ}    = $args->{templater} or panic "Requires templater";
	weaken $self->{LRTT_templ};

	$self;
}


sub upgrade($%)
{	my ($class, $domain, %args) = @_;

	ref $domain eq 'Log::Report::Domain'
		or error __x"extension to domain '{name}' already exists", name => $domain->name;

	(bless $domain, $class)->_initMe(\%args);
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
	my $context = $service->context;

	# Prepare as much and fast as possible, because it gets called often!
	sub { # called with ($msgid, @positionals, [\%params])
		my $msgid  = shift;
		my $params = @_ && ref $_[-1] eq 'HASH' ? pop @_ : {};
		my $plural = $msgid =~ s/\|(.*)// ? $1 : undef;
		if(defined $plural && ! defined $params->{_count})
		{	@_ or error __x"no counting positional for '{msgid}'", msgid => $msgid;
			$params->{_count} = shift;
		}
		@_ and error __x"superfluous positional parameters for '{msgid}'", msgid => $msgid;

		Log::Report::Message->new(
			_msgid => $msgid, _plural => $plural, _domain => $self,
			%$params, _stash => $context->{STASH}, _expand => 1,
		)->toString($self->lang);
	};
}

sub translationFilter()
{	my $self   = shift;

	# Prepare as much and fast as possible, because it gets called often!
	# A TT filter can be either static or dynamic.  Dynamic filters need to
	# implement a "a factory for static filters": a sub which produces a
	# sub which does the real work.
	sub {
		my $context = shift;
		my $params  = @_ && ref $_[-1] eq 'HASH' ? pop @_ : {};
		$params->{_count} = shift if @_;
		$params->{_error} = 'too many' if @_;   # don't know msgid yet

		sub { # called with $msgid (template container content) only, the
			  # parameters are caught when the factory produces this sub.
			my $msgid  = shift;
			my $plural = $msgid =~ s/\|(.*)// ? $1 : undef;
			defined $plural || ! defined $params->{_count}
				or error __x"message does not contain counting alternatives in '{msgid}'", msgid => $msgid;

			! defined $plural || defined $params->{_count}
				or error __x"no counting positional for '{msgid}'", msgid => $msgid;

			! $params->{_error}
				or error __x"superfluous positional parameters for '{msgid}'", msgid => $msgid;

			Log::Report::Message->new(
				_msgid => $msgid, _plural => $plural, _domain => $self,
				%$params, _stash => $context->{STASH}, _expand => 1,
			)->toString($self->lang);
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
