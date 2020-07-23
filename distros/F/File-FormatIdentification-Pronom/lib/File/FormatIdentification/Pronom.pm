package File::FormatIdentification::Pronom;

use feature qw(say);
use strict;
use warnings;
use XML::LibXML;
use Carp;
use List::Util qw( none first );
use Scalar::Util;
use YAML::XS;
use File::FormatIdentification::Regex;
use Moose;

our $VERSION = '0.02';

# Preloaded methods go here.
# flattens a regex-structure to a regex-string, expects a signature-pattern and a list of regex-structures
# returns regex
#
no warnings 'recursion';

sub _flatten_rx_recursive ($$$@) {
    my $regex         = shift;
    my $lastpos       = shift;
    my $open_brackets = shift;
    my @rx_groups     = @_;
    my $rx            = shift @rx_groups;

    #use Data::Printer;
    #say "_flatten_rx_recursive";
    #p( @rx_groups );
    #p( $rx );
    my $bracket_symbol = "(";
    if ( !defined $regex ) { confess; }

    if ( !defined $rx ) {    # do nothing
        while ( $open_brackets > 0 ) {
            $regex .= ")";
            $open_brackets--;
        }
    }
    else {
        my $pos_diff    = $rx->{position} - $lastpos;
        my $local_regex = $rx->{regex};
        if ( !defined $local_regex ) {
            $local_regex = '';
        }
        if ( 0 == $pos_diff ) {

            # TODO:
            File::FormatIdentification::Regex::simplify_two_or_combined_regex(
                $regex, $local_regex );
            $regex =
              &_flatten_rx_recursive( "$regex|$local_regex", $lastpos,
                $open_brackets, @rx_groups );
        }
        elsif ( $pos_diff > 0 ) {    # is deeper
               # look a head, if same pos found, then use bracket, otherwise not
            if (
                (
                    scalar @rx_groups > 0
                    && ( $rx_groups[0]->{position} == $rx->{position} )
                )
                || $pos_diff > 1
              )
            {    # use (
                $regex = &_flatten_rx_recursive(
                    "$regex" . ( $bracket_symbol x $pos_diff ) . $local_regex,
                    $rx->{position}, $open_brackets += $pos_diff, @rx_groups );
            }
            else {
                $regex = &_flatten_rx_recursive(
                    "$regex$local_regex", $rx->{position},
                    $open_brackets,       @rx_groups
                );
            } ## end else [ if ( scalar @rx_groups...)]
        }
        elsif ( $pos_diff < 0 ) {    # is higher
            $regex = &_flatten_rx_recursive(
                "$regex)$local_regex",
                $rx->{position},
                $open_brackets - 1,    #($rx->{position} - $lastpos),
                @rx_groups
            );
        }
        else {
            confess
"FL: pos=$rx->{position} lastpos=$lastpos regex='$regex' open=$open_brackets\n";
        }
    }
    return $regex;
} ## end sub _flatten_rx_recursive ($$$@)
use warnings 'recursion';

sub _flatten_rx ($@) {
    my $regex     = shift;
    my @rx_groups = @_;

    #say "calling flatten_rx with regex=$regex quality=$quality";
    #use Data::Printer;
    #p( @rx_groups );
    $regex = _flatten_rx_recursive( $regex, 0, 0, @rx_groups );
    return $regex;
} ## end sub _flatten_rx ($@)

# expands pattern of form "FFFB[10:EB]" to FFFB10, FFFB11, ... FFFBEB
sub _expand_pattern ($) {
    my $pattern = $_[0];
    $pattern =~ s/(?<=\[)!/^/g;
    $pattern =~ s/(?<=[0-9A-F]{2}):(?=[0-9A-F]{2})\]/-]/g;
    $pattern =~ s/([0-9A-F]{2})/\\x{$1}/g;

    # substitute hex with printable ASCII-Output
    $pattern =~ s#\\x\{(3[0-9]|[46][1-9A-F]|[57][0-9A])\}#chr( hex($1) );#egs;
    return $pattern;
} ## end sub _expand_pattern ($)

# expands offsets min,max to regex ".{$min,$max}" and uses workarounds if $min or $max exceeds 32766
sub _expand_offsets($$) {
    my $minoffset = shift;
    my $maxoffset = shift;
    my $byte =
      '.';    # HINT: needs the character set modifier "aa" in $foo=~m/$regex/aa
              #my $byte = '[\x00-\xff]';
    my $offset_expanded = "";
    if (   ( ( not defined $minoffset ) || ( length($minoffset) == 0 ) )
        && ( ( not defined $maxoffset ) || ( length($maxoffset) == 0 ) ) )
    {
        $offset_expanded = "";
    }
    elsif (( defined $minoffset )
        && ( length($minoffset) > 0 )
        && ( defined $maxoffset )
        && ( length($maxoffset) > 0 )
        && ( $minoffset == $maxoffset ) )
    {
        if ( $minoffset > 0 ) {
            my $maxloops    = int( $maxoffset / 32766 );
            my $maxresidual = $maxoffset % 32766;
            for ( my $i = 0 ; $i < $maxloops ; $i++ ) {
                $offset_expanded .= $byte . "{32766}";
            }
            $offset_expanded .= $byte . "{$maxresidual}";
        } ## end if ( $minoffset > 0 )
    }
    else {

    # workaround, because perl quantifier limits,
    #  calc How many repetitions we need! Both offsets should be less than 32766
    #TODO: check if this comes from Droid or is calculated

        my $mintmp = 0;
        my $maxtmp = 0;
        if ( defined $minoffset && ( length($minoffset) > 0 ) ) {
            $mintmp = $minoffset;
        }
        if ( defined $maxoffset && ( length($maxoffset) > 0 ) ) {
            $maxtmp = $maxoffset;
        }

        my $maxloops;
        if ( $maxtmp >= $mintmp ) {
            $maxloops = int( $maxtmp / 32766 );
        }
        else {
            $maxloops = int( $mintmp / 32766 );
        }
        my $maxresidual = $maxtmp % 32766;
        my $minresidual = $mintmp % 32766;

        #say "\tMaxloops=$maxloops maxres = $maxresidual minres=$minresidual";
        my @offsets;
        my $minstr = "";
        my $maxstr = "";
        if ( defined $minoffset && length($minoffset) > 0 ) {
            $minstr = $minresidual;
            $mintmp = $mintmp - $minresidual;
        }

        for ( my $i = 0 ; $i <= $maxloops ; $i++ ) {

            # loop, so we assure the special handling of residuals
            if ( $maxtmp > $maxresidual ) {
                $maxstr = 32766;
            }
            elsif ( $maxtmp < 0 ) {
                $maxstr = 0;
            }
            else {
                $maxstr = $maxresidual;
            }
            if ( $mintmp > $minresidual ) {
                $minstr = 32766;
            }
            elsif ( $mintmp < 0 ) {
                $minstr = 0;
            }
            else {
                $minstr = $minresidual;
            }
            #### handle residuals
            if ( $i == 0 ) {
                $minstr = $minresidual;
                $mintmp = $mintmp - $minresidual;
            }
            elsif ( $i == $maxloops ) {
                $maxstr = $maxresidual;
                $maxtmp = $maxtmp - $maxresidual;
            }

            # mark offsets
            my $tmp;
            $tmp->{minoffset} = $minstr;
            $tmp->{maxoffset} = $maxstr;
            push @offsets, $tmp;
        } ## end for ( my $i = 0 ; $i <=...)
        my @filtered = map {
            if ( !defined $maxoffset || length($maxoffset) == 0 ) {
                $_->{maxoffset} = "";
            }
            if ( !defined $minoffset || length($minoffset) == 0 ) {
                $_->{minoffset} = "";
            }
            $_;
        } @offsets;
        foreach my $tmp (@filtered) {

# ? at the end - means non-greedy
#$offset_expanded .= $byte."{" . $tmp->{minoffset} . "," . $tmp->{maxoffset} . "}?";
            $offset_expanded .=
              $byte . "{" . $tmp->{minoffset} . "," . $tmp->{maxoffset} . "}";
        } ## end foreach my $tmp (@filtered)
    } ## end else [ if ( ( ( not defined $minoffset...)))]

#say "DEBUG: minoffset='$minoffset' maxoffset='$maxoffset' --> offset_expanded='$offset_expanded'";

    # minimization steps
    $offset_expanded =~ s#{0,}#*#g;
    $offset_expanded =~ s#{1,}#+#g;
    $offset_expanded =~ s#{0,1}#?#g;
    return $offset_expanded;
} ## end sub _expand_offsets($$)

# got XPath-object and returns a regex-structure as hashref
sub _parse_fragments ($) {
    my $fq        = shift;
    my $position  = $fq->getAttribute('Position');
    my $minoffset = $fq->getAttribute('MinOffset');
    my $maxoffset = $fq->getAttribute('MaxOffset');
    my $rx        = $fq->textContent;
    my $expanded  = _expand_pattern($rx);
    my $ret;
    $ret->{position}  = $position;
    $ret->{direction} = "left";
    $ret->{regex}     = "";

    my ($offset_expanded) = _expand_offsets( $minoffset, $maxoffset );

    if ( $fq->localname eq "LeftFragment" ) {
        $ret->{direction} = "left";
        $ret->{regex}     = "($expanded)$offset_expanded";
    }
    elsif ( $fq->localname eq "RightFragment" ) {
        $ret->{direction} = "right";
        $ret->{regex}     = "$offset_expanded($expanded)";
    }

    #say "pF: rx=$rx expanded=$expanded offset=$offset_expanded";
    return $ret;
} ## end sub _parse_fragments ($)

# got XPath-object and search direction and returns a regex-structure as hashref
sub _parse_subsequence ($$) {
    my $ssq       = shift;
    my $dir       = shift;
    my $position  = $ssq->getAttribute('Position');
    my $minoffset = $ssq->getAttribute('SubSeqMinOffset');
    my $maxoffset = $ssq->getAttribute('SubSeqMaxOffset');

    my $rx = $ssq->getElementsByTagName('Sequence')->get_node(1)->textContent;

    my @lnodes        = $ssq->getElementsByTagName('LeftFragment');
    my @rnodes        = $ssq->getElementsByTagName('RightFragment');
    my @lrx_fragments = map { _parse_fragments($_) } @lnodes;
    my @rrx_fragments = map { _parse_fragments($_) } @rnodes;
    my $lregex        = _flatten_rx( "", @lrx_fragments );
    my $rregex        = _flatten_rx( "", @rrx_fragments );
    my $expanded      = _expand_pattern($rx);

 #if (   length($minoffset) > 0
 #    && length($maxoffset) > 0
 #    && $minoffset > $maxoffset ) {
 #    confess(
 #"parse_subsequence: Maxoffset=$maxoffset < Minoffset=$minoffset! regex= '$rx'"
 #            );
 #    } ## end if ( length($minoffset...))

    my $offset_expanded = _expand_offsets( $minoffset, $maxoffset );
    my $prefix;
    my $suffix;
    my $ret;
    my $regex;
    if ( !defined $dir || length($dir) == 0 ) {
        $regex = join( "", $lregex, $expanded, $rregex );
    }
    elsif ( $dir eq "BOFoffset" ) {
        $regex =
          join( "", $offset_expanded, "(", $lregex, $expanded, $rregex, ")" );
    }
    elsif ( $dir eq "EOFoffset" ) {
        $regex =
          join( "", "(", $lregex, $expanded, $rregex, ")", $offset_expanded );
    }
    else {
        warn "unknown reference '$dir' found\n";
        $regex = join( "", $lregex, $expanded, $rregex );
    }
    $ret->{regex} =
      File::FormatIdentification::Regex::peep_hole_optimizer($regex);
    $ret->{position} = $position;

    return $ret;
} ## end sub _parse_subsequence ($$)

# got XPath-object and returns regex-string
sub _parse_bytesequence ($) {
    my $bsq = shift;

    #say "rx_groups in parse_byte_sequence:";
    my $reference = $bsq->getAttribute('Reference');
    ;    # if BOFoffset -> anchored begin of file, EOFofset -> end of file
    my @nodes           = $bsq->getElementsByTagName('SubSequence');
    my @rx_groups       = map { _parse_subsequence( $_, $reference ) } @nodes;
    my $expanded        = "";
    my $regex_flattened = _flatten_rx( $expanded, @rx_groups );

    #my $ro = Regexp::Optimizer->new;
    #my $ro = Regexp::Assemble->new;
    #$ro->add( $regex_flattened);
    #$regex_flattened = $ro->as_string($regex_flattened);
    #$regex_flattened = $ro->re;
    my $regex;
    if ( !defined $reference || 0 == length($reference) ) {
        $regex = "$regex_flattened";
    }
    elsif ( $reference eq "BOFoffset" ) {
        $regex = "\\A$regex_flattened";
    }
    elsif ( $reference eq "EOFoffset" ) {
        $regex = "$regex_flattened\\Z";
    }
    else {
        warn "unknown reference '$reference' found\n";
        $regex = "$regex_flattened";
    }

    use Regexp::Optimizer;
    my $ro = Regexp::Optimizer->new;

    #say "regex='$regex'";
    #$regex = $ro->as_string( $regex );
    return $regex;
} ## end sub _parse_bytesequence ($)

# ($%signatures, $%internal) = parse_signaturefile( $file )
sub _parse_signaturefile($) {
    my $pronomfile = shift;
    my %signatures;

    # hash{internalid}->{regex} = $regex
    #                 ->{signature} = $signature
    my %internal_signatures;

    my $dom = XML::LibXML->load_xml( location => $pronomfile );
    $dom->indexElements();
    my $xp = XML::LibXML::XPathContext->new($dom);
    $xp->registerNs( 'droid',
        'http://www.nationalarchives.gov.uk/pronom/SignatureFile' );

# find Fileformats
#my $tmp = $xp->find('/*[local-name() = "FFSignatureFile"]')->get_node(1);
#say "E:", $tmp->nodeName;
#say "EXISTS:", $xp->exists('/droid:FFSignatureFile');
#say "EXISTS2", $xp->exists('/droid:FFSignatureFile/droid:FileFormatCollection/droid:FileFormat');

    my $fmts = $xp->find(
'/*[local-name() = "FFSignatureFile"]/*[local-name() = "FileFormatCollection"]/*[local-name() = "FileFormat"]'
    );
    foreach my $fmt ( $fmts->get_nodelist() ) {
        my $id       = $fmt->getAttribute('ID');
        my $mimetype = $fmt->getAttribute('MIMEtype');
        my $name     = $fmt->getAttribute('Name');
        my $puid     = $fmt->getAttribute('PUID');
        my $version  = $fmt->getAttribute('Version');
        #

        ##
        my @extensions =
          map { $_->textContent() } $fmt->getElementsByTagName('Extension');
        my @internalsignatures =
          map { $_->textContent() }
          $fmt->getElementsByTagName('InternalSignatureID');
        my @haspriorityover = map { $_->textContent() }
          $fmt->getElementsByTagName('HasPriorityOverFileFormatID');
        $signatures{$id}->{mimetype}   = $mimetype;
        $signatures{$id}->{name}       = $name;
        $signatures{$id}->{puid}       = $puid;
        $signatures{$id}->{version}    = $version;       # optional
        $signatures{$id}->{extensions} = \@extensions;
        $signatures{$id}->{internal_signatures} = \@internalsignatures;

        foreach my $prio (@haspriorityover) {
            $signatures{$id}->{priorityover}->{$prio} = 1;
        }

        foreach my $internal (@internalsignatures) {
            $internal_signatures{$internal}->{signature} = $id;
        }
    } ## end foreach my $fmt ( $fmts->get_nodelist...)

    # find InternalSignatures
    my $sigs =
      $xp->find(
'/*[local-name() = "FFSignatureFile"]/*[local-name() = "InternalSignatureCollection"]/*[local-name() = "InternalSignature"]'
      );

    foreach my $sig ( $sigs->get_nodelist() ) {

        my $id          = $sig->getAttribute('ID');
        my $specificity = $sig->getAttribute('Specificity');
        $internal_signatures{$id}->{specificity} = $specificity;

        #p( $sig->toString() );
        my @nodes = $sig->getElementsByTagName('ByteSequence');

        #p( @nodes );
        my @rx_groups = map { _parse_bytesequence($_) } @nodes;
        my @rx_quality =
          map { File::FormatIdentification::Regex::calc_quality($_); }
          @rx_groups;

        $internal_signatures{$id}->{regex}   = \@rx_groups;
        $internal_signatures{$id}->{quality} = \@rx_quality;
    } ## end foreach my $sig ( $sigs->get_nodelist...)

    return ( \%signatures, \%internal_signatures );
} ## end sub _parse_signaturefile($)

sub uniq_signature_ids_by_priority {
    my $self       = shift;
    my @signatures = @_;
    my %found_signature_ids;

    # which PUIDs are in list?
    foreach my $signatureid (@signatures) {
        if ( defined $signatureid ) {
            $found_signature_ids{$signatureid} = 1;
        }
    }

    # remove all signatures when actual signature has priority over
    foreach my $signatureid ( keys %found_signature_ids ) {
        foreach my $priority_over_sid (
            keys %{ $self->{signatures}->{$signatureid}->{priorityover} } )
        {
            if ( exists $found_signature_ids{$priority_over_sid} ) {
                delete $found_signature_ids{$priority_over_sid};
            }
        } ## end foreach my $priority_over_sid...
    } ## end foreach my $signatureid ( keys...)

    # reduce list to all signatures with correct priority
    my @result =
      grep { defined $found_signature_ids{ $_->{signature} } } @signatures;
    return @result;
} ## end sub uniq_signature_ids_by_priority

has 'droid_signature_filename' => (
    is       => 'ro',
    required => 1,
    reader   => 'get_droid_signature_filename',
    trigger  => sub {
        my $self = shift;

        #say "TRIGGER";
        my $yaml_file = $self->get_droid_signature_filename() . ".yaml";
        if ( $self->{auto_load} && -e $yaml_file ) {
            $self->load_from_yamlfile($yaml_file);
        }
        else {
            my ( $signatures, $internal_signatures ) =
              _parse_signaturefile( $self->{droid_signature_filename} );
            $self->{signatures}          = $signatures;
            $self->{internal_signatures} = $internal_signatures;

            #die;
            if ( $self->{auto_store} ) {
                $self->save_as_yamlfile($yaml_file);
            }
        } ## end else [ if ( $self->{auto_load...})]
        foreach my $s ( keys %{ $self->{signatures} } ) {
            my $puid = $self->{signatures}->{$s}->{puid};
            if ( defined $puid && length($puid) > 0 ) {
                $self->{puids}->{$puid} = $s;
            }
        }
    }
);

sub save_as_yamlfile {
    my $self     = shift;
    my $filename = shift;
    my @res;
    push @res, $self->{signatures};
    push @res, $self->{internal_signatures};
    YAML::XS::DumpFile( "$filename", @res );
    return;
} ## end sub save_as_yamlfile

sub load_from_yamlfile {
    my $self     = shift;
    my $filename = shift;
    my ( $sig, $int ) = YAML::XS::LoadFile($filename);
    $self->{signatures}          = $sig;
    $self->{internal_signatures} = $int;
    return;
} ## end sub load_from_yamlfile

has 'auto_store' => (
    is      => 'ro',
    default => 1,
);

has 'auto_load' => (
    is      => 'ro',
    default => 1,
);

sub get_all_signature_ids {
    my $self = shift;
    my @sigs = sort { $a <=> $b } keys %{ $self->{signatures} };
    return @sigs;
}

sub get_signature_id_by_puid {
    my $self = shift;
    my $puid = shift;
    my $sig  = $self->{puids}->{$puid};
    return $sig;
}

sub get_internal_ids_by_puid {
    my $self = shift;
    my $puid = shift;
    my $sig  = $self->get_signature_id_by_puid($puid);
    my @ids  = ();
    if ( defined $sig ) {
        @ids = grep { defined $_ }
          @{ $self->{signatures}->{$sig}->{internal_signatures} };
    }
    return @ids;
}

sub get_file_endings_by_puid {
    my $self    = shift;
    my $puid    = shift;
    my $sig     = $self->get_signature_id_by_puid($puid);
    my @endings = ();
    if ( defined $sig ) {
        @endings = $self->{signatures}->{$sig}->{extensions};
    }
    return @endings;
}

sub get_all_internal_ids {
    my $self = shift;
    my @ids = sort { $a <=> $b } keys %{ $self->{internal_signatures} };
    foreach my $id (@ids) {
        if ( !defined $id ) { confess("$id not defined") }
    }
    return @ids;
}

sub get_all_puids {
    my $self = shift;
    my @ids =
      sort grep { defined $_ }
      map       { $self->{signatures}->{$_}->{puid}; }
      grep      { defined $_ } $self->get_all_signature_ids();
    return @ids;
}

sub get_regular_expressions_by_internal_id {
    my $self       = shift;
    my $internalid = shift;
    if ( !defined $internalid ) { confess("internalid must exists!"); }
    my @rx = @{ $self->{internal_signatures}->{$internalid}->{regex} };
    return @rx;
}

sub get_all_regular_expressions {
    my $self    = shift;
    my @ids     = $self->get_all_internal_ids();
    my @regexes = ();
    foreach my $id (@ids) {
        my @rx = $self->get_regular_expressions_by_internal_id($id);
        push @regexes, @rx;
    }
    my @ret = sort @regexes;
    return @ret;
}

sub get_qualities_by_internal_id {
    my $self       = shift;
    my $internalid = shift;
    if ( !defined $internalid ) { confess("internalid must exists!"); }
    my $value = $self->{internal_signatures}->{$internalid}->{quality};
    if ( defined $value ) {
        return @{$value};
    }
    return;
}

sub get_signature_id_by_internal_id {
    my $self       = shift;
    my $internalid = shift;
    if ( !defined $internalid ) { confess("internalid must exists!"); }
    return $self->{internal_signatures}->{$internalid}->{signature};
}

sub get_name_by_signature_id {
    my $self      = shift;
    my $signature = shift;
    return $self->{signatures}->{$signature}->{name};
}

sub get_puid_by_signature_id {
    my $self      = shift;
    my $signature = shift;
    return $self->{signatures}->{$signature}->{puid};
}

sub get_puid_by_internal_id {
    my $self       = shift;
    my $internalid = shift;
    if ( !defined $internalid ) { confess("internalid must exists!"); }
    my $signature = $self->get_signature_id_by_internal_id($internalid);
    return $self->get_puid_by_signature_id($signature);
}

sub get_quality_sorted_internal_ids {
    my $self = shift;
    my @ids  = sort {

        # sort by regexes
        my @a_rxq = @{ $self->{internal_signatures}->{$a}->{quality} };
        my @b_rxq = @{ $self->{internal_signatures}->{$b}->{quality} };
        my $aq    = 0;
        foreach my $as (@a_rxq) { $aq += $as; }
        my $bq = 0;
        foreach my $bs (@b_rxq) { $bq += $bs; }

        #use Data::Printer;
        #p( $a );
        #p( $aq );
        $aq <=> $bq;
    } $self->get_all_internal_ids();
    return @ids;
}

sub get_combined_regex_by_puid {
    my $self      = shift;
    my $puid      = shift;
    my @internals = $self->get_internal_ids_by_puid($puid);

    #use Data::Printer;
    #p( $puid );
    #p( @internals );
    my @regexes = map {
        my @regexes_per_internal =
          $self->get_regular_expressions_by_internal_id($_);
        my $combined =
          File::FormatIdentification::Regex::and_combine(@regexes_per_internal);

        #p( $combined );
        $combined;
    } @internals;
    my $result = File::FormatIdentification::Regex::or_combine(@regexes);

    #p( $result );
    return $result;
}

sub _prepare_statistics {
    my $self = shift;
    my $results;

    # count of PUIDs
    # count of internal ids (IDs per PUID)
    # count of regexes
    # count of file endings only
    # count of internal ids without PUID
    # larges and shortest regex
    # complex and simple regex
    # common regexes
    #say "stat";
    my @puids                       = $self->get_all_puids();
    my $puids                       = scalar(@puids);
    my @internals                   = $self->get_all_internal_ids();
    my $internals                   = scalar(@internals);
    my $regexes                     = 0;
    my $fileendingsonly             = 0;
    my @fileendingsonly             = ();
    my $fileendings                 = 0;
    my $int_per_puid                = 0;
    my $internal_without_puid       = 0;
    my @internal_without_puid       = ();
    my @quality_sorted_internal_ids = $self->get_quality_sorted_internal_ids();
    my %uniq_regexes;

    foreach my $internalid (@internals) {
        my @regexes =
          $self->get_regular_expressions_by_internal_id($internalid);
        foreach my $rx (@regexes) {
            my @tmp = ();
            if ( exists $uniq_regexes{$rx} ) {
                @tmp = @{ $uniq_regexes{$rx} };
            }
            push @tmp, $internalid;
            $uniq_regexes{$rx} = \@tmp;
        }

        $regexes += scalar(@regexes);
        my $sigid = $self->get_signature_id_by_internal_id($internalid);
        if ( !defined $sigid ) {
            $internal_without_puid++;
            push @internal_without_puid, $internalid;
        }
    }
    foreach my $puid (@puids) {
        my @ints        = $self->get_internal_ids_by_puid($puid);
        my @fileendings = $self->get_file_endings_by_puid($puid);
        if ( 0 == scalar(@ints) ) {
            $fileendingsonly++;
            push @fileendingsonly, $puid;
        }
        else {
            $fileendings  += scalar(@fileendings);
            $int_per_puid += scalar(@ints);
        }
    }
    foreach my $i (@quality_sorted_internal_ids) {
        my $regex =
          join( "#", $self->get_regular_expressions_by_internal_id($i) );
        my $quality = join( " ", $self->get_qualities_by_internal_id($i) );

    }

    $results->{filename}              = $self->get_droid_signature_filename();
    $results->{count_of_puids}        = $puids;
    $results->{count_of_internal_ids} = $internals;
    $results->{count_of_regular_expressions}        = $regexes;
    $results->{count_of_fileendings}                = $fileendings;
    $results->{count_of_puid_with_fileendings_only} = $fileendingsonly;
    $results->{puids_with_fileendings_only}         = \@fileendingsonly;
    $results->{count_of_orphaned_internal_ids}      = $internal_without_puid;
    $results->{internal_ids_without_puids}          = \@internal_without_puid;
    no warnings;

    for ( my $i = 0 ; $i <= 4 ; $i++ ) {
        my $best_quality_internal = pop @quality_sorted_internal_ids;
        if ( defined $best_quality_internal ) {
            my $best_quality = join( ";",
                $self->get_qualities_by_internal_id($best_quality_internal) );
            my $best_puid =
              $self->get_puid_by_internal_id($best_quality_internal);
            my $best_name =
              $self->get_name_by_signature_id(
                $self->get_signature_id_by_internal_id($best_quality_internal)
              );
            my $best_regex = $self->get_combined_regex_by_puid($best_puid);
            $results->{nth_best_quality}->[$i]->{internal_id} =
              $best_quality_internal;
            $results->{nth_best_quality}->[$i]->{puid}    = $best_puid;
            $results->{nth_best_quality}->[$i]->{name}    = $best_name;
            $results->{nth_best_quality}->[$i]->{quality} = $best_quality;
            $results->{nth_best_quality}->[$i]->{combined_regex} = $best_regex;
        }
    }
    for ( my $i = 0 ; $i <= 4 ; $i++ ) {
        my $worst_quality_internal = shift @quality_sorted_internal_ids;
        if ( defined $worst_quality_internal ) {
            my $worst_quality = join( ";",
                $self->get_qualities_by_internal_id($worst_quality_internal) );
            my $worst_puid =
              $self->get_puid_by_internal_id($worst_quality_internal);
            my $worst_name =
              $self->get_name_by_signature_id(
                $self->get_signature_id_by_internal_id($worst_quality_internal)
              );
            my $worst_regex = $self->get_combined_regex_by_puid($worst_puid);
            $results->{nth_worst_quality}->[$i]->{internal_id} =
              $worst_quality_internal;
            $results->{nth_worst_quality}->[$i]->{puid}    = $worst_puid;
            $results->{nth_worst_quality}->[$i]->{name}    = $worst_name;
            $results->{nth_worst_quality}->[$i]->{quality} = $worst_quality;
            $results->{nth_worst_quality}->[$i]->{combined_regex} =
              $worst_regex;
        }
    }
    my @multiple_used_regex = grep {
        my $tmp = $uniq_regexes{$_};
        my @tmp = @{$tmp};
        scalar(@tmp) > 1
    } sort keys %uniq_regexes;
    $results->{count_of_multiple_used_regex} = scalar(@multiple_used_regex);
    for ( my $i = 0 ; $i <= $#multiple_used_regex ; $i++ ) {
        $results->{multiple_used_regex}->[$i]->{regex} =
          $multiple_used_regex[$i];
        my @ids = join( ",", @{ $uniq_regexes{ $multiple_used_regex[$i] } } );
        $results->{multiple_used_regex}->[$i]->{internal_ids} = \@ids;
    }
    return $results;
}

sub print_csv_statistics {
    my $self    = shift;
    my $csv_file = shift;
    my $results = $self->_prepare_statistics();
    my $version = $results->{filename};
    $version =~ s/DROID_SignatureFile_V(\d+)\.xml/$1/;
    $results->{version}           = $version;
    $results->{best_quality_puid} = $results->{nth_best_quality}->[0]->{puid};
    $results->{best_quality_internal_id} =
      $results->{nth_best_quality}->[0]->{internal_id};
    $results->{best_quality_quality} =
      $results->{nth_best_quality}->[0]->{quality};
    $results->{best_quality_combined_regex} =
      $results->{nth_best_quality}->[0]->{combined_regex};
    $results->{worst_quality_puid} = $results->{nth_worst_quality}->[0]->{puid};
    $results->{worst_quality_internal_id} =
      $results->{nth_worst_quality}->[0]->{internal_id};
    $results->{worst_quality_quality} =
      $results->{nth_worst_quality}->[0]->{quality};
    $results->{worst_quality_combined_regex} =
      $results->{nth_worst_quality}->[0]->{combined_regex};

    my @headers =
      qw(version filename count_of_puids count_of_internal_ids count_of_regular_expressions count_of_fileendings count_of_puid_with_fileendings_only count_of_orphaned_internal_ids count_of_multiple_used_regex best_quality_puid best_quality_internal_id best_quality_quality best_quality_combined_regex worst_quality_puid worst_quality_internal_id worst_quality_quality worst_quality_combined_regex);
    my $file_exists = (-e $csv_file);
    open (my $FH, ">>", "$csv_file") or croak "Can't open file '$csv_file', $0";
    if (not $file_exists) {
        say $FH "#", join( ",", @headers );
    }
    say $FH join(
        ",",
        map {
            my $result = $results->{$_};
            if ( !defined $result ) { $result = ""; }
            "\"$result\"";
        } @headers
    );
    close ($FH);
    return;
}

sub print_statistics {
    my $self    = shift;
    my $verbose = shift;
    my $results = $self->_prepare_statistics();

    say "Statistics of file $results->{filename}";
    say "=======================================";
    say "";
    say "Countings";
    say "---------------------------------------";
    say "Count of PUIDs:                        $results->{count_of_puids}";
    say
"         internal IDs:                 $results->{count_of_internal_ids}";
    say
"         regular expressions:          $results->{count_of_regular_expressions}";
    say
      "         file endings:                 $results->{count_of_fileendings}";
    say
"         PUIDs with file endings only: $results->{count_of_puid_with_fileendings_only}";

    if ( defined $verbose ) {
        say "         (",
          join( ", ", sort @{ $results->{puids_with_fileendings_only} } ), ")";
    }
    say
"         orphaned internal IDs:        $results->{count_of_orphaned_internal_ids}";
    if ( defined $verbose ) {
        say "         (",
          join( ", ", sort {$a <=> $b} @{ $results->{internal_ids_without_puids} } ), ")";
    }
    say "";
    say "Quality of internal IDs";
    say "---------------------------------------";

    my $nth = 1;
    foreach my $n ( @{ $results->{nth_best_quality} } ) {
        say
"$nth-best quality internal ID (PUID, name):       $n->{internal_id} ($n->{puid}, $n->{name}) -> $n->{quality}";
        if ( defined $verbose ) {
            say "        combined regex: ", $n->{combined_regex};
        }
        $nth++;
    }
    say "";
    $nth = 1;
    foreach my $n ( @{ $results->{nth_worst_quality} } ) {
        say
"$nth-worst quality internal ID (PUID, name):       $n->{internal_id} ($n->{puid}, $n->{name}) -> $n->{quality}";
        if ( defined $verbose ) {
            say "        combined regex: ", $n->{combined_regex};
        }
        $nth++;
    }
    say "";

    say "";
    say "Regular expressions";
    say "---------------------------------------";
    say
"Count of multiple used regular expressions: $results->{count_of_multiple_used_regex}";
    if ( defined $verbose ) {
        for ( my $i = 0 ; $i < $results->{count_of_multiple_used_regex} ; $i++ )
        {
            say "         common regex group no $i:";
            say "            regex='"
              . $results->{multiple_used_regex}->[$i]->{regex} . "'";
            say "            internal IDs: ",
              join( ",", @{ $results->{multiple_used_regex}->[$i]->{internal_ids} } );
        }
    }
    say "";

    #my @rx = $self->get_all_regular_expressions();
    #use Data::Printer;
    #p( %uniq_regexes );
    return;
}

1;

no Moose;
__PACKAGE__->meta->make_immutable;
1;

=pod

=encoding UTF-8

=head1 NAME

File::FormatIdentification::Pronom

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use File::FormatIdentification::Pronom;
  my $pronomfile = "Droid-Signature.xml";
  my ( $signatures, $internals ) = parse_signaturefile($pronomfile);

=head1 DESCRIPTION

The module allows to handle Droid signatures. Droid is a utility which
uses the PRONOM database to identify file formats.

See https://www.nationalarchives.gov.uk/PRONOM/ for details.

With this module you could:

=over

=item convert Droid signatures to Perl regular expressions

=item analyze files and display which/where pattern of Droid signature matches  via tag-files for wxHexEditor

=item calc statistics about Droid signatures

=back

The module is in early alpha state and should not be used in production.

=head2 Examples

=head3 Colorize wxHexeditor fields

See example file F<bin/pronom2wxhexeditor.pl>. This colorizes the hex-blob to check PRONOM pattern matches for a given file.

=head3 Identify file

There are better tools for the job, but as a proof of concept certainly not bad: Identifying the file type of a file.

  my $pronom = File::FormatIdentification::Pronom->new(
    "droid_signature_filename" => $pronomfile
  );
  # .. $filestream is a scalar representing a file
  foreach my $internalid ( $pronom->get_all_internal_ids() ) {
      my $sig = $pronom->get_signature_id_by_internal_id($internalid);
      my $puid = $pronom->get_puid_by_signature_id($sig);
      my $name = $pronom->get_name_by_signature_id($sig);
      my $quality = $pronom->get_qualities_by_internal_id($internalid);
      my @regexes = $pronom->get_regular_expressions_by_internal_id($internalid);
      if ( all {$filestream =~ m/$_/saa} @regexes ) {
          say "$binaryfile identified as $name with PUID $puid (regex quality $quality)";
      }
  }

See example file F<bin/pronomidentify.pl> for a  full working script.

=head3 Get PRONOM Statistics

To get a feeling for which signatures need to be revised in PRONOM, or why which file formats are difficult to recognize,
you can get detailed statistics for given signature files.

In the blog entry under L<https://kulturreste.blogspot.com/2018/10/heres-tool-make-it-work.html> the statistic report is presented in more detail.

=head2 EXPORT

None by default.

=head1 NAME

File::FormatIdentification::Pronom - Perl extension for parsing PRONOM-Signatures using DROID-Signature file

=head1 SEE ALSO

L<File::FormatIdentification::Regex>

=head1 AUTHOR

Andreas Romeyke L<pause@andreas-romeyke.de>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018/19/20 by Andreas Romeyke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

The droid-signature file in t/ is from L<https://www.nationalarchives.gov.uk/PRONOM/Default.aspx>
and without guarantee, it does not look like it is legally protected. If there are any legal claims,
please let me know that I can remove them from the distribution.

=head1 BUGS

=over

=item Some droid recipes results in PCREs which are greedy and therefore the running
  time could be exponential with size of binary file.

=back

=head1 CONTRIBUTING

Please feel free to send me comments and patches to my email address. You can clone the modules
from L<https://art1pirat.spdns.org/art1/File-FormatIdentification-Pronom> and send me merge requests.

=head1 AUTHOR

Andreas Romeyke <pause@andreas-romeyke.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Andreas Romeyke.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
# Below is stub documentation for your module. You'd better edit it!


