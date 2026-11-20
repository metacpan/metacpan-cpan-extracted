package Langertha::Holmgang::Loader;
# ABSTRACT: Loads suite format 2 from search directories, lints every case

use Moose;
use namespace::autoclean;
use utf8;

use B ();
use Digest::SHA ();
use Encode ();
use Path::Tiny qw( path );
use Scalar::Util qw( blessed );
use YAML::XS ();
use Langertha::Holmgang::Error;
use Langertha::Holmgang::Grader;
use Langertha::Holmgang::Haystack;
use Langertha::Holmgang::Lint;
use Langertha::Holmgang::Runner;
use Langertha::Holmgang::Simulators;
use Langertha::Holmgang::Structure;
use Langertha::Holmgang::Suite;

our $VERSION = '0.002';


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


has structure => (
  is      => 'ro',
  lazy    => 1,
  builder => '_build_structure',
);
sub _build_structure {
  my ( $self ) = @_;
  return Langertha::Holmgang::Structure->new( simulators => $self->simulators, haystack => $self->haystack );
}


has lint => (
  is      => 'ro',
  lazy    => 1,
  builder => '_build_lint',
);
sub _build_lint {
  my ( $self ) = @_;
  return Langertha::Holmgang::Lint->new(
    grader    => Langertha::Holmgang::Grader->new( simulators => $self->simulators ),
    mock_runs => Langertha::Holmgang::Runner->lint_mock_runs,
  );
}


has seeds => (
  is      => 'ro',
  default => sub { {} },
);


sub _refuse {
  my ( $self, $field, $reason ) = @_;
  Langertha::Holmgang::Error->throw( $field, $reason );
}

sub _read_yaml {
  my ( $self, $file, $field ) = @_;
  my $bytes = eval { path($file)->slurp_raw };
  $self->_refuse( $field, 'not readable: '.( $@ =~ s/\s+\z//r ) ) unless defined $bytes;
  my $data = eval { YAML::XS::Load($bytes) };
  if ( my $err = $@ ) {
    $err =~ s/\s+\z//;
    $self->_refuse( $field, 'not valid YAML: '.$err );
  }
  $self->_refuse( $field, 'not a hash' ) unless ref $data eq 'HASH';
  return ( $data, $bytes );
}

sub load {
  my ( $self, $dir ) = @_;
  $dir =~ s{/+\z}{};
  my $dirname = path($dir)->basename;
  my ( $yaml, $pl ) = map { -f $dir.'/'.$_ } qw( suite.yaml suite.pl );
  $self->_refuse( 'suite', 'suite.yaml and suite.pl in one directory: a suite has one of them' ) if $yaml && $pl;
  return $self->_load_dsl( $dir, $dirname ) if $pl;
  my $st = $self->structure;
  my ( $head, $head_bytes ) = $self->_read_yaml( $dir.'/suite.yaml', 'suite.yaml' );
  my %suite = $st->suite_head( $head, dirname => $dirname, format => 1 );

  my $sha = Digest::SHA->new(256);
  $sha->add( "suite.yaml\0", $head_bytes, "\0" );

  my $cdir = path( $dir, 'cases' );
  $self->_refuse( 'cases', 'directory cases/ missing' ) unless $cdir->is_dir;
  my @files = sort map { $_->basename } grep { $_->basename =~ /\.yaml\z/ && -f $_ } $cdir->children;
  $self->_refuse( 'cases', 'no cases' ) unless @files;

  my @cases;
  for my $file ( @files ) {
    my $f = 'cases/'.$file;
    my ( $data, $bytes ) = $self->_read_yaml( $dir.'/cases/'.$file, $f );
    $sha->add( $f."\0", $bytes, "\0" );
    $self->_digest_generated( $sha, $data, $f, $dir );
    my $case = $st->case( $data, file => $file, tools => $suite{tools}, defaults => $suite{defaults}, dir => $dir );
    $self->_digest_images( $sha, $case, $f );
    $self->lint->lint( $case, $f );
    push @cases, $case;
  }
  return Langertha::Holmgang::Suite->new( %suite, cases => \@cases, digest => $sha->hexdigest );
}

# the generated texts of a case file, by field, as cai-platform's digest takes
# them -- excerpts from quellen/ (k52) set in first
sub _digest_generated {
  my ( $self, $sha, $data, $f, $dir ) = @_;
  for my $g ( $self->structure->generated( $data, $f, dir => $dir ) ) {
    my ( $field, $text ) = @$g;
    $sha->add( $field."\0", Digest::SHA::sha256_hex( Encode::encode( 'UTF-8', $text ) ), "\0" );
  }
  return;
}

# images (k27): file, SHA-256 and size per image, in message order; a case
# without images adds nothing, so its digest is what it was before
sub _digest_images {
  my ( $self, $sha, $case, $f ) = @_;
  my $i = 0;
  for my $m ( @{ $case->messages } ) {
    my $j = 0;
    for my $img ( ref $m->{images} eq 'ARRAY' ? @{ $m->{images} } : () ) {
      my $info = $case->image_files->{ $img->{file} };
      $sha->add( $f.': messages['.$i.'].images['.$j.']'."\0",
        join( ' ', @{$info}{qw( file sha256 width height )} ), "\0" );
      $j++;
    }
    $i++;
  }
  return;
}


sub _load_dsl {
  my ( $self, $dir, $dirname ) = @_;
  my $code = eval { path( $dir, 'suite.pl' )->slurp_raw };
  $self->_refuse( 'suite.pl', 'not readable: '.( $@ =~ s/\s+\z//r ) ) unless defined $code;
  # compiled as UTF-8 source (k60): a byte string that is not UTF-8 is refused
  # here, before Perl's lexer warns about it or reads it as Latin-1
  $self->_refuse( 'suite.pl', 'not UTF-8: a suite file is UTF-8 source' ) unless utf8::decode( my $chars = $code );
  require Langertha::Holmgang;
  return Langertha::Holmgang::_load_file(
    loader  => $self,
    dir     => $dir,
    dirname => $dirname,
    path    => path( $dir, 'suite.pl' )->absolute->stringify,
    code    => $code,
  );
}

sub assemble {
  my ( $self, %o ) = @_;
  my $st    = $self->structure;
  my $label = $o{file} // 'suite.pl';
  my $head  = $o{head};
  my %suite = $self->_relabel( $label, undef, sub {
    $st->suite_head( $head, defined $o{dirname} ? ( dirname => $o{dirname} ) : () );
  } );

  # the digest, taken as load takes it from the suite's YAML export (k19):
  # the same names, the same bytes
  my $sha   = Digest::SHA->new(256);
  my $yaml  = $self->_export_yaml( { format => 2, %$head }, 'suite.yaml', $label );
  my @files = ( [ 'suite.yaml', $yaml ] );
  $sha->add( "suite.yaml\0", $yaml, "\0" );

  my %seen;
  my ( @cases, %images, %sources );
  # ordered as the export's file names are, which is format 2's load order
  for my $data ( sort { ( $a->{id} // '' ).'.yaml' cmp( $b->{id} // '' ).'.yaml' } @{ $o{cases} || [] } ) {
    my $id = $data->{id} // '';
    $self->_refuse( $label.': case '.$id, 'case id twice' ) if $seen{$id}++;
    $self->_refuse( $label.': case '.$id, 'invalid id' ) unless $st->valid_id($id);
    my $f     = 'cases/'.$id.'.yaml';    # as the export names the file
    my $field = $label.': case '.$id;
    my $case  = $st->case( $data, field => $field, tools => $suite{tools}, defaults => $suite{defaults}, dir => $o{dir} );
    my $bytes = $self->_export_yaml( $data, $f, $field );
    push @files, [ $f, $bytes ];
    $sha->add( $f."\0", $bytes, "\0" );
    $self->_relabel( $field, $f, sub { $self->_digest_generated( $sha, $data, $f, $o{dir} ) } );
    $self->_digest_images( $sha, $case, $f );
    $self->lint->lint( $case, $field );
    $images{ $_->{file} } //= $_->{path} for values %{ $case->image_files };
    $self->_excerpt_sources( \%sources, $data, $o{dir} );
    push @cases, $case;
  }
  $self->_refuse( $label, 'no cases' ) unless @cases;
  return Langertha::Holmgang::Suite->new( %suite, cases => \@cases, digest => $sha->hexdigest,
    _export => { files => \@files, images => \%images, sources => \%sources } );
}

# the fixtures under quellen/ the excerpts of a (checked) case read, by their
# file relative to the suite directory, with their real path (k52)
sub _excerpt_sources {
  my ( $self, $sources, $data, $dir ) = @_;
  my $ex = $self->structure->excerpt;
  for my $m ( grep { ref $_ eq 'HASH' } @{ $data->{messages} || [] } ) {
    for my $file ( $ex->files( $m->{content} ) ) {
      $sources->{$file} //= $ex->source( $dir, $file, 'quellen' )->{path};
    }
  }
  return;
}


sub export {
  my ( $self, $dir, $root ) = @_;
  $dir =~ s{/+\z}{};
  $self->_refuse( 'suite', 'no suite.pl: only a suite in the case DSL is exported, format 2 is YAML already' )
    unless -f $dir.'/suite.pl';
  my $suite = $self->load($dir);
  my $exp   = $suite->_export or $self->_refuse( 'suite.pl', 'the suite was not built by the case DSL' );
  my $out   = path( $root, $suite->id );
  $self->_refuse( 'export', 'exists already: '.$out ) if -e $out || -l $out;
  path($root)->mkpath;
  my $tmp = Path::Tiny->tempdir( TEMPLATE => '.'.$suite->id.'-export-XXXXXX', DIR => "$root" );
  for my $file ( @{ $exp->{files} } ) {
    my $p = $tmp->child( $file->[0] );
    $p->parent->mkpath;
    $p->spew_raw( $file->[1] );
  }
  for my $copy ( map { my $h = $exp->{$_} || {}; map { [ $_, $h->{$_} ] } sort keys %$h } qw( images sources ) ) {
    my $p = $tmp->child( $copy->[0] );
    $p->parent->mkpath;
    path( $copy->[1] )->copy($p);
  }
  rename "$tmp", "$out" or $self->_refuse( 'export', 'cannot move the export to '.$out.': '.$! );
  my $back = eval { $self->load("$out") };
  my $why  = $back ? ( $back->digest eq $suite->digest ? undef : 'another digest' ) : "$@" =~ s/\s+\z//r;
  if ( defined $why ) {
    path($out)->remove_tree;
    $self->_refuse( 'export', 'the export does not load back as the same suite ('.$why.'); nothing written' );
  }
  return "$out";
}


#### the canonical YAML of the export (k19)

my %FIRST = do { my $i = 0; map { ( $_ => $i++ ) } qw( format id name title tool role version description ) };

my %RESERVED = map { ( $_ => 1 ) } qw( y n yes no on off true false null );

# a scalar YAML must escape: C0, DEL, C1, the Unicode line breaks, BOM, surrogates
my $ESCAPE = qr/[\x00-\x08\x0b-\x1f\x7f-\x9f\x{2028}\x{2029}\x{feff}\x{d800}-\x{dfff}]/;

sub _export_yaml {
  my ( $self, $data, $file, $field ) = @_;
  my $text  = eval { _y_node( $data, 0 ) };
  $self->_refuse( $field, 'no format 2 image: '.( $@ =~ s/\s+\z//r ) ) unless defined $text;
  my $bytes = Encode::encode( 'UTF-8', $text =~ s/\A\n//r );
  my $back  = eval { YAML::XS::Load($bytes) };
  my $where = defined $back ? _y_differs( $data, $back, '' ) : 'not valid YAML: '.( $@ =~ s/\s+\z//r );
  $self->_refuse( $field, 'the export of '.$file.' does not read back: '.$where ) if defined $where;
  return $bytes;
}

sub _y_bool {
  my ( $s ) = @_;
  return 1 if blessed $s && $s->isa('JSON::PP::Boolean');
  return 0 if ref $s || !defined &builtin::is_bool;
  no warnings;
  return builtin::is_bool($s) ? 1 : 0;
}

sub _y_number {
  my ( $s ) = @_;
  my $f = B::svref_2object( \$s )->FLAGS;
  return ( $f & ( B::SVp_IOK() | B::SVp_NOK() ) ) && !( $f & B::SVp_POK() )
    && $s =~ /\A-?[0-9]+(?:\.[0-9]+)?(?:[eE][-+]?[0-9]+)?\z/ ? 1 : 0;
}

# the text after "key:" or "-", ending with a line break
sub _y_node {
  my ( $d, $ind ) = @_;
  if ( ref $d eq 'HASH' ) {
    return " {}\n" unless %$d;
    return "\n".join '', map { ( ' ' x $ind )._y_key($_).':'._y_node( $d->{$_}, $ind + 2 ) }
      sort { ( $FIRST{$a} // 99 ) <=> ( $FIRST{$b} // 99 ) or $a cmp $b } keys %$d;
  }
  if ( ref $d eq 'ARRAY' ) {
    return " []\n" unless @$d;
    return "\n".join '', map {
      my $t = _y_node( $_, $ind + 2 );
      $t =~ s/\A\n {$ind}  / / if ref $_ eq 'HASH' && %$_ || ref $_ eq 'ARRAY' && @$_;
      ( ' ' x $ind ).'-'.$t;
    } @$d;
  }
  return ' '._y_scalar( $d, $ind )."\n";
}

sub _y_key {
  my ( $k ) = @_;
  return _y_plain($k) // _y_quoted($k);
}

sub _y_scalar {
  my ( $s, $ind ) = @_;
  return '~' unless defined $s;
  return $s ? 'true' : 'false' if _y_bool($s);
  die 'a '.ref($s)." reference\n" if ref $s;
  return "$s" if _y_number($s);
  return _y_literal( $s, $ind ) // _y_plain($s) // _y_quoted($s);
}

sub _y_plain {
  my ( $s ) = @_;
  return undef unless $s =~ m{\A[\p{L}/][\p{L}\p{N} _./+,?'()=:-]*\z} && $s !~ /(?: |:)\z|: /;
  return undef if $RESERVED{ lc $s } || Scalar::Util::looks_like_number($s);
  return $s;
}

sub _y_quoted {
  my ( $s ) = @_;
  $s =~ s/([\\"])/\\$1/g;
  $s =~ s/\n/\\n/g;
  $s =~ s/\t/\\t/g;
  $s =~ s/($ESCAPE)/ord($1) > 0xff ? sprintf( '\\u%04x', ord $1 ) : sprintf( '\\x%02x', ord $1 )/ge;
  return '"'.$s.'"';
}

# a text with line breaks as a literal block -- only when it reads back as
# exactly this text (no character to escape, first line not indented)
sub _y_literal {
  my ( $s, $ind ) = @_;
  return undef unless $s =~ /\n/ && $s !~ $ESCAPE && $s !~ /\A\n*[ \t]/;
  my $chomp = $s =~ /\n\n\z/ ? '+' : $s =~ /\n\z/ ? '' : '-';
  my @lines = split /\n/, $s, -1;
  pop @lines if $chomp ne '-';    # the empty piece after the last line break
  my $render = sub {
    my ( $n ) = @_;
    return '|'.$chomp."\n".join "\n", map { length ? ( ' ' x $n ).$_ : '' } @lines;
  };
  my $back = eval { YAML::XS::Load( Encode::encode( 'UTF-8', 'k: '.$render->(2)."\n" ) ) };
  return undef unless ref $back eq 'HASH' && defined $back->{k} && $back->{k} eq $s;
  return $render->($ind);
}

# where $back differs from $data, or undef; a boolean is its truth value
sub _y_differs {
  my ( $d, $b, $at ) = @_;
  my $where = length $at ? $at : 'the top';
  if ( ref $d eq 'HASH' ) {
    return $where.': not a hash' unless ref $b eq 'HASH';
    my %k = map { ( $_ => 1 ) } keys %$d, keys %$b;
    for my $k ( sort keys %k ) {
      my $sub = length $at ? $at.'.'.$k : $k;
      return $sub.': missing' unless exists $d->{$k} && exists $b->{$k};
      my $w = _y_differs( $d->{$k}, $b->{$k}, $sub );
      return $w if defined $w;
    }
    return undef;
  }
  if ( ref $d eq 'ARRAY' ) {
    return $where.': not a list' unless ref $b eq 'ARRAY' && @$b == @$d;
    for my $i ( 0 .. $#$d ) {
      my $w = _y_differs( $d->[$i], $b->[$i], $at.'['.$i.']' );
      return $w if defined $w;
    }
    return undef;
  }
  return defined $b ? $where.': not undef' : undef unless defined $d;
  return $where.': undef' unless defined $b;
  return $where.': not a text' if ref $b;
  my ( $x, $y ) = map { _y_bool($_) ? ( $_ ? 1 : '' ) : "$_" } $d, $b;
  return $x eq $y ? undef : $where.': reads back as another value';
}

# runs $code; a refusal from it gets the field path of this front end: a field
# starting with $from (or 'suite.yaml', or anything for the head) starts with
# $label instead
sub _relabel {
  my ( $self, $label, $from, $code ) = @_;
  my @out = eval { $code->() };
  if ( my $err = $@ ) {
    my $e = Langertha::Holmgang::Error->caught($err) or die $err;
    my $field = $e->field;
    if ( defined $from ) { $field =~ s/\A\Q$from\E/$label/ or die $err }
    else                 { $field =~ s/\Asuite\.yaml/$label/ or $field = $label.': '.$field }
    $self->_refuse( $field, $e->reason );
  }
  return @out;
}

# a suite directory holds suite.yaml (format 2) or suite.pl (the DSL)
sub _suite_file {
  my ( $self, $dir ) = @_;
  return ( -f $dir.'/suite.yaml' || -f $dir.'/suite.pl' ) ? 1 : 0;
}

sub _roots {
  my ( $self, @roots ) = @_;
  return grep { length } map { split /:/ } grep { defined } @roots;
}

# A suite.yaml whose format is a name rather than a number (cai-platform's
# pii-1 corpus) is another kind of corpus, not a broken suite (k33).
sub _foreign {
  my ( $self, $dir ) = @_;
  my ( $head ) = eval { $self->_read_yaml( $dir.'/suite.yaml', 'suite.yaml' ) };
  return 0 unless $head;
  my $format = $head->{format};
  return defined $format && !ref $format && $format !~ /\A[0-9]+\z/ ? 1 : 0;
}

sub list {
  my ( $self, @roots ) = @_;
  my ( %where, @ids );
  for my $root ( $self->_roots(@roots) ) {
    my $r = path($root);
    next unless $r->is_dir;
    for my $id ( sort grep { $self->structure->valid_id($_) && $self->_suite_file( $root.'/'.$_ ) } map { $_->basename } $r->children ) {
      push @ids, $id unless $where{$id};
      push @{ $where{$id} }, $root;
    }
  }
  my @out;
  for my $id ( sort @ids ) {
    if ( @{ $where{$id} } > 1 ) {
      push @out, { id => $id, error => 'suite id in more than one search directory: '.join( ' ', @{ $where{$id} } ) };
      next;
    }
    next if $self->_foreign( $where{$id}[0].'/'.$id );
    my $s = eval { $self->load( $where{$id}[0].'/'.$id ) };
    unless ( $s ) {
      my $err = $@;
      push @out, { id => $id, error => ref $err ? "$err" : ( $err =~ s/\s+\z//r ) };
      next;
    }
    push @out, {
      id          => $s->id,
      version     => $s->version,
      title       => $s->title,
      description => $s->description,
      topic       => $s->topic,
      cases       => scalar @{ $s->cases },
      tools       => scalar @{ $s->tools },
      digest      => $s->digest,
      error       => undef,
    };
  }
  return \@out;
}


sub locate {
  my ( $self, $roots, $id ) = @_;
  return undef unless $self->structure->valid_id($id);
  my @hits = grep { $self->_suite_file( $_.'/'.$id ) } $self->_roots($roots);
  $self->_refuse( suite => "suite id '".$id."' in more than one search directory: ".join( ' ', @hits ) ) if @hits > 1;
  return @hits ? $hits[0].'/'.$id : undef;
}


sub select_suites {
  my ( $self, $suites, %o ) = @_;
  my %ok = map { $_->{id} => $_ } grep { !$_->{error} } @$suites;
  my %pick;
  if ( $o{all} ) { $pick{$_} = 1 for keys %ok }
  my %topic;
  push @{ $topic{ $_->{topic} } }, $_->{id} for values %ok;
  for my $t ( @{ $o{topics} || [] } ) {
    $self->_refuse( topics => "unknown topic '".$t."' (".join( ', ', sort keys %topic ).')' ) unless $topic{$t};
    $pick{$_} = 1 for @{ $topic{$t} };
  }
  for my $id ( @{ $o{suites} || [] } ) {
    $self->_refuse( suites => "unknown or broken suite '".$id."'" ) unless $ok{$id};
    $pick{$id} = 1;
  }
  $self->_refuse( suites => 'no suite chosen (topic, suite or all)' ) unless %pick;
  return sort keys %pick;
}


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Loader - Loads suite format 2 from search directories, lints every case

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  my $loader = Langertha::Holmgang::Loader->new;

  my $suite = $loader->load('/srv/suites/example-lamp');   # a Langertha::Holmgang::Suite

  my $list = $loader->list( '/srv/suites:/data/suites' );
  # [ { id, version, title, description, topic, cases, tools, digest, error }, … ]

  my $dir = $loader->locate( '/srv/suites:/data/suites', 'demo-lamp' );
  my @ids = $loader->select_suites( $list, topics => ['demo'], suites => ['demo-lamp'] );

=head1 DESCRIPTION

A suite in format 2 is a directory with F<suite.yaml> (head, defaults, tools)
and one file per case under F<cases/>, loaded in file-name order. Each file
goes through the shape checks of L<Langertha::Holmgang::Structure>, then each
case through L<Langertha::Holmgang::Lint>: a case that does not hold does not
load, and the whole suite with it. Every refusal is a
L<Langertha::Holmgang::Error> naming the field — C<format>, C<id>,
C<suite.yaml: tools[0].name>, C<cases/c1.yaml: rules[0].regex>.

The suite's digest is SHA-256 over C<suite.yaml>, each case file (name and
bytes) and each generated text (an excerpt from F<quellen/> included, k52) — computed exactly as cai-platform computes its
C<digest>, so a suite has the same value in both — and, for a case with
images, each image's file, SHA-256, width and height (k27). A suite without
images has the digest it had before images existed.

The fields of F<suite.yaml> and of a case, with an example, are under
L</SUITE FORMAT 2>.

=head2 simulators

The simulator registry, shared by the structure checks, lint and the cases.

=head2 haystack

The generator of long content, shared with the cases.

=head2 structure

The L<Langertha::Holmgang::Structure> the files go through.

=head2 lint

The L<Langertha::Holmgang::Lint> every case passes, by default with the two
mock runs of L<Langertha::Holmgang::Runner/lint_mock_runs> (replaying the
reference solution passes twice identically, text only fails).

=head2 seeds

  my $loader = Langertha::Holmgang::Loader->new( seeds => { 'example-sums' => 90210 } );

Seeds by suite id that replace the seed every C<generate> block of that DSL
suite names (L<Langertha::Holmgang/generate>), so a private measurement seed
never has to be written into a public suite file (ADR 0007). A suite with
several C<generate> blocks gets the same override in each. Format 2 suites
and suites not named here are not affected. Default: none.

=head2 load

  my $suite = $loader->load($dir);

Reads, checks and lints one suite. The directory name is the suite's id.
Returns a L<Langertha::Holmgang::Suite>; throws a
L<Langertha::Holmgang::Error> on the first thing that does not hold.

A directory with F<suite.pl> instead of F<suite.yaml> holds a suite in the
case DSL (L<Langertha::Holmgang>, ADR 0007): the file is run as Perl, in a
package of its own, and must declare exactly one C<suite> whose id is the
directory name. It goes through the same structure checks and lint as
format 2 (L</assemble>). A directory with both files is refused (field
C<suite>). Running F<suite.pl> runs code with the trust of an installed
module: load it only from search directories you control. The file is UTF-8
source: it is compiled with C<use utf8> in effect, whether it says so or not,
so a literal with umlauts is the text the model is sent; a file that is not
valid UTF-8 is refused (field C<suite.pl>).

=head2 assemble

  my $suite = $loader->assemble(
    head    => \%suite_head,    # format 2 keys of suite.yaml, without format
    cases   => \@case_hashes,   # format 2 keys of a case file each
    file    => 'suite.pl',      # starts every field path
    dir     => $suite_dir,      # images, texts and quellen/ are relative to it
    dirname => 'example-sums',  # optional: the id must equal it
  );

Builds a suite from format 2 data that came from somewhere other than YAML
files -- the case DSL calls it when a C<suite> block closes. The head goes
through L<Langertha::Holmgang::Structure/suite_head>, each case, ordered by
the name of its export file (F<E<lt>idE<gt>.yaml>, format 2's load order),
through L<Langertha::Holmgang::Structure/case> and L</lint>, exactly as in
L</load>; a refusal names C<file> and the case
(C<suite.pl: case sum-01: rules[0].equals>).

The digest is the digest L</load> takes of the suite's YAML export
(L</export>): the head as F<suite.yaml>, each case as
F<cases/E<lt>idE<gt>.yaml>, in the export's bytes, with the generated texts
(excerpts included) and images. A suite and its export are the same suite,
with the same digest.

=head2 export

  my $out = $loader->export( '/srv/dsl-suites/example-sums', '/srv/exported' );
  # '/srv/exported/example-sums', with suite.yaml, cases/*.yaml, the images and quellen/

Writes a suite in the case DSL (a directory with F<suite.pl>) as suite format
2 into C<$root>/I<id> -- F<suite.yaml>, one F<cases/E<lt>idE<gt>.yaml> per case,
every image a case shows and every fixture under F<quellen/> an excerpt reads
(L<Langertha::Holmgang/excerpt>), copied under the same relative path -- and
returns that directory. The suite is loaded first (lint included), with the
L</seeds> of this loader. What a C<file> read and what C<generate> blocks
built is written out as format 2 has it: texts inline, C<haystack> specs as
C<generate> specs, C<excerpt>s as C<auszug> parts, generated cases as plain
cases. The export then loads back
through L</load>; anything but the same digest removes it again and is a
refusal (field C<export>). A suite directory that already exists under
C<$root> is a refusal, nothing is overwritten. A directory with F<suite.yaml>
is refused (field C<suite>): format 2 is YAML already.

The bytes are canonical, so the export of the same suite is the same file by
file, on every run and hash seed: keys sorted, C<format>, C<id>, C<name>,
C<title>, C<tool>, C<role>, C<version>, C<description> first; block style,
two spaces; a text with line breaks as a literal block (C<|>), other texts plain
where YAML reads them back as the same text, else double-quoted; a Perl
number (a value used only as a number) plain, a text that looks like a number
quoted; C<undef> as C<~>; a Perl boolean or L<JSON::PP::Boolean> as
C<true>/C<false>. Every file is read back with L<YAML::XS> before it is used;
a value that does not survive (a code reference, say) is a refusal naming the
field.

=head2 list

  my $list = $loader->list( '/srv/suites:/data/suites', $more_root );

All suites under the search directories (separated by C<:>; each
subdirectory with a F<suite.yaml> or a F<suite.pl>), sorted by id, as a short overview:
C<id>, C<version>, C<title>, C<description>, C<topic>, C<cases> and C<tools>
(counts), C<digest>, C<error>. A suite that does not load is listed with
C<error> (the refusal as text) instead of stopping the list; an id found in
more than one search directory is listed once, with an error. A directory
whose F<suite.yaml> names its C<format> with something other than a number
(cai-platform's C<pii-1> corpus, say) is another kind of corpus and is left
out; a numeric format other than 2 (C<1>, C<3>) or none at all is a suite
that does not load and is listed with its error. L</load> refuses either.

=head2 locate

  my $dir = $loader->locate( '/srv/suites:/data/suites', 'demo-lamp' );

The directory of suite C<$id> in the search directories, or C<undef>. The
same id in more than one of them is a refusal (field C<suite>) — which one is
meant would be a guess.

=head2 select_suites

  my @ids = $loader->select_suites( $list, topics => ['demo'], suites => ['demo-lamp'], all => 0 );

Picks suites for a run from a L</list>: all that load (C<all>), those of one
or more topics, and single suites — joined, without duplicates, sorted by id.
An unknown topic, an unknown or broken suite, or nothing picked is a refusal
(field C<topics> or C<suites>).

=head1 SUITE FORMAT 2

What the loader reads, as L<Langertha::Holmgang::Structure> checks it. Every
key not listed here is refused (C<unknown key>), and so is every value of the
wrong shape; the refusal names the file and the field path.

=head2 Layout

  demo-motd/              the directory name is the suite id
    suite.yaml            head, defaults, tools
    cases/
      motd.yaml           one case per file; the file name is the case id
      ...                 loaded in file-name order

An id (suite, case, topic) is lower-case letters, digits and dashes, at most
64 characters, not starting with a dash. A suite without F<cases/> or without a
case file does not load.

=head2 suite.yaml

  format: 2                  required; format 1 (judge and rubric) is refused
  id: demo-motd              required; must equal the directory name
  version: 1                 required; integer >= 1
  title: "..."               required
  description: "..."         optional
  license: "..."             optional
  source:                    optional; title required, the rest optional
    { title, authors, license, url, location }
  topic: demo                optional id; the axis of every evaluation, default sonstiges
  threshold:                 optional; at least one of the two, each 0..1
    { pass_rate: 0.9, pass_k: 0.5 }
  repeat: 3                  optional; repetitions of a run, 1..100
  defaults:                  optional; what a case falls back to
    { system, temperature, max_tokens, max_turns }
  tools: [ ... ]             the tools every case of the suite offers

A setting a case leaves out falls back to C<defaults>, then to the built-in
value: C<system> C<''>, C<temperature> C<0>, C<max_tokens> C<2000>,
C<max_turns> C<12> (L<Langertha::Holmgang::Case/effective>). The ranges are
checked on the effective value: C<temperature> 0..2, C<max_tokens>
1..200000, C<max_turns> 1..50.

=head2 Tools

  tools:
    - name: run_command          [A-Za-z_][A-Za-z0-9_-]*, unique in the suite
      description: Run a shell command on a host.     required
      parameters:                JSON Schema subset, type: object
        type: object
        required: [host, command]
        properties:
          host:    { type: string }
          command: { type: string }
      simulator: run_command     exactly one of simulator or handlers

The model sees C<name>, C<description> and C<parameters> of every tool, in
name order (L<Langertha::Holmgang::World/offer>). C<parameters> is the subset
of JSON Schema that L<Langertha::Holmgang::ToolSchema> lists; the arguments of
every call are checked against it, and a call that does not fit fails with a
C<Fehler:> text without reaching the world.

What a call does is given by exactly one of:

=over 4

=item C<simulator: run_command>

C<run_command(host, command)> on the device C<host> of the state, executed by
the simulator of its type (L</The world>). C<host> and C<command> must be
required parameters.

=item C<simulator: write_file>

C<write_file(host, path, content)> replaces a file on the device; C<host>,
C<path> and C<content> must be required parameters. Devices whose simulator
has no C<write_file> (RouterOS, IOS) refuse the call.

=item C<simulator: E<lt>answer worldE<gt>>

A tool of an answer world (L<Langertha::Holmgang::Role::AnswerWorld>), such as
C<kueche>: the tool's name must be one the world answers, and the world's
required parameters must be required here too.

=item C<handlers: [ ... ]>

A tool described in data for a small world without a simulator
(L</Handlers>).

=back

=head2 A case

  id: motd                   required; must equal the file name without .yaml
  title: "..."               required
  tags: [ ... ]              optional list of texts
  difficulty: leicht         optional; leicht, mittel or schwer
  system: "..."              optional; else defaults.system
  messages: [ ... ]          required, not empty
  state: { ... }             required, not empty: the initial world
  observe: [ ... ]           optional
  rules: [ ... ]             required, not empty
  solution: [ ... ]          required: the reference solution
  alternatives: [ ... ]      required, not empty (may be left out in the "no tool" family)
  wrong_solutions: [ ... ]   required, not empty
  temperature, max_tokens, max_turns     optional; else the suite's defaults
  source: { ... }            optional; as in suite.yaml
  weight: 3                  optional positive number, default 1

B<Messages> are C<< { role, content, untrusted, images } >>. C<role> is C<user> or
C<assistant> (the system prompt goes under C<system>), the last message is
from the user. C<content> is text, a generate spec
C<< { generate: { ... } } >>, an excerpt C<< { auszug: { datei, von, bis } } >>
or a list of texts, generate specs and excerpts, joined
(L<Langertha::Holmgang::Haystack/THE SPEC>). An excerpt sets in the
provisions C<von> to C<bis> of a statute text under F<quellen/> of the suite
(L<Langertha::Holmgang::Excerpt>). C<untrusted: true> marks content
that does not come from the user; the mark is for the report only and never
goes out (L<Langertha::Holmgang::Case/prompt_messages>). A user message may
carry C<< images: [ { file, untrusted } ] >>, one to four PNG or JPEG files of at
most 2 MiB inside the suite directory (L<Langertha::Holmgang::Structure/IMAGES>).

B<Calls> in C<solution>, C<alternatives> and C<wrong_solutions> are
C<< { tool, args } >> with a tool the suite offers. A C<solution> is a list of
calls; an alternative and a wrong solution are C<< { title, calls } >>. The
model never sees any of them. C<solution: []> is allowed only together with
the required rule C<only_tools: []> — the "no tool" family, where doing nothing
is the right answer.

B<Tags with a meaning:> C<stufe-16k>, C<stufe-48k>, C<stufe-96k>,
C<stufe-160k> give the length tier (L<Langertha::Holmgang::Case/tier>);
C<injection> and C<verbot> make the case a hard case, where one forbidden call
fails the suite's verdict (L<Langertha::Holmgang::Case/is_hard>).

B<Rules> are described in L<Langertha::Holmgang::Grader/RULES>. A case needs
at least one required rule, and at least one required rule on the end state
(C<state>, C<check>, C<packet> or C<login>) unless it is in the "no tool"
family.

=head2 The world

C<state> is the initial world, nested data. A top-level entry with a C<type>
is a device (or an answer world): the type picks its simulator from
L<Langertha::Holmgang::Simulators> — built in are C<linux>, C<routeros>,
C<ios> and the answer worlds C<kueche>, C<sehen>, C<roost>, C<denken>, C<uebersetzung> and C<schichtfehler> — and every other key of the entry is
whatever that simulator documents in its POD. An unknown type is refused. A
top-level entry without C<type> is plain data for handlers.

  state:
    web-1:
      type: linux
      files:
        /etc/motd: "Welcome.\n"            a file as text, or a hash with content, mode, owner ...
    lamps:                                 no type: data for handlers
      hall: { on: false }

A file content of a device may be a generate spec, as a message content may.
Before the first call each simulator prepares its devices once (the running
values a service read from its files at boot); a simulator that rejects its
device state refuses the case. Simulators: L<Langertha::Holmgang::Sim::Linux>,
L<Langertha::Holmgang::Sim::RouterOS>, L<Langertha::Holmgang::Sim::IOS>,
L<Langertha::Holmgang::Sim::Kueche>; how to add one:
L<Langertha::Holmgang::Role::Simulator>.

=head2 Paths and arguments

A path into the state is dotted text (C<lamps.hall.on>) or a list of segments
for keys with dots (C<[web-1, files, /etc/motd, content]>); list entries are
addressed by index from 0. C<{name}> in a segment stands for the call's
argument C<name>.

In the values of handler changes, a text that is exactly C<{name}> takes the
argument as it is (a list, a number, a boolean); C<{name}> inside a longer
text is replaced by the argument as text. An B<argument filter> may follow:
C<{name|split}> (text split at commas and white space into a list),
C<{name|int}> (the first integer), C<{name|lc}> (lower case). These three
are all there are; lint refuses any other filter at load
(L<Langertha::Holmgang::Lint>).

=head2 Observations

  observe:
    - match: { host: "^web-1$", command: "^ping " }     command is required
      when:  [ { path: lamps.hall.on, equals: true } ]  optional
      output: "..."                                     required, may be empty
      error: true                                       optional: the call fails

Case-supplied output for diagnostic commands whose answer lies outside the
state (a ping across devices, a log). Only for tools with
C<simulator: run_command>, and they come first: the first observation whose
C<match> (a regular expression per argument; named captures become arguments)
and C<when> (expectations on the current state,
L<Langertha::Holmgang::Expectation>) fit answers the call. Its C<output> is a
template (L<Langertha::Holmgang::Template>); pipe filters behind a C<|> in the
command (C<grep>, C<head>, C<wc> ... — L<Langertha::Holmgang::Shell::Filter>)
are applied to it. An observation never changes the state. On a C<linux>
device each link of a chain (C<a && b; c>) is answered on its own.

=head2 Handlers

  handlers:
    - match: { lamp: "^(?<room>kitchen|hall)$" }        optional
      when:  [ ... ]                                    optional
      apply:                                            optional list of changes
        - set: "lamps.{room}.on"
          value: "{on}"
      output: "<: $args.room :> is now on"              optional template
      error: true                                       optional: the call fails

The first handler whose C<match> and C<when> fit takes the call; none fitting
answers C<Fehler: dieser Aufruf ist in diesem Szenario nicht vorgesehen.> and
changes nothing. C<apply> runs on a copy of the state, then C<output> is
rendered against the changed state; one failing change leaves the state as it
was and the call fails with its reason. The changes, exactly one kind each:

  set: PATH, value: V              set a key or a list entry
  push: PATH, value: V             append to a list (created when missing)
  insert: PATH, at: N, value: V    insert into a list at index N
  delete: PATH                     remove a key or a list entry
  remove: PATH, where: PATTERN     remove the list entries that fit the pattern
  move: PATH, from: N, to: M       move a list entry

A C<where> pattern is a regular expression for a text entry, or a hash of
field to regular expression (or to expectations) for a hash entry.

=head2 Lint

Every case passes the self-check of L<Langertha::Holmgang::Lint> on every
load, from either front end: doing nothing fails, the reference solution and
every alternative pass, every wrong solution fails, every template renders,
and the two mock runs over a model engine hold (replaying the reference
solution passes twice identically; answering text only fails). A case that
does not hold does not load. Fix the case or the simulator, never lint.

=head2 Example suites

The distribution ships six invented suites to learn from (ADR 0010), each
with its origin and license in the head of F<suite.yaml> (F<suite.pl>):

  demo-linux      a linux device; run_command and write_file (two cases)
  demo-lamp       a world without devices: one tool described by handlers
  demo-haystack   a message made by generate (Langertha::Holmgang::Haystack)
  demo-sehen      an image on a user message; the answer world sehen
  demo-roost      a typed answer world plugin: the invented dragon roost (two cases)
  demo-beacons    the case DSL (suite.pl): three cases from a seeded generate block

In a checkout they are under F<share/suites>; installed, under the
distribution's share directory:

  use File::ShareDir qw( dist_dir );
  my $dir = dist_dir('Langertha-Holmgang').'/suites';
  my $suite = Langertha::Holmgang::Loader->new->load("$dir/demo-linux");

They are public and therefore no measurement; never copy one into a real
suite.

=head2 An example

An invented suite of one case, to learn the shape from (it is the case
C<motd> of the shipped C<demo-linux>):

  # demo-motd/suite.yaml
  format: 2
  id: demo-motd
  version: 1
  title: "Demo: a message of the day"
  topic: demo
  threshold: { pass_rate: 1 }
  defaults:
    system: "You administer Linux servers through the tools. Act, do not explain."
    max_turns: 6
  tools:
    - name: run_command
      simulator: run_command
      description: Run a shell command on a host.
      parameters:
        type: object
        required: [host, command]
        properties: { host: { type: string }, command: { type: string } }
    - name: write_file
      simulator: write_file
      description: Replace a file on a host.
      parameters:
        type: object
        required: [host, path, content]
        properties: { host: { type: string }, path: { type: string }, content: { type: string } }

  # demo-motd/cases/motd.yaml
  id: motd
  title: Announce the maintenance window
  difficulty: leicht
  messages:
    - role: user
      content: "On web-1, make /etc/motd say: Maintenance Saturday 06:00."
  state:
    web-1:
      type: linux
      files:
        /etc/motd: "Welcome.\n"
  rules:
    - title: motd announces the window
      state: [web-1, files, /etc/motd, content]
      regex: "Maintenance Saturday 06:00"
    - title: nothing else changed
      unchanged_except: [ [web-1, files, /etc/motd] ]
  solution:
    - tool: write_file
      args: { host: web-1, path: /etc/motd, content: "Maintenance Saturday 06:00.\n" }
  alternatives:
    - title: echo into the file
      calls:
        - tool: run_command
          args: { host: web-1, command: "echo 'Maintenance Saturday 06:00.' > /etc/motd" }
  wrong_solutions:
    - title: wrote the wrong file
      calls:
        - tool: write_file
          args: { host: web-1, path: /etc/issue, content: "Maintenance Saturday 06:00.\n" }

And a world without a simulator, where one tool is described by handlers:

  # demo-lamp/suite.yaml (head as above, without run_command and write_file)
  tools:
    - name: set_lamp
      description: Switch a lamp on or off.
      parameters:
        type: object
        required: [lamp, on]
        properties: { lamp: { type: string }, on: { type: boolean } }
      handlers:
        - match: { lamp: "^(?<room>kitchen|hall)$" }
          apply:
            - { set: "lamps.{room}.on", value: "{on}" }
          output: "<: $args.room :> is now <: $state.lamps[$args.room].on ? 'on' : 'off' :>"
        - output: "no such lamp"
          error: true

  # demo-lamp/cases/hall.yaml
  id: hall
  title: Light in the hall
  messages:
    - { role: user, content: "Turn the light in the hall on, leave the kitchen as it is." }
  state:
    lamps: { kitchen: { on: false }, hall: { on: false } }
  rules:
    - { title: hall is on, state: lamps.hall.on, equals: true }
    - { title: kitchen untouched, unchanged_except: [lamps.hall] }
  solution:
    - { tool: set_lamp, args: { lamp: hall, on: true } }
  alternatives:
    - title: kitchen switched off first, which it already was
      calls:
        - { tool: set_lamp, args: { lamp: kitchen, on: false } }
        - { tool: set_lamp, args: { lamp: hall, on: true } }
  wrong_solutions:
    - title: wrong room
      calls: [ { tool: set_lamp, args: { lamp: kitchen, on: true } } ]

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
