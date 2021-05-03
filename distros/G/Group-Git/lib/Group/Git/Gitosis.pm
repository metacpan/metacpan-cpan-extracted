package Group::Git::Gitosis;

# Created on: 2013-05-04 20:18:43
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use strict;
use warnings;
use version;
use Carp;
use English qw/ -no_match_vars /;
use Path::Tiny;
use File::chdir;

our $VERSION = version->new('0.7.5');

extends 'Group::Git';

sub _repos {
    my ($self) = @_;

    if ( -d '.gitosis' ) {
        local $CWD = '.gitosis';
        system 'git', 'pull';
    }
    else {
        system 'git', 'clone', $self->conf->{gitosis}, '.gitosis';
    }

    my $data = Config::Any->load_files({
        files         => ['.gitosis/gitosis.conf'],
        use_ext       => 0,
        force_plugins => ['Config::Any::INI'],
    });
    $data = {
        map {
            %$_
        }
        map {
            values %$_
        }
        @{$data}
    };

    my $base = $self->conf->{gitosis};
    $base =~ s{([:/]).*?$}{$1};

    my %repos = %{ $self->SUPER::_repos() };
    for my $group ( keys %$data ) {
        for my $sub_group ( keys %{ $data->{$group} } ) {
            for my $type (qw/readonly writable/) {
                next if !$data->{$group}{$sub_group}{$type};

                for my $name ( split /\s+/, $data->{$group}{$sub_group}{$type} ) {
                    $repos{$name} = Group::Git::Repo->new(
                        name => path($name),
                        git  => "$base$name.git",
                    );
                }
            }
        }
    }

    return \%repos;
}

1;

__END__

=head1 NAME

Group::Git::Gitosis - Adds reading all repositories you have access to on a gitosis host

=head1 VERSION

This documentation refers to Group::Git::Gitosis version 0.7.5.

=head1 SYNOPSIS

   use Group::Git::Gitosis;

   # pull (or clone missing) all repositories that joeblogs has created/forked
   my $ggg = Group::Git::Github->new(
       conf => {
           gitosis => 'git://gitosis/url',
       },
   );

   # list all repositories
   my $repositories = $ggg->repo();

   # do something to each repository
   for my $repo (keys %{$repositories}) {
       # eg do a pull
       $ggg->pull($repo);
   }

=head1 DESCRIPTION

Reads all repositories you have access to (via standard git username). You
must have read access to the .gitosis repository.

=head1 SUBROUTINES/METHODS

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
