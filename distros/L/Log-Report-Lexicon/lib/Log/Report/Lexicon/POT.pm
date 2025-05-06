# Copyrights 2007-2025 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Log-Report-Lexicon. Meta-POD processed
# with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Log::Report::Lexicon::POT;{
our $VERSION = '1.13';
}

use base 'Log::Report::Lexicon::Table';

use warnings;
use strict;

use Log::Report 'log-report-lexicon';
use Log::Report::Lexicon::PO  ();

use POSIX        qw/strftime/;
use List::Util   qw/sum/;
use Scalar::Util qw/blessed/;
use Encode       qw/decode/;

use constant     MSGID_HEADER => '';


sub init($)
{   my ($self, $args) = @_;

    $self->{LRLP_fn}      = $args->{filename};
    $self->{LRLP_index}   = $args->{index}   || {};
    $self->{LRLP_charset} = $args->{charset} || 'UTF-8';

    my $version    = $args->{version};
    my $domain     = $args->{textdomain}
        or error __"textdomain parameter is required";

    my $forms      = $args->{plural_forms};
    unless($forms)
    {   my $nrplurals = $args->{nr_plurals} || 2;
        my $algo      = $args->{plural_alg} || 'n!=1';
        $forms        = "nplurals=$nrplurals; plural=($algo);";
    }

    $self->_createHeader
      ( project => $domain . (defined $version ? " $version" : '')
      , forms   => $forms
      , charset => $args->{charset}
      , date    => $args->{date}
      );

    $self->setupPluralAlgorithm;
    $self;
}


sub read($@)
{   my ($class, $fn, %args) = @_;
    my $self    = bless {LRLP_index => {}}, $class;

    my $charset = $args{charset};
    $charset    = $1
        if !$charset && $fn =~ m!\.([\w-]+)(?:\@[^/\\]+)?\.po$!i;

    my $fh;
    if(defined $charset)
    {   open $fh, "<:encoding($charset):crlf", $fn
            or fault __x"cannot read in {cs} from file {fn}"
                 , cs => $charset, fn => $fn;
    }
    else
    {   open $fh, '<:raw:crlf', $fn
            or fault __x"cannot read from file {fn} (unknown charset)", fn=>$fn;
    }

    local $/   = "\n\n";
    my $linenr = 1;  # $/ frustrates $fh->input_line_number
    while(1)
    {   my $location = "$fn line $linenr";
        my $block    = <$fh>;
        defined $block or last;

        $linenr += $block =~ tr/\n//;

        $block   =~ s/\s+\z//s;
        length $block or last;

        unless($charset)
        {   $charset = $block =~ m/\"content-type:.*?charset=["']?([\w-]+)/mi
              ? $1 : error __x"cannot detect charset in {fn}", fn => $fn;
            trace "auto-detected charset $charset for $fn";
            binmode $fh, ":encoding($charset):crlf";

            $block = decode $charset, $block
               or error __x"unsupported charset {charset} in {fn}"
                    , charset => $charset, fn => $fn;
        }

        my $po = Log::Report::Lexicon::PO->fromText($block, $location);
        $self->add($po) if $po;
    }

    close $fh
        or fault __x"failed reading from file {fn}", fn => $fn;

    $self->{LRLP_fn}      = $fn;
    $self->{LRLP_charset} = $charset;

    $self->setupPluralAlgorithm;
    $self;
}


sub write($@)
{   my $self = shift;
    my $file = @_%2 ? shift : $self->filename;
    my %args = @_;

    defined $file
        or error __"no filename or file-handle specified for PO";

    my $need_refs = $args{only_active};
    my @opt       = (nr_plurals => $self->nrPlurals);

    my $fh;
    if(ref $file) { $fh = $file }
    else
    {    my $layers = '>:encoding('.$self->charset.')';
         open $fh, $layers, $file
             or fault __x"cannot write to file {fn} with {layers}"
                    , fn => $file, layers => $layers;
    }

    $fh->print($self->msgid(MSGID_HEADER)->toString(@opt));
    my $index = $self->index;
    foreach my $msgid (sort keys %$index)
    {   next if $msgid eq MSGID_HEADER;

        my $rec  = $index->{$msgid};
        my @recs = blessed $rec ? $rec   # one record with $msgid
          : @{$rec}{sort keys %$rec};    # multiple records, msgctxt

        foreach my $po (@recs)
        {   next if $po->useless;
            next if $need_refs && !$po->references;
            $fh->print("\n", $po->toString(@opt));
        }
    }

    $fh->close
        or failure __x"write errors for file {fn}", fn => $file;

    $self;
}

#-----------------------

sub charset()  {shift->{LRLP_charset}}
sub index()    {shift->{LRLP_index}}
sub filename() {shift->{LRLP_fn}}


sub language() { shift->filename =~ m![/\\](\w+)[^/\\]*$! ? $1 : undef }

#-----------------------

sub msgid($;$)
{   my ($self, $msgid, $msgctxt) = @_;
    my $msgs = $self->index->{$msgid} or return;

    return $msgs
        if blessed $msgs
        && (!$msgctxt || $msgctxt eq $msgs->msgctxt);

    $msgs->{$msgctxt};
}


sub msgstr($;$$)
{   my ($self, $msgid, $count, $msgctxt) = @_;
    my $po   = $self->msgid($msgid, $msgctxt)
        or return undef;

    $count //= 1;
    $po->msgstr($self->pluralIndex($count));
}


sub add($)
{   my ($self, $po) = @_;
    my $msgid = $po->msgid;
    my $index = $self->index;

    my $h = $index->{$msgid};
    $h or return $index->{$msgid} = $po;

    $h = $index->{$msgid} = +{ ($h->msgctxt // '') => $h }
        if blessed $h;

    my $ctxt = $po->msgctxt // '';
    error __x"translation already exists for '{msgid}' with '{ctxt}"
      , msgid => $msgid, ctxt => $ctxt
        if $h->{$ctxt};

    $h->{$ctxt} = $po;
}


sub translations(;$)
{   my $self = shift;
    @_ or return map +(blessed $_ ? $_ : values %$_)
      , values %{$self->index};

    error __x"the only acceptable parameter is 'ACTIVE', not '{p}'", p => $_[0]
        if $_[0] ne 'ACTIVE';

    grep $_->isActive, $self->translations;
}


sub _now() { strftime "%Y-%m-%d %H:%M%z", localtime }

sub header($;$)
{   my ($self, $field) = (shift, shift);
    my $header = $self->msgid(MSGID_HEADER)
        or error __x"no header defined in POT for file {fn}"
                   , fn => $self->filename;

    if(!@_)
    {   my $text = $header->msgstr(0) || '';
        return $text =~ m/^\Q$field\E\:\s*([^\n]*?)\;?\s*$/im ? $1 : undef;
    }

    my $content = shift;
    my $text    = $header->msgstr(0);

    for($text)
    {   if(defined $content)
        {   s/^\Q$field\E\:([^\n]*)/$field: $content/im  # change
         || s/\z/$field: $content\n/;      # new
        }
        else
        {   s/^\Q$field\E\:[^\n]*\n?//im;  # remove
        }
    }

    $header->msgstr(0, $text);
    $content;
}


sub updated(;$)
{   my $self = shift;
    my $date = shift || _now;
    $self->header('PO-Revision-Date', $date);
    $date;
}

### internal
sub _createHeader(%)
{   my ($self, %args) = @_;
    my $date   = $args{date} || _now;

    my $header = Log::Report::Lexicon::PO->new
     (  msgid  => MSGID_HEADER, msgstr => <<__CONFIG);
Project-Id-Version: $args{project}
Report-Msgid-Bugs-To:
POT-Creation-Date: $date
PO-Revision-Date: $date
Last-Translator:
Language-Team:
MIME-Version: 1.0
Content-Type: text/plain; charset=$args{charset}
Content-Transfer-Encoding: 8bit
Plural-Forms: $args{forms}
__CONFIG

    my $version = $Log::Report::VERSION || '0.0';
    $header->addAutomatic("Header generated with ".__PACKAGE__." $version\n");

    $self->index->{&MSGID_HEADER} = $header
        if $header;

    $header;
}


sub removeReferencesTo($)
{   my ($self, $filename) = @_;
    sum map $_->removeReferencesTo($filename), $self->translations;
}


sub keepReferencesTo($)
{   my ($self, $keep) = @_;
    sum map $_->keepReferencesTo($keep), $self->translations;
}


sub stats()
{   my $self  = shift;
    my %stats = (msgids => 0, fuzzy => 0, inactive => 0);
    foreach my $po ($self->translations)
    {   next if $po->msgid eq MSGID_HEADER;
        $stats{msgids}++;
        $stats{fuzzy}++    if $po->fuzzy;
        $stats{inactive}++ if !$po->isActive && !$po->useless;
    }
    \%stats;
}

1;
