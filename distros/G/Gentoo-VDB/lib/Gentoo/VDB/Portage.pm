use 5.006;    # our
use strict;
use warnings;

package Gentoo::VDB::Portage;

our $VERSION = '0.001002';

# ABSTRACT: VDB Query Implementation for Portage/Emerge

# AUTHORITY

use Path::Tiny 0.048 qw( path );  # subsumes

sub new {
    my ( $class, @args ) = @_;
    my $config = { ref $args[0] ? %{ $args[0] } : @args };
    return bless $config, $class;
}

sub _path {
    return ( $_[0]->{path} ||= '/var/db/pkg' );
}

sub _abspath {
    my $root = path( $_[0]->_path )->absolute->realpath;
    my $path = path( $_[0]->_path, @_[ 1 .. $#_ ] )->absolute->realpath;
    die "Illegal path, outside of VDB" unless $root->subsumes($path);
    return $path->stringify;
}

sub __dir_iterator {
    my ($path) = @_;
    my $handle;
    ( -d $path and opendir $handle, $path ) or return sub { return undef };
    return sub {
        while (1) {
            my $dir = readdir $handle;
            return undef unless defined $dir;
            next if $dir eq '.' or $dir eq '..';    # skip hidden entries
            return $dir;
        }
    };
}

sub _category_iterator {
    my ($self) = @_;
    my $root = $self->_path;
    return sub { return undef }
      unless -d $root;
    my $_cat_iterator = __dir_iterator($root);
    return sub {
        while (1) {

            # Category possible
            my $category = $_cat_iterator->();
            return undef if not defined $category;

            # Skip hidden categories
            next if $category =~ /\A[.]/x;

            # Validate category to have at least one package with a file
            my $_pkg_iterator = __dir_iterator( $self->_abspath($category) );
            while ( my $package = $_pkg_iterator->() ) {
                next if $package =~ /\A[.]/x;
                my $_file_iterator =
                  __dir_iterator( $self->_abspath( $category, $package ) );
                while ( my $file = $_file_iterator->() ) {
                    next if $file =~ /\A[.]/x;
                    ## Found one package with one file, category is valid
                    return $category;
                }
            }
        }
    };
}

sub categories {
    my ($self) = @_;
    my $it = $self->_category_iterator;
    my @cats;
    while ( my $entry = $it->() ) {
        push @cats, $entry;
    }
    return @cats;
}

sub _package_iterator {
    my ( $self, $config ) = @_;
    my $root = $self->_path;
    if ( $config->{in} ) {
        my $catdir = $self->_abspath( $config->{in} );
        return sub { return undef }
          unless -d $catdir;
        my $_pkg_iterator = __dir_iterator($catdir);
        return sub {
            while (1) {
                my $package = $_pkg_iterator->();
                return undef if not defined $package;
                next if $package =~ /\A[.]/x;
                my $_file_iterator =
                  __dir_iterator( $self->_abspath( $config->{in}, $package ) );
                while ( my $file = $_file_iterator->() ) {
                    next if $file =~ /\A[.]/x;
                    ## Found one package with one file, package is valid
                    return $config->{in} . '/' . $package;
                }
            }
        };
    }

    return sub { return undef }
      unless -d $root;

    my $_cat_iterator = __dir_iterator($root);
    my $category      = $_cat_iterator->();

    return sub { return undef }
      unless defined $category;

    my $_pkg_iterator = __dir_iterator( $self->_abspath($category) );

    return sub {
        while (1) {
            return undef if not defined $category;
            my $package = $_pkg_iterator->();
            if ( not defined $package ) {
                $category = $_cat_iterator->();
                return undef if not defined $category;
                if ( defined $category ) {
                    $_pkg_iterator =
                      __dir_iterator( $self->_abspath($category) );
                    next;
                }
                next;
            }
            next if $package =~ /\A[.]/x;
            my $_file_iterator =
              __dir_iterator( $self->_abspath( $category, $package ) );
            while ( my $file = $_file_iterator->() ) {
                next if $file =~ /\A[.]/x;
                ## Found one package with one file, package is valid
                return $category . '/' . $package;
            }
        }
    };
}

sub packages {
    my ( $self, @args ) = @_;
    my $config = { ref $args[0] ? %{ $args[0] } : @args };
    my $iterator = $self->_package_iterator($config);
    my (@packages);
    while ( my $result = $iterator->() ) {
        push @packages, $result;
    }
    return @packages;
}

sub _property_files_iterator {
    my ( $self, $config ) = @_;
    return sub { undef }
      unless $config->{'for'};
    my $catdir = $self->_abspath( $config->{'for'} );
    return sub { undef }
      unless -d $catdir;
    my $iterator = __dir_iterator($catdir);
    return sub {

        while (1) {
            my $file = $iterator->();
            return undef if not defined $file;
            next if $file =~ /\A[.]/x;
            return $file;
        }
    };
}

my $ENATIVE = {
    BUILD_TIME        => 'timestamp',
    CATEGORY          => 'string',
    CBUILD            => 'string',
    CC                => 'string',
    CFLAGS            => 'string',
    CHOST             => 'string',
    CONTENTS          => 'contents',
    COUNTER           => 'number',
    CTARGET           => 'string',
    CXX               => 'string',
    CXXFLAGS          => 'string',
    DEBUGBUILD        => 'flag-file',
    DEFINED_PHASES    => 'space-separated-list',
    DEPEND            => 'dependencies',
    DESCRIPTION       => 'string',
    EAPI              => 'string',
    FEATURES          => 'use-list',
    'environment.bz2' => {
        type     => 'file',
        encoding => 'application/x-bzip2',
        content  => 'text/plain'
    },
    HOMEPAGE             => 'url-list',
    INHERITED            => 'space-separated-list',
    IUSE                 => 'use-list',
    IUSE_EFFECTIVE       => 'use-list',
    KEYWORDS             => 'keywords',
    LDFLAGS              => 'string',
    LICENSE              => 'licenses',
    NEEDED               => 'elf-dependency-map',
    'NEEDED.ELF.2'       => 'arch-elf-dependency-map',
    PDEPEND              => 'dependencies',
    PF                   => 'string',
    PKGUSE               => 'use-list',
    PROVIDES             => 'arch-so-map',
    QA_CONFIGURE_OPTIONS => 'string',
    QA_PREBUILT          => 'space-separated-list',
    RDEPEND              => 'dependencies',
    repository           => 'string',
    REQUIRES             => 'arch-so-map',
    REQUIRES_EXCLUDE     => 'space-separated-list',
    RESTRICT             => 'space-seperated-list',
    SIZE                 => 'bytecount',
    SLOT                 => 'string',
    USE                  => 'use-list',
};

my @ERULES = (
    [
        sub { $_[0] =~ /\.ebuild\z/ },
        {
            label   => 'special:source_ebuild',
            type    => 'file',
            content => 'text/plain'
        }
    ],
);

sub properties {
    my ( $self, @args ) = @_;
    my $config = { ref $args[0] ? %{ $args[0] } : @args };
    my (@proplist);
    my $it = $self->_property_files_iterator($config);
    while ( my $entry = $it->() ) {
        my $matched = 0;
        if ( exists $ENATIVE->{$entry} ) {
            $matched = 1;
            push @proplist,
              {
                property => $entry,
                label    => $entry,
                for      => $config->{for},
                (
                    ref $ENATIVE->{$entry}
                    ? %{ $ENATIVE->{$entry} }
                    : ( type => $ENATIVE->{$entry} )
                ),
              };
        }
        for my $rule (@ERULES) {
            next unless $rule->[0]->($entry);
            $matched = 1;
            push @proplist,
              {
                property => $entry,
                label    => $entry,
                for      => $config->{for},
                (
                    ref $rule->[1]
                    ? %{ $rule->[1] }
                    : ( type => $rule->[1] )
                ),
              };
        }
        if ( not $matched ) {
            push @proplist,
              {
                property => $entry,
                label    => 'unknown:' . $entry,
                for      => $config->{for},
                type     => 'file',
                content  => 'application/octet-stream',
              };
        }
    }
    return @proplist;
}

sub get_property {
    my ( $self, @args ) = @_;
    my $config = { ref $args[0] ? %{ $args[0] } : @args };
    return undef
      unless exists $config->{for} and exists $config->{property};
    my $content;
    open my $fh, '<', $self->_abspath( $config->{for}, $config->{property} )
      or return undef;
    {
        local $/ = undef;
        $content = <$fh>;
    }
    close $fh;
    chomp $content;
    return $content;
}

1;

=head1 NAME

Gentoo::VDB::Portage - VDB Query Implementation for Portage/Emerge

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 LICENSE

This software is copyright (c) 2016 by Kent Fredric.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

## Please see file perltidy.ERR
