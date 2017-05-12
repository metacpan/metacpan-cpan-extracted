package Hash::Tabular::Markdown;
use 5.008001;
use strict;
use warnings;
use Data::Dumper;

our $VERSION = "0.03";

our $Delimit = "|";

our $DataDumperFunciton = sub {
    my ($value) = @_;
    return $value unless (ref($value));
    {
        local $Data::Dumper::Terse  = 1;
        local $Data::Dumper::Indent = 0;
        return Data::Dumper::Dumper($value);
    }
};

sub tabulate {
    my ($class, $hashref) = @_;

    return "require hash ref." unless ( ref($hashref) eq 'HASH' );

    my $md = _to_md($hashref);
    return $md;
}

sub _to_md {
    my ($content) = @_;

    my $dth = _hash_nest_depth( $content, 0 );
    my $md;
    my $delimit = $Delimit;
    $md .= $delimit . $delimit x $dth . "\n";
    $md .= $delimit . ":--$delimit" x $dth . "\n";
    my $nest = [$delimit];
    _to_table( $content, \$md, $nest );

    # $md =~ s/\n\n+/\n/g;
    return $md;
}

sub _hash_nest_depth {
    my ( $content, $dth ) = @_;

    my $max = $dth;
    $max++;
    $dth++;
    if ( ref($content) eq 'HASH' ) {
        foreach my $ky ( keys %$content ) {
            my $new = _hash_nest_depth( $content->{$ky}, $dth );
            $max = $max < $new ? $new : $max;
        }
    }
    return $max;
}

sub _dump {
    my ($content) = @_;
    return $DataDumperFunciton->($content);
}

sub _to_table {
    my ( $content, $md, $nest ) = @_;

    my $lf;
    if ( ref($content) eq 'HASH' && keys(%$content)) {
        foreach my $ky ( keys %$content ) {
            if ($lf) {
                $$md .= join( '', @$nest ) . _dump($ky);
                $lf = undef;
            }
            else {
                $$md .= $nest->[0] . _dump($ky);
            }
            push @$nest, $nest->[0];
            $lf = _to_table( $content->{$ky}, $md, $nest );
            pop @$nest;
        }
    }
    else {
        $$md .= "|" . _dump($content);
        $$md .= "\n";
        return 1;
    }
    return $lf;
}

1;
__END__

=encoding utf-8

=head1 NAME

Hash::Tabular::Markdown - Tabulate hashref to markdown table format.

=head1 SYNOPSIS

    use Hash::Tabular::Markdown;

=head1 DESCRIPTION

Hash::Tabular::Markdown is dump hashref as markdown table format string.

=head1 VALIABLES

=over 4

=item $Hash::Tabular::Markdown::Delimit

    delimit for markdown table

=back

=head1 METHODS

=over 4

=item tabulate

    my $hashref = { 1 => 2 };
    my $md = Hash::Tabular::Markdown->tabulate($hashref);

convert hashref to markdown table.

=back

=head1 LICENSE

Copyright (C) Tomoo Amano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Tomoo Amano E<lt>sheercat@gmail.comE<gt>

=cut

