package HTTP::MobileAgent::Plugin::SmartPhone;
use strict;
use warnings;
use utf8;
our $VERSION = '0.03';

sub HTTP::MobileAgent::is_smartphone {
    my $self = shift;
    $self->is_ios || $self->is_android;
}

sub HTTP::MobileAgent::is_ios {
    my $self = shift;

    my $ua = $self->user_agent || '';
    $ua =~ /\(iP(?:hone|od|ad)/;
}

sub HTTP::MobileAgent::is_iphone {
    my $self = shift;

    my $ua = $self->user_agent || '';
    $ua =~ /\(iPhone/;
}

sub HTTP::MobileAgent::is_ipad {
    my $self = shift;

    my $ua = $self->user_agent || '';
    $ua =~ /\(iPad/;
}

sub HTTP::MobileAgent::is_ipod {
    my $self = shift;

    my $ua = $self->user_agent || '';
    $ua =~ /\(iPod/;
}

sub HTTP::MobileAgent::is_android {
    my $self = shift;

    my $ua = $self->user_agent || '';
    $ua =~ /Android/;
}

sub HTTP::MobileAgent::is_android_tablet {
    my $self = shift;
    $self->is_android && $self->user_agent !~ /Mobile/
}

sub HTTP::MobileAgent::ios_full_version {
    my $self = shift;
    return () unless $self->is_ios;

    local $1;
    my $full_version;
    if ($self->user_agent =~ /CPU (?:iPhone )?(?:OS ((?:\d+)(?:_\d+)*) )?like/) {
        $full_version = $1 || 1;
    }
    $full_version;
}

sub HTTP::MobileAgent::ios_version {
    my ($version) = (shift->ios_full_version || '') =~ /^(\d+)/;
    $version;
}

sub HTTP::MobileAgent::is_tablet {
    my $self = shift;
    $self->is_ipad || $self->is_android_tablet;
}

sub HTTP::MobileAgent::android_full_version {
    my $self = shift;
    return () unless $self->is_android;

    my ($full_version) = $self->user_agent =~ /Android\s*([0-9\.]+).*?;/;
    $full_version;
}

sub HTTP::MobileAgent::android_version {
    my ($version) = (shift->android_full_version || '') =~ /^((?:\d+)(?:\.\d+)?)/;
    $version;
}

1;
__END__

=head1 NAME

HTTP::MobileAgent::Plugin::SmartPhone - Plugin of HTTP::MobileAgent for detecting smartphone

=head1 SYNOPSIS

    use HTTP::MobileAgent;
    use HTTP::MobileAgent::Plugin::SmartPhone;

    my $agent = HTTP::MobileAgent->new;
    if ($agent->is_smartphone) {
        if ($agent->is_ios) {
            if ($agent->is_iphone) {
                ...
            }
            elsif ($agent->is_ipod) {
                ...
            }
            elsif ($agent->is_ipad) {
                ...
            }
        }
        elsif ($agent->is_android) {
            if ($agent->is_android_tablet) {
                ...
            }
            else {
                ...
            }
        }
    }
    $agent->ios_version;      # eg. 5
    $agent->ios_full_version; # eg. 5_0_1


=head1 DESCRIPTION

HTTP::MobileAgent::Plugin::SmartPhone is a plugin of HTTP::MobileAgent for detecting smartphone.

=head1 METHODS

=over

=item is_smartphone

True if ios or android.

=item is_ios

Checking iOS or not. Including iPhone, iPod and iPad.

=item is_iphone

=item is_ipod

=item is_ipad

=item ios_version

iOS major version. ex. 5.
undef unless iOS.

=item ios_full_version

iOS full version. ex. 5_0_1.
undef unless iOS.

=item is_android

=item is_android_tablet

experimental.

=item is_tablet

experimental.

=back

=head1 AUTHOR

Masayuki Matsuki E<lt>y.songmu@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
