package Draft::Protozoa::Eml;

=head1 NAME

Draft::Protozoa::Eml - CAD drawing-object base class

=head1 SYNOPSIS

This class is DEPRECATED, use YAML formatted file instead.

A CAD drawing object that consists of a single file that resembles
an rfc822 email message.

=head1 DESCRIPTION

If you find yourself using this base-class directly, then you are
probably doing something wrong.

=cut

use strict;
use warnings;

use File::Atomism::utils qw /TempFilename Journal/;

=pod

=head1 USAGE

Create an object by supplying the 'new' method with a file-path:

    use Draft::Drawing::Eml;
    my $foo = Draft::Drawing::Eml->new ('/path/to/file.eml');

=cut

sub new
{
    my $class = shift;
    $class = ref $class || $class;
    my $self = bless {}, $class;
    $self->{_path} = shift;
    return $self;
}

=pod

Read/Parse an existing file with the Read method:

    $foo->Read;

Currently the file-format is a simple series of key->value
declarations, one per line:

    Pi: 3.1418
    Author: Plato
    Author: Descartes

This might become a perl structure like this:

    '/path/to/file.eml' => bless( {
      'pi' => [ '3.1418' ],
      'author' => [ 'Plato', 'Descartes' ],
      '_path' => '/path/to/file.eml'
    }, 'Draft::Drawing::Eml' )

=cut

sub Read
{
    my $self = shift;

    my $data = LoadFile ($self->{_path});

    my $newclass = "Draft::Protozoa::Eml::". $self->Type ($data) ."::". $self->Version ($data);

    eval "use $newclass";
    $@ and return 0;

    bless $self, $newclass;

    $self->_parse ($data);
}

sub LoadFile
{
    my $path = shift;
    open FILE, "<". $path or warn $path ." not found.\n";
    my @lines = <FILE>;
    close FILE;

    my $data;

    # FIXME: should stop processing on first blank line
    # FIXME: should join lines prefixed with whitespace

    for my $line (@lines)
    {
        chomp $line;
        my ($key, $value) = split (':', $line);
        $key = lc ($key);
        $value =~ s/^ +//;
        push @{$data->{$key}}, $value;
    }

    return $data;
}

=pod

Objects can be moved in the world-space:

    $foo->Move ([10, 5, 0]);

This edits the file on the filesystem in one atomic operation.  This
is a permanent operation - If you find that you didn't want to move
the object, you might want to investigate using cvs for your data.

=cut

sub Move
{
    my $self = shift;
    my $vec = shift;

    open FILE, "<". $self->{_path} or warn $self->{_path} ." not found.\n";
    my @lines = <FILE>;
    close FILE;

    my $temp = TempFilename ($self->{_path});
    open FILE, ">". $temp;

    my $done;

    for my $line (@lines)
    {
        my ($key, $value) = split ': ', $line;
        $done->{$key} = 0 unless $done->{$key};

        if ($key =~ /^[0-9]+$/)
        {
            $value += $vec->[$done->{$key}];
            $line = "$key: $value\n";
        }

        $done->{$key}++;
        print FILE $line;
    }

    close FILE || return;

    Journal ([[$self->{_path}, $temp]]);
    rename $temp, $self->{_path};
}

sub _capitalise
{
    my $self = shift;
    my $word = shift;
    my $first = substr ($word, 0, 1, '');
    return uc ($first) . lc ($word);
}

=pod

Query the type and version of the object like so:

    my $type = $self->Type ($foo);
    my $version = $self->Version ($foo);

=cut

sub Type
{
    my $self = shift;
    my $data = shift;
    my $type = $data->{type}->[0] || 'unknown';
    $type =~ s/ .*//;
    $type =~ s/[^a-z0-9_]//gi;
    $self->_capitalise ($type);
}

sub Version
{
    my $self = shift;
    my $data = shift;
    my $version = $data->{version}->[0] || 'draft1';
    $version =~ s/ .*//;
    $version =~ s/[^a-z0-9_]//gi;
    $self->_capitalise ($version);
}

#sub Process {}

#sub Draw {}

1;
