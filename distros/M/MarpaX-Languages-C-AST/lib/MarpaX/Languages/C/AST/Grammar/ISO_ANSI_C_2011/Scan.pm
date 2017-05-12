use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::C::AST::Grammar::ISO_ANSI_C_2011::Scan;
use parent qw/MarpaX::Languages::C::Scan/;

# ABSTRACT: Scan C source

use MarpaX::Languages::C::AST;
use Config;
use Carp qw/croak/;
use Data::Dumper;
use Try::Tiny;
use IO::CaptureOutput qw/capture_exec/;
use File::Temp qw/tempfile/;
use IO::File;
use Scalar::Util qw/blessed reftype/;
use Regexp::Common;
use Log::Any qw/$log/;
use constant {
    LEXEME_POSITION_INDEX => 0,
    LEXEME_LENGTH_INDEX => 1,
    LEXEME_VALUE_INDEX => 2
};
use MarpaX::Languages::C::AST::Grammar::ISO_ANSI_C_2011::Scan::Actions;
use File::ShareDir qw/dist_dir/;
use File::Find qw/find/;
use File::Spec;
use File::Basename qw/basename/;
use Unicode::CaseFold;
use XML::LibXML;
use XML::LibXSLT;
use constant { TYPE => 0, QUALIFIER => 1, IDENTIFIER => 2, OTHER => 3, SKIPPED => 4, DECLARATOR => 5 };
our @type2String = qw/TYPE QUALIFIER IDENTIFIER OTHER SKIPPED DECLARATOR/;

our $RESAMELINE = qr/(?:[ \t\v\f])*/;                        # i.e. WS* without \n
our $REDEFINE = qr/^${RESAMELINE}#${RESAMELINE}define${RESAMELINE}((\w+)(?>[^\n\\]*)(?>\\.[^\n\\]*)*)/ms; # dot-matches-all mode, keeping ^ meaningful
our $BALANCEDPARENS = qr/$RE{balanced}{-parens=>'()'}{-keep}/;

our $VERSION = '0.47'; # VERSION


# ----------------------------------------------------------------------------------------

sub new {
  my ($class, %opts) = @_;

  if (exists($opts{filename}) && exists($opts{content})) {
    croak 'filename and content are mutually exclusive';
  }
  if (! exists($opts{filename}) && ! exists($opts{content})) {
    croak 'filename or content is required';
  }

  my %astConfig = %opts;
  foreach (qw/asDOM xpathDirectories xsltDirectories filename_filter enumType cpprun cppflags nocpp/) {
    delete($astConfig{$_});
  }
  my $self = {
              _asDOM            => exists($opts{asDOM})             ? $opts{asDOM}               : undef,
              _xpathDirectories => exists($opts{xpathDirectories})  ? $opts{xpathDirectories}    : [],
              _xsltDirectories  => exists($opts{xsltDirectories})   ? $opts{xsltDirectories}     : [],
              _filename_filter  => exists($opts{filename_filter}  ) ? $opts{filename_filter}     : undef,
              _enumType         => exists($opts{enumType})          ? $opts{enumType}            : 'int',
              _cpprun           => exists($opts{cpprun})            ? $opts{cpprun}              : ($ENV{MARPAX_LANGUAGES_C_SCAN_CPPRUN} || $Config{cpprun}),
              _cppflags         => exists($opts{cppflags})          ? $opts{cppflags}            : ($ENV{MARPAX_LANGUAGES_C_SCAN_CPPFLAGS} || $Config{cppflags}),
              _nocpp            => exists($opts{nocpp})             ? $opts{nocpp}               : 0,
              _astConfig        => \%astConfig,
             };

  #
  # For anonymous enums or structs, so that their names do not clash
  #
  $self->{_anonCount} = 0;

  if (exists($opts{content})) {
    if (! defined($opts{content})) {
      croak 'Undefined content';
    }
    $self->{_content2fh} = File::Temp->new(UNLINK => 1, SUFFIX => '.c');
    my $filename = $self->{_orig_filename} = $self->{_content2fh}->filename;
    #
    # We open twice the temporary file to make sure it is not deleted
    # physically on disk and still visible for our process
    #
    $self->{_tmpfh} = IO::File->new($filename, 'r') || croak "Cannot open $filename, $!";
    $self->{_content2fh}->print($opts{content});
    $self->{_content2fh}->close() || warn "Cannot close $self->{_content2fh}, $!";
    $self->{_content} = $opts{content};
  } else {
    if (! exists($opts{filename}) || ! defined($opts{filename})) {
      croak 'Undefined filename';
    }
    my $filename = $self->{_orig_filename} = $opts{filename};
    $self->{_tmpfh} = IO::File->new($filename, 'r') || croak "Cannot open $filename, $!";
  }

  if (defined($self->{_filename_filter})) {
      my $ref = reftype($self->{_filename_filter}) || '';
      if ($ref) {
          if ($ref ne 'REGEXP') {
              croak 'filename_filter must be a scalar or a regular expression';
          } else {
              #
              # For efficiency, instead of doing ref() or reftype() all the time, we will do exists()
              #
              $self->{_filename_filter_re} = $self->{_filename_filter};
          }
      }
  }

  bless($self, $class);

  $self->_init();

  #
  # We always produce the ast, and do heuristic processing, to liberate the temporary files.
  #
  $log->debugf('Producing AST');
  $self->_ast();
  $log->debugf('Doing heuristic analysis');
  $self->_analyse_with_heuristics();
  $log->debugf('Post-processing heuristics');
  $self->_posprocess_heuristics();
  #
  # This will unlink temporary file
  #
  delete($self->{_tmpfh});
  delete($self->{_content2fh});
  #
  # Delete what is left
  #
  # delete($self->{_content});
  delete($self->{_anonCount});

  return $self;
}

# ----------------------------------------------------------------------------------------


sub ast {
  my $self = shift;

  return $self->{_ast};
}

# ----------------------------------------------------------------------------------------


sub astToString {
  my $self = shift;

  return $self->{_asDOM} ? $self->ast()->toString(1) : Dumper($self->ast());
}

# ----------------------------------------------------------------------------------------


sub content {
  my $self = shift;

  return $self->{_content};
}

# ----------------------------------------------------------------------------------------


sub get {
  my ($self, $attribute) = @_;

  if ($attribute eq 'get' ||
      $attribute eq 'new') {
    croak "$attribute attribute is not supported";
  }

  return $self->$attribute;
}

# ----------------------------------------------------------------------------------------


sub includes {
  my ($self) = @_;

  return $self->{_includes};
}

# ----------------------------------------------------------------------------------------


sub defines_args {
  my ($self) = @_;

  return $self->{_defines_args};
}

# ----------------------------------------------------------------------------------------


sub defines_no_args {
  my ($self) = @_;

  return $self->{_defines_no_args};
}

# ----------------------------------------------------------------------------------------


sub strings {
  my ($self) = @_;

  return $self->{_strings};
}

# ----------------------------------------------------------------------------------------


sub macros {
  my ($self) = @_;

  return $self->{_macros};
}

# ----------------------------------------------------------------------------------------


sub fdecls {
  my ($self) = @_;

  if (! defined($self->{_fdecls})) {
    $self->_fdecls();
  }

  return $self->{_fdecls};
}

# ----------------------------------------------------------------------------------------


sub inlines {
  my ($self) = @_;

  if (! defined($self->{_inlines})) {
    $self->_inlines();
  }

  return $self->{_inlines};
}

# ----------------------------------------------------------------------------------------


sub parsed_fdecls {
  my ($self) = @_;

  if (! defined($self->{_parsed_fdecls})) {
    $self->_parsed_fdecls();
  }

  return $self->{_parsed_fdecls};
}

# ----------------------------------------------------------------------------------------


sub typedef_hash {
  my ($self) = @_;

  if (! defined($self->{_typedef_hash})) {
    $self->_typedef_hash();
  }

  return $self->{_typedef_hash};
}

# ----------------------------------------------------------------------------------------


sub typedef_texts {
  my ($self) = @_;

  if (! defined($self->{_typedef_texts})) {
    $self->_typedef_texts();
  }

  return $self->{_typedef_texts};
}

# ----------------------------------------------------------------------------------------


sub typedefs_maybe {
  my ($self) = @_;

  if (! defined($self->{_typedefs_maybe})) {
    $self->_typedefs_maybe();
  }

  return $self->{_typedefs_maybe};
}

# ----------------------------------------------------------------------------------------


sub vdecls {
  my ($self) = @_;

  if (! defined($self->{_vdecls})) {
    $self->_vdecls();
  }

  return $self->{_vdecls};
}

# ----------------------------------------------------------------------------------------


sub vdecl_hash {
  my ($self) = @_;

  if (! defined($self->{_vdecl_hash})) {
    $self->_vdecl_hash();
  }

  return $self->{_vdecl_hash};
}

# ----------------------------------------------------------------------------------------


sub typedef_structs {
  my ($self) = @_;

  if (! defined($self->{_typedef_structs})) {
    $self->_typedef_structs();
  }

  return $self->{_typedef_structs};
}

# ----------------------------------------------------------------------------------------


sub topDeclarations {
  my ($self) = @_;

  if ($self->{_asDOM} && ! defined($self->{_topDeclarations})) {
    $self->_topDeclarations();
  }

  return $self->{_topDeclarations};
}

# ----------------------------------------------------------------------------------------


sub cdecl {
  my ($self) = @_;

  if ($self->{_asDOM} && ! defined($self->{_cdecl})) {
    $self->_cdecl();
  }

  return $self->{_cdecl};
}


# ----------------------------------------------------------------------------------------

sub _init {
    my ($self) = @_;

    my $stdout_buf;

    if (! $self->{_nocpp}) {
      #
      # Note that, because we do not know if cpprun or cppflags contain multiple things
      # we cannot use the array version of run(). So ye have to stringify ourself.
      # It is assumed (and is the case with %Config value), that cpprun and cppflags
      # will be already properly escaped.
      # Remains the filename that we do ourself.
      # Two big categories: Win32, others
      #
      my $cmd = "$self->{_cpprun} $self->{_cppflags} $self->{_orig_filename}";

      my ($stdout, $stderr, $success, $exitCode );
      my $executed = 0;
      my $errorString = undef;
      try {
        ($stdout, $stderr, $success, $exitCode) = capture_exec($cmd);
      } catch {
        $errorString = $_;
        return;
      } finally {
        if (! $@) {
          $executed = 1;
        }
      };

      if (! $executed) {
        if (defined($errorString)) {
          croak "$cmd: $errorString";
        } else {
          croak "$cmd: failure (no error available)";
        }
      }

      $stdout_buf = $stdout;
    } else {
      $log->debugf('Disabling cpp step');
      my $fh;
      open($fh, '<', $self->{_orig_filename}) || croak "Cannot open $self->{_orig_filename}";
      $stdout_buf = do {local $/; <$fh>;};
      close($fh) || $log->warnf('Cannot close %s, %s', $self->{_orig_filename}, $!);
    }

    $self->{_stdout_buf} = $stdout_buf;
    $self->{_position2File} = {};
    $self->{_sortedPosition2File} = [];

}

# ----------------------------------------------------------------------------------------

sub _ast {
  my ($self) = @_;

  #
  # Temporary stuff
  #
  my %tmpHash = (_currentFile => undef, _includes => {});
  #
  # Get the AST, the lexeme callback will flag position2File to things of interest
  #
  $self->{_includes} = $self->{_asDOM} ? XML::LibXML::Document->new() : {};
  $self->{_strings} = $self->{_asDOM} ? XML::LibXML::Document->new() : [];
  #
  # Plus from our module: strings detection
  #
  my $value = MarpaX::Languages::C::AST->new
      (
       lexemeCallback => [ \&_lexemeCallback,
                           {self => $self,
                            tmpHashp => \%tmpHash,
                           }
       ],
       actionObject => sprintf('%s::%s', __PACKAGE__, 'Actions'),
       nonTerminalSemantic => ':default ::= action => nonTerminalSemantic',
       %{$self->{_astConfig}},
      )->parse(\$self->{_stdout_buf})->value;
  $self->{_ast} = ${$value};

  #
  # For lookup, do a sorted version of position2File
  #
  $self->{_sortedPosition2File}  = [ map { [ $_, $self->{_position2File}->{$_} ] } sort { $a <=> $b } keys %{$self->{_position2File}} ];
  #
  # Includes was a hash in %tmpHash
  #
  if ($self->{_asDOM}) {
    foreach (sort keys %{$tmpHash{_includes}}) {
      my $child = XML::LibXML::Element->new('include');
      $self->{_includes}->addChild(XML::LibXML::Element->new('include'))->setAttribute('text', $_);
    }
  } else {
    $self->{_includes} = [ sort keys %{$tmpHash{_includes}} ];
  }

  if ($self->{_asDOM}) {
    #
    # We want to systematically provide a "text" attribute on all nodes
    #
    foreach ($self->ast()->findnodes($self->_xpath('allNodes.xpath'))) {
      #
      # In order to distringuish between a lexeme or not in the future, we remember
      # if there was originally a lexeme -;
      #
      my $text = $_->getAttribute('text');
      my $isLexeme = defined($text) ? 'true' : 'false';
      $_->setAttribute('isLexeme', $isLexeme);
      #
      # And file information, which is acting as a filter
      #
      $self->_pushNodeFile(undef, $_, 1);
      $self->_pushNodeString(undef, $_, 1);
    }
  }
}

# ----------------------------------------------------------------------------------------

sub _position2File {
  my ($self, $position) = @_;

  my $file = '';
  if (! exists($ENV{MARPAX_LANGUAGES_C_AST_T_SCAN})) {
    #
    # In the test suite, we cannot rely on filename that is compiler+OS dependant
    #
    foreach (@{$self->{_sortedPosition2File}}) {
      if ($_->[0] > $position) {
        last;
      }
      $file = $_->[1];
    }
  }

  return $file;
}

# ----------------------------------------------------------------------------------------

sub _xpath {
  my ($self, $wantedFilename) = @_;

  if (! defined($self->{_xpath}->{$wantedFilename})) {
    my $found = 0;
    my @searchPath = (@{$self->{_xpathDirectories}}, File::Spec->catdir(dist_dir('MarpaX-Languages-C-AST'), 'xpath'));
    foreach (@searchPath) {
      #
      # The fact that filesystem could be case tolerant is not an issue here
      #
      my $filename = File::Spec->canonpath(File::Spec->catfile($_, $wantedFilename));
      $log->tracef('%s: trying with %s', $wantedFilename, $filename);
      {
        use filetest 'access';
        if (-r $filename) {
          my $fh;
          if (! open($fh, '<', $filename)) {
            #
            # This should not happen
            #
            $log->warnf('Cannot open %s, %s', $filename, $!);
          } else {
            my $xpath = do {local $/; <$fh>};
            if (! close($fh)) {
              $log->warnf('Cannot close %s, %s', $filename, $!);
            }
            #
            # Remove any blank outside of the xpath expression
            #
            $xpath =~ s/^\s*//;
            $xpath =~ s/\s*$//;
            $self->{_xpath}->{$wantedFilename} = eval {XML::LibXML::XPathExpression->new($xpath)};
            if ($@) {
              $log->warnf('Cannot evaluate xpath in %s, %s', $filename, $@);
              #
              # Make sure it is really undefined
              #
              $self->{_xpath}->{$wantedFilename} = undef;
            } else {
              #
              # Done
              #
              $log->infof('%s evaluated using %s', $wantedFilename, $filename);
              $found = 1;
              last;
            }
          }
        }
      }
    }
    if (! $found) {
      croak "Cannot find or evaluate \"$wantedFilename\". Search path was: [" . join(', ', map {"\"$_\""} (@searchPath)) . ']';
    }
  }
  return $self->{_xpath}->{$wantedFilename};
}

# ----------------------------------------------------------------------------------------


sub xslt {
  my ($self, $wantedFilename) = @_;

  if (! defined($self->{_xslt}->{$wantedFilename})) {
    my $found = 0;
    my @searchPath = (@{$self->{_xsltDirectories}}, File::Spec->catdir(dist_dir('MarpaX-Languages-C-AST'), 'xslt'));
    foreach (@searchPath) {
      #
      # The fact that filesystem could be case tolerant is not an issue here
      #
      my $filename = File::Spec->canonpath(File::Spec->catfile($_, $wantedFilename));
      $log->tracef('%s: trying with %s', $wantedFilename, $filename);
      {
        use filetest 'access';
        if (-r $filename) {
          $self->{_xslt}->{$wantedFilename} = eval {XML::LibXSLT->new()->parse_stylesheet_file($filename)};
          if ($@) {
            $log->warnf('Cannot evaluate xslt in %s, %s', $filename, $@);
            #
            # Make sure it is really undefined
            #
            $self->{_xslt}->{$wantedFilename} = undef;
          } else {
            #
            # Done
            #
            $log->infof('%s evaluated using %s', $wantedFilename, $filename);
            $found = 1;
            last;
          }
        }
      }
    }
    if (! $found) {
      croak "Cannot find or evaluate \"$wantedFilename\". Search path was: [" . join(', ', map {"\"$_\""} (@searchPath)) . ']';
    }
  }
  return $self->{_xslt}->{$wantedFilename};
}

# ----------------------------------------------------------------------------------------

sub _pushNodeString {
  my ($self, $outputp, $node, $setAttributes) = @_;

  $setAttributes //= 0;

  #
  # Unless the node is already a lexeme, we have to search surrounding lexemes
  # This routine assumes that $outputp is always a reference to either an array or a scalar
  #
  my $text = $node->getAttribute('text');
  if (defined($text)) {
    #
    # Per def text, start and length attributes already exist
    #
    if (defined($outputp)) {
      if (ref($outputp) eq 'ARRAY') {
        push(@{$outputp}, $text);
      } elsif (ref($outputp) eq 'SCALAR') {
        ${$outputp} = $text;
      } else {
        croak "Expecting a reference to an array or a scalar, not a reference to " . (ref($outputp) || 'nothing');
      }
    }
    return $text;
  } else {
    #
    ## Get first and last lexemes positions
    #
    my $firstLexemeXpath = $self->_xpath('firstLexeme.xpath');
    my $lastLexemeXpath = $self->_xpath('lastLexeme.xpath');

    my $firstLexeme = $node->findnodes($firstLexemeXpath);
    my $lastLexeme = $node->findnodes($lastLexemeXpath);

    if ($firstLexeme && $lastLexeme) {
      my $startPosition = $firstLexeme->[0]->findvalue('./@start');
      my $endPosition = $lastLexeme->[0]->findvalue('./@start') + $lastLexeme->[0]->findvalue('./@length');
      my $length = $endPosition - $startPosition;
      my $text = substr($self->{_stdout_buf}, $startPosition, $length);
      if (defined($outputp)) {
        if (ref($outputp) eq 'ARRAY') {
          push(@{$outputp}, $text);
        } elsif (ref($outputp) eq 'SCALAR') {
          ${$outputp} = $text;
        } else {
          croak "Expecting a reference to an array or a scalar, not a reference to " . (ref($outputp) || 'nothing');
        }
      }
      if ($setAttributes) {
        $node->setAttribute('start', $startPosition);
        $node->setAttribute('length', $length);
        $node->setAttribute('text', $text);
      }
      return $text;
    } else {
      return;
    }
  }
}

# ----------------------------------------------------------------------------------------


sub fileOk {
  my ($self, $file) = @_;

  my $rc = 0;
  my ($volume, $directories, $filename) = File::Spec->splitpath($file);

  if (exists($self->{_filename_filter_re})) {
    if (File::Spec->case_tolerant($volume)) {
      $rc = ($file =~ /$self->{_filename_filter_re}/i) ? 1 : 0;
    } else {
      $rc = ($file =~ $self->{_filename_filter_re}) ? 1 : 0;
    }
  } elsif (defined($self->{_filename_filter})) {
    #
    # fc() crashed for me if $file is of zero length
    #
    if (length($file) <= 0) {
      $rc = (length($self->{_filename_filter}) <= 0) ? 1 : 0;
    } else {
      if (File::Spec->case_tolerant($volume)) {
        $rc = (fc($file) eq fc($self->{_filename_filter})) ? 1 : 0;
      } else {
        $rc = ($file eq $self->{_filename_filter}) ? 1 : 0;
      }
    }
  } else {
    $rc = 1;
  }

  return $rc;
}

# ----------------------------------------------------------------------------------------

sub _pushNodeFile {
  my ($self, $outputp, $node, $setAttribute) = @_;

  $setAttribute //= 0;

  #
  # Unless the node is already a lexeme, we have to search surrounding lexemes
  # This routine assumes that $outputp is always a reference to either an array or a scalar
  #
  # Get first lexeme position and return a false value only if filename filter is on and output does not match the filter
  #
  my $firstLexeme;
  if ($node->getAttribute('text')) {
    $firstLexeme = [$node];
  } else {
    my $firstLexemeXpath = $self->_xpath('firstLexeme.xpath');
    $firstLexeme = $node->findnodes($firstLexemeXpath);
  }
  my $file = '';

  if ($firstLexeme) {
    my $startPosition = $firstLexeme->[0]->findvalue('./@start');
    $file = $self->_position2File($startPosition);
  }

  if (defined($outputp)) {
    if (ref($outputp) eq 'ARRAY') {
      push(@{$outputp}, $file);
    } elsif (ref($outputp) eq 'SCALAR') {
      ${$outputp} = $file;
    } else {
      croak "Expecting a reference to an array or a scalar, not a reference to " . (ref($outputp) || 'nothing');
    }
  }

  if ($setAttribute) {
    $node->setAttribute('file', $file);
  }

  return $self->fileOk($file);
}

# ----------------------------------------------------------------------------------------

sub _fdecls {
  my ($self) = @_;

  if (! defined($self->{_fdecls})) {
    #
    # We rely on parsed_fdecls
    #
    $self->parsed_fdecls();
  }

  return $self->{_fdecls};
}

# ----------------------------------------------------------------------------------------

sub _typedef_texts {
  my ($self) = @_;

  if (! defined($self->{_typedef_texts})) {
    #
    # We rely on typedef_hash
    #
    $self->typedef_hash();
  }

  return $self->{_typedef_texts};
}

# ----------------------------------------------------------------------------------------

sub _typedefs_maybe {
  my ($self) = @_;

  if (! defined($self->{_typedefs_maybe})) {
    #
    # We rely on typedef_hash
    #
    $self->typedef_hash();
  }

  return $self->{_typedefs_maybe};
}

# ----------------------------------------------------------------------------------------

sub _typedef_structs {
  my ($self) = @_;

  if (! defined($self->{_typedef_structs})) {
    #
    # We rely on typedef_hash
    #
    $self->typedef_hash();
  }

  return $self->{_typedef_structs};
}

# ----------------------------------------------------------------------------------------

sub _vdecls {
  my ($self) = @_;

  if (! defined($self->{_vdecls})) {
    #
    # We rely on vdecl_hash
    #
    $self->vdecl_hash();
  }

  return $self->{_vdecls};
}

# ----------------------------------------------------------------------------------------

sub _removeWord {
  my ($self, $outputp, $toRemove) = @_;

  my $quotemeta = quotemeta($toRemove);
  ${$outputp} =~ s/^\s*$quotemeta\b\s*//;
  ${$outputp} =~ s/\s*\b$quotemeta\s*$//;
  ${$outputp} =~ s/\s*\b$quotemeta\b\s*/ /;
}

# ----------------------------------------------------------------------------------------

sub _vdecl_hash {
  my ($self) = @_;

  if (! defined($self->{_vdecl_hash})) {
    $self->{_vdecl_hash} = $self->{_asDOM} ? XML::LibXML::Document->new() : {};
    $self->{_vdecls} = $self->{_asDOM} ? XML::LibXML::Document->new() : [];
    #
    # a vdecl is a "declaration" node
    #
    foreach my $declaration ($self->ast()->findnodes($self->_xpath('vdecl.xpath'))) {
      my $file = '';
      if (! $self->_pushNodeFile(\$file, $declaration)) {
        next;
      }
      #
      # Get first declarationSpecifiers
      #
      my @declarationSpecifiers = $declaration->findnodes($self->_xpath('firstDeclarationSpecifiers.xpath'));
      if (! @declarationSpecifiers) {
        #
        # Could be a static assert declaration
        #
        next;
      }
      my $vdecl = '';
      $self->_pushNodeString(\$vdecl, $declaration);
      #
      # vdecl_hash does not have the extern keyword.
      #
      my $textForHash;
      $self->_pushNodeString(\$textForHash, $declarationSpecifiers[0]);
      $self->_removeWord(\$textForHash, 'extern');

      if ($self->{_asDOM}) {
        my $child = XML::LibXML::Element->new('vdecl');
        $child->setAttribute('text', $vdecl);
        $child->setAttribute('file', $file);
        $self->{_vdecls}->addChild($child);
      } else {
        push(@{$self->{_vdecls}}, $vdecl);
      }
      #
      # variable name
      #
      my @declarator = $declaration->findnodes($self->_xpath('declaration2Declarator.xpath'));
      my @keys = ();
      my @before = ();
      my @after = ();
      foreach (@declarator) {
        my $declarator;
        $self->_pushNodeString(\$declarator, $_);

        my @IDENTIFIER = $_->findnodes($self->_xpath('declarator2IDENTIFIER.xpath'));
        if (@IDENTIFIER) {
          $self->_pushNodeString(\@keys, $IDENTIFIER[0]);
        } else {
          my $anon = sprintf('ANON%d', $self->{_anonCount}++);
          push(@keys, $anon);
        }
        $declarator =~ /(.*)$keys[-1](.*)/;
        my $before = defined($-[1]) ? substr($declarator, $-[1], $+[1]-$-[1]) : '';
        my $after = defined($-[2]) ? substr($declarator, $-[2], $+[2]-$-[2]) : '';
        push(@before, ($before =~ /[^\s]/) ? ' ' . $before : '');
        push(@after, ($after =~ /[^\s]/) ? ' ' . $after : '');
      }
      if (! @keys) {
        push(@keys, sprintf('ANON%d', $self->{_anonCount}++));
        push(@before, '');
        push(@after, '');
      }
      foreach (0..$#keys) {
        if ($self->{_asDOM}) {
          my $child = XML::LibXML::Element->new('vdecl');
          $child->setAttribute('before', $textForHash . $before[$_]);
          $child->setAttribute('after', $after[$_]);
          $child->setAttribute('id', $keys[$_]);
          $child->setAttribute('file', $file);
          $self->{_vdecl_hash}->addChild($child);
        } else {
          $self->{_vdecl_hash}->{$keys[$_]} = [ $textForHash . $before[$_], $after[$_] ];
        }
      }
    }
  }

  return $self->{_vdecl_hash};
}

# ----------------------------------------------------------------------------------------

sub _topDeclarations {
  my ($self) = @_;

  if ($self->{_asDOM} && ! defined($self->{_topDeclarations})) {
    $self->{_topDeclarations} = XML::LibXML::Document->new();
    my $declarationList = XML::LibXML::Element->new('declarationList');
    $self->{_topDeclarations}->addChild($declarationList);

    foreach ($self->ast()->findnodes($self->_xpath('topDeclarations.xpath'))) {
      my $declaration = $_;
      my $file;
      if (! $self->_pushNodeFile(\$file, $_)) {
        next;
      }
      $declarationList->addChild($declaration->cloneNode(1));
    }
  }
}

# ----------------------------------------------------------------------------------------

sub _addMissingIdentifiers {
  my ($self, $declaration) = @_;
  #
  # Our model do not mind if we do not respect exactly the AST. In fact, it requires an IDENTIFIER
  # or an IDENTIFIER_UNAMBIGUOUS (or ELLIPSIS exceptionnaly) to know when to "stop" when scanning nodes.
  # We insert fake identifiers wherever needed.
  #
  foreach ($declaration->findnodes($self->_xpath('missingIdentifier.xpath'))) {
    my $identifier = sprintf('__ANON%d', ++$self->{_cdeclAnonNb});
    my $newNode = XML::LibXML::Element->new('ANON_IDENTIFIER');
    $newNode->setAttribute('isLexeme', 'true');
    $newNode->setAttribute('text', $identifier);
    $newNode->setAttribute('start', -1);
    $newNode->setAttribute('length', length($identifier));
    if ($_->localname() eq 'SEMICOLON' || $_->localname() eq 'COLON') {
      $log->debugf('_addMissingIdentifiers: %s: faking identifier %s before: %s', $declaration->getAttribute('text'), $identifier, $_->getAttribute('text'));
      $_->parentNode->insertAfter($newNode, $_);
    } else {
      $log->debugf('_addMissingIdentifiers: %s: faking identifier %s after: %s', $declaration->getAttribute('text'), $identifier, $_->getAttribute('text'));
      $_->parentNode->insertAfter($newNode, $_);
    }
  }
}

# ----------------------------------------------------------------------------------------

sub _removeEmptyStructDeclaration {
  my ($self, $declaration) = @_;

  foreach ($declaration->findnodes($self->_xpath('emptyStructDeclaration.xpath'))) {
    my $SEMICOLON = $_;
    my $structDeclaration = $SEMICOLON->parentNode();
    my $structDeclarationList = $structDeclaration->parentNode();
    my $structOrUnionSpecifier = $structDeclarationList->parentNode();
    $log->debugf('[-]_removeEmptyStructDeclaration: %s: removing empty declaration: %s', $structOrUnionSpecifier->getAttribute('text'), $_->getAttribute('text'));
    $structDeclarationList->removeChild($structDeclaration);
    #
    # /If/ $structDeclarationList then have no child, remove it as well
    #
    if (! $structDeclarationList->childNodes()) {
      $log->infof('_removeEmptyStructDeclaration: %s: removing empty declaration list', $structOrUnionSpecifier->getAttribute('text'));
      #
      # We remove it and the surrounding curlies
      #
      my $LCURLY = $structDeclarationList->previousSibling();
      my $RCURLY = $structDeclarationList->nextSibling();
      $structOrUnionSpecifier->removeChild($LCURLY);
      $structOrUnionSpecifier->removeChild($structDeclarationList);
      $structOrUnionSpecifier->removeChild($RCURLY);
    }
  }
}

# ----------------------------------------------------------------------------------------

sub _recoverCommas {
  my ($self, $declaration) = @_;

  foreach ($declaration->findnodes($self->_xpath('missingComma.xpath'))) {
    my $i = 0;
    my $previousNode;
    foreach ($_->childNodes()) {
      if ($i > 0) {
        $log->debugf('_recoverCommas: %s: restoring comma lexeme after child No %d "%s"', $declaration->getAttribute('text'), $i - 1, $previousNode->getAttribute('text'));
        my $newNode = XML::LibXML::Element->new('COMMA');
        $newNode->setAttribute('isLexeme', 'true');
        $newNode->setAttribute('text', ',');
        $newNode->setAttribute('start', $previousNode->getAttribute('start') + $previousNode->getAttribute('length'));
        $newNode->setAttribute('length', $_->getAttribute('start') - $previousNode->getAttribute('start'));
        $previousNode->parentNode->insertAfter($newNode, $previousNode);
      }
      ++$i;
      $previousNode = $_;
    }
  }
}

# ----------------------------------------------------------------------------------------

sub _simplifyEnumerators {
  my ($self, $declaration) = @_;

  foreach ($declaration->findnodes($self->_xpath('enumerators.xpath'))) {
    my $i = 0;
    my $firstChild = $_->firstChild();
    my $EQUAL = $firstChild->nextSibling();
    if (defined($EQUAL)) {
      my $constantExpression = $EQUAL->nextSibling();
      $log->debugf('_simplifyEnumerators: %s: removing constant expression "%s %s"', $_->getAttribute('text'), $EQUAL->getAttribute('text'), $constantExpression->getAttribute('text'));
      $_->removeChild($EQUAL);
      $_->removeChild($constantExpression);
    }
  }
}

# ----------------------------------------------------------------------------------------

sub _simplifyInitDeclarators {
  my ($self, $declaration) = @_;

  foreach ($declaration->findnodes($self->_xpath('initDeclarators.xpath'))) {
    my $i = 0;
    my $firstChild = $_->firstChild();
    my $EQUAL = $firstChild->nextSibling();
    if (defined($EQUAL)) {
      my $initializer = $EQUAL->nextSibling();
      $log->debugf('_simplifyInitDeclarators: %s: removing initializer expression "%s %s"', $_->getAttribute('text'), $EQUAL->getAttribute('text'), $initializer->getAttribute('text'));
      $_->removeChild($EQUAL);
      $_->removeChild($initializer);
    }
  }
}

# ----------------------------------------------------------------------------------------

sub _cdecl {
  my ($self) = @_;

  if ($self->{_asDOM} && ! defined($self->{_cdecl})) {
    $self->{_cdeclAnonNb} = 0;
    $self->{_cdecl} = [];
    #
    # We will analyse topDeclarations
    #
    foreach ($self->topDeclarations()->firstChild()->childNodes()) {
      #
      # We change the DOM before processing it, so better to work on a clone
      #
      my $declaration = $_->cloneNode(1);
      #
      # We remove unsupported things
      #
      $self->_removeEmptyStructDeclaration($declaration);
      #
      # Recover COMMAs that Marpa's separator hided (and this is normal btw). Our DOM processing relies on the COMMA node.
      #
      $self->_recoverCommas($declaration);
      #
      # Enumerators are special: they have no declarator (ok) and can have an initialisation that
      # is irrelevant for us (and that would cause trouble in fact)
      #
      $self->_simplifyEnumerators($declaration);
      #
      # Ditto for the declarator initializers.
      #
      $self->_simplifyInitDeclarators($declaration);
      #
      # We rely on presence of identifiers : insert fake ones wherever needed
      #
      $self->_addMissingIdentifiers($declaration);
      #
      # Parse the declaration
      #
      my $callLevel = -1;
      push(@{$self->{_cdecl}}, $self->_topDeclaration2Cdecl($callLevel, $declaration));
    }
    delete($self->{_cdeclAnonNb});
  }
}

# ----------------------------------------------------------------------------------------

sub _topDeclaration2Cdecl {
  my ($self, $callLevel, $declaration) = @_;

  $self->_logCdecl('[>]' . (' ' x ++$callLevel) . '_topDeclaration2Cdecl');

  #
  # For every declaration we scan all the lexemes, aka nodes that have isLexeme equal to 'true'.
  # Other nodes are used to get the context.
  #
  my $allNodesXpath = $self->_xpath('allNodes.xpath');
  my @nodes = $declaration->findnodes($allNodesXpath);

  my $localCdecl = '';
  my @cdecl = ();
  my @stack = ();
  my @declSpecStack = ();

  my $i = 0;
  my $last = $self->_readToId($callLevel, \@nodes, \@stack, \$localCdecl, \@declSpecStack);
  do {
    #
    # Every declarator will share the stack up to first (eventually faked) identifier
    #
    if ($i++ > 0) {
      @stack = @declSpecStack;
      $last = $self->_readToId($callLevel, \@nodes, \@stack, \$localCdecl);
    }
    $last = $self->_parseDeclarator($callLevel, \@nodes, \@stack, \$localCdecl, $last);
    push(@cdecl, $localCdecl);
    $localCdecl = '';

  } while ($last->{node}->localname() eq 'COMMA');

  $self->_logCdecl('[<]' . (' ' x $callLevel--) . '_topDeclaration2Cdecl', cdecl => \@cdecl);

  return @cdecl;
}

sub _logCdecl {
  my ($self, $function, %h) = @_;

  #
  # Rework case of stack and declSpecStack
  #
  if (exists($h{stack}) && defined($h{stack})) {
    $h{stack} = [ map { $_->{string} } @{$h{stack}} ];
  }
  if (exists($h{declSpecStack}) && defined($h{declSpecStack})) {
    $h{declSpecStack} = [ map { $_->{string} } @{$h{declSpecStack}} ];
  }
  #
  # Rework case of last, next, or previous
  #
  foreach (qw/previous last next node/) {
    if (exists($h{$_})) {
      if (exists($h{$_}->{node}) && defined($h{$_}->{node})) {
        $h{$_} = {name => $h{$_}->{node}->localname(), isLexeme => $h{$_}->{node}->getAttribute('isLexeme'), text => $h{$_}->{node}->getAttribute('text'), text => $h{$_}->{node}->getAttribute('text'), type => defined($h{$_}->{type}) ? ($type2String[$h{$_}->{type}] || 'UNKNOWN') : undef};
      } else {
        $h{$_} = undef;
      }
    }
  }
  $log->debugf('%s: %s', $function, \%h);
}

sub _checkPtr {
  my ($self, $callLevel, $nodesp, $stackp, $cdeclp) = @_;

  $self->_logCdecl('[>]' . (' ' x ++$callLevel) . '_checkPtr', stack => $stackp, cdecl => $cdeclp);

  if (! @{$stackp}) {
    $self->_logCdecl('[<]' . (' ' x $callLevel--) . '_checkPtr', stack => $stackp, cdecl => $cdeclp);
    return;
  }

  my $t;
  for ($t = pop(@{$stackp});
       defined($t) && $t->{node}->localname() eq 'STAR';
       $t = pop(@{$stackp})) {
    ${$cdeclp} .= 'pointer to ';
  }
  if (defined($t)) {
    push(@{$stackp}, $t);
  }

  $self->_logCdecl('[<]' . (' ' x $callLevel--) . '_checkPtr', stack => $stackp, cdecl => $cdeclp);

}

sub _parseDeclarator {
  my ($self, $callLevel, $nodesp, $stackp, $cdeclp, $last) = @_;

  $self->_logCdecl('[>]' . (' ' x ++$callLevel) . '_parseDeclarator', stack => $stackp, cdecl => $cdeclp, last => $last);

  if ($last->{node}->localname() eq 'LBRACKET') {
    while ($last->{node}->localname() eq 'LBRACKET') {
      $last = $self->_readArraySize($callLevel, $nodesp, $cdeclp);
    }
  } elsif ($last->{node}->localname() eq 'LPAREN_SCOPE') {
    $last = $self->_readFunctionArgs($callLevel, $nodesp, $cdeclp);
  } elsif ($last->{node}->localname() eq 'LCURLY') {
    if ($last->{node}->parentNode()->localname() eq 'structOrUnionSpecifier') {
      $last = $self->_readStructDeclarationList($callLevel, $nodesp, $cdeclp);
    }
    elsif ($last->{node}->parentNode()->localname() eq 'enumSpecifier') {
      $last = $self->_readEnumeratorList($callLevel, $nodesp, $cdeclp);
    } else {
      croak 'Unsupported parent for LCURLY node: ' . $last->{node}->parentNode()->localname();
    }
  }
  $self->_checkPtr($callLevel, $nodesp, $stackp, $cdeclp);

  while (@{$stackp}) {
    my $t = pop(@{$stackp});
    if ($t->{node}->localname() eq 'LPAREN') {
      $last = $self->_getNode($callLevel, $nodesp, $cdeclp);
      $last = $self->_parseDeclarator($callLevel + 1, $nodesp, $stackp, $cdeclp, $last); # Recursively parse this ( dcl )
    } else {
      if ($t->{node}->localname() eq 'TYPEDEF') {
        ${$cdeclp}  = "Type definition of ${$cdeclp}";
      } else {
        ${$cdeclp} .= sprintf('%s ', $t->{string});
      }
    }
  }

  $self->_logCdecl('[<]' . (' ' x $callLevel--) . '_parseDeclarator', stack => $stackp, cdecl => $cdeclp, last => $last);

  return $last;
}

sub _readFunctionArgs {
  my ($self, $callLevel, $nodesp, $cdeclp) = @_;

  $self->_logCdecl('[>]' . (' ' x ++$callLevel) . '_readFunctionArgs', cdecl => $cdeclp);

  my $last = $self->_getNode($callLevel, $nodesp, $cdeclp);

  if ($last->{node}->localname() eq 'RPAREN_SCOPE') {
    ${$cdeclp} .= 'function returning ';
    $last = $self->_getNode($callLevel, $nodesp, $cdeclp);
    $self->_logCdecl('[<]' . (' ' x $callLevel--) . '_readFunctionArgs', cdecl => $cdeclp, last => $last);
    return $last;
  }

  #
  # Push back the node
  #
  unshift(@{$nodesp}, $last->{node});

  ${$cdeclp} .= 'function receiving ';

  my @stack = ();
  my $cdecl = '';
  do {
    #
    # Every argument has its own independant stack.
    #
    $last = $self->_readToId($callLevel, $nodesp, \@stack, \$cdecl);
    $last = $self->_parseDeclarator($callLevel, $nodesp, \@stack, \$cdecl, $last);

    if ($last->{node}->localname() eq 'COMMA') {
      $cdecl .= ', ';
    }
  } while ($last->{node}->localname() eq 'COMMA');

  ${$cdeclp} .= '(' . $cdecl . ') and returning ';

  $last = $self->_getNode($callLevel, $nodesp, $cdeclp);
  $self->_logCdecl('[<]' . (' ' x $callLevel--) . '_readFunctionArgs', cdecl => $cdeclp, last => $last);

  return $last;
}

sub _readStructDeclarationList {
  my ($self, $callLevel, $nodesp, $cdeclp) = @_;

  $self->_logCdecl('[>]' . (' ' x ++$callLevel) . '_readStructDeclarationList', cdecl => $cdeclp);

  ${$cdeclp} .= 'structure defined as ';

  my $localCdecl = '';
  my $last;

  do {
    my @stack = ();
    my @declSpecStack = ();

    $last = $self->_getNode($callLevel, $nodesp, \$localCdecl);
    #
    # Push back the node
    #
    unshift(@{$nodesp}, $last->{node});

    if ($last->{node}->localname() ne 'RCURLY') {
      my $i;
      $last = $self->_readToId($callLevel, $nodesp, \@stack, \$localCdecl, \@declSpecStack);

      do {
        #
        # Every declarator will share the stack up to first (eventually faked) identifier
        #
        if ($i++ > 0) {
          #
          # declarators piling up. Per def they share the same stack, and only the first
          # one gets the stack for all the others
          #
          @stack = @declSpecStack;
          $last = $self->_readToId($callLevel, $nodesp, \@stack, \$localCdecl);
        }
        $last = $self->_parseDeclarator($callLevel, $nodesp, \@stack, \$localCdecl, $last);

        if ($last->{node}->localname() eq 'COMMA') {
          $localCdecl .= ', ';
        }

      } while ($last->{node}->localname() eq 'COMMA');

      if ($last->{node}->localname() eq 'SEMICOLON') {
        $localCdecl .= '; ';
      }

    }

  } while ($last->{node}->localname() eq 'SEMICOLON');

  ${$cdeclp} .= '{' . $localCdecl . '}';

  $last = $self->_getNode($callLevel, $nodesp, $cdeclp);

  $self->_logCdecl('[<]' . (' ' x $callLevel--) . '_readStructDeclarationList', cdecl => $cdeclp, last => $last);

  return $last;
}

sub _readEnumeratorList {
  my ($self, $callLevel, $nodesp, $cdeclp) = @_;
  #
  # This is very similar to _readFunctionArgs()
  #
  $self->_logCdecl('[>]' . (' ' x ++$callLevel) . '_readEnumeratorList', cdecl => $cdeclp);
  #
  # Empty enumeratorList is not allowed. No need to pre-read the next node.
  #
  ${$cdeclp} .= 'enumeration defined as ';

  my @stack = ();
  my $cdecl = '';
  my $last;
  do {
    #
    # Every argument has its own stack (which contains only the identifier -;)
    #
    $last = $self->_readToId($callLevel, $nodesp, \@stack, \$cdecl);
    #
    # There is no declarator, really - we fake one.
    #
    $cdecl .= $self->{_enumType};

    if ($last->{node}->localname() eq 'COMMA') {
      $cdecl .= ', ';
    }

  } while ($last->{node}->localname() eq 'COMMA');

  ${$cdeclp} .= '{' . $cdecl . '} ';

  $self->_logCdecl('[<]' . (' ' x $callLevel--) . '_readEnumeratorList', cdecl => $cdeclp, last => $last);

  return $last;
}

sub _readArraySize {
  my ($self, $callLevel, $nodesp, $cdeclp) = @_;

  $self->_logCdecl('[>]' . (' ' x ++$callLevel) . '_readArraySize', cdecl => $cdeclp);

  #
  # Per def next node in the list is the one just after LBRACKET
  #
  my $last = $self->_getNode($callLevel, $nodesp, $cdeclp);
  my $start = $last->{node}->getAttribute('start');
  my $end = 0;

  while ($last->{node}->localname() ne 'RBRACKET') {
    $end = $last->{node}->getAttribute('start') + $last->{node}->getAttribute('length');
    $last = $self->_getNode($callLevel, $nodesp, $cdeclp);
  }
  my $size = '';
  if ($end > 0) {
    ${$cdeclp} .= sprintf('array[%s] of ', substr($self->{_stdout_buf}, $start, $end - $start));
  } else {
    ${$cdeclp} .= sprintf('array[] of ');
  }

  $last = $self->_getNode($callLevel, $nodesp, $cdeclp);

  $self->_logCdecl('[<]' . (' ' x $callLevel--) . '_readArraySize', cdecl => $cdeclp, last => $last);

  return $last;
}

sub _readToId {
  my ($self, $callLevel, $nodesp, $stackp, $cdeclp, $declSpecStackp) = @_;

  $self->_logCdecl('[>]' . (' ' x ++$callLevel) . '_readToId', stack => $stackp, cdecl => $cdeclp, declSpecStack => $declSpecStackp);

  my $last;

  #
  # _readToId() has a special mode when we want to distinguish the presence of declarator
  # inside the stack. This is needed in cases of:
  # * top level declarations
  # * structure declaration lists
  # because, in this case, multiple declarators can share the same declaration specifiers, e.g.:
  # float x,y
  #
  # This is not needed in case of enumeration lists, not function arguments, because in these later
  # cases, no identifier is sharing a declaration specifier stack, e.g.:
  # f(float x, float y)
  # f(float, float)
  # enum {A, B}
  #
  if (defined($declSpecStackp)) {
    for ($last = $self->_getNode($callLevel, $nodesp, $cdeclp, 1);

         $last->{type} != IDENTIFIER && $last->{type} != DECLARATOR;

         do {
           if ($last->{type} != DECLARATOR) {
             push(@{$stackp}, $last);
             $self->_logCdecl('[-]' . (' ' x $callLevel) . '_readToId: pushed to stack', stack => $stackp);
             push(@{$declSpecStackp}, $last);
             $self->_logCdecl('[-]' . (' ' x $callLevel) . '_readToId: pushed to declaration specifiers stack', declSpecStack => $declSpecStackp);
             $last = $self->_getNode($callLevel, $nodesp, $cdeclp, 1);
           }
         }) {}
  }
  if (! defined($declSpecStackp) || $last->{type} == DECLARATOR) {
    for ($last = $self->_getNode($callLevel, $nodesp, $cdeclp);

         $last->{type} != IDENTIFIER;

         push(@{$stackp}, $last),
         $self->_logCdecl('[-]' . (' ' x $callLevel) . '_readToId: pushed to stack', stack => $stackp),
         $last = $self->_getNode($callLevel, $nodesp, $cdeclp)) {}
  }

  #
  # Subtility with ELLIPSIS, per def there is no declaration at all
  #
  if ($last->{node}->localname() eq 'ELLIPSIS') {
    ${$cdeclp} .= sprintf('%s ', $last->{string});
  } else {
    ${$cdeclp} .= sprintf('%s: ', $last->{string});
  }

  $last = $self->_getNode($callLevel, $nodesp, $cdeclp);

  $self->_logCdecl('[<]' . (' ' x $callLevel--) .'_readToId', stack => $stackp, declSpecStack => $declSpecStackp, cdecl => $cdeclp, last => $last);

  return $last;
}

sub _classifyNode {
  my ($self, $callLevel, $node, $nodesp, $cdeclp, $detectDeclarator) = @_;

  $detectDeclarator //= 0;

  my $previous = $node->previousSibling();
  my $last = {node => $node,
              string => undef,
              type => undef};
  my $next = $node->nextSibling();

  $self->_logCdecl('[>]' . (' ' x ++$callLevel) . '_classifyNode', cdecl => $cdeclp, last => $last, detectDeclarator => $detectDeclarator);

  my $name = $node->localname();
  my $firstChild = $node->firstChild();
  my $isLexeme = $last->{node}->getAttribute('isLexeme') || 'false';

  if ($name eq 'CONST') { # We call const "read-only" to clarify
    $last->{string} = 'read-only';
  } elsif ($name eq 'ELLIPSIS') { # We call ... "etc."
    $last->{string} = 'etc.';
  } else {
    $last->{string} = $last->{node}->getAttribute('text');
  }

  my $parent = $last->{node}->parentNode();
  my $parentName = $parent->localname();

  if ($name eq 'declarator' && $detectDeclarator) {
    $last->{type} = DECLARATOR;
  }
  elsif ($name eq 'IDENTIFIER' || $name eq 'IDENTIFIER_UNAMBIGUOUS' || $name eq 'ANON_IDENTIFIER' || $name eq 'ELLIPSIS') {
    $last->{type} = IDENTIFIER;
  }
  elsif ($parentName eq 'typeQualifier') {
    $last->{type} = QUALIFIER;
  }
  #
  # Case of embedded definitions within declarations
  #
  elsif ($name eq 'structOrUnionSpecifier') {
    #
    # Remember that we guaranteed to have inserted a fake identifier if there is none, i.e.
    # the rule is:
    #
    # structOrUnionSpecifier
    # ::= structOrUnion ANON_IDENTIFIER LCURLY structDeclarationList RCURLY
    # | structOrUnion IDENTIFIER_UNAMBIGUOUS LCURLY structDeclarationList RCURLY
    # | structOrUnion IDENTIFIER_UNAMBIGUOUS
    #
    if (defined($firstChild->nextSibling()->nextSibling())) {
      #
      # The test on the third child is necessary because of recursive calls to this routine
      #
      my $structOrUnion = $firstChild;
      my $IDENTIFIER = $structOrUnion->nextSibling();
      my $LCURLY = $IDENTIFIER->nextSibling();
      my $structDeclarationList = $LCURLY->nextSibling();
      my $RCURLY = $structDeclarationList->nextSibling();
      #
      # Get a verbose string for this structure definition.
      # Even if _topDeclaration can return more than one value, per def for a
      # structOrUnionSpecifier it will return a single element.
      #
      $last->{string} = ($self->_topDeclaration2Cdecl($callLevel, $node->cloneNode(1)))[0];
      $node->setAttribute('text', $last->{string});
      #
      # Eat all nodes until /this/ RCURLY
      #
          my $startRcurly=$RCURLY->getAttribute('start');
          my $nextStart;
      do {
        my $nextNode = shift(@{$nodesp});
        $self->_logCdecl('[-]' . (' ' x $callLevel) . '_classifyNode: pass-through', node => {node => $nextNode});
                $nextStart = defined($nextNode) ? ($nextNode->getAttribute('start') || -1) : -1;
      } while ($nextStart != $startRcurly);
      #
      # We remove also children from LCURLY up to RCURLY
      #
      $node->removeChild($LCURLY);
      $node->removeChild($structDeclarationList);
      $node->removeChild($RCURLY);
    }
    #
    # Say that current node, a 'structOrUnionSpecifier' is a type (and it is)
    #
    $last->{type} = TYPE;
  }
  #
  # We do not want to the words 'struct' or 'union' to appear: full decl is in the return value of the embedded call to _topDeclaration2Cdecl() upper
  #
  elsif ($name eq 'STRUCT' || $name eq 'UNION') {
    $last->{type} = SKIPPED;
  }
  elsif ($name eq 'enumSpecifier') {
    #
    # Remember (bis) that we guaranteed to have inserted a fake identifier if there is none, i.e.
    # the rule is:
    #
    # enumSpecifier
    # ::= ENUM ANON_IDENTIFIER LCURLY enumeratorList RCURLY
    # | ENUM IDENTIFIER_UNAMBIGUOUS LCURLY enumeratorList RCURLY
    # | ENUM IDENTIFIER_UNAMBIGUOUS
    #
    if (defined($firstChild->nextSibling()->nextSibling())) {
      #
      # The test on the third child is necessary because of recursive calls to this routine
      #
      my $ENUM = $firstChild;
      my $IDENTIFIER = $ENUM->nextSibling();
      my $LCURLY = $IDENTIFIER->nextSibling();
      my $enumeratorList = $LCURLY->nextSibling();
      my $RCURLY = $enumeratorList->nextSibling();
      #
      # Get a verbose string for this enum definition
      # Even if _topDeclaration can return more than one value, per def for an
      # enumSpecifier it will return a single element.
      #
      $last->{string} = ($self->_topDeclaration2Cdecl($callLevel, $node->cloneNode(1)))[0];
      $node->setAttribute('text', $last->{string});
      #
      # Eat all nodes until /this/ RCURLY
      #
          my $startRcurly=$RCURLY->getAttribute('start');
          my $nextStart;
      do {
        my $nextNode = shift(@{$nodesp});
        $self->_logCdecl('[-]' . (' ' x $callLevel) . '_classifyNode: pass-through', node => {node => $nextNode});
                $nextStart = defined($nextNode) ? ($nextNode->getAttribute('start') || -1) : -1;
      } while ($nextStart != $startRcurly);
      #
      # We remove also children from LCURLY up to RCURLY
      #
      $node->removeChild($LCURLY);
      $node->removeChild($enumeratorList);
      $node->removeChild($RCURLY);
    }
    #
    # Say that current node, a 'enumSpecifier' is a type (and it is)
    #
    $last->{type} = TYPE;
  }
  #
  # We do not want to the word 'enum' to appear: full decl is in the return value of the embedded call to _topDeclaration2Cdecl() upper
  #
  elsif ($name eq 'ENUM') {
    $last->{type} = SKIPPED;
  }
  elsif ($parentName eq 'typeSpecifier1' ||
         $parentName eq 'typeSpecifier2' ||
         $parentName eq 'atomicTypeSpecifier' ||
         $parentName eq 'msvsBuiltinType' ||
         $parentName eq 'gccBuiltinType' ||
         $parentName eq 'gccTypeof') {
    $last->{type} = TYPE;
  }
  elsif ($isLexeme eq 'true') {
    $last->{type} = OTHER;
    if ($name eq 'STAR') {
      # Make string contain "pointer to", otherwise, qualified pointers would be printed as '*'
      $last->{string} = 'pointer to';
    }
  } else {
    $last->{type} = SKIPPED;
  }

  $self->_logCdecl('[<]' . (' ' x $callLevel--) . '_classifyNode', cdecl => $cdeclp, detectDeclarator => $detectDeclarator, last => $last);

  return $last;
}

sub _getNode {
  my ($self, $callLevel, $nodesp, $cdeclp, $detectDeclarator) = @_;

  $detectDeclarator //= 0;

  $self->_logCdecl('[>]' . (' ' x ++$callLevel) . '_getNode', cdecl => $cdeclp, detectDeclarator => $detectDeclarator);

  my $node;
  my $last;
  do {
    $node = shift(@{$nodesp});
    if (! defined($node)) {
      $self->_logCdecl('[<]' . (' ' x $callLevel--) . '_getNode', cdecl => $cdeclp, detectDeclarator => $detectDeclarator, last => undef);
      return;
    }
    $last = $self->_classifyNode($callLevel, $node, $nodesp, $cdeclp, $detectDeclarator);
  } while ($last->{type} == SKIPPED);

  $self->_logCdecl('[<]' . (' ' x $callLevel--) . '_getNode', cdecl => , $cdeclp, detectDeclarator => $detectDeclarator, last => $last, string => $last->{string});

  return $last;
}

# ----------------------------------------------------------------------------------------

sub _typedef_hash {
  my ($self) = @_;

  if (! defined($self->{_typedef_hash})) {
    $self->{_typedef_hash} = $self->{_asDOM} ? XML::LibXML::Document->new() : {};
    $self->{_typedef_texts} = $self->{_asDOM} ? XML::LibXML::Document->new() : [];
    $self->{_typedefs_maybe} = $self->{_asDOM} ? XML::LibXML::Document->new() : [];
    $self->{_typedef_structs} = $self->{_asDOM} ? XML::LibXML::Document->new() : {};
    #
    # typedef is a "declaration" node
    #
    foreach my $declaration ($self->ast()->findnodes($self->_xpath('typedef.xpath'))) {
      my $file;
      if (! $self->_pushNodeFile(\$file, $declaration)) {
        next;
      }

      my @declarationSpecifiers = $declaration->findnodes($self->_xpath('firstDeclarationSpecifiers.xpath'));
      if (! @declarationSpecifiers) {
        #
        # Could be a static assert declaration
        #
        next;
      }
      my $text;
      my $declarationSpecifiers;
      $self->_pushNodeString(\$text, $declaration);
      $self->_pushNodeString(\$declarationSpecifiers, $declarationSpecifiers[0]);
      #
      # typedef_texts does not have the typedef keyword, neither what will contain typedef_hash
      #
      $self->_removeWord(\$text, 'typedef');
      $self->_removeWord(\$declarationSpecifiers, 'typedef');
      if ($self->{_asDOM}) {
        my $child = XML::LibXML::Element->new('typedef');
        $child->setAttribute('text', $text);
        $child->setAttribute('file', $file);
        $self->{_typedef_texts}->addChild($child);
      } else {
        push(@{$self->{_typedef_texts}}, $text);
      }
      #
      # typedef name
      #
      my @declarator = $declaration->findnodes($self->_xpath('declaration2Declarator.xpath'));
      my @keys = ();
      my @before = ();
      my @after = ();
      foreach (@declarator) {
        my $declarator;
        $self->_pushNodeString(\$declarator, $_);

        my @IDENTIFIER = $_->findnodes($self->_xpath('declarator2IDENTIFIER.xpath'));
        $self->_pushNodeString(\@keys, $IDENTIFIER[0]);
        $declarator =~ /(.*)$keys[-1](.*)/;
        my $before = defined($-[1]) ? substr($declarator, $-[1], $+[1]-$-[1]) : '';
        my $after = defined($-[2]) ? substr($declarator, $-[2], $+[2]-$-[2]) : '';
        push(@before, ($before =~ /[^\s]/) ? ' ' . $before : '');
        push(@after, ($after =~ /[^\s]/) ? ' ' . $after : '');
      }
      if (! @keys) {
        push(@keys, sprintf('ANON%d', $self->{_anonCount}++));
        push(@before, '');
        push(@after, '');
      }
      if ($self->{_asDOM}) {
        foreach (@keys) {
          my $child = XML::LibXML::Element->new('typedef');
          $child->setAttribute('id', $_);
          $child->setAttribute('file', $file);
          $self->{_typedefs_maybe}->addChild($child);
        }
      } else {
        push(@{$self->{_typedefs_maybe}}, @keys);
      }
      foreach (0..$#keys) {
        #
        # typedef before/after
        #
        if ($self->{_asDOM}) {
          my $child = XML::LibXML::Element->new('typedef');
          $child->setAttribute('id', $keys[$_]);
          $child->setAttribute('before', $declarationSpecifiers . $before[$_]);
          $child->setAttribute('after', $after[$_]);
          $child->setAttribute('file', $file);
          $self->{_typedef_hash}->addChild($child);
        } else {
          $self->{_typedef_hash}->{$keys[$_]} = [ $declarationSpecifiers . $before[$_], $after[$_] ];
        }
      }
      #
      # Is a struct or union declaration ?
      #
      my @structOrUnionSpecifier = $declarationSpecifiers[0]->findnodes($self->_xpath('declarationSpecifiers2structOrUnionSpecifier.xpath'));
      if (@structOrUnionSpecifier) {
        my $struct = $self->{_asDOM} ? XML::LibXML::Document->new() : [];
        my $declsDOM = undef;

        my @structDeclaration = $structOrUnionSpecifier[0]->findnodes($self->_xpath('structOrUnionSpecifier2structDeclaration.xpath'));
        foreach (@structDeclaration) {

          my @specifierQualifierList = $_->findnodes($self->_xpath('structDeclaration2specifierQualifierList.xpath'));
          if (! @specifierQualifierList) {
            # Gcc extension
            next;
          }
          my $specifierQualifierList;
          $self->_pushNodeString(\$specifierQualifierList, $specifierQualifierList[0]);

          my @structDeclarator = $_->findnodes($self->_xpath('structDeclaration2structDeclarator.xpath'));
          my @keys = ();
          my @before = ();
          my @after = ();
          foreach (@structDeclarator) {
            my $structDeclarator;
            $self->_pushNodeString(\$structDeclarator, $_);

            my @IDENTIFIER = $_->findnodes($self->_xpath('structDeclarator2IDENTIFIER.xpath'));
            if (@IDENTIFIER) {
              $self->_pushNodeString(\@keys, $IDENTIFIER[0]);
            } else {
              # COLON constantExpression
              push(@keys, sprintf('ANON%d', $self->{_anonCount}++));
            }
            $structDeclarator =~ /(.*)$keys[-1](.*)/;

            my $before = defined($-[1]) ? substr($structDeclarator, $-[1], $+[1]-$-[1]) : '';
            my $after = defined($-[2]) ? substr($structDeclarator, $-[2], $+[2]-$-[2]) : '';
            push(@before, $specifierQualifierList . (($before =~ /[^\s]/) ? ' ' . $before : ''));
            push(@after, $after);
          }
          if (! @keys) {
            push(@keys, sprintf('ANON%d', $self->{_anonCount}++));
            push(@before, '');
            push(@after, '');
          }
          foreach (0..$#keys) {
            #
            # structDeclarator before/after
            #
            if ($self->{_asDOM}) {
              my $child = XML::LibXML::Element->new('decl');
              $child->setAttribute('id', $keys[$_]);
              $child->setAttribute('before', $before[$_]);
              $child->setAttribute('after', $after[$_]);
              $child->setAttribute('file', $file);
              if (! defined($declsDOM)) {
                $declsDOM = XML::LibXML::Element->new('decls');
                $struct->addChild($declsDOM);
              }
              $declsDOM->addChild($child);
            } else {
              push(@{$struct}, [ $before[$_], $after[$_], $keys[$_] ]);
            }
          }
        }
        foreach (0..$#keys) {
          #
          # typedef before/after
          #
          if ($self->{_asDOM}) {
            my $child = XML::LibXML::Element->new('struct');
            $child->setAttribute('id', $keys[$_]);
            $child->setAttribute('file', $file);
            $child->setAttribute('structOrUnion', 'true');
            $self->{_typedef_structs}->addChild($child);
            foreach ($struct->childNodes()) {
              my $newnode = $_->cloneNode(1);
              $child->addChild($newnode);
            }
          } else {
            $self->{_typedef_structs}->{$keys[$_]} = $struct;
          }
        }
      } else {
        foreach (0..$#keys) {
          #
          # Not a struct nor union
          #
          if ($self->{_asDOM}) {
            my $child = XML::LibXML::Element->new('struct');
            $child->setAttribute('id', $keys[$_]);
            $child->setAttribute('file', $file);
            $child->setAttribute('structOrUnion', 'false');
            $self->{_typedef_structs}->addChild($child);
          } else {
            $self->{_typedef_structs}->{$keys[$_]} = undef;
          }
        }
      }
    }
  }

  return $self->{_typedef_hash};
}

# ----------------------------------------------------------------------------------------

sub _parsed_fdecls {
  my ($self) = @_;

  if (! defined($self->{_parsed_fdecls})) {
    $self->{_parsed_fdecls} = $self->{_asDOM} ? XML::LibXML::Document->new() : [];
    $self->{_fdecls} = $self->{_asDOM} ? XML::LibXML::Element->new('fdecls') : [];

    foreach my $node ($self->ast()->findnodes($self->_xpath('fdecls.xpath'))) {
      my $file = '';
      if (! $self->_pushNodeFile(\$file, $node)) {
        next;
      }

      my $fdecl = [];
      #
      # rt
      #
      my @declarationSpecifiers = $node->findnodes($self->_xpath('firstDeclarationSpecifiers.xpath'));
      if (! @declarationSpecifiers) {
        #
        # Could be a static assert declaration
        #
        next;
      }
      $self->_pushNodeString($fdecl, $declarationSpecifiers[0]);
      #
      # Remove eventual typedef
      #
      $self->_removeWord(\$fdecl->[-1], 'typedef');
      #
      # nm. In case of a function declaration, there can be only a single declarator
      # in the declaration
      #
      my @declarator = $node->findnodes($self->_xpath('declaration2Declarator.xpath'));
      if (! @declarator) {
        my $anon = sprintf('ANON%d', $self->{_anonCount}++);
        push(@{$fdecl}, $anon);
      } else {
        my @IDENTIFIER = $declarator[0]->findnodes($self->_xpath('declarator2IDENTIFIER.xpath'));
        if (! @IDENTIFIER) {
          my $anon = sprintf('ANON%d', $self->{_anonCount}++);
          push(@{$fdecl}, $anon);
        } else {
          $self->_pushNodeString($fdecl, $IDENTIFIER[0]);
        }
      }
      #
      # args
      #
      my $args = $self->{_asDOM} ? XML::LibXML::Element->new('args') : [];
      my @args = $node->findnodes($self->_xpath('fdecl2args.xpath'));
      foreach (@args) {
        #
        # arg is a parameterDeclaration
        #
        my $arg = [];
        #
        # arg.rt
        #
        my @declarationSpecifiers = $_->findnodes($self->_xpath('firstDeclarationSpecifiers.xpath'));
        $self->_pushNodeString($arg, $declarationSpecifiers[0]);
        #
        # arg.nm or ANON
        #
        my $anon = undef;
        my @nm = $_->findnodes($self->_xpath('arg2nm.xpath'));
        if (@nm) {
          $self->_pushNodeString($arg, $nm[0]);
        } else {
          my $anon = sprintf('ANON%d', $self->{_anonCount}++);
          push(@{$arg}, $anon);
        }
        #
        # arg.arg is always undef
        #
        push(@{$arg}, undef);
        #
        # arg.ft
        #
        $self->_pushNodeString($arg, $_);
        if ($anon) {
          #
          # We faked an anonymous identifier
          #
          $arg->[-1] .= ' ' . $anon;
        }
        #
        # arg.mod
        #
        my @mod = $_->findnodes($self->_xpath('arg2mod.xpath'));
        if (@mod) {
          #
          # Per def $mod[0] is a directDeclarator that can be:
          #
          # directDeclarator LBRACKET RBRACKET
          # directDeclarator LBRACKET STAR RBRACKET
          # directDeclarator LBRACKET STATIC gccArrayTypeModifierList assignmentExpression RBRACKET
          # etc...
          #
          # We clone the node, remove the first child. What remains will be the array modifiers.
          #
          my $newnode = $mod[0]->cloneNode(1);
          my $childnode = $newnode->firstChild;
          $newnode->removeChild($childnode );
          $self->_pushNodeString($arg, $newnode);
        } else {
          push(@{$arg}, '');
        }
        if ($self->{_asDOM}) {
          my $child = XML::LibXML::Element->new('arg');
          $child->setAttribute('type', $arg->[0]);
          $child->setAttribute('id', $arg->[1]);
          #
          # Undef per construction, i.e. we do not put this attribute
          #
          # $child->setAttribute('args', $arg->[2]);
          $child->setAttribute('text', $arg->[3]);
          $child->setAttribute('mod', $arg->[4]);
          $args->addChild($child);
        } else {
          push(@{$args}, $arg);
        }
      }
      push(@{$fdecl}, $args);
      #
      # ft, without remaining semicolon
      #
      $self->_pushNodeString($fdecl, $node);
      $fdecl->[-1] =~ s/\s*;$//;
      #
      # mod is always undef
      #
      push(@{$fdecl}, undef);

      if ($self->{_asDOM}) {
        my $child = XML::LibXML::Element->new('fdecl');
        $child->setAttribute('type', $fdecl->[0]);
        $child->setAttribute('id', $fdecl->[1]);
        $child->addChild($fdecl->[2]);
        $child->setAttribute('text', $fdecl->[3]);
        $child->setAttribute('file', $file);
        #
        # Undef per construction: we do not include this attribute
        #
        # $child->setAttribute('mod', $fdecl->[4]);
        $self->{_parsed_fdecls}->addChild($child);
      } else {
        push(@{$self->{_parsed_fdecls}}, $fdecl);
      }

      if ($self->{_asDOM}) {
        my $child = XML::LibXML::Element->new('fdecl');
        $child->setAttribute('id', $fdecl->[1]);
        $child->setAttribute('text', $fdecl->[3]);
        $child->setAttribute('file', $file);
        $self->{_fdecls}->addChild($child);
      } else {
        push(@{$self->{_fdecls}}, $fdecl->[3]);
      }
    }
  }

  return $self->{_parsed_fdecls};
}

# ----------------------------------------------------------------------------------------

sub _inlines {
  my ($self) = @_;

  if (! defined($self->{_inlines})) {
    $self->{_inlines} = $self->{_asDOM} ? XML::LibXML::Document->new() : [];
    #
    # Simply, any path matching functionDefinition
    #
    foreach ($self->ast()->findnodes($self->_xpath('inlines.xpath'))) {
      my $file = '';
      if (! $self->_pushNodeFile(\$file, $_)) {
        next;
      }
      my $text = '';
      $self->_pushNodeString(\$text, $_);
      if ($self->{_asDOM}) {
        my $child = XML::LibXML::Element->new('inline');
        $child->setAttribute('text', $text);
        $child->setAttribute('file', $file);
        $self->{_inlines}->addChild($child);
      } else {
        push(@{$self->{_inlines}}, $text);
      }
    }
  }

  return $self->{_inlines};
}

# ----------------------------------------------------------------------------------------

sub _lexemeCallback {
  my ($lexemeCallbackHashp, $lexemeHashp) = @_;

  my $self = $lexemeCallbackHashp->{self};
  my $tmpHashp = $lexemeCallbackHashp->{tmpHashp};

  #
  # We wait until the first #line information: this will give the name of current file
  #
  if ($lexemeHashp->{name} eq 'PREPROCESSOR_LINE_DIRECTIVE') {
    if ($lexemeHashp->{value} =~ /([\d]+)\s*\"([^\"]+)\"/) {
        my $currentFile = File::Spec->canonpath(substr($lexemeHashp->{value}, $-[2], $+[2] - $-[2]));
        if (! defined($self->{_filename})) {
          #
          # The very first filename is always the original source.
          #
          $self->{_filename} = $currentFile;
        }

        $tmpHashp->{_currentFile} = $currentFile;
        $tmpHashp->{_includes}->{$currentFile} = 1;

        $self->{_position2File}->{$lexemeHashp->{start}} = $currentFile;

    }
    #
    # This is an internal lexeme, no problem to change a bit the value. For instance, remove
    # \s if any.
    #
    $lexemeHashp->{value} =~ s/^\s*//g;
    $lexemeHashp->{value} =~ s/\s*$//g;
    $lexemeHashp->{value} =~ s/\n/\\n/g;
  }

  if (defined($tmpHashp->{_currentFile}) && $self->fileOk($tmpHashp->{_currentFile})) {
    if ($lexemeHashp->{name} eq 'STRING_LITERAL_UNIT') {
      #
      # ISO C permits WS at the end of a string literal, we remove it
      #
      my $string = $lexemeHashp->{value};
      $string =~ s/[ \t\v\n\f]*$//;
      if ($self->{_asDOM}) {
        my $child = XML::LibXML::Element->new('string');
        $child->setAttribute('text', $string);
        $child->setAttribute('file', $tmpHashp->{_currentFile});
        $self->{_strings}->addChild($child)
      } else {
        push(@{$self->{_strings}}, $string);
      }
    }
  }
}

# ----------------------------------------------------------------------------------------

sub _analyse_with_heuristics {
  my ($self) = @_;

  if (! defined($self->{_content})) {
      #
      # Case where it was a filename given.
      # Per-def $self->{_tmpfh} is at the beginning of file at this time
      #
      $self->{_content} = do {my $fh = $self->{_tmpfh}; local $/; <$fh>;};
  }

  $self->{_macros} = $self->{_asDOM} ? XML::LibXML::Document->new() : [];
  pos($self->{_content}) = undef;
  while ($self->{_content} =~ m/$REDEFINE/g) {
    my $text = substr($self->{_content}, $-[1], $+[1] - $-[1]);
    my $id = substr($self->{_content}, $-[2], $+[2] - $-[2]);
    my $file = $self->_position2File($-[0]);
    if ($self->{_asDOM}) {
      my $child = XML::LibXML::Element->new('macro');
      $child->setAttribute('text', $text);
      $child->setAttribute('id', $id);
      $child->setAttribute('file', $file);
      $self->{_macros}->addChild($child);
    } else {
      push(@{$self->{_macros}}, [ $text, $id, $file ]);
    }
  }
}

# ----------------------------------------------------------------------------------------

sub _posprocess_heuristics {
  my ($self) = @_;

  #
  # We want to have defines_args and defines_no_args
  #
  $self->{_defines_args} = $self->{_asDOM} ? XML::LibXML::Document->new() : {};
  $self->{_defines_no_args} = $self->{_asDOM} ? XML::LibXML::Document->new() : {};
  foreach ($self->{_asDOM} ? $self->macros->childNodes() : @{$self->macros}) {
    my $text  = $self->{_asDOM} ? $_->getAttribute('text') : $_->[0];
    my $id    = $self->{_asDOM} ? $_->getAttribute('id')   : $_->[1];
    my $file  = $self->{_asDOM} ? $_->getAttribute('file') : $_->[2];
    if ($text =~ /^(\w+)\s*$BALANCEDPARENS\s*(.*)/s) {
      my $args  = substr($text, $-[2], $+[2] - $-[2]);
      my $value = substr($text, $-[3], $+[3] - $-[3]);
      substr($args,  0, 1, '');  # '('
      substr($args, -1, 1, '');  # ')'
      my @args = map {my $element = $_; $element =~ s/\s//g; $element;} split(/,/, $args);
      if ($self->{_asDOM}) {
        my $child = XML::LibXML::Element->new('define');
        $child->setAttribute('text', $text);
        $child->setAttribute('id', $id);
        $child->setAttribute('file', $file);
        $child->setAttribute('value', $value);

        my $subchild = XML::LibXML::Element->new('args');
        foreach (@args) {
          $subchild->addChild(XML::LibXML::Element->new('arg'))->setAttribute('id', $_);
        }
        $child->addChild($subchild);

        $self->{_defines_args}->addChild($child);
      } else {
        $self->{_defines_args}->{$id} = [ $text, [ @args ], $value, $file ];
      }
    } elsif ($text =~ /(\w+)\s*(.*)/s) {
      my $value = substr($text, $-[2], $+[2] - $-[2]);
      if ($self->{_asDOM}) {
        my $child = XML::LibXML::Element->new('define');
        $child->setAttribute('text', $text);
        $child->setAttribute('id', $id);
        $child->setAttribute('file', $file);
        $child->setAttribute('value', $value);
        $self->{_defines_no_args}->addChild($child);
      } else {
        $self->{_defines_no_args}->{$id} = [ $text, $value, $file ];
      }
    }
  }
}

# ----------------------------------------------------------------------------------------


sub c2cifce {
  my ($self, $lang, %params) = @_;

  $log->tracef('Calling transformation with parameters %s', \%params);

  my $ast = $self->ast();
  my $langXslt = $self->xslt($lang);
  my $transform = $langXslt->transform($ast, %params);

  return ($langXslt, $transform);
}

# ----------------------------------------------------------------------------------------


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::C::AST::Grammar::ISO_ANSI_C_2011::Scan - Scan C source

=head1 VERSION

version 0.47

=head1 SYNOPSIS

    use strict;
    use warnings FATAL => 'all';
    use MarpaX::Languages::C::Scan;
    use Config;
    use Data::Dumper;
    #
    # Parse C
    #
    my $filename = 'mysource.c';
    my %config = (cpprun => $Config{cpprun},
                  cppflags => $Config{cppflags});
    my $c = MarpaX::Languages::C::Scan->new(filename => $filename, %config);
    print Dumper($c->get('parsed_fdecls'));
    print Dumper($c->parsed_fdecls);

=head1 DESCRIPTION

This module scans a C source and exposes methods compatible with C::Scan module.

=head1 SUBROUTINES

=head2 new($class, %options)

Instantiate a new object. Parameters are in a hash that can contain the following keys:

=over

=item filename

File name to parse.

=item content

Content to parse.

=item filename_filter

Filter on filename from pre-processor output.

=item asDOM

Say that all C::Scan-like methods should return an xml document.

=item enumType

Type for enumerators. Default is 'int'.

=item xpathDirectories

A reference to an array giving xpath directories that will have precedence over the shared directory installed with this module.

=item xsltDirectories

A reference to an array giving xslt directories that will have precedence over the shared directory installed with this module.

=item cpprun

Preprocessor command, default is $ENV{MARPAX_LANGUAGES_C_SCAN_CPPRUN}, or $Config{cpprun}. It is assume that cpprun is already correctly quoted for your system shell.

=item cppflags

Preprocessor flags, default is $ENV{MARPAX_LANGUAGES_C_SCAN_CPPFLAGS}, $Config{cppflags}. It is assume that cppflags is already correctly quoted for your system shell.

=item nocpp

Disable preprocessor command. It is then up to the user to make that filename, or content, are suitable for the grammar. Eventually setting other MarpaX::Languages::C::AST->new() other options, like lazy mode and/or a list of typedef. Default is a false value.

=back

Any other option is passed as-is to MarpaX::Languages::C::AST->new() and will have precedence.

Please refer to the Config perl documentation for the meaning of $Config{cpprun} or $Config{cppflags}.

This module will execute "$cpprun $cppflags $filename", using a temporary filename if $content was given. Thus a working precompiler is required.

$filename and $content are mutually exclusive. If $content is used a temporary file will be created using File::Temp (which may fail under taint mode -;).

The $filename_filter value limits the output to file names equal to $filename_filter (if this is a SCALAR) or matching $filename_filter (if this is a Regexp): since we use the precompiler, any #include statements is "polluting" the original source, i.e. much more files that just $filename (or $content) are used. Default value is $filename or the generated temporary filename when using $content mode.

The methods defines_args() and defines_no_args() are not subject to the filename_filter parameter: they always apply on the content or filename given /before/ the preprocessing. They are based on heuristic parsing, so their result should not be blindly trusted. A typical example of false positive is a macro inside string or a comment.

This module will croak on any error.

=head1 METHODS

=head2 ast($self)

AST of the preprocessed output. This is an XML::LibXML document.

=head2 astToString($self)

Stringified AST of the preprocessed output. This is an XML::LibXML document passed through its toString(1) in DOM mode, a Data::Dumper output if non-DOM mode.

=head2 content($self)

Original content.

=head2 get($self, $attribute)

C::Scan like method, that is a proxy to $self->$attribute. All methods described after can be used as attribute, for example: $self->get('strings'), or $self->get('includes').

=head2 includes($self)

Returns a reference to a list of included files, sorted alphabetically. This is available JUST because preprocessors give the file that has been preprocessed in their output using a #line directive, and there is a special procedure in MarpaX::Languages::C::AST for that, on top of the ISO C grammar.

=head2 defines_args($self)

Returns a reference to hash of macros with arguments. The values are references to an array of length 2, the first element is a reference to the list of arguments, the second one being the expansion.

=head2 defines_no_args($self)

Returns a reference to hash of macros without arguments.

=head2 strings($self)

Returns a reference to a list of strings after preprocessing, regardless of scope level.

=head2 macros($self)

Returns a reference to a list of macros before preprocessing.

=head2 fdecls($self)

C::Scan compatible reference to a list of parsed declarations of functions.

=head2 inlines($self)

C::Scan compatible reference to a list of definitions of functions.

=head2 parsed_fdecls($self)

C::Scan NOT-FULLY compatible reference to list of parsed declarations of functions: the type of arguments consist only of type specifiers as per the grammar. For instance pointers are not in argument types: strictly speaking pointers are part of a declarator.

=head2 typedef_hash($self)

Reference to a hash which contains known typedefs as keys. Values of the hash are array references of length 2, with what should be put before/after the type for a standalone typedef declaration (but without the typedef substring). Note that it is the minimal full text of the C source that is used to obtain the before/after strings, so this /can/ contain definition of other variables.

=head2 typedef_texts($self)

Returns a reference to a list which contains known expansions of typedefs. This is just the first indice from "value" part of typedef_hash.

=head2 typedefs_maybe($self)

Returns a reference to a list of typedefed names. This is just the "key" part of typedef_hash. The name "maybe" is kept for compatibility with C::Scan.

=head2 vdecls($self)

Returns a reference to a list of extern variable declarations.

=head2 vdecl_hash($self)

Reference to a hash of parsed extern variable declarations, containing the variable names as keys. Values of the hash are array references of length 2, with what should be put before/after the name for a standalone extern variable declaration (but without the extern substring). Note that it is the minimal full text of the C source that is used to obtain the before/after strings, so this /can/ contain definition of other variables.

=head2 typedef_structs($self)

Hopefully C::Scan compatible reference to a hash which contains known typedefs as keys. The values of the hash may not be compatible with C::Scan output. In our case these are array references of length 2, with at index 0 the full text used to parsed this typedef (maybe inclusing more than needed, but always what is necessary), and at index 1 an empty string.

=head2 topDeclarations($self)

All top-level declarations. This is a XML::LibXML::Document containing a list of declaration children. Available only when asDOM option is a true value.

=head2 cdecl($self)

Cdecl-like string of top-level declarations. Available only when asDOM option is atrue value. Returns a reference to an array.

=head2 xslt($self, $wantedFilename)

Compiles an XSLT, searching $wantedFilename in the $self's xsltDirectories if given, then in the shared directory provided with this package. Returns an XML::LibXSLT object instance.

=head2 fileOk($self, $file)

Returns a true or false value if the $file argument matches the original filter. Default filter is the file being analysed.

=head2 c2cifce($self, $lang, %params)

Applies the transformation $lang, with parameters %params, and returns an array composed of the XML::LibXSLT instance and the transformed new XML::LibXML::Document.

=head1 NOTES

The default return type for functions without type specifier is fixed to 'int', as per the C standard.

=head1 SEE ALSO

L<Config>

L<MarpaX::Languages::C::AST>

L<C::Scan>

L<File:Temp>

L<C::Tokenize>

L<ModPerl::CScan>

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
