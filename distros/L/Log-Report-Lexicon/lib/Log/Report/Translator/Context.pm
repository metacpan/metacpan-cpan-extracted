# Copyrights 2007-2018 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Log-Report-Lexicon. Meta-POD processed
# with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Log::Report::Translator::Context;
use vars '$VERSION';
$VERSION = '1.11';


use warnings;
use strict;

use Log::Report 'log-report-lexicon';


sub new(@)  { my $class = shift; (bless {}, $class)->init({@_}) }
sub init($)
{   my ($self, $args) = @_;
    $self->{LRTC_rules} = $self->_context_table($args->{rules} || {});
    $self;
}

#-------

sub rules() {shift->{LRTC_rules}}

#-------

sub _strip_ctxt_spec($)
{   my $msgid = shift;
    my @tags;
    while($msgid =~ s/\{ ([^<}]*) \<(\w+) ([^}]*) \}/
                      length "$1$3" ? "{$1$3}" : ''/xe)
    {  push @tags, $2;
    }
    ($msgid, [sort @tags]);
}

sub ctxtFor($$;$)
{   my ($self, $msg, $lang, $def_context) = @_;
    my $rawid = $msg->msgid;
    my ($msgid, $tags) = _strip_ctxt_spec $rawid;
    @$tags or return ($msgid, undef);

    my $maps = $self->rules;
    $lang    =~ s/_.*//;

    my $msg_context = $self->needDecode($rawid, $msg->context || {});
    $def_context  ||= {};
#use Data::Dumper;
#warn "context = ", Dumper $msg, $msg_context, $def_context;

    my @c;
    foreach my $tag (@$tags)
    {   my $map = $maps->{$tag}
            or error __x"no context definition for `{tag}' in `{msgid}'"
               , tag => $tag, msgid => $rawid;

        my $set = $map->{$lang} || $map->{default};
        next if $set eq 'IGNORE';

        my $v   = $msg_context->{$tag} || $def_context->{$tag};
        unless($v)
        {   warning __x"no value for tag `{tag}' in the context", tag => $tag;
            ($v) = keys %$set;
        }
        unless($set->{$v})
        {   warning __x"unknown alternative `{alt}' for tag `{tag}' in context of `{msgid}'"
               , alt => $v, tag => $tag, msgid => $rawid;
            ($v) = keys %$set;
        }

        push @c, "$tag=$set->{$v}";
    }

    my $msgctxt = join ' ', sort @c;
    ($msgid, $msgctxt);
}


sub needDecode($@)
{   my ($thing,  $source) = (shift, shift);
    return +{@_} if @_ > 1;
    my $c = shift;
    return $c if !defined $c || ref $c eq 'HASH';

    my %c;
    foreach (ref $c eq 'ARRAY' ? @$c : (split /[\s,]+/, $c))
    {   my ($kw, $val) = split /\=/, $_, 2;
        defined $val
            or error __x"tags value must have form `a=b', found `{this}' in `{source}'"
              , this => $_, source => $source;
        $c{$kw} = $val;
    }
    \%c;
}


sub expand($$@)
{   my ($self, $raw, $lang) = @_;
    my ($msgid, $tags) = _strip_ctxt_spec $raw;

    $lang =~ s/_.*//;

    my $maps    = $self->rules;
    my @options = [];

    foreach my $tag (@$tags)
    {   my $map = $maps->{$tag}
            or error __x"unknown context tag '{tag}' used in '{msgid}'"
              , tag => $tag, msgid => $msgid;
        my $set = $map->{$lang} || $map->{default};

        my %uniq   = map +("$tag=$_" => 1), values %$set;
        my @oldopt = @options;
        @options   = ();

        foreach my $alt (keys %uniq)
        {   push @options, map +[ @$_, $alt ], @oldopt;
        }
    }

    ($msgid, [sort map join(' ', @$_), @options]);
}

sub _context_table($)
{   my ($self, $rules) = @_;
    my %rules;
    foreach my $tag (keys %$rules)
    {   my $d = $rules->{$tag};
        $d = +{ alternatives => $d } if ref $d eq 'ARRAY';
        my %simple;
        my $default  = $d->{default} || {};           # default map
        if(my $alt   = $d->{alternatives})            # simpelest map
        {   $default = +{ map +($_ => $_), @$alt };
        }
        $simple{default} = $default;
        foreach my $set (keys %$d)
        {   next if $set eq 'default' || $set eq 'alternatives';
            my %set = (%$default, %{$d->{$set}});
            $simple{$_} = \%set for split /\,/, $set;  # table per lang
        }
        $rules{$tag} = \%simple;
    }

    \%rules;
}

#------------

1;
