package Langertha::Raider::SearchTools;
# ABSTRACT: Internal search tools of raider: glob (files by name) and grep (files by content)
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use Carp qw( croak );
use Cwd qw( realpath );
use Encode ();
use File::Which ();
use IPC::Run ();
use MCP::Server;
use Langertha::Raider::PathConfine;
use Path::Tiny;


has root => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);


has rg => (
  is      => 'ro',
  lazy    => 1,
  builder => '_build_rg',
);


has default_limit => (
  is      => 'ro',
  isa     => 'Int',
  default => 250,
);


has max_file_size => (
  is      => 'ro',
  isa     => 'Int',
  default => 10 * 1024 * 1024,
);

has extra_roots => (
  is      => 'ro',
  isa     => 'ArrayRef[Str]|CodeRef',
  default => sub { [] },
);


has confine => (
  is      => 'ro',
  isa     => 'Bool|CodeRef',
  default => 1,
);


has hider => (
  is  => 'ro',
  isa => 'CodeRef',
);


has _hide => ( is => 'rw', init_arg => undef );
has _hidden => ( is => 'rw', default => 0, init_arg => undef );

# The roots and the confinement, one object shared with the file tools.
has _confinement => (
  is       => 'ro',
  lazy     => 1,
  builder  => '_build__confinement',
  init_arg => undef,
);

sub _build__confinement {
  my ( $self ) = @_;
  return Langertha::Raider::PathConfine->new(
    root        => $self->real_root,
    extra_roots => $self->extra_roots,
    confine     => $self->confine,
    dirs_only   => 1,
  );
}

has real_root => (
  is       => 'ro',
  lazy     => 1,
  builder  => '_build_real_root',
  init_arg => undef,
);

has server => (
  is       => 'ro',
  lazy     => 1,
  builder  => '_build_server',
  init_arg => undef,
);


my %VCS = map { $_ => 1 } qw( .git .hg .svn );

# The file types of the grep tool's `type`, as the extensions they stand for.
my %TYPES = (
  c      => [qw( c h )],
  cpp    => [qw( cpp cc cxx hpp hh hxx h )],
  css    => [qw( css scss sass less )],
  go     => [qw( go )],
  html   => [qw( html htm )],
  java   => [qw( java )],
  js     => [qw( js mjs cjs jsx )],
  json   => [qw( json )],
  kotlin => [qw( kt kts )],
  lua    => [qw( lua )],
  md     => [qw( md markdown )],
  perl   => [qw( pl pm t psgi pod xs )],
  php    => [qw( php )],
  py     => [qw( py pyi )],
  rb     => [qw( rb rake gemspec )],
  rust   => [qw( rs )],
  sh     => [qw( sh bash zsh )],
  sql    => [qw( sql )],
  swift  => [qw( swift )],
  toml   => [qw( toml )],
  ts     => [qw( ts tsx mts cts )],
  txt    => [qw( txt )],
  xml    => [qw( xml )],
  yaml   => [qw( yml yaml )],
);

my %MODES = map { $_ => 1 } qw( content files_with_matches count );

# Longest line a grep result carries; longer ones are cut.
my $MAX_LINE = 2000;

sub _build_rg {
  my ( $self ) = @_;
  return File::Which::which('rg') // 0;
}

sub _build_real_root {
  my ( $self ) = @_;
  my $real = realpath( $self->root );
  croak __PACKAGE__.' root does not exist: '.$self->root unless defined $real;
  return $real;
}


sub engine { my ( $self ) = @_; return $self->rg ? 'ripgrep' : 'perl' }


sub types { return sort keys %TYPES }

#### Paths

# A directory or file below the root, as the real absolute path. Croaks when
# the path is missing or leaves the root.
sub _resolve {
  my ( $self, $path ) = @_;
  my $root = $self->real_root;
  return $root unless defined $path && length $path;
  my $abs  = path($path)->is_absolute ? path($path) : path($root)->child($path);
  my $real = realpath("$abs");
  croak 'no such path: '.$path unless defined $real && -e $real;
  croak 'path escapes root: '.$path unless $self->_confinement->allows($real);
  return $real;
}

# $abs as the path the results show: relative below the root, else absolute
# (an additional directory).
sub _shown {
  my ( $self, $abs ) = @_;
  my $root = $self->real_root;
  return '.' if $abs eq $root;
  return $abs unless index( $abs, $root.'/' ) == 0;
  return substr( $abs, length($root) + 1 );
}

# Starts a call: the hider in force for it, no file hidden yet.
sub _begin_call {
  my ( $self ) = @_;
  $self->_hide( $self->hider ? $self->hider->() : undef );
  $self->_hidden(0);
  return;
}

# The text of a call with the note on hidden files.
sub _with_hidden {
  my ( $self, $text ) = @_;
  my $n = $self->_hidden;
  return $text unless $n;
  return $text."\n\n(".$n.' path'.( $n == 1 ? '' : 's' ).' hidden by permission rules)';
}

# The message of a croak, without " at FILE line N."
sub _message {
  my ( $self, $error ) = @_;
  $error =~ s/\s+at \S+ line \d+\.?\s*\z//;
  return $error;
}

# Every regular file below $dir that is no symbolic link, VCS directories
# left out: [ [ absolute path, mtime ], ... ] sorted by path.
sub _walk {
  my ( $self, $dir ) = @_;
  my @files;
  my @stack = ($dir);
  while ( defined( my $d = pop @stack ) ) {
    opendir( my $dh, $d ) or next;
    my @names = grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh;
    for my $name (@names) {
      my $p  = $d.'/'.$name;
      my @st = lstat $p or next;
      next if -l _;
      if ( -d _ ) {
        push @stack, $p unless $VCS{$name};
        next;
      }
      push @files, [ $p, $st[9] ] if -f _;
    }
  }
  return [ sort { $self->_path_cmp( $a->[0], $b->[0] ) } @files ];
}

# Paths in the order a directory walk lists them (ripgrep --sort path): by
# segment, so that sub/x comes before sub.pm.
sub _path_cmp {
  my ( $self, $x, $y ) = @_;
  my @x = split m{/}, $x;
  my @y = split m{/}, $y;
  while ( @x && @y ) {
    my $c = shift(@x) cmp shift(@y);
    return $c if $c;
  }
  return @x <=> @y;
}

#### Glob patterns

# A glob as an anchored regular expression over a "/" separated path. With
# $anywhere, a pattern without "/" matches the last segment at any depth
# (the way ripgrep's --glob and .gitignore do).
sub _glob_regex {
  my ( $self, $glob, $anywhere ) = @_;
  my @c = split //, $glob;
  my ( $re, $depth ) = ( '', 0 );
  for ( my $i = 0 ; $i < @c ; $i++ ) {
    my $c = $c[$i];
    if ( $c eq '*' ) {
      if ( ( $c[ $i + 1 ] // '' ) eq '*' ) {
        $i++ while ( $c[ $i + 1 ] // '' ) eq '*';
        if ( ( $c[ $i + 1 ] // '' ) eq '/' ) { $i++; $re .= '(?:.*/)?' }
        else                                { $re .= '.*' }
      }
      else { $re .= '[^/]*' }
    }
    elsif ( $c eq '?' ) { $re .= '[^/]' }
    elsif ( $c eq '[' ) {
      my $j = $i + 1;
      $j++ if ( $c[$j] // '' ) =~ /[!^]/;
      $j++ if ( $c[$j] // '' ) eq ']';
      $j++ while $j < @c && $c[$j] ne ']';
      if ( $j >= @c ) { $re .= '\\[' }
      else {
        my $class = join '', @c[ $i + 1 .. $j - 1 ];
        $class =~ s/\\/\\\\/g;
        $class =~ s/\A!/^/;
        $re .= '['.$class.']';
        $i = $j;
      }
    }
    elsif ( $c eq '{' )              { $depth++; $re .= '(?:' }
    elsif ( $c eq '}' && $depth )    { $depth--; $re .= ')' }
    elsif ( $c eq ',' && $depth )    { $re .= '|' }
    elsif ( $c eq '\\' )             { $i++; $re .= quotemeta( $c[$i] // '\\' ) }
    else                             { $re .= quotemeta $c }
  }
  croak 'unbalanced { in glob: '.$glob if $depth;
  $re = '(?:.*/)?'.$re if $anywhere && $glob !~ m{/};
  my $qr = eval { qr/\A$re\z/s };
  croak 'invalid glob: '.$glob unless $qr;
  return $qr;
}

# The pattern of a glob call, checked: relative to the search directory.
sub _glob_pattern {
  my ( $self, $glob ) = @_;
  croak 'a pattern is required' unless defined $glob && length $glob;
  croak 'the pattern must be relative to the search directory (use path to search elsewhere): '.$glob
    if $glob =~ m{\A/} || grep { $_ eq '..' } split m{/}, $glob;
  $glob =~ s{\A(?:\./)+}{};
  return $glob;
}

# The files of a search: [ [ absolute, mtime ], ... ] below $dir (or the one
# file $dir), passing $filter, a CodeRef on the path relative to $dir.
sub _candidates {
  my ( $self, $dir, $filter ) = @_;
  if ( -f $dir ) {
    my @st = stat $dir;
    return [ [ $dir, $st[9] ] ];
  }
  my $skip = length($dir) + 1;
  my @files = grep { !$filter || $filter->( substr( $_->[0], $skip ) ) } @{ $self->_walk($dir) };
  if ( my $hide = $self->_hide ) {
    my $before = @files;
    @files = grep { !$hide->( $_->[0] ) } @files;
    $self->_hidden( $self->_hidden + $before - @files );
  }
  return \@files;
}

# Newest first, ties by path.
sub _by_mtime {
  my ( $self, @files ) = @_;
  return sort { $b->[1] <=> $a->[1] || $self->_path_cmp( $a->[0], $b->[0] ) } @files;
}


sub glob {
  my ( $self, $in ) = @_;
  $self->_begin_call;
  return $self->_with_hidden( $self->_glob($in) );
}

sub _glob {
  my ( $self, $in ) = @_;
  my $glob = $self->_glob_pattern( $in->{pattern} );
  my $dir  = $self->_resolve( $in->{path} );
  croak 'not a directory: '.$in->{path} unless -d $dir;
  my $re    = $self->_glob_regex($glob);
  my @found = $self->_by_mtime( @{ $self->_candidates( $dir, sub { $_[0] =~ $re } ) } );
  return 'No files found' unless @found;
  my $limit = $self->default_limit;
  my @shown = map { $self->_shown( $_->[0] ) } @found > $limit ? @found[ 0 .. $limit - 1 ] : @found;
  my $text  = join "\n", @shown;
  $text .= "\n\n(Showing the newest $limit of ".scalar(@found).' files. Use a more specific pattern or path.)'
    if @found > $limit;
  return $text;
}

#### Grep

# The options of a grep call, checked and with their defaults.
sub _grep_options {
  my ( $self, $in ) = @_;
  croak 'a pattern is required' unless defined $in->{pattern} && length $in->{pattern};
  my %o = (
    pattern   => $in->{pattern},
    mode      => $in->{output_mode} // 'files_with_matches',
    icase     => $in->{'-i'} ? 1 : 0,
    numbers   => exists $in->{'-n'} ? ( $in->{'-n'} ? 1 : 0 ) : 1,
    multiline => $in->{multiline} ? 1 : 0,
    offset    => $in->{offset} // 0,
    limit     => $in->{head_limit} // $self->default_limit,
    glob      => $in->{glob},
  );
  croak 'the literal "\n" is not allowed in a regex; set multiline to match across lines'
    if !$o{multiline} && $o{pattern} =~ /(?<!\\)(?:\\\\)*\\n/;
  croak 'unknown output_mode: '.$o{mode}.' (content, files_with_matches or count)' unless $MODES{ $o{mode} };
  my $c = $in->{'-C'} // $in->{context};
  $o{before} = $in->{'-B'} // $c // 0;
  $o{after}  = $in->{'-A'} // $c // 0;
  for my $k (qw( before after offset limit )) {
    croak "$k must be a non-negative integer" unless $o{$k} =~ /\A\d+\z/;
  }
  if ( defined $in->{type} ) {
    croak 'unknown type: '.$in->{type}.' (known: '.join( ', ', $self->types ).')' unless $TYPES{ $in->{type} };
    $o{type} = $in->{type};
  }
  $o{glob} = $self->_glob_pattern( $o{glob} ) if defined $o{glob} && length $o{glob};
  delete $o{glob} unless defined $o{glob} && length $o{glob};
  return \%o;
}


sub grep {
  my ( $self, $in ) = @_;
  $self->_begin_call;
  return $self->_with_hidden( $self->_grep($in) );
}

sub _grep {
  my ( $self, $in ) = @_;
  my $o   = $self->_grep_options($in);
  my $dir = $self->_resolve( $in->{path} );
  my @lines =
    $self->rg && !( $o->{type} && defined $o->{glob} ) && !$self->_hide
    ? $self->_grep_rg( $o, $dir )
    : $self->_grep_perl( $o, $dir );
  return 'No matches found' unless @lines;
  return $self->_slice( $o, \@lines );
}

# The part of the output lines the offset and the limit ask for.
sub _slice {
  my ( $self, $o, $lines ) = @_;
  my $total = @$lines;
  my @out   = splice @$lines, 0, $total;
  @out = @out[ $o->{offset} .. $#out ] if $o->{offset};
  return 'No matches found at this offset (there are '.$total.' lines)' unless @out;
  my $cut = $o->{limit} && @out > $o->{limit};
  @out = @out[ 0 .. $o->{limit} - 1 ] if $cut;
  my $text = join "\n", map { length > $MAX_LINE ? substr( $_, 0, $MAX_LINE ).' [line cut]' : $_ } @out;
  $text .= "\n\n(Showing ".scalar(@out).' of '.$total.' lines from offset '.$o->{offset}.'. Raise head_limit or use offset for more.)'
    if $cut;
  return $text;
}

# The files and ordering the modes ask for, from the paths of the matching
# files: files_with_matches is newest first, the others by path.
sub _files_by_mtime {
  my ( $self, @paths ) = @_;
  my $root = $self->real_root;
  return map { $self->_shown( $_->[0] ) } $self->_by_mtime(
    map { my $abs = m{\A/} ? $_ : $root.'/'.$_; [ $abs, ( stat $abs )[9] // 0 ] } @paths
  );
}

#### Grep: Perl

sub _grep_perl {
  my ( $self, $o, $dir ) = @_;
  my $flags = ( $o->{icase} ? 'i' : '' ).( $o->{multiline} ? 'ms' : '' );
  my $re    = eval { $flags ? qr/(?$flags:$o->{pattern})/ : qr/$o->{pattern}/ };
  croak 'invalid regular expression: '.$self->_message($@) unless $re;

  my @filters;
  if ( defined $o->{glob} ) {
    my $g = $self->_glob_regex( $o->{glob}, 1 );
    push @filters, sub { $_[0] =~ $g };
  }
  if ( $o->{type} ) {
    my $ext = join '|', map { quotemeta } @{ $TYPES{ $o->{type} } };
    push @filters, sub { $_[0] =~ /\.(?:$ext)\z/ };
  }
  my $filter = @filters ? sub { my ($p) = @_; !grep { !$_->($p) } @filters } : undef;

  my ( @content, @counts, @matched );
  for my $f ( @{ $self->_candidates( $dir, $filter ) } ) {
    my $text = $self->_read_text( $f->[0] );
    next unless defined $text;
    my $hits = $o->{multiline} ? $self->_hits_multiline( $re, $text ) : $self->_hits_lines( $re, $text );
    next unless %{ $hits->{lines} };
    my $shown = $self->_shown( $f->[0] );
    push @matched, $shown;
    push @counts, $shown.':'.scalar( keys %{ $hits->{lines} } );
    push @content, $self->_content_lines( $o, $shown, $hits ) if $o->{mode} eq 'content';
  }
  return $o->{mode} eq 'count'   ? @counts
       : $o->{mode} eq 'content' ? $self->_separated( $o, @content )
       :                           $self->_files_by_mtime(@matched);
}

# The text of a file, or undef for one that is too big, unreadable or binary.
sub _read_text {
  my ( $self, $file ) = @_;
  return if -s $file > $self->max_file_size;
  open( my $fh, '<:raw', $file ) or return;
  local $/;
  my $bytes = <$fh>;
  close $fh;
  return unless defined $bytes;
  return if substr( $bytes, 0, 8000 ) =~ /\0/;
  return Encode::decode( 'UTF-8', $bytes, Encode::FB_DEFAULT );
}

# { lines => { N => 1 }, all => [ the lines ] } for a regex per line.
sub _hits_lines {
  my ( $self, $re, $text ) = @_;
  my @all = split /\n/, $text, -1;
  pop @all if @all && $all[-1] eq '';
  s/\r\z// for @all;
  my %lines;
  for my $i ( 0 .. $#all ) { $lines{ $i + 1 } = 1 if $all[$i] =~ $re }
  return { lines => \%lines, all => \@all };
}

# The same for a regex over the whole text: every line a match touches.
sub _hits_multiline {
  my ( $self, $re, $text ) = @_;
  my @all = split /\n/, $text, -1;
  pop @all if @all && $all[-1] eq '';
  my @start = (0);    # offset of each line's first character
  push @start, $start[-1] + length($_) + 1 for @all;
  my $line_of = sub {
    my ($off) = @_;
    my ( $lo, $hi ) = ( 0, $#all );
    while ( $lo < $hi ) {
      my $mid = int( ( $lo + $hi + 1 ) / 2 );
      if   ( $start[$mid] <= $off ) { $lo = $mid }
      else                          { $hi = $mid - 1 }
    }
    return $lo + 1;
  };
  my %lines;
  while ( $text =~ /$re/g ) {
    my ( $from, $to ) = ( $-[0], $+[0] );
    my ( $first, $last ) = ( $line_of->($from), $line_of->( $to > $from ? $to - 1 : $from ) );
    $last = scalar @all if $last > @all;
    $lines{$_} = 1 for $first .. $last;
  }
  s/\r\z// for @all;
  return { lines => \%lines, all => \@all };
}

# The output lines of one file in content mode: matches, context, and "--"
# between groups that do not touch.
sub _content_lines {
  my ( $self, $o, $shown, $hits ) = @_;
  my ( $all, $match ) = ( $hits->{all}, $hits->{lines} );
  my %show;
  for my $n ( keys %$match ) {
    my $from = $n - $o->{before};
    my $to   = $n + $o->{after};
    $from = 1 if $from < 1;
    $to = @$all if $to > @$all;
    $show{$_} = 1 for $from .. $to;
  }
  my ( @out, $prev );
  for my $n ( sort { $a <=> $b } keys %show ) {
    push @out, '--' if defined $prev && $n > $prev + 1 && ( $o->{before} || $o->{after} );
    my $sep = $match->{$n} ? ':' : '-';
    push @out, $shown.$sep.( $o->{numbers} ? $n.$sep : '' ).$all->[ $n - 1 ];
    $prev = $n;
  }
  return \@out;
}

# The output of the files joined, a `--` between files when there is
# context, as ripgrep prints it.
sub _separated {
  my ( $self, $o, @files ) = @_;
  my @out;
  for my $f (@files) {
    push @out, '--' if @out && ( $o->{before} || $o->{after} );
    push @out, @$f;
  }
  return @out;
}

#### Grep: ripgrep

sub _grep_rg {
  my ( $self, $o, $dir ) = @_;
  my @cmd = (
    $self->rg, qw( --no-config --color never --hidden --no-ignore --sort path --no-messages ),
    '--max-filesize', $self->max_file_size,
  );
  push @cmd, '--ignore-case' if $o->{icase};
  push @cmd, '--multiline', '--multiline-dotall' if $o->{multiline};
  if ( $o->{mode} eq 'content' ) {
    push @cmd, qw( --with-filename --no-heading ), ( $o->{numbers} ? '--line-number' : '--no-line-number' );
    push @cmd, '--before-context', $o->{before} if $o->{before};
    push @cmd, '--after-context',  $o->{after}  if $o->{after};
  }
  elsif ( $o->{mode} eq 'count' ) { push @cmd, qw( --count --with-filename ) }
  else                            { push @cmd, '--files-with-matches' }
  push @cmd, '--glob', $o->{glob} if defined $o->{glob};
  if ( $o->{type} ) {
    push @cmd, '--glob', '*.{'.join( ',', @{ $TYPES{ $o->{type} } } ).'}';
  }
  push @cmd, map { ( '--glob', '!'.$_ ) } sort keys %VCS;
  my $target = $dir eq $self->real_root ? '.' : $self->_shown($dir);
  push @cmd, '--regexp', $o->{pattern}, '--', $target;

  my ( $out, $err ) = ( '', '' );
  my $root = $self->real_root;
  IPC::Run::run( \@cmd, \undef, \$out, \$err, init => sub { chdir $root } );
  my $status = $? >> 8;
  die "ripgrep failed to start\n" if $? == -1;
  croak 'invalid search: '.( $err =~ s/\s+\z//r ) if $status == 2 && !length $out && length $err;
  my @lines = split /\n/, $out;
  s{\A\./}{} for @lines;
  return $o->{mode} eq 'files_with_matches' ? $self->_files_by_mtime(@lines) : @lines;
}

#### Server

sub _build_server {
  my ( $self ) = @_;
  my $server = MCP::Server->new( name => 'raider-search', version => '1.0' );

  my $run = sub {
    my ( $method ) = @_;
    return sub {
      my ( $tool, $in ) = @_;
      my $text = eval { $self->$method($in) };
      return $tool->text_result( 'Error: '.$self->_message($@), 1 ) if $@;
      return $tool->text_result($text);
    };
  };

  $server->tool(
    name         => 'glob',
    description  => 'Find files by name pattern, newest first. Patterns like "**/*.pm", "src/**/*.ts" or "*.{json,yml}"; '
      .'* and ? stay within one path segment, ** crosses directories. Paths are relative to the working directory. '
      .'Does not follow symbolic links, skips .git and does not read .gitignore.',
    input_schema => {
      type       => 'object',
      properties => {
        pattern => { type => 'string', description => 'Glob pattern, relative to path' },
        path    => { type => 'string', description => 'Directory to search in (default: the working directory)' },
      },
      required => ['pattern'],
    },
    code => $run->('glob'),
  );

  $server->tool(
    name         => 'grep',
    description  => 'Search file contents with a regular expression (ripgrep when installed, else Perl). '
      .'output_mode: "files_with_matches" (default, newest first), "content" (path:line:text, with context) or "count". '
      .'Filter with glob ("*.pm", any depth) or type ("perl", "js", "py", ...). Does not follow symbolic links, skips .git, '
      .'binary files and files over 10 MB, and does not read .gitignore. Keep the pattern to syntax Perl and Rust share.',
    input_schema => {
      type       => 'object',
      properties => {
        pattern     => { type => 'string',  description => 'Regular expression to search for' },
        path        => { type => 'string',  description => 'File or directory to search (default: the working directory)' },
        glob        => { type => 'string',  description => 'Only files matching this glob, e.g. "*.pm" or "src/**/*.ts"' },
        type        => { type => 'string',  description => 'Only files of this type: '.join( ', ', $self->types ) },
        output_mode => { type => 'string',  enum => [qw( content files_with_matches count )], description => 'What to return (default files_with_matches)' },
        '-i'        => { type => 'boolean', description => 'Ignore case' },
        '-n'        => { type => 'boolean', description => 'Line numbers in content mode (default true)' },
        '-A'        => { type => 'integer', minimum => 0, description => 'Lines of context after each match (content mode)' },
        '-B'        => { type => 'integer', minimum => 0, description => 'Lines of context before each match (content mode)' },
        '-C'        => { type => 'integer', minimum => 0, description => 'Lines of context around each match (content mode)' },
        context     => { type => 'integer', minimum => 0, description => 'Alias of -C' },
        multiline   => { type => 'boolean', description => 'Let the pattern span lines; . matches a newline' },
        head_limit  => { type => 'integer', minimum => 0, description => 'Limit the output to this many lines/entries (default 250, 0 = no limit)' },
        offset      => { type => 'integer', minimum => 0, description => 'Skip this many lines/entries of the output first' },
      },
      required => ['pattern'],
    },
    code => $run->('grep'),
  );

  return $server;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::SearchTools - Internal search tools of raider: glob (files by name) and grep (files by content)

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    my $search = Langertha::Raider::SearchTools->new( root => '/some/project' );
    my $server = $search->server;     # MCP::Server with the tools glob and grep

    say $search->glob({ pattern => 'lib/**/*.pm' });
    say $search->grep({ pattern => 'sub \w+', output_mode => 'count' });

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The two search tools of raider, named and shaped after Claude Code's
C<Glob> and C<Grep> (L<Langertha::Raider::ToolNames>), confined to one
directory the way L<Langertha::Raider::FileTools> is: every path argument
is resolved with C<realpath> and must stay inside L</root> (unless
L</confine> is off). Paths in the results are relative to L</root>, so they
go straight into C<read_file>.

Both tools see the same files. They walk the tree without following
symbolic links, skip the version control directories (F<.git>, F<.hg>,
F<.svn>), look into hidden files and do B<not> apply F<.gitignore>: what
is searched does not depend on which engine runs the search. Narrow a
search with C<path> and C<glob> instead. Files over 10 MB and binary
files (a NUL byte near the start) are skipped.

C<glob> matches a pattern against the path below the search directory
(C<*> and C<?> stay within one path segment, C<**> crosses segments,
C<[abc]> and C<{a,b}> as in a shell) and lists the matches, newest
modification time first.

C<grep> searches file contents with a regular expression, with the modes
and options of Claude Code's tool. It runs ripgrep when there is one
(L</rg>) and plain Perl otherwise; the output is the same. A C<type>
together with a C<glob> is always searched by the Perl code, as ripgrep
cannot take both filters at once. The pattern is a Perl regular
expression in the Perl code and a Rust one in ripgrep -- stay with the
common syntax (no look-around, no back-references).

=head2 root

Required. The directory the tools are confined to and the relative paths
of the results are taken from. It must exist.

=head2 rg

Path of the ripgrep executable C<grep> uses. Default: C<rg> off C<PATH>.
Pass C<0> to always use the Perl code (a test does, to be independent of
the host), or a path to name the executable.

=head2 default_limit

How many results a call returns unless C<head_limit> says otherwise
(C<glob>: files; C<grep>: lines of content, files or counts). Default 250.

=head2 extra_roots

More directories a C<path> may name besides L</root> (the additional
directories of ADR 0021). Results inside them are shown as absolute paths.
One that does not exist is left out. A CodeRef returning the list (or an
ArrayRef) is called on every call, so the roots can change while the tools
are mounted (C</reload>).

=head2 confine

True by default: a C<path> must stay inside L</root> and the
L</extra_roots>. False (or a CodeRef answering false, asked on every
call) lets a search start anywhere -- the application does so in the
Claude layout, where the permission gate asks before a search outside the
root and the additional directories (ADR 0023). Results outside L</root>
are absolute paths; the walk still follows no symbolic link.

=head2 hider

Called without arguments at the start of every call. Returns undef, or code
that is called with the real absolute path of each file a call would list
or search and returns true for a file to leave out -- the application hides
the files a permission rule refuses or asks about reading (ADR 0021). The
result then ends with C<(N paths hidden by permission rules)>. While a
hider is in force C<grep> runs the Perl code, which applies it file by file.

=head2 server

The L<MCP::Server> with the tools C<glob> and C<grep>, built once.

=head2 engine

    my $engine = $search->engine;     # 'ripgrep' or 'perl'

Which one L</grep> runs for an ordinary search.

=head2 types

The names C<grep> accepts as C<type>, sorted.

=head2 glob

    my $text = $search->glob({ pattern => '**/*.pm', path => 'lib' });

The files below C<path> (default: L</root>) whose path below C<path>
matches C<pattern>, one per line, newest modification time first, as paths
relative to L</root>. At most L</default_limit> are listed; the text says
so when there are more. Croaks on a missing pattern, a pattern that
leaves the search directory, and a C<path> that does not exist, is not a
directory or leaves the root (and the L</extra_roots>). Files the
L</hider> hides are not listed; the text then ends with how many.

=head2 grep

    my $text = $search->grep({
      pattern     => 'TODO',
      path        => 'lib',              # directory or file; default: the root
      glob        => '*.pm',             # only files matching it (any depth)
      type        => 'perl',             # only files of this type
      output_mode => 'content',          # files_with_matches (default), content, count
      '-i'        => 1,                  # ignore case
      '-n'        => 1,                  # line numbers in content mode (default on)
      '-B' => 1, '-A' => 2, '-C' => 3,   # context lines; context is an alias of -C
      multiline   => 1,                  # the pattern may span lines, . matches a newline
      head_limit  => 50, offset => 0,    # slice of the output
    });

The files of C<path> whose content matches C<pattern>. C<files_with_matches>
lists the files, newest first; C<count> gives C<path:N> lines, the number
of matching lines; C<content> gives the matching lines as C<path:line:text>
and context lines as C<path-line-text>, groups of lines apart from each
other separated by C<-->. C<head_limit> (default L</default_limit>, C<0>
for no limit) and C<offset> cut the lines of the output, and the text says
when it was cut. Lines over 2000 characters are shortened. Croaks on an
invalid option or pattern and a C<path> that does not exist or leaves the
root; a search without a match returns C<No matches found>. Files the
L</hider> hides are not searched; the text then ends with how many.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::FileTools>

=item * L<Langertha::Raider::ToolNames>

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
