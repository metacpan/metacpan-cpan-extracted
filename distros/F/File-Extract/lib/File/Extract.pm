# $Id: /mirror/perl/File-Extract/trunk/lib/File/Extract.pm 9350 2007-11-18T13:33:38.729170Z daisuke  $
#
# Copyright (c) 2005-2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package File::Extract;
use strict;
use warnings;
use base qw(Class::Data::Inheritable);
use File::MMagic::XS qw(:compat);
use File::Temp();
our $VERSION = '0.07000';

sub new
{
    my $class = shift;
    my %args  = @_;

    my $encoding  = $args{output_encoding} || 'utf8';
    my @encodings = $args{encodings} ?
        (ref($args{encodings}) eq 'ARRAY' ? @{$args{encodings}} : $args{encodings}) : ();
    my $self  = bless {
        filters => $args{filters},
        processors => $args{processors},
        magic => 
            $args{file_mmagic_args} ?
                File::MMagic::XS->new(%{$args{file_mmagic_args}}) :
                File::MMagic::XS->new(),
        encodings => \@encodings,
        output_encoding => $encoding
    }, $class;

    return $self;
}

sub magic { shift->{magic} }

sub register_processor
{
    my $class = shift;
    my $pkg   = shift;

    eval "require $pkg" or die;
    my $mime  = $pkg->mime_type;
    $class->RegisteredProcessors->{$mime} ||= [];
    push @{$class->RegisteredProcessors->{$mime}}, $pkg;
}

sub register_filter
{
    my $class = shift;
    my $pkg   = shift;

    eval "require $pkg" or die;
    my $mime  = $pkg->mime_type;
    $class->RegisteredFilter->{$mime} ||= [];
    push @{$class->RegisteredFilter->{$mime}}, $pkg;
}

sub _processors
{
    my $self = shift;
    my $mime = shift;

    my $processors;

    # First, check if we have instance specific processors
    $processors = $self->{processors}{$mime};
    if ($processors) {
        return @$processors;
    }

    $processors = ref($self)->RegisteredProcessors->{$mime};
    if ($processors) {
        return @$processors;
    }

    return ();
}

sub _filters
{
    my $self = shift;
    my $mime = shift;

    my $filters;

    # First, check if we have instance specific filters
    $filters = $self->{filters}{$mime};
    if ($filters) {
        return @$filters;
    }

    $filters = ref($self)->RegisteredFilters->{$mime};
    if ($filters) {
        return @$filters;
    }

    return ();
}

sub extract
{
    my $self  = shift;
    my $file  = shift;

    my $magic = $self->{magic};
    my $mime  = $magic->checktype_filename($file);
    return unless $mime;
    my $o_mime = $mime;

    my $tmp;
    my $source = $file;
    if (my @filters = $self->_filters($mime)) {
        # Filters are applied one after the other, even if that may cause the
        # underlying MIME type to change (i.e. maybe you are crazy enough to
        # apply a filter that changes a plain text file to HTML -- god knows
        # why ;). This may be a bit confusing, since text extractors are
        # applied from the MIME type of the resulting file.
        foreach my $f (@filters) {
            $tmp = File::Temp->new(UNLINK => 1);
            $f->filter(file => $source, output => $tmp);
            $source = $tmp->filename;
        }

        $tmp->flush;
        $mime = $magic->checktype_filename($source);
        return unless $mime;
    }

    if (my @processors = $self->_processors($mime)) {
        foreach my $pkg (@processors) {
            my $p = $pkg->new(
                encodings       => $self->{encodings},
                output_encoding => $self->{output_encoding}
            );
            my $r = eval { $p->extract($source) };

            # Restore the original mime type of the source file. This is
            # required because we might have passed through several filters
            if ($r) {
                if ($source ne $file) {
                    $r->filename($file);
                    $r->mime_type($o_mime);
                }
                return $r;
            }
        }
    }

    return undef;
}

BEGIN
{
    __PACKAGE__->mk_classdata('RegisteredFilters');
    __PACKAGE__->mk_classdata('RegisteredProcessors');
    __PACKAGE__->RegisteredFilters({});
    __PACKAGE__->RegisteredProcessors({});

    my @p = qw(
        File::Extract::Excel
        File::Extract::HTML
        File::Extract::MP3
        File::Extract::PDF
        File::Extract::Plain
        File::Extract::RTF
    );
    foreach my $p (@p) {
        __PACKAGE__->register_processor($p);
    }
}

1;

__END__

=head1 NAME

File::Extract - Extract Text From Arbitrary File Types

=head1 SYNOPSIS

  use File::Extract;
  my $e = File::Extract->new();
  my $r = $e->extract($filename);

  my $e = File::Extract->new(encodings => [...]);

  my $class = "MyExtractor";
  File::Extract->register_processor($class);

  my $filter = MyCustomFilter->new;
  File::Extact->register_filter($mime_type => $filter);

=head1 DESCRIPTION

File::Extract is a framework to extract text data out of arbitrary file types,
useful to collect data for indexing.

=head1 CLASS METHODS

=head2 register_processor($class)

Registers a new text-extractor. The processor is used as the default processor
for a given MIME type, but it can be overridden by specifying the 'processors'
parameter

The specified class needs to implement two functions:

=over 4

=item mime_type(void)

Returns the MIME type that $class can extract files from. 

=item extract($file)

Extracts the text from $file. Returns a File::Extract::Result object.

=back

=head2 register_filter($mime_type, $filter)

Registers a filter to be used when a particular mime type has been found.

=head1 METHODS

=head2 new(%args)

=over 4

=item magic

Returns the File::MMagic::XS object that used by the object. Use this to
modify, set options, etc. E.g.:

  my $extract = File::Extract->new(...);
  $extract->magic->add_file_ext(t => 'text/perl-test');
  $extract->extract(...);

=item filters

A hashref of filters to be applied before attempting to extract the text
out of it. 

Here's a trivial example that puts line numbers in the beginning of each line
before extracting the output out of it.

  use File::Extract;
  use File::Extract::Filter::Exec;

  my $extract = File::Extract->new(
    filters => {
      'text/plain' => [
        File::Extract::Filter::Exec->new(cmd => "perl -pe 's/^/\$. /'")
      ]
    }
  );
  my $r = $extract->extract($file);

=item processors

A list of processors to be used for this instance. This overrides any
processors that were registered previously via register_processor() class
method.

=item encodings

List of encodings that you expect your files to be in. This is used to
re-encode and normalize the contents of the file via Encode::Guess.

=item output_encoding

The final encoding that you the extracted test to be in. The default
encoding is UTF8.

=back

=head2 extract($file)

=head1 SEE ALSO

L<File::MMagic::XS|File::MMagic::XS>

=head1 AUTHOR

Copyright 2005-2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>.
All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
