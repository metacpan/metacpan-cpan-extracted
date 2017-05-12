package Locale::Maketext::From::Strings;

=head1 NAME

Locale::Maketext::From::Strings - Parse Apple .strings files

=head1 VERSION

0.03

=head1 SYNOPSIS

  use Locale::Maketext::From::Strings;

  my $strings = Locale::Maketext::From::Strings->new(
                  path => '/path/to/strings',
                  namespace => 'MyApp::I18N',
                  out_dir => 'lib',
                );

  $strings->load; # in memory
  $strings->generate; # to disk

=head1 DESCRIPTION

This module will parse C<.strings> file used in the Apple world and generate
in memory perl-packages used by the L<Locale::Maketext> module.

=head2 Formatting rules

This module can parse most of the formatting mentioned here:
L<http://blog.lingohub.com/developers/2013/03/i18n-resource-file-formats-ios-strings-files/>.

=over 4

=item *

Key-value pairs are delimited with the equal character (=), and terminated by
a semicolon (;).

=item *

Keys and values are surrounded by double quotes (").

=item *

Place-holders look can be: %.2f, %d, %1$s:

  qr{\%[\d|\.]*\$*\d*[dsf]\b}

=item *

Comments start at the beginning of the line and span the whole line.

=item *

Multi-line comments are enclosed in /* */.

=item *

Single-line comments start with double slashes (//).

=item *

The specification says it expect UTF-16LE encoding by default, but this
module expect UTF-8 instead.

NOTE! This might change in future release. Pass L</encoding> to constructor
if you want to be sure about the value.

=back

=head2 Example file

This could be the content of "i18n/en.strings":

  /* comments in .strings files
  can be multi line,
  single line */
  // or combination of the two
  "hello_user" = "Hello %1$s";

  "Sample data" = "sample %s %d %.3f data";

  // keys and values can be spread to multiple lines
  "welcome_message" = "Welcome back,
  we have missed you";

TIP! Adding the default value on the left side (instead of hello_user and
welcome_message) works better with L<Locale::Maketext> since it will use that
as fallback if translation is missing.

=cut

use strict;
use warnings;
use File::Spec::Functions qw( catfile splitdir );
use Data::Dumper ();
use constant DEBUG => $ENV{MAKETEXT_FROM_STRINGS_DEBUG} ? 1 : 0;

our $VERSION = '0.03';

=head1 ATTRIBUTES

=head2 encoding

Holds the encoding used when reading the C<.strings> files. Defaults to
"UTF-8".

=cut

sub encoding { shift->{encoding} ||= 'UTF-8' }

=head2 namespace

Package name of where to L</generate> or L</load> code into. Default to the
caller namespace.

=cut

sub namespace {
  my $self = shift;
  $self->{namespace} ||= do {
    my $caller = (caller 0)[0];
    $caller = (caller 1) if $caller->isa(__PACKAGE__);
    $caller .= '::I18N';
  };
}

=head2 out_dir

Directory to where files should be written to. Defaults to "lib".

=cut

sub out_dir { shift->{out_dir} ||= 'lib' }

=head2 path

Path to ".strings" files. Defaults to "i18n".

=cut

sub path { shift->{path} ||= 'i18n' }

sub _namespace_dir {
  my $self = shift;
  $self->{_namespace_dir} ||= do {
    my $dir = $self->namespace;
    $dir =~ s!::!/!g;
    $dir;
  };
}

=head1 METHODS

=head2 new

  $self = Locale::Maketext::From::Strings->new(%attributes);
  $self = Locale::Maketext::From::Strings->new($attributes);

Object constructor.

=cut

sub new {
  my $class = shift;
  bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
}

=head2 generate

  Locale::Maketext::From::Strings->generate($namespace);
  $self->generate;

This method will write the I18N code to disk. Use this when the L</load> time
goes up.

NOTE! This method does not check for existing files - they will be overwritte
without warning.

Example one-liners:

  $ perl -MLocale::Maketext::From::Strings=generate -e1 MyApp::I18N
  $ perl -Ilib -E'say +(require MyApp::I18N)->get_handle(shift)->maketext(@ARGV);' en "some key" ...

=cut

sub generate {
  my $self = shift;
  my($code, $namespace_dir, $path);

  unless(ref $self) {
    $self = bless @_ ? @_ > 1 ? {@_} : !ref $_[0] ? { namespace => shift } : {%{$_[0]}} : {}, $self;
  }

  $path = $self->path;
  $namespace_dir = catfile $self->out_dir, $self->_namespace_dir;

  _mkdir($namespace_dir);
  _spurt($self->_namespace_code, $namespace_dir .'.pm') unless -s $namespace_dir .'.pm';
  opendir(my $DH, $path) or die "opendir $path: $!";

  for my $file (grep { /\.strings$/ } readdir $DH) {
    my $language = $file;
    my($code, $kv);

    $language =~ s/\.strings$// or next;
    $code = $self->_package_code($language);
    $kv = $self->parse(catfile $path, $file);

    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Terse = 1;
    $kv = Data::Dumper::Dumper($kv);
    $kv =~ s!^\{!our %Lexicon = (!;
    $kv =~ s!\}$!);!;
    substr $code, -3, -3, $kv;
    _spurt($code, catfile $namespace_dir, "$language.pm");
  }

  return $self;
}

=head2 load 

  Locale::Maketext::From::Strings->load($path);
  $self->load;

Will parse C<language.strings> files from L</path> and generage in-memory
packages in the given L</namespace>.

Example L<Mojolicious> app:

  package MyApp;
  use Locale::Maketext::From::Strings;
  use base 'Mojolicious';

  sub startup {
    my $self = sihft;
    my $default_lang = 'en';

    Locale::Maketext::From::Strings->load($self->home->rel_dir('i18n'));

    $self->helper(l => sub {
      my $c = shift;
      $c->stash->{i18n} ||= MyApp::I18N->get_handle($c->session('lang'), $default_lang);
      $c->stash->{i18n}->maketext(@_);
    });
  }

See also L<Mojolicious::Plugin::I18N>.

=cut

sub load {
  my $self = shift;
  my($namespace, $namespace_dir, $path);

  unless(ref $self) {
    $self = bless @_ ? @_ > 1 ? {@_} : !ref $_[0] ? { path => shift } : {%{$_[0]}} : {}, $self;
  }

  $namespace = $self->namespace;
  $namespace_dir = $self->_namespace_dir;
  $path = $self->path;

  eval $self->_namespace_code or die $@;
  $INC{"$namespace_dir.pm"} = 'GENERATED';
  opendir(my $DH, $path) or die "opendir $path: $!";

  for my $file (grep { /\.strings$/ } readdir $DH) {
    my $language = $file;
    $language =~ s/\.strings$// or next;

    eval $self->_package_code($language) or die $@;
    $self->parse(catfile($path, $file), eval "\\%$namespace\::$language\::Lexicon");
    $INC{"$namespace_dir/$language.pm"} = 'GENERATED';
  }

  return $self;
}

=head2 parse

  $data = $self->parse($file);

Will parse C<$file> and store the key value pairs in C<$data>.

=cut

sub parse {
  my($self, $file, $data) = @_;
  my $encoding = $self->{encoding} || 'UTF-8';
  my $buf = '';

  $data ||= {};
  open my $FH, "<:encoding($encoding)", $file or die "read $file: $!";

  while(<$FH>) {
    $buf .= $_;

    if($buf =~ s!"([^"]+)"\s*=\s*"([^"]+)(");!!s) { # key-value
      my($key, $value) = ($1, $2);
      warn "[$file] ($key) => ($value)\n" if DEBUG;
      my $pos = 0;
      $data->{$key} = $value;
      $data->{$key} =~ s/\%(\d*)\$?([\d\.]*[dsf])\b/{ ++$pos; sprintf '[sprintf,%%%s,_%s]', $2, $1 || $pos }/ge;
    }
    elsif($buf =~ s!^//(.*)$!!m) { # comment
      warn "[$file] COMMENT ($1)\n" if DEBUG;
    }
    elsif($buf =~ s!/\*(.*)\*/!!s) { # multi-line comment
      warn "[$file] MULTI-LINE-COMMENT ($1)\n" if DEBUG;
    }
  }

  return $data;
}

=head2 import

See L</generate> for example one-liner.

=cut

sub import {
  my $class = shift;

  if(@_ and $_[0] eq 'generate') {
    $class->generate(@ARGV);
  }
}

sub _mkdir {
  my @path = splitdir shift;
  my @current_path;

  for my $part (@path) {
    push @current_path, $part;
    my $dir = catfile @current_path;
    next if -d $dir;
    mkdir $dir or die "mkdir $dir: $!";
  }
}

sub _namespace_code {
  my $self = shift;
  my $namespace = $self->namespace;

  if(eval "require $namespace; 1") {
    return $self;
  }

  return <<"  PACKAGE"
package $namespace;
use base 'Locale::Maketext';
our \%Lexicon = ( _AUTO => 1 );
our \%LANGUAGES = (); # key = language name, value = class name
"$namespace";
  PACKAGE
}

sub _package_code {
  my($self, $language) = @_;
  my $namespace = $self->namespace;

  return <<"  PACKAGE";
\$${namespace}::LANGUAGES{$language} = "$namespace\::$language";
package $namespace\::$language;
use base '$namespace';
1;
  PACKAGE
}

sub _spurt {
  my($content, $path) = @_;
  die qq{Can't open file "$path": $!} unless open my $FH, '>', $path;
  die qq{Can't write to file "$path": $!} unless defined syswrite $FH, $content;
}

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
