package Mail::DKIM::KeyValueList;
use strict;
use warnings;
our $VERSION = '1.20220520'; # VERSION
# ABSTRACT: Represents a Key/Value list

# Copyright 2005-2007 Messiah College. All rights reserved.
# Jason Long <jlong@messiah.edu>

# Copyright (c) 2004 Anthony D. Urso. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use Carp;

sub new {
    my $class = shift;
    my %args  = @_;

    my $self = bless \%args, $class;
    return $self;
}

sub parse {
    my $self_or_class = shift;
    croak 'wrong number of arguments' unless ( @_ == 1 );
    my ($string) = @_;

    my $self = ref($self_or_class) ? $self_or_class : $self_or_class->new;

    $self->{tags}         = [];
    $self->{tags_by_name} = {};
    foreach my $raw_tag ( split /;/, $string, -1 ) {
        my $tag = { raw => $raw_tag };
        push @{ $self->{tags} }, $tag;

        # strip preceding and trailing whitespace
        $raw_tag =~ s/^\s+|\s*$//g;

        next if ( $raw_tag eq '' );

        my ( $tagname, $value ) = split( /\s*=\s*/, $raw_tag, 2 );
        unless ( defined $value ) {
            die "syntax error\n";
        }

        $tag->{name}  = $tagname;
        $tag->{value} = $value;

        $self->{tags_by_name}->{$tagname} = $tag;
    }

    return $self;
}

sub clone {
    my $self = shift;
    my $str  = $self->as_string;
    return ref($self)->parse($str);
}

sub get_tag {
    my $self = shift;
    my ($tagname) = @_;

    if ( $self->{tags_by_name}->{$tagname} ) {
        return $self->{tags_by_name}->{$tagname}->{value};
    }
    return undef;
}

sub set_tag {
    my $self = shift;
    my ( $tagname, $value ) = @_;

    if ( $tagname =~ /[;=\015\012\t ]/ ) {
        croak 'invalid tag name';
    }

    if ( defined $value ) {
        if ( $value =~ /;/ ) {
            croak 'invalid tag value';
        }
        if ( $value =~ /\015\012[^\t ]/ ) {
            croak 'invalid tag value';
        }

        if ( $self->{tags_by_name}->{$tagname} ) {
            $self->{tags_by_name}->{$tagname}->{value} = $value;
            my ( $rawname, $rawvalue ) =
              split( /=/, $self->{tags_by_name}->{$tagname}->{raw}, 2 );
            $self->{tags_by_name}->{$tagname}->{raw} = "$rawname=$value";
        }
        else {
            my $tag = {
                name  => $tagname,
                value => $value,
                raw   => " $tagname=$value"
            };
            push @{ $self->{tags} }, $tag;
            $self->{tags_by_name}->{$tagname} = $tag;
        }
    }
    else {
        if ( $self->{tags_by_name}->{$tagname} ) {
            delete $self->{tags_by_name}->{$tagname};
        }
        @{ $self->{tags} } = grep { $_->{name} ne $tagname } @{ $self->{tags} };
    }
}

sub as_string {
    my $self = shift;
    if ($Mail::DKIM::SORTTAGS) {
        return join( ';', sort map { $_->{raw} } @{ $self->{tags} } );
    }
    return join( ';', map { $_->{raw} } @{ $self->{tags} } );
}

# Start - length of the signature's prefix
# Margin - how far to the right the text can go
# Insert - characters to insert when wrapping a line
# Tags - special processing for tags
# Default - how to handle unspecified tags
# PreserveNames - if set, the name= part of the tag will be preserved
sub wrap {
    my $self = shift;
    my %args = @_;

    my $TEXTWRAP_CLASS = 'Mail::DKIM::TextWrap';
    return unless ( UNIVERSAL::can( $TEXTWRAP_CLASS, 'new' ) );

    my $result = '';
    my $wrap   = $TEXTWRAP_CLASS->new(
        Output    => \$result,
        Separator => $args{Insert} || "\015\012\t",
        Margin    => $args{Margin} || 72,
        cur       => $args{Start} || 0,
    );
    my $did_first;
    foreach my $tag ( @{ $self->{tags} } ) {
        my $tagname = $tag->{name};
        my $tagtype = $args{Tags}->{$tagname} || $args{Default} || '';

        $wrap->{Break}       = undef;
        $wrap->{BreakBefore} = undef;
        $did_first ? $wrap->add(';') : ( $did_first = 1 );

        my ( $raw_name, $raw_value ) = split( /=/, $tag->{raw}, 2 );
        unless ( $args{PreserveNames} ) {
            $wrap->flush;    #allow a break before the tag name
            $raw_name =~ s/^\s*/ /;
            $raw_name =~ s/\s+$//;
        }
        $wrap->add( $raw_name . '=' );

        if ( $tagtype eq 'b64' ) {
            $raw_value =~ s/\s+//gs;    #removes all whitespace
            $wrap->flush;
            $wrap->{Break} = qr/./;
        }
        elsif ( $tagtype eq 'list' ) {
            $raw_value =~ s/\s+/ /gs;    #reduces any whitespace to single space
            $raw_value =~ s/^\s|\s$//g;  #trims preceding/trailing spaces
            $raw_value =~ s/\s*:\s*/:/g;
            $wrap->flush;
            $wrap->{Break}       = qr/[\s]/;
            $wrap->{BreakBefore} = qr/[:]/;
        }
        elsif ( $tagtype eq '' ) {
            $raw_value =~ s/\s+/ /gs;    #reduces any whitespace to single space
            $raw_value =~ s/^\s|\s$//g;  #trims preceding/trailing spaces
            $wrap->flush;
            $wrap->{Break} = qr/\s/;
        }
        $wrap->add($raw_value);
    }

    $wrap->finish;
    parse( $self, $result );
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::DKIM::KeyValueList - Represents a Key/Value list

=head1 VERSION

version 1.20220520

=head1 AUTHORS

=over 4

=item *

Jason Long <jason@long.name>

=item *

Marc Bradshaw <marc@marcbradshaw.net>

=item *

Bron Gondwana <brong@fastmailteam.com> (ARC)

=back

=head1 THANKS

Work on ensuring that this module passes the ARC test suite was
generously sponsored by Valimail (https://www.valimail.com/)

=head1 COPYRIGHT AND LICENSE

=over 4

=item *

Copyright (C) 2013 by Messiah College

=item *

Copyright (C) 2010 by Jason Long

=item *

Copyright (C) 2017 by Standcore LLC

=item *

Copyright (C) 2020 by FastMail Pty Ltd

=back

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
