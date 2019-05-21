package MPMinus::Dispatcher; # $Id: Dispatcher.pm 274 2019-05-09 18:52:43Z minus $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

MPMinus::Dispatcher - URL Dispatching

=head1 VERSION

Version 1.04

=head1 SYNOPSIS

    package MPM::foo::Handlers;
    use strict;

    use MPMinus::Dispatcher;

    sub handler {
        my $r = shift;
        my $m = MPMinus->m;

        $m->set(
                disp => new MPMinus::Dispatcher($m->conf('project'),$m->namespace)
            ) unless $m->disp;

        ...

        return Apache2::Const::OK;
    }

=head1 DESCRIPTION

URL Dispatching

=head1 METHODS

=over 8

=item B<new>

    my $disp = new MPMinus::Dispatcher(
            $m->conf('project'),
            $m->namespace)
        );

=item B<get>

    my $drec = $disp->get(
            -uri => $m->conf('request_uri')
        );

=item B<set>

    package MPM::foo::test;
    use strict;

    ...

    $disp->set(
            -uri    => ['locarr','test',
                        ['/test.mpm',lc('/test.mpm')]
                       ],
            -init     => \&init,
            -response => \&response,
            -cleanup  => \&cleanup,

            ... and other handlers's keys , see later ...

            -meta     => {}, # See MPMinus::Transaction

        );

=item B<default>

Returns Apache2::Const::NOT_FOUND only

=back

=head1 HANDLERS AND KEYS

Supported handlers:

    -postreadrequest
    -trans
    -maptostorage
    -init
    -headerparser
    -access
    -authen
    -authz
    -type
    -fixup
    -response
    -log
    -cleanup

See L<MPMinus::BaseHandlers/"HTTP PROTOCOL HANDLERS"> for details

=head1 HISTORY

See C<CHANGES> file

=head1 DEPENDENCIES

C<mod_perl2>, L<CTK>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

C<mod_perl2>, L<CTK::Util>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw($VERSION);
$VERSION = 1.04;

use Apache2::Const;
use Carp;
use CTK::Util qw/ :API /;

sub new {
    my $class = shift;
    my @in = read_attributes([
          ['PROJECT','PRJ','SITE','PROJECTNAME','NAME'],
          ['NAMESPACE', 'NS']
        ],@_);

    my $namespace = $in[1] || '';
    my %args = (
            project   => $in[0] || '', # Project name
            namespace => $namespace,   # Namespace
            records   => {},           # URIs
        );

    my $self = bless \%args, $class;

    # NOT_FOUND
    $self->set('default');

    # Get project sub-module from *::Index.pm
    eval "
        use $namespace\::Index;
        $namespace\::Index\::init(\$self);
    ";
    croak("Error initializing the module $namespace\::Index\: $@") if $@;

    return $self;
}
sub set {
    my $self = shift;
    my @in = read_attributes([
          ['URI','URL','REQUEST','KEY'], # 0

          # HTTP Protocol Handlers
          ['POSTREADREQUEST','HPOSTREADREQUEST','POSTREADREQUESTHANDLER'],  # 1
          ['TRANS','HTRANS','TRANSHANDLER'],                                # 2
          ['MAPTOSTORAGE','HMAPTOSTORAGE','MAPTOSTORAGEHANDLER'],           # 3
          ['INIT','HINIT','INITHANDLER'],                                   # 4
          ['HEADERPARSER','HHEADERPARSER','HEADERPARSERHANDLER'],           # 5
          ['ACCESS','HACCESS','ACCESSHANDLER'],                             # 6
          ['AUTHEN','HAUTHEN','AUTHENHANDLER'],                             # 7
          ['AUTHZ','HAUTHZ','AUTHZHANDLER'],                                # 8
          ['TYPE','HTYPE','TYPEHANDLER'],                                   # 9
          ['FIXUP','HFIXUP','FIXUPHANDLER'],                                # 10
          ['RESPONSE','HRESPONSE','RESPONSEHANDLER'],                       # 11
          ['LOG','HLOG','LOGHANDLER'],                                      # 12
          ['CLEANUP','HCLEANUP','CLEANUPHANDLER'],                          # 13

          ['ACTION','ACTIONS','META'], # 14

        ],@_);

    my $uri = $in[0];
    my $uniqname;
    my $type = 'location';
    my %params;
    if (ref($uri) eq 'ARRAY') {
        # ARRAY dispatching
        croak("Invalid URI in the definition section of the called module") unless $uri->[0];
        if (lc($uri->[0]) eq 'regexp') {
            $type     = 'regexp';
            $uniqname = $uri->[1] || 'undefined'; # Uniq name
            %params = (
                regexp => $uri->[2] || qr/^undefined$/
            );
        } elsif (lc($uri->[0]) eq 'locarr') {
            $type     = 'locarr';
            $uniqname = $uri->[1] || 'undefined'; # Uniq name
            %params = (
                locarr => $uri->[2] || []
            );
        } elsif (lc($uri->[0]) eq 'mixarr') {
            $type     = 'mixarr';
            $uniqname = $uri->[1] || 'undefined'; # Uniq name
            %params = (
                mixarr => $uri->[2] || []
            );
        } else {
            croak("Wrong type dispatch called module!")
        }
    } else {
        # Simple dispatching
        $uniqname = $uri;
    }

    $self->{records}->{$uniqname} = {
            Postreadrequest => $in[1] || sub { Apache2::Const::OK },
            Trans           => $in[2] || sub { Apache2::Const::DECLINED },
            Maptostorage    => $in[3] || sub { Apache2::Const::DECLINED },
            Init            => $in[4] || sub { Apache2::Const::OK },
            headerparser    => $in[5] || sub { Apache2::Const::OK },
            Access          => $in[6] || sub { Apache2::Const::OK },
            Authen          => $in[7] || sub { Apache2::Const::DECLINED },
            Authz           => $in[8] || sub { Apache2::Const::DECLINED },
            Type            => $in[9] || sub { Apache2::Const::DECLINED },
            Fixup           => $in[10] || sub { Apache2::Const::OK },
            Response        => $in[11] || \&default, # Main handler!
            Log             => $in[12] || sub { Apache2::Const::OK },
            Cleanup         => $in[13] || sub { Apache2::Const::OK },

            type     => $type,
            params   => {%params}, # Internal params
            actions  => $in[14] || {}, # Actions
        };
}
sub get {
    my $self = shift;
    my @in = read_attributes([
          ['URI','URI','REQUEST','KEY'],
        ],@_);
    my $uri = $in[0] || 'default';
    my $ret = $uri;

    # Stage 1
    # Searching by location
    $ret = 'default' unless grep {$_ eq $uri} keys %{$self->{records}};

    # Stage 2
    # Searching by ARRAY of location
    if ($ret eq 'default') {
        my @locarr_keys = grep {$self->{records}->{$_}->{type} eq 'locarr'} keys %{$self->{records}};
        foreach my $key (@locarr_keys) {
            $ret = $key if grep {$uri eq $_} @{$self->{records}->{$key}->{params}->{locarr}};
        }
        $ret ||= 'default';
    }

    # Stage 3
    # Searching by ARRAY of location and Regexp
    if ($ret eq 'default') {
        my @mixarr_keys = grep {$self->{records}->{$_}->{type} eq 'mixarr'} keys %{$self->{records}};
        foreach my $key (@mixarr_keys) {
            $ret = $key if grep {
                        if (ref $_ && lc(ref $_) eq 'regexp') {
                            $uri =~ $_
                        } else {
                            $uri eq $_
                        }
                    }
                    @{$self->{records}->{$key}->{params}->{mixarr}};
        }
        $ret ||= 'default';
    }

    # Stage 4
    # Searching by regexp only
    if ($ret eq 'default') {
        my @regexp_keys = grep {$self->{records}->{$_}->{type} eq 'regexp'} keys %{$self->{records}};
        if (@regexp_keys) {
            ($ret) = grep {$uri =~ $self->{records}->{$_}->{params}->{regexp}} @regexp_keys;
            $ret ||= 'default';
        }
    }

    return $self->{records}->{$ret};
}
sub default { Apache2::Const::NOT_FOUND };

1;
