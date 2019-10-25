use strict;
use warnings;
package Git::Open::Util;
use Moose;

has remote_url => (
    is      => 'ro',
    isa     => 'Str',
    default => sub {
        for (`git ls-remote --get-url`) {
          chomp;
          if (/^git@/) { # Change protocal to http if git
            s/:/\//; # Change : to /
            s/^git@/https:\/\//;
          }
          s/\.git$//; # Remove .git at the end
          return $_;
        }
    }
);

has current_branch => (
    is      => 'ro',
    isa     => 'Str',
    default => sub {
        my $current_branch = `git symbolic-ref --short HEAD`;
        chomp $current_branch;
        return $current_branch;
    }
);

has service => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        $self->remote_url =~ m|//([a-z]+)\.|;
        return $1;
    }
);

sub generate_url {
    my $self = shift;
    my $args = shift;

    my $suffix = '';
    if( defined $args->{compare} ) {
        if( $args->{compare} eq '' ) {
            $suffix = 'compare';
        }else {
            my @branches = split( /-/, $args->{compare} );
            $suffix = $self->_url_pattern( 'compare' );
            foreach my $i ( 0..1 ) {
                $suffix =~ s/_$i/$branches[$i]/;
            }
        }
    }elsif ( defined $args->{branch} ) {
        my $branch = $args->{branch} || $self->current_branch;
        $suffix = $self->_url_pattern( 'branch' );
        $suffix =~ s/_0/$branch/;
    }

    return $self->remote_url.'/'.$suffix;
};

sub _url_pattern {
    my $self = shift;
    my $view = shift;
    my $mapping_pattern = {
        github => {
            compare => 'compare/_0..._1',
            branch => 'tree/_0'
        },
        bitbucket => {
            compare => 'compare/_0.._1',
            branch => 'src?at=_0'
        }
    };

    return $mapping_pattern->{$self->service}->{$view};
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Open::Util

=head1 VERSION

version 0.1.12

=head1 AUTHOR

Pattarawat Chormai <pat.chormai@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Pattarawat Chormai.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
