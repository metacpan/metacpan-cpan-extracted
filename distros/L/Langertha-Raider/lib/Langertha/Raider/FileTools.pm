package Langertha::Raider::FileTools;
our $VERSION = '0.504';
# ABSTRACT: MCP::Server factory with local filesystem tools (list/read/write/edit/multi_edit)

use strict;
use warnings;
use utf8;
use Cwd qw( realpath );
use Encode qw( decode encode FB_DEFAULT );
use JSON::MaybeXS qw( JSON );
use MIME::Base64 qw( encode_base64 );
use Path::Tiny;
use File::Which ();
use IPC::Run ();
use MCP::Server;
use Langertha::Raider::FileTools::ReadState;
use Langertha::Raider::PathConfine;

use Exporter 'import';
our @EXPORT_OK = qw( build_file_tools_server );


my $MAX_LINES       = 2000;
my $MAX_LINE_CHARS  = 2000;
my $MAX_READ_BYTES  = 256 * 1024;
my $MAX_IMAGE_BYTES = 3_932_160;          # 3.75 MB: 5 MB once in base64
my $MAX_PDF_BYTES   = 32 * 1024 * 1024;
my $MAX_READ_TOKENS = 25_000;             # Claude Code's limit on what one read returns
my $PDF_INLINE_PAGES = 10;                # a PDF with more pages is read by page range
my $PDF_MAX_PAGES    = 20;                # pages per request
my $STATE_NOTE      = ' (file state is current in your context — no need to Read it back)';

my %IMAGE_MIME = (
  png  => 'image/png',
  jpg  => 'image/jpeg',
  jpeg => 'image/jpeg',
  gif  => 'image/gif',
  webp => 'image/webp',
);

# Claude Code's list of extensions its Read refuses as binary (images and
# PDF are read another way).
my %BINARY_EXT = map { $_ => 1 } qw(
  bmp ico tiff tif heic heif avif mp4 mov avi mkv webm wmv flv m4v mpeg mpg mp3 wav ogg flac
  aac m4a wma aiff opus zip tar gz bz2 7z rar xz z tgz iso zst lz4 whl exe dll so dylib bin o a
  obj lib app msi deb rpm dmg apk doc docx docm dotx dotm xls xlsx xlsm xlsb xltx xltm ppt pptx
  pptm ppsx ppsm potx potm odt ods odp numbers epub ttf otf woff woff2 eot pyc pyo class jar war
  ear node wasm rlib sqlite sqlite3 db mdb idx parquet feather npy npz pickle psd ai eps sketch
  fig xd blend 3ds max swf fla lockb dat data
);

sub build_file_tools_server {
  my %args = @_;
  my $root = defined $args{root} ? path($args{root})->absolute : undef;
  my $root_realpath = $root ? realpath($root) : undef;
  die "Root does not exist: $root\n" if $root && !defined $root_realpath;
  my $real_root = $root ? path($root_realpath)->absolute : undef;
  my $confinement = Langertha::Raider::PathConfine->new(
    root        => $real_root ? "$real_root" : undef,
    extra_roots => $args{extra_roots} // [],
    confine     => exists $args{confine} ? $args{confine} : 1,
  );
  my $flag = sub {
    my ($v) = @_;
    return sub { ref $v eq 'CODE' ? ( $v->() ? 1 : 0 ) : ( $v ? 1 : 0 ) };
  };
  my $sees_images = $flag->( exists $args{sees_images} ? $args{sees_images} : 1 );
  my $reads_pdf   = $flag->( exists $args{reads_pdf}   ? $args{reads_pdf}   : 1 );
  my $state = $args{read_state} // Langertha::Raider::FileTools::ReadState->new;
  my $cwd = $real_root ? "$real_root" : path('.')->absolute->stringify;

  my $assert_in_root = sub {
    my ($p) = @_;
    die "Path escapes root: $p\n" unless $confinement->allows("$p");
    return;
  };

  my $nearest_existing = sub {
    my ($p) = @_;
    my $cur = $p;
    while (!-e $cur) {
      my $parent = $cur->parent;
      die "No existing parent for $p\n" if "$parent" eq "$cur";
      $cur = $parent;
    }
    return $cur;
  };

  my $resolve = sub {
    my ($path) = @_;
    my $p = path($path);
    if ($root) {
      $p = $p->is_absolute ? $p : $root->child($path);
      $p = $p->absolute;
      my $existing = $nearest_existing->($p);
      my $existing_realpath = realpath($existing)
        or die "Cannot resolve path: $existing\n";
      my $real_existing = path($existing_realpath)->absolute;
      $assert_in_root->($real_existing);
      if (-e $p) {
        my $p_realpath = realpath($p)
          or die "Cannot resolve path: $p\n";
        my $real_p = path($p_realpath)->absolute;
        $assert_in_root->($real_p);
        $p = $real_p;
      }
    }
    elsif (-e $p) {
      my $p_realpath = realpath($p);
      $p = path($p_realpath)->absolute if defined $p_realpath;
    }
    return $p->absolute;
  };

  my $resolve_for_write = sub {
    my ($path) = @_;
    my $p = $resolve->($path);
    return $p if -e $p;
    my $parent = $p->parent;
    my $existing = $nearest_existing->($parent);
    my $existing_realpath = realpath($existing)
      or die "Cannot resolve path: $existing\n";
    my $real_existing = path($existing_realpath)->absolute;
    $assert_in_root->($real_existing);
    return $p;
  };

  # A validation error, as Claude Code frames one.
  my $refuse = sub { my ( $tool, $text ) = @_; $tool->text_result('<tool_use_error>'.$text.'</tool_use_error>', 1) };
  my $failed = sub { my ( $tool, $text ) = @_; $tool->text_result($text, 1) };

  my $missing_text = sub {
    my ($p) = @_;
    my $text = 'File does not exist. Note: your current working directory is '.$cwd.'.';
    my $similar = _similar_file($p);
    $text .= ' Did you mean '.$similar.'?' if defined $similar;
    return $text;
  };

  # What a write leaves behind: the real path, noted as read whole.
  my $wrote = sub {
    my ( $p, $bytes ) = @_;
    my $real = realpath("$p") // "$p";
    $state->record( $real, bytes => $bytes );
    return;
  };

  my $server = MCP::Server->new(name => 'raider-files', version => '1.0');

  $server->tool(
    name         => 'list_files',
    description  => 'List the entries of a directory, one per line; directories end with "/".',
    input_schema => {
      type       => 'object',
      properties => { path => { type => 'string', description => 'Directory path, absolute or relative to the project root' } },
      required   => ['path'],
    },
    code => sub {
      my ($tool, $in) = @_;
      my $p = eval { $resolve->($in->{path}) };
      return $tool->text_result("Error: $@", 1) if $@;
      return $failed->($tool, 'Directory does not exist. Note: your current working directory is '.$cwd.'.')
        unless -e $p;
      return $failed->($tool, $p.' is a file, not a directory. Use read_file to read it.') unless -d $p;
      my @entries = sort map { -d $_ ? $_->basename . '/' : $_->basename } $p->children;
      return $tool->text_result(join("\n", @entries));
    },
  );

  $server->tool(
    name         => 'read_file',
    description  => join( "\n",
      'Reads a file from the local filesystem.',
      '- `path` is absolute or relative to the project root.',
      '- Reads up to '.$MAX_LINES.' lines by default; `offset` (the 1-based line to start at) and `limit` (the number of lines) read a part. When you already know which part of the file you need, only read that part.',
      '- Results are returned using cat -n format, with line numbers starting at 1: the line number, a tab, then the line as it is in the file. Lines longer than '.$MAX_LINE_CHARS.' characters are truncated.',
      '- Reads images (PNG, JPG, GIF, WebP) and PDFs when the model can see them, and Jupyter notebooks (.ipynb) as cells with outputs.',
      '- A PDF of more than '.$PDF_INLINE_PAGES.' pages must be read by page range with `pages` (e.g. "1-5"), at most '.$PDF_MAX_PAGES.' pages per request; those pages come back as text (needs pdftotext from poppler-utils).',
      '- A read that returns more than '.$MAX_READ_TOKENS.' tokens is refused; read a part with `offset` and `limit`.',
      '- Reading a directory, a missing file, or an empty file returns an error or system reminder rather than content.',
    ),
    input_schema => {
      type       => 'object',
      properties => {
        path   => { type => 'string',  description => 'The path of the file to read, absolute or relative to the project root' },
        offset => { type => 'integer', description => 'The line number to start reading from. Only provide if the file is too large to read at once' },
        limit  => { type => 'integer', description => 'The number of lines to read. Only provide if the file is too large to read at once.' },
        pages  => { type => 'string',  description => 'Page range for PDF files (e.g., "1-5", "3", "10-20"). Only applicable to PDF files. Maximum '.$PDF_MAX_PAGES.' pages per request.' },
      },
      required => ['path'],
    },
    code => sub {
      my ($tool, $in) = @_;
      my $p = eval { $resolve->($in->{path}) };
      return $tool->text_result("Error: $@", 1) if $@;
      return $failed->($tool, $missing_text->($p)) unless -e $p;
      return $failed->($tool, "EISDIR: illegal operation on a directory, read '".$p."'") if -d $p;
      return $refuse->($tool, "Cannot read '".$p."': this device file would block or produce infinite output.")
        unless -f $p;
      my $ext = $p->basename =~ /\.([^.\/]+)\z/ ? lc $1 : '';
      return _read_image( $tool, $p, $ext, $state, $sees_images, $refuse ) if $IMAGE_MIME{$ext};
      return _read_pdf( $tool, $p, $state, $reads_pdf, $refuse, $in ) if $ext eq 'pdf';
      return $refuse->($tool, _binary_text($ext)) if $BINARY_EXT{$ext};
      return _read_notebook( $tool, $p, $state, $sees_images, $failed ) if $ext eq 'ipynb';

      my $whole = !defined $in->{offset} && !defined $in->{limit};
      my $size  = -s $p;
      return $failed->($tool, 'File content ('._size_text($size).') exceeds maximum allowed size ('
        ._size_text($MAX_READ_BYTES).'). Use offset and limit parameters to read specific portions of the file, '
        .'or search for specific content instead of reading the whole file.')
        if $whole && $size > $MAX_READ_BYTES;
      my $bytes = eval { $p->slurp_raw };
      return $tool->text_result("Error reading $p: $@", 1) if $@;
      return $refuse->($tool, _binary_text($ext)) if index( substr( $bytes, 0, 8192 ), "\0" ) >= 0;
      return _read_text( $tool, $p, $bytes, $in, $state );
    },
  );

  $server->tool(
    name         => 'write_file',
    description  => join( "\n",
      'Writes a file to the local filesystem, creating parent directories.',
      '- This tool will overwrite the existing file if there is one at the provided path.',
      '- An existing file must have been read with read_file first; writing it fails otherwise.',
      '- Prefer edit_file for modifying existing files -- it only sends the diff. Only use this tool to create new files or for complete rewrites.',
    ),
    input_schema => {
      type       => 'object',
      properties => {
        path    => { type => 'string', description => 'The path of the file to write, absolute or relative to the project root' },
        content => { type => 'string', description => 'The content to write to the file' },
      },
      required => ['path', 'content'],
    },
    code => sub {
      my ($tool, $in) = @_;
      my $p = eval { $resolve_for_write->($in->{path}) };
      return $tool->text_result("Error: $@", 1) if $@;
      return $refuse->($tool, $p.' is a directory, not a file. To create a file inside it, include the file name in path.')
        if -d $p;
      return $refuse->($tool, $p.' exists but is not a regular file (a device, FIFO or socket). '
        .'Write only creates or overwrites regular files.') if -e $p && !-f $p;
      my $existed = -e $p ? 1 : 0;
      if ( my $problem = $existed ? $state->write_problem("$p") : undef ) {
        return $refuse->($tool, $problem);
      }
      my $bytes = encode( 'UTF-8', $in->{content} // '' );
      eval {
        $p->parent->mkpath unless -d $p->parent;
        $p->spew_raw($bytes);
      };
      return $tool->text_result("Error writing $p: $@", 1) if $@;
      $wrote->( $p, $bytes );
      return $tool->text_result( $existed
        ? 'The file '.$p.' has been updated successfully.'.$STATE_NOTE
        : 'File created successfully at: '.$p.$STATE_NOTE );
    },
  );

  # One edit on the content in memory: the new content, or an error text.
  my $apply = sub {
    my ( $content, $old, $new, $all ) = @_;
    return ( undef, 'No changes to make: old_string and new_string are exactly the same.' ) if $old eq $new;
    my $count = () = $content =~ /\Q$old\E/g;
    return ( undef, "String to replace not found in file.\nString: ".$old ) if $count == 0;
    return ( undef, 'Found '.$count.' matches of the string to replace, but replace_all is false. To replace all '
      .'occurrences, set replace_all to true. To replace only one occurrence, please provide more context to '
      ."uniquely identify the instance.\nString: ".$old ) if $count > 1 && !$all;
    if ($all) { $content =~ s/\Q$old\E/$new/g } else { $content =~ s/\Q$old\E/$new/ }
    return ( $content, undef );
  };

  # The file an edit works on: ( $p, $content, $created ) or ( undef, $result ).
  my $edit_target = sub {
    my ( $tool, $path, $first_old ) = @_;
    my $p = eval { $resolve_for_write->($path) };
    return ( undef, $tool->text_result("Error: $@", 1) ) if $@;
    return ( undef, $failed->($tool, "EISDIR: illegal operation on a directory, read '".$p."'") ) if -d $p;
    unless ( -e $p ) {
      return ( $p, '', 1 ) if $first_old eq '';
      return ( undef, $refuse->($tool, $missing_text->($p)) );
    }
    return ( undef, $refuse->($tool, "Cannot read '".$p."': this device file would block or produce infinite output.") )
      unless -f $p;
    my $raw = eval { $p->slurp_raw };
    return ( undef, $tool->text_result("Error reading $p: $@", 1) ) if $@;
    my $content = decode( 'UTF-8', $raw, FB_DEFAULT );
    if ( $first_old eq '' ) {
      return ( undef, $refuse->($tool, 'Cannot create new file - file already exists.') ) if $content =~ /\S/;
      return ( $p, $content, 0 );
    }
    if ( my $problem = $state->write_problem("$p") ) {
      return ( undef, $refuse->($tool, $problem) );
    }
    return ( $p, $content, 0 );
  };

  my $write_edit = sub {
    my ( $tool, $p, $content ) = @_;
    my $bytes = encode( 'UTF-8', $content );
    eval {
      $p->parent->mkpath unless -d $p->parent;
      $p->spew_raw($bytes);
    };
    return $tool->text_result("Error writing $p: $@", 1) if $@;
    $wrote->( $p, $bytes );
    return;
  };

  $server->tool(
    name         => 'edit_file',
    description  => join( "\n",
      'Performs exact string replacements in files.',
      '- The file must have been read with read_file first; editing it fails otherwise.',
      '- When editing text from read_file output, preserve the exact indentation (tabs/spaces) as it appears AFTER the line number prefix (the line number and a tab). Never include any part of the line number prefix in old_string or new_string.',
      '- The edit will FAIL if old_string is not unique in the file. Either provide a larger string with more surrounding context to make it unique or use replace_all to change every instance of old_string.',
      '- Use replace_all for replacing and renaming strings across the file.',
      '- An empty old_string creates a new file with new_string as its content.',
    ),
    input_schema => {
      type       => 'object',
      properties => {
        path        => { type => 'string',  description => 'The path of the file to modify, absolute or relative to the project root' },
        old_string  => { type => 'string',  description => 'The text to replace' },
        new_string  => { type => 'string',  description => 'The text to replace it with (must be different from old_string)' },
        replace_all => { type => 'boolean', description => 'Replace all occurrences of old_string (default false)' },
      },
      required => ['path', 'old_string', 'new_string'],
    },
    code => sub {
      my ($tool, $in) = @_;
      my ( $old, $new ) = ( $in->{old_string} // '', $in->{new_string} // '' );
      return $refuse->($tool, 'No changes to make: old_string and new_string are exactly the same.') if $old eq $new;
      my ( $p, $content, $created ) = $edit_target->( $tool, $in->{path}, $old );
      return $content unless defined $p;
      if ( $old eq '' ) {
        $content = $new;
      }
      else {
        my ( $changed, $error ) = $apply->( $content, $old, $new, $in->{replace_all} );
        return $refuse->($tool, $error) if defined $error;
        $content = $changed;
      }
      if ( my $error = $write_edit->( $tool, $p, $content ) ) { return $error }
      return $tool->text_result( $in->{replace_all} && $old ne ''
        ? 'The file '.$p.' has been updated. All occurrences were successfully replaced.'.$STATE_NOTE
        : 'The file '.$p.' has been updated successfully.'.$STATE_NOTE );
    },
  );

  $server->tool(
    name         => 'multi_edit',
    description  => join( "\n",
      'Makes several edits to one file in one call, like edit_file applied once per edit.',
      '- The edits are applied in the order given, each to the result of the one before.',
      '- Atomic: if any edit fails, none is applied and the file is unchanged.',
      '- The file must have been read with read_file first; editing it fails otherwise.',
      '- Every edit follows the rules of edit_file: old_string must match exactly (unique unless replace_all) and differ from new_string.',
      '- An empty old_string in the first edit creates a new file.',
    ),
    input_schema => {
      type       => 'object',
      properties => {
        path  => { type => 'string', description => 'The path of the file to modify, absolute or relative to the project root' },
        edits => {
          type        => 'array',
          minItems    => 1,
          description => 'The edits to make, applied one after the other',
          items       => {
            type       => 'object',
            properties => {
              old_string  => { type => 'string',  description => 'The text to replace' },
              new_string  => { type => 'string',  description => 'The text to replace it with' },
              replace_all => { type => 'boolean', description => 'Replace all occurrences of old_string (default false)' },
            },
            required => ['old_string', 'new_string'],
          },
        },
      },
      required => ['path', 'edits'],
    },
    code => sub {
      my ($tool, $in) = @_;
      my $edits = $in->{edits};
      return $refuse->($tool, 'edits must be a non-empty list of { old_string, new_string, replace_all }.')
        unless ref $edits eq 'ARRAY' && @$edits;
      my $n = @$edits;
      for my $i ( 1 .. $n ) {
        my $e = $edits->[ $i - 1 ];
        return $refuse->($tool, 'Edit '.$i.' of '.$n.' failed, no edit was applied: it needs old_string and new_string.')
          unless ref $e eq 'HASH' && defined $e->{old_string} && !ref $e->{old_string}
            && defined $e->{new_string} && !ref $e->{new_string};
      }
      my ( $p, $content, $created ) = $edit_target->( $tool, $in->{path}, $edits->[0]{old_string} );
      return $content unless defined $p;
      my $original = $content;
      for my $i ( 1 .. $n ) {
        my $e = $edits->[ $i - 1 ];
        my $fail = sub { $refuse->($tool, 'Edit '.$i.' of '.$n.' failed, no edit was applied: '.$_[0]) };
        if ( $e->{old_string} eq '' ) {
          return $fail->('Cannot create new file - file already exists.') if $i > 1 || $content =~ /\S/;
          return $fail->('No changes to make: old_string and new_string are exactly the same.') if $e->{new_string} eq '';
          $content = $e->{new_string};
          next;
        }
        my ( $changed, $error ) = $apply->( $content, $e->{old_string}, $e->{new_string}, $e->{replace_all} );
        return $fail->($error) if defined $error;
        $content = $changed;
      }
      return $refuse->($tool, 'Original and edited file match exactly. Failed to apply edit.')
        if !$created && $content eq $original;
      if ( my $error = $write_edit->( $tool, $p, $content ) ) { return $error }
      my $short = sub { length $_[0] > 50 ? substr( $_[0], 0, 50 ).'...' : $_[0] };
      return $tool->text_result( 'Applied '.$n.' edit'.( $n == 1 ? '' : 's' ).' to '.$p.":\n"
        .join( "\n", map {
          $_.'. Replaced "'.$short->( $edits->[ $_ - 1 ]{old_string} ).'" with "'.$short->( $edits->[ $_ - 1 ]{new_string} ).'"'
        } 1 .. $n ).$STATE_NOTE );
    },
  );

  return $server;
}

#### Reading

# A file name in the same directory with the same stem and another
# extension, for "Did you mean ...?".
sub _similar_file {
  my ( $p ) = @_;
  my $dir = $p->parent;
  return unless -d $dir;
  ( my $stem = $p->basename ) =~ s/\.[^.]*\z//;
  return unless length $stem;
  my ( $hit ) = sort grep { $_ ne $p->basename && /\A\Q$stem\E\.[^.\/]+\z/ } map { $_->basename } grep { -f $_ } $dir->children;
  return defined $hit ? $dir->child($hit)->stringify : undef;
}

sub _binary_text {
  my ( $ext ) = @_;
  return 'This tool cannot read binary files. The file appears to be a binary '
    .( length $ext ? '.'.$ext.' file' : 'file' )
    .'. Use a skill for this file type if one is available, or a shell command or script that can read the format.';
}

# Bytes as Claude Code writes a size: 512 bytes, 256KB, 399.6KB, 1.2MB.
sub _size_text {
  my ( $n ) = @_;
  return $n.' bytes' if $n < 1024;
  for my $unit (qw( KB MB GB )) {
    $n /= 1024;
    if ( $n < 1024 || $unit eq 'GB' ) {
      ( my $t = sprintf '%.1f', $n ) =~ s/\.0\z//;
      return $t.$unit;
    }
  }
}

sub _read_text {
  my ( $tool, $p, $bytes, $in, $state ) = @_;
  my $content = decode( 'UTF-8', $bytes, FB_DEFAULT );
  if ( $content eq '' ) {
    $state->record( "$p", bytes => $bytes );
    return $tool->text_result('<system-reminder>Warning: the file exists but the contents are empty.</system-reminder>');
  }
  my @lines = split /\n/, $content, -1;
  my $total = @lines;
  my $start = defined $in->{offset} && $in->{offset} =~ /\A\d+\z/ && $in->{offset} > 1 ? int $in->{offset} : 1;
  my $asked = defined $in->{limit} && $in->{limit} =~ /\A\d+\z/ && $in->{limit} > 0 ? int $in->{limit} : undef;
  my $limit = $asked // $MAX_LINES;
  if ( $start > $total ) {
    $state->record( "$p", partial => 1 );
    return $tool->text_result('<system-reminder>Warning: the file exists but is shorter than the provided offset ('
      .$start.'). The file has '.$total.' lines.</system-reminder>');
  }
  my $end = $start + $limit - 1;
  $end = $total if $end > $total;
  my @out;
  for my $n ( $start .. $end ) {
    my $line = $lines[ $n - 1 ];
    $line =~ s/\r\z//;
    $line = substr( $line, 0, $MAX_LINE_CHARS ).'... [truncated]' if length $line > $MAX_LINE_CHARS;
    push @out, $n."\t".$line;
  }
  my $text = join "\n", @out;
  if ( my $tokens = _tokens_over($text) ) {
    return $tool->text_result('File content ('.$tokens.' tokens) exceeds maximum allowed tokens ('.$MAX_READ_TOKENS
      .'). Use offset and limit parameters to read specific portions of the file, or search for specific content instead of reading the whole file.', 1);
  }
  my $cut = !defined $asked && $end < $total;
  $text .= "\n\n[Truncated: PARTIAL view — ".$p.': showing lines '.$start.'-'.$end.' of '.$total.' total. Call read_file with offset='
    .( $end + 1 ).' limit='.$MAX_LINES.' for the next page, or grep to find a specific section. Do NOT answer from this page alone if the answer may be further in the file.]'
    if $cut;
  my $partial = $start > 1 || defined $asked || $cut;
  $state->record( "$p", $partial ? ( partial => 1 ) : ( bytes => $bytes ) );
  return $tool->text_result($text);
}

sub _sees_text {
  my ( $what, $p ) = @_;
  return 'This model cannot see '.$what.': '.$p.' was not read. Use a model that can read images, '
    .'or a shell command or script that can describe or convert the file.';
}

sub _read_image {
  my ( $tool, $p, $ext, $state, $sees_images, $refuse ) = @_;
  return $refuse->($tool, _sees_text( 'images', $p )) unless $sees_images->();
  my $size = -s $p;
  return $refuse->($tool, 'Image file ('._size_text($size).') exceeds maximum allowed size ('._size_text($MAX_IMAGE_BYTES)
    .'). Use a shell command or script to make it smaller first.') if $size > $MAX_IMAGE_BYTES;
  my $bytes = eval { $p->slurp_raw };
  return $tool->text_result("Error reading $p: $@", 1) if $@;
  $state->record( "$p", partial => 1 );
  return {
    content => [ { type => 'image', data => encode_base64( $bytes, '' ), mimeType => $IMAGE_MIME{$ext} } ],
    isError => JSON->false,
  };
}

# The size in tokens of a text when it is over the limit of one read, else 0.
# A token is about four bytes, as Claude Code counts them without a tokenizer.
sub _tokens_over {
  my ( $text ) = @_;
  my $tokens = int( ( length( encode( 'UTF-8', $text ) ) + 3 ) / 4 );
  return $tokens > $MAX_READ_TOKENS ? $tokens : 0;
}

# The number of pages of a PDF from pdfinfo (poppler), or undef.
sub _pdf_page_count {
  my ( $p ) = @_;
  my $pdfinfo = File::Which::which('pdfinfo') or return;
  my ( $out, $err );
  eval { IPC::Run::run( [ $pdfinfo, "$p" ], \undef, \$out, \$err ) } or return;
  return $out =~ /^Pages:\s+(\d+)/m ? int $1 : undef;
}

my $BAD_PAGES = 'Invalid pages parameter: "%s". Use formats like "1-5", "3", or "10-20". Pages are 1-indexed.';

# A page range "N", "N-M" or "N-" as ( first, last ), last undef when open,
# or ( undef, undef, error text ).
sub _pdf_range {
  my ( $pages ) = @_;
  my ( $first, $dash, $last ) = $pages =~ /\A\s*(\d+)\s*(?:(-)\s*(\d*))?\s*\z/
    or return ( undef, undef, sprintf $BAD_PAGES, $pages );
  $last = $dash ? ( length $last ? int $last : undef ) : int $first;
  $first = int $first;
  return ( undef, undef, sprintf $BAD_PAGES, $pages ) if $first < 1 || ( defined $last && $last < $first );
  return ( $first, $last );
}

# Some pages of a PDF as text through pdftotext (poppler); this works for a
# model that cannot see PDFs, too.
sub _read_pdf_pages {
  my ( $tool, $p, $pages, $state, $refuse ) = @_;
  my ( $first, $last, $error ) = _pdf_range($pages);
  return $refuse->($tool, $error) if defined $error;
  my $too_many = 'Page range "'.$pages.'" exceeds maximum of '.$PDF_MAX_PAGES.' pages per request. Please use a smaller range.';
  return $refuse->($tool, $too_many) if defined $last && $last - $first + 1 > $PDF_MAX_PAGES;
  my $pdftotext = File::Which::which('pdftotext')
    or return $refuse->($tool, 'The pages parameter needs pdftotext, which is not installed. Install poppler-utils '
      .'(for example `apt-get install poppler-utils` or `brew install poppler`), or extract the text with a shell command.');
  my $count = _pdf_page_count($p);
  $last //= $count // $first + $PDF_MAX_PAGES - 1;
  $last = $count if defined $count && $last > $count && $first <= $count;
  return $refuse->($tool, $too_many) if $last - $first + 1 > $PDF_MAX_PAGES;
  return $refuse->($tool, 'Page '.$first.' is beyond the end of the PDF, which has '.$count.' pages.')
    if defined $count && $first > $count;
  my ( $out, $err );
  my $ok = eval { IPC::Run::run( [ $pdftotext, '-f', $first, '-l', $last, '-layout', "$p", '-' ], \undef, \$out, \$err ) };
  unless ($ok) {
    my $why = length( $err // '' ) ? $err : ( $@ || 'pdftotext failed' );
    $why =~ s/\s+\z//;
    return $tool->text_result('Failed to read the PDF pages: '.$why, 1);
  }
  my @text = split /\f/, decode( 'UTF-8', $out // '', FB_DEFAULT );
  my $n = $first;
  my $text = 'PDF pages '.$first.'-'.$last.' of '.$p.":\n\n".join( "\n\n", map { 'Page '.$n++.":\n".$_ } @text );
  if ( my $tokens = _tokens_over($text) ) {
    return $tool->text_result('PDF text ('.$tokens.' tokens) exceeds maximum allowed tokens ('.$MAX_READ_TOKENS
      .'). Use a smaller page range.', 1);
  }
  $state->record( "$p", partial => 1 );
  return $tool->text_result($text);
}

sub _read_pdf {
  my ( $tool, $p, $state, $reads_pdf, $refuse, $in ) = @_;
  my $pages = $in->{pages};
  return _read_pdf_pages( $tool, $p, $pages, $state, $refuse ) if defined $pages && length $pages;
  return $refuse->($tool, _sees_text( 'PDF files', $p )) unless $reads_pdf->();
  my $size = -s $p;
  return $refuse->($tool, 'PDF file ('._size_text($size).') exceeds maximum allowed size ('._size_text($MAX_PDF_BYTES)
    .'). Use a shell command or script that can extract the text (such as pdftotext).') if $size > $MAX_PDF_BYTES;
  my $count = _pdf_page_count($p);
  return $refuse->($tool, 'This PDF has '.$count.' pages, which is too many to read at once. Use the pages parameter '
    .'to read specific page ranges (e.g., pages: "1-5"). Maximum '.$PDF_MAX_PAGES.' pages per request.')
    if defined $count && $count > $PDF_INLINE_PAGES;
  my $bytes = eval { $p->slurp_raw };
  return $tool->text_result("Error reading $p: $@", 1) if $@;
  $state->record( "$p", partial => 1 );
  return {
    content => [
      { type => 'text', text => 'PDF file read: '.$p.' ('._size_text($size).')' },
      { type => 'resource', resource => {
        uri => 'file://'.$p, mimeType => 'application/pdf', blob => encode_base64( $bytes, '' ),
      } },
    ],
    isError => JSON->false,
  };
}

# A notebook as Claude Code shows it: each cell as <cell id="..."> with its
# source, the text of its outputs after it; output images as image content
# when the model sees images.
sub _read_notebook {
  my ( $tool, $p, $state, $sees_images, $failed ) = @_;
  my $size = -s $p;
  return $failed->($tool, 'Notebook content ('._size_text($size).') exceeds maximum allowed size ('._size_text($MAX_READ_BYTES)
    .'). Use bash with jq to read specific portions, for example: jq \'.cells[:20]\' '.$p) if $size > $MAX_READ_BYTES;
  my $raw = eval { $p->slurp_raw };
  return $tool->text_result("Error reading $p: $@", 1) if $@;
  my $nb = eval { JSON::MaybeXS->new( utf8 => 1 )->decode($raw) };
  if ( my $err = $@ ) {
    $err =~ s/\s+at \S+ line \d+\.?\s*\z//;
    return $failed->($tool, 'Notebook file is not valid JSON (it may be truncated, corrupted, or still being written): '.$err);
  }
  return $failed->($tool, 'Notebook file is not a valid Jupyter notebook (top-level "cells" must be an array of cell objects, '
    .'each with a string or string-array "source").')
    unless ref $nb eq 'HASH' && ref $nb->{cells} eq 'ARRAY'
      && !grep { ref $_ ne 'HASH' || !( defined $_->{source} && ( !ref $_->{source} || ref $_->{source} eq 'ARRAY' ) ) } @{ $nb->{cells} };
  my $lang = ref $nb->{metadata} eq 'HASH' && ref $nb->{metadata}{language_info} eq 'HASH'
    ? $nb->{metadata}{language_info}{name} // 'python' : 'python';
  my $join = sub { my ($v) = @_; ref $v eq 'ARRAY' ? join( '', grep { !ref } @$v ) : ( $v // '' ) };
  my $images = $sees_images->();
  my @content;
  my $add_text = sub {
    my ($text) = @_;
    if ( @content && $content[-1]{type} eq 'text' ) { $content[-1]{text} .= "\n".$text }
    else { push @content, { type => 'text', text => $text } }
  };
  my $i = 0;
  for my $cell ( @{ $nb->{cells} } ) {
    my $id   = $cell->{id} // 'cell-'.$i;
    my $type = $cell->{cell_type} // 'code';
    my $tags = ( $type ne 'code' ? '<cell_type>'.$type.'</cell_type>' : '' )
      .( $type eq 'code' && $lang ne 'python' ? '<language>'.$lang.'</language>' : '' );
    $add_text->( '<cell id="'.$id.'">'.$tags.$join->( $cell->{source} ).'</cell id="'.$id.'">' );
    for my $out ( $type eq 'code' && ref $cell->{outputs} eq 'ARRAY' ? @{ $cell->{outputs} } : () ) {
      next unless ref $out eq 'HASH';
      my $kind = $out->{output_type} // '';
      my $data = ref $out->{data} eq 'HASH' ? $out->{data} : {};
      my $text = $kind eq 'stream' ? $join->( $out->{text} )
        : $kind eq 'error' ? join( ' ', grep { defined } $out->{ename}.':', $out->{evalue},
          ref $out->{traceback} eq 'ARRAY' ? join( "\n", @{ $out->{traceback} } ) : () )
        : $join->( $data->{'text/plain'} );
      $add_text->($text) if length $text;
      next unless $images;
      for my $mime (qw( image/png image/jpeg )) {
        my $b64 = $data->{$mime};
        next unless defined $b64 && !ref $b64;
        $b64 =~ s/\s+//g;
        push @content, { type => 'image', data => $b64, mimeType => $mime };
        last;
      }
    }
    $i++;
  }
  @content = ( { type => 'text', text => '' } ) unless @content;
  $state->record( "$p", bytes => $raw );
  return { content => \@content, isError => JSON->false };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::FileTools - MCP::Server factory with local filesystem tools (list/read/write/edit/multi_edit)

=head1 VERSION

version 0.504

=head1 DESCRIPTION

The file tools of L<raider>: an L<MCP::Server> with C<list_files(path)>,
C<read_file(path, offset, limit, pages)>, C<write_file(path, content)>,
C<edit_file(path, old_string, new_string, replace_all)> and
C<multi_edit(path, edits)>, which answer as Claude Code's C<Read>, C<Write>,
C<Edit> and C<MultiEdit> do (ADR 0023): the same result and error texts, the
same error flag.

=over

=item * C<read_file> returns the file in C<cat -n> form (line number, a tab,
the line), at most 2000 lines unless C<limit> says otherwise, from line
C<offset> (1-based); a line longer than 2000 characters is cut; a result of
more than 25000 tokens (a token counted as four bytes) is refused. With
C<pages> (C<"3">, C<"1-5">, at most 20 pages) a PDF is read as text through
C<pdftotext> (poppler) for any model; a PDF of more than 10 pages must be
read that way. An image
(PNG, JPEG, GIF, WebP) or a PDF comes back as image or document content
when the model can take it in a tool result (C<sees_images> for images,
C<reads_pdf> for PDFs), a Jupyter notebook as its cells
with their outputs; other binary files, directories and devices are refused
with a message.

=item * B<Read before write.> C<write_file>, C<edit_file> and C<multi_edit>
refuse to change a file that exists but was not read in this run, or that
changed on disk since it was read (L<Langertha::Raider::FileTools::ReadState>).
A new file needs no read; what the tools wrote counts as read.

=item * C<edit_file> replaces C<old_string> where it occurs exactly once, or
every occurrence with C<replace_all>; C<multi_edit> applies several such
edits one after the other to the content in memory and writes only when all
of them apply.

=back

=head2 build_file_tools_server

    my $server = Langertha::Raider::FileTools::build_file_tools_server(
        root        => '/some/dir',      # optional confinement root
        extra_roots => [ '/other/dir' ], # optional: more directories allowed
        # or a CodeRef returning the list, asked on every call:
        # extra_roots => sub { [ '/other/dir' ] },
        confine     => 1,                # default; 0 (or a CodeRef) lets the gate decide
        read_state  => $state,           # optional Langertha::Raider::FileTools::ReadState
        sees_images => sub { 1 },        # optional: may images go back as content
        reads_pdf   => sub { 1 },        # optional: may PDFs go back as content
    );

Returns an L<MCP::Server> instance with the tools C<list_files>, C<read_file>,
C<write_file>, C<edit_file> and C<multi_edit> registered. Relative paths are
read against C<root>. When C<root> is set and C<confine> is true (the
default), all path arguments are confined to that directory and the
C<extra_roots> (the additional directories of ADR 0021). Existing paths and
nearest existing parents are resolved with C<realpath>, so symlinks cannot
be used to escape them. An extra root that does not exist is left out.
C<extra_roots> may be a CodeRef that returns the list (or an ArrayRef); it is
called on every tool call, so the application can change the additional
directories while the server is mounted (C</reload>).

C<confine> may be a CodeRef, asked on every call. False means the tools
reach any path: the application does so in the Claude layout, where the
permission gate asks before a path outside the root and the additional
directories (ADR 0023) -- never without a gate.

C<read_state> is the record of the files read in this run; without one the
server keeps its own, which is never emptied. C<sees_images> (a value or a
CodeRef asked on every call, default true) says whether an image (and a
notebook's output images) may go back as content; C<reads_pdf> (same shape,
default true) says the same for a PDF. They are independent: a model can take
one and not the other (the application asks the engine's C<tool_result_images>
and C<tool_result_pdf> capabilities). What is not taken is refused with a
message; a PDF read by C<pages> is text and needs neither.

=head1 SEE ALSO

=over

=item * L<MCP::Server>

=item * L<Langertha::Raider::FileTools::ReadState>

=item * L<Langertha::Raider::CLI>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-raider/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

L<https://raudssus.de/>

=cut
