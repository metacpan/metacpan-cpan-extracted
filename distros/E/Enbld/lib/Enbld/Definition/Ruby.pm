package Enbld::Definition::Ruby;

use strict;
use warnings;

use parent qw/Enbld::Definition/;

require Enbld::Home;

sub initialize {
    my $self = shift;

    $self->SUPER::initialize;

    $self->{defined}{ArchiveName}    = 'ruby';
    $self->{defined}{WebSite}        = 'https://www.ruby-lang.org';
    $self->{defined}{VersionForm}    = '\d\.\d\.\d(-p\d{1,3})?';
    $self->{defined}{Dependencies}   = [ 'openssl' ];
    $self->{defined}{DownloadSite}   = 'https://ftp.ruby-lang.org/pub/ruby/';

    $self->{defined}{VersionList}       =   \&set_versionlist;
    $self->{defined}{URL}               =   \&set_url;
 
    $self->{defined}{AdditionalArgument} = \&set_argument;
    $self->{defined}{SortedVersionList}  = \&set_sorted_version_list;

    return $self;
}

sub set_sorted_version_list {
    my $attributes = shift;

    my @sorted = sort { $a cmp $b } @{ $attributes->VersionList };

    return \@sorted;
}

sub set_argument {
    return "--with-openssl-dir=" . Enbld::Home->library;
}

sub set_versionlist {
    my $attributes = shift;

    require Enbld::HTTP;
    my $first_html = Enbld::HTTP->get_html( $attributes->IndexSite );

    my $first_list = $first_html->parse_version(
            quotemeta( '<a href="') . '\d\.\d/' . quotemeta( '">' ),
            '\d\.\d'
            );

    my @versionlist;
    for my $ver ( @{ $first_list } ) {
        my $html = Enbld::HTTP->get_html( $attributes->IndexSite . $ver );
        my $list = $html->parse_version(
                $attributes->IndexParserForm,
                $attributes->VersionForm,
                );

        for my $version ( @{ $list } ) {
            push @versionlist, $version;
        }
    }

    return \@versionlist;
}

sub set_url {
    my $attributes = shift;

    my $ver = $attributes->Version;

    my $major;
    if ( $ver =~ /^(\d\.\d)\.\d.*$/ ) {
        $major = $1;
    }

    my $filename = $attributes->Filename;
    my $url = $attributes->DownloadSite . $major . '/' . $filename;

    return $url;
}

1;

=pod

=head1 NAME

Enbld::Definition::Ruby - definition module for Ruby Programming Language

=head1 SEE ALSO

L<Ruby Programming Language|https://www.ruby-lang.org>

L<Enbld::Definition>

=head1 COPYRIGHT

copyright 2013- Magnolia C<< <magnolia.k@me.com> >>.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
