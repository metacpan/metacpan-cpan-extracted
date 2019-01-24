package Devel::CallTrace::Utils;
$Devel::CallTrace::Utils::VERSION = '0.02';
use MetaCPAN::Client;
use Module::CoreList;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
  substr_method
  substr_module_name
  substr_file_line
  is_cpan_publishedЫ
  is_core
  isin
  rle
  str_has_multiplier
  str_minus_multiplier
  str_add_multiplier
);
our %EXPORT_TAGS = ( 'ALL' => [@EXPORT_OK] );

my $mcpan = MetaCPAN::Client->new( version => 'v1' );

# return '2' if 'abc (x2)'
sub str_has_multiplier {
    my ($str) = @_;
    if ( $str =~ /\(x(\d+)\)(\n?)$/ ) {
        return $1;
    }
    return;
}

# return string without multiplier
sub str_minus_multiplier {
    my ($str) = @_;
    $str =~ s/\(x(\d+)\)//;
    return $str;
}

sub str_add_multiplier {
    my ( $str, $num ) = @_;
    $num = 1 if !defined $num;
    if ( my $n = str_has_multiplier($str) ) {
        $str = str_minus_multiplier($str);
        my $new_m = $n + $num;
        $str .= '(x' . $new_m . ')';
    }
    else {
        $str .= ' (x2)';
    }
    return $str;
}

sub rle {
    my (@a) = @_;

    my @rle;

    for ( my $i = 0 ; $i < @a ; ) {
        my $j = 1;

        for ( ; $j + $i < @a && $a[ $j + $i ] eq $a[$i] ; $j++ ) { }

        push @rle, $a[$i] . ( $j > 1 ? " (x$j)" : "" );
        $i += $j;
    }

    return @rle;
}

# 'XPortal::General::xmlescape (/media/sf_FictionHub/XPortal/General.pm:441-446)'
sub substr_file_line {
    my ($val) = @_;
    if ( $val =~ /[\w|:]+\s+\(((.*)\/)/ ) {
        return $2;
    }
    return;
}

# sub guess_lib_source { }

sub substr_method {
    my ($str) = @_;
    ( split( '::', $str ) )[-1];
}

sub substr_module_name {
    my ($sub) = @_;
    my @x = split( '::', $sub );
    return $x[0] if ( scalar @x == 1 );
    pop @x;
    return join( '::', @x );
}

sub is_cpan_published {
    my ( $pkg, $severity ) = @_;
    return 0 if !defined $pkg;
    $severity = 2 if !defined $severity;

    if ( $severity == 0 ) {
        eval { return $mcpan->module($pkg)->distribution; } or do {
            return 0;
        }
    }

    elsif ( $severity == 1 ) {
        my $expected_distro = $pkg;
        $expected_distro =~ s/::/-/g;
        eval { return $mcpan->distribution($expected_distro)->name; } or do {
            return 0;
        }
    }

    elsif ( $severity == 2 ) {
        my $expected_distro = $pkg;
        $expected_distro =~ s/::/-/g;

        my $success = eval { $mcpan->distribution($expected_distro)->name; };
        return $success if $success;

        $success = eval { $mcpan->module($pkg)->distribution; };

        if ($success) {

            # exceptions
            return $success if ( $success eq 'Moo' );
            return $success if ( $success eq 'Moose' );

            # $pkg can be Sub::Defer and $success is Sub-Quote
            my $root_namespace = ( split( '-', $success ) )[0];
            return $success if ( $pkg =~ qr/$root_namespace/ );
        }

        return 0;
    }

    else {
        die "Wrong or non implemented severity value";
    }
}

sub is_core {
    my ($pkg) = @_;
    return 0 if !defined $pkg;
    return Module::CoreList::is_core(@_);
}

sub isin($$) {
    my ( $val, $array_ref ) = @_;

    return 0 unless $array_ref && defined $val;
    for my $v (@$array_ref) {
        return 1 if $v eq $val;
    }

    return 0;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::CallTrace::Utils

=head1 VERSION

version 0.02

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
