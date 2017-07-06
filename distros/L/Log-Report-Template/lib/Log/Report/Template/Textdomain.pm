# Copyrights 2017 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package Log::Report::Template::Textdomain;
use vars '$VERSION';
$VERSION = '0.12';

use base 'Log::Report::Domain';

use Log::Report 'log-report-template';

use Log::Report::Message ();


sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);

    if(my $only =  $args->{only_in_directory})
    {   my @only = ref $only eq 'ARRAY' ? @$only : $only;
    	my $dirs = join '|', map "\Q$_\E", @only;
        $self->{LRTT_only_in} = qr!^(?:$dirs)(?:$|/)!;
    }

    $self->{LRTT_function} = $args->{translation_function} || 'loc';
    my $lexicon = $self->{LRTT_lexicon}  = $args->{lexicon};
    $self;
}

#----------------

sub function() { shift->{LRTT_function} }


sub lexicon() { shift->{LRTT_lexicon} }


sub expectedIn($)
{   my ($self, $fn) = @_;
    my $only = $self->{LRTT_only_in} or return 1;
    $fn =~ $only;
}

#----------------

sub translationFunction($)
{	my ($self, $service) = @_;
my $lang = 'NL';

    # Prepare as much and fast as possible, because it gets called often!
    sub { # called with ($msgid, \%params)
        $_[1]->{_stash} = $service->{CONTEXT}{STASH};
        Log::Report::Message->fromTemplateToolkit($self, @_)->toString($lang);
    };
}

sub translationFilter()
{	my $self   = shift;
    my $domain = $self->name;
my $lang = 'NL';

    # Prepare as much and fast as possible, because it gets called often!
    # A TT filter can be either static or dynamic.  Dynamic filters need to
    # implement a "a factory for static filters": a sub which produces a
    # sub which does the real work.
    sub {
        my $context = shift;
    	my $pairs   = pop if @_ && ref $_[-1] eq 'HASH';
        sub { # called with $msgid (template container content) only, the
              # parameters are caught when the factory produces this sub.
             $pairs->{_stash} = $context->{STASH};
             Log::Report::Message->fromTemplateToolkit($self, $_[0], $pairs)
                ->toString($lang);
        }
    };
}

sub _reportMissingKey($$)
{   my ($self, $sp, $key, $args) = @_;

    # Try to grab the value from the stash.  That's a major advantange
    # of TT over plain Perl: we have access to the variable namespace.

    my $stash = $args->{_stash};
    if($stash)
    {   my $value = $stash->get($key);
        return $value if defined $value && length $value;
    }

    warning
      __x"Missing key '{key}' in format '{format}', in {use //template}"
      , key => $key, format => $args->{_format}
      , use => $stash->{template}{name};

    undef;
}

1;
