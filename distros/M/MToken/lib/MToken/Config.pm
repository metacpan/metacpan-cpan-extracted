package MToken::Config; # $Id: Config.pm 103 2021-10-10 11:04:34Z minus $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

MToken::Config - MToken local configuration

=head1 VERSION

Version 1.03

=head1 SYNOPSIS

    use MToken::Config;

    my $config = MToken::Config->new(
        file => '/my/device/mtoken.conf',
        name => 'foo', # Optional. See device config file first
    );

    my $foo = $config->get('foo');

    my $foo = $config->set('foo' => 'bar');

    my $status = $config->save(); # Local file only

=head1 DESCRIPTION

The module works with the local configuration data

=head1 METHODS

=over 8

=item B<new>

    my $config = WWW::MLite::Config->new(
        file => '/my/device/mtoken.conf',
        name => 'foo', # Optional. See device config file first
    );

Returns configuration object

=item B<get>

    my $value = $config->get( 'key' );

Returns value by keyname

=item B<getall, conf, config>

    my %config = $config->getall;

Returns all configuration pairs - key and value

=item B<is_loaded>

    print $self->is_loaded ? 'loaded' : 'not loaded';

Returns status of local config

=item B<set>

    $config->set( 'key', $value );

Set new value for key. Returns status of the operation

=item B<save>

    $config->save;

Save current configuration to local_file and returns status of the operation

=back

=head1 HISTORY

See C<Changes> file

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2021 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use Carp;
use File::HomeDir;
use Config::General;
use Try::Tiny;
use Cwd;
use File::Spec;
use CTK::Util qw/preparedir/;
use MToken::Const qw/ :GENERAL :MATH /;

use vars qw/$VERSION/;
$VERSION = '1.03';

use constant {
    ALLOWED_KEYS        => [qw/
            token
            server_url
            gpgbin opensslbin
            fingerprint
        /],
};

sub new {
    my $class   = shift;
    my %args    = (@_);
    my $is_loaded = 0;

    my $config_file = $args{file} || $args{config_file} || $args{device_file}
       || File::Spec->catfile(cwd(), DIR_PRIVATE, DEVICE_CONF_FILE);

    # Load device config
    my %dev = _loadconfig($config_file);
    my $name = $dev{token} || $dev{token_name} || $dev{name};
    $is_loaded = 1 if $name;


    # Get path of local config
    $name ||= $args{name} || "noname";
    $name =~ s/\s+//g;
    $name =~ s/[^a-z0-9]//g;
    $name ||= "noname";
    my $local_dir = File::Spec->catdir(File::HomeDir->my_data(), PROJECTNAMEL);
    my $local_file = File::Spec->catfile($local_dir, sprintf("%s.conf", $name));
    my %lkl = ();
    if (-f $local_file) { # Ok! File exists, try load local config
        %lkl = _loadconfig($local_file);
        while (my ($k,$v) = each %lkl) {
            $dev{$k} //= $v if defined $v;
        }
    }

    # Set data
    my %cfg = (
        name                => $name,
        is_loaded           => $is_loaded,
        device_config_file  => $config_file,
        local_config_dir    => $local_dir,
        local_config_file   => $local_file,
        _config             => {%dev},
    );

    my $self = bless { %cfg }, $class;
    return $self;
}
sub save {
    my $self = shift;
    if (!$self->{name} || $self->{name} eq "noname") {
        carp("Can't use nonamed devices");
        return FALSE;
    }

    my %svh = ();
    foreach my $k (@{(ALLOWED_KEYS)}) {
        my $v = $self->get($k);
        $svh{$k} = $v if defined $v;
    }
    preparedir($self->{local_config_dir}, 0755) or do {
        carp(sprintf("Can't prepare directory %s", $self->{local_config_dir}));
        return FALSE;
    };

    return _saveconfig($self->{local_config_file}, {%svh});
}
sub get {
    my $self = shift;
    my $key  = shift;
    return undef unless $key;
    return $self->{_config}{$key};
}
sub getall {
    my $self = shift;
    my $lh = $self->{_config};
    return (%$lh);
}
sub conf { goto &getall };
sub config { goto &getall };
sub set {
    my $self = shift;
    my $key  = shift;
    my $val  = shift;
    unless ($key) {
        carp("Key not specified");
        return FALSE;
    }
    $self->{_config}{$key} = $val;
    return TRUE;
}
sub is_loaded {
    my $self = shift;
    $self->{is_loaded};
}

sub _loadconfig {
    my $file = shift;
    unless ($file) {
        carp("Filename not specified!");
        return ();
    }
    my %config = ();

    # Load
    if ($file && -f $file) {
        my $gconf;
        try {
            $gconf = Config::General->new(
                -ConfigFile         => $file,
                -ApacheCompatible   => TRUE,
                -LowerCaseNames     => TRUE,
                -AutoTrue           => TRUE,
            );
        } catch {
            carp($_);
        };
        if ($gconf && $gconf->can('getall')) {
            %config = ($gconf->getall);
        }
    }

    return %config;
}
sub _saveconfig {
    my $file = shift;
    my $config = shift;
    unless ($file) {
        carp("Filename not specified!");
        return 0;
    }
    unless ($config && ref($config) eq 'HASH') {
        carp("No configuration data for saving");
        return 0;
    }

    my $conf = Config::General->new(
                -ConfigHash         => $config,
                -ApacheCompatible   => TRUE,
                -LowerCaseNames     => TRUE,
                -AutoTrue           => TRUE,
            );
    $conf->save_file($file);
    return 1;
}

1;

__END__
