# Copyrights 2007-2018 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Log-Report-Lexicon. Meta-POD processed
# with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Log::Report::Extract::Template;
use vars '$VERSION';
$VERSION = '1.10';

use base 'Log::Report::Extract';

use warnings;
use strict;

use Log::Report 'log-report-lexicon';


sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);
    $self->{LRET_domain}  = $args->{domain}
        or error "template extract requires explicit domain";

    $self->{LRET_pattern} = $args->{pattern};
    $self;
}

#----------

sub domain()  {shift->{LRET_domain}}
sub pattern() {shift->{LRET_pattern}}

#----------

sub process($@)
{   my ($self, $fn, %opts) = @_;

    my $charset = $opts{charset} || 'utf-8';
    info __x"processing file {fn} in {charset}", fn=> $fn, charset => $charset;

    my $pattern = $opts{pattern} || $self->pattern
        or error __"need pattern to scan for, either via new() or process()";

    # Slurp the whole file
    local *IN;
    open IN, "<:encoding($charset)", $fn
        or fault __x"cannot read template from {fn}", fn => $fn;

    undef $/;
    my $text = <IN>;
    close IN;

    my $domain  = $self->domain;
    $self->_reset($domain, $fn);

    if(ref $pattern eq 'CODE')
    {   return $pattern->($fn, \$text);
    }
    elsif($pattern =~ m/^TT([12])-(\w+)$/)
    {   return $self->scanTemplateToolkit($1, $2, $fn, \$text);
    }
    else
    {   error __x"unknown pattern {pattern}", pattern => $pattern;
    }
    ();
}

sub _no_escapes_in($$$$)
{   my ($msgid, $plural, $fn, $linenr) = @_;
    return if $msgid !~ /\&\w+\;/
           && (defined $plural ? $plural !~ /\&\w+\;/ : 1);
	$msgid .= "|$plural" if defined $plural;

    warning __x"msgid '{msgid}' contains html escapes, don't do that.  File {fn} line {linenr}"
       , msgid => $msgid, fn => $fn, linenr => $linenr;
}

sub scanTemplateToolkit($$$$)
{   my ($self, $version, $function, $fn, $textref) = @_;

    # Split the whole file on the pattern in four fragments per match:
    #       (text, leading, needed trailing, text, leading, ...)
    # f.i.  ('', '[% loc("', 'some-msgid', '", params) %]', ' more text')
    my @frags = $version==1
      ? split(/[\[%]%(.*?)%[%\]]/s, $$textref)
      : split(/\[%(.*?)%\]/s, $$textref);

    my $domain     = $self->domain;
    my $linenr     = 1;
    my $msgs_found = 0;

    # pre-compile the regexes, for performance
    my $pipe_func_block  = qr/^\s*\|\s*$function\b/;
    my $msgid_pipe_func  = qr/^\s*(["'])([^\r\n]+?)\1\s*\|\s*$function\b/;
    my $func_msgid_multi = qr/(\b$function\s*\(\s*)(["'])([^\r\n]+?)\2/s;

    while(@frags > 2)
    {   my ($skip_text, $take) = (shift @frags, shift @frags);
        $linenr += $skip_text =~ tr/\n//;
        if($take =~ $pipe_func_block)
        {   # [% | loc(...) %] $msgid [%END%]
            if(@frags < 2 || $frags[1] !~ /^\s*END\s*$/)
            {   error __x"template syntax error, no END in {fn} line {line}"
                  , fn => $fn, line => $linenr;
            }
            my $msgid  = $frags[0];  # next content
            my $plural = $msgid =~ s/\|(.*)// ? $1 : undef;
			_no_escapes_in $msgid, $plural, $fn, $linenr;

            $self->store($domain, $fn, $linenr, $msgid, $plural);
            $msgs_found++;

            $linenr   += $take =~ tr/\n//;
            next;
        }

        if($take =~ $msgid_pipe_func)
        {   # [% $msgid | loc(...) %]
            my $msgid  = $2;
            my $plural = $msgid =~ s/\|(.*)// ? $1 : undef;
			_no_escapes_in $msgid, $plural, $fn, $linenr;

            $self->store($domain, $fn, $linenr, $msgid, $plural);
            $msgs_found++;

            $linenr   += $take =~ tr/\n//;
            next;
        }

        # loc($msgid, ...) form, can appear more than once
        my @markup = split $func_msgid_multi, $take;
        while(@markup > 4)
        {   # quads with text, call, quote, msgid
            $linenr   += ($markup[0] =~ tr/\n//)
                      +  ($markup[1] =~ tr/\n//);
            my $msgid  = $markup[3];
            my $plural = $msgid =~ s/\|(.*)// ? $1 : undef;
			_no_escapes_in $msgid, $plural, $fn, $linenr;

            $self->store($domain, $fn, $linenr, $msgid, $plural);
            $msgs_found++;
            splice @markup, 0, 4;
        }
        $linenr += $markup[-1] =~ tr/\n//; # rest of container
    }
#   $linenr += $frags[-1] =~ tr/\n//; # final page fragment not needed

    $msgs_found;
}

#----------------------------------------------------

1;
