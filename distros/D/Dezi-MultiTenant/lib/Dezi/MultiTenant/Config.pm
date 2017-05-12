package Dezi::MultiTenant::Config;
use strict;
use warnings;
use Carp;
use Dezi::Config;
use Plack::Util::Accessor qw(
    configs
);
use Data::Dump qw( dump );

our $VERSION = '0.003';

=head1 NAME

Dezi::MultiTenant::Config - multi-tenant Dezi configuration

=head1 SYNOPSIS

 use Dezi::MultiTenant::Config;

 my $dmc = Dezi::MultiTenant::Config->new(
     '/foo' => {
         engine_config => {
             type => 'Lucy'
         },
     },
     '/bar' => {
         engine_config => {
             type => 'Xapian',
         },
     },
 });

 for my $path ($dmc->paths()) {
    printf("%s mounted with config: %s\n",
        $path, Data::Dump::dump( $dmc->config_for( $path )
    );
 }

=head1 DESCRIPTION

Dezi::MultiTenant::Config is a hash-based configuration
with keys representing Plack mount points and values of
Dezi::Config objects.

=head1 METHODS

=head2 new( I<config> )

I<config> should be a hashref with keys representing
Plack mount points. Values are passed directly
to Dezi::Config->new().

=cut

sub new {
    my $class = shift;
    my $config = shift or croak "config hashref required";
    if ( !ref $config or ref $config ne 'HASH' ) {
        croak "config should be a hashref";
    }

    #dump $config;

    # some "meta" keys apply to all servers so propogate them
    # unless explicitly set already
    my %meta_config
        = map { $_ => $config->{$_} } grep { !m,^(/|http), } keys %$config;

    #dump \%meta_config;

    my %configs;
    for my $key ( keys %$config ) {

        next if exists $meta_config{$key};

        # merge in meta
        my $single_config = $config->{$key};
        for my $k ( keys %meta_config ) {
            next if exists $single_config->{$k};
            $single_config->{$k} = $meta_config{$k};
        }

        #dump $single_config;

        $configs{$key} = Dezi::Config->new($single_config);
    }

    #dump \%configs;

    return bless { configs => \%configs }, $class;
}

=head2 paths

Returns array of keys set in new().

=cut

sub paths {
    my $self = shift;
    return keys %{ $self->configs };
}

=head2 config_for( I<path> )

Returns Dezi::Config object for I<path>.

=cut

sub config_for {
    my $self = shift;
    my $path = shift or croak "path required";
    return $self->{configs}->{$path};
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dezi-multitenant at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dezi-MultiTenant>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dezi::MultiTenant


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-MultiTenant>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dezi-MultiTenant>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dezi-MultiTenant>

=item * Search CPAN

L<http://search.cpan.org/dist/Dezi-MultiTenant/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2013 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

