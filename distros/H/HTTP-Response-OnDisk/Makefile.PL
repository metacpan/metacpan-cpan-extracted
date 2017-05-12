use strict;
use inc::Module::Install;

name('HTTP-Response-OnDisk');
all_from('lib/HTTP/Response/OnDisk.pm');
license('perl');

requires('Class::Accessor::Fast');
requires('Class::Data::Inheritable');
requires('Class::Inspector');
requires('Fcntl');
requires('File::Temp', '0.17');
requires('File::Spec');
requires('HTTP::Status');
requires('HTTP::Headers');
requires('Path::Class::Dir');

# Hey, stolen right off of Plagger
eval {
    require YAML;
    require DirHandle;
    require File::Spec;

    my $dh = DirHandle->new("deps");
    my @plugins;
    while (my $f = $dh->read) {
        next unless $f =~ /\.(?:yml|yaml)$/;
        my $meta = eval { YAML::LoadFile( File::Spec->catfile("deps", $f) ) };
        if ($@) {
            warn "Loading deps/$f failed: $@";
            next;
        }
        push @plugins, $meta if !$meta->{platform} || $meta->{platform} eq $^O;
    }

    for my $meta (sort { $b->{default} <=> $a->{default} || $a->{name} cmp $b->{name} } @plugins) {
        features(
            $meta->{name}, [
                -default => $meta->{default},
                map recommends($_ => $meta->{depends}->{$_}), keys %{$meta->{depends} || {}},
            ],
        );
    }
};
if ($@) {
    die "Failed to load deps! : $@";
}


auto_install;
WriteAll;
