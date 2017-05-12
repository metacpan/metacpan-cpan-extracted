
# NAME
    Locale::Meta - Multilanguage support loading json structures based on
    Locale::Wolowitz.

# VERSION
    version 0.008

# SYNOPSIS
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

# DESCRIPTION

    Locale::Meta has been inspired by Locale::Wolowitz, and the base code,
    documentation, and function has been taken from it. The main goal of
    Lecale::Meta is to provide the same functionality as Locale::Wolowitz, but
    removing the dependency of the file names as part of the definition of the
    language, to manage a new json data structure for the .json files
    definitions, and also, add a meta field in order to be able to extend the
    use of the locate to other purposes, like search.

    The objective of the package is to take different json structures,
    transform the data into key/value structure and build a big repository
    into memory to be use as base point to localize language definitions.

    The metadata attribute "meta" defined on the json file is optional and is
    used to maintain information related to the definition of the term.

    package Locale::Meta;

## CONSTRUCTOR

  new( [ $path / $filename, \%options ] )
  
    Creates a new instance of this module. A path to a directory in which JSON
    localization files exist, or a path to a specific localization file. If
    you pass a directory, all JSON localization files in it will be loaded and
    merged. If you pass one file, only that file will be loaded.

    Note that "Locale::Meta" will ignore dotfiles in the provided path (e.g.
    hidden files, backups files, etc.).

    A hash-ref of options can also be provided. The only option currently
    supported is "utf8", which is on by default. If on, all JSON files are
    assumed to be in UTF-8 character set and will be automatically decoded.
    Provide a false value if your files are not UTF-8 encoded, for example:

            Locale::Meta->new( '/path/to/files', { utf8 => 0 } );

## OBJECT METHODS

### load_path( $path / $filename )

    Receives a path to a directory in which JSON localization files exist, or
    a path to a specific localization file, and loads (and merges) the
    localization data from the file(s). If localization data was already
    loaded previously, the structure will be merged, with the new data taking
    precedence.

    You can call this method and load_structure() as much as you want, the
    data from each call will be merged with existing data.

### load_structure ( $structure)
    
    Receives a Hash variable representing the same structure as the synopsis, and
    load the structure into the locales.

###  loc( $msg, $lang, [ @args ] )

    Returns the string $msg, translated to the requested language (if such a
    translation exists, otherwise no traslation occurs). Any other parameters
    passed to the method (@args) are injected to the placeholders in the
    string (if present).

## DIAGNOSTICS

    The following exceptions are thrown by this module:

    "You must provide a path to localization directory."
     This exception is thrown if you haven't provided the "new()"
     subroutine a path to a localization file, or a directory of
     localization files. Read the documentation for the "new()" subroutine
     above.

    "Can't open localization directory: %s" and "Can't close localization directory: %s" 
     This exception is thrown if Locale::Meta failed to open/close the
     directory of the localization files. This will probably happen due to
     permission problems. The error message should include the actual
     reason for the failure.

    "Path must be to a directory or a JSON file."
     This exception is thrown if you passed a wrong value to the "new()"
     subroutine as the path to the localization directory/file. Either the
     path is wrong and thus does not exist, or the path does exist, but is
     not a directory and not a file.

    "Can't open localization file %s: %s" and "Can't close localization file %s: %s"
     This exception is thrown if Locale::Wolowitz fails to open/close a
     specific localization file. This will usually happen because of
     permission problems. The error message will include both the name of
     the file, and the actual reason for the failure.

# CONFIGURATION AND ENVIRONMENT

"Locale::Meta" requires no configuration files or environment variables.

# DEPENDENCIES

"Locale::Meta" depends on the following CPAN modules:

  * Carp

  * JSON::MaybeXS

"Locale::Meta" recommends Cpanel::JSON::XS or JSON::XS for faster parsing
of JSON files.

# INCOMPATIBILITIES WITH OTHER MODULES
None reported.

# BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
"https://github.com/ramortegui/LocaleMeta"

## COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Ruben Amortegui.

This is free software; you can redistribute it and/or modify it 
under the same terms as the Perl 5 programming language system itself.



## DISCLAIMER OF WARRANTY

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

