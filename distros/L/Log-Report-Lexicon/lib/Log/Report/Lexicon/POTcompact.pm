# Copyrights 2007-2018 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Log-Report-Lexicon. Meta-POD processed
# with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Log::Report::Lexicon::POTcompact;
use vars '$VERSION';
$VERSION = '1.10';

use base 'Log::Report::Lexicon::Table';

use warnings;
use strict;

use Log::Report        'log-report-lexicon';
use Log::Report::Util  qw/escape_chars unescape_chars/;

use Encode             qw/find_encoding/;

sub _unescape($$);
sub _escape($$);


sub read($@)
{   my ($class, $fn, %args) = @_;

    my $self    = bless {}, $class;

    my $charset = $args{charset};

    # Try to pick-up charset from the filename (which may contain a modifier)
    $charset    = $1
        if !$charset && $fn =~ m!\.([\w-]+)(?:\@[^/\\]+)?\.po$!i;

    my $fh;
    if($charset)
    {   open $fh, "<:encoding($charset):crlf", $fn
            or fault __x"cannot read in {charset} from file {fn}"
                , charset => $charset, fn => $fn;
    }
    else
    {   open $fh, '<:raw:crlf', $fn
            or fault __x"cannot read from file {fn} (unknown charset)", fn=>$fn;
    }

    # Speed!
    my $msgctxt = '';
    my ($last, $msgid, @msgstr);
    my $index   = $self->{index} ||= {};

	my $add = sub {
       unless($charset)
       {   $msgid eq ''
               or error __x"header not found for charset in {fn}", fn => $fn;
           $charset = $msgstr[0] =~ m/^content-type:.*?charset=["']?([\w-]+)/mi
              ? $1 : error __x"cannot detect charset in {fn}", fn => $fn;
           my $enc = find_encoding($charset)
               or error __x"unsupported charset {charset} in {fn}"
                    , charset => $charset, fn => $fn;

           trace "auto-detected charset $charset for $fn";
           $fh->binmode(":encoding($charset):crlf");

           $_ = $enc->decode($_) for @msgstr, $msgctxt;
       }

       $index->{"$msgid#$msgctxt"} = @msgstr > 1 ? [@msgstr] : $msgstr[0];
       ($msgctxt, $msgid, @msgstr) = ('');
    };

 LINE:
    while(my $line = $fh->getline)
    {   next if substr($line, 0, 1) eq '#';

        if($line =~ m/^\s*$/)  # blank line starts new
        {   $add->() if @msgstr;
            next LINE;
        }

        if($line =~ s/^msgctxt\s+//)
        {   $msgctxt = _unescape $line, $fn; 
            $last   = \$msgctxt;
        }
        elsif($line =~ s/^msgid\s+//)
        {   $msgid  = _unescape $line, $fn;
            $last   = \$msgid;
        }
        elsif($line =~ s/^msgstr\[(\d+)\]\s*//)
        {   $last   = \($msgstr[$1] = _unescape $line, $fn);
        }
        elsif($line =~ s/^msgstr\s+//)
        {   $msgstr[0] = _unescape $line, $fn;
            $last   = \$msgstr[0];
        }
        elsif($last && $line =~ m/^\s*\"/)
        {   $$last .= _unescape $line, $fn;
        }
    }
    $add->() if @msgstr;   # don't forget the last

    close $fh
        or failure __x"failed reading from file {fn}", fn => $fn;

    $self->{origcharset} = $charset;
    $self->{filename}    = $fn;
    $self->setupPluralAlgorithm;
    $self;
}

#------------------

sub filename() {shift->{filename}}
sub originalCharset() {shift->{origcharset}}

#------------------

sub index()     {shift->{index}}
# The index is a HASH with "$msg#$msgctxt" keys.  If there is no
# $msgctxt, then there still is the #


sub msgid($) { $_[0]->{index}{$_[1].'#'.($_[2]//'')} }


# speed!!!
sub msgstr($;$$)
{   my ($self, $msgid, $count, $ctxt) = @_;

    $ctxt //= '';
    my $po  = $self->{index}{"$msgid#$ctxt"}
        or return undef;

    ref $po   # no plurals defined
        or return $po;

    $po->[$self->{algo}->($count // 1)] || $po->[$self->{algo}->(1)];
}

#
### internal helper routines, shared with ::PO.pm and ::POT.pm
#

sub _unescape($$)
{   unless( $_[0] =~ m/^\s*\"(.*)\"\s*$/ )
    {   warning __x"string '{text}' not between quotes at {location}"
           , text => $_[0], location => $_[1];
        return $_[0];
    }
    unescape_chars $1;
}

sub _escape($$)
{   my @escaped = map { '"' . escape_chars($_) . '"' }
        defined $_[0] && length $_[0] ? split(/(?<=\n)/, $_[0]) : '';

    unshift @escaped, '""' if @escaped > 1;
    join $_[1], @escaped;
}

1;
