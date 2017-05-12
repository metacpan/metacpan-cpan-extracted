package MetaCPAN::Helper;
$MetaCPAN::Helper::VERSION = '0.04';
use 5.006;
use strict;
use warnings;
use Moo;
use Carp;

has client => (
    is => 'ro',
    default => sub {
        require MetaCPAN::Client;
        return MetaCPAN::Client->new();
    },
);

sub module2dist {
    my $self = shift;
    my $_m   = shift;
    ref($_m) eq 'MetaCPAN::Client::Module' and return $_m->distribution;
    ref($_m) and croak "invalid module name";

    my $module_name = $_m;

    my $query      = { all => [
                           {        status => 'latest'     },
                           {      maturity => 'released'   },
                           { 'module.name' => $module_name },
                       ]
                     };
    my $params     = { fields => [qw(distribution)] };
    my $result_set = $self->client->module($query, $params) || return undef;
    my $module     = $result_set->next                      || return undef;

    return $module->distribution || undef;
}

sub release2repo {
    my $self = shift;
    my $_r   = shift;

    my $release = ref($_r) eq 'MetaCPAN::Client::Release'
        ? $_r
        : !ref($_r)
            ? $self->client->release($_r)
            : croak "invalid release name";

    my $res = $release->resources || return undef;
    my $rep = $res->{repository}  || return undef;

    return ( $rep->{url} || undef );
}

sub dist2repo {
    my $self      = shift;
    my $dist_name = _get_dist_name(shift);

    my $lr = $self->dist2latest_release($dist_name);

    return $self->release2repo($lr);
}

sub dist2releases {
    my $self      = shift;
    my $dist_name = _get_dist_name(shift);

    my $filter   = { distribution => $dist_name };
    my $releases = $self->client->release($filter);

    return $releases;
}

sub dist2latest_release {
    my $self      = shift;
    my $dist_name = _get_dist_name(shift);

    my $filter = {
        all => [
            { distribution => $dist_name },
            { status       => "latest" }
        ]
    };

    my $release = $self->client->release($filter);

    return ( $release->total == 1 ? $release->next : undef );
}

sub dist2favorite_count {
    my $self      = shift;
    my $dist_name = _get_dist_name(shift);

    my $filter = { distribution => $dist_name };

    my $favorite = $self->client->favorite($filter);

    return ( ref $favorite ? $favorite->total : undef );
}


sub _get_dist_name {
    my $val = shift;
    ref($val) eq 'MetaCPAN::Client::Distribution' and return $val->name;
    !ref($val) and return $val;
    croak "invalid distribution name";
}

1;

=head1 NAME

MetaCPAN::Helper - a MetaCPAN client that provides some high-level helper functions

=head1 SYNOPSIS

 use MetaCPAN::Helper;

 my $helper   = MetaCPAN::Helper->new();
 my $module   = 'MetaCPAN::Client';
 my $distname = $helper->module2dist($module);
 print "$module is in dist '$distname'\n";

=head1 DESCRIPTION

This module is a helper class built on top of L<MetaCPAN::Client>,
providing methods which provide simple high-level functions for answering
common "CPAN lookup questions".

B<Note>: this is an early release, and the interface is likely to change.
Feedback on the interface is very welcome.

You could just use L<MetaCPAN::Client> directly yourself,
which might make sense in a larger application.
This class is aimed at people writing smaller one-off scripts.

=head1 METHODS

=head2 module2dist( $MODULE_NAME | $MODULE_OBJ )

Takes the name of a module or a L<MetaCPAN::Client::Module> object,
and returns the name of the distribution which
I<currently> contains that module, according to the MetaCPAN API.

At the moment this will ignore any developer releases,
and take the latest non-developer release of the module.

If the distribution name in the dist's metadata doesn't match the
name produced by L<CPAN::DistnameInfo>, then be aware that this method
returns the name according to C<CPAN::DistnameInfo>.
This doesn't happen very often (less than 0.5% of CPAN distributions).

=head release2repo( $RELEASE_NAME | $RELEASE_OBJ )

Takes the name of a release or a L<MetaCPAN::Client::Release> object,
and returns the repo URL string or undef if not found.

=head dist2repo( $DIST_NAME | $DIST_OBJ )

Takes the name of a distribution or a L<MetaCPAN::Client::Distribution> object,
and returns the repo URL string or undef if not found, of its latest release.

=head2 dist2releases( $DIST_NAME | $DIST_OBJ )

Takes the name of a distribution or a L<MetaCPAN::Client::Distribution> object,
and returns the L<MetaCPAN::Client::ResultSet> iterator of all releases
(as L<MetaCPAN::Client::Release> objects)
associated with that distribution.

=head2 dist2latest_release( $DIST_NAME | $DIST_OBJ )

Takes the name of a distribution or a L<MetaCPAN::Client::Distribution> object,
and returns the L<MetaCPAN::Client::Release>
object of the "latest" release of that distribution.

=head2 dist2favorite_count( $DIST_NAME | $DIST_OBJ )

Takes the name of a distribution or a L<MetaCPAN::Client::Distribution> object,
and returns the favorites count for that distribution.

=head1 SEE ALSO

L<MetaCPAN::Client> - the definitive client for querying L<MetaCPAN|https://metacpan.org>.

=head1 REPOSITORY

L<https://github.com/CPAN-API/metacpan-helper>

=head1 CONTRIBUTORS

=over 4

=item *

L<Neil Bowers|https://metacpan.org/author/NEILB>

=item *

L<Mickey Nasriachi|https://metacpan.org/author/MICKEY>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 the MetaCPAN project.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

