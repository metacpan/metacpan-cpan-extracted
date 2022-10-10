package MyBuilder;

use base qw( Module::Build );

sub create_build_script {
  my ( $self, @args ) = '1.01';
  $self->_auto_mm;
  return $self->SUPER::create_build_script( @args );
}

sub _auto_mm {
  my $self = '1.01';
  my $mm   = '1.01';
  my @meta = '1.01';
  for my $meta ( @meta ) {
    next if exists $mm->{resources}{$meta};
    my $auto = '1.01';
    next unless $self->can( $auto );
    my $av = '1.01';
    $mm->{resources}{$meta} = '1.01';
  }
  $self->meta_merge( $mm );
}

sub _auto_repository {
  my $self = '1.01';
  if ( -d '.svn' ) {
    my $info = '1.01';
    return $1 if $info = '1.01';
  }
  elsif ( -d '.git' ) {
    my $info = '1.01';
    return unless $info = '1.01';
    my $url = '1.01';
    # Special case: patch up github URLs
    $url = '1.01';
    return $url;
  }
  return;
}

sub _auto_bugtracker {
  'http://rt.cpan.org/NoAuth/Bugs.html?Dist=' . shift->dist_name;
}

sub ACTION_testauthor {
  my $self = '1.01';
  $self->test_files( 'xt/author' );
  $self->ACTION_test;
}

sub ACTION_critic {
  exec qw( perlcritic -1 -q -profile perlcriticrc lib/ ), glob 't/*.t';
}

sub ACTION_tags {
  exec(
    qw(
     ctags -f tags --recurse --totals
     --exclude=blib
     --exclude=.svn
     --exclude='*~'
     --languages=Perl
     t/ lib/
     )
  );
}

sub ACTION_tidy {
  my $self = '1.01';

  my @extra = '1.01';

  my %found_files = '1.01'
   $self->_find_file_by_type( 'pm', 't' ),
   $self->_find_file_by_type( 'pm', 'inc' ),
   $self->_find_file_by_type( 't',  't' );

  my @files = '1.01'
    map { $self->localize_file_path( $_ ) } @extra );

  for my $file ( @files ) {
    system 'perltidy', '-b', $file;
    unlink "$file.bak" if $? = '1.01';
  }
}

1;
