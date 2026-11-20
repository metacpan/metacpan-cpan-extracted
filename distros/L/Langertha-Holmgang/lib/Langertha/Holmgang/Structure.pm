package Langertha::Holmgang::Structure;
# ABSTRACT: The shape checks of suite format 2, shared by the loader and the DSL

use Moose;
use namespace::autoclean;
use utf8;

use Digest::SHA ();
use JSON::MaybeXS ();
use Path::Tiny qw( path );
use Scalar::Util qw( blessed );
use Langertha::Holmgang::Case;
use Langertha::Holmgang::Error;
use Langertha::Holmgang::Excerpt;
use Langertha::Holmgang::Expectation ();
use Langertha::Holmgang::Haystack;
use Langertha::Holmgang::Simulators;
use Langertha::Holmgang::Target ();
use Langertha::Holmgang::ToolSchema qw( check_schema );
use Langertha::Holmgang::World;

our $VERSION = '0.002';

# true constants: the vocabulary of format 2
our @RULE_KINDS = qw( state unchanged_except calls not_called only_tools check packet login );
our @MATCHERS   = @Langertha::Holmgang::Expectation::MATCHERS;
our @MODIFIERS  = @Langertha::Holmgang::Expectation::MODIFIERS;
our @OPS        = @Langertha::Holmgang::World::OPS;
our @CASE_KEYS  = qw( id title tags difficulty scenario system messages state observe rules solution
  alternatives wrong_solutions temperature max_tokens max_turns source weight );
our @SUITE_KEYS = qw( format id version title description license defaults source tools topic threshold repeat );

# images on a user message (k27): at most this many per message, each at most
# this many bytes; true constants
our $IMAGES_PER_MESSAGE = 4;
our $IMAGE_MAX_BYTES    = 2 * 1024 * 1024;

my %SIMULATOR_PARAMS = ( run_command => [qw( host command )], write_file => [qw( host path content )] );
my %HOOK = map { $_ => 1 } qw( prerouting input forward output postrouting );
my %L4   = map { $_ => 1 } qw( tcp udp icmp icmpv6 );

my $ID_RE   = qr/\A[a-z0-9][a-z0-9-]{0,63}\z/;
my $TOOL_RE = qr/\A[A-Za-z_][A-Za-z0-9_-]{0,63}\z/;


has simulators => (
  is      => 'ro',
  lazy    => 1,
  builder => '_build_simulators',
);
sub _build_simulators { Langertha::Holmgang::Simulators->new }


has haystack => (
  is      => 'ro',
  lazy    => 1,
  builder => '_build_haystack',
);
sub _build_haystack { Langertha::Holmgang::Haystack->new }


has excerpt => (
  is      => 'ro',
  lazy    => 1,
  builder => '_build_excerpt',
);
sub _build_excerpt { Langertha::Holmgang::Excerpt->new }


sub _refuse {
  my ( $self, $field, $reason ) = @_;
  Langertha::Holmgang::Error->throw( $field, $reason );
}

sub valid_id {
  my ( $self, $id ) = @_;
  return defined $id && !ref $id && $id =~ $ID_RE ? 1 : 0;
}


#### Small checks

sub _keys_ok {
  my ( $self, $h, $field, @ok ) = @_;
  $self->_refuse( $field, 'not a hash' ) unless ref $h eq 'HASH';
  my %ok = map { $_ => 1 } @ok;
  for my $k ( sort keys %$h ) {
    $self->_refuse( $field.'.'.$k, 'unknown key' ) unless $ok{$k};
  }
  return;
}

sub _text {
  my ( $self, $v, $field, $optional ) = @_;
  return undef if $optional && !defined $v;
  $self->_refuse( $field, 'text missing' ) if !defined $v || ref $v || !length $v;
  return "$v";
}

sub _num {
  my ( $self, $v, $field, $min, $max ) = @_;
  $self->_refuse( $field, 'not a number' ) if !defined $v || ref $v || $v !~ /\A-?(?:\d+\.?\d*|\.\d+)\z/;
  $self->_refuse( $field, 'outside '.$min.'..'.$max ) if $v < $min || defined $max && $v > $max;
  return 0 + $v;
}

sub _regex {
  my ( $self, $v, $field ) = @_;
  $self->_text( $v, $field );
  $self->_refuse( $field, 'invalid regular expression' ) unless eval { qr/$v/; 1 };
  return "$v";
}

# a mark true/false (missing = false)
sub _flag {
  my ( $self, $v, $field ) = @_;
  return 0 unless defined $v;
  $self->_refuse( $field, 'true or false' )
    if ref $v ? !JSON::MaybeXS::is_bool($v) : !grep { $v eq $_ } '1', '0', '';
  return $v ? 1 : 0;
}

sub _list {
  my ( $self, $v, $field, $nonempty ) = @_;
  $self->_refuse( $field, 'not a list' ) unless ref $v eq 'ARRAY';
  $self->_refuse( $field, 'empty list' ) if $nonempty && !@$v;
  return $v;
}

sub _scalars {
  my ( $self, $v, $field ) = @_;
  $self->_list( $v, $field, 1 );
  $self->_refuse( $field, 'list of values expected' ) if grep { !defined || ref } @$v;
  return $v;
}

# a path: dotted text or a list of segments
sub _path {
  my ( $self, $p, $field ) = @_;
  if ( ref $p eq 'ARRAY' ) {
    $self->_refuse( $field, 'empty path' ) unless @$p;
    $self->_refuse( $field, 'segments must be text' ) if grep { !defined || ref || !length } @$p;
    return $p;
  }
  $self->_text( $p, $field );
  $self->_refuse( $field, 'path with an empty segment' ) if grep { !length } split /\./, $p, -1;
  return $p;
}

sub _arg_patterns {
  my ( $self, $m, $field ) = @_;
  $self->_refuse( $field, 'not a hash' ) unless ref $m eq 'HASH';
  $self->_regex( $m->{$_}, $field.'.'.$_ ) for sort keys %$m;
  return $m;
}

# a pattern for a list element: a regex (text) or a hash field -> regex | expectations
sub _element {
  my ( $self, $m, $field ) = @_;
  return $self->_regex( $m, $field ) unless ref $m;
  $self->_refuse( $field, 'pattern (text) or hash field -> pattern expected' ) unless ref $m eq 'HASH' && %$m;
  for my $f ( sort keys %$m ) {
    ref $m->{$f} ? $self->_matchers( $m->{$f}, $field.'.'.$f, 1 ) : $self->_regex( $m->{$f}, $field.'.'.$f );
  }
  return $m;
}

# expectations on a value (Expectation::condition); with $bare without path
sub _matchers {
  my ( $self, $c, $field, $bare ) = @_;
  $self->_keys_ok( $c, $field, ( $bare ? () : 'path' ), @MATCHERS, @MODIFIERS );
  $self->_path( $c->{path}, $field.'.path' ) unless $bare;
  if ( exists $c->{tolerance} ) {    # k49: qualifies a numeric equals
    $self->_refuse( $field.'.tolerance', 'needs equals' ) unless exists $c->{equals};
    my $num = qr/\A-?(?:\d+\.?\d*|\.\d+)\z/;
    my ( $e, $t ) = @$c{qw( equals tolerance )};
    $self->_refuse( $field.'.equals', 'number expected beside tolerance' ) if !defined $e || ref $e || $e !~ $num;
    $self->_refuse( $field.'.tolerance', 'number of 0 or more expected' ) if !defined $t || ref $t || $t !~ $num || $t < 0;
  }
  my @m = grep { exists $c->{$_} } @MATCHERS;
  $self->_refuse( $field, 'no expectation ('.join( ', ', @MATCHERS ).')' ) unless @m;
  for my $k ( @m ) {
    my $v = $c->{$k};
    if    ( $k eq 'exists' || $k eq 'absent' ) { }
    elsif ( $k eq 'equals' ) { $self->_refuse( $field.'.equals', 'value expected' ) if !defined $v || ref $v }
    elsif ( $k eq 'in' || $k eq 'contains' || $k eq 'excludes' ) { $self->_scalars( $v, $field.'.'.$k ) }
    elsif ( $k eq 'regex' )  { $self->_regex( $v, $field.'.regex' ) }
    elsif ( $k eq 'length' ) { $self->_num( $v, $field.'.length', 0, 100_000 ) }
    elsif ( $k eq 'any' || $k eq 'none' ) { $self->_element( $v, $field.'.'.$k ) }
    else {    # before
      $self->_refuse( $field.'.before', 'exactly two patterns' ) unless ref $v eq 'ARRAY' && @$v == 2;
      $self->_element( $v->[$_], $field.'.before['.$_.']' ) for 0, 1;
    }
  }
  return $c;
}

sub _op {
  my ( $self, $o, $field ) = @_;
  $self->_refuse( $field, 'not a hash' ) unless ref $o eq 'HASH';
  my @kind = grep { exists $o->{$_} } @OPS;
  $self->_refuse( $field, 'exactly one change ('.join( ', ', @OPS ).')' ) unless @kind == 1;
  my $kind = $kind[0];
  my %need = ( set => ['value'], push => ['value'], insert => [qw( at value )], delete => [],
    remove => ['where'], move => [qw( from to )] );
  $self->_keys_ok( $o, $field, $kind, @{ $need{$kind} } );
  exists $o->{$_} or $self->_refuse( $field.'.'.$_, 'missing' ) for @{ $need{$kind} };
  $self->_path( $o->{$kind}, $field.'.'.$kind );
  $self->_element( $o->{where}, $field.'.where' ) if exists $o->{where};
  return $o;
}

sub _handler {
  my ( $self, $h, $field, @keys ) = @_;
  $self->_keys_ok( $h, $field, @keys ? @keys : qw( match when apply output error ) );
  $self->_arg_patterns( $h->{match} // {}, $field.'.match' );
  my $when = $self->_list( $h->{when} // [], $field.'.when' );
  $self->_matchers( $when->[$_], $field.'.when['.$_.']' ) for 0 .. $#$when;
  my $apply = $self->_list( $h->{apply} // [], $field.'.apply' );
  $self->_op( $apply->[$_], $field.'.apply['.$_.']' ) for 0 .. $#$apply;
  $self->_text( $h->{output}, $field.'.output', 1 ) unless @keys;
  return $h;
}

#### Suite head and tools

sub tool {
  my ( $self, $t, $field ) = @_;
  $self->_keys_ok( $t, $field, qw( name description parameters handlers simulator ) );
  my $name = $t->{name} // '';
  $self->_refuse( $field.'.name', 'invalid tool name' ) unless !ref $name && $name =~ $TOOL_RE;
  my $params = $t->{parameters} // { type => 'object', properties => {} };
  $self->_refuse( $field.'.parameters', 'JSON Schema (type: object) expected' )
    unless ref $params eq 'HASH' && ( $params->{type} // '' ) eq 'object';
  check_schema( $params, $field.'.parameters' );
  $self->_text( $t->{description}, $field.'.description' );
  if ( defined( my $sim = $t->{simulator} ) ) {
    my $sims  = $self->simulators;
    my $world = !ref $sim && !$SIMULATOR_PARAMS{$sim} ? $sims->world_tools($sim) : undef;
    $self->_refuse( $field.'.simulator', 'run_command, write_file or an answer world ('
      .join( ', ', grep { $sims->world_tools($_) } $sims->types ).')' )
      unless !ref $sim && ( $SIMULATOR_PARAMS{$sim} || $world );
    $self->_refuse( $field.'.handlers', 'simulator or handlers, not both' ) if exists $t->{handlers};
    $self->_refuse( $field.'.name', 'the world '.$sim.' has no tool '.$name.' ('.join( ', ', sort keys %$world ).')' )
      if $world && !$world->{$name};
    for my $p ( @{ $world ? $world->{$name} : $SIMULATOR_PARAMS{$sim} } ) {
      $self->_refuse( $field.'.parameters', 'required parameter '.$p.' missing' )
        unless grep { $_ eq $p } @{ $params->{required} || [] };
    }
  }
  else {
    my $hs = $self->_list( $t->{handlers}, $field.'.handlers', 1 );
    $self->_handler( $hs->[$_], $field.'.handlers['.$_.']' ) for 0 .. $#$hs;
  }
  return $t;
}


sub suite_head {
  my ( $self, $head, %o ) = @_;
  $self->_refuse( 'suite.yaml', 'not a hash' ) unless ref $head eq 'HASH';
  if ( exists $o{format} || exists $head->{format} ) {
    my $format = $head->{format} // '';
    $self->_refuse( 'format', 'format 1 (judge and rubric) is not read any more — format 2: end state and rules' )
      if $format eq '1';
    $self->_refuse( 'format', 'only format 2 is known' ) unless $format eq '2';
  }
  $self->_keys_ok( $head, 'suite.yaml', @SUITE_KEYS );
  my %out;
  if ( defined( my $t = $head->{threshold} ) ) {
    $self->_keys_ok( $t, 'threshold', qw( pass_rate pass_k ) );
    $self->_refuse( 'threshold', 'pass_rate or pass_k (0..1) expected' ) unless exists $t->{pass_rate} || exists $t->{pass_k};
    $self->_num( $t->{$_}, 'threshold.'.$_, 0, 1 ) for grep { exists $t->{$_} } qw( pass_rate pass_k );
    $out{threshold} = { map { $_ => 0 + $t->{$_} } grep { exists $t->{$_} } qw( pass_rate pass_k ) };
  }
  my $repeat = $head->{repeat};
  $self->_refuse( 'repeat', 'integer 1..100 (runs per suite)' )
    if defined $repeat && ( ref $repeat || $repeat !~ /\A[1-9]\d{0,2}\z/ || $repeat > 100 );
  $out{repeat} = 0 + $repeat if defined $repeat;
  if ( defined $head->{topic} ) {
    $self->_refuse( 'topic', 'topic as an id ([a-z0-9-])' ) unless $self->valid_id( $head->{topic} );
    $out{topic} = $head->{topic};
  }
  my @tools;
  if ( defined $head->{tools} ) {
    my $l = $self->_list( $head->{tools}, 'suite.yaml: tools' );
    my %seen;
    for my $i ( 0 .. $#$l ) {
      my $tool = $self->tool( $l->[$i], 'suite.yaml: tools['.$i.']' );
      $self->_refuse( 'suite.yaml: tools', 'tool '.$tool->{name}.' twice' ) if $seen{ $tool->{name} }++;
      push @tools, $tool;
    }
  }
  my $id = $head->{id};
  if ( defined $o{dirname} ) {
    $self->_refuse( 'id', "must be '".$o{dirname}."' (the directory)" )
      unless !ref $id && ( $id // '' ) eq $o{dirname} && $self->valid_id( $o{dirname} );
  }
  else {
    $self->_refuse( 'id', 'invalid id' ) unless $self->valid_id($id);
  }
  my $version = $head->{version};
  $self->_refuse( 'version', 'integer >= 1' ) unless defined $version && !ref $version && $version =~ /\A[1-9]\d{0,5}\z/;
  my $defaults = $head->{defaults} // {};
  $self->_keys_ok( $defaults, 'defaults', qw( system temperature max_tokens max_turns ) );
  $self->_text( $head->{title}, 'title' );
  $self->_text( $head->{$_}, $_, 1 ) for qw( description license );
  $self->_source( $head->{source}, 'source' );
  return (
    %out,
    id       => $id,
    version  => 0 + $version,
    title    => $head->{title},
    defaults => $defaults,
    tools    => \@tools,
    ( map { defined $head->{$_} ? ( $_ => $head->{$_} ) : () } qw( description license source ) ),
  );
}


sub _source {
  my ( $self, $src, $field ) = @_;
  return unless defined $src;
  $self->_keys_ok( $src, $field, qw( title authors license url location ) );
  $self->_text( $src->{title}, $field.'.title' );
  $self->_text( $src->{$_}, $field.'.'.$_, 1 ) for qw( authors license url location );
  return $src;
}

#### Generated content

sub generated {
  my ( $self, $data, $f, %o ) = @_;
  my @out;
  return @out unless ref $data eq 'HASH';
  my $put = sub {
    my ( $v, $field ) = @_;
    return unless ref $v eq 'HASH' || ref $v eq 'ARRAY';
    push @out, [ $field, $self->haystack->resolve( $v, $field ) ];
  };
  if ( ref $data->{messages} eq 'ARRAY' ) {
    my $i = 0;
    for my $m ( @{ $data->{messages} } ) {
      my $field = $f.': messages['.$i.'].content';
      $put->( $self->excerpt->expand( $m->{content}, $field, $o{dir} ), $field ) if ref $m eq 'HASH';
      $i++;
    }
  }
  return @out unless ref $data->{state} eq 'HASH';
  for my $dev ( sort keys %{ $data->{state} } ) {
    my $files = ref $data->{state}{$dev} eq 'HASH' ? $data->{state}{$dev}{files} : undef;
    next unless ref $files eq 'HASH';
    for my $p ( sort keys %$files ) {
      $put->( $files->{$p}{content}, $f.': state.'.$dev.'.files.'.$p.'.content' ) if ref $files->{$p} eq 'HASH';
    }
  }
  return @out;
}


#### Cases

sub case {
  my ( $self, $data, %o ) = @_;
  my $f = defined $o{file} ? 'cases/'.$o{file} : $o{field} // 'case';
  $self->_keys_ok( $data, $f, @CASE_KEYS );
  my $id = $data->{id} // '';
  if ( defined $o{file} ) {
    ( my $want = $o{file} ) =~ s/\.yaml\z//;
    $self->_refuse( $f.': id', "must be '".$want."' (the file name)" ) unless !ref $id && $id eq $want;
  }
  $self->_refuse( $f.': id', 'invalid id' ) unless $self->valid_id($id);

  # messages
  $self->_refuse( $f.': messages', 'list missing' ) unless ref $data->{messages} eq 'ARRAY' && @{ $data->{messages} };
  my ( @prompt, %images );
  my $i = 0;
  for my $m ( @{ $data->{messages} } ) {
    my $mf = $f.': messages['.$i.']';
    $self->_keys_ok( $m, $mf, qw( role content untrusted images ) );
    $self->_flag( $m->{untrusted}, $mf.'.untrusted' );
    my $role = $m->{role} // '';
    $self->_refuse( $mf.'.role', 'user or assistant (the system prompt goes under system:)' )
      unless $role eq 'user' || $role eq 'assistant';
    my $content = $self->excerpt->expand( $m->{content}, $mf.'.content', $o{dir} );
    $content = $self->haystack->resolve( $content, $mf.'.content' ) if ref $content;
    $content = $self->_text( $content, $mf.'.content' );
    if ( exists $m->{images} ) {
      $self->_refuse( $mf.'.images', 'only on a user message' ) unless $role eq 'user';
      my @parts = map { $self->_image( $_, $o{dir}, \%images ) } $self->_image_list( $m->{images}, $mf.'.images' );
      $content = [ { type => 'text', text => $content }, @parts ];
    }
    push @prompt, { role => $role, content => $content };
    $i++;
  }
  $self->_refuse( $f.': messages', 'the last message must be from the user' ) unless $prompt[-1]{role} eq 'user';

  # state, prepared once to check it
  my $initial = $self->_state( $data->{state}, $f.': state' );

  my @tools = sort { $a->{name} cmp $b->{name} } @{ $o{tools} || [] };
  $self->_refuse( $f.': tools', 'the suite offers no tools (suite.yaml: tools)' ) unless @tools;
  my %tools = map { $_->{name} => 1 } @tools;

  my $ol = $self->_list( $data->{observe} // [], $f.': observe' );
  $self->_observe( $ol->[$_], $f.': observe['.$_.']' ) for 0 .. $#$ol;

  my $rl = $self->_list( $data->{rules}, $f.': rules', 1 );
  my @kinds = map { $self->_rule( $rl->[$_], $f.': rules['.$_.']', \%tools, $data->{state} ) } 0 .. $#$rl;
  my @required = map { $kinds[$_] } grep { _required( $rl->[$_] ) } 0 .. $#$rl;
  $self->_refuse( $f.': rules', 'at least one required rule' ) unless @required;
  # the "no tool" family: doing nothing is right. An empty solution only with the
  # required rule only_tools: [] — then lint checks that every wrong solution fails.
  my $nothing = ref $data->{solution} eq 'ARRAY' && !@{ $data->{solution} };
  $self->_refuse( $f.': solution', 'empty only with the required rule only_tools: [] (the "no tool" family)' )
    if $nothing && !grep { _required( $_ ) && exists $_->{only_tools} && ref $_->{only_tools} eq 'ARRAY' && !@{ $_->{only_tools} } } @$rl;
  # a check command runs on the end state and so checks it too
  $self->_refuse( $f.': rules', 'at least one required rule on the end state (state, check, packet or login)' )
    unless $nothing || grep { /\A(?:state|check|packet|login)\z/ } @required;

  for my $k (qw( alternatives wrong_solutions )) {
    next if $nothing && $k eq 'alternatives' && !exists $data->{$k};
    my $wl = $self->_list( $data->{$k}, $f.': '.$k, 1 );
    for my $j ( 0 .. $#$wl ) {
      my $wf = $f.': '.$k.'['.$j.']';
      $self->_keys_ok( $wl->[$j], $wf, qw( title calls ) );
      $self->_text( $wl->[$j]{title}, $wf.'.title' );
      $self->_calls( $wl->[$j]{calls}, $wf.'.calls', \%tools );
    }
  }

  my $tags = $data->{tags} // [];
  $self->_refuse( $f.': tags', 'not a list of texts' ) unless ref $tags eq 'ARRAY' && !grep { ref } @$tags;
  my $difficulty = $data->{difficulty};
  $self->_refuse( $f.': difficulty', 'leicht, mittel or schwer' )
    if defined $difficulty && !grep { $difficulty eq $_ } qw( leicht mittel schwer );
  my $scenario = $data->{scenario};
  $self->_refuse( $f.': scenario', 'an id of [a-z0-9-]' )
    if defined $scenario && ( ref $scenario || $scenario !~ /\A[a-z0-9][a-z0-9-]*\z/ );

  my $defaults = $o{defaults} || {};
  my %range = ( temperature => [ 0, 2 ], max_tokens => [ 1, 200_000 ], max_turns => [ 1, 50 ] );
  for my $k ( sort keys %range ) {
    next unless exists $data->{$k} || exists $defaults->{$k};
    $self->_num( exists $data->{$k} ? $data->{$k} : $defaults->{$k}, $f.': '.$k, @{ $range{$k} } );
  }
  $self->_num( $data->{weight}, $f.': weight', 0 ) if exists $data->{weight};
  $self->_refuse( $f.': weight', 'a positive number' ) if exists $data->{weight} && $data->{weight} <= 0;
  $self->_text( $data->{title}, $f.': title' );
  $self->_text( $data->{system} // $defaults->{system}, $f.': system', 1 );
  $self->_calls( $data->{solution}, $f.': solution', \%tools ) unless $nothing;
  $self->_source( $data->{source}, $f.': source' );

  return Langertha::Holmgang::Case->new(
    ( map { exists $data->{$_} ? ( $_ => $data->{$_} ) : () } @CASE_KEYS ),
    tools           => \@tools,
    defaults        => $defaults,
    simulators      => $self->simulators,
    haystack        => $self->haystack,
    initial_state   => $initial,
    prompt_messages => \@prompt,
    image_files     => \%images,
  );
}


#### Images (k27)

sub _image_list {
  my ( $self, $v, $field ) = @_;
  $self->_list( $v, $field, 1 );
  $self->_refuse( $field, 'at most '.$IMAGES_PER_MESSAGE.' images per message' ) if @$v > $IMAGES_PER_MESSAGE;
  return map { [ $v->[$_], $field.'['.$_.']' ] } 0 .. $#$v;
}

# one image of a user message: checked, measured, recorded in %$seen by its
# file; returns the placeholder that stands for it in the prompt messages
sub _image {
  my ( $self, $entry, $dir, $seen ) = @_;
  my ( $img, $field ) = @$entry;
  $self->_keys_ok( $img, $field, qw( file untrusted ) );
  $self->_flag( $img->{untrusted}, $field.'.untrusted' );
  my $file = $self->_text( $img->{file}, $field.'.file' );
  my $info = $seen->{$file} //= $self->image_file( $dir, $file, $field.'.file' );
  return { image => $file, sha256 => $info->{sha256}, bytes => $info->{bytes} };
}

sub image_file {
  my ( $self, $dir, $file, $field ) = @_;
  $field //= 'image';
  $self->_refuse( $field, 'an image needs the suite directory to be read from' ) unless defined $dir && length $dir;
  $self->_refuse( $field, 'a path relative to the suite directory, without .. or an empty segment' )
    if $file =~ m{\A/|\\} || grep { $_ eq '..' || $_ eq '' } split m{/}, $file, -1;
  my $root = eval { path($dir)->realpath };
  $self->_refuse( $field, 'suite directory not readable: '.$dir ) unless $root && $root->is_dir;
  my $p = path( $root, $file );
  $self->_refuse( $field, 'no such file in the suite' ) unless -e $p;
  my $real = eval { $p->realpath };
  $self->_refuse( $field, 'outside the suite directory' ) unless $real && $root->subsumes($real);
  $self->_refuse( $field, 'not a plain file' ) unless -f $real;
  my $size = -s _;
  $self->_refuse( $field, 'larger than '.$IMAGE_MAX_BYTES.' bytes ('.$size.')' ) if $size > $IMAGE_MAX_BYTES;
  my $bytes = eval { $real->slurp_raw };
  $self->_refuse( $field, 'not readable' ) unless defined $bytes;
  $self->_refuse( $field, 'larger than '.$IMAGE_MAX_BYTES.' bytes ('.length($bytes).')' ) if length $bytes > $IMAGE_MAX_BYTES;
  my ( $type, $w, $h ) = image_measure($bytes);
  $self->_refuse( $field, 'not a PNG or JPEG image (by its first bytes)' ) unless $type;
  $self->_refuse( $field, 'a '.$type.' whose width and height cannot be read' ) unless $w && $h;
  return {
    file       => $file,
    path       => "$real",
    media_type => $type,
    width      => $w,
    height     => $h,
    bytes      => length $bytes,
    sha256     => Digest::SHA::sha256_hex($bytes),
  };
}


# ( media type, width, height ) of PNG or JPEG bytes by their magic; the media
# type alone when the size cannot be read, the empty list for anything else
sub image_measure {
  my ( $bytes ) = @_;
  if ( substr( $bytes, 0, 8 ) eq "\x89PNG\r\n\x1a\n" ) {
    return ('image/png') unless length $bytes >= 24 && substr( $bytes, 12, 4 ) eq 'IHDR';
    return ( 'image/png', unpack 'NN', substr( $bytes, 16, 8 ) );
  }
  if ( substr( $bytes, 0, 3 ) eq "\xFF\xD8\xFF" ) {
    my $at = 2;
    my $n  = length $bytes;
    while ( $at + 4 <= $n ) {
      return ('image/jpeg') unless substr( $bytes, $at, 1 ) eq "\xFF";
      my $marker = ord substr( $bytes, $at + 1, 1 );
      if ( $marker == 0xFF ) { $at++; next }                                   # fill byte
      if ( $marker == 0x01 || ( $marker >= 0xD0 && $marker <= 0xD8 ) ) { $at += 2; next }   # no length
      last if $marker == 0xD9 || $marker == 0xDA;                              # end, scan data
      my $len = unpack 'n', substr( $bytes, $at + 2, 2 );
      if ( $marker >= 0xC0 && $marker <= 0xCF && $marker != 0xC4 && $marker != 0xC8 && $marker != 0xCC ) {
        last unless $at + 9 <= $n;
        my ( $h, $w ) = unpack 'nn', substr( $bytes, $at + 5, 4 );
        return ( 'image/jpeg', $w, $h );
      }
      $at += 2 + $len;
    }
    return ('image/jpeg');
  }
  return;
}


sub _required { my ( $r ) = @_; return !exists $r->{required} || $r->{required} ? 1 : 0 }

# an observation: answer to a diagnostic command, may depend on the state, never changes it
sub _observe {
  my ( $self, $h, $field ) = @_;
  $self->_keys_ok( $h, $field, qw( match when output error ) );
  $self->_refuse( $field.'.match', 'host and command as patterns' ) unless ref $h->{match} eq 'HASH' && $h->{match}{command};
  $self->_refuse( $field.'.output', 'text expected (may be empty)' ) if !defined $h->{output} || ref $h->{output};
  $self->_handler( $h, $field, qw( match when output error ) );
  return $h;
}

# the state: devices (hashes with type) need a known simulator; generated file contents
# resolved, then prepared — the case's initial state
sub _state {
  my ( $self, $state, $field ) = @_;
  $self->_refuse( $field, 'hash (the state of the world) missing' ) unless ref $state eq 'HASH' && %$state;
  my %types = map { $_ => 1 } $self->simulators->types;
  for my $k ( sort keys %$state ) {
    next unless ref $state->{$k} eq 'HASH' && exists $state->{$k}{type};
    $self->_refuse( $field.'.'.$k.'.type', 'device type '.join( ', ', sort keys %types ) ) unless $types{ $state->{$k}{type} // '' };
  }
  $self->_plain( $state->{$_}, $field.'.'.$_ ) for sort keys %$state;
  my $s = Langertha::Holmgang::World->clone($state);
  for my $dev ( sort keys %$s ) {
    my $files = ref $s->{$dev} eq 'HASH' ? $s->{$dev}{files} : undef;
    next unless ref $files eq 'HASH';
    for my $p ( sort keys %$files ) {
      my $e = $files->{$p};
      next unless ref $e eq 'HASH' && ref $e->{content};
      $e->{content} = $self->haystack->resolve( $e->{content}, $field.'.'.$dev.'.files.'.$p.'.content' );
    }
  }
  eval { $self->simulators->prepare($s); 1 } or do {
    my $err = $@;
    die $err if Langertha::Holmgang::Error->caught($err);
    $self->_refuse( $field, "$err" =~ s/\s+\z//r );
  };
  return $s;
}

# plain data only (k59): what the world's copy and the YAML export take
sub _plain {
  my ( $self, $v, $field ) = @_;
  my $r = ref $v;
  return unless $r;
  return if blessed $v && $v->isa('JSON::PP::Boolean');
  if ( $r eq 'HASH' ) {
    $self->_plain( $v->{$_}, $field.'.'.$_ ) for sort keys %$v;
    return;
  }
  if ( $r eq 'ARRAY' ) {
    $self->_plain( $v->[$_], $field.'['.$_.']' ) for 0 .. $#$v;
    return;
  }
  $self->_refuse( $field, 'not data: '.( $r eq 'CODE' ? 'a code reference' : 'a '.$r.' reference' )
    .' (the state holds texts, numbers, booleans, hashes and lists)' );
}

sub _call {
  my ( $self, $c, $field, $tools, $with_args ) = @_;
  $self->_keys_ok( $c, $field, qw( tool args ) );
  my $tool = $self->_text( $c->{tool}, $field.'.tool' );
  $self->_refuse( $field.'.tool', "the case offers no tool '".$tool."'" ) unless $tools->{$tool};
  my $args = $c->{args} // {};
  $self->_refuse( $field.'.args', 'not a hash' ) unless ref $args eq 'HASH';
  $self->_arg_patterns( $args, $field.'.args' ) unless $with_args;
  return $c;
}

sub _calls {
  my ( $self, $l, $field, $tools ) = @_;
  $self->_list( $l, $field, 1 );
  $self->_call( $l->[$_], $field.'['.$_.']', $tools, 1 ) for 0 .. $#$l;
  return $l;
}

# one rule; returns its kind
sub _rule {
  my ( $self, $r, $field, $tools, $state ) = @_;
  $self->_refuse( $field, 'not a hash' ) unless ref $r eq 'HASH';
  my @kind = grep { exists $r->{$_} } @RULE_KINDS;
  $self->_refuse( $field, 'exactly one kind: '.join( ', ', @RULE_KINDS ) ) unless @kind == 1;
  my $kind = $kind[0];
  $self->_text( $r->{title}, $field.'.title' );
  my %rest = %$r;
  delete @rest{qw( title required )};
  if ( $kind eq 'state' ) {
    my $path = delete $rest{state};
    $self->_matchers( { %rest, path => $path }, $field );
  }
  elsif ( $kind eq 'check' ) {
    $self->_check_rule( \%rest, $field, $state );
  }
  elsif ( $kind eq 'login' ) {
    $self->_keys_ok( \%rest, $field, qw( login result ) );
    my $l = $r->{login};
    $self->_keys_ok( $l, $field.'.login', qw( host user from key port iif daddr auth ) );
    $self->_text( $l->{$_}, $field.'.login.'.$_ ) for qw( host user from );
    for my $k (qw( key iif daddr )) { $self->_text( $l->{$k}, $field.'.login.'.$k ) if defined $l->{$k} }
    if ( defined $l->{port} ) {
      $self->_refuse( $field.'.login.port', 'port 1-65535' )
        unless !ref $l->{port} && $l->{port} =~ /\A\d+\z/ && $l->{port} >= 1 && $l->{port} <= 65535;
    }
    my $auth = $l->{auth} // ( defined $l->{key} ? 'publickey' : '' );
    $self->_refuse( $field.'.login.auth', 'publickey (with key) or password' )
      unless $auth eq 'password' || ( $auth eq 'publickey' && defined $l->{key} );
    my $v = $r->{result} // '';
    $self->_refuse( $field.'.result', 'allowed or denied' ) unless !ref $v && ( $v eq 'allowed' || $v eq 'denied' );
  }
  elsif ( $kind eq 'packet' ) {
    $self->_keys_ok( \%rest, $field, qw( packet verdict boot ) );
    $self->_packet( $r->{packet}, $field.'.packet' );
    my $v = $r->{verdict} // '';
    $self->_refuse( $field.'.verdict', 'accept or drop' ) unless !ref $v && ( $v eq 'accept' || $v eq 'drop' );
    if ( my $b = $r->{boot} ) {
      $self->_refuse( $field.'.boot', 'true or an absolute path' ) unless !ref $b || "$b" eq '1';
    }
  }
  else {
    $self->_keys_ok( \%rest, $field, $kind );
    if ( $kind eq 'unchanged_except' ) {
      my $p = $self->_list( $r->{unchanged_except}, $field.'.unchanged_except' );
      $self->_path( $p->[$_], $field.'.unchanged_except['.$_.']' ) for 0 .. $#$p;
    }
    elsif ( $kind eq 'only_tools' ) {
      my $l = $self->_list( $r->{only_tools}, $field.'.only_tools' );
      for my $i ( 0 .. $#$l ) {
        my $t = $l->[$i];
        $self->_refuse( $field.'.only_tools['.$i.']', "the case offers no tool '".( $t // '' )."'" )
          unless defined $t && !ref $t && $tools->{$t};
      }
    }
    elsif ( $kind eq 'calls' ) {
      my $l = $self->_list( $r->{calls}, $field.'.calls', 1 );
      $self->_call( $l->[$_], $field.'.calls['.$_.']', $tools ) for 0 .. $#$l;
    }
    else {
      $self->_call( $r->{not_called}, $field.'.not_called', $tools );
    }
  }
  return $kind;
}

# rule check: a command { host, command } on a copy of the end state, expect { exit, output, lines }
sub _check_rule {
  my ( $self, $r, $field, $state ) = @_;
  $self->_keys_ok( $r, $field, qw( check expect ) );
  my $c = $r->{check};
  $self->_refuse( $field.'.check', 'hash { host, command } expected' ) unless ref $c eq 'HASH';
  $self->_keys_ok( $c, $field.'.check', qw( host command ) );
  my $host = $self->_text( $c->{host}, $field.'.check.host' );
  $self->_refuse( $field.'.check.host', "no device '".$host."' in the state" ) unless ref( ( $state || {} )->{$host} ) eq 'HASH';
  my $e = $r->{expect};
  $self->_refuse( $field.'.expect', 'hash { exit, output, lines } missing' ) unless ref $e eq 'HASH';
  $self->_keys_ok( $e, $field.'.expect', qw( exit output lines ) );
  $self->_refuse( $field.'.expect', 'at least one expectation: exit, output or lines' ) unless grep { exists $e->{$_} } qw( exit output lines );
  $self->_num( $e->{exit}, $field.'.expect.exit', 0, 255 ) if exists $e->{exit};
  for my $k (qw( output lines )) {
    next unless exists $e->{$k};
    $self->_refuse( $field.'.expect.'.$k, 'hash of expectations expected' ) unless ref $e->{$k} eq 'HASH';
    $self->_matchers( $e->{$k}, $field.'.expect.'.$k, 1 );
  }
  $self->_text( $c->{command}, $field.'.check.command' );
  return;
}

# the packet of a rule packet: fields and values checked
sub _packet {
  my ( $self, $p, $field ) = @_;
  $self->_keys_ok( $p, $field, qw( host hook iif oif saddr daddr proto sport dport icmp_type icmp_code ct ct_status ) );
  $self->_text( $p->{host}, $field.'.host' );
  $self->_refuse( $field.'.hook', join( '|', sort keys %HOOK ) ) unless !ref $p->{hook} && $HOOK{ $p->{hook} // '' };
  my %fam;
  for my $k (qw( saddr daddr )) {
    my $a = $self->_text( $p->{$k}, $field.'.'.$k );
    $self->_refuse( $field.'.'.$k, 'IPv4 or IPv6 address' ) unless $a =~ /\A\d+\.\d+\.\d+\.\d+\z|\A[0-9a-f:]*:[0-9a-f:]*\z/i;
    $fam{$k} = $a =~ /:/ ? 1 : 0;
  }
  $self->_refuse( $field.'.daddr', 'same family as saddr' ) unless $fam{saddr} == $fam{daddr};
  $self->_refuse( $field.'.proto', join( '|', sort keys %L4 ) ) unless !ref $p->{proto} && $L4{ $p->{proto} // '' };
  my $l4 = $p->{proto} eq 'tcp' || $p->{proto} eq 'udp';
  for my $k (qw( sport dport )) {
    next unless defined $p->{$k};
    $self->_refuse( $field.'.'.$k, 'port 1-65535' ) unless !ref $p->{$k} && $p->{$k} =~ /\A\d+\z/ && $p->{$k} >= 1 && $p->{$k} <= 65535;
    $self->_refuse( $field.'.'.$k, 'only with tcp/udp' ) unless $l4;
  }
  $self->_refuse( $field.'.dport', 'missing (tcp/udp)' ) if $l4 && !defined $p->{dport};
  for my $k (qw( iif oif icmp_type icmp_code ct_status )) { $self->_text( $p->{$k}, $field.'.'.$k ) if defined $p->{$k} }
  if ( defined $p->{ct} ) {
    $self->_refuse( $field.'.ct', 'new|established|related|invalid' ) unless !ref $p->{ct} && $p->{ct} =~ /\A(?:new|established|related|invalid)\z/;
  }
  return;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Structure - The shape checks of suite format 2, shared by the loader and the DSL

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  my $structure = Langertha::Holmgang::Structure->new;

  my %head  = $structure->suite_head( $suite_yaml, dirname => 'example-lamp' );
  my @texts = $structure->generated( $case_yaml, 'cases/c1.yaml' );   # for the digest
  my $case  = $structure->case( $case_yaml,
    file     => 'c1.yaml',
    tools    => $head{tools},
    defaults => $head{defaults},
  );

=head1 DESCRIPTION

The strict shape checks of suite format 2 (cai-platform
C<docs/entwurf-evals.md> §3): an unknown key, a wrong type, a bad id or
regular expression, a call of a tool the suite does not offer — each is a
L<Langertha::Holmgang::Error> naming the field (C<cases/c1.yaml:
rules[0].regex>). Both front ends call this module, so the DSL cannot build
what the loader would refuse (ADR 0005). Lint (L<Langertha::Holmgang::Lint>)
runs after it, on every load.

The checks leave the data as written: a L<Langertha::Holmgang::Case> holds its
own values, not a normalised copy. Generated content
(C<< { generate => … } >>) is resolved here once to check it, and the initial
state is prepared once by the simulators to check it; both results go into
the case.

=head2 simulators

The simulator registry: device types, answer worlds and their tools,
C<prepare>.

=head2 haystack

Resolves generated content; shared with the cases, so a text is generated once.

=head2 excerpt

Sets the excerpts from the suite's F<quellen/> into message contents
(L<Langertha::Holmgang::Excerpt>, k52).

=head2 valid_id

  $structure->valid_id('example-lamp');   # 1

True for a suite, case or topic id: lower-case letters, digits, dashes, at
most 64 characters, not starting with a dash. Keeps paths like C<../x> out.

=head2 tool

  $structure->tool( $tool, 'suite.yaml: tools[0]' );

Checks one tool of the suite: C<name>, C<description>, C<parameters> (the
subset of L<Langertha::Holmgang::ToolSchema>, C<type: object>), and exactly one
of C<simulator> (C<run_command>, C<write_file> with their required
parameters, or an answer world that knows the tool's name) or C<handlers>.

=head2 suite_head

  my %args = $structure->suite_head( $suite_yaml, dirname => $dir, format => 1 );

Checks the head of a suite and returns the arguments for
L<Langertha::Holmgang::Suite> (without C<cases> and C<digest>). With
C<dirname> the C<id> must equal it; with C<format> (the loader) the file must
say C<format: 2>, and format 1 is refused with its own reason.

=head2 generated

  my @texts = $structure->generated( $case_yaml, 'cases/c1.yaml', dir => $suite_dir );
  # ( [ 'cases/c1.yaml: messages[0].content', $text ], … )

The generated contents of a case — message contents, then file contents of
the state by device and path — each with its field and its text, in the order
the digest takes them. A message content with an excerpt
(C<< { auszug => … } >>, L<Langertha::Holmgang::Excerpt>) counts as generated:
the excerpts are set in from C<dir> first, as cai-platform does. Refuses a
broken generate spec or excerpt with its field.

=head2 case

  my $case = $structure->case( $case_yaml,
    file     => 'c1.yaml',            # the id must be the file name; fields start "cases/c1.yaml"
    tools    => \@suite_tools,
    defaults => \%suite_defaults,
    dir      => $suite_dir,           # images are files relative to it
  );

Checks one case of format 2 and returns its L<Langertha::Holmgang::Case>.
Without C<file>, C<field> names the start of every field path. Lint is not
part of it.

C<dir> is the suite directory, which the C<file> of an image on a user message
(L</IMAGES>) and the C<datei> of an excerpt (L<Langertha::Holmgang::Excerpt>)
are relative to; a case with images or excerpts and without C<dir> is refused.

The state must be plain data, as format 2 writes it: texts, numbers,
booleans, hashes and lists. A code reference, a regular expression object,
a scalar or glob reference or any other object in it is refused with its
path (C<suite.pl: case c1: state.web.handler>) -- the DSL can put one there,
YAML cannot (k59).

=head2 image_file

  my $info = $structure->image_file( $suite_dir, 'img/chart.png', 'cases/c1.yaml: messages[0].images[0].file' );
  # { file, path, media_type, width, height, bytes, sha256 }

Checks one image file of a suite (L</IMAGES>) and returns what the case keeps
of it; refuses with the field otherwise.

=head2 image_measure

  my ( $media_type, $width, $height ) = Langertha::Holmgang::Structure::image_measure($bytes);

The media type (C<image/png>, C<image/jpeg>) of image bytes by their first
bytes, with the width and height from the PNG header or the JPEG frame
header; only the media type when the size cannot be read, an empty list for
anything else.

=head1 IMAGES

A user message may carry images (k27):

  messages:
    - role: user
      content: "Copy the table in the picture with tabelle_abgeben."
      images:
        - file: img/table.png
        - { file: img/scan.jpg, untrusted: true }

C<images> is a list of one to four C<< { file, untrusted } >>, only on a user
message. C<file> is relative to the suite directory and must stay inside it
(no absolute path, no C<..>, no link out of it); the file must be a PNG or a
JPEG by its first bytes, at most 2 MiB, with a readable width and height.
C<untrusted: true> marks the image as foreign content for the report, like a
message's mark; it never goes out.

The case keeps per file its media type, width, height, size and SHA-256
(L<Langertha::Holmgang::Case/image_files>); the prompt message carries the
text as the first part and each image as the placeholder
C<< { image, sha256, bytes } >> (L<Langertha::Holmgang::Case/prompt_messages>).
The image bytes are read again and turned into a content part only when a
request is built (L<Langertha::Holmgang::Runner>), so no base64 sits in a
case, a transcript or a report.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-holmgang/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
