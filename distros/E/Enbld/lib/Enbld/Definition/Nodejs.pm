package Enbld::Definition::Nodejs;

use strict;
use warnings;

use parent qw/Enbld::Definition/;

use version;

sub initialize {
    my $self = shift;

    $self->SUPER::initialize;

    $self->{defined}{ArchiveName}       =   'node';
    $self->{defined}{WebSite}           =   'http://nodejs.org';
    $self->{defined}{VersionForm}       =   'v\d\.\d{1,2}\.\d{1,2}';
    $self->{defined}{DownloadSite}      =   'http://nodejs.org/dist/';
    $self->{defined}{AllowedCondition}  =   'development';
    $self->{defined}{Version}           =   \&evaluate_version;

    $self->{defined}{VersionList}       =   \&set_versionlist;
    $self->{defined}{URL}               =   \&set_url;

    $self->{defined}{TestAction}        =   'test';

    return $self;
}

sub set_versionlist {
    my $attributes = shift;

    require Enbld::HTTP;
    my $html = Enbld::HTTP->get_html( $attributes->IndexSite );

    my $list = $html->parse_version(
            quotemeta( '<a href="') .
            'v\d\.\d{1,2}\.\d{1,2}/' .
            quotemeta( '">' ),
            'v\d\.\d{1,2}\.\d{1,2}'
            );

    return $list;
}

sub evaluate_version {
    my $attributes = shift;

    my $list = $attributes->VersionList;
    my ( $stable, $development ) = parse_version_list( $list );

    my $condition = $attributes->VersionCondition;
    return $stable      if ( $condition eq 'latest' );
    return $development if ( $condition eq 'development' );
    return $condition   if ( grep { $condition eq $_ } @{ $list} );

    require Enbld::Error;
    die( Enbld::Error->new(
                "Invalid Version Condition:$condition, ".
                "please check install condition"
                ));
}

sub parse_version_list {
    my $list = shift;

    my @stable;
    my @development;

    foreach my $version ( @{ $list } ) {
        my @frag = split( /\./, $version );

        if ( $frag[1] % 2 == 0 ) {
            push @stable, $version;
        } else {
            push @development, $version;
        }
    }

    my @stable_sorted = sort {
        version->declare( $a ) cmp version->declare( $b )
    } @stable;

    my @development_sorted = sort {
        version->declare( $a ) cmp version->declare( $b )
    } @development;

    return ( $stable_sorted[-1], $development_sorted[-1] );
}


sub set_url {
    my $attributes = shift;

    my $ver = $attributes->Version;

    my $filename = $attributes->Filename;
    my $url = $attributes->DownloadSite . $ver . '/' . $filename;

    return $url;
}

1;

=pod

=head1 NAME

Enbld::Definition::Nodejs - definition module for node.js

=head1 SEE ALSO

L<node.js|http://nodejs.org>

L<Enbld::Definition>

=head1 COPYRIGHT

copyright 2013- Magnolia C<< <magnolia.k@me.com> >>.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
