package Locale::Meta;

# ABSTRACT: Localization tool based on Locale::Wolowitz.

use strict;
use warnings;
use utf8;
use Carp;
use JSON::MaybeXS qw/JSON/;

our $VERSION = "0.008";

=head1 NAME

Locale::Meta - Multilanguage support loading json structures based on Locale::Wolowitz.

=head1 VERSION

version 0.008

=head1 SYNOPSIS

  #in ./i18n/file.json
  {
    "en": {
      "color": {
        "trans" : "color"
        "meta": {
          "searchable": 1,
        }
      }
    },
    "en_gb": {
      "color": {
        "trans": "colour"
      }
    }
  }

  # in your app
  use Locale::Meta

  my $lm = Locale::Meta->new('./i18n');
 
	print $lm->loc('color', 'en_gb'); # prints 'colour'

=head1 DESCRIPTION

Locale::Meta has been inspired by Locale::Wolowitz, and the base code, documentation,
and function has been taken from it.  The main goal of Locale::Meta is to 
provide the same functionality as Locale::Wolowitz, but removing the dependency of the 
file names as part of the definition of the language, to manage a new json data structure 
for the .json files definitions, and also, add a meta field in order to be 
able to extend the use of the locate to other purposes, like search.

The objective of the package is to take different json structures, transform the
data into key/value structure and build a big repository into memory to be use as
base point to localize language definitions.

The metadata attribute "meta" defined on the json file is optional and is used
to maintain information related to the definition of the term.

package Locale::Meta;

=head1 CONSTRUCTOR

=head2 new( [ $path / $filename, \%options ] )

Creates a new instance of this module. A path to a directory in
which JSON localization files exist, or a path to a specific localization
file. If you pass a directory, all JSON localization files
in it will be loaded and merged. If you pass one file, only that file will be loaded.

Note that C<Locale::Meta> will ignore dotfiles in the provided path (e.g.
hidden files, backups files, etc.).


A hash-ref of options can also be provided. The only option currently supported
is C<utf8>, which is on by default. If on, all JSON files are assumed to be in
UTF-8 character set and will be automatically decoded. Provide a false value
if your files are not UTF-8 encoded, for example:

	Locale::Meta->new( '/path/to/files', { utf8 => 0 } );


=cut

sub new {
	my ($class, $path, $options) = @_;

	$options ||= {};

	my $self = bless {}, $class;

	$self->{json} = JSON->new->relaxed;
	$self->{json}->utf8;

	$self->load_path($path)
		if $path;

	return $self;
}

=head1 OBJECT METHODS

=head2 load_path( $path / $filename )

Receives a path to a directory in which JSON localization files exist, or a
path to a specific localization file, and loads (and merges) the localization
data from the file(s). If localization data was already loaded previously,
the structure will be merged, with the new data taking precedence.

You can call this method and L<load_structure()|/"load_structure( \%structure, [ $lang ] )">
as much as you want, the data from each call will be merged with existing data.

=cut

sub load_path {
	my ($self, $path) = @_;

	croak "You must provide a path to localization directory."
		unless $path;

	$self->{locales} ||= {};

	my @files;

	if (-d $path) {
		# open the locales directory
		opendir(PATH, $path)
			|| croak "Can't open localization directory: $!";
	
		# get all JSON files
		@files = grep {/^[^.].*\.json$/} readdir PATH;

		closedir PATH
			|| carp "Can't close localization directory: $!";
	} elsif (-e $path) {
		my ($file) = ($path =~ m{/([^/]+)$})[0];
		$path = $`;
		@files = ($file);
	} else {
		croak "Path must be to a directory or a JSON file.";
	}

	# load the files
	foreach (@files) {
		# read the file's contents and parse it as json
		open(FILE, "$path/$_")
			|| croak "Can't open localization file $_: $!";
		local $/;
		my $json = <FILE>;
		close FILE
			|| carp "Can't close localization file $_: $!";

		my $data = $self->{json}->decode($json);

    #Get the language definitions
    foreach my $lang (keys %$data){
      foreach my $key (keys %{$data->{$lang}}){
        $self->{locales}->{$key} ||= {};
				$self->{locales}->{$key}->{$lang} = $data->{$lang}->{$key}->{trans} || $data->{$lang}->{$key};
        $self->{locales}->{$key}->{meta} ||={};
        foreach my $meta_key ( keys %{$data->{$lang}->{$key}->{meta}} ) {
          $self->{locales}->{$key}->{meta}->{$meta_key} = $data->{$lang}->{$key}->{meta}->{$meta_key};
        }
      }
    };
	}

	return 1;
}


=head2 charge($structure)

  Load #structure into $self->{locales}

=cut

sub charge{
  my ($self, $structure) = @_;
  $self->{locales} ||= {};
  if ( (ref $structure) =~ /HASH/ ){
    foreach my $lang ( keys %{$structure} ){
      foreach my $key ( keys %{$structure->{$lang}} ){
        $self->{locales}->{$key} ||= {};
        $self->{locales}->{$key}->{$lang} = $structure->{$lang}->{$key}->{trans} || $structure->{$lang}->{$key};
        $self->{locales}->{$key}->{meta} ||={};
        foreach my $meta_key ( keys %{$structure->{$lang}->{$key}->{meta}} ) {
          $structure->{$lang}->{$key}->{meta}->{$meta_key} = $structure->{$lang}->{$key}->{meta}->{$meta_key};
        }
      }
    }
  }
  else{
    croak "Structure received by charge method isn't a Hash";
  }
  return;
}

=head2 loc( $msg, $lang, [ @args ] )

Returns the string C<$msg>, translated to the requested language (if such
a translation exists, otherwise no traslation occurs). Any other parameters
passed to the method (C<@args>) are injected to the placeholders in the string
(if present).

=cut

sub loc {
	my ($self, $key, $lang, @args) = @_;

	return unless defined $key; # undef strings are passed back as-is
	return $key unless $lang;

	my $ret = $self->{locales}->{$key} && $self->{locales}->{$key}->{$lang} ? $self->{locales}->{$key}->{$lang} : $key;

	if (scalar @args) {
		for (my $i = 1; $i <= scalar @args; $i++) {
			$ret =~ s/%$i/$args[$i-1]/g;
		}
	}

	return $ret;
}

=head1 DIAGNOSTICS

The following exceptions are thrown by this module:

=over

=item C<< "You must provide a path to localization directory." >>

This exception is thrown if you haven't provided the C<new()> subroutine
a path to a localization file, or a directory of localization files. Read
the documentation for the C<new()> subroutine above.

=item C<< "Can't open localization directory: %s" and "Can't close localization directory: %s" >>

This exception is thrown if Locale::Meta failed to open/close the directory
of the localization files. This will probably happen due to permission
problems. The error message should include the actual reason for the failure.

=item C<< "Path must be to a directory or a JSON file." >>

This exception is thrown if you passed a wrong value to the C<new()> subroutine
as the path to the localization directory/file. Either the path is wrong and thus
does not exist, or the path does exist, but is not a directory and not a file.

=item C<< "Can't open localization file %s: %s" and "Can't close localization file %s: %s" >>

This exception is thrown if Locale::Wolowitz fails to open/close a specific localization
file. This will usually happen because of permission problems. The error message
will include both the name of the file, and the actual reason for the failure.

=back

=head1 CONFIGURATION AND ENVIRONMENT
  
C<Locale::Meta> requires no configuration files or environment variables.

=head1 DEPENDENCIES

C<Locale::Meta> B<depends> on the following CPAN modules:

=over

=item * L<Carp>

=item * L<JSON::MaybeXS>

=back

C<Locale::Meta> recommends L<Cpanel::JSON::XS> or L<JSON::XS> for faster
parsing of JSON files.

=head1 INCOMPATIBILITIES WITH OTHER MODULES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<https://github.com/ramortegui/LocaleMeta>

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
1;
