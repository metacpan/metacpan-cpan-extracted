package Langertha::Raider::Config;
# ABSTRACT: Internal resolver and writer for the project config file
our $VERSION = '0.503';
use Moose;
use namespace::autoclean;
use Carp qw( croak );
use JSON::MaybeXS ();
use Path::Tiny;
use YAML::PP ();
use Langertha::Raider::Detect;
use Langertha::Raider::Home;


# Keys that configure raider itself and never reach the engine constructor.
my %APP_KEY = map { $_ => 1 } qw( detect engine no_detect packs perl preferred_lib_target project_tools skills );

my %PROFILE_KEYWORD = (
  claude => 'claude',
  openai => 'openai',
  codex  => 'openai',
  agents => 'openai',
);


has root => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);


has file => (
  is         => 'ro',
  isa        => 'Path::Tiny',
  lazy_build => 1,
);

sub _build_file {
  my ( $self ) = @_;
  return -f $self->native_file ? $self->native_file : $self->legacy_file;
}

sub home_class { 'Langertha::Raider::Home' }


has home_file => (
  is         => 'ro',
  isa        => 'Maybe[Path::Tiny]',
  lazy_build => 1,
);

sub _build_home_file {
  my ( $self ) = @_;
  my $base = $self->home_class->home_base;
  return defined $base ? $base->child('config.yml') : undef;
}


has uses_home => (
  is         => 'ro',
  isa        => 'Bool',
  lazy_build => 1,
);

sub _build_uses_home {
  my ( $self ) = @_;
  my $home = $self->home_file;
  return 0 unless defined $home && -f $home;
  return $self->_is_home_file ? 0 : 1;
}

# True when the file in use is the home file itself (raider runs in the
# home directory), compared by real path.
sub _is_home_file {
  my ( $self ) = @_;
  my $home = $self->home_file;
  return 0 unless defined $home && -f $home && -f $self->file;
  return $home->realpath eq $self->file->realpath ? 1 : 0;
}


sub home_label { 'home' }


sub native_file { $_[0]->home_class->project_base($_[0]->root)->child('config.yml') }

sub legacy_file { path($_[0]->root)->child('.raider.yml') }

sub is_native { $_[0]->file eq $_[0]->native_file ? 1 : 0 }

sub label { $_[0]->is_native ? $_[0]->home_class->dir_name.'/config.yml' : '.raider.yml' }


sub ignored_files {
  my ( $self ) = @_;
  return unless $self->is_native && -f $self->legacy_file;
  return {
    file   => $self->legacy_file->absolute->stringify,
    reason => 'both .raider.yml and '.$self->label.' exist; only '.$self->label.' is loaded',
  };
}


has data => (
  is         => 'ro',
  isa        => 'HashRef',
  lazy_build => 1,
);


has home_data => (
  is         => 'ro',
  isa        => 'HashRef',
  lazy_build => 1,
);

sub _build_home_data {
  my ( $self ) = @_;
  return $self->uses_home ? $self->_load($self->home_file) : {};
}

# A YAML::PP error as one line. Its detailed report ("Line : 2",
# "Column : 3", "Expected : ..." or "Message : ...") is summed up as
# "line 2, column 3: expected EOL, got COLON"; a short error keeps its
# first line. Either way without YAML::PP's source location.
sub _parse_error {
  my ( $self, $error ) = @_;
  my %f = $error =~ /^(Line|Column|Message|Expected|Got)\s*: (.*)$/mg;
  if (defined $f{Line}) {
    my $reason = defined $f{Message} ? $f{Message}
      : defined $f{Expected} ? 'expected '.$f{Expected}.', got '.( $f{Got} // '?' )
      : 'syntax error';
    return 'line '.$f{Line}.( defined $f{Column} ? ', column '.$f{Column} : '' ).': '.$reason;
  }
  return ( split /\n/, $error )[0] =~ s/ at (?:(?! at ).)+ line \d+\.\z//r;
}

sub _build_data {
  my ( $self ) = @_;
  return $self->_load($self->file);
}

sub _load {
  my ( $self, $file ) = @_;
  return {} unless -f $file;
  my $data;
  eval { $data = YAML::PP->new->load_string($file->slurp_utf8); 1 }
    or croak 'Cannot parse '.$file.': '.$self->_parse_error($@);
  return {} unless defined $data;
  croak 'Cannot use '.$file.': the top level must be a mapping' unless ref $data eq 'HASH';
  for my $key (sort keys %$data) {
    next unless $APP_KEY{$key} && !$self->_may_be_mapping($key) && ref $data->{$key} eq 'HASH';
    croak 'Cannot use '.$file.': '.$key.': configures raider, not an engine section; must not be a mapping';
  }
  # Every section, the inactive ones too: the file is valid or not whichever
  # engine runs.
  for my $section (sort grep { ref $data->{$_} eq 'HASH' && !$APP_KEY{$_} } keys %$data) {
    for my $key (sort keys %{ $data->{$section} }) {
      next unless $APP_KEY{$key} && !$self->_may_be_mapping($key) && ref $data->{$section}{$key} eq 'HASH';
      croak 'Cannot use '.$file.': '.$section.'.'.$key.': configures raider; must not be a mapping';
    }
  }
  return $data;
}


sub file_exists { -f $_[0]->file ? 1 : 0 }

# The raider keys whose value may be a mapping; any other top-level mapping
# is an engine section.
sub _may_be_mapping {
  my ( $self, $key ) = @_;
  return $key eq 'skills' || $key eq 'detect' || $key eq 'project_tools';
}

sub _is_section {
  my ( $self, $data, $key ) = @_;
  return !$self->_may_be_mapping($key) && ref $data->{$key} eq 'HASH';
}

# The layers of one file, named top, default and the engine; with a
# $prefix (the home file: 'home ') in front of each name.
sub _layers {
  my ( $self, $engine, $data, $prefix ) = @_;
  my @layers = ( [ $prefix.'top' => { map { $_ => $data->{$_} } grep { !$self->_is_section($data, $_) } keys %$data } ] );
  push @layers, [ $prefix.'default' => $data->{default} ] if $self->_is_section($data, 'default');
  push @layers, [ $prefix.$engine => $data->{$engine} ]
    if defined $engine && $engine ne 'default' && $self->_is_section($data, $engine);
  return @layers;
}

# Effective value and source per key, the shadowed sources, the skills of
# every layer, and what was ignored: the project file over the home file,
# merged per key as DESCRIPTION says. merged_with names the home layer a
# merged key took values from; project is the project file on its own.
sub _resolve {
  my ( $self, $engine ) = @_;
  my $project = $self->_resolve_file($engine, $self->data, '');
  return $project unless $self->uses_home;
  my $home = $self->_resolve_file($engine, $self->home_data, $self->home_label.' ');

  my %value    = %{ $home->{value} };
  my %source   = %{ $home->{source} };
  my %shadowed = map { $_ => [ @{ $home->{shadowed}{$_} } ] } keys %{ $home->{shadowed} };
  my %merged_with;
  for my $key (sort keys %{ $project->{value} }) {
    my $value  = $project->{value}{$key};
    my @before = @{ $project->{shadowed}{$key} // [] };
    if (exists $value{$key}) {
      if (my $merged = $self->_merge_home($key, $value{$key}, $value)) {
        $value = $merged->[0];
        $merged_with{$key} = [ $source{$key} ];
      }
      else {
        unshift @before, $source{$key};
      }
      unshift @before, @{ $shadowed{$key} // [] };
    }
    $value{$key}  = $value;
    $source{$key} = $project->{source}{$key};
    if (@before) { $shadowed{$key} = \@before } else { delete $shadowed{$key} }
  }
  return {
    value       => \%value,
    source      => \%source,
    shadowed    => \%shadowed,
    merged_with => \%merged_with,
    skills      => [ @{ $home->{skills} }, @{ $project->{skills} } ],
    ignored     => [ @{ $home->{ignored} }, @{ $project->{ignored} } ],
    project     => $project,
  };
}

# A key set in both files: [ merged value ] for the keys that merge
# (no_detect: union; detect: per pack when both are maps), else nothing,
# and the project value replaces the home one.
sub _merge_home {
  my ( $self, $key, $home, $project ) = @_;
  if ($key eq 'no_detect') {
    my %seen;
    return [ [ grep { ref || !$seen{$_}++ } map { $self->_name_list($_) } $home, $project ] ];
  }
  return [ { %$home, %$project } ] if $key eq 'detect' && ref $home eq 'HASH' && ref $project eq 'HASH';
  return;
}

# A no_detect value as a list: its items, or a string split on commas. A
# value of any other shape stays one item, for normalize_detect to reject.
sub _name_list {
  my ( $self, $value ) = @_;
  return ()      unless defined $value;
  return @$value if ref $value eq 'ARRAY';
  return $value  if ref $value;
  return split /\s*,\s*/, $value;
}

# One pass over the layers of one file: effective value and source per
# key, the shadowed sources, the skills of every layer, and what was
# ignored.
sub _resolve_file {
  my ( $self, $engine, $data, $prefix ) = @_;
  my ( %value, %source, %shadowed, @skills, @ignored );
  for my $layer ($self->_layers($engine, $data, $prefix)) {
    my ( $name, $hash ) = @$layer;
    for my $key (sort keys %$hash) {
      if ($key eq 'skills') {
        push @skills, { source => $name, value => $hash->{$key} };
        next;
      }
      if ($key eq 'project_tools') {
        # Read on its own (project_tools), never layered; anywhere else
        # than the top level of the home file it is reported, not used.
        my $top = $name eq $prefix.'top';
        push @ignored, $self->_ignored_project_tools($name, $top)
          unless $top && ( length $prefix || $self->_is_home_file );
        next;
      }
      if ($key eq 'engine' && $name ne $prefix.'top' && $name ne $prefix.'default') {
        push @ignored, { key => $name.'.engine', reason => 'engine: inside an engine section' };
        next;
      }
      push @{ $shadowed{$key} }, $source{$key} if exists $source{$key};
      $value{$key}  = $hash->{$key};
      $source{$key} = $name;
    }
  }
  for my $key (sort keys %$data) {
    next unless $self->_is_section($data, $key);
    next if $key eq 'default' || (defined $engine && $key eq $engine);
    push @ignored, { key => $prefix.$key, reason => 'section of an inactive engine' };
  }
  return {
    value    => \%value,
    source   => \%source,
    shadowed => \%shadowed,
    skills   => \@skills,
    ignored  => \@ignored,
  };
}


sub layer_label {
  my ( $self, $layer ) = @_;
  my $file   = $self->label;
  my $prefix = $self->home_label.' ';
  if (index($layer, $prefix) == 0) {
    $file  = $self->home_label;
    $layer = substr $layer, length $prefix;
  }
  return $layer eq 'top' ? $file : $file.' '.$layer.':';
}


sub value_label {
  my ( $self, $engine, $key ) = @_;
  return $self->label unless $self->uses_home;
  return exists $self->_resolve($engine)->{project}{value}{$key} ? $self->label : $self->home_label;
}

sub detect_rule_label {
  my ( $self, $engine, $pack ) = @_;
  return $self->label.' detect:' unless $self->uses_home;
  my $project = $self->_resolve($engine)->{project}{value}{detect};
  my $from_project = ref $project eq 'HASH' ? exists $project->{$pack} : defined $project;
  return ( $from_project ? $self->label : $self->home_label ).' detect:';
}


sub engine {
  my ( $self ) = @_;
  my $engine = $self->_resolve(undef)->{value}{engine};
  return defined $engine && !ref $engine && length $engine ? $engine : undef;
}


sub options {
  my ( $self, $engine ) = @_;
  return { %{ $self->_resolve($engine)->{value} } };
}


sub engine_options {
  my ( $self, $engine ) = @_;
  my $opts = $self->options($engine);
  delete @$opts{keys %APP_KEY};
  return $opts;
}


sub is_app_key {
  my ( $self, $key ) = @_;
  return $APP_KEY{$key} ? 1 : 0;
}

sub detect_class { 'Langertha::Raider::Detect' }


sub detect_settings {
  my ( $self, $engine ) = @_;
  my $opts = $self->options($engine);
  return $self->normalize_detect($opts->{detect}, $opts->{no_detect});
}


sub normalize_detect {
  my ( $self, $detect, $no_detect ) = @_;
  my %settings = ( enabled => 1, rules => {}, off => {} );
  if (defined $detect) {
    if (ref $detect eq 'HASH') {
      for my $name (sort keys %$detect) {
        my $rule = $detect->{$name};
        if (ref $rule eq 'HASH') {
          $self->detect_class->validate_rule($rule, 'detect.'.$name);
          $settings{rules}{$name} = $rule;
        }
        elsif (ref $rule || !defined $rule || ($rule && $rule ne '1')) {
          croak 'Invalid detect setting detect.'.$name.': must be a rule or false';
        }
        elsif (!$rule) {
          $settings{off}{$name} = 'detect: '.$name.': false';
        }
      }
    }
    elsif (ref $detect) {
      croak 'Invalid detect setting detect: must be a map of pack name to rule, or false';
    }
    else {
      $settings{enabled} = $detect ? 1 : 0;
    }
  }
  if (defined $no_detect) {
    my @names = ref $no_detect eq 'ARRAY' ? @$no_detect
              : ref $no_detect            ? croak 'Invalid detect setting no_detect: must be a list of pack names'
              :                             split /\s*,\s*/, $no_detect;
    for my $name (@names) {
      croak 'Invalid detect setting no_detect: must be a list of pack names' if ref $name || !length($name // '');
      $settings{off}{$name} = 'no_detect';
    }
  }
  return \%settings;
}


has project_tools => (
  is         => 'ro',
  isa        => 'ArrayRef',
  lazy_build => 1,
);

sub _build_project_tools {
  my ( $self ) = @_;
  return $self->normalize_project_tools($self->_project_tools_data->{project_tools});
}

# The file whose top-level project_tools grants: the home layer, or the
# file in use when it is the home file; empty otherwise.
sub _project_tools_data {
  my ( $self ) = @_;
  return $self->uses_home ? $self->home_data : $self->_is_home_file ? $self->data : {};
}


sub normalize_project_tools {
  my ( $self, $value ) = @_;
  return [] unless defined $value;
  croak 'Invalid project_tools setting project_tools: must be a map of workspace selector to a list of tool names'
    unless ref $value eq 'HASH';
  my @entries;
  for my $selector (sort keys %$value) {
    my $label = 'project_tools.'.$selector;
    my $names = $value->{$selector};
    my @tools = !defined $names       ? ()
              : ref $names eq 'ARRAY' ? @$names
              : ref $names            ? croak 'Invalid project_tools setting '.$label.': must be a list of tool names'
              :                         split /\s*,\s*/, $names;
    for my $name (@tools) {
      croak 'Invalid project_tools setting '.$label.': must be a list of tool names'
        if ref $name || !length($name // '');
    }
    push @entries, { selector => $selector, kind => $self->_selector_kind($selector, $label), tools => \@tools };
  }
  return \@entries;
}

sub _selector_kind {
  my ( $self, $selector, $label ) = @_;
  my $fail = sub { croak 'Invalid project_tools setting '.$label.': '.$_[0] };
  $fail->('empty workspace selector') unless length $selector;
  return 'all' if $selector eq '*';
  return 'path' if $selector =~ m{\A(?:/|~(?:/|\z))};
  $fail->('~user is not supported; start a path glob with / or ~/') if $selector =~ /\A~/;
  $fail->('a path glob must be absolute or start with ~/') if $selector =~ m{/};
  $fail->('a workspace name cannot hold * or ?; a path glob must be absolute or start with ~/') if $selector =~ /[*?]/;
  return 'workspace';
}


sub project_tools_matches {
  my ( $self ) = @_;
  my $root = path($self->root)->absolute;
  $root = $root->realpath if -e $root;
  return [ map { { %$_, $self->_match_selector($_, "$root") } } @{ $self->project_tools } ];
}

sub _match_selector {
  my ( $self, $entry, $root ) = @_;
  return ( matched => 1, reason => '* matches every project' ) if $entry->{kind} eq 'all';
  return ( matched => 0, reason => 'workspace names are not supported yet' ) if $entry->{kind} eq 'workspace';
  my $glob = $self->_selector_glob($entry->{selector});
  return ( matched => 0, reason => 'no home directory for ~' ) unless defined $glob;
  return $root =~ $self->_glob_regex($glob)
    ? ( matched => 1, reason => 'matches '.$root )
    : ( matched => 0, reason => $glob.' does not match '.$root );
}

# A path selector as an absolute glob: ~ expanded, trailing slashes
# dropped, the leading directories without a wildcard by their real path.
sub _selector_glob {
  my ( $self, $selector ) = @_;
  my $glob = $selector;
  if ($glob =~ /\A~/) {
    my $home = $self->home_class->home_dir;
    return unless defined $home;
    $glob = $home.substr($glob, 1);
  }
  $glob =~ s{(?<=.)/+\z}{};
  my @parts = split m{/}, $glob, -1;
  my $n = 0;
  $n++ while $n < @parts && $parts[$n] !~ /[*?]/;
  my $literal = join '/', @parts[0 .. $n - 1];
  if (length $literal && -e $literal) {
    my $real = path($literal)->realpath->stringify;
    $glob = $n < @parts ? join('/', $real eq '/' ? '' : $real, @parts[$n .. $#parts]) : $real;
  }
  return $glob;
}

# A glob as an anchored regex: ** any characters, * and ? without /,
# everything else literal.
sub _glob_regex {
  my ( $self, $glob ) = @_;
  my $re = join '', map {
    $_ eq '**' ? '.*' : $_ eq '*' ? '[^/]*' : $_ eq '?' ? '[^/]' : quotemeta
  } split /(\*\*|\*|\?)/, $glob;
  return qr/\A$re\z/;
}

# How explain lists a project_tools that is not read: at the top of a
# project file (only the home file grants), or inside a section of either
# file.
sub _ignored_project_tools {
  my ( $self, $layer, $top ) = @_;
  return { key => 'project_tools', reason => 'only ~/.raider/config.yml grants tools to projects; a project file cannot' }
    if $top;
  return { key => $layer.'.project_tools', reason => 'read only at the top level of ~/.raider/config.yml' };
}


sub normalize_skill_spec {
  my ( $self, $spec ) = @_;
  if (!ref $spec) {
    return (
      { type => 'file',   path => 'CLAUDE.md' },
      { type => 'claude', path => '.claude/skills' },
    ) if $spec eq 'claude';
    return { type => 'file', path => 'AGENTS.md' } if $PROFILE_KEYWORD{$spec};
    return { type => 'dir', path => $spec };
  }
  return $spec if ref $spec eq 'HASH';
  return;
}

sub _skill_items {
  my ( $self, $engine ) = @_;
  my @items;
  for my $layer (@{ $self->_resolve($engine)->{skills} }) {
    my $raw = $layer->{value};
    next unless defined $raw;
    push @items, ref $raw eq 'ARRAY' ? @$raw : ($raw);
  }
  return @items;
}

sub _spec_key {
  my ( $self, $spec ) = @_;
  return join "\0", map { $spec->{$_} // '' } qw( type path glob );
}


sub skill_specs {
  my ( $self, $engine, @cli ) = @_;
  my ( %seen, @specs );
  for my $spec (map { $self->normalize_skill_spec($_) } $self->_skill_items($engine), @cli) {
    push @specs, $spec unless $seen{ $self->_spec_key($spec) }++;
  }
  return @specs;
}


sub profiles {
  my ( $self, $engine ) = @_;
  my ( %seen, @profiles );
  for my $item ($self->_skill_items($engine)) {
    next if ref $item;
    my $profile = $PROFILE_KEYWORD{$item} or next;
    push @profiles, $profile unless $seen{$profile}++;
  }
  return @profiles;
}


sub explain {
  my ( $self, $engine ) = @_;
  my $r = $self->_resolve($engine);
  my @values = map {
    my $key = $_;
    {
      key        => $key,
      value      => $r->{value}{$key},
      source     => $r->{source}{$key},
      shadowed   => $r->{shadowed}{$key} // [],
      applies_to => $APP_KEY{$key} ? 'raider' : 'engine',
      ( $r->{merged_with} && $r->{merged_with}{$key} ? ( merged_with => $r->{merged_with}{$key} ) : () ),
    }
  } sort keys %{ $r->{value} };
  push @values, map {
    { key => 'skills', value => $_->{value}, source => $_->{source}, merged => 1, applies_to => 'raider' }
  } @{ $r->{skills} };
  return {
    file          => $self->file->stringify,
    exists        => $self->file_exists,
    label         => $self->label,
    ignored_files => [ $self->ignored_files ],
    ( $self->uses_home ? ( home_file => $self->home_file->stringify ) : () ),
    engine        => $engine,
    values        => \@values,
    ignored       => $r->{ignored},
    ( defined $self->_project_tools_data->{project_tools} ? ( project_tools => {
      file      => ( $self->uses_home ? $self->home_file : $self->file )->stringify,
      label     => $self->uses_home ? $self->home_label : $self->label,
      selectors => $self->project_tools_matches,
    } ) : () ),
  };
}

# The one writer: mutate the parsed data, write it back when the callback
# returns true, then re-read. Refuses (croaks) on a file that does not parse.
sub _update {
  my ( $self, $code ) = @_;
  my $data = $self->data;
  return unless $code->($data);
  $self->file->spew_utf8($self->_dump($data));
  $self->clear_data;
  return 1;
}

# The one YAML dump, for the project writers and update_home alike.
sub _dump { YAML::PP->new->dump_string($_[1]) }


sub update_home {
  my ( $self, $code ) = @_;
  my $file = $self->home_file;
  croak __PACKAGE__.'->update_home: there is no home directory' unless defined $file;
  my $data = $self->_load($file);
  return unless $code->($data);
  my $yaml = $self->_dump($data);
  my $dir  = $file->parent;
  unless ( -d $dir ) {
    $dir->mkpath( { mode => 0700 } );
    chmod 0700, $dir;
  }
  my $tmp = $dir->tempfile('.config.yml.XXXXXX');
  $tmp->spew_utf8($yaml);
  chmod 0600, $tmp;
  if ( -f $file ) {
    my $bak = $dir->child('config.yml.bak');
    $file->copy($bak);
    chmod 0600, $bak;
  }
  $tmp->move($file);
  $self->clear_data;
  $self->clear_home_data;
  $self->clear_uses_home;
  $self->clear_project_tools;
  return 1;
}


sub add_skills {
  my ( $self, @items ) = @_;
  my @added;
  $self->_update(sub {
    my ( $data ) = @_;
    my @have;
    # copy the values: a foreach alias would autovivify default: { skills: ~ }
    my @raw = ( $data->{skills}, ( ref $data->{default} eq 'HASH' ? $data->{default}{skills} : () ) );
    for my $raw (@raw) {
      next unless defined $raw;
      push @have, ref $raw eq 'ARRAY' ? @$raw : ($raw);
    }
    my %have = map { $self->_item_key($_) => 1 } @have;
    my @list = !defined $data->{skills} ? ()
             : ref $data->{skills} eq 'ARRAY' ? @{ $data->{skills} }
             : ($data->{skills});
    for my $item (@items) {
      next if $have{ $self->_item_key($item) }++;
      push @list, $item;
      push @added, $item;
    }
    return 0 unless @added;
    $data->{skills} = \@list;
    return 1;
  });
  return @added;
}

sub _item_key {
  my ( $self, $item ) = @_;
  return ref $item eq 'HASH' ? $self->_spec_key($item) : 'item:'.($item // '');
}


sub set_model {
  my ( $self, $model ) = @_;
  $self->_update(sub {
    my ( $data ) = @_;
    $data->{default} = {} unless ref $data->{default} eq 'HASH';
    $data->{default}{model} = $model;
    return 1;
  });
  return;
}


sub remove_api_keys {
  my ( $self, $data ) = @_;
  my @where;
  push @where, 'top' if exists $data->{api_key};
  delete $data->{api_key};
  my @sections = sort { ( $a ne 'default' ) <=> ( $b ne 'default' ) || $a cmp $b }
    grep { $self->_is_section($data, $_) } keys %$data;
  for my $section (@sections) {
    next unless exists $data->{$section}{api_key};
    delete $data->{$section}{api_key};
    push @where, $section;
  }
  return @where;
}


sub migration_content {
  my ( $self ) = @_;
  my $file = $self->legacy_file;
  my $want = $self->_load($file);
  my $text = -f $file ? $file->slurp_utf8 : '';
  my @where = $self->remove_api_keys($want);
  return { text => $text, api_keys => [], removed_lines => [], rewritten => 0 } unless @where;
  my @lines = split /^/m, $text;
  my ( @kept, @removed );
  for my $n (0 .. $#lines) {
    if ($lines[$n] =~ /\A[ \t]*api_key[ \t]*:(?:[ \t].*)?\r?\n?\z/) { push @removed, $n + 1 }
    else                                                           { push @kept, $lines[$n] }
  }
  my $stripped = join '', @kept;
  my $got = eval { YAML::PP->new->load_string($stripped) };
  $got = {} if !$@ && !defined $got;
  my $json = JSON::MaybeXS->new(canonical => 1, allow_nonref => 1, allow_blessed => 1, convert_blessed => 1);
  return { text => $stripped, api_keys => \@where, removed_lines => \@removed, rewritten => 0 }
    if ref $got eq 'HASH' && $json->encode($got) eq $json->encode($want);
  return { text => $self->_dump($want), api_keys => \@where, removed_lines => [], rewritten => 1 };
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Config - Internal resolver and writer for the project config file

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $config = Langertha::Raider::Config->new( root => $dir );

    my $engine  = $config->engine;                    # engine: from the file, or undef
    my $options = $config->engine_options('openai');  # for the engine constructor
    my @specs   = $config->skill_specs('openai');
    my $report  = $config->explain('openai');         # which value came from where

    my @added = $config->add_skills('claude');        # the one writer
    $config->set_model('gpt-4o');

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice; use
L<Langertha::Raider::CLI> instead.

The one place that reads and writes the project config of L</root>. The
file in use (L</file>) is F<.raider/config.yml> (ADR 0011) when it exists,
else the legacy F<.raider.yml>; both take the same keys. When both exist,
only F<.raider/config.yml> is loaded: the legacy file is not read and is
reported by L</ignored_files>.

Under the project file lies the home file F<~/.raider/config.yml> (ADR
0011; L</home_file>), with the same keys: default E<lt> home E<lt>
project E<lt> command line. Each file is read in three layers, later ones
winning:

=over

=item C<top> -- every top-level key whose value is not a hash (plus
C<skills>, C<detect> and C<project_tools>, which may be one)

=item C<default> -- the C<default:> section

=item the engine section -- the section named after the active engine
(C<openai:>, C<anthropic:>, ...)

=back

Every other top-level hash is the section of an engine that is not active.
C<skills> is merged across the layers instead of replaced. C<engine> is read
from C<top> and C<default> only, as it picks the engine section.

Then the project file's values are laid over the home file's, per key:

=over

=item C<skills> -- both files' lists, home first, duplicates dropped

=item C<no_detect> -- both files' pack names, home first, duplicates
dropped

=item C<detect> -- when both are maps, per pack: the project's entry for a
pack replaces the home's (ADR 0012); otherwise the project's value
replaces the home's

=item everything else, C<packs> and C<api_key> included -- the project's
value replaces the home's

=back

C<project_tools> is not layered at all: only the top level of the home
file grants tools to projects (L</project_tools>).

The project writers never touch the home file (L</update_home> is the only
one, with no caller yet). When the home file is the file in
use -- raider runs in the home directory itself -- it is read once, as the
project file, and there is no home layer.

A file, project or home, that does not parse, whose top level is not a mapping, or that holds
a mapping under one of raider's own keys other than C<skills>, C<detect> and C<project_tools>
(see L</is_app_key>) -- at top level or in any section, active or not -- is
an error: readers croak and the writer refuses to
overwrite it.

=head2 root

The project directory. Required.

=head2 file

L<Path::Tiny> of the file in use: L</native_file> when it exists, else
L</legacy_file>. Decided once, when first asked. The writers write here, so
without any file they create the legacy F<.raider.yml>, never
F<.raider/config.yml>; only C<raider config migrate>
(L<Langertha::Raider::Config::Migrate>, with L</migration_content>)
creates that.

=head2 home_file

L<Path::Tiny> of F<config.yml> in the user's F<~/.raider>
(L<Langertha::Raider::Home/home_base>), present or not; undef when there
is no home at all.

=head2 uses_home

True when L</home_file> is read as the home layer: it exists and is not
the file in use (L</file>, compared by real path). Decided once, when
first asked.

=head2 home_label

C<home>: how reports name the home file as a source.

=head2 native_file

L<Path::Tiny> of F<.raider/config.yml> in L</root>, present or not.

=head2 legacy_file

L<Path::Tiny> of F<.raider.yml> in L</root>, present or not.

=head2 is_native

True when L</file> is F<.raider/config.yml>.

=head2 label

The file in use relative to L</root>, C<.raider/config.yml> or
C<.raider.yml>: how reports name it as a source.

=head2 ignored_files

    for my $ign ($config->ignored_files) {
      warn 'ignoring '.$ign->{file}.': '.$ign->{reason}."\n";
    }

The config files that are present but not loaded, each as C<file>
(absolute path) and C<reason>: the legacy F<.raider.yml> while
F<.raider/config.yml> is in use. Empty otherwise.

=head2 data

The parsed file as a hash; empty when the file is missing or empty. Croaks
when the file does not parse, its top level is not a mapping, or a raider
key other than C<skills>, C<detect> and C<project_tools> holds a mapping,
at top level or in a section.

=head2 home_data

L</home_file> parsed like L</data>, croaking like it; empty unless
L</uses_home>.

=head2 file_exists

True when L</file> exists.

=head2 layer_label

    $config->layer_label('default');       # '.raider/config.yml default:'
    $config->layer_label('home openai');   # 'home openai:'

How reports name a layer of L</explain>: the label of its file (L</label>,
or L</home_label> for a C<home> layer), then the section and a colon
unless it is the top level.

=head2 value_label

    my $where = $config->value_label($engine_name, 'packs');   # 'home'

The label of the file the effective value of a key comes from:
L</home_label> when only the home file sets it, else L</label>.

=head2 detect_rule_label

    my $from = $config->detect_rule_label($engine_name, 'perl');   # 'home detect:'

Where the effective C<detect:> entry of a pack comes from: the label of
its file, as L</value_label>, and C<detect:>.

=head2 engine

The engine name from C<engine:> (top level or C<default:>), or undef.

=head2 options

    my $opts = $config->options($engine_name);

Every effective key except C<skills>, layered for C<$engine_name>.

=head2 engine_options

    my $opts = $config->engine_options($engine_name);

L</options> without raider's own keys (C<detect>, C<engine>, C<no_detect>,
C<packs>, C<perl>, C<preferred_lib_target>, C<project_tools>, C<skills>): what goes to the
engine constructor.

=head2 is_app_key

    $config->is_app_key('perl');   # 1

True for the keys that configure raider itself (C<detect>, C<engine>,
C<no_detect>, C<packs>, C<perl>, C<preferred_lib_target>, C<project_tools>,
C<skills>) and never reach the engine constructor.

=head2 detect_settings

    my $d = $config->detect_settings($engine_name);
    # { enabled => 1,
    #   rules   => { perl => { must => [ { file => 'cpanfile' } ] } },
    #   off     => { rust => 'no_detect', go => 'detect: go: false' } }

Pack detection (ADR 0012) as configured in the file: L</normalize_detect>
of the effective C<detect> and C<no_detect> values for C<$engine_name>.
Croaks on an invalid value or rule.

=head2 normalize_detect

    my $d = $config->normalize_detect($detect, $no_detect);

Checks and normalizes a C<detect> value -- a map of pack name to rule
(L<Langertha::Raider::Detect>) or C<false>, a pack name mapped to C<false>
switching detection off for that pack, the whole key C<false> switching
it off entirely -- and a C<no_detect> list of pack names (or a
comma-separated string). Returns C<enabled>, C<rules> and C<off> (pack name
to the reason) as in L</detect_settings>; croaks naming the offending key.

=head2 project_tools

    for my $entry (@{ $config->project_tools }) {
      # { selector => '~/dev/*', kind => 'path', tools => ['telegram'] }
    }

C<project_tools> of the home file (ADR 0011): which home tools and
services a project gets, as a map of workspace selector to a list of tool
names (or one comma-separated string). Only the top level of
F<~/.raider/config.yml> counts -- the home layer, or the file in use when
raider runs in the home directory itself. A project file cannot grant:
its C<project_tools>, like one inside a C<default:> or engine section of
either file, is not read and is listed as ignored by L</explain>.

The entries, sorted by selector, each with its C<kind>:

=over

=item C<all> -- the selector C<*>, every project

=item C<path> -- a path glob: absolute, or starting with C<~/> (C<~> is
the user's home). It is matched against the real path of L</root>, the
whole path: C<**> matches any characters, C<*> and C<?> any characters or
one character except C</>; everything else, C<[> and C<{> included, is
literal. A trailing C</> is dropped, so C<~/dev/*> matches F<~/dev/foo>
but not F<~/dev/foo/bar>, and C<~/dev/**> matches every directory below
F<~/dev>, not F<~/dev> itself. The leading directories without a wildcard
are resolved to their real path when they exist, so a symlink on the way
does not keep a glob from matching.

=item C<workspace> -- any other selector: a workspace name (ADR 0004).
Accepted, but never matched yet: raider has no workspace registry.

=back

Empty when the home file has no C<project_tools>. Croaks with C<Invalid
project_tools setting ...> naming the offending key when the value is not
a map, a selector holds no list of names, or a selector is C<~user>, a
relative path, or a name with a wildcard. Information only: nothing is
mounted from it yet (L</explain>).

=head2 normalize_project_tools

    my $entries = $config->normalize_project_tools($value);

Checks a C<project_tools> value and returns its entries as in
L</project_tools>; croaks like it.

=head2 project_tools_matches

    for my $m (@{ $config->project_tools_matches }) {
      # { selector => '~/dev/*', kind => 'path', tools => ['telegram'],
      #   matched => 1, reason => 'matches /home/me/dev/app' }
    }

The entries of L</project_tools>, each with whether it applies to
L</root> (C<matched>) and why (C<reason>). A workspace name never matches:
C<workspace names are not supported yet>.

=head2 normalize_skill_spec

    my @specs = $config->normalize_skill_spec($item);

Turns one C<skills:> item into skill-source hashes: C<claude> becomes
F<CLAUDE.md> plus F<.claude/skills>, C<openai> / C<codex> / C<agents> become
F<AGENTS.md>, any other string a markdown directory, a hash passes through.

=head2 skill_specs

    my @specs = $config->skill_specs($engine_name, @cli_specs);

The skill sources of every layer, then C<@cli_specs>, normalized and
deduplicated in that order.

=head2 profiles

    my @profiles = $config->profiles($engine_name);

The agent profiles (C<claude>, C<openai>) named in C<skills:>, in order.

=head2 explain

    my $report = $config->explain($engine_name);

Where each effective value came from:

    {
      file    => '/path/.raider/config.yml',
      exists  => 1,
      label   => '.raider/config.yml',
      ignored_files => [ { file => '/path/.raider.yml', reason => '...' } ],
      engine  => 'openai',
      values  => [
        { key => 'temperature', value => 0.7, source => 'openai',
          shadowed => ['default'], applies_to => 'engine' },
        { key => 'skills', value => ['claude'], source => 'top',
          merged => 1, applies_to => 'raider' },
      ],
      ignored => [ { key => 'anthropic', reason => 'section of an inactive engine' } ],
    }

C<source> is a layer (C<top>, C<default> or the engine name), for the
home file prefixed with C<home> (C<home top>, C<home default>, ...;
L</layer_label> names them); C<applies_to> says whether the value reaches
the engine constructor or configures raider itself. C<skills> gets one
entry per layer, as they merge. A C<no_detect> or C<detect> merged from
both files names the home layer it took values from in C<merged_with>.
C<file> is the file in use, C<label> its L</label> and C<ignored_files>
the L</ignored_files>; C<home_file> is L</home_file>, present only when
L</uses_home>.

C<project_tools> is present when the home file has one: C<file> and
C<label> of the file it was read from, and C<selectors>, the
L</project_tools_matches> -- information only, it mounts nothing. A
C<project_tools> that is not read (in a project file, or inside a section)
is listed in C<ignored>.

=head2 update_home

    $config->update_home(sub {
      my ( $data ) = @_;
      $data->{default}{model} = 'gpt-4o';
      return 1;             # true: write it
    });

Internal, no caller yet besides tests. The one writer of the home file
L</home_file>, shaped like the project writers: the callback gets the
parsed data of that file (empty when the file is absent), changes it in
place and returns true to have it written; false leaves the disk alone.
Returns true when it wrote.

Nothing but this method writes the home file. It creates F<~/.raider>
(mode 0700) and the file (mode 0600, the home file may hold an C<api_key>)
when absent. The new content is dumped first, written to a temporary file
next to the target and renamed over it, so a failure never leaves a partial
file; the previous file is kept as F<config.yml.bak>, one generation,
replaced by every write. A home file that does not parse (or whose
top level is no mapping) croaks like L</data> does and stays untouched.

When raider runs in the home directory itself, L</home_file> is the project
file: the same file is written, and the caches are dropped. Croaks when
there is no home at all.

=head2 add_skills

    my @added = $config->add_skills('claude', 'my-skills');

Appends the items not yet listed to the top-level C<skills:> list and writes
the file. Items already present at top level or in C<default:> are skipped.
Returns the items that were added.

=head2 set_model

    $config->set_model('gpt-4o');

Writes C<default: { model: ... }>, the shape the REPL's C</model> saves.

=head2 remove_api_keys

    my @where = $config->remove_api_keys($data);   # ('top', 'openai')

Deletes C<api_key> from the top level and from every section of the
parsed C<$data>, in place. Returns the layers it was in, named as in
L</explain> (C<top>, C<default>, the engine sections sorted).

=head2 migration_content

    my $m = $config->migration_content;
    # { text => "...", api_keys => ['top', 'openai'],
    #   removed_lines => [ 3, 9 ], rewritten => 0 }

The legacy F<.raider.yml> (L</legacy_file>) as the content of a
F<.raider/config.yml>, for C<raider config migrate>: the file as it is,
but without any C<api_key> (L</remove_api_keys>), because a project must
not choose a secret. The C<api_key> lines are dropped from the text, so
comments and layout stay, when what is left parses to exactly the data
without the keys; C<removed_lines> are their line numbers. Otherwise the
data without the keys is written anew (C<rewritten>), losing comments and
layout. Croaks like L</data> when the file does not parse; an absent file
gives an empty text.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::CLI>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
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

=cut
