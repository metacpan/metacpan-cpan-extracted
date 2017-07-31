package MARC::Xform::AddRDA33x;

use strict;
use warnings;

use MARC::Loop qw(marcparse marcfield marcbuild TAG VALREF SUBS SUB_ID SUB_VALREF);

my (%a2b, %b2a, %tag2src, %act2descrip);
my %len2tag = qw(
    3 336
    1 337
    2 338
);

# --- Create a transformation

sub new {
    my $cls = shift;
    my $self = bless { 'minsize' => 1, @_ }, $cls;
    build_mappings() if !%a2b;
    my $rules = $self->rules;
    my $vocab = $self->vocabulary;
    $vocab = $self->read_vocabulary($vocab) if !ref $vocab;
    $rules = $self->read_rules($rules) if !ref $rules;
    return sub {
        my ($bib) = @_;
        my ($leader, $fields, $marcref, $anno) = @$bib;
        my (@sig, %result, @add, $fixed);
        my @f33x;
        @f33x = grep { $_->[TAG] =~ /^33[678]/ } @$fields
            if !$self->{'replace'};
        my $force = $self->{'force'};
        foreach (@f33x) {
            my $tag = $_->[TAG];
            my @subs = subfields($_);
            my ($sb) = map { ${ $_->[SUB_VALREF] } } grep { $_->[SUB_ID] eq 'b' } @subs;
            my ($s2) = map { ${ $_->[SUB_VALREF] } } grep { $_->[SUB_ID] eq '2' } @subs;
            my ($sa) = map { ${ $_->[SUB_VALREF] } } grep { $_->[SUB_ID] eq 'a' } @subs;
            next if defined $sb
                 || !defined $s2
                 || $s2 !~ /^rda/
                 || !defined $sa;
            $sa =~ s/^\s+|\s+$//g;
            $sa =~ tr/A-Z/a-z/;
            $sb = $a2b{$tag}{$sa};
            next if !defined $sb;
            splice @$_, SUBS;
            push @$_, (
                ['a' => \$sa ],
                ['b' => \$sb ],
                ['2' => \$s2 ],
            );
            $anno->{'result'}{'fixed'}{$tag} = $fixed = 1;
        }
        if ($fixed) {
            # Nothing special to do
        }
        elsif (@f33x && !$force) {
            $anno->{'result'}{'skip'} = 1;
        }
        elsif ($self->{'add'}) {
            @add = @f33x if $force;
            push @add, map { mk33x($len2tag{length $_} || die("I don't know how to add code $_"), $_) } @{ $self->{'add'} };
        }
        else {
            my $ldr06 = substr($leader, 6, 1);
            my @f007val = map { substr(${$_->[VALREF]}, 0, 2) } grep { $_->[TAG] eq '007' } @$fields;
            @f007val = qw(--) if !@f007val;
            @sig = map { $ldr06 . $_ } @f007val;
            my %added;
            foreach my $s (@sig) {
                my $rule = $rules->{$s} or next;
                my ($act, @fields) = $rule->{'code'}->($self, $s, $leader, $fields);
                $anno->{'result'}{'skip'} = 1, next if $act eq '';
                if (@fields) {
                    $anno->{'result'}{'add'} = \@add;
                    foreach (map { split /,/ } @fields) {
                        s/^\s+|\s+$//g;
                        next if $added{$_}++;
                        push @add, mk33x($len2tag{length $_} || die("I don't know how to add code $_"), $_);
                    }
                    $anno->{'result'}{'flagged'} = 1 if $act eq 'flag';
                    push @{ $anno->{'result'}{'rule'} ||= [] }, $rule;
                }
            }
        }
        @$fields = (
            ( grep { $_->[TAG] lt '336'      } @$fields ),
            ( sort { $a->[TAG] cmp $b->[TAG] } @add,   ),
            ( grep { $_->[TAG] gt '338'      } @$fields ),
        ) if @add;
        return [$leader, $fields, undef, $anno];
    }
}

# --- Supporting functions

sub rules { $_[0]->{'rules'} }
sub vocabulary { $_[0]->{'vocabulary'} }

sub read_vocabulary {
    my ($self, $f) = @_;
    open my $fh, '<', $f
        or die "Can't open $f for reading: $!";
    my (%vocab, $sec);
    my $n = 0;
    while (<$fh>) {
        chomp;
        if (/^\[(.+?)\](?:\s+"(.+)")?(?:\s+<([^<>]+)>)?$/) {
            my ($v, $d) = ($1, $2 || $1);
            $sec = $vocab{$v} ||= {};
            $sec->{'order'} = ++$n;
            $sec->{'code'} = $v;
            $sec->{'descrip'} = $d;
            $sec->{'link'} = $3 if defined $3;
            $sec->{'terms'} = {};
        }
        elsif (!$sec) {
            die "Term outside of section: $_";
        }
        elsif (/^(\S+) = (.+)$/) {
            $sec->{'terms'}{$1} = {
                'code' => $1,
                'descrip' => $2,
                'count' => -1,
            };
        }
        elsif (/^\s*(?:#.*)?$/) {
            next;
        }
        else {
            die "Bad line in terms: $_";
        }
    }
    close $fh;
    # Build record signature terms XXX I should really do this outside of this script
    my $pfx = $vocab{'sig'}{'prefix'};
    if ($pfx) {
        my $db;  # XXX
        my $terms = $vocab{'sig'}{'terms'} ||= {};
        my $iter = $db->allterms_begin($pfx);
        if ($iter) {
            do {
                my $code = substr($iter->get_termname, length($pfx));
                my $rtyp = substr($code, 0, 1);
                my $mtyp = substr($code, 1);
                my $descrip = join(' - ',
                    $vocab{'rtyp'}{'terms'}{$rtyp}{'descrip'} // '(unrecognized record type)',
                    $vocab{'mtyp'}{'terms'}{$mtyp}{'descrip'} // '(unrecognized material type)',
                );
                $terms->{$code} = {
                    'code' => $code,
                    'descrip' => $descrip,
                    'count' => $iter->get_termfreq,
                };
            } while $iter++
        }
    }
    return $self->{'vocabulary'} = \%vocab;
}

sub read_rules {
    my ($self, $f) = @_;
    open my $fh, '<', $f
        or die "Can't open $f for reading: $!";
    my %rule;
    my $vocab = $self->vocabulary;
    while (<$fh>) {
        next if !s/^>\s+//;
        chomp;
        my ($sig, $act, $f336b, $f337b, $f338b) = split /\s+/, $_;
        my %r = (
            'sig' => $sig,
            'code336' => $f336b,
            'code337' => $f337b,
            'code338' => $f338b,
        );
        if ($act eq '-') {
            $r{'action'} = $act = 'skip';
            $r{'code'} = sub { $act };
        }
        elsif ($act eq '?') {
            $r{'action'} = $act = 'query';
            $r{'code'} = sub { 'query' };
        }
        elsif ($act =~ /^\(([a-z]+)\)$/) {
            $r{'action'} = $act = 'special';
            $r{'code'} = $self->can("rule_$1") or die "No rule handler: $1";
        }
        else {
            $r{'action'} = $act = $act eq '*' ? 'flag' : 'add';
            $r{'code'} = sub { $act, $f336b, $f337b, $f338b };
        }
        my $pfx = $vocab->{'sig'}{'prefix'};
        $r{'actiondescrip'} = $act2descrip{$r{'action'}};
        $rule{$sig} = \%r;
    }
    return $self->{'rules'} = \%rule;
}

sub build_mappings {
    my %f336a2b = (
        q{cartographic dataset} => q{crd},
        q{cartographic image} => q{cri},
        q{cartographic moving image} => q{crm},
        q{cartographic tactile image} => q{crt},
        q{cartographic tactile three-dimensional form} => q{crn},
        q{cartographic three-dimensional form} => q{crf},
        q{computer dataset} => q{cod},
        q{computer program} => q{cop},
        q{notated movement} => q{ntv},
        q{notated music} => q{ntm},
        q{performed music} => q{prm},
        q{sounds} => q{snd},
        q{spoken word} => q{spw},
        q{still image} => q{sti},
        q{tactile image} => q{tci},
        q{tactile notated music} => q{tcm},
        q{tactile notated movement} => q{tcn},
        q{tactile text} => q{tct},
        q{tactile three-dimensional form} => q{tcf},
        q{text} => q{txt},
        q{three-dimensional form} => q{tdf},
        q{three-dimensional moving image} => q{tdm},
        q{two-dimensional moving image} => q{tdi},
        q{other} => q{xxx},
        q{unspecified} => q{zzz},
    );
    my %f337a2b = (
        q{audio} => q{s},
        q{computer} => q{c},
        q{microform} => q{h},
        q{microscopic} => q{p},
        q{projected} => q{g},
        q{stereographic} => q{e},
        q{unmediated} => q{n},
        q{video} => q{v},
        q{other} => q{x},
        q{unspecified} => q{z},
    );
    my %f338a2b = (
        q{audio cartridge} => q{sg},
        q{audio cylinder} => q{se},
        q{audio disc} => q{sd},
        q{sound track reel} => q{si},
        q{audio roll} => q{sq},
        q{audiocassette} => q{ss},
        q{audiotape reel} => q{st},
        q{other} => q{sz},
        q{computer card} => q{ck},
        q{computer chip cartridge} => q{cb},
        q{computer disc} => q{cd},
        q{computer disc cartridge} => q{ce},
        q{computer tape cartridge} => q{ca},
        q{computer tape cassette} => q{cf},
        q{computer tape reel} => q{ch},
        q{online resource} => q{cr},
        q{other} => q{cz},
        q{aperture card} => q{ha},
        q{microfiche} => q{he},
        q{microfiche cassette} => q{hf},
        q{microfilm cartridge} => q{hb},
        q{microfilm cassette} => q{hc},
        q{microfilm reel} => q{hd},
        q{microfilm roll} => q{hj},
        q{microfilm slip} => q{hh},
        q{microopaque} => q{hg},
        q{other} => q{hz},
        q{microscope slide} => q{pp},
        q{other} => q{pz},
        q{film cartridge} => q{mc},
        q{film cassette} => q{mf},
        q{film reel} => q{mr},
        q{film roll} => q{mo},
        q{filmslip} => q{gd},
        q{filmstrip} => q{gf},
        q{filmstrip cartridge} => q{gc},
        q{overhead transparency} => q{gt},
        q{slide} => q{gs},
        q{other} => q{mz},
        q{stereograph card} => q{eh},
        q{stereograph disc} => q{es},
        q{other} => q{ez},
        q{card} => q{no},
        q{flipchart} => q{nn},
        q{roll} => q{na},
        q{sheet} => q{nb},
        q{volume} => q{nc},
        q{object} => q{nr},
        q{other} => q{nz},
        q{video cartridge} => q{vc},
        q{videocassette} => q{vf},
        q{videodisc} => q{vd},
        q{videotape reel} => q{vr},
        q{other} => q{vz},
        q{unspecified} => q{zu},
    );
    my %f336b2a = reverse %f336a2b;
    my %f337b2a = reverse %f337a2b;
    my %f338b2a = reverse %f338a2b;
    %a2b = (
        '336' => \%f336a2b,
        '337' => \%f337a2b,
        '338' => \%f338a2b,
    );
    %b2a = (
        '336' => \%f336b2a,
        '337' => \%f337b2a,
        '338' => \%f338b2a,
    );
    %tag2src = qw(
        336 rdacontent
        337 rdamedia
        338 rdacarrier
    );
    %act2descrip = (
        'add'    => 'add fields',
        'flag'   => 'add fields but flag for review',
        'skip'   => 'do not attempt to add 33x fields',
        'fix'    => 'fix existing 33x fields',
        'ignore' => 'leave existing 33x fields unmodified',
        'query'  => 'appropriate action is under review',
        '???'    => 'no criteria apply',
    );
}

sub mk33x {
    my ($tag, $bval) = @_;
    marcfield($tag, ' ', ' ', 'a' => $b2a{$tag}{$bval}, 'b' => $bval, '2' => $tag2src{$tag});
}

sub subfields {
    my ($field) = @_;
    return @$field[SUBS..$#$field];
}

sub subval1 {
    my ($fields, $tagsub) = @_;
    my ($tag, $sub) = ( $tagsub =~ /^(...)(.)$/ );
    foreach (grep { $_->[TAG] eq $tag } @$fields) {
        my ($sub) = grep { $_->[SUB_ID] eq $sub } subfields($_);
        return ${ $sub->[SUB_VALREF] } if $sub;
    }
}

sub rule_a {
    my ($self, $sig, $leader, $fields) = @_;
    return 'skip' if @$fields < $self->{'minsize'};
    my $f245h = subval1($fields, '245h');
    if ($f245h) {
        return qw(add txt c cr)
            if $f245h =~ /electronic resource/i;
    }
    return qw(add txt n nc);
}

sub rule_acr {
    my ($self, $sig, $leader, $fields) = @_;
    return 'skip' if @$fields < $self->{'minsize'};
    my $f245h = subval1($fields, '245h');
    if ($f245h) {
        return qw(add txt c cr)
            if $f245h =~ /electronic resource/i;
    }
    return 'skip';  # XXX Remove this restriction later?
    return qw(add txt c cr);
}

sub rule_c {
    my ($self, $sig, $leader, $fields) = @_;
    my $f300a = subval1($fields, '300a') or return 'skip';
    return qw(flag ntm n nc)
        if $f300a =~ /^\bscores?\b/;
    my $f245h = subval1($fields, '245h') or return 'skip';
    return qw(flag ntm c cd)
        if $f300a =~ /\d CD-ROM/
        && $f245h =~ /electronic resource/;
}

sub rule_m {
    my ($self, $sig, $leader, $fields) = @_;
    my $f245h = subval1($fields, '245h') or return 'skip';
    my $f516a = subval1($fields, '516a') or return 'skip';
    return qw(flag tdi c cr)
        if $f516a =~ /Streaming video/
        && $f245h =~ /electronic resource/;
}

sub rule_j {
    my ($self, $sig, $leader, $fields) = @_;
    my $f245h = subval1($fields, '245h');
    if ($f245h) {
        return qw(flag prm c cr) if $f245h =~ /electronic resource/;
    }
    return 'skip';
}

sub rule_k {
    my ($self, $sig, $leader, $fields) = @_;
    my $f245h = subval1($fields, '245h');
    if ($f245h) {
        return qw(flag sti n no) if $f245h =~ /(flash|activity) card/;
        return qw(flag sti n nb) if $f245h =~ /study print|picture|poster/;
    }
    my $f300a = subval1($fields, '300a');
    if ($f300a) {
        return qw(flag sti n no) if $f300a =~ /\d (post|activity )cards?\b/;
        return qw(flag sti n nb) if $f300a =~ /\d posters?\b/;
    }
}

sub rule_g {
    my ($self, $sig, $leader, $fields) = @_;
    my $f245h = subval1($fields, '245h') or return 'skip';
    if ($f245h =~ /\bDVD\b/) {
        return qw(flag tdi v vd);
    }
    elsif ($f245h =~ /\b(videorecording|motion picture)\b/) {
        my $f300a = subval1($fields, '300a') or return 'skip';
        return qw(flag tdi g mr) if $f300a =~ /\d (film )?reel/;
        return qw(flag tdi v vd) if $f300a =~ /videodisc|dvd/i;
        return qw(flag tdi v vf) if $f300a =~ /videocas+et+e/;
        my $f300c = subval1($fields, '300c') or return 'skip';
        return qw(flag tdi g mr) if $f300c =~ /^\d+ *mm/;
    }
    elsif ($f245h =~ /\b(slide)\b/) {
        return qw(flag sti g gs);
    }
}

1;
