# Copyrights 2007-2016 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package Log::Report::Lexicon::MOTcompact;
use vars '$VERSION';
$VERSION = '1.06';

use base 'Log::Report::Lexicon::Table';

use Log::Report        'log-report-lexicon';
use Fcntl              'SEEK_SET';
use Encode             'decode';

use constant MAGIC_NUMBER => 0x95_04_12_DE;


sub read($@)
{   my ($class, $fn, %args) = @_;
    my $take_all = exists $args{take_all} ? $args{take_all} : 1;

    my $charset  = $args{charset}
        or error __x"charset parameter required for {fn}", fn => $fn;

    my (%index, %locs);
    my %self     =
     +( index    => \%index   # fully prepared ::PO objects
      , locs     => \%locs    # know where to find it
      , filename => $fn
      , charset  => $charset
      );
    my $self    = bless \%self, $class;

    my $fh;
    open $fh, "<:raw", $fn
        or fault __x"cannot read in {cs} from file {fn}"
             , cs => $charset, fn => $fn;

    # The magic number will tell us the byte-order
    # See http://www.gnu.org/software/gettext/manual/html_node/MO-Files.html
    # Found in a bug-report that msgctxt are prepended to the msgid with
    # a separating EOT (4)
    my ($magic, $superblock, $originals, $translations);
    CORE::read $fh, $magic, 4
        or fault __x"cannot read magic from {fn}", fn => $fn;

    my $byteorder
       = $magic eq pack('V', MAGIC_NUMBER) ? 'V'
       : $magic eq pack('N', MAGIC_NUMBER) ? 'N'
       : error __x"unsupported file type (magic number is {magic%x})"
           , magic => $magic;

    # The superblock contains pointers to strings
    CORE::read $fh, $superblock, 6*4  # 6 times a 32 bit int
        or fault __x"cannot read superblock from {fn}", fn => $fn;

    my ( $format_rev, $nr_strings, $offset_orig, $offset_trans
       , $size_hash, $offset_hash ) = unpack $byteorder x 6, $superblock;

    # warn "($format_rev, $nr_strings, $offset_orig, $offset_trans
    #       , $size_hash, $offset_hash)";

    # Read location of all originals
    seek $fh, $offset_orig, SEEK_SET
        or fault __x"cannot seek to {loc} in {fn} for originals"
          , loc => $offset_orig, fn => $fn;

    CORE::read $fh, $originals, $nr_strings*8  # each string 2*4 bytes
        or fault __x"cannot read originals from {fn}, need {size} at {loc}"
           , fn => $fn, loc => $offset_orig, size => $nr_strings*4;

    my @origs = unpack $byteorder.'*', $originals;

    # Read location of all translations
    seek $fh, $offset_trans, SEEK_SET
        or fault __x"cannot seek to {loc} in {fn} for translations"
          , loc => $offset_orig, fn => $fn;

    CORE::read $fh, $translations, $nr_strings*8  # each string 2*4 bytes
        or fault __x"cannot read translations from {fn}, need {size} at {loc}"
           , fn => $fn, loc => $offset_trans, size => $nr_strings*4;

    my @trans = unpack $byteorder.'*', $translations;

    # We need the originals as index to the translations (unless there
    # is a HASH build-in... which is not defined)
    # The strings are strictly ordered, the spec tells me.
    my ($orig_start, $orig_end) = ($origs[1], $origs[-1]+$origs[-2]);

    seek $fh, $orig_start, SEEK_SET
        or fault __x"cannot seek to {loc} in {fn} for msgid strings"
          , loc => $orig_start, fn => $fn;

    my ($orig_block, $trans_block);
    my $orig_block_size = $orig_end - $orig_start;
    CORE::read $fh, $orig_block, $orig_block_size
        or fault __x"cannot read msgids from {fn}, need {size} at {loc}"
           , fn => $fn, loc => $orig_start, size => $orig_block_size;

    my ($trans_start, $trans_end) = ($trans[1], $trans[-1]+$trans[-2]);
    seek $fh, $trans_start, SEEK_SET
        or fault __x"cannot seek to {loc} in {fn} for transl strings"
          , loc => $trans_start, fn => $fn;

    if($take_all)
    {   my $trans_block_size = $trans_end - $trans_start;
        CORE::read $fh, $trans_block, $trans_block_size
            or fault __x"cannot read translations from {fn}, need {size} at {loc}"
               , fn => $fn, loc => $trans_start, size => $trans_block_size;
    }

    while(@origs)
    {   my ($id_len, $id_loc) = (shift @origs, shift @origs);
        my $msgid_b   = substr $orig_block, $id_loc-$orig_start, $id_len;
        my $msgctxt_b = $msgid_b =~ s/(.*)\x04// ? $1 : '';

        my $msgid     = decode $charset, $msgid_b;
        my $msgctxt   = decode $charset, $msgctxt_b;

        my ($trans_len, $trans_loc) = (shift @trans, shift @trans);
        if($take_all)
        {   my $msgstr_b = substr $trans_block, $trans_loc - $trans_start, $trans_len;
            my @msgstr   = map decode($charset, $_), split /\0x00/, $msgstr_b;
            $index{"$msgid#$msgctxt"} = @msgstr > 1 ? \@msgstr : $msgstr[0];
        }
        else
        {   # this may save memory...
            $locs{"$msgid#$msgctxt"}  = [$trans_loc, $trans_len];
        }
    }

    if($take_all)
    {   close $fh
           or failure __x"failed reading from file {fn}", fn => $fn;
    }
    else
    {   $self->{fh} = $fh;
    }

    $self->setupPluralAlgorithm;
    $self;
}


sub index()     {shift->{index}}
sub filename()  {shift->{filename}}


sub msgid($;$)
{   my ($self, $msgid, $msgctxt) = @_;
    my $tag = $msgid.'#'.($msgctxt//'');
    my $po  = $self->{index}{$tag};
    return $po if $po;

    my $l   = delete $self->{locs}{$tag} or return ();

    my $fh  = $self->{fh};
    seek $fh, $l->[0], SEEK_SET
        or fault __x"cannot seek to {loc} late in {fn} for transl strings"
          , loc => $l->[0], fn => $self->filename;

    my $block;
    CORE::read $fh, $block, $l->[1]
      or fault __x"cannot read late translation from {fn}, need {size} at {loc}"
          , fn => $self->filename, loc => $l->[0], size => $l->[1];

    my @msgstr = split /\0x00/, $block;
    $self->{index}{$tag} = @msgstr > 1 ? \@msgstr : $msgstr[0]; 
}


sub msgstr($;$$)
{   my $po   = $_[0]->msgid($_[1], $_[3])
        or return undef;

    ref $po   # no plurals defined
        or return $po;

    # speed!!!
       $po->[$_[0]->{algo}->(defined $_[2] ? $_[2] : 1)]
    || $po->[$_[0]->{algo}->(1)];
}

1;
