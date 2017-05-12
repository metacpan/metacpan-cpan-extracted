package Installer::Target;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Currently running project
$Installer::Target::VERSION = '0.904';
use Moo;
use IO::All;
use IPC::Open3 ();
use Installer::Software;
use JSON_File;
use File::chdir;
use CPAN::Perl::Releases qw[perl_tarballs];
use Installer::cpanm;
use CPAN;
use Path::Class;
use namespace::clean;

has output_code => (
  is => 'ro',
  lazy => 1,
  default => sub { sub {
    print @_, "\n";
  } },
);

has installer_code => (
  is => 'ro',
  required => 1,
);

has source_directory => (
  is => 'ro',
  predicate => 1,
);
has source => (
  is => 'ro',
  lazy => 1,
  default => sub { dir($_[0]->source_directory)->absolute },
);
sub source_path { dir(shift->source,@_) }
sub source_file { file(shift->source,@_) }

has target_directory => (
  is => 'ro',
  required => 1,
);
has target => (
  is => 'ro',
  lazy => 1,
  default => sub { dir($_[0]->target_directory)->absolute },
);
sub target_path { dir(shift->target,@_) }
sub target_file { file(shift->target,@_) }

has installer_dir => (
  is => 'ro',
  lazy => 1,
  default => sub { dir($_[0]->target,'installer') },
);

has software => (
  is => 'ro',
  lazy => 1,
  default => sub {{}},
);

has actions => (
  is => 'ro',
  lazy => 1,
  default => sub {[]},
);

has src_dir => (
  is => 'ro',
  lazy => 1,
  default => sub { dir($_[0]->target,'src') },
);
sub src_path { dir(shift->src_dir,@_) }
sub src_file { file(shift->src_dir,@_) }

has log_filename => (
  is => 'ro',
  lazy => 1,
  default => sub { file($_[0]->installer_dir,'build.'.(time).'.log') },
);

has log_io => (
  is => 'ro',
  lazy => 1,
  default => sub { io($_[0]->log_filename) },
);

has meta => (
  is => 'ro',
  lazy => 1,
  default => sub {
    my ( $self ) = @_;
    tie(my %meta,'JSON_File',file($self->installer_dir,'meta.json')->absolute->stringify, pretty => 1);
    return \%meta;
  },
);

sub install_software {
  my ( $self, $software ) = @_;
  $self->software->{$software->alias} = $software;
  $software->installation;
  $self->meta->{software_packages_done} = [keys %{$self->software}];
  push @{$self->actions}, $software;
  $self->update_env;
  if (!defined $software->meta->{installed_export} && $software->has_export) {
    $self->install_export(ref $software->export eq 'ARRAY'
      ? @{$software->export}
      : $software->export
    );
    $software->meta->{installed_export} = 1;
  }
  if (!defined $software->meta->{installed_unset} && $software->has_unset) {
    $self->install_unset(ref $software->unset eq 'ARRAY'
      ? @{$software->unset}
      : $software->unset
    );
    $software->meta->{installed_unset} = 1;
  }
  $self->write_export;
  if (!defined $software->meta->{post_install} && $software->has_post_install) {
    $software->post_install->($software);
    $software->meta->{post_install} = 1;
  }
  $self->write_export;
}

sub install_url {
  my ( $self, $url, %args ) = @_;
  $self->install_software(Installer::Software->new(
    target => $self,
    archive_url => $url,
    %args,
  ));
}

sub install_git {
  my ( $self, $git, %args ) = @_;
  $self->install_software(Installer::Software->new(
    target => $self,
    git_url => $git,
    %args,
  ));
}

sub install_copy {
  my ( $self, $source, @target_path ) = @_;
  $self->log_print("Copy ".$source." to ".(join('/',@target_path))."...");
  io($self->target_path(@target_path))->print(io($source)->get->content);
}

sub install_text {
  my ( $self, $text, @target_path ) = @_;
  $self->log_print("Generating textfile at ".(join('/',@target_path))."...");
  io($self->target_path(@target_path))->print($text);
}

sub install_file {
  my ( $self, $file, %args ) = @_;
  $self->install_software(Installer::Software->new(
    target => $self,
    archive => rel2abs(catfile($file)),
    %args,
  ));
}

sub install_perl {
  my ( $self, $perl_version, %args ) = @_;
  my $hashref = perl_tarballs($perl_version);
  die 'No such Perl version: '.$perl_version unless defined $hashref;
  my $src = 'http://www.cpan.org/authors/id/'.$hashref->{'tar.gz'};
  $self->install_software(Installer::Software->new(
    target => $self,
    archive_url => $src,
    testable => 1,
    custom_configure => sub {
      my ( $self ) = @_;
      $self->run($self->unpack_path,'./Configure','-des','-Dprefix='.$self->target_directory);
    },
    post_install => sub {
      my ( $self ) = @_;
      $self->log_print("Installing App::cpanminus ...");
      my $cpanm_filename = file($self->target->installer_dir,'cpanm');
      Installer::cpanm::install_to($cpanm_filename);
      chmod(0755,$cpanm_filename);
      $self->run(undef,$cpanm_filename,'-L',$self->target_path('perl5'),qw(
        App::cpanminus
        local::lib
        Module::CPANfile
      ));
    },
    export_sh => sub {
      my ( $self ) = @_;
      'eval $( perl -I'.$self->target_path('perl5','lib','perl5').' -Mlocal::lib=--deactivate-all )',
      'eval $( perl -I'.$self->target_path('perl5','lib','perl5').' -Mlocal::lib='.$self->target_path('perl5').' )'
    },
    %args,
  ));
}

#url "http://ftp.postgresql.org/pub/source/v9.3.0/postgresql-9.3.0.tar.bz2", with => {
#  pgport => 15700,
#};
sub install_postgres {
  my ( $self, $version, %args ) = @_;
  my $url = "http://ftp.postgresql.org/pub/source/v".$version."/postgresql-".$version.".tar.bz2";
  my %with = defined $args{with}
    ? %{delete $args{with}}
    : ();
  $with{pgport} = delete $args{port} if defined $args{port};
  my %users = defined $args{users}
    ? %{delete $args{users}}
    : ();
  my $pgdata = defined $args{data}
    ? dir(delete $args{data})->absolute->stringify
    : $self->target_path('pgdata')->absolute->stringify;
  my $logfile = defined $args{log}
    ? dir(delete $args{log})->absolute->stringify
    : $self->target_file('pgdata','postgresql.log');
  if (defined $args{superuser_with_db}) {
    my $superuser_with_db = delete $args{superuser_with_db};
    if (ref $superuser_with_db eq 'HASH') {
      for (keys %{$superuser_with_db}) {
        $users{$_} = {
          superuser => 1,
          dbs => [
            ref $superuser_with_db->{$_} eq 'ARRAY'
              ? @{$superuser_with_db->{$_}}
              : $superuser_with_db->{$_}
          ],
        };
      }
    } elsif (ref $superuser_with_db eq 'ARRAY') {
      for (@{$superuser_with_db}) {
        $users{$_} = {
          superuser => 1,
          dbs => [$_],
        };
      }
    } elsif (ref $superuser_with_db eq '') {
      $users{$superuser_with_db} = {
        superuser => 1,
        dbs => [$superuser_with_db],
      };
    } else {
      die "unknown how to handle ".(ref $superuser_with_db);
    }
  }
  my $post_install = delete $args{post_install};
  $self->install_software(Installer::Software->new(
    target => $self,
    archive_url => $url,
    ignore_makefile_on_configure => 1,
    %with ? ( with => \%with ) : (),
    export => [
      'PGDATA='.$pgdata,
      defined $with{pgport} ? ('PGPORT='.$with{pgport}, 'PGHOST=localhost') : (),
      defined $args{export} ? ( delete $args{export} ) : (),
    ],
    post_install => sub {
      my @post_install_args = @_;

      $_[0]->run(undef,'initdb');
      $_[0]->run(undef,'pg_ctl','-w','-l',$logfile,'start');

      for my $user (keys %users) {
        my @create_args = '-w';
        if ($users{$user}->{superuser}) {
          push @create_args, '-s';
        }
        $_[0]->run(undef,'createuser',@create_args,$user);
        if (defined $users{$user}->{dbs}) {
          for (@{$users{$user}->{dbs}}) {
            $_[0]->run(undef,'createdb','-O',$user,$_);
          }
        }
      }

      if (defined $post_install) {
        $post_install->(@post_install_args);
      }

      $_[0]->run(undef,'pg_ctl','stop');
    },
    %args,
  ));
}

sub install_debian {
  my ( $self, @modules ) = @_;
  $self->run(undef,'sudo','apt-get','install','-y',@modules);
}

sub install_cpanm {
  my ( $self, @modules ) = @_;
  $self->run(undef,'cpanm',@modules);
}

sub install_pip {
  my ( $self, @modules ) = @_;
  for (@modules) {
    $self->run(undef,'pip','install',$_);    
  }
}

sub install_run {
  my ( $self, @args ) = @_;
  $self->run($self->target,@args);
  push @{$self->actions}, {
    run => \@args,
  };
}

sub install_perldeps {
  my ( $self, $path, @args ) = @_;
  die "No source_directory or path given" unless defined $path || $self->has_source_directory;
  $self->run(undef,"cpanm","--installdeps",defined $path ? $path : $self->source_directory);
  $self->run(undef,"set");
}

sub install_dzildeps {
  my ( $self, $path, @args ) = @_;
  die "No source_directory or path given" unless defined $path || $self->has_source_directory;
  $self->run(undef,"cpanm","Dist::Zilla");
  my $dzil_dir = defined $path ? $path : $self->source_directory;
  $self->run($dzil_dir,qw( dzil authordeps | grep -v " " | cpanm ));
  $self->run($dzil_dir,qw( dzil listdeps | grep -v " " | cpanm ));
}

sub install_export {
  my ( $self, @args ) = @_;
  my @exports = defined $self->meta->{export}
    ? @{$self->meta->{export}}
    : ();
  for (@args) {
    my @new_exports;
    if (ref $_ eq 'CODE') {
      push @new_exports, $_->($self);
    } else {
      push @new_exports, $_;
    }
    for (@new_exports) {
      $self->log_print("Adding export ".$_);
      push @exports, $_;
    }
  }
  $self->meta->{export} = \@exports;
  $self->write_export;
}

sub install_unset {
  my ( $self, @args ) = @_;
  my @unsets = defined $self->meta->{unset}
    ? @{$self->meta->{unset}}
    : ();
  for (@args) {
    my @new_unsets;
    if (ref $_ eq 'CODE') {
      push @new_unsets, $_->($self);
    } else {
      push @new_unsets, $_;
    }
    for (@new_unsets) {
      $self->log_print("Adding export ".$_);
      push @unsets, $_;
    }
  }
  $self->meta->{unset} = \@unsets;
  $self->write_export;
}

sub patch_via_url {
  my ( $self, $path, $url, @args ) = @_;
  local $CWD = $path;
  $self->log_print("Fetching patch from $url into ".$path." ...");
  my $diff_name = $url;
  $diff_name =~ s/^https{0,1}//g;
  $diff_name =~ s/[^\w]+/_/g;
  $diff_name =~ s/^_+//g;
  $diff_name =~ s/_+$//g;
  $diff_name .= '.patch';
  io(file($path,$diff_name))->print(io($url)->get->content);
  $self->log_print("Applying patch as ".$diff_name." ...");
  $|=1;
  my $patch_log = "";
  my $pid = IPC::Open3::open3(my ( $in, $out ), undef, "patch",@args);
  print $in scalar io($diff_name)->slurp;
  close ($in);
  while(defined(my $line = <$out>)){
    $patch_log .= $line;
    chomp($line);
    $self->log($line);
  }
  waitpid($pid, 0);
  my $status = $? >> 8;
  if ($status) {
    print $patch_log;
    print "\n";
    print "     Command: patch ".join(" ",@args)."\n";
    print "in Directory: ".$path."\n\n";
    print "exited with status $status\n\n";
    die "Error on run ".$self->log_filename;
  }
}

sub run {
  my ( $self, $dir, @args ) = @_;
  $dir = $self->target_path unless $dir;
  local $CWD = "$dir";
  $self->log_print("Executing in $dir: ".join(" ",@args));
  $|=1;
  my $run_log = "";
  my $export_sh_filename = $self->target_file('export.sh')->absolute->stringify;
  my $prefix = "";
  if (-f $export_sh_filename) {
    my @export_sh_lines = io($export_sh_filename)->slurp;
    for my $line (@export_sh_lines) {
      $run_log .= $line;
      $prefix .= $line;
      chomp($line);
      $self->log($line);
    }
    $prefix .= "\n# Command ".("#" x 50)."\n";
  }
  my $shell_script = $prefix.join(" ",@args)."";
  my $pid = IPC::Open3::open3(my ( $in, $out ), undef, "/bin/sh -s");
  print $in $shell_script;
  close ($in);
  while(defined(my $line = <$out>)){
    $run_log .= $line;
    chomp($line);
    $self->log($line);
  }
  waitpid($pid, 0);
  my $status = $? >> 8;
  if ($status) {
    print $run_log;
    print "\n";
    print " Command:\n";
    print "\n".join(" ",@args)."\n\n";
    print " in Directory: ".$dir."\n";
    print "exited with status $status\n\n";
    print "\n";
    die "Error on run ".$self->log_filename;
  }
}

sub log {
  my ( $self, @line ) = @_;
  $self->log_io->append(join(" ",@line),"\n");
}

sub log_print {
  my ( $self, @line ) = @_;
  $self->log("#" x 80);
  $self->log("##");
  $self->log("## ",@line);
  my ($sec,$min,$hour,$mday,$mon,$year) = localtime(time);
  $self->log("## ",sprintf("%.2d.%.2d.%.4d %.2d:%.2d:%.2d",$mday,$mon,$year+1900,$hour,$min,$sec));
  $self->log("##");
  $self->log("#" x 80);
  $self->output_code->(@line);
}

our $current;

sub prepare_installation {
  my ( $self ) = @_;
  die "Target directory is a file" if -f $self->target;
  $current = $self;
  $self->target->mkpath unless -d $self->target;
  $self->installer_dir->mkpath unless -d $self->installer_dir;
  $self->src_dir->mkpath unless -d $self->src_dir;
  $self->log_io->print(("#" x 80)."\nStarting new log ".(time)."\n".("#" x 80)."\n\n");
  $self->meta->{last_run} = time;
  $self->meta->{preinstall_ENV} = \%ENV;
}

sub finish_installation {
  my ( $self ) = @_;
  $self->log_print("Done ".$self->log_filename);
  %ENV = %{$self->meta->{preinstall_ENV}};
  delete $self->meta->{preinstall_ENV};
  $current = undef;
}

sub installation {
  my ( $self ) = @_;
  $self->prepare_installation;
  $self->installer_code->($self);
  $self->finish_installation;
}

sub write_export {
  my ( $self ) = @_;
  my $export_filename = $self->target_file('export.sh');
  $self->log_print("Generating ".$export_filename." ...");
  my $export_sh = "#!/bin/sh\n#\n# Installer auto generated export.sh\n#\n".("#" x 60)."\n\n";
  $export_sh .= 'export CURRENT_INSTALLER_ENV='.$self->target_path->stringify."\n";
  if (defined $self->meta->{unset} && @{$self->meta->{unset}}) {
    $export_sh .= '# custom unsets'."\n";
    for (@{$self->meta->{unset}}) {
      $export_sh .= 'unset '.$_."\n";
    }
  }
  if (defined $self->meta->{PATH} && @{$self->meta->{PATH}}) {
    $export_sh .= 'export PATH="'.join(':',@{$self->meta->{PATH}}).'${PATH+:}$PATH"'."\n";
  }
  if (defined $self->meta->{LD_LIBRARY_PATH} && @{$self->meta->{LD_LIBRARY_PATH}}) {
    $export_sh .= 'export LD_LIBRARY_PATH="'.join(':',@{$self->meta->{LD_LIBRARY_PATH}}).'${LD_LIBRARY_PATH+:}$LD_LIBRARY_PATH"'."\n";
  }
  if (defined $self->meta->{C_INCLUDE_PATH} && @{$self->meta->{C_INCLUDE_PATH}}) {
    $export_sh .= 'export C_INCLUDE_PATH="'.join(':',@{$self->meta->{C_INCLUDE_PATH}}).'${C_INCLUDE_PATH+:}$C_INCLUDE_PATH"'."\n";
  }
  if (defined $self->meta->{MANPATH} && @{$self->meta->{MANPATH}}) {
    $export_sh .= 'export MANPATH="'.join(':',@{$self->meta->{MANPATH}}).'${MANPATH+:}$MANPATH"'."\n";
  }
  if (defined $self->meta->{PKG_CONFIG_PATH} && @{$self->meta->{PKG_CONFIG_PATH}}) {
    $export_sh .= 'export PKG_CONFIG_PATH="'.join(':',@{$self->meta->{PKG_CONFIG_PATH}}).'${PKG_CONFIG_PATH+:}$PKG_CONFIG_PATH"'."\n";
  }
  if (defined $self->meta->{ACLOCAL_PATH}) {
    $export_sh .= 'export ACLOCAL_PATH="'.$self->meta->{ACLOCAL_PATH}.'"'."\n";
  }
  if (defined $self->meta->{ACLOCAL}) {
    $export_sh .= 'export ACLOCAL="'.$self->meta->{ACLOCAL}.'"'."\n";
  }
  if (defined $self->meta->{export} && @{$self->meta->{export}}) {
    $export_sh .= '# custom exports'."\n";
    for (@{$self->meta->{export}}) {
      $export_sh .= 'export '.$_."\n";
    }
  }
  $export_sh .= "\n";
  for (@{$self->meta->{software_packages_done}}) {
    my $software = $self->software->{$_};
    if ($software->has_export_sh) {
      my @lines = $software->export_sh->($software);
      $export_sh .= "# export.sh addition by ".$software->alias."\n";
      $export_sh .= join("\n",@lines)."\n\n";
    }
  }
  $export_sh .= ("#" x 60)."\n";
  io($export_filename)->print($export_sh);
  chmod(0755,$export_filename);
}

sub update_env {
  my ( $self ) = @_;
  my %seen = defined $self->meta->{seen_dirs}
    ? %{$self->meta->{seen_dirs}}
    : ();
  if (!$seen{'bin'} and -e $self->target_path('bin')) {
    my @bindirs = defined $self->meta->{PATH}
      ? @{$self->meta->{PATH}}
      : ();
    my $bindir = $self->target_path('bin')->absolute->stringify;
    push @bindirs, $bindir;
    $self->meta->{PATH} = \@bindirs;
    $seen{'bin'} = 1;
  }
  for my $p (qw( lib share )) {
    my $path = $self->target_path($p,'pkgconfig');
    my $skey = $p.'pkgconfig';
    if (!$seen{$skey} and -e $path) {
      my @pcp = defined $self->meta->{PKG_CONFIG_PATH}
        ? @{$self->meta->{PKG_CONFIG_PATH}}
        : ();
      push @pcp, $path->absolute->stringify;
      $self->meta->{PKG_CONFIG_PATH} = \@pcp;
      $seen{$skey} = 1;
    }
  }
  if (!$seen{'man'} and -e $self->target_path('man')) {
    my @mandirs = defined $self->meta->{MANPATH}
      ? @{$self->meta->{MANPATH}}
      : ();
    my $mandir = $self->target_path('man')->absolute->stringify;
    push @mandirs, $mandir;
    $self->meta->{MANPATH} = \@mandirs;
    $seen{'man'} = 1;
  }
  if (!$seen{'aclocal'} and -e $self->target_path('share','aclocal')) {
    $self->meta->{ACLOCAL_PATH} = $self->target_path('share','aclocal')->stringify;
    $self->meta->{ACLOCAL} = 'aclocal -I '.$self->meta->{ACLOCAL_PATH};
    $seen{'aclocal'} = 1;
  }
  if (!$seen{'lib'} and -e $self->target_path('lib')) {
    my @libdirs = defined $self->meta->{LD_LIBRARY_PATH}
      ? @{$self->meta->{LD_LIBRARY_PATH}}
      : ();
    my $libdir = $self->target_path('lib')->absolute->stringify;
    push @libdirs, $libdir;
    $self->meta->{LD_LIBRARY_PATH} = \@libdirs;
    $seen{'lib'} = 1;
  }
  if (!$seen{'include'} and -e $self->target_path('include')) {
    my @libdirs = defined $self->meta->{C_INCLUDE_PATH}
      ? @{$self->meta->{C_INCLUDE_PATH}}
      : ();
    my $libdir = $self->target_path('include')->absolute->stringify;
    push @libdirs, $libdir;
    $self->meta->{C_INCLUDE_PATH} = \@libdirs;
    $seen{'include'} = 1;
  }
  $self->meta->{seen_dirs} = \%seen;
}

1;

__END__

=pod

=head1 NAME

Installer::Target - Currently running project

=head1 VERSION

version 0.904

=head1 DESCRIPTION

You should use this through the command L<installto>.

B<TOTALLY BETA, PLEASE TEST :D>

=head1 SUPPORT

IRC

  Join #cindustries on irc.quakenet.org. Highlight Getty for fast reaction :).

Repository

  http://github.com/Getty/p5-installer
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-installer/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
