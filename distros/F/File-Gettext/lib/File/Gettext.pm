package File::Gettext;

use 5.010001;
use namespace::autoclean;
use version; our $VERSION = qv( sprintf '0.33.%d', q$Rev: 1 $ =~ /\d+/gmx );

use English                    qw( -no_match_vars );
use File::DataClass::Constants qw( EXCEPTION_CLASS FALSE NUL SPC TRUE );
use File::DataClass::Functions qw( is_hashref merge_attributes throw );
use File::DataClass::IO        qw( io );
use File::DataClass::Types     qw( ArrayRef Directory HashRef Str Undef );
use File::Gettext::Constants   qw( LOCALE_DIRS );
use File::Spec::Functions      qw( tmpdir );
use Type::Utils                qw( as coerce declare from enum via );
use Unexpected::Functions      qw( Unspecified );
use Moo;

extends q(File::DataClass::Schema);

# Private functions
my $_build_localedir = sub {
   my $dir = shift; $dir and $dir = io( $dir ) and $dir->is_dir and return $dir;

   for $dir (map { io $_ } @{ LOCALE_DIRS() }) {
      $dir->exists and $dir->is_dir and return $dir;
   }

   return io tmpdir();
};

my $LocaleDir  = declare as Directory;

coerce $LocaleDir,
   from ArrayRef, via { $_build_localedir->( $_ ) },
   from Str,      via { $_build_localedir->( $_ ) },
   from Undef,    via { $_build_localedir->( $_ ) };

my $SourceType = enum 'SourceType' => [ 'mo', 'po' ];

# Public attributes
has 'charset'           => is => 'ro', isa => Str, default => 'iso-8859-1';

has 'default_po_header' => is => 'ro', isa => HashRef,
   default              => sub { {
      appname           => 'Your_Application',
      company           => 'ExampleCom',
      email             => '<translators@example.com>',
      lang              => 'en',
      team              => 'Translators',
      translator        => 'Athena', } };

has 'gettext_catagory'  => is => 'ro', isa => Str, default => 'LC_MESSAGES';

has 'header_key_table'  => is => 'ro', isa => HashRef,
   default              => sub { {
      project_id_version        => [ 0,  'Project-Id-Version'        ],
      report_msgid_bugs_to      => [ 1,  'Report-Msgid-Bugs-To'      ],
      pot_creation_date         => [ 2,  'POT-Creation-Date'         ],
      po_revision_date          => [ 3,  'PO-Revision-Date'          ],
      last_translator           => [ 4,  'Last-Translator'           ],
      language_team             => [ 5,  'Language-Team'             ],
      language                  => [ 6,  'Language'                  ],
      mime_version              => [ 7,  'MIME-Version'              ],
      content_type              => [ 8,  'Content-Type'              ],
      content_transfer_encoding => [ 9,  'Content-Transfer-Encoding' ],
      plural_forms              => [ 10, 'Plural-Forms'              ], } };

has 'localedir'      => is => 'ro', isa => $LocaleDir, coerce => TRUE,
   default           => NUL;

has '+result_source_attributes' =>
   default           => sub { {
      mo             => {
         attributes  => [ qw( msgid_plural msgstr ) ],
         defaults    => { msgstr => [], }, },
      po             => {
         attributes  =>
            [ qw( translator_comment extracted_comment reference flags
                  previous msgctxt msgid msgid_plural msgstr ) ],
         defaults    => { 'flags' => [], 'msgstr' => [], },
         label_attr  => 'labels',
      }, } };

has '+storage_class' => default => '+File::Gettext::Storage::PO';

has 'source_name'    => is => 'ro', isa => $SourceType,
   default           => 'po', trigger => TRUE;

# Private methods
my $_is_file_or_log_debug = sub {
   my ($self, $path) = @_;

   $path->exists  or ($self->log->debug( 'Path '.$path->pathname.' not found' )
                      and return FALSE);
   $path->is_file or ($self->log->debug( 'Path '.$path->pathname.' not a file' )
                      and return FALSE);

   return TRUE;
};

# Construction
around 'BUILDARGS' => sub {
   my ($orig, $self, @args) = @_; my $attr = $orig->( $self, @args );

   my $builder = $attr->{builder} or return $attr;
   my $config  = $builder->can( 'config' ) ? $builder->config : {};
   my $keys    = [ 'gettext_catagory', 'localedir' ];

   merge_attributes $attr, $builder, $keys;
   merge_attributes $attr, $config,  $keys;

   return $attr;
};

around 'source' => sub {
   my ($orig, $self) = @_; return $orig->( $self, $self->source_name );
};

around 'resultset' => sub {
   my ($orig, $self) = @_; return $orig->( $self, $self->source_name );
};

around 'load' => sub {
   my ($orig, $self, $lang, @files) = @_;

   my @paths = grep { $self->$_is_file_or_log_debug( $_ ) }
               map  { $self->object_file( $lang, $_ ) } @files;

   not $paths[ 0 ] and not $self->path and return {};

   my $data  = $orig->( $self, @paths );
   my $po_header = exists $data->{po_header}
                 ? $data->{po_header}->{msgstr} // {} : {};
   my $plural_func;

   # This is here because of the code ref. Cannot serialize (cache) a code ref
   # Determine plural rules. The leading and trailing space is necessary
   # to be able to match against word boundaries.
   if (exists $po_header->{plural_forms}) {
      my $code = SPC.$po_header->{plural_forms}.SPC;

      $code =~ s{ ([^_a-zA-Z0-9] | \A) ([_a-z][_A-Za-z0-9]*)
                     ([^_a-zA-Z0-9]) }{$1\$$2$3}gmsx;
      $code = "sub { my \$n = shift; my (\$plural, \$nplurals);
                     $code;
                     return (\$nplurals, \$plural ? \$plural : 0); }";

      # Now try to evaluate the code. There is no need to run the code in
      # a Safe compartment. The above substitutions should have destroyed
      # all evil code. Corrections are welcome!
      $plural_func = eval $code; ## no critic
      $EVAL_ERROR and $plural_func = undef;
   }

   # Default is Germanic plural (which is incorrect for French).
   $data->{plural_func} = $plural_func // sub { (2, shift > 1) };

   return $data;
};

sub _trigger_source_name {
   my ($self, $source) = @_;

   $source eq 'mo' and $self->storage_class( '+File::Gettext::Storage::MO' );
   $source eq 'po' and $self->storage_class( '+File::Gettext::Storage::PO' );

   return;
}

# Public methods
sub object_file {
   my ($self, $lang, $file) = @_;

   $lang or throw Unspecified, [ 'language' ];
   $file or throw Unspecified, [ 'language file name' ];

   my $dir = $self->localedir; my $extn = $self->storage->extn;

   length $self->gettext_catagory or return $dir->catfile( $lang, $file.$extn );

   return $dir->catfile( $lang, $self->gettext_catagory, $file.$extn );
}

sub set_path {
   my $self = shift; return $self->path( $self->object_file( @_ ) );
}

1;

__END__

=pod

=encoding utf-8

=begin html

<a href="https://travis-ci.org/pjfl/p5-file-gettext"><img src="https://travis-ci.org/pjfl/p5-file-gettext.svg?branch=master" alt="Travis CI Badge"></a>
<a href="https://roxsoft.co.uk/coverage/report/file-gettext/latest"><img src="https://roxsoft.co.uk/coverage/badge/file-gettext/latest" alt="Coverage Badge"></a>
<a href="http://badge.fury.io/pl/File-Gettext"><img src="https://badge.fury.io/pl/File-Gettext.svg" alt="CPAN Badge"></a>
<a href="http://cpants.cpanauthors.org/dist/File-Gettext"><img src="http://cpants.cpanauthors.org/dist/File-Gettext.png" alt="Kwalitee Badge"></a>

=end html

=head1 Name

File::Gettext - Read and write GNU Gettext po / mo files

=head1 Version

This documents version v0.33.$Rev: 1 $ of L<File::Gettext>

=head1 Synopsis

   use File::Gettext;

   my $domain = File::Gettext->new( $attrs )->load( $lang, @files );

=head1 Description

Extends L<File::DataClass::Schema>. Provides for the reading and
writing of GNU Gettext PO files and the reading of MO files. Used by
L<Class::Usul::L10N> to translate application message strings into different
languages

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<charset>

Default character set used it the F<mo> / F<po> does not specify one. Defaults
to C<iso-8859-1>

=item C<default_po_header>

Default header information used to create new F<po> files

=item C<gettext_catagory>

Subdirectory of a language specific subdirectory of L</localdir> that contains
the F<mo> / F<po> files. Defaults to C<LC_MESSAGES>. Can be set to the null
string to eliminate from path

=item C<header_key_table>

Maps attribute header names onto their F<po> file header strings

=item C<localedir>

Base path to the F<mo> / F<po> files

=item C<result_source_attributes>

Defines the attributes available in the result object

=item C<source_name>

Either F<po> or F<mo>. Defaults to F<po>

=back

=head1 Subroutines/Methods

=head2 C<BUILDARGS>

Extracts default attribute values from the C<builder> parameter

=head2 C<load>

This method modifier adds the pluralisation function to the return data

=head2 C<object_file>

   $gettext->object_file( $lang, $file );

Returns the path to the F<po> / F<mo> file for the specified language

=head2 C<resultset>

A method modifier that provides the result source name to the same method
in the parent class

=head2 C<set_path>

   $gettext->set_path( $lang, $file );

Sets the I<path> attribute on the parent class from C<$lang> and C<$file>

=head2 C<source>

A method modifier that provides the result source name to the same method
in the parent class

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<File::DataClass>

=item L<Moo>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2016 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
