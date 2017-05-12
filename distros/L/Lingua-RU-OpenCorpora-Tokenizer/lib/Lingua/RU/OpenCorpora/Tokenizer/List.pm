package Lingua::RU::OpenCorpora::Tokenizer::List;

use utf8;
use strict;
use warnings;

our $VERSION = 0.06;

use IO::File;
use File::Spec;
use Carp qw(croak);
use Encode qw(decode);
use IO::Uncompress::Gunzip;
use File::ShareDir qw(dist_dir);

sub data_version { 0.05 }

sub new {
    my($class, $name, $args) = @_;

    croak "List name unspecified" unless defined $name;

    $args             ||= {};
    $args->{data_dir} ||= dist_dir('Lingua-RU-OpenCorpora-Tokenizer');
    $args->{root_url} ||= 'http://opencorpora.org/files/export/tokenizer_data';

    my $self = bless {
        %$args,
        name => $name,
    }, $class;

    $self->_load;

    $self;
}

sub in_list { exists $_[0]->{data}{lc $_[1]} }

sub _load {
    my $self = shift;

    my $fn = $self->_path;
    my $fh = IO::Uncompress::Gunzip->new($fn) or die "$fn: $IO::Uncompress::Gunzip::GunzipError";

    chomp($self->{version} = $fh->getline);

    my @data = map decode('utf-8', lc), $fh->getlines;

    # workaround for The Unicode Bug
    # see https://metacpan.org/module/perlunicode#The-Unicode-Bug
    utf8::upgrade($_) for @data;

    $self->_parse_list(\@data);

    $fh->close;

    return;
}

sub _update {
    my($self, $new_data) = @_;

    my $fn = $self->_path;
    my $fh = IO::File->new($fn, '>') or croak "$fn: $!";
    $fh->binmode;
    $fh->print($new_data);
    $fh->close;

    $self->_load;
}


sub _parse_list {
    my($self, $list) = @_;

    chomp @$list;
    $self->{data} = +{ map {$_,undef} @$list };

    return;
}

sub _path {
    my $self = shift;

    File::Spec->catfile($self->{data_dir}, "$self->{name}.gz");
}

sub _url {
    my($self, $mode) = @_;

    $mode ||= 'file';

    my $url = join '/', $self->{root_url}, $self->data_version, $self->{name};
    if($mode eq 'file') {
        $url .= '.gz';
    }
    elsif($mode eq 'version') {
        $url .= '.latest';
    }

    $url;
}

1;

__END__

=head1 NAME

Lingua::RU::OpenCorpora::Tokenizer::List - represents a data file

=head1 DESCRIPTION

This module provides an API to access files that are used by tokenizer.

It's useful to know that this module actually has 2 versions: the code version and the data version. These versions do not depend on each other.

=head1 METHODS

=head2 new($name [, $args])

Constructor.

Takes one required argument: list name. List name is one of these: exceptions, prefixes and hyphens.

Optionally you can pass a hashref with additional arguments:

=over 4

=item data_dir

Path to the directory where vectors file is stored. Defaults to distribution directory (see L<File::ShareDir>).

=back

=head2 in_list($value)

Checks if given value is in the list.

Returns true or false correspondingly.

=head1 SEE ALSO

L<Lingua::RU::OpenCorpora::Tokenizer::Vectors>

L<Lingua::RU::OpenCorpora::Tokenizer::Updater>

L<Lingua::RU::OpenCorpora::Tokenizer>

=head1 AUTHOR

OpenCorpora team L<http://opencorpora.org>

=head1 LICENSE

This program is free software, you can redistribute it under the same terms as Perl itself.
