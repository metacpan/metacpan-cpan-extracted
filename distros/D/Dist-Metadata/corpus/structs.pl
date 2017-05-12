#
# This file is part of Dist-Metadata
#
# This software is copyright (c) 2011 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
$Dist::Metadata::Test::Structs = {
  'index_like_pause' => {
    'Dist-Metadata-Test-LikePause-0.1/README' => 'This "dist" is for testing Dist::Metadata.
',
    'Dist-Metadata-Test-LikePause-0.1/lib/Dist/Metadata/Test/LikePause.pm' => 'package Dist::Metadata::Test::LikePause;

# ABSTRACT: Fake dist for testing metadata determination

our $VERSION = \'0.1\';

# This should be excluded unless "include_inner_packages" is true
package ExtraPackage;

our $VERSION = \'0.2\';
'
  },
  'metafile' => {
    'Dist-Metadata-Test-MetaFile-2.2/META.json' => '{
   "abstract" : "Fake dist for testing metadata determination",
   "author" : [
      "Randy Stauner <rwstauner@cpan.org>"
   ],
   "dynamic_config" : 0,
   "generated_by" : "hand",
   "license" : [
      "perl_5"
   ],
   "meta-spec" : {
      "url" : "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
      "version" : "2"
   },
   "name" : "Dist-Metadata-Test-MetaFile",
   "no_index" : {
      "directory" : [
         "corpus",
         "examples",
         "inc",
         "share",
         "t",
         "xt"
      ]
   },
   "provides" : {
      "Dist::Metadata::Test::MetaFile" : {
         "file" : "lib/Dist/Metadata/Test/MetaFile.pm",
         "version" : "2.1"
      },
      "Dist::Metadata::Test::MetaFile::PM" : {
         "file" : "lib/Dist/Metadata/Test/MetaFile/PM.pm",
         "version" : "2.0"
      }
   },
   "release_status" : "stable",
   "version" : "2.2"
}

',
    'Dist-Metadata-Test-MetaFile-2.2/META.yml' => '---
abstract: Fake dist for testing metadata determination
author:
- Randy Stauner <rwstauner@cpan.org>
dynamic_config: 0
generated_by: hand
license:
- perl_5
meta-spec:
  url: http://search.cpan.org/perldoc?CPAN::Meta::Spec
  version: \'2\'
name: Dist-Metadata-Test-MetaFile
no_index:
  directory:
  - corpus
  - examples
  - inc
  - share
  - t
  - xt
provides:
  Dist::Metadata::Test::MetaFile:
    file: lib/Dist/Metadata/Test/MetaFile.pm
    version: \'2.05\'
  Dist::Metadata::Test::MetaFile::PM:
    file: lib/Dist/Metadata/Test/MetaFile/PM.pm
    version: \'2.04\'
release_status: stable
version: \'2.2\'
',
    'Dist-Metadata-Test-MetaFile-2.2/lib/Dist/Metadata/Test/MetaFile.pm' => 'package Dist::Metadata::Test::MetaFile;
# ABSTRACT: Fake dist for testing metadata determination

# does not match META file but we trust the META file
our $VERSION = \'1.5\';
',
    'Dist-Metadata-Test-MetaFile-2.2/lib/Dist/Metadata/Test/MetaFile/PM.pm' => 'package Dist::Metadata::Test::MetaFile::PM;
# ABSTRACT: Just a file to be indexed

our $VERSION = \'1.1\';
',
    'Dist-Metadata-Test-MetaFile-2.2/README' => 'This "dist" is for testing Dist::Metadata.
'
  },
  'subdir' => {
    'Dist-Metadata-Test-SubDir-1.5/README' => 'This "dist" is for testing Dist::Metadata.
',
    'Dist-Metadata-Test-SubDir-1.5/lib/Dist/Metadata/Test/SubDir.pm' => 'package Dist::Metadata::Test::SubDir;
# ABSTRACT: Fake dist for testing metadata determination

our $VERSION = \'1.1\';
',
    'Dist-Metadata-Test-SubDir-1.5/lib/Dist/Metadata/Test/SubDir/PM.pm' => 'package Dist::Metadata::Test::SubDir::PM;
# ABSTRACT: Just a file to be indexed

our $VERSION = \'1.0\';
'
  },
  'metafile_incomplete' => {
    'Dist-Metadata-Test-MetaFile-Incomplete-2.1/META.yml' => '---
abstract: Fake dist for testing metadata determination
author:
- Randy Stauner <rwstauner@cpan.org>
dynamic_config: 0
generated_by: hand
license:
- perl_5
meta-spec:
  url: http://search.cpan.org/perldoc?CPAN::Meta::Spec
  version: \'2\'
name: Dist-Metadata-Test-MetaFile-Incomplete
no_index:
  directory:
  - examples
  - share
  - xt
provides: {}
release_status: stable
version: \'2.2\'
',
    'Dist-Metadata-Test-MetaFile-Incomplete-2.1/README' => 'This "dist" is for testing Dist::Metadata.
',
    'Dist-Metadata-Test-MetaFile-Incomplete-2.1/META.json' => '{
   "abstract" : "Fake dist for testing metadata determination",
   "author" : [
      "Randy Stauner <rwstauner@cpan.org>"
   ],
   "dynamic_config" : 0,
   "generated_by" : "hand",
   "license" : [
      "perl_5"
   ],
   "meta-spec" : {
      "url" : "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
      "version" : "2"
   },
   "name" : "Dist-Metadata-Test-MetaFile-Incomplete",
   "no_index" : {
      "directory" : [
         "examples",
         "share",
         "xt"
      ]
   },
   "provides" : {},
   "release_status" : "stable",
   "version" : "2.1"
}

',
    'Dist-Metadata-Test-MetaFile-Incomplete-2.1/lib/Dist/Metadata/Test/MetaFile/Incomplete.pm' => 'package Dist::Metadata::Test::MetaFile::Incomplete;
# ABSTRACT: Just a file to be indexed

our $VERSION = \'2.1\';
',
    'Dist-Metadata-Test-MetaFile-Incomplete-2.1/inc/NotThis.pm' => 'package NotThis;
# ABSTRACT: Not to be indexed
1;
',
    'Dist-Metadata-Test-MetaFile-Incomplete-2.1/t/lib/Never.pm' => 'package Never;
# ABSTRACT: Never index this

1;
'
  },
  'noroot' => {
    'lib/Dist/Metadata/Test/NoRoot/PM.pm' => 'package Dist::Metadata::Test::NoRoot::PM;
# ABSTRACT: Just a file to be indexed

our $VERSION = \'3.25\';
',
    'README' => 'This "dist" is for testing Dist::Metadata.
',
    'lib/Dist/Metadata/Test/NoRoot.pm' => 'package Dist::Metadata::Test::NoRoot;
# ABSTRACT: Fake dist for testing metadata determination

our $VERSION = \'3.3\';
'
  },
  'nometafile' => {
    'Dist-Metadata-Test-NoMetaFile-0.1/README' => 'This "dist" is for testing Dist::Metadata.
',
    'Dist-Metadata-Test-NoMetaFile-0.1/lib/Dist/Metadata/Test/NoMetaFile/PM.pm' => 'package Dist::Metadata::Test::NoMetaFile::PM;
# ABSTRACT: Just a file to be indexed

our $VERSION = \'0.1\';
',
    'Dist-Metadata-Test-NoMetaFile-0.1/lib/Dist/Metadata/Test/NoMetaFile.pm' => 'package Dist::Metadata::Test::NoMetaFile;
# ABSTRACT: Fake dist for testing metadata determination

our $VERSION = \'0.1\';
'
  },
  'nometafile_dev_release' => {
    'Dist-Metadata-Test-NoMetaFile-DevRelease-0.1_1/README' => 'This "dist" is for testing Dist::Metadata.
',
    'Dist-Metadata-Test-NoMetaFile-DevRelease-0.1_1/lib/Dist/Metadata/Test/NoMetaFile/DevRelease.pm' => 'package Dist::Metadata::Test::NoMetaFile::DevRelease;
# ABSTRACT: Fake dist for testing metadata determination

our $VERSION = \'0.1_1\';
'
  }
};
