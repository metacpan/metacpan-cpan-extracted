use 5.006;
use strict;
use warnings;

package Dist::Zilla::Plugin::Author::KENTNL::RecommendFixes;

our $VERSION = '0.005004';

# ABSTRACT: Recommend generic changes to the dist.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( with has around );
use MooX::Lsub qw( lsub );
use Path::Tiny qw( path );
use YAML::Tiny;
use Data::DPath qw( dpath );
use Generic::Assertions;

with 'Dist::Zilla::Role::InstallTool';

use Term::ANSIColor qw( colored ); () = eval { require Win32::Console::ANSI } if 'MSWin32' eq $^O;

our $LOG_COLOR = 'yellow';

around 'log' => sub {
  my ( $orig, $self, @args ) = @_;
  return $self->$orig( map { ref $_ ? $_ : colored( [$LOG_COLOR], $_ ) } @args );
};

## no critic (Subroutines::ProhibitSubroutinePrototypes,Subroutines::RequireArgUnpacking,Variables::ProhibitLocalVars)
sub _is_bad(&) { local $LOG_COLOR = 'red'; return $_[0]->() }

sub _badly(&) {
  my $code = shift;
  return sub { local $LOG_COLOR = 'red'; return $code->(@_); };
}
## use critic

sub _after_true {
  my ( $subname, $code ) = @_;
  return around $subname, sub {
    my ( $orig, $self, @args ) = @_;
    return unless my $rval = $self->$orig(@args);
    return $code->( $rval, $self, @args );
  };

}

sub _rel {
  my ( $self, @args ) = @_;
  return $self->root->child(@args)->relative( $self->root );
}

sub _mk_assertions {
  my ( $self, @args ) = @_;
  return Generic::Assertions->new(
    @args,
    '-handlers' => {
      test => sub {
        my ( $status, $message, $name ) = @_;
        if ( not $status ) {
          $self->log_debug("test $name: $message");
          return;
        }
        $self->log_debug("ok:test $name: $message");
        return $status;
      },
      should => sub {
        my ( $status, $message, $name, @slurpy ) = @_;
        if ( not $status ) {
          $self->log("should $name: $message");
          return;
        }
        $self->log_debug("ok:should $name: $message");
        return $slurpy[0];
      },
      should_not => sub {
        my ( $status, $message, $name, @slurpy ) = @_;
        if ($status) {
          $self->log("should_not $name: $message");
          return;
        }
        $self->log_debug("ok:should not $name: $message");
        return $slurpy[0];
      },
      must => sub {
        my ( $status, $message, $name, @slurpy ) = @_;
        $self->log_fatal("must $name: $message") unless $status;
        return $slurpy[0];
      },
      must_not => sub {
        my ( $status, $message, $name, @slurpy ) = @_;
        $self->log_fatal("must_not $name: $message") if $status;
        return $slurpy[0];
      },
    },
  );
}

has _pc => ( is => ro =>, lazy => 1, builder => '_build__pc' );

sub _build__pc {
  my ($self) = @_;

  my %cache;

  my $get_lines = sub {
    exists $cache{ $_[0] } or ( $cache{ $_[0] } = [ $_[0]->lines_raw( { chomp => 1 } ) ] );
    return $cache{ $_[0] };
  };

  return $self->_mk_assertions(
    '-input_transformer' => sub {
      my ( undef, @bits ) = @_;
      my $path = shift @bits;
      return ( $self->_rel($path), @bits );
    },
    exist => sub {
      if ( $_[0]->exists ) {
        return ( 1, "$_[0] exists" );
      }
      return ( 0, "$_[0] does not exist" );
    },
    have_line => sub {
      my ( $path, $regex ) = @_;
      my (@lines) = @{ $get_lines->($path) };
      return ( 0, "$path has no lines ( none to match $regex )" ) unless @lines;
      for my $line (@lines) {
        return ( 1, "$path Has line matching $regex" ) if $line =~ $regex;
      }
      return ( 0, "$path Does not have line matching $regex" );
    },
    have_one_of_line => sub {
      my ( $path, @regexs ) = @_;
      my (@rematches);
      for my $line ( @{ $get_lines->($path) } ) {
        for my $re (@regexs) {
          if ( $line =~ $re ) {
            push @rematches, "Has line matching $re";
          }
        }
      }
      if ( not @rematches ) {
        return ( 0, "Does not match at least one of ( @regexs )" );
      }
      if ( @rematches > 1 ) {
        return ( 0, 'Matches more than one of ( ' . ( join q[, ], @rematches ) . ' )' );
      }
      return ( 1, "Matches only @rematches" );
    },
    have_any_of_line => sub {
      my ( $path, @regexs ) = @_;
      my (@rematches);
      for my $line ( @{ $get_lines->($path) } ) {
        for my $re (@regexs) {
          if ( $line =~ $re ) {
            push @rematches, "Has line matching $re";
          }
        }
      }
      if ( not @rematches ) {
        return ( 0, "Does not match at least one of ( @regexs )" );
      }
      return ( 1, 'Matches more than one of ( ' . ( join q[, ], @rematches ) . ' )' );
    },
    have_assign => sub {
      my ( $path, $key, $callback ) = @_;
      my (@lines) = @{ $get_lines->($path) };
      return ( 0, "$path has no lines ( none to assign to $key )" ) unless @lines;
      my @failures;
      for my $line (@lines) {
        if ( $line =~ /\A\s*\Q$key\E\s*=\s*(.+$)/ ) {
          my ( $result, $message ) = $callback->("$1");
          if ($result) {
            return ( $result, "${path}'s $key assigns ok ( $message )" );
          }
          push @failures, $message;
        }
      }
      if ( not @failures ) {
        return ( 0, "${path}'s $key is not assigned" );
      }
      return ( 0, "${path}'s $key does not assign ok (" . ( join q[, ], @failures ) . ')' );
    },
  );
}

has _dc => ( is => ro =>, lazy => 1, builder => '_build__dc' );

sub _build__dc {
  my ($self) = @_;

  my %yaml_cache;

  my $get_yaml = sub {
    exists $yaml_cache{ $_[0] } or (
      $yaml_cache{ $_[0] } = do {
        my ( $r, $ok );
        ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
        eval {
          $r  = YAML::Tiny->read( path( $_[0] )->stringify )->[0];
          $ok = 1;
        };
        $r;
      }
    );
    return $yaml_cache{ $_[0] };
  };

  return $self->_mk_assertions(
    have_dpath => sub {
      my ( $label, $data, $expression ) = @_;
      if ( dpath($expression)->match($data) ) {
        return ( 1, "$label matches $expression" );
      }
      return ( 0, "$label does not match $expression" );

    },
    yaml_have_dpath => sub {
      my ( $yaml_path, $expression ) = @_;
      if ( dpath($expression)->match( $get_yaml->($yaml_path) ) ) {
        return ( 1, "$yaml_path matches $expression" );
      }
      return ( 0, "$yaml_path does not match $expression" );

    },
  );

}

lsub root => sub { my ($self) = @_; return path( $self->zilla->root ) };

my %amap = (
  git               => '.git',
  libdir            => 'lib',
  dist_ini          => 'dist.ini',
  git_config        => '.git/config',
  dist_ini_meta     => 'dist.ini.meta',
  weaver_ini        => 'weaver.ini',
  travis_yml        => '.travis.yml',
  perltidyrc        => '.perltidyrc',
  gitignore         => '.gitignore',
  changes           => 'Changes',
  license           => 'LICENSE',
  mailmap           => '.mailmap',
  perlcritic_gen    => 'maint/perlcritic.rc.gen.pl',
  perlcritic_deps   => 'misc/perlcritic.deps',
  contributing_pod  => 'CONTRIBUTING.pod',
  contributing_mkdn => 'CONTRIBUTING.mkdn',
  makefile_pl       => 'Makefile.PL',
  install_skip      => 'INSTALL.SKIP',
  readme_pod        => 'README.pod',
  tdir              => 't',
);

for my $key (qw( git libdir dist_ini )) {
  my $value = delete $amap{$key};
  lsub $key => _badly { $_[0]->_pc->should( exist => $value ) };
}
for my $key ( keys %amap ) {
  my $value = $amap{$key};
  lsub $key => sub { $_[0]->_pc->should( exist => $value ) };
  lsub "_have_$key" => sub { $_[0]->_pc->test( exist => $value ) };
}

_after_true makefile_pl => sub {
  my ( $file, $self ) = @_;
  undef $file if $self->install_skip;
  return $file;
};

_after_true contributing_pod => sub {
  my ( $file, $self ) = @_;
  undef $file if $self->_pc->should_not( exist => $amap{contributing_mkdn} );
  return $file;
};

_after_true gitignore => sub {
  my ( $rval, $self, ) = @_;
  my $file     = $amap{'gitignore'};
  my $assert   = $self->_pc;
  my $ok       = $rval;
  my $distname = $self->zilla->name;
  undef $ok unless $assert->should( have_line => $file, qr/\A\/\.build\z/ );
  undef $ok unless $assert->should( have_line => $file, qr/\A\/tmp\/\z/ );

  undef $ok unless $assert->should( have_line => $file, qr/\A\/\Q$distname\E-\*\z/ );
  undef $ok unless $assert->should_not( have_line => $file, qr/\A\Q$distname\E-\*\z/ );

  if ( $self->_have_makefile_pl ) {
    ## no critic ( RegularExpressions::ProhibitFixedStringMatches )
    undef $ok unless $assert->should( have_line => $file, qr/\A\/META\.json\z/ );
    undef $ok unless $assert->should( have_line => $file, qr/\A\/MYMETA\.json\z/ );
    undef $ok unless $assert->should( have_line => $file, qr/\A\/META\.yml\z/ );
    undef $ok unless $assert->should( have_line => $file, qr/\A\/MYMETA\.yml\z/ );
    undef $ok unless $assert->should( have_line => $file, qr/\A\/Makefile\z/ );
    undef $ok unless $assert->should( have_line => $file, qr/\A\/Makefile\.old\z/ );
    undef $ok unless $assert->should( have_line => $file, qr/\A\/blib\/\z/ );
    undef $ok unless $assert->should( have_line => $file, qr/\A\/pm_to_blib\z/ );
  }
  return $ok;
};

_after_true install_skip => sub {
  my ( $rval, $self, ) = @_;
  my $skipfile  = $amap{'install_skip'};
  my (@entries) = qw( contributing_pod readme_pod );
  my $assert    = $self->_pc;
  my $ok        = $rval;
  for my $entry (@entries) {
    my $sub = $self->can("_have_${entry}");
    next unless $self->$sub();
    my $entry_re = quotemeta $amap{$entry};
    undef $ok unless $assert->should( have_line => $skipfile, qr/\A\Q$entry_re\E\$\z/ );
  }
  return $ok;
};

lsub changes_deps_files => sub { return [qw( Changes.deps Changes.deps.all Changes.deps.dev Changes.deps.all )] };

lsub libfiles => sub {
  my ($self) = @_;
  return [] unless $self->libdir;
  my @out;
  my $it = $self->libdir->iterator( { recurse => 1 } );
  while ( my $thing = $it->() ) {
    next if -d $thing;
    next unless $thing->basename =~ /\.pm\z/msx;
    push @out, $thing;
  }
  if ( not @out ) {
    _is_bad { $self->log( 'Should have modules in ' . $self->libdir ) };
  }

  return \@out;
};
lsub tfiles => sub {
  my ($self) = @_;
  return [] unless $self->tdir;
  my @out;
  my $it = $self->tdir->iterator( { recurse => 1 } );
  while ( my $thing = $it->() ) {
    next if -d $thing;
    next unless $thing->basename =~ /\.t\z/msx;
    push @out, $thing;
  }
  if ( not @out ) {
    $self->log( 'Should have tests in ' . $self->tdir );
  }
  return \@out;

};

sub has_new_changes_deps {
  my ($self) = @_;
  my $ok     = 1;
  my $assert = $self->_pc;
  for my $file ( @{ $self->changes_deps_files } ) {
    undef $ok unless $assert->should( exist => 'misc/' . $file );
    undef $ok unless $assert->should_not( exist => $file );
  }
  return $ok;
}

_after_true perlcritic_deps => sub {
  my ( $file, $self ) = @_;
  my $ok     = $file;
  my $assert = $self->_pc;
  undef $ok unless $assert->should_not( exist => 'perlcritic.deps' );
  return $ok;
};

_after_true 'perlcritic_gen' => sub {
  my ( $file, $self ) = @_;
  my $assert = $self->_pc;
  my $ok     = $file;
  undef $ok unless $assert->should( have_line => $file, qr/Path::Tiny/ );
  undef $ok unless $assert->should( have_line => $file, qr/\.\/misc/ );
  return $ok;
};

_after_true 'git_config' => sub {
  my ( $rval, $self ) = @_;
  undef $rval unless $self->_pc->should_not( have_line => $rval, qr/kentfredric/ );
  return $rval;
};

sub _matrix_include_perl { my ($perl)   = @_; return "/matrix/include/*/perl[ value eq \"$perl\"]"; }
sub _branch_only         { my ($branch) = @_; return '/branches/only/*[ value eq "' . $branch . '"]' }

_after_true 'travis_yml' => sub {
  my ( $yaml, $self ) = @_;
  my $assert = $self->_dc;
  my $ok     = $yaml;

  undef $ok unless $assert->should( yaml_have_dpath => $yaml, '/matrix/include/*/env[ value =~ /COVERAGE_TESTING=1/' );

  for my $perl (qw( 5.21 5.20 5.10 )) {
    undef $ok unless $assert->should( yaml_have_dpath => $yaml, _matrix_include_perl($perl) );
  }
  for my $perl (qw( 5.8 )) {
    undef $ok unless $assert->should( yaml_have_dpath => $yaml, _matrix_include_perl($perl) );
  }
  for my $perl (qw( 5.19 )) {
    undef $ok unless _is_bad { $assert->should_not( yaml_have_dpath => $yaml, _matrix_include_perl($perl) ) };
  }
  for my $perl (qw( 5.18 )) {
    undef $ok unless $assert->should_not( yaml_have_dpath => $yaml, _matrix_include_perl($perl) );
  }
  undef $ok
    unless _is_bad { $assert->should( yaml_have_dpath => $yaml, '/before_install/*[ value =~/git clone.*maint-travis-ci/ ]' ) };
  for my $branch (qw( master builds releases )) {
    undef $ok unless $assert->should( yaml_have_dpath => $yaml, _branch_only($branch) );
  }
  for my $branch (qw( build/master )) {
    undef $ok unless $assert->should_not( yaml_have_dpath => $yaml, _branch_only($branch) );
  }

  return $ok;
};

_after_true 'dist_ini' => sub {
  my ( $ini, $self ) = @_;
  my $assert = $self->_pc;
  my $ok     = $ini;
  my (@tests) = ( qr/dzil bakeini/, qr/normal_form\s*=\s*numify/, qr/mantissa\s*=\s*6/, );
  for my $test (@tests) {
    undef $ok unless $assert->should( have_line => $ini, $test );
  }
  if ( not $assert->test( have_line => $ini, qr/dzil bakeini/ ) ) {
    _is_bad { undef $ok unless $assert->should( have_one_of_line => $ini, qr/bump_?versions\s*=\s*1/, qr/git_versions/ ) };
  }
  return $ok;
};

_after_true 'weaver_ini' => sub {
  my ( $weave, $self ) = @_;
  my $assert = $self->_pc;
  my $ok     = $weave;
  undef $ok unless $assert->should( have_line => $weave, qr/-SingleEncoding/, );
  undef $ok unless $assert->should_not( have_line => $weave, qr/-Encoding/, );
  return $ok;
};

_after_true 'dist_ini_meta' => sub {
  my ( $file, $self ) = @_;
  my $assert = $self->_pc;
  my (@wanted_regex) = (
    qr/bump_?versions\s*=\s*1/,              qr/toolkit\s*=\s*eumm/,
    qr/toolkit_hardness\s*=\s*soft/,         qr/src_?readme\s*=.*/,
    qr/copyright_holder\s*=.*<[^@]+@[^>]+>/, qr/twitter_extra_hash_tags\s*=\s*#/,
    qr/;\s*vim:\s+.*syntax=dosini/,
  );
  my (@unwanted_regex) = (
    #
    qr/copy_?files\s*=.*LICENSE/,
    qr/author.*=.*kentfredric/, qr/git_versions/,    #
    qr/twitter_hash_tags\s*=\s*#perl\s+#cpan\s*/,    #
  );
  my $ok = $file;
  for my $test (@wanted_regex) {
    undef $ok unless $assert->should( have_line => $file, $test );
  }
  for my $test (@unwanted_regex) {
    undef $ok unless $assert->should_not( have_line => $file, $test );
  }
  my (@upgrade_regex) = ( qr/src_readme\s*=.*/, qr/bump_versions\s*=.*/, qr/copy_files\s*=.*/ );
  if ( $assert->test( have_any_of_line => $file, @upgrade_regex ) ) {
    my $check = sub {
      my $v = $_[0];
      return (
          ( version->parse('2.025020') <= version->parse($v) )
        ? ( 1, "version $v is at least 2.025020" )
        : ( 0, "version $v is not at least 2.025020" )
      );
    };
    undef $ok unless $assert->should( have_assign => $file, ':version' => $check );
  }

  _is_bad {
    undef $ok unless $assert->should( have_one_of_line => $file, qr/bump_?versions\s*=\s*1/, qr/git_versions/ );
  };

  return $ok;
};

lsub unrecommend => sub {
  [
    qw( Path::Class Path::Class::File Path::Class::Dir ),    # Path::Tiny preferred
    qw( JSON JSON::XS JSON::Any ),                           # JSON::MaybeXS preferred
    qw( Path::IsDev Path::FindDev ),                         # Ugh, this is such a bad idea
    qw( File::ShareDir::ProjectDistDir ),                    # Whhhy
    qw( File::Find File::Find::Rule ),                       # Path::Iterator::Rule is much better
    qw( Class::Load ),                                       # Module::Runtime preferred
    qw( Readonly ),                                          # use Const::Fast
    qw( Sub::Name ),                                         # use Sub::Util
    qw( autobox ),                                           # Rewrite it
    qw( Moose::Autobox ),                                    # Rewrite it
    qw( List::MoreUtils ),                                   # Some people want to avoid it,
                                                             # consider avoiding if its easy to do so
  ];
};

sub avoid_old_modules {
  my ($self) = @_;
  return unless my $distmeta = $self->zilla->distmeta;
  my $assert = $self->_dc;

  my $ok = 1;
  for my $bad ( @{ $self->unrecommend } ) {
    undef $ok unless $assert->should_not( have_dpath => 'distmeta', $distmeta, '/prereqs/*/*/' . $bad );
  }
  return $ok;
}

_after_true 'mailmap' => sub {
  my ( $mailmap, $self ) = @_;
  my $ok = $mailmap;
  undef $ok unless $self->_pc->should( have_line => $mailmap, qr/<kentnl\@cpan.org>.*<kentfredric\@gmail.com>/ );
  return $ok;
};

# Hack to avoid matching ourselves.
sub _plugin_re {
  my $inpn = shift;
  my $pn = join q[::], split qr/\+/, $inpn;
  return qr/$pn/;
}

sub dzil_plugin_check {
  my ($self) = @_;
  return unless $self->libdir;
  return unless @{ $self->libfiles };
  my $assert = $self->_pc;
  my (@plugins) = grep { $_->stringify =~ /\Alib\/Dist\/Zilla\/Plugin\//msx } @{ $self->libfiles };
  return unless @plugins;
  for my $plugin (@plugins) {
    $assert->should_not( have_line => $plugin, _plugin_re('Dist+Zilla+Util+ConfigDumper') );
  }
  return unless $self->tdir;
  return unless @{ $self->tfiles };
FIND_DZTEST: {
    for my $tfile ( @{ $self->tfiles } ) {
      if ( $assert->test( have_line => $tfile, qr/dztest/ ) ) {
        $self->log('Tests should probably not use dztest (Dist::Zilla::Util::Test::KENTNL)');
        last FIND_DZTEST;
      }
    }
  }
  return;
}

sub setup_installer {
  my ($self) = @_;
  $self->git;
  $self->git_config;
  $self->dist_ini;
  $self->dist_ini_meta;
  $self->weaver_ini;
  $self->travis_yml;
  $self->contributing_pod;
  $self->makefile_pl;
  $self->perltidyrc;
  $self->gitignore;
  $self->changes;
  $self->license;
  $self->has_new_changes_deps;
  $self->perlcritic_deps;
  $self->perlcritic_gen;
  $self->avoid_old_modules;
  $self->mailmap;
  $self->dzil_plugin_check;
  return;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Author::KENTNL::RecommendFixes - Recommend generic changes to the dist.

=head1 VERSION

version 0.005004

=head1 DESCRIPTION

Nothing interesting to see here.

This module just informs me during C<dzil build> that a bunch of
changes that I intend to make to multiple modules have not been applied
to the current distribution.

It does this by spewing colored output.

=for Pod::Coverage setup_installer
has_new_changes_deps
avoid_old_modules
dzil_plugin_check

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
