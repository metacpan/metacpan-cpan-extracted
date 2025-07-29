# Copyrights 2017-2025 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Log-Report-Template. Meta-POD processed
# with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

#!!! This code is  of
# to use Log::Report::Template instead of (Template Toolkit's) Template module.
# Follow issue https://github.com/PerlDancer/Dancer2/issues/1722 to see whether
# this module can be removd.

package Dancer2::Template::TTLogReport;
use vars '$VERSION';
$VERSION = '1.02';


#XXX rework of Dancer2::Template::TemplateToolkit 1.1.2

use Moo;
use Dancer2::Core::Types;
use Dancer2::FileUtils qw<path>;
use Scalar::Util qw<weaken>;
use Log::Report::Template ();
use Log::Report::Util     qw(parse_locale);

with 'Dancer2::Core::Role::Template';


sub _build_engine { $_[0]->tt; $_[0] }


has tt => ( is => 'rw', isa => InstanceOf ['Template'], builder => 1 );

sub _build_tt {
	my $self	  = shift;
	my %config	  = %{$self->config};
	my $charset   = $self->charset;
	my $templater = delete $config{templater}  || 'Log::Report::Template';

	$Template::Stash::PRIVATE = undef if delete $config{show_private_variables};

	weaken(my $ttt = $self);
	my $include_path = delete $config{include_path};

	$templater->new(
		ANYCASE   => 1,
		ABSOLUTE  => 1,
		START_TAG => delete $config{start_tag} || '\[\%',
		END_TAG   => delete $config{end_tag}   || delete $config{stop_tag} || '\%\]',
		INCLUDE_PATH => [ (defined $include_path ? $include_path : ()), sub { [ $ttt->views ] } ],
		(length $charset) ? (ENCODING => $charset) : (),
		%config,
	);
}

#-----------

sub addTextdomain(%) {
	my $self = shift;
	$self->tt->addTextdomain(@_);
}


sub render($$) {
	my ($self, $template, $tokens) = @_;
	my $content = '';
	my $charset = $self->charset;
	my @options = (length $charset) ? (binmode => ":encoding($charset)") : ();
	my $tt      = $self->tt;

	if(my $lang = $tokens->{translate_to}) {
		$tt->translateTo($lang);
	}

	local $tokens->{locale} = my $locale = $tt->translateTo || '';
	my ($lang, $terr) = parse_locale $locale;
	local $tokens->{language} = $lang // '';
	local $tokens->{language_territory} = defined $lang && defined $terr ? $lang . '_' . $terr : '';

	$tt->process($template, $tokens, \$content, @options)
		or $self->log_cb->(core => 'Failed to render template: ' . $tt->error);

	$content;
}

#### The next is reworked from Dancer2::Template::TemplateToolkit.  No idea
#### whether it is reasonable.

# Override *_pathname methods from Dancer2::Core::Role::Template
# Let TT2 do the concatenation of paths to template names.
#
# TT2 will look in a its INCLUDE_PATH for templates.
# Typically $self->views is an absolute path, and we set ABSOLUTE => 1 above.
# In that case TT2 does NOT iterate through what is set for INCLUDE_PATH
# However, if its not absolute, we want to allow TT2 iterate through the
# its INCLUDE_PATH, which we set to be $self->views.

sub view_pathname($) {
	my ($self, $view) = @_;
	$self->_template_name($view);
}

sub layout_pathname($) {
	my ($self, $layout) = @_;
	path($self->layout_dir, $self->_template_name($layout));
}

sub pathname_exists($) {
	my ($self, $pathname) = @_;

	# dies if pathname can not be found via TT2's INCLUDE_PATH search
	my $exists = eval { $self->engine->service->context->template($pathname); 1 };
	$exists or $self->log_cb->(debug => $@);

	$exists;
}

1;

__END__


