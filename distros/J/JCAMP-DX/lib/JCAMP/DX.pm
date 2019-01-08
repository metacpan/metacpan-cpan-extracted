#------------------------------------------------------------------------------
#$Author: andrius $
#$Date: 2018-12-20 11:24:42 +0200 (Kt, 20 gruod. 2018) $
#$Revision: 78 $
#$URL: svn+ssh://www.crystallography.net/home/coder/svn-repositories/jcamp-dx/tags/v0.02/lib/JCAMP/DX.pm $
#------------------------------------------------------------------------------
#*
#  Parser for JCAMP-DX format.
#**

package JCAMP::DX;

use strict;
use warnings;
use JCAMP::DX::LabelDataRecord;

our $VERSION = '0.02';

sub new
{
    my( $class, $title ) = @_;
    my $self = bless {
        labels => [],
        data   => {},
        blocks => [],
    }, $class;

    if( $title ) {
        $self->push_LDR( JCAMP::DX::LabelDataRecord->new( 'TITLE', $title ) );
    }

    return $self;
}

sub new_from_file
{
    my( $class, $filename, $options ) = @_;
    open( my $inp, $filename );

    ${$options->{store_file}} = '' if $options->{store_file};

    my $title = <$inp>;
    ${$options->{store_file}} .= $title if $options->{store_file};
    $title =~ s/^\s*##title=//i;
    $title =~ s/\r?\n$//;

    my $block = $class->new_from_fh( $inp, $title, $options );

    close $inp;
    return $block;
}

sub new_from_fh
{
    my( $class, $inp, $title, $options ) = @_;
    my $block = $class->new();
    my( $last_label, $buffer ) = ( 'title', $title );
    while( my $line = <$inp> ) {
        ${$options->{store_file}} .= $line if $options->{store_file};
        $line =~ s/\$\$.*$//; # removing comments
        $line =~ s/\r?\n$//;     # removing newlines
        next if $line =~ /^\s*$/;
        last if $line =~ /^\s*##end=/i;
        if( $line =~ s/^\s*##title=//i ) {
            if( defined $last_label && $last_label ne '' ) {
                $block->push_LDR(
                     JCAMP::DX::LabelDataRecord->new( $last_label, $buffer )
                );
                undef $last_label;
                undef $buffer;
            }
            $block->push_block( $class->new_from_fh( $inp, $line, $options ) );
        } elsif( $line =~ /^\s*##([^=]*)=(.*)$/ ) {
            if( defined $last_label && $last_label ne '' ) {
                $block->push_LDR(
                     JCAMP::DX::LabelDataRecord->new( $last_label, $buffer )
                );
            }
            ( $last_label, $buffer ) = ( $1, $2 );
        } elsif( $block->{labels} ) {
            $buffer .= "\n$line";
        }
    }

    if( defined $last_label && $last_label ne '' ) {
        $block->push_LDR(
            JCAMP::DX::LabelDataRecord->new( $last_label, $buffer )
        );
    }

    return $block;
}

sub push_block
{
    my( $self, $block ) = @_;
    push @{$self->{blocks}}, $block;
}

sub push_LDR
{
    my( $self, $ldr ) = @_;

    if( exists $self->{data}{$ldr->canonical_label} ) {
        warn "duplicate values for label '" . $ldr->canonical_label .
             "' were found, will not overwrite";
        return;
    }

    push @{$self->{labels}}, $ldr;
    $self->{data}{$ldr->canonical_label} = $ldr;
}

sub title
{
    return $_[0]->{data}{TITLE}->value;
}

sub order_labels
{
    my( $self ) = @_;

    $self->{labels} = [
        (exists $self->{data}{TITLE}   ? $self->{data}{TITLE} : () ),
        (exists $self->{data}{JCAMPDX} ? $self->{data}{JCAMPDX} : () ),
        grep { $_->label ne 'TITLE' && $_->label ne 'JCAMP-DX' }
             @{$self->{labels}} ];
}

sub to_string
{
    my( $self ) = @_;
    my $output = '';

    for my $label (@{$self->{labels}}) {
        $output .= $label->to_string;
    }

    for my $block (@{$self->{blocks}}) {
        $output .= $block->to_string;
    }

    $output .= "##END=\n";
    return $output;
}

1;
