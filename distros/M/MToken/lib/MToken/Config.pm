package MToken::Config; # $Id: Config.pm 57 2019-06-06 13:46:47Z minus $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

MToken::Config - MToken global and local configuration

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    use MToken::Config;

    my $config = new MToken::Config(
        global_file => '/foo/bar/global.conf',
        local_file => '/foo/bar/local.conf',
        name => 'foo', # Optional
    );

    my $foo = $config->get('foo');

    my $foo = $config->set('foo' => 'bar');

    my $status = $config->save(); # Local file only

=head1 DESCRIPTION

The module works with the configuration data

=head1 METHODS

=over 8

=item B<new>

    my $config = new WWW::MLite::Config(
        global_file => '/foo/bar/global.conf',
        local_file => '/foo/bar/local.conf',
        name => 'foo', # Optional
    );

Returns configuration object

=item B<get>

    my $value = $config->get( 'key' );

Returns value by keyname

=item B<getall, conf, config>

    my %config = $config->getall;

Returns all allowed pairs - key and value

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

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

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
use MToken::Const qw/ :GENERAL :MATH /;

use vars qw/$VERSION/;
$VERSION = '1.01';

use constant {
    ALLOWED_KEYS        => [qw/
            name distname project
            server_url
            gpgbin opensslbin
        /],
};

sub new {
    my $class   = shift;
    my %args    = (@_);

    my $global_file = $args{global_file};
    my $local_file = $args{local_file};
    my $project = $args{project};

    # global_file
    unless (defined $global_file) {
        $global_file = File::Spec->catfile(cwd(), DIR_ETC, GLOBAL_CONF_FILE);
    }

    # local_file
    my $locex = (defined($project) && $project ne PROJECT) ? TRUE : FALSE;
    if (defined $local_file) {
        $locex = TRUE;
    } else {
        my $lcf = $locex
            ? sprintf("%s_%s", LOCAL_CONF_FILE, $project)
            : LOCAL_CONF_FILE;
        $local_file = File::Spec->catfile(home(), $lcf);
    }

    unless ($locex) {
        my %tmp = _loadconfig($global_file);
        my $project = $tmp{project};
        croak("Can't get PROJECT param from $global_file file. Please reinitialize this project") unless $project;
        $local_file = File::Spec->catfile(home(), sprintf("%s_%s", LOCAL_CONF_FILE, $project));
    }

    my %cfg = (
        global_conf_file => $global_file,
        local_conf_file  => $local_file,
        _loadconfig($global_file, $local_file)
    );

    my $self = bless { %cfg }, $class;
    return $self;
}
sub save {
    my $self = shift;
    return _saveconfig($self->get("local_conf_file"), {($self->getall)});
}
sub get {
    my $self = shift;
    my $key  = shift;
    unless ($self) {
        carp("Object not specified");
        return undef;
    }
    return undef unless $key;
    return $self->{$key};
}
sub getall {
    my $self = shift;

    my %svh = ();
    foreach my $k (@{(ALLOWED_KEYS)}) {
        my $v = $self->get($k);
        $svh{$k} = $v if defined $v;
    }
    return (%svh);
}
sub conf { goto &getall };
sub config { goto &getall };
sub set {
    my $self = shift;
    my $key  = shift;
    my $val  = shift;
    unless ($self) {
        carp("Object not specified");
        return FALSE;
    }
    unless ($key) {
        carp("Key not specified");
        return FALSE;
    }
    $self->{$key} = $val;
    return TRUE;
}

sub _loadconfig {
    my $gfile = shift;
    my $lfile = shift;

    my %config = (
        loadstatus_global   => FALSE,
        loadstatus_local    => FALSE,
        configfiles         => [],
    );

    # Global
    if ($gfile && -e $gfile) {
        my $gconf;
        try {
            $gconf = new Config::General(
                -ConfigFile         => $gfile,
                #-ConfigPath         => $cdirs,
                -ApacheCompatible   => TRUE,
                -LowerCaseNames     => TRUE,
                -AutoTrue           => TRUE,
            );
        } catch {
            carp($_);
        };
        if ($gconf && $gconf->can('getall')) {
            %config = (%config, $gconf->getall);
            $config{loadstatus_global} = 1;
        }
        $config{configfiles} = [$gconf->files] if $gconf && $gconf->can('files');
    }

    # Local
    if ($lfile && -e $lfile) {
        my $lconf;
        try {
            $lconf = new Config::General(
                -ConfigFile         => $lfile,
                -ApacheCompatible   => TRUE,
                -LowerCaseNames     => TRUE,
                -AutoTrue           => TRUE,
            );
        } catch {
            carp($_);
        };
        if ($lconf && $lconf->can('getall')) {
            my %rplc = $lconf->getall;
            while (my ($k,$v) = each %rplc) {
                $config{$k} = $v if defined $v;
            }
            $config{loadstatus_local} = 1;
        }
        my $cfs = $config{configfiles};
        push(@$cfs, ($lconf->files)) if $lconf && $lconf->can('files');
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

    my $conf = new Config::General(
                -ConfigHash         => $config,
                -ApacheCompatible   => TRUE,
                -LowerCaseNames     => TRUE,
                -AutoTrue           => TRUE,
            );
    $conf->save_file($file);
    return 1;
}

1;
