# Copyrights 2007-2017 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package Log::Report::Lexicon::POTcompact;
use vars '$VERSION';
$VERSION = '1.08';

use base 'Log::Report::Lexicon::Table';

use Log::Report        'log-report-lexicon';
use Log::Report::Util  qw/escape_chars unescape_chars/;

sub _unescape($$);
sub _escape($$);


sub read($@)
{   my ($class, $fn, %args) = @_;

    my $self    = bless {}, $class;

    my $charset = $args{charset}
        or error __x"charset parameter required for {fn}", fn => $fn;

    open my $fh, "<:encoding($charset):crlf", $fn
        or fault __x"cannot read in {cs} from file {fn}"
             , cs => $charset, fn => $fn;

    # Speed!
    my $msgctxt = '';
    my ($last, $msgid, @msgstr);
    my $index   = $self->{index} ||= {};

 LINE:
    while(my $line = $fh->getline)
    {   next if substr($line, 0, 1) eq '#';

        if($line =~ m/^\s*$/)  # blank line starts new
        {   if(@msgstr)
            {   $index->{"$msgid#$msgctxt"}
                   = @msgstr > 1 ? [@msgstr] : $msgstr[0];
                ($msgctxt, $msgid, @msgstr) = ('');
            }
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

    $index->{"$msgid#$msgctxt"} = (@msgstr > 1 ? \@msgstr : $msgstr[0])
        if @msgstr;   # don't forget the last

    close $fh
        or failure __x"failed reading from file {fn}", fn => $fn;

    $self->{filename} = $fn;
    $self->setupPluralAlgorithm;
    $self;
}


sub filename()  {shift->{filename}}


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
