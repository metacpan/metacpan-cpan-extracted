package Device::Inverter::KOSTAL::PIKO;

use strict;
use utf8;
use warnings;

our $VERSION = '0.1';

use Mouse;
use Mouse::Util::TypeConstraints;
use Carp qw(carp confess croak);
use Params::Validate qw(validate_pos);
use Scalar::Util qw(openhandle);
use URI;
use namespace::clean -except => 'meta';

class_type('URI');
coerce URI => from Str => via { URI->new(shift) };

has configfile => (
    is      => 'rw',
    isa     => 'Str',
    default => sub {
        require File::HomeDir;
        require File::Spec;
        File::Spec->catfile( File::HomeDir->my_home, '.pikorc' );
    }
);

# Define standard attributes which are read from ~/.pikorc if needed:
for (
    [
        host => (
            last_resort => sub {
                'piko';
            },
        ),
    ],
    [
        status_url => (
            coerce      => 1,
            isa         => 'URI',
            last_resort => sub {
                my $self = shift;
                defined( my $host = $self->host ) or return;
                "http://$host/";
            },
        )
    ],
    [
        logdata_url => (
            coerce      => 1,
            isa         => 'URI',
            last_resort => sub {
                my $self = shift;
                defined( my $status_url = $self->status_url ) or return;
                ( my $logdata_url = $status_url->clone )->path('/LogDaten.dat');
                $logdata_url;
            },
        )
    ],
    ['number'],
    [
        password => (
            last_resort => sub {
                my $self = shift;
                require Net::Netrc;
                my $pvserver = Net::Netrc->lookup( $self->host ) or return;
                $pvserver->password;
            },
        ),
    ],
    [ time_offset => ( isa => 'Int', ) ],
    [
        username => (
            last_resort => sub {
                'pvserver';
            },
        )
    ]
  )
{
    my ( $attr, %spec ) = @$_;
    my $last_resort = delete $spec{last_resort};
    my $has_attr    = "has_$attr";

    # Include defaults in spec:
    %spec = (
        is      => 'rw',
        isa     => 'Str',
        lazy    => 1,
        default => sub {
            my $self = shift;
            $self->read_configfile;
            return $self->$attr if $self->$has_attr;
            if (   defined $last_resort
                && defined( my $value = $last_resort->($self) ) )
            {
                $self->$attr($value);
                return $value;
            }
            confess("$attr not set");
        },
        predicate => $has_attr,
        %spec
    );

    has $attr => %spec;
}

sub configure {
    my ( $self, $config_subhash ) = @_;
    while ( my ( $attr, $data ) = each %$config_subhash ) {
        my $has_attr = "has_$attr";
        $self->$attr($data) unless $self->$has_attr;
    }
}

sub fetch_logdata {
    my $self = shift;
    $self->load( \$self->get( logdata_url => @_ ) );
}

sub get {
    my ( $self, $what, %args ) = @_;
    my $url = $self->$what;
    require HTTP::Request;
    require LWP::UserAgent;
    ( my $request = HTTP::Request->new( GET => $url ) )
      ->authorization_basic( $self->username, $self->password );
    my $ua = LWP::UserAgent->new;
    local *STDERR = \*STDERR;
    if ( $args{progress_to} ) {
        open STDERR, '>&', $args{progress_to};
        $ua->show_progress(1);
    }
    my $response = $ua->request($request);
    croak( "Could not fetch <$url>: " . $response->status_line )
      unless $response->is_success;
    $response->decoded_content;
}

sub get_current_status {
    my $self = shift;
    require Device::Inverter::KOSTAL::PIKO::Status;
    Device::Inverter::KOSTAL::PIKO::Status->new(
        $self->get( status_url => @_ ) );
}

sub load {
    my $self     = shift;
    my ($source) = validate_pos( @_, 1 );
    my %param    = ( inverter => $self );
    unless ( ref $source ) {    # String => filename
        open $param{fh}, '<:crlf', $param{filename} = $source
          or croak(qq(Cannot open file "$source" for reading: $!));
    }
    elsif ( openhandle $source ) {
        binmode( $source, ':crlf' );
        $param{fh} = $source;
    }
    else {
        open $param{fh}, '<:crlf', $source
          or croak(qq(Cannot open reference for reading: $!));
    }
    require Device::Inverter::KOSTAL::PIKO::File;
    Device::Inverter::KOSTAL::PIKO::File->new(%param);
}

sub read_configfile {
    my $self       = shift;
    my $configfile = $self->configfile;
    carp(qq(Config file "$configfile" not found)) unless -e $configfile;
    require Config::INI::Reader;
    my $config_hash = Config::INI::Reader->read_file($configfile);

    if ( $self->has_number ) {
        if ( defined( my $specific_config = $config_hash->{ $self->number } ) )
        {
            $self->configure($specific_config);
        }
    }
    if ( defined( my $general_config = $config_hash->{_} ) ) {
        $self->configure($general_config);
    }
}

__PACKAGE__->meta->make_immutable;
no Mouse;

1;

__END__

=encoding UTF-8

=head1 NAME

Device::Inverter::KOSTAL::PIKO - represents a KOSTAL PIKO DC/AC converter

=head1 SYNOPSIS

    use Device::Inverter::KOSTAL::PIKO;

    my $piko = Device::Inverter::KOSTAL::PIKO->new( time_offset => 1309160816 );
    my $file = $piko->load($filename_or_handle_or_ref_to_data);
    say $_->timestamp for $file->logdata;

=head1 SAMPLE ~/.pikorc

    [255]
    host = piko
    time_offset = 1309160816

=head1 METHODS

=head1 host

=head1 logdata_url

=head1 status_url

=head1 fetch_logdata

=head1 get_current_status

Fetch current device status and return it as
L<Device::Inverter::KOSTAL::PIKO::Status> object.

=head1 read_configfile

=head1 AUTHOR

Martin Sluka, C<< <fany at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests at
L<https://github.com/fany/Device-Inverter-KOSTAL-PIKO/issues>.
L<Pull requests|https://github.com/fany/Device-Inverter-KOSTAL-PIKO/pulls>
are also welcome.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Device::Inverter::KOSTAL::PIKO

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Device-Inverter-KOSTAL-PIKO>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Device-Inverter-KOSTAL-PIKO>

=item * Search CPAN

L<https://metacpan.org/release/Device-Inverter-KOSTAL-PIKO>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012–2021 Martin Sluka.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See https://dev.perl.org/licenses/ for more information.
