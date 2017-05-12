# Copyright (c) 2016  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
package Game::Asset;
$Game::Asset::VERSION = '0.3';
# ABSTRACT: Load assets (images, music, etc.) for games
use strict;
use warnings;
use Moose;
use namespace::autoclean;

use Game::Asset::Type;
use Game::Asset::Null;
use Game::Asset::PerlModule;
use Game::Asset::PlainText;
use Game::Asset::YAML;
use Game::Asset::MultiExample;

use Archive::Zip qw( :ERROR_CODES );
use YAML ();


has 'file' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);
has 'mappings' => (
    is => 'ro',
    isa => 'HashRef[Game::Asset::Type]',
    default => sub {{}},
    auto_deref => 1,
);
has 'entries' => (
    is => 'ro',
    isa => 'ArrayRef[Game::Asset::Type]',
    default => sub {[]},
    auto_deref => 1,
);
has '_entries_by_shortname' => (
    traits => ['Hash'],
    is => 'ro',
    isa => 'HashRef[Game::Asset::Type]',
    default => sub {{}},
    handles => {
        _get_by_name => 'get',
    },
);
has '_zip' => (
    is => 'ro',
    isa => 'Archive::Zip',
);


sub BUILDARGS
{
    my ($class, $args) = @_;
    my $file = $args->{file};

    my $zip = $class->_read_zip( $file );
    $args->{'_zip'} = $zip;

    my $index = $class->_read_index( $zip, $file );
    $args->{mappings} = {
        yml => 'Game::Asset::YAML',
        txt => 'Game::Asset::PlainText',
        pm => 'Game::Asset::PerlModule',
        %$index,
    };

    my ($entries, $entries_by_shortname) = $class->_build_entries( $zip,
        $args->{mappings} );
    $args->{entries} = $entries;
    $args->{'_entries_by_shortname'} = $entries_by_shortname;

    return $args;
}


sub get_by_name
{
    my ($self, $name) = @_;
    my $entry = $self->_get_by_name( $name );

    if( $entry ) {
        my $full_name = $entry->full_name;
        my $contents = $self->_zip->contents( $full_name );
        $entry->process_content( $contents );
    }

    return $entry;
}


sub _read_zip
{
    my ($class, $file) = @_;

    my $zip = Archive::Zip->new;
    my $read_result = $zip->read( $file );
    if( $read_result == AZ_STREAM_END ) {
        die "Hit end of stream unexpectedly in '$file'\n";
    }
    elsif( $read_result == AZ_ERROR ) {
        die "Generic error while reading '$file'\n";
    }
    elsif( $read_result == AZ_FORMAT_ERROR ) {
        die "Formatting error while reading '$file'\n";
    }
    elsif( $read_result == AZ_IO_ERROR ) {
        die "IO error while reading '$file'\n";
    }

    return $zip;
}

sub _read_index
{
    my ($class, $zip, $file) = @_;
    my $index_contents = $zip->contents( 'index.yml' );
    die "Could not find index.yml in '$file'\n" unless $index_contents;

    my $index = YAML::Load( $index_contents );
    return $index;
}

sub _build_entries
{
    my ($class, $zip, $mappings) = @_;
    my %mappings = %$mappings;

    my (@entries, %entries_by_shortname);
    foreach my $member ($zip->memberNames) {
        next if $member eq 'index.yml'; # Ignore index
        next if $member =~ m!\/ \z!x;
        my ($short_name, $ext) = $member =~ /\A (.*) \. (.*?) \z/x;
        die "Could not find mapping for '$ext' (full name: $member)\n"
            if ! exists $mappings{$ext};

        my $entry_class = $mappings{$ext};
        my $entry = $entry_class->new({
            name => $short_name,
            full_name => $member,
        });
        push @entries, $entry;
        $entries_by_shortname{$short_name} = $entry;
    }

    return (\@entries, \%entries_by_shortname);
}



no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

  Game::Asset - Load assets (images, music, etc.) for games

=head1 SYNOPSIS

    my $asset = Game::Asset->new({
        file => 't_data/test1.zip',
    });
    my $foo = $asset->get_by_name( 'foo' );
    my $name = $foo->name;
    my $type = $foo->type;

=head1 DESCRIPTION

A common way to handle game assets is to load them in one big zip file. It 
might end up named with extensions like ".wad" or ".pk3" or even ".jar", but 
it's a zip file.

This module allows you to load up these files and fetch their contents into 
Perl objects. Each type of file is represented by a class that does the 
L<Game::Asset::Type> Moose role. Which type class, exactly, is determined with 
mappings defined in the C<index.yml> file. There are also a few built-in 
mappings.

=head1 THE INDEX FILE

A file named C<index.yml> (a L<YAML> file) is required inside the zip file, 
and resolves to a hash. Keys are the file extensions (without the dot), and 
values are the Perl class that will handle that type. That class must do 
the L<Game::Asset::Type> Moose role.

The file must exist. If you just want to use the built-in mappings, it can 
resolve to an empty hash.

=head2 Built-in Mappings

The following mappings are always available without being in the index file:

=over 4

=item * txt -- L<Game::Asset::PlainText>

=item * yml -- L<Game::Asset::YAML>

=item * pm -- L<Game::Asset::PerlModule>

=back

=head2 Multi-mappings

There are times when the given content should be processed by more than one 
mapping. For instance, a game may want to process a L<Graphics::GVG> vector 
in both OpenGL and Chipmunk (physics library).

This is what multi-mappings are for. See L<Game::Asset::Multi> for details.

=head1 ATTRIBUTES

=head2 file

The path to the zip file.

=head2 mappings

A hashref (with autoderef). The keys are the file extensions, and the values 
are the L<Game::Asset::Type> classes that will handle that type.

=head2 entries

A list of all the assets with their file extensions removed. Note that the 
C<index.yml> file is filtered out.

=head1 METHODS

=head2 get_by_name

  $asset->get_by_name( 'foo' );

Pass in a name of an asset (without the extension). Returns an object 
representing the data in the zip file.

=head1 LICENSE

Copyright (c) 2016  Timm Murray
All rights reserved.

Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright 
      notice, this list of conditions and the following disclaimer in the 
      documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
POSSIBILITY OF SUCH DAMAGE.

=cut
