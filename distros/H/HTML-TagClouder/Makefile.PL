use strict;
use inc::Module::Install;

name('HTML-TagClouder');
all_from('lib/HTML/TagClouder.pm');

requires 'overload';
requires 'Class::Accessor::Fast';
requires 'Class::C3';
requires 'Class::Inspector';
requires 'UNIVERSAL::isa';
requires 'UNIVERSAL::require';

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