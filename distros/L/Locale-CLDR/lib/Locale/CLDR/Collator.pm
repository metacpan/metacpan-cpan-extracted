package Locale::CLDR::Collator;

use version;
our $VERSION = version->declare('v0.46.0');

use v5.10.1;
use mro 'c3';
use utf8;
use feature 'unicode_strings';

#line 7012
use Unicode::Normalize('NFD');
use Moo;
use Types::Standard qw(Str Int Maybe ArrayRef InstanceOf RegexpRef Bool);
with 'Locale::CLDR::CollatorBase';

sub IsCLDREmpty {
	return '';
}

# Test for missing Unicode properties
BEGIN {
    our %missing_unicode_properties = ();
    my @properties = (qw(
        Block=Tangut
        Block=Tangut_Components
        Block=Tangut_Supplement
        Block=Nushu
        Block=Khitan_Small_Script
        Unified_Ideograph=True
        Block=CJK_Unified_Ideograph
        Block=CJK_Compatibility_Ideographs
        ccc=0
        ccc
    ));

    foreach my $missing (@properties) {
        $missing_unicode_properties{$missing} = 1
            unless eval "'a' =~ qr/\\p{$missing}|a/";
    }
}

sub _fix_missing_unicode_properties {
    my $self    = shift;
    my $regex   = shift;
	our %missing_unicode_properties;
    
	
	return '' unless defined $regex;
	
    foreach my $missing (keys %missing_unicode_properties) {
        $regex =~ s/\\(p)\{$missing\}/\\${1}{IsCLDREmpty}/ig
            if $missing_unicode_properties{$missing};
    }
    
    return qr/$regex/;
}


has 'type' => (
    is => 'ro',
    isa => Str,
    default => 'standard',
);

has 'locale' => (
    is => 'ro',
    isa => Maybe[InstanceOf['Locale::CLDR']],
    default => undef,
    predicate => 'has_locale',
);

has 'alternate' => (
    is => 'ro',
    isa => Str,
    default => 'noignore'
);

# Note that backwards is only at level 2
has 'backwards' => (
    is => 'ro',
    isa => Str,
    default => 'false',
);

has 'case_level' => (
    is => 'ro',
    isa => Str,
    default => 'false',
);

has 'case_ordering' => (
    is => 'ro',
    isa => Str,
    default => 'false',
);

has 'normalization' => (
    is => 'ro',
    isa => Str,
    default => 'true',
);

has 'numeric' => (
    is => 'ro',
    isa => Str,
    default => 'false',
);

has 'reorder' => (
    is => 'ro',
    isa => ArrayRef,
    default => sub { [] },
);

has 'strength' => (
    is => 'ro',
    isa => Int,
    default => 3,
);

sub _generate_derived_ce {
    my ($self, $character) = @_;

    my $aaaa;
    my $bbbb;

    if ( $character =~ $self->_fix_missing_unicode_properties( '(?!\p{Cn})(?:\p{Block=Tangut}|\p{Block=Tangut_Components}|\p{Block=Tangut_Supplement})' )) {
        $aaaa = 0xFB00;
        $bbbb = (ord($character) - 0x17000) | 0x8000;
    }
    elsif ($character =~ $self->_fix_missing_unicode_properties( '(?!\p{Cn})\p{Block=Nushu}' )) {
        $aaaa = 0xFB01;
        $bbbb = (ord($character) - 0x1B170) | 0x8000;
    }
    elsif ($character =~ $self->_fix_missing_unicode_properties( '(?=\p{Unified_Ideograph=True})(?:\p{Block=CJK_Unified_Ideographs}|\p{Block=CJK_Compatibility_Ideographs})' )) {
        $aaaa = 0xFB40 + (ord($character) >> 15);
        $bbbb = (ord($character) & 0x7FFFF) | 0x8000;
    }
    elsif ($character =~ $self->_fix_missing_unicode_properties( '(?=\p{Unified_Ideograph=True})(?!\p{Block=CJK_Unified_Ideographs})(?!\p{Block=CJK_Compatibility_Ideographs})' )) {
        $aaaa = 0xFB80 + (ord($character) >> 15);
        $bbbb = (ord($character) & 0x7FFFF) | 0x8000;
    }
    else {
        $aaaa = 0xFBC0 + (ord($character) >> 15);
        $bbbb = (ord($character) & 0x7FFFF) | 0x8000;
    }
    return [[$aaaa, 0x0020, 0x0002], [$bbbb, 0, 0]];
}

sub _process_variable_weightings {
    my ($self, $ces) = @_;
    return $ces if $self->alternate() eq 'noignore';

    foreach my $ce (@$ces) {
        if ($ce->[0] <= $self->max_variable_weight && $ce->[0] >= $self->min_variable_weight) {
            # Variable waighted codepoint
            if ($self->alternate eq 'blanked') {
                @$ce = qw(0 0 0);

            }
            if ($self->alternate eq 'shifted') {
                my $l4;
                if ($ce->[0] == 0 && $ce->[1] == 0 && $ce->[2] == 0) {
                    $ce->[3] = 0;
                }
                else {
                    $ce->[3] = $ce->[1];
                }
                @$ce[0 .. 2] = qw(0 0 0);
            }
            $self->_in_variable_weigting(1);
        }
        else {
            if ($self->_in_variable_weigting()) {
                if( $ce->[0] == 0 && $self->alternate eq 'shifted' ) {
                    $ce->[3] = 0;
                }
                elsif($ce->[0] != 0) {
                    $self->_in_variable_weigting(0);
                    if ( $self->alternate eq 'shifted' ) {
                        $ce->[3] = 0xFFFF;
                    }
                }
            }
        }
    }
    
    return $ces;
}

sub get_collation_elements {
    my $self = shift;
    my $string = shift;
    my $ces = [];
    
    
    while ($string) {
        my ($match3) = $string =~ /^(...)/;
        my ($match2) = $string =~ /^(..)/;
        my ($match1) = $string =~ /^(.)/;
        my $ce;
    
        my $matched = '';
        $match1 //= '';
        $match2 //= '';
        $match3 //= '';
    
        if ($self->collation_elements->{$match3}) {
            $matched = $match3;
            $string =~ s/^...//;
            $ce = $self->collation_elements->{$match3};
        }
        elsif ($self->collation_elements->{$match2}) {
            $matched = $match2;
            $string =~ s/^..//;
            $ce = $self->collation_elements->{$match2};
        }
        elsif ($self->collation_elements->{$match1}) {
            $matched = $match1;
            $string =~ s/^.//;
            $ce = $self->collation_elements->{$match1};
        }
    
        if ($matched) {
            my $regex = '';
            if (_fix_missing_unicode_properties('ccc=0') !~ /IsCLDREmpty/) {
                $regex = eval 'qr/^(\\P{ccc=0}+)/';
            }
            elsif (_fix_missing_unicode_properties('ccc') !~ /IsCLDREmpty/) {
                $regex = eval 'qr/^(\\p{ccc}+)/';
            }
            if ($regex && (my ($ccc) = $string =~ $regex)) {
                foreach my $cp (split //, $ccc) {
                    my $new_match = "$matched$cp";
                    if ($self->collation_elements->{$new_match}) {
                        $matched = $new_match;
                        $string =~ s/^.*?\K$cp//;
                        $ce = $self->collation_elements->{$new_match};
                    }
                }
            }
        }
        
        if (! @$ce) {
            $ce = $self->_generate_derived_ce($match1);
        }
        
        push @$ces, @{$self->_process_variable_weightings($ce)};
    }
    
    return $ces;
}

# Converts $string into a sort key. Two sort keys can be correctly sorted by cmp
sub get_sort_key {
    my ($self, $string) = @_;

    $string = NFD($string) if $self->normalization eq 'true';

    my @sort_key;

    my $ces = $self->get_collation_elements($string);

    for (my $count = 0; $count < $self->strength(); $count++ ) {
        if ($count == 1 && $self->backwards ne 'noignore') {
            foreach my $ce (reverse @$ces) {
                if ($ce->[$count]) {
                    push @sort_key, $ce->[$count];
                }
            }
        }
        else {
            foreach my $ce (@$ces) {
                if ($ce->[$count]) {
                    push @sort_key, $ce->[$count];
                }
            }
        }
        push @sort_key, 0;
    }

    return join '', map { chr $_ } @sort_key;
}

sub sort {
    my $self = shift;
    my @elements = @_;
    
    return sort { $self->cmp($a,$b) } @elements;
}

sub cmp {
    my $self = shift;
    my $s1 = shift;
    my $s2 = shift;
    
    my $sk1 = $self->get_sort_key($s1);
    my $sk2 = $self->get_sort_key($s2);
    
    return $sk1 cmp $sk2;
}

sub eq {
    my $self = shift;
    
    return $self->cmp(@_) == 0 ? 1 : 0;
}

sub ne {
    my $self = shift;
    
    return $self->cmp(@_) == 0 ? 0 : 1;
}

sub lt {
    my $self = shift;
    
    return $self->cmp(@_) == -1 ? 1 : 0;
}

sub gt {
    my $self = shift;
    
    return $self->cmp(@_) == 1 ? 1 : 0;
}

no Moo;

1;

# vim: tabstop=4
