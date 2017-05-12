package Enbld::Definition::Perl;

use strict;
use warnings;

use version;

use parent qw/Enbld::Definition/;

require Enbld::Feature;

sub initialize {
    my $self = shift;

    $self->SUPER::initialize;

    $self->{defined}{ArchiveName}           =   'perl';
    $self->{defined}{WebSite}               =   'http://www.perl.org';
    $self->{defined}{VersionForm}           =   '5\.\d{1,2}\.\d{1,2}';
    $self->{defined}{DistName}              =   'TMTOWTDI';
    $self->{defined}{AllowedCondition}      =   'development';
    $self->{defined}{DownloadSite}          =   'http://www.cpan.org/src/5.0/';
    $self->{defined}{Version}               =   \&evaluate_version;
    $self->{defined}{Prefix}                =   '-Dprefix=';
    $self->{defined}{AdditionalArgument}    =   \&set_argument;

    $self->{defined}{TestAction}        =   'test';

    $self->{defined}{CommandConfigure}  =   'sh Configure -de';

    return $self;
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

sub set_argument {
    my $attributes = shift;

    my $argument = " ";

    unless ( _is_stable( $attributes ) ) {
        $argument .= '-Dusedevel';
    }

    return $argument;
}

sub _is_stable {
    my $attributes = shift;

    my $version = $attributes->Version;

    my @frag = split( /\./, $version );

    if ( $frag[1] % 2 == 0 ) {
        return $version;
    }

    return;
}

1;

=pod

=head1 NAME

Enbld::Definition::Perl - definition module for The Perl Programming Language

=head1 INSTALL DEVELOPMENT VERSION

Definition module for Perl supports installation for development version of perl.Set attribute 'VersionCondition' to 'development', install latest development version of perl(e.g. 5.19.1).

  target 'perl' => {
      version 'development';
      # -> $attributes->add( 'VersionCondition', 'development' );
  };

  # -> install odd numbers version(e.g. 5.19.1)


=head1 INSTALL MODULES

Definition module for Perl supports installation for CPAN modules by specified cpanfile.

  target 'perl' => {
  	  version 'latest';
      module_file 'cpanfile';
  };

=head1 SEE ALSO

L<The Perl Programming Language|http://www.perl.org>

L<Enbld::Definition>

=head1 COPYRIGHT

copyright 2013- Magnolia C<< <magnolia.k@me.com> >>.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
