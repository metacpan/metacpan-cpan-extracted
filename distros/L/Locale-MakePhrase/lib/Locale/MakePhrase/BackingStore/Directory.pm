package Locale::MakePhrase::BackingStore::Directory;
our $VERSION = 0.3;
our $DEBUG = 0;

=head1 NAME

Locale::MakePhrase::BackingStore::Directory - Retrieve translations
from files located in a specified directory.

=head1 DESCRTIPION

This backing store is capable of loading language rules, from files
located in the specified directory.  All files ending with the
extension B<.mpt> will try to be loaded.

Files need to be named according to language/dialect. For example:

  en.mpt
  en_au.mpt
  cn.mpt

Thus, the filename is used to defined the I<language> component of
the language rule object.

The files must be formatted as shown in the B<en.mpt-example> and
B<cn.mpt-example> files (which can be located in the same directories
that these modules are are installed in).  The important points to
note are that the file is broken into groups containing:

=over 2

=item B<key>

=item B<expression>

=item B<priority>

=item B<translation>

Where expression & priority are optional.  However, if you specify the
priority and/or expression, make sure the translation key is the last
entry in the group - this is necessary, as we dont know when the
the block is finished.

=back

=head1 API

The following methods are implemented:

=cut

use strict;
use warnings;
use utf8;
use Data::Dumper;
use base qw(Locale::MakePhrase::BackingStore);
use I18N::LangTags;
use Locale::MakePhrase::Utils qw(alltrim die_from_caller);
our $implicit_data_structure = [ "key","expression","priority","translation" ];
our $language_file_extension = '.mpt';  # .mpt => 'MakePhrase Translations'
our $default_encoding = 'utf-8';
local $Data::Dumper::Indent = 1 if $DEBUG;

#--------------------------------------------------------------------------

=head2 $self new([...])

We support loading text/translations (from the translation files) which
may be encoded using any character encoding.  Since we need to know
something about the files we are trying to load, we expect this object
to be constructed with the following options:

=over 2

=item C<directory>

The full path to the directory containing the translation files. eg:

  /usr/local/myapp/translations

Default: none; you must specify a directory

=item C<extension>

You can specify a different file extension to use, rather than using
B<.mpt>.

Default: use B<.mpt> as the extension

=item C<encoding>

We can load translations from any enocding supported by the L<Encode>
module.  Upon load, this module will convert the translations from
the specified encoding, into the interal encoding of UTF-8.

Default: load UTF-8 text translations.

=item C<reload>

This module will dynamically reload its known translations, if the
files get updated.  You can set this option to avoid reloading the
file if it changes.

Default: reload language files if changed

=back

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = bless {}, $class;

  # get options
  my %options;
  if (@_ > 1 and not(@_ % 2)) {
    %options = @_;
  } elsif (@_ == 1 and ref($_[0]) eq 'HASH') {
    %options = %{$_[0]};
  } elsif (@_ == 1) {
    $options{directory} = shift;
  }
  print STDERR "Arguments to ". ref($self) .": ". Dumper(\%options) if $DEBUG > 5;

  # allow sub-class to control construction
  $self = $self->init();
  return undef unless $self;

  $self->{directory} = (exists $options{directory}) ? $options{directory} : $self->{directory};
  $self->{extension} = (exists $options{extension}) ? $options{extension} : (exists $self->{extension}) ? $self->{extension} : $language_file_extension;
  $self->{encoding} = (exists $options{encoding}) ? $options{encoding} : (exists $self->{encoding}) ? $self->{encoding} : $default_encoding;
  $self->{reload} = (exists $options{reload}) ? ($options{reload} ? 1 : 0) : (exists $self->{reload}) ? ($self->{reload} ? 1 : 0) : 1;
  $self->{loaded_languages} = {};
  $self->{rules} = {};

  # Error checking
  die_from_caller("Missing 'directory' definition") unless (defined $self->{directory});
  die_from_caller("No such directory:",$self->{directory}) unless (-d $self->{directory});
  die_from_caller("Invalid encoding specified") unless $self->{encoding};
  die_from_caller("Invalid file extension") unless (defined $self->{extension});

  # check the file extension
  if (length $self->{extension} and substr($self->{extension},0,1) ne '.') {
    $self->{extension} = ".".$self->{extension};
  }

  # Pre-load all available languages
  $self->_load_language_files();

  return $self;
}

#--------------------------------------------------------------------------

=head2 \@rule_objs get_rules($context,$key,\@languages)

Retrieve the translations (that have been previously loaded), using
the selected languages.  This implementation will reload the
appropiate language file if it changes (unless it has been told not
to).

=cut

sub get_rules {
  my ($self,$context,$key,$languages) = @_;
  my @translations;

  # make sure languages are loaded
  $self->_load_languages($languages) if $self->{reload};

  # look for rules for each language in the current key
  my @langs;
  my $rules = $self->{rules};
  foreach my $language (@$languages) {
    next unless (exists $rules->{$language});
    push @langs, $rules->{$language};
  }
  return undef unless @langs;
  $rules = undef;

  # Only use rules which match this context, if we are using a context
  if ($context) {

    # look for rules that match the key
    foreach my $language (@langs) {
      my $keys = $language->{$key};
      next unless ($keys or ref($keys) ne 'HASH');
      $keys = $keys->{$context};
      next unless $keys;
      foreach my $ky (@$keys) {
        push @translations, $ky;
      }
    }

  } else {

    # look for rules that match the key
    foreach my $language (@langs) {
      my $keys = $language->{$key};
      next unless $keys;
      $keys = $keys->{_};
      foreach my $ky (@$keys) {
        push @translations, $ky;
      }
    }

  }

  print STDERR "Found translations:\n", Dumper(@translations) if $DEBUG;
  return \@translations;
}

#--------------------------------------------------------------------------
# The following methods are not part of the API - they are private.
#
# This means that everything above this code-break is allowed/designed
# to be overloaded.
#--------------------------------------------------------------------------

#--------------------------------------------------------------------------
#
# Load all the available language files
#
sub _load_language_files {
  my ($self) = @_;
  my $dir = $self->{directory};
  my $ext = $self->{extension};
  die_from_caller("Directory is not readable:",$dir) unless (-r $dir);
  opendir(DIR, $dir) or die_from_caller("Failed to read into directory:",$dir);
  my @files = readdir(DIR);
  closedir DIR;
  foreach my $language (@files) {
    next unless ($language =~ /$ext$/);
    next unless ((-f "$dir/$language" || -l "$dir/$language") and -r "$dir/$language");
    $language =~ s/$ext$//;
    next unless I18N::LangTags::is_language_tag($language);
    $self->_load_language($language);
  }
}

#--------------------------------------------------------------------------
#
# Load the translations for each language.
#
# If the file for that language hasn't yet been loaded or its mtime has changed,
# load it into the cache.
#
# If the cached language is valid, dont do anything.
#
sub _load_languages {
  my ($self,$languages) = @_;
  my $loaded_languages = $self->{loaded_languages};
  my $rules = $self->{rules};
  foreach my $language (@$languages) {
    if (exists $loaded_languages->{$language}) {
      my $file = $loaded_languages->{$language}->{file};
      my $mtime = (stat($file))[9];
      next if ($loaded_languages->{$language}->{mtime} == $mtime);
      $rules->{$language} = undef;
    }
    $self->_load_language($language);
  }
}

#--------------------------------------------------------------------------
#
# Load the translations for the language.
#
sub _load_language {
  my ($self,$language) = @_;

  # get the name of the language file, then open it
  my $file;
  if (exists $self->{loaded_languages}->{$language}) {
    $file = $self->{loaded_languages}->{$language}->{file};
  }
  unless (defined $file) {
    $file = $self->_get_language_filename($language);
    return unless (defined $file);
    $self->{loaded_languages}->{$language}->{file} = $file;
  }
  $self->{loaded_languages}->{$language}->{mtime} = (stat($file))[9];

  # Load the translations from the file (skip empty lines, or comments)
  my $rules = $self->{rules}->{$language};
  $rules = {} unless $rules;
  my ($key,$expression,$priority,$translation,$context);
  my $in_group = 0;
  my $line = 0;
  my $encoding = $self->{encoding};
  my $fh;
  open ($fh, "<:encoding($encoding)", "$file") || return;

  while (<$fh>) {
    chomp;
    s/$//;
    $line++;
    $_ = alltrim($_);
    next if (not defined or length == 0 or /^#/);

    # search for group entries
    /^
      ([^=]*)=(.*)
      |
      (?:.+)
     $/sx;
    next unless ($1);
    my $lhs = alltrim($1);
    my $rhs = alltrim($2);

    # process group entries
    if ($lhs eq 'key') {
      die_from_caller("Found another group while processing previous group, file '$file' line '$line'") if $in_group;
      $in_group++;
      $key = $rhs;
      die_from_caller("Key must have some length, file '$file' line '$line'") unless (length $key);
#      $line += _read_lines($fh,\$key);
      next;
    } elsif ($lhs eq 'expression' and not defined $expression) {
      $expression = $rhs;
    } elsif ($lhs eq 'priority' and not defined $priority) {
      $priority = $rhs;
      $priority = int($priority); # must be a valid number
    } elsif ($lhs eq 'translation' and not defined $translation) {
      $translation = $rhs;
      die_from_caller("Translation must have some length, file '$file' line '$line'") unless (length $translation);
#      $line += _read_lines($fh,\$translation);
    } elsif ($lhs eq 'context' and not defined $context) {
      $context = $rhs;
    } else {
      die_from_caller("Syntax error in translation file '$file', line '$line'");
    }

    # Have we enough info to make a linguistic rule?
    next unless (defined $translation);
    $expression = "" unless $expression;
    $priority = 0 unless $priority;
    $context = "" unless $context;

    # Make this linguistic rule, and add it to any others that may exist for this language/key
    $in_group--;
    my $entries;
    if ($context) {
      $entries = $rules->{$key}{$context};
      unless ($entries) {
        $entries = [] unless $entries;
        $rules->{$key}{$context} = $entries;
      }
    } else {
      $entries = $rules->{$key}{_};
      unless ($entries) {
        $entries = [] unless $entries;
        $rules->{$key}{_} = $entries;
      }
    }
    push @$entries, $self->make_rule(
      key => $key,
      language => $language,
      expression => $expression,
      priority => $priority,
      translation => $translation,
    );

    $key = $expression = $priority = $translation = $context = undef;
  }

  close $fh;
  $self->{rules}->{$language} = $rules;
}

#--------------------------------------------------------------------------
#
# Helper routine for looking up filenames for a given language
#
sub _get_language_filename {
  my ($self, $language) = @_;
  my $path = $self->{directory} ."/". $language . $self->{extension};
  if ((-f $path || -l $path) and -r $path) {
    print STDERR "Found new language file: $path" if $DEBUG > 2;
    return $path;
  }
  return undef;
}

#--------------------------------------------------------------------------
#
# Helper routine for reading multiple lines for a given key
#
sub _read_lines {
  my ($fh,$s_ref);
  my $line = 0;
  if ($$s_ref =~ /\/$/) {
    while (<$fh>) {
      chomp;
      s/$//;
      $line++;
      $_ = alltrim($_);
      if (/\.\s*\\$/) {
        $$s_ref =~ s/\s*\/$/\n/;
      } else {
        $$s_ref =~ s/\s*\/$/ /;
      }
      $$s_ref .= $_;
      last unless ($$s_ref =~ /\/$/);
    }
  }
  return $line;
}

1;
__END__
#--------------------------------------------------------------------------

=head1 NOTES

=head2 file extension

If you find that the filename extension B<.mpt> is unsuitable, you can
change it by setting the variable:

C<$Locale::MakePhrase::BackingStore::Directory::language_file_extension>

to the extension that you prefer, or simply set it in your constructor.

=head2 line-ending

We automatically handle the Unix/MS-DOS line-ending difference.

=head2 multi-line

Strings can be spanned over multiple lines, if the end of the line is
backslash-escaped.

=cut

