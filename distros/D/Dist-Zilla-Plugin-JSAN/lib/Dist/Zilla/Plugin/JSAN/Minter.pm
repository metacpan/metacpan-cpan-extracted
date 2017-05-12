package Dist::Zilla::Plugin::JSAN::Minter;
BEGIN {
  $Dist::Zilla::Plugin::JSAN::Minter::VERSION = '0.06';
}

# ABSTRACT: Default "minter"

use Moose;

extends 'Dist::Zilla::Plugin::JSAN::GatherDir::Template';

with 'Dist::Zilla::Role::FilePruner';
with 'Dist::Zilla::Role::FileMunger';


has 'include_dotfiles' => (
    is          => 'rw',
    default     => 1
);


sub exclude_file {
    my ($self, $file) = @_;

    my $main_perl_moudule    = $self->zilla->name;
    $main_perl_moudule       =~ s|-|/|g;

    return 1 if $file->name eq "lib/$main_perl_moudule.pm";
    return 1 if $file->name eq 'profile.ini';
    
    return 0;
}


sub prune_files {
    my ($self) = @_;

    my $files = $self->zilla->files;

    @$files = grep {
        $self->exclude_file($_) ? do { $self->log_debug([ 'pruning %s', $_->name ]); 0 } : 1
    } @$files;

    return;
}


sub dist_name {
    my ($self) = @_;
    
    my $name = $self->zilla->name;
    
    $name =~ s/-/\./g;
    
    return $name;
}


sub munge_file {
    my ($self, $file) = @_;
    
    return unless $file->name =~ m|^lib/Module/Stub\.(.+)$|;
    
    my $ext     = $1;
    my $name    = $self->zilla->name;
    
    $name       =~ s|-|/|g;
    
    
    $file->name("lib/$name.$ext")
}


no Moose;
__PACKAGE__->meta->make_immutable();


1;




__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::JSAN::Minter - Default "minter"

=head1 VERSION

version 0.06

=head1 SYNOPSIS

In your F<profile.ini>:

    [JSAN::Minter]

To start a new JSAN distribution:

    > dzil new -P JSAN -p joose Distribution-Name

or using your own profile:

    > dzil new -p my_profile Distribution-Name     

=head1 DESCRIPTION

Before you'll start creating distributions, setup the Dist::Zilla:

    > dzil setup

It will ask you some basic info. When asking about the default license, here's the list 
of available identificators (at the bottom and w/o leading "Software::License::"): L<Software::License>

=head1 CUSTOMIZING THE PROFILE

First you need to copy the default profile, which comes with this distribution to the "~/.dzil/profiles/" directory,
where Dist::Zilla stores profiles. Probably the easiest way to do it will be to download the tarball of this distribution
from L<http://search.cpan.org/dist/Dist-Zilla-Plugin-JSAN/>. Then unpack it and copy the "Dist-Zilla-Plugin-JSAN-0.xx/share/profiles/joose"
directory to the "~/.dzil/profiles/my_profile". Then you can start a new distribution based on this profile with:

    > dzil new -p my_profile Distribution-Name     

Each profile is a directory which should at least contain a "profile.ini" file, specifying the
plugins used during new distribution creation.

JSAN::Minter will look for "lib/Module/Stub.*" files in the profile directory and process them as templates.
The result of processing will be stored as "lib/Distribution/Name.*" (with the same extension).

=head1 AUTHOR

Nickolay Platonov <nplatonov@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Nickolay Platonov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

